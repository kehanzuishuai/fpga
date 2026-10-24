"""Verify prefix negation and both staged constant divisions against arithmetic."""
from pathlib import Path
import subprocess,json,hashlib
R=Path(__file__).resolve().parents[1];A=R/'audit/routing_followup_20261022/display_arithmetic';O=A/'verification';O.mkdir(exist_ok=True)
(O/'tb.sv').write_text('''`timescale 1ns/1ps
module tb;
reg[26:0] v27=0;reg[15:0] v16=0;reg negative=0;wire[26:0] q27;wire[15:0] q16;
visual_conditional_negate #(.WIDTH(27),.GROUP_BITS(6)) a(v27,negative,q27);
visual_conditional_negate #(.WIDTH(16),.GROUP_BITS(4)) b(v16,negative,q16);
wire[23:0] rgb;
visual_scene scene(12'd0,12'd0,1'b0,512'd0,rgb,10'sd0,10'sd0,96'd0,24'd0,24'd0,1'b0);
reg[26:0] expected27;reg[15:0] expected16;integer i,k,seed=761982;
initial begin
 for(i=0;i<2048;i=i+1)if(scene.div13_finish(scene.div13_seed(6'(i>>5)),5'(i))!==8'(i/13))$fatal(1,"divide13 %0d",i);
 for(i=0;i<1024;i=i+1)if(scene.div5_finish(scene.div5_seed(5'(i>>5)),5'(i))!==8'(i/5))$fatal(1,"divide5 %0d",i);
 for(i=0;i<65536;i=i+1)begin
  v16=16'(i);v27=$random(seed);
  for(k=0;k<2;k=k+1)begin
   negative=k!=0;expected27=negative?-v27:v27;expected16=negative?-v16:v16;#1;
   if(q27!==expected27 || q16!==expected16)$fatal(1,"prefix negation mismatch v27%h sign%b new%h old%h",v27,negative,q27,expected27);
  end
 end
 for(i=0;i<27;i=i+1)begin
  v27=27'd1<<i;negative=1;expected27=-v27;#1;if(q27!==expected27)$fatal(1,"walking1");
  v27=~(27'd1<<i);expected27=-v27;#1;if(q27!==expected27)$fatal(1,"walking0");
 end
 $display("PASS all2048 divide13 and1024 divide5 inputs;131072 full16-bit sign-restoration cases;131126 27-bit negation cases with walking extremes");$finish;
end
endmodule
''')
iv=Path('D:/gaoyun/piano_v2/codex_test/tools/iverilog/bin/iverilog.exe')
files=[R/'src/display/visual_renderer.sv',R/'src/display/visual_scene.sv',O/'tb.sv']
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();inputs={str(p.relative_to(R)):sha(p) for p in files}
for label,cmd in [('compile',[iv,'-g2012','-s','tb','-o',O/'arithmetic.vvp',*files]),('simulation',[iv.with_name('vvp.exe'),O/'arithmetic.vvp'])]:
    with (O/(label+'.log')).open('w') as f:p=subprocess.run([str(x) for x in cmd],cwd=R,stdout=f,stderr=subprocess.STDOUT,timeout=120)
    out=(O/(label+'.log')).read_text(errors='replace');print(out[-1400:],flush=True);assert p.returncode==0,(label,out[-3000:])
assert all(sha(R/n)==h for n,h in inputs.items())
(O/'RESULT.json').write_text(json.dumps(dict(status='PASS',scope='Actual RTL helper outputs versus original unary minus and constant division, no extra pipeline clock.',inputs=inputs,programming=False),indent=2))
