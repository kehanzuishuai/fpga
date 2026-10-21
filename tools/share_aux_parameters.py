"""Explicitly share stateless note/ratio calculations; keep the public voice interface."""
from pathlib import Path
import shutil
R=Path(__file__).resolve().parents[1];D=R/'src/instruments';O=R/'tests/remote_music_20261019/out/pre_share'
if O.exists():raise RuntimeError('Preserve existing pre-share snapshot; do not run twice')
shutil.copytree(D,O)
p=D/'gongyong/yinse_aux_voice.sv';s=p.read_text()
s=s.replace('module yinse_aux_voice #(','module yinse_aux_voice_shared #(')
s=s.replace('output wire overrun,output wire clipped,output reg [6:0] note\n','output wire overrun,output wire clipped,output reg [6:0] note,\n input wire [91:0] note_params\n')
a=s.index(' wire [31:0] note_increment');b=s.index(' wire [15:0] attack_step',a)
s=s[:a]+''' wire [31:0] note_increment,bell_load_increment;
 reg [31:0] bell_increment;
 wire [10:0] ks_length;wire signed [15:0] ks_tuning;wire note_valid;
 assign {note_valid,note_increment,ks_length,ks_tuning,bell_load_increment}=note_params;
'''+s[b:]
wrapper='''`default_nettype none
// Public standalone interface. A bank instead instantiates the shared-input
// core below so all voices use one stateless note table and ratio calculation.
module yinse_aux_voice #(parameter integer MAX_DELAY=1024,parameter [23:0] SEED=24'h713AC5)(
 input wire clk,rst_n,sample_tick,start,stop,clear,
 input wire [2:0] instrument_in,input wire [6:0] note_in,input wire [7:0] velocity_in,
 output wire ready,active,output wire signed [23:0] sample,
 output wire overrun,clipped,output wire [6:0] note
);
 wire [31:0] increment,bell_increment;wire [10:0] length,ks_length;
 wire signed [15:0] tuning,ks_tuning;wire valid;
 yinse_note_table table_lut(note_in,increment,length,tuning,valid);
 yinse_ks_tuning kt(length,tuning,ks_length,ks_tuning);
 yinse_bell_profile bell(increment,bell_increment);
 yinse_aux_voice_shared #(.MAX_DELAY(MAX_DELAY),.SEED(SEED)) core(
  clk,rst_n,sample_tick,start,stop,clear,instrument_in,note_in,velocity_in,
  ready,active,sample,overrun,clipped,note,{valid,increment,ks_length,ks_tuning,bell_increment});
endmodule
'''
p.write_text(wrapper+s)
p=D/'gongyong/yinse_aux_bank.sv';s=p.read_text()
marker=' wire [VOICES*24-1:0] samples;'
assert marker in s
s=s.replace(marker,marker+'''
 // Only the request is shared. Each voice captures its own parameters on start.
 wire [31:0] shared_inc,shared_bell;wire [10:0] shared_length,shared_ks_length;
 wire signed [15:0] shared_tuning,shared_ks_tuning;wire shared_valid;
 yinse_note_table shared_table(event_note,shared_inc,shared_length,shared_tuning,shared_valid);
 yinse_ks_tuning shared_kt(shared_length,shared_tuning,shared_ks_length,shared_ks_tuning);
 yinse_bell_profile shared_ratio(shared_inc,shared_bell);
 wire [91:0] note_params={shared_valid,shared_inc,shared_ks_length,shared_ks_tuning,shared_bell};''')
s=s.replace('yinse_aux_voice #(','yinse_aux_voice_shared #(')
assert 'notes[g*7 +: 7]);' in s
s=s.replace('notes[g*7 +: 7]);','notes[g*7 +: 7],note_params);')
p.write_text(s)
print('Explicit shared note/KS/bell request parameters; public voice interface preserved')
