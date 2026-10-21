`default_nettype none
// Standalone auxiliary bank. ID 0 is rejected here: piano stays in original src.
// One event per clk when event_ready=1; accepted velocity-zero note-on is note-off.
module yinse_aux_bank #(parameter integer VOICES=16,MAX_DELAY=1024)(
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
 localparam integer SHIFT=$clog2(VOICES);
 wire [VOICES-1:0] ready;
 wire [VOICES*7-1:0] notes;
 wire [VOICES*24-1:0] samples;
 reg [VOICES-1:0] starts,stops;
 reg [IW-1:0] round_robin,chosen;
 reg found;
 wire on=event_note_on && event_velocity!=0;
 wire pitch_valid=event_note>=36 && event_note<=96;
 wire instrument_valid=instrument_id>=1 && instrument_id<=4;
 assign event_ready=!on || !pitch_valid || !instrument_valid || found;
 integer alloc_i,mix_i,stop_i;
 always_comb begin
  chosen=0;found=0;
  // Prefer same-note retrigger, then a ready free slot, then a rotating ready victim.
  for(alloc_i=VOICES-1;alloc_i>=0;alloc_i=alloc_i-1)
   if(ready[alloc_i] && active_mask[alloc_i] && notes[alloc_i*7 +: 7]==event_note)begin chosen=index_value(alloc_i);found=1;end
  if(!found)for(alloc_i=VOICES-1;alloc_i>=0;alloc_i=alloc_i-1)
   if(ready[alloc_i] && !active_mask[alloc_i])begin chosen=index_value(alloc_i);found=1;end
  if(!found)for(alloc_i=VOICES-1;alloc_i>=0;alloc_i=alloc_i-1)
   if(ready[({{(32-IW){1'b0}},round_robin}+alloc_i)%VOICES])begin chosen=index_value(({{(32-IW){1'b0}},round_robin}+alloc_i)%VOICES);found=1;end
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
 genvar g;
 generate for(g=0;g<VOICES;g=g+1)begin:G
  yinse_aux_voice #(.MAX_DELAY(MAX_DELAY),.SEED(24'h713AC5+24'(g))) voice(
   clk,rst_n,sample_tick,starts[g],stops[g],all_notes_off,instrument_id,event_note,event_velocity,
   ready[g],active_mask[g],samples[g*24 +: 24],overrun_mask[g],clipped_mask[g],notes[g*7 +: 7]);
 end endgenerate
endmodule
`default_nettype wire
