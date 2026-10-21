"""One-time, exact ROM symmetry reduction; retain the unroutable attempt."""
from pathlib import Path
import re,shutil,json,hashlib
R=Path(__file__).resolve().parents[2];A=R/'audit/remote_music_20261019/routing_672_unrouted'
A.mkdir(parents=True,exist_ok=False)
paths=['impl/gwsynthesis/yinyue_fashengqi.vg','impl/pnr/yinyue_fashengqi.rpt.txt','impl/pnr/yinyue_fashengqi.pin.html','tests/remote_music_20261019/out/gowin.log','audit/remote_music_20261019/BUILD.json',
 'src/instruments/gongyong/yinse_sine_rom.sv','src/instruments/gongyong/yinse_aux_bank.sv','src/instruments/gongyong/yinse_aux_voice.sv']
for q in paths:
 d=A/q;d.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(R/q,d)
b=json.loads((R/'audit/remote_music_20261019/BUILD.json').read_text())
assert b['status']=='FAIL' and not b['outputs']['impl/pnr/yinyue_fashengqi.tr']['fresh']
b['stale_previous_timing_values']={'slacks':b['worst_slack_ns'],'violated_endpoints':b['violated_endpoints']}
b['worst_slack_ns']={k:None for k in b['worst_slack_ns']};b['violated_endpoints']={'Setup':None,'Hold':None};b['all_timing_checks_pass']=False
b['failure_reason']='PR0004: 672 unrouted nets; no fresh FS or timing report. Stale prior timing is not this build.'
(R/'audit/remote_music_20261019/BUILD.json').write_text(json.dumps(b,indent=2))
p=R/'src/instruments/gongyong/yinse_sine_rom.sv';old=p.read_text()
values={int(a):int(v,16) for a,v in re.findall(r"rom\[8'd(\d+)\]=16'h([\da-f]+)",old)}
assert len(values)==256
def quarter_value(a):
 low=a&63;index=(-low)&63 if a&64 else low
 magnitude=32767 if (a&64 and low==0) else values[index]
 return (-magnitude if a&128 else magnitude)&65535
assert all(quarter_value(a)==v for a,v in values.items())
text='''`default_nettype none
// Exact quarter-wave factorization of the original 256 signed Q1.15 words.
// No interpolation, new rounding, or sample latency is introduced.
module yinse_sine_rom(input wire [7:0] address,output wire signed [15:0] sample);
 wire [5:0] index=address[6] ? -address[5:0] : address[5:0];
 reg [14:0] rom[0:63];
 initial begin
'''
text+=''.join(f"  rom[6'd{i}]=15'h{values[i]:04x};\n" for i in range(64))
text+=''' end
 wire [15:0] magnitude=(address[6] && address[5:0]==0)?16'd32767:{1'b0,rom[index]};
 assign sample=address[7] ? -$signed(magnitude) : $signed(magnitude);
endmodule
`default_nettype wire
'''
p.write_text(text)
print('Exact all-256-word ROM symmetry verified; unroutable attempt archived')
