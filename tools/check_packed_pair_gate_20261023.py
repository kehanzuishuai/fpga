"""Check the actual three-BSRAM synthesized pair against its RTL read ports."""
from pathlib import Path
import re,subprocess,json,hashlib
R=Path(__file__).resolve().parents[1];A=R/'audit/routing_followup_20261022/packed_ks';O=A/'pair_gate';O.mkdir(exist_ok=True)
vg=A/'resource_pair/impl/gwsynthesis/probe.vg';s=vg.read_text();modules=re.findall(r'^module (\w+)',s,re.M)
s=re.sub(r'\b(?:'+ '|'.join(re.escape(n) for n in modules)+r')\b',lambda m:'gate_'+m[0],s);(O/'gate.v').write_text(s)
(O/'tb.sv').write_text('''`timescale 1ns/1ps
module tb;
GSR GSR(.GSRI(1'b1));reg clk=0;always #5 clk=~clk;
reg[9:0] aa=0,ab=0;reg ra=0,rb=0,wa=0,wb=0;reg[23:0] da=0,db=0;
wire[23:0] qa,qb,ga,gb;
yinse_ks_ram_pair rtl(clk,aa,ra,wa,da,qa,ab,rb,wb,db,qb);
gate_yinse_ks_ram_pair mapped(clk,aa,ra,wa,da,ga,ab,rb,wb,db,gb);
integer i,seed=88231,checked=0;
always @(posedge clk)begin #1;
 if(ra && qa!==ga)$fatal(1,"mapped portA mismatch address%0d rtl%h gate%h",aa,qa,ga);
 if(rb && qb!==gb)$fatal(1,"mapped portB mismatch address%0d rtl%h gate%h",ab,qb,gb);
 if(ra)checked=checked+1;if(rb)checked=checked+1;
end
initial begin
 repeat(5)@(negedge clk);
 for(i=0;i<1024;i=i+1)begin
  aa=10'(i);ab=10'(1023-i);wa=1;wb=1;da=$random(seed);db=$random(seed);@(negedge clk);
 end
 wa=0;wb=0;ra=1;rb=1;
 for(i=0;i<1024;i=i+1)begin aa=10'(i);ab=10'(1023-i);@(negedge clk);end
 for(i=0;i<4096;i=i+1)begin
  aa=$random(seed);ab=$random(seed);wa=i%2==0;wb=i%3==0;ra=!wa;rb=!wb;
  da=$random(seed);db=$random(seed);@(negedge clk);
 end
 $display("PASS actual three-BSRAM gate pair: %0d synchronous read comparisons, both1024-address half-banks and asymmetric concurrent writes",checked);$finish;
end
endmodule
''')
iv=Path('D:/gaoyun/piano_v2/codex_test/tools/iverilog/bin/iverilog.exe')
files=[R/'src/instruments/gongyong/yinse_aux_bank.sv',O/'gate.v',O/'tb.sv',Path('C:/Gowin2/Gowin_V1.9.12_x64/IDE/simlib/gw5a/prim_sim.v')]
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();inputs={str(p):sha(p) for p in files}
for label,cmd in [('compile',[iv,'-g2012','-s','tb','-o',O/'gate.vvp',*files]),('simulation',[iv.with_name('vvp.exe'),O/'gate.vvp'])]:
    with (O/(label+'.log')).open('w') as f:p=subprocess.run([str(x) for x in cmd],cwd=R,stdout=f,stderr=subprocess.STDOUT,timeout=120)
    out=(O/(label+'.log')).read_text(errors='replace');print(out[-1100:],flush=True);assert p.returncode==0,(label,out[-3000:])
assert all(sha(Path(n))==h for n,h in inputs.items())
(O/'RESULT.json').write_text(json.dumps(dict(status='PASS',scope='Actual mapped three-block pair versus RTL; registered read latency and independent half-bank address/write behavior.',netlist_sha256=sha(vg),inputs=inputs,programming=False),indent=2))
