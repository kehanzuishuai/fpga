`default_nettype none
// Standalone auxiliary bank. ID 0 is rejected here: piano stays in original src.
// One event per clk when event_ready=1; accepted velocity-zero note-on is note-off.
module yinse_aux_bank #(parameter integer VOICES=16,MAX_DELAY=1024,MIX_SHIFT=$clog2(VOICES))(
 input wire clk,rst_n,sample_tick,all_notes_off,event_valid,event_note_on,
 input wire [2:0] instrument_id,input wire [6:0] event_note,input wire [7:0] event_velocity,
 output wire event_ready,output reg signed [23:0] pcm,output reg pcm_valid,
 output wire [VOICES-1:0] active_mask,output wire [VOICES-1:0] overrun_mask,
 output wire [VOICES-1:0] clipped_mask,output reg rejected
);
 localparam integer IW=(VOICES<2)?1:$clog2(VOICES);
 function automatic [IW-1:0] index_value(input integer unused_index);
  index_value=unused_index[IW-1:0];
 endfunction
 localparam integer MIX_W=24+$clog2(VOICES)+1;
 localparam integer SHIFT=MIX_SHIFT;
 wire [VOICES-1:0] ready;
 wire [VOICES*7-1:0] notes;
 wire [VOICES*24-1:0] samples;
 // Only the request is shared. Each voice captures its own parameters on start.
 wire [31:0] shared_inc,shared_bell;wire [10:0] shared_length,shared_ks_length;
 wire signed [15:0] shared_tuning,shared_ks_tuning;wire shared_valid;
 yinse_note_table shared_table(event_note,shared_inc,shared_length,shared_tuning,shared_valid);
 yinse_ks_tuning shared_kt(shared_length,shared_tuning,shared_ks_length,shared_ks_tuning);
 yinse_bell_profile shared_ratio(shared_inc,shared_bell);
 wire [91:0] note_params={shared_valid,shared_inc,shared_ks_length,shared_ks_tuning,shared_bell};
 reg [VOICES-1:0] starts,stops;
 reg [IW-1:0] round_robin,chosen;
 reg found;
 wire on=event_note_on && event_velocity!=0;
 wire pitch_valid=event_note>=36 && event_note<=96;
 wire instrument_valid=instrument_id>=1 && instrument_id<=4;
 // Readiness must not depend on note_on: the upstream FIFO qualifies its
 // note strobes with ready. Even NoteOff can wait briefly for an idle slot.
 assign event_ready=!pitch_valid || !instrument_valid || found;
 integer alloc_i,mix_i,stop_i;
 always_comb begin
  chosen=0;found=0;
  // Prefer same-note retrigger, then a ready free slot, then a rotating ready victim.
  for(alloc_i=VOICES-1;alloc_i>=0;alloc_i=alloc_i-1)
   if(ready[alloc_i] && active_mask[alloc_i] && notes[alloc_i*7 +: 7]==event_note)begin chosen=index_value(alloc_i);found=1;end
  if(!found)for(alloc_i=VOICES-1;alloc_i>=0;alloc_i=alloc_i-1)
   if(ready[alloc_i] && !active_mask[alloc_i])begin chosen=index_value(alloc_i);found=1;end
  // First ready at/above the rotating cursor, wrapping to the lowest ready
  // slot if needed. This is the same ordering as the previous variable-index
  // scan, without VOICES replicated VOICES-to-one readiness multiplexers.
  if(!found)begin
   for(alloc_i=VOICES-1;alloc_i>=0;alloc_i=alloc_i-1)
    if(ready[alloc_i])begin chosen=index_value(alloc_i);found=1;end
   for(alloc_i=VOICES-1;alloc_i>=0;alloc_i=alloc_i-1)
    if(ready[alloc_i] && index_value(alloc_i)>=round_robin)begin chosen=index_value(alloc_i);found=1;end
  end
 end
 always_comb begin
  starts=0;stops=0;stop_i=0;
  if(event_valid && event_ready && !all_notes_off)begin
   if(on && pitch_valid && instrument_valid)starts[chosen]=1;
   else if(!on)for(stop_i=0;stop_i<VOICES;stop_i=stop_i+1)
    if(notes[stop_i*7 +: 7]==event_note)stops[stop_i]=1;
  end
 end
 reg signed [MIX_W-1:0] sum,scaled_sum;
 always_comb begin
  sum=0;
  for(mix_i=0;mix_i<VOICES;mix_i=mix_i+1)sum=sum+{{(MIX_W-24){samples[mix_i*24+23]}},samples[mix_i*24 +: 24]};
  scaled_sum=sum>>>SHIFT; // fixed headroom; quiet with fewer notes, no pumping
 end
 initial if(VOICES<1 || VOICES>32 || (VOICES&(VOICES-1))!=0)$fatal(1,"VOICES must be power-of-two 1..32");
 always @(posedge clk or negedge rst_n)
 if(!rst_n)begin round_robin<=0;pcm<=0;pcm_valid<=0;rejected<=0;end
 else begin
  pcm_valid<=sample_tick;
  if(all_notes_off)begin pcm<=0;round_robin<=0;rejected<=0;end
  else begin
   if(event_valid && event_ready && on)begin
    if(pitch_valid && instrument_valid)round_robin<=(chosen==index_value(VOICES-1))?{IW{1'b0}}:chosen+1'b1;
    else rejected<=1;
   end
   if(sample_tick)begin
    if(scaled_sum>8388607)pcm<=24'sh7fffff;
    else if(scaled_sum< -8388608)pcm<=24'sh800000;else pcm<=scaled_sum[23:0];
   end
  end
 end
 localparam integer THREADS=(VOICES<8)?VOICES:8;
 localparam integer LANES=VOICES/THREADS;
 localparam integer CW=(THREADS<2)?1:$clog2(THREADS);
 reg [CW-1:0] cursor;
 always @(posedge clk or negedge rst_n)
  if(!rst_n)cursor<=0;
  else if(THREADS>1 && !(&ready))cursor<=cursor+1'b1;
  else cursor<=0; // No outstanding context/KS work: keep the shared bus quiet.
 wire [VOICES*399-1:0] queries;wire [LANES*334-1:0] results;
 genvar lane,thread;
 generate for(lane=0;lane<LANES;lane=lane+1)begin:L
  wire [398:0] words[0:THREADS-1];
  for(thread=0;thread<THREADS;thread=thread+1)begin:T
   assign words[thread]=queries[(lane*THREADS+thread)*399+:399];
  end
  yinse_aux_arithmetic math(words[cursor],results[lane*334+:334]);
 end endgenerate
 genvar g;
 generate for(g=0;g<VOICES;g=g+1)begin:G
  yinse_aux_voice_shared #(.MAX_DELAY(MAX_DELAY),.SEED(24'h713AC5+24'(g)),.EXTERNAL_ARITH(1)) voice(
   clk,rst_n,sample_tick,starts[g],stops[g],all_notes_off,instrument_id,event_note,event_velocity,
   ready[g],active_mask[g],samples[g*24 +: 24],overrun_mask[g],clipped_mask[g],notes[g*7 +: 7],note_params,cursor==CW'(g%THREADS),results[(g/THREADS)*334+:334],queries[g*399+:399]);
 end endgenerate
endmodule
`default_nettype wire
