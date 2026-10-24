`default_nettype none
// Standalone auxiliary bank. ID 0 is rejected here: piano stays in original src.
// One event per clk when event_ready=1; accepted velocity-zero note-on is note-off.
module yinse_aux_bank #(parameter integer VOICES=16,MAX_DELAY=1024,MIX_SHIFT=$clog2(VOICES))(
 input wire clk,rst_n,sample_tick,all_notes_off,event_valid,event_note_on,
 input wire [2:0] instrument_id,input wire [6:0] event_note,input wire [7:0] event_velocity,
 output wire event_ready,output reg signed [23:0] pcm,output reg pcm_valid,
 output wire [VOICES-1:0] active_mask,output wire [VOICES-1:0] overrun_mask,
 output wire [VOICES-1:0] clipped_mask,output reg rejected,
 output wire [VOICES*7-1:0] display_voice_notes
);
 localparam integer IW=(VOICES<2)?1:$clog2(VOICES);
 function automatic [IW-1:0] index_value(input integer unused_index);
  index_value=unused_index[IW-1:0];
 endfunction
 localparam integer MIX_W=24+$clog2(VOICES)+1;
 localparam integer SHIFT=MIX_SHIFT;
 wire [VOICES-1:0] ready;
 wire [VOICES*7-1:0] notes;
 assign display_voice_notes=notes;
 wire [VOICES*24-1:0] samples;
 // Only the request is shared. Each voice captures its own parameters on start.
 wire [31:0] shared_inc,shared_bell;wire [10:0] shared_length,shared_ks_length;
 wire signed [15:0] shared_tuning,shared_ks_tuning;wire shared_valid;
 yinse_note_table shared_table(event_note,shared_inc,shared_length,shared_tuning,shared_valid);
 yinse_ks_tuning shared_kt(shared_length,shared_tuning,shared_ks_length,shared_ks_tuning);
 yinse_bell_profile shared_ratio(shared_inc,shared_bell);
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
 // Each lane keeps its THREADS voice contexts in distributed RAM and steps
 // the cursor-selected voice on exactly the clocks the per-voice registers did.
 wire [VOICES-1:0] accepted,fresh;
 wire [VOICES*3-1:0] voice_states,voice_instruments;
 wire [VOICES*16-1:0] envelopes;wire [VOICES*24-1:0] ks_latched;
 wire [LANES-1:0] lane_write,lane_sample_write,lane_clipped;
 wire [LANES*3-1:0] lane_state;wire [LANES*24-1:0] lane_sample;
 wire [71:0] static_data={(event_velocity>127)?8'd127:event_velocity,shared_inc,shared_bell};
 genvar lane;
 generate for(lane=0;lane<LANES;lane=lane+1)begin:L
  wire [THREADS-1:0] lane_starts=accepted[lane*THREADS+:THREADS];
  reg [CW-1:0] start_thread;integer s;
  always_comb begin start_thread=0;for(s=0;s<THREADS;s=s+1)if(lane_starts[s])start_thread=CW'(s);end
  yinse_aux_context_lane #(.THREADS(THREADS),.CW(CW),.SEED_BASE(24'h713AC5+24'(lane*THREADS))) store(
   clk,all_notes_off,cursor,voice_states[lane*THREADS*3+:THREADS*3],voice_instruments[lane*THREADS*3+:THREADS*3],
   envelopes[lane*THREADS*16+:THREADS*16],ks_latched[lane*THREADS*24+:THREADS*24],fresh[lane*THREADS+:THREADS],lane_starts,
   |lane_starts,start_thread,static_data,
   lane_write[lane],lane_state[lane*3+:3],lane_sample_write[lane],lane_sample[lane*24+:24],lane_clipped[lane]);
 end endgenerate
 // Keep every24-bit sample and each independent logical port. The upper
 // six bits of two voices share one true-dual-port2048x9 block; lower18
 // bits each retain a1024x18 block. Three blocks per pair, no arbitration.
 localparam PACKED_KS=(MAX_DELAY==1024 && VOICES>=2);
 localparam KAW=$clog2(MAX_DELAY);
 wire [VOICES*KAW-1:0] ks_address;
 wire [VOICES-1:0] ks_read,ks_write;
 wire [VOICES*24-1:0] ks_write_data,ks_read_data;
 genvar pair;
 generate if(PACKED_KS)begin:G_PACKED_KS
  for(pair=0;pair<VOICES/2;pair=pair+1)begin:P
   yinse_ks_ram_pair memory(clk,
    ks_address[(pair*2)*KAW+:KAW],ks_read[pair*2],ks_write[pair*2],ks_write_data[(pair*2)*24+:24],ks_read_data[(pair*2)*24+:24],
    ks_address[(pair*2+1)*KAW+:KAW],ks_read[pair*2+1],ks_write[pair*2+1],ks_write_data[(pair*2+1)*24+:24],ks_read_data[(pair*2+1)*24+:24]);
  end
 end else begin:G_LOCAL_KS
  assign ks_read_data=0;
 end endgenerate
 // One shared Karplus-Strong datapath; per-voice string registers stay in the slots.
 wire [VOICES-1:0] ks_pending,engine_read,engine_write;
 wire [VOICES*KAW-1:0] ks_ptrs;wire [VOICES*11-1:0] ks_lengths;wire [VOICES*16-1:0] ks_coefficients;
 wire [VOICES*24-1:0] ks_ws;wire [KAW-1:0] engine_address,engine_ptr;wire [23:0] engine_data;
 wire signed [23:0] engine_w,engine_sample;wire engine_clipped;
 genvar g;
 generate for(g=0;g<VOICES;g=g+1)begin:G
  yinse_aux_voice_slot #(.MAX_DELAY(MAX_DELAY),.SEED(24'h713AC5+24'(g)),.EXTERNAL_KS_MEMORY(PACKED_KS)) voice(
   clk,rst_n,sample_tick,starts[g],stops[g],all_notes_off,instrument_id,event_note,shared_valid,shared_ks_length,shared_ks_tuning,
   ready[g],active_mask[g],samples[g*24 +: 24],overrun_mask[g],clipped_mask[g],notes[g*7 +: 7],
   accepted[g],voice_states[g*3+:3],voice_instruments[g*3+:3],envelopes[g*16+:16],ks_latched[g*24+:24],fresh[g],
   lane_write[g/THREADS] && cursor==CW'(g%THREADS),lane_state[(g/THREADS)*3+:3],lane_sample_write[g/THREADS],
   lane_sample[(g/THREADS)*24+:24],lane_clipped[g/THREADS],
   ks_pending[g],ks_ptrs[g*KAW+:KAW],ks_lengths[g*11+:11],ks_coefficients[g*16+:16],ks_ws[g*24+:24],
   engine_read[g],engine_write[g],engine_address,engine_data,engine_w,engine_sample,engine_ptr,engine_clipped,
   ks_address[g*KAW+:KAW],ks_read[g],ks_write[g],ks_write_data[g*24+:24],ks_read_data[g*24+:24]);
 end endgenerate
 yinse_ks_engine #(.VOICES(VOICES),.KAW(KAW)) ks_engine(clk,rst_n,all_notes_off,ks_pending,accepted,
  ks_ptrs,ks_lengths,ks_coefficients,ks_ws,ks_read_data,engine_read,engine_write,
  engine_address,engine_data,engine_w,engine_sample,engine_ptr,engine_clipped);
endmodule
`default_nettype wire

`default_nettype none
// Two independent1024x24 synchronous ports occupy three18Kbit BSRAMs.
module yinse_ks_ram_pair(
 input wire clk,
 input wire[9:0] address_a,input wire read_a,write_a,input wire[23:0] data_a,output wire[23:0] q_a,
 input wire[9:0] address_b,input wire read_b,write_b,input wire[23:0] data_b,output wire[23:0] q_b
);
 (* syn_ramstyle="block_ram" *) reg[17:0] lower_a[0:1023],lower_b[0:1023];
 reg[17:0] low_q_a,low_q_b;
 always @(posedge clk)begin
  if(read_a)low_q_a<=lower_a[address_a];
  if(write_a)lower_a[address_a]<=data_a[17:0];
  if(read_b)low_q_b<=lower_b[address_b];
  if(write_b)lower_b[address_b]<=data_b[17:0];
 end
 wire[17:0] high_q_a,high_q_b;
 DPX9B #(.READ_MODE0(1'b0),.READ_MODE1(1'b0),.WRITE_MODE0(2'b00),.WRITE_MODE1(2'b00),
 .BIT_WIDTH_0(9),.BIT_WIDTH_1(9)) upper_pair(
 .DOA(high_q_a),.DOB(high_q_b),.DIA({12'd0,data_a[23:18]}),.DIB({12'd0,data_b[23:18]}),
 .BLKSELA(3'd0),.BLKSELB(3'd0),
 .ADA({1'b0,address_a,3'd0}),.ADB({1'b1,address_b,3'd0}),
 .WREA(write_a),.WREB(write_b),.CLKA(clk),.CLKB(clk),.CEA(read_a||write_a),.CEB(read_b||write_b),
 .OCEA(1'b1),.OCEB(1'b1),.RESETA(1'b0),.RESETB(1'b0));
 assign q_a={high_q_a[5:0],low_q_a};assign q_b={high_q_b[5:0],low_q_b};
endmodule
`default_nettype wire

`default_nettype none
// Time-shared context store for THREADS auxiliary voices. On every clock the
// voice selected by cursor is read from distributed RAM, advanced by one step
// of the original yinse_aux_voice_context state machine through the shared
// arithmetic, and written back - the same voice and step the per-voice
// registers took on that clock. Values the original reset on note-on (and on
// reset) are substituted on read while the voice's fresh flag is set; every
// other context field is always written before it is read.
module yinse_aux_context_lane #(parameter integer THREADS=8,CW=3,parameter [23:0] SEED_BASE=24'h713AC5)(
 input wire clk,clear,input wire [CW-1:0] cursor,
 input wire [THREADS*3-1:0] states,instruments,input wire [THREADS*16-1:0] envelopes,
 input wire [THREADS*24-1:0] ks_samples,input wire [THREADS-1:0] fresh,starts,
 input wire static_write,input wire [CW-1:0] static_thread,input wire [71:0] static_data,
 output wire write,output reg [2:0] next_state,output reg sample_write,
 output wire signed [23:0] next_sample,output wire next_clipped
);
 localparam [2:0] IDLE=0,PARTIAL=1,MODULATOR=2,CARRIER=3,OUTPUT=4,VELOCITY=5,START_FRAME=6;
 localparam integer DW=287;
 (* syn_ramstyle="distributed_ram" *) reg [71:0] static_ram[0:THREADS-1];
 (* syn_ramstyle="distributed_ram" *) reg [DW-1:0] dynamic_ram[0:THREADS-1];
 integer i;
 initial for(i=0;i<THREADS;i=i+1)begin static_ram[i]=0;dynamic_ram[i]=0;end
 wire [2:0] state=states[cursor*3+:3],instrument=instruments[cursor*3+:3];
 wire [15:0] envelope=envelopes[cursor*16+:16];
 wire signed [23:0] ks_sample=ks_samples[cursor*24+:24];
 wire is_fresh=fresh[cursor];
 wire [7:0] velocity;wire [31:0] increment,bell_increment;
 assign {velocity,increment,bell_increment}=static_ram[cursor];
 wire [32:0] stored_phase;wire [31:0] stored_mod_phase,stored_lfo_phase;
 wire [15:0] stored_modulation_level;wire [5:0] stored_modulation_count;wire [3:0] slot;
 wire signed [27:0] accumulator,raw,enveloped;wire signed [31:0] phase_offset;
 wire [23:0] stored_noise;wire signed [23:0] stored_ks_dc;
 assign {stored_phase,stored_mod_phase,stored_lfo_phase,stored_modulation_level,stored_modulation_count,
  slot,accumulator,raw,phase_offset,stored_noise,stored_ks_dc,enveloped}=dynamic_ram[cursor];
 wire [32:0] phase=is_fresh?33'd0:stored_phase;
 wire [31:0] mod_phase=is_fresh?32'd0:stored_mod_phase;
 wire [31:0] lfo_phase=is_fresh?32'd0:stored_lfo_phase;
 wire [15:0] modulation_level=is_fresh?16'd65535:stored_modulation_level;
 wire [5:0] modulation_count=is_fresh?6'd0:stored_modulation_count;
 wire [23:0] noise=is_fresh?SEED_BASE+24'(cursor):stored_noise;
 wire signed [23:0] ks_dc=is_fresh?24'sd0:stored_ks_dc;
 wire [333:0] result;
 yinse_aux_arithmetic math({state,instrument,slot,phase,increment,mod_phase,lfo_phase,modulation_level,
  accumulator,raw,phase_offset,noise,velocity,enveloped,envelope,ks_sample,ks_dc,bell_increment},result);
 wire [32:0] next_phase;wire [31:0] next_mod_phase,next_lfo_phase;
 wire signed [27:0] partial_sum,raw_flute,carrier_value,enveloped_next,ks_raw;
 wire signed [31:0] phase_offset_next;wire signed [23:0] dc_next;wire [15:0] next_modulation_level;
 assign {next_phase,next_mod_phase,next_lfo_phase,partial_sum,raw_flute,phase_offset_next,
  carrier_value,enveloped_next,next_sample,next_clipped,dc_next,ks_raw,next_modulation_level}=result;
 reg [32:0] phase_w;reg [31:0] mod_phase_w,lfo_phase_w;reg [15:0] modulation_level_w;reg [5:0] modulation_count_w;
 reg [3:0] slot_w;reg signed [27:0] accumulator_w,raw_w,enveloped_w;reg signed [31:0] phase_offset_w;
 reg [23:0] noise_w;reg signed [23:0] ks_dc_w;
 always_comb begin
  phase_w=phase;mod_phase_w=mod_phase;lfo_phase_w=lfo_phase;modulation_level_w=modulation_level;
  modulation_count_w=modulation_count;slot_w=slot;accumulator_w=accumulator;raw_w=raw;
  phase_offset_w=phase_offset;noise_w=noise;ks_dc_w=ks_dc;enveloped_w=enveloped;
  next_state=state;sample_write=0;
  case(state)
   START_FRAME:begin
    phase_w=next_phase;lfo_phase_w=next_lfo_phase;mod_phase_w=next_mod_phase;
    noise_w={noise[22:0],noise[23]^noise[22]^noise[21]^noise[16]};
    if(instrument==1 || instrument==2)begin slot_w=0;accumulator_w=0;next_state=PARTIAL;end
    else if(instrument==4)begin
     next_state=MODULATOR;modulation_count_w=modulation_count+1'b1;
     if(&modulation_count && modulation_level!=0)modulation_level_w=next_modulation_level;
    end else begin ks_dc_w=dc_next;raw_w=ks_raw;next_state=OUTPUT;end
   end
   PARTIAL:begin
    accumulator_w=partial_sum;
    if(slot==((instrument==1)?4'd8:4'd2))begin
     raw_w=(instrument==2)?raw_flute:partial_sum>>>2;next_state=OUTPUT;
    end else slot_w=slot+1'b1;
   end
   MODULATOR:begin phase_offset_w=phase_offset_next;next_state=CARRIER;end
   CARRIER:begin raw_w=carrier_value;next_state=OUTPUT;end
   OUTPUT:begin enveloped_w=enveloped_next;next_state=VELOCITY;end
   VELOCITY:begin sample_write=1;next_state=IDLE;end
   default:begin end
  endcase
 end
 // IDLE (waiting for the sample tick) and the unused code 7 stay in the voice.
 assign write=!clear && !starts[cursor] && state!=IDLE && state!=3'd7;
 always @(posedge clk)begin
  if(static_write)static_ram[static_thread]<=static_data;
  if(write)dynamic_ram[cursor]<={phase_w,mod_phase_w,lfo_phase_w,modulation_level_w,modulation_count_w,
   slot_w,accumulator_w,raw_w,phase_offset_w,noise_w,ks_dc_w,enveloped_w};
 end
endmodule
`default_nettype wire

`default_nettype none
// Per-voice part of a time-shared auxiliary voice: the original preset and
// envelope, the registers that all voices expose at once (ready/active for
// allocation, note for display, sample for the mixer) and the per-string KS
// registers plus note-on noise fill. The KS loss filter/tuning datapath is
// the bank's shared yinse_ks_engine.
module yinse_aux_voice_slot #(parameter integer MAX_DELAY=1024,parameter [23:0] SEED=24'h713AC5,parameter EXTERNAL_KS_MEMORY=1)(
 input wire clk,rst_n,sample_tick,start,stop,clear,
 input wire [2:0] instrument_in,input wire [6:0] note_in,input wire note_valid,
 input wire [10:0] ks_length,input wire signed [15:0] ks_tuning,
 output wire ready,active,output reg signed [23:0] sample,output wire overrun,clipped,output reg [6:0] note,
 output wire accepted_start,output reg [2:0] state,output reg [2:0] instrument,output wire [15:0] envelope,
 output reg signed [23:0] ks_previous,output reg fresh,
 input wire lane_write,input wire [2:0] lane_state,input wire lane_sample_write,
 input wire signed [23:0] lane_sample,input wire lane_clipped,
 output reg ks_pending,output reg [$clog2(MAX_DELAY)-1:0] ks_ptr,output reg [10:0] ks_len,
 output reg signed [15:0] ks_coef,output reg signed [23:0] ks_w,
 input wire engine_read,engine_write,input wire [$clog2(MAX_DELAY)-1:0] engine_address,
 input wire [23:0] engine_data,input wire signed [23:0] engine_w,engine_sample,
 input wire [$clog2(MAX_DELAY)-1:0] engine_ptr,input wire engine_clipped,
 output wire [$clog2(MAX_DELAY)-1:0] ks_memory_address,
 output wire ks_memory_read,ks_memory_write,output wire [23:0] ks_memory_write_data,
 input wire [23:0] ks_memory_read_data
);
 localparam [2:0] IDLE=0,START_FRAME=6;
 localparam integer AW=$clog2(MAX_DELAY);
 typedef logic [AW-1:0] address_t;
 initial if(!EXTERNAL_KS_MEMORY || MAX_DELAY<4 || MAX_DELAY>1024 || (MAX_DELAY&(MAX_DELAY-1))!=0 || SEED==0)
  $fatal(1,"shared KS needs bank memory, power-of-two MAX_DELAY 4..1024 and nonzero seed");
 reg local_overrun,local_clipped;
 wire [15:0] attack_step,decay_step,sustain_level,release_step;
 wire [4:0] unused_fx_ctrl;wire unused_preset_valid;
 wire [23:0] unused_read_data=ks_memory_read_data;
 yinse_preset preset(instrument,attack_step,decay_step,sustain_level,release_step,unused_fx_ctrl,unused_preset_valid);
 assign accepted_start=start && note_valid && instrument_in>=1 && instrument_in<=4;
 yinse_envelope env(clk,rst_n,sample_tick,accepted_start,stop,clear,
 attack_step,decay_step,sustain_level,release_step,envelope,active);
 // String state of the original yinse_ks_loop_core; the 5-clock filter pass
 // runs in the shared engine, the note-on noise fill stays here.
 reg ks_filling,ks_overrun,ks_clipped;reg [AW-1:0] ks_fill_ptr;reg [23:0] ks_noise;
 reg signed [23:0] ks_sample;
 wire ks_start=accepted_start && instrument_in==3;
 wire ks_clear=clear || (accepted_start && instrument_in!=3);
 wire ks_enable=active && instrument==3;
 always @(posedge clk or negedge rst_n)
 if(!rst_n)begin
  ks_filling<=0;ks_pending<=0;ks_ptr<=0;ks_fill_ptr<=0;ks_len<=2;ks_coef<=0;ks_noise<=SEED;
  ks_w<=0;ks_sample<=0;ks_overrun<=0;ks_clipped<=0;
 end else if(ks_clear)begin ks_filling<=0;ks_pending<=0;ks_sample<=0;ks_w<=0;ks_overrun<=0;ks_clipped<=0;end
 else if(ks_start)begin
  ks_len<=ks_length;ks_coef<=ks_tuning;ks_ptr<=0;ks_fill_ptr<=0;ks_noise<=SEED;ks_w<=0;ks_sample<=0;ks_pending<=0;
  if(ks_length>=2 && {21'd0,ks_length}<=MAX_DELAY)ks_filling<=1;else begin ks_filling<=0;ks_overrun<=1;end
 end else begin
  if(sample_tick && ks_enable && ks_pending)ks_overrun<=1;
  if(ks_filling)begin
   ks_noise<={ks_noise[22:0],ks_noise[23]^ks_noise[22]^ks_noise[21]^ks_noise[16]};
   if(ks_fill_ptr==address_t'(ks_len-1'b1))ks_filling<=0;else ks_fill_ptr<=ks_fill_ptr+1'b1;
  end else if(sample_tick && ks_enable)ks_pending<=1;
  if(engine_write)begin
   ks_w<=engine_w;ks_sample<=engine_sample;ks_ptr<=engine_ptr;ks_pending<=0;
   if(engine_clipped)ks_clipped<=1;
  end
 end
 assign ks_memory_address=ks_filling?ks_fill_ptr:engine_address;
 assign ks_memory_read=engine_read;
 assign ks_memory_write=ks_filling || engine_write;
 // Arithmetic shift in its own signed context, as in yinse_ks_loop_core (inside the
 // mux below the unsigned engine_data operand would make it a logical shift).
 wire signed [23:0] ks_fill_data=$signed(ks_noise)>>>1;
 assign ks_memory_write_data=ks_filling?ks_fill_data:engine_data;
 assign ready=state==IDLE && !ks_filling;
 assign overrun=local_overrun || ks_overrun;assign clipped=local_clipped || ks_clipped;
 always @(posedge clk or negedge rst_n)
 if(!rst_n)begin
  state<=IDLE;instrument<=1;note<=0;ks_previous<=0;sample<=0;fresh<=1;local_overrun<=0;local_clipped<=0;
 end else if(clear)begin state<=IDLE;sample<=0;ks_previous<=0;local_overrun<=0;local_clipped<=0;end
 else if(accepted_start)begin
  state<=IDLE;instrument<=instrument_in;note<=note_in;ks_previous<=0;sample<=0;fresh<=1;
 end else begin
  if(sample_tick && active && state!=IDLE)local_overrun<=1;
  if(lane_write)begin
   state<=lane_state;fresh<=0;
   if(lane_sample_write)begin sample<=lane_sample;if(lane_clipped)local_clipped<=1;end
  end else if(state==IDLE)begin
   if(sample_tick)begin
    if(!active)sample<=0;
    else begin ks_previous<=ks_sample;state<=START_FRAME;end
   end
  end else if(state==3'd7)state<=IDLE;
 end
endmodule
`default_nettype wire

`default_nettype none
// One Karplus-Strong loss-filter/fractional-delay datapath for all voices.
// Pending voices are served in index order: IDLE, READ0, READ1, AVERAGE,
// TUNE, WRITE (6 clocks each). Arithmetic, RAM addresses and read timing are
// those of yinse_ks_loop_core. A note-on or clear cancels the voice in flight.
module yinse_ks_engine #(parameter integer VOICES=32,KAW=10)(
 input wire clk,rst_n,clear,input wire [VOICES-1:0] pending,cancel,
 input wire [VOICES*KAW-1:0] ptrs,input wire [VOICES*11-1:0] lengths,
 input wire [VOICES*16-1:0] coefficients,input wire [VOICES*24-1:0] ws,read_data,
 output wire [VOICES-1:0] read_en,write_en,
 output wire [KAW-1:0] address,output wire [23:0] write_data,
 output wire signed [23:0] new_w,new_sample,output wire [KAW-1:0] new_ptr,output wire new_clipped
);
 localparam integer IW=(VOICES<2)?1:$clog2(VOICES);
 localparam [2:0] IDLE=0,READ0=2,READ1=3,AVERAGE=4,TUNE=5,WRITE=6;
 typedef logic [KAW-1:0] address_t;
 reg [2:0] state;reg [IW-1:0] sel;reg signed [23:0] current,v;
 wire [KAW-1:0] ptr=ptrs[sel*KAW+:KAW];
 wire [10:0] length=lengths[sel*11+:11];
 wire signed [15:0] coefficient=coefficients[sel*16+:16];
 wire signed [23:0] w=ws[sel*24+:24];
 wire signed [23:0] read_value=read_data[sel*24+:24];
 wire [KAW-1:0] next_ptr=(ptr==address_t'(length-1'b1))?{KAW{1'b0}}:ptr+1'b1;
 wire signed [24:0] pair_sum={current[23],current}+{read_value[23],read_value};
 wire signed [24:0] average=pair_sum>>>1;
 wire signed [40:0] average_wide={{16{average[24]}},average};
 wire signed [40:0] loss_product=(average_wide<<<15)-(average_wide<<<5)-(average_wide<<<4);
 wire signed [31:0] difference={{8{v[23]}},v}-{{8{w[23]}},w};
 wire signed [47:0] tune_product=difference*coefficient;
 wire [32:0] unused_quantization={loss_product[40:39],loss_product[14:0],tune_product[47],tune_product[14:0]};
 wire signed [31:0] m=tune_product[46:15];
 wire signed [31:0] new_ring=m+{{8{w[23]}},w};
 wire signed [31:0] new_w_raw=m+{{8{v[23]}},v};
 function automatic signed [23:0] clamp24(input signed [31:0] x);
  if(x>32'sd8388607)clamp24=24'sh7fffff;
  else if(x< -32'sd8388608)clamp24=24'sh800000;
  else clamp24=x[23:0];
 endfunction
 wire abort=clear || cancel[sel];
 reg [IW-1:0] first;reg any;integer i;
 always_comb begin
  first=0;any=0;
  for(i=VOICES-1;i>=0;i=i-1)if(pending[i] && !cancel[i])begin first=IW'(i);any=1;end
 end
 wire op_read=state==READ0 || state==READ1;
 wire op_write=state==WRITE && !abort;
 genvar g;
 generate for(g=0;g<VOICES;g=g+1)begin:SEL
  assign read_en[g]=op_read && sel==IW'(g);
  assign write_en[g]=op_write && sel==IW'(g);
 end endgenerate
 assign address=(state==READ0 || state==WRITE)?ptr:next_ptr;
 assign write_data=clamp24(new_ring);
 assign new_w=clamp24(new_w_raw);assign new_sample=current;assign new_ptr=next_ptr;
 assign new_clipped=new_ring>8388607 || new_ring< -8388608 || new_w_raw>8388607 || new_w_raw< -8388608;
 always @(posedge clk or negedge rst_n)
 if(!rst_n)begin state<=IDLE;sel<=0;current<=0;v<=0;end
 else if(state!=IDLE && abort)state<=IDLE;
 else case(state)
  IDLE:if(any && !clear)begin sel<=first;state<=READ0;end
  READ0:state<=READ1;
  READ1:begin current<=read_value;state<=AVERAGE;end
  AVERAGE:begin v<=loss_product[38:15];state<=TUNE;end
  TUNE:state<=WRITE;
  WRITE:state<=IDLE;
  default:state<=IDLE;
 endcase
endmodule
`default_nettype wire
