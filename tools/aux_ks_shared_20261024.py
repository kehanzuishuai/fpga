"""Share one Karplus-Strong datapath among the 32 auxiliary voices.

Before (after aux_context_ram_20261023): every voice slot carried a complete
yinse_ks_loop_core (two-tap loss filter, 32x16 tuning multiply, clamps) that
worked only on guitar notes and only for 5 clocks after each sample tick.
After: each voice keeps the KS registers that hold its string (pointer, length,
coefficient, w, output sample) and its own noise filler; one bank-level engine
visits the pending voices in index order, 6 clocks each (<= 192 of 256), using
the same arithmetic, RAM ports and read timing as before.

Why the outputs stay identical:
* A guitar voice whose KS is processed at a tick also starts its oscillator
  context at that tick; the context needs at least 17 clocks, so the original
  5-clock KS busy window never changed `ready`. The KS busy that remains
  visible to the allocator is the note-on noise fill, kept per voice unchanged.
* The KS output sample is only consumed when the voice latches it at the next
  sample tick, and the engine finishes every pending voice before that tick.
* A note-on or clear that reaches a voice before the engine does cancels that
  voice's pending update; the note-on resets pointer, w and sample and refills
  the whole active delay line, exactly the state the original reached.
Only the timing of the unused per-voice KS overrun/clipped flags can differ.
Idempotent.
"""
from pathlib import Path
import re
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))
from aux_context_ram_20261023 import MODULES as CONTEXT_MODULES  # noqa: E402

OLD_SLOT = CONTEXT_MODULES[CONTEXT_MODULES.index('`default_nettype none\n// Per-voice part of a time-shared'):]

NEW_SLOT = r'''`default_nettype none
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
'''

VOICE_OLD = '''   lane_sample[(g/THREADS)*24+:24],lane_clipped[g/THREADS],
   ks_address[g*KAW+:KAW],ks_read[g],ks_write[g],ks_write_data[g*24+:24],ks_read_data[g*24+:24]);
 end endgenerate
'''
VOICE_NEW = '''   lane_sample[(g/THREADS)*24+:24],lane_clipped[g/THREADS],
   ks_pending[g],ks_ptrs[g*KAW+:KAW],ks_lengths[g*11+:11],ks_coefficients[g*16+:16],ks_ws[g*24+:24],
   engine_read[g],engine_write[g],engine_address,engine_data,engine_w,engine_sample,engine_ptr,engine_clipped,
   ks_address[g*KAW+:KAW],ks_read[g],ks_write[g],ks_write_data[g*24+:24],ks_read_data[g*24+:24]);
 end endgenerate
 yinse_ks_engine #(.VOICES(VOICES),.KAW(KAW)) ks_engine(clk,rst_n,all_notes_off,ks_pending,accepted,
  ks_ptrs,ks_lengths,ks_coefficients,ks_ws,ks_read_data,engine_read,engine_write,
  engine_address,engine_data,engine_w,engine_sample,engine_ptr,engine_clipped);
'''
DECL_ANCHOR = ''' genvar g;
 generate for(g=0;g<VOICES;g=g+1)begin:G
  yinse_aux_voice_slot'''
DECL_NEW = ''' // One shared Karplus-Strong datapath; per-voice string registers stay in the slots.
 wire [VOICES-1:0] ks_pending,engine_read,engine_write;
 wire [VOICES*KAW-1:0] ks_ptrs;wire [VOICES*11-1:0] ks_lengths;wire [VOICES*16-1:0] ks_coefficients;
 wire [VOICES*24-1:0] ks_ws;wire [KAW-1:0] engine_address,engine_ptr;wire [23:0] engine_data;
 wire signed [23:0] engine_w,engine_sample;wire engine_clipped;
 genvar g;
 generate for(g=0;g<VOICES;g=g+1)begin:G
  yinse_aux_voice_slot'''


def convert(s):
    if 'module yinse_ks_engine' in s:
        return s
    assert s.count(OLD_SLOT) == 1, 'context-RAM slot module not found verbatim'
    s = s.replace(OLD_SLOT, NEW_SLOT)
    for old, new in [(VOICE_OLD, VOICE_NEW), (DECL_ANCHOR, DECL_NEW)]:
        assert s.count(old) == 1, old[:60]
        s = s.replace(old, new)
    return s


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
