"""Move the auxiliary voice contexts from per-voice registers into one small
distributed RAM per arithmetic lane.

Before: 32 yinse_aux_voice_context instances each kept ~400 bits of state in
flip-flops (each bit with its own load multiplexer) and published a 399-bit
query; every lane picked one of eight queries through a 399-bit 8:1 mux.
After: each lane reads the cursor-selected voice's context from an 8-entry RAM,
advances it by exactly the step the original state machine took on that clock
(same cursor, same shared arithmetic) and writes it back.  Only the registers
every voice must expose at the same time stay per voice (state, instrument,
note, sample, KS sample latched at the tick, flags) together with the
unchanged envelope, preset and KS loop.  Note-on/reset values are substituted
on read through a per-voice fresh flag.  Clock-for-clock identical ports.
Idempotent; the standalone yinse_aux_voice_context is left untouched.
"""
from pathlib import Path
import sys

LANE_OLD = ''' wire [VOICES*399-1:0] queries;wire [LANES*334-1:0] results;
 genvar lane,thread;
 generate for(lane=0;lane<LANES;lane=lane+1)begin:L
  wire [398:0] words[0:THREADS-1];
  for(thread=0;thread<THREADS;thread=thread+1)begin:T
   assign words[thread]=queries[(lane*THREADS+thread)*399+:399];
  end
  yinse_aux_arithmetic math(words[cursor],results[lane*334+:334]);
 end endgenerate
'''
LANE_NEW = ''' // Each lane keeps its THREADS voice contexts in distributed RAM and steps
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
'''
VOICE_OLD = ''' generate for(g=0;g<VOICES;g=g+1)begin:G
  yinse_aux_voice_context #(.MAX_DELAY(MAX_DELAY),.SEED(24'h713AC5+24'(g)),.EXTERNAL_ARITH(1),.EXTERNAL_KS_MEMORY(PACKED_KS)) voice(
   clk,rst_n,sample_tick,starts[g],stops[g],all_notes_off,instrument_id,event_note,event_velocity,
   ready[g],active_mask[g],samples[g*24 +: 24],overrun_mask[g],clipped_mask[g],notes[g*7 +: 7],note_params,cursor==CW'(g%THREADS),results[(g/THREADS)*334+:334],queries[g*399+:399],
   ks_address[g*KAW+:KAW],ks_read[g],ks_write[g],ks_write_data[g*24+:24],ks_read_data[g*24+:24]);
 end endgenerate
'''
VOICE_NEW = ''' generate for(g=0;g<VOICES;g=g+1)begin:G
  yinse_aux_voice_slot #(.MAX_DELAY(MAX_DELAY),.SEED(24'h713AC5+24'(g)),.EXTERNAL_KS_MEMORY(PACKED_KS)) voice(
   clk,rst_n,sample_tick,starts[g],stops[g],all_notes_off,instrument_id,event_note,shared_valid,shared_ks_length,shared_ks_tuning,
   ready[g],active_mask[g],samples[g*24 +: 24],overrun_mask[g],clipped_mask[g],notes[g*7 +: 7],
   accepted[g],voice_states[g*3+:3],voice_instruments[g*3+:3],envelopes[g*16+:16],ks_latched[g*24+:24],fresh[g],
   lane_write[g/THREADS] && cursor==CW'(g%THREADS),lane_state[(g/THREADS)*3+:3],lane_sample_write[g/THREADS],
   lane_sample[(g/THREADS)*24+:24],lane_clipped[g/THREADS],
   ks_address[g*KAW+:KAW],ks_read[g],ks_write[g],ks_write_data[g*24+:24],ks_read_data[g*24+:24]);
 end endgenerate
'''
PARAMS_OLD = ''' wire [91:0] note_params={shared_valid,shared_inc,shared_ks_length,shared_ks_tuning,shared_bell};
'''

MODULES = r'''
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
// Per-voice part of a time-shared auxiliary voice: the original preset,
// envelope and KS loop plus the registers that all voices expose at once
// (ready/active for allocation, note for display, sample for the mixer).
module yinse_aux_voice_slot #(parameter integer MAX_DELAY=1024,parameter [23:0] SEED=24'h713AC5,parameter EXTERNAL_KS_MEMORY=0)(
 input wire clk,rst_n,sample_tick,start,stop,clear,
 input wire [2:0] instrument_in,input wire [6:0] note_in,input wire note_valid,
 input wire [10:0] ks_length,input wire signed [15:0] ks_tuning,
 output wire ready,active,output reg signed [23:0] sample,output wire overrun,clipped,output reg [6:0] note,
 output wire accepted_start,output reg [2:0] state,output reg [2:0] instrument,output wire [15:0] envelope,
 output reg signed [23:0] ks_previous,output reg fresh,
 input wire lane_write,input wire [2:0] lane_state,input wire lane_sample_write,
 input wire signed [23:0] lane_sample,input wire lane_clipped,
 output wire [$clog2(MAX_DELAY)-1:0] ks_memory_address,
 output wire ks_memory_read,ks_memory_write,output wire [23:0] ks_memory_write_data,
 input wire [23:0] ks_memory_read_data
);
 localparam [2:0] IDLE=0,START_FRAME=6;
 reg local_overrun,local_clipped;
 wire [15:0] attack_step,decay_step,sustain_level,release_step;
 wire [4:0] unused_fx_ctrl;wire unused_preset_valid;
 yinse_preset preset(instrument,attack_step,decay_step,sustain_level,release_step,unused_fx_ctrl,unused_preset_valid);
 assign accepted_start=start && note_valid && instrument_in>=1 && instrument_in<=4;
 yinse_envelope env(clk,rst_n,sample_tick,accepted_start,stop,clear,
 attack_step,decay_step,sustain_level,release_step,envelope,active);
 wire signed [23:0] ks_sample;wire ks_busy,ks_overrun,ks_clipped;
 yinse_ks_loop_core #(.MAX_DELAY(MAX_DELAY),.SEED(SEED),.EXTERNAL_MEMORY(EXTERNAL_KS_MEMORY)) ks(
 clk,rst_n,sample_tick,accepted_start && instrument_in==3,clear || (accepted_start && instrument_in!=3),
 active && instrument==3,ks_length,ks_tuning,ks_sample,ks_busy,ks_overrun,ks_clipped,
 ks_memory_address,ks_memory_read,ks_memory_write,ks_memory_write_data,ks_memory_read_data);
 assign ready=state==IDLE && !ks_busy;
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
'''


def convert(s):
    if 'module yinse_aux_context_lane' in s:
        return s
    for old, new in [(LANE_OLD, LANE_NEW), (VOICE_OLD, VOICE_NEW), (PARAMS_OLD, '')]:
        assert s.count(old) == 1, old[:70]
        s = s.replace(old, new)
    return s.rstrip('\n') + '\n' + MODULES


def rewrite(path):
    raw = path.read_bytes()
    crlf = b'\r\n' in raw
    s = raw.decode('utf-8').replace('\r\n', '\n')
    t = convert(s)
    if t != s:
        path.write_bytes((t.replace('\n', '\r\n') if crlf else t).encode('utf-8'))
        print('updated', path)
    else:
        print('unchanged', path)


if __name__ == '__main__':
    root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).resolve().parents[1]
    rewrite(root / 'src/instruments/gongyong/yinse_aux_bank.sv')
