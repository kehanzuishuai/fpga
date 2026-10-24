"""Check32-context memory wiring against original bank, without long audio regression."""
from pathlib import Path
import subprocess,json,hashlib
R=Path(__file__).resolve().parents[1];A=R/'audit/routing_followup_20261022/packed_ks';O=A/'bank_verification';O.mkdir(exist_ok=True)
old=A/'before/src/instruments/gongyong/yinse_aux_bank.sv'
(O/'bank_before.sv').write_text(old.read_text().replace('module yinse_aux_bank','module bank_before',1))
(O/'tb.sv').write_text('''`timescale 1ns/1ps
module tb;
GSR GSR(.GSRI(1'b1));reg clk=0,rst_n=0,tick=0,clear=0,ev=0,on=1;always #5 clk=~clk;
integer cycles=0;always @(negedge clk)begin cycles=cycles+1;tick=cycles%256==0;end
reg[2:0] inst=3;reg[6:0] note=60;reg[7:0] vel=100;
wire ra,rb,va,vb,ja,jb;wire[31:0] aa,ab,oa,ob,ca,cb;wire[23:0] a,b;wire[223:0] notes_a,notes_b;
yinse_aux_bank #(.VOICES(32),.MIX_SHIFT(3)) actual(clk,rst_n,tick,clear,ev,on,inst,note,vel,ra,a,va,aa,oa,ca,ja,notes_a);
bank_before #(.VOICES(32),.MIX_SHIFT(3)) original(clk,rst_n,tick,clear,ev,on,inst,note,vel,rb,b,vb,ab,ob,cb,jb,notes_b);
integer checked=0,n,k,frames,cases;reg[31:0] heard=0;
always @(posedge clk)begin #1;if(rst_n)begin
 if({ra,va,ja,aa,oa,ca,a,notes_a}!=={rb,vb,jb,ab,ob,cb,b,notes_b})$fatal(1,"bank mismatch cycle%0d inst%0d PCM%h/%h active%h/%h",cycles,inst,a,b,aa,ab);
 if(|oa || ja || ^a===1'bx)$fatal(1,"overrun/rejection/unknown PCM");
 checked=checked+1;
end end
task event_note(input bit yes,input integer pitch);begin
 @(negedge clk);ev=0;note=7'(pitch);on=yes;
 while(!(ra&&rb))@(negedge clk);
 ev=1;@(negedge clk);ev=0;
end endtask
initial begin
 #1;rst_n=1;#1;rst_n=0;repeat(5)@(negedge clk);rst_n=1;
 for(cases=0;cases<4;cases=cases+1)begin
  @(negedge clk);clear=1;repeat(2)@(negedge clk);clear=0;
  inst=cases==0?3:cases==1?1:cases==2?2:4;heard=0;
  for(n=60;n<=91;n=n+1)event_note(1,n);
  frames=0;
  while(frames<(cases==0?64:8))begin
   @(posedge clk);#2;if(va)begin frames=frames+1;
    for(k=0;k<32;k=k+1)if(actual.samples[k*24+:24]!=0)heard[k]=1;
   end
  end
  if(aa!=32'hffffffff || heard!=32'hffffffff)$fatal(1,"missing voice inst%0d heard%h",inst,heard);
  for(n=60;n<=91;n=n+1)event_note(0,n);
  event_note(1,60);event_note(1,91);repeat(512)@(negedge clk);
  $display("PASS packed bank instrument%0d:32 voices heard, PCM/control cycle exact",inst);$fflush();
 end
 $display("PASS %0d packed32-bank cycle comparisons, all4 auxiliary instruments and32 voices retained",checked);$finish;
end
initial begin #1000000;$fatal(1,"timeout");end
endmodule
''')
iv=Path('D:/gaoyun/piano_v2/codex_test/tools/iverilog/bin/iverilog.exe')
files=list((R/'src/instruments').rglob('*.sv'))+[O/'bank_before.sv',O/'tb.sv',Path('C:/Gowin2/Gowin_V1.9.12_x64/IDE/simlib/gw5a/prim_sim.v')]
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();inputs={str(p):sha(p) for p in files}
for label,cmd in [('compile',[iv,'-g2012','-s','tb','-o',O/'bank.vvp',*files]),('simulation',[iv.with_name('vvp.exe'),O/'bank.vvp'])]:
    with (O/(label+'.log')).open('w') as f:p=subprocess.run([str(x) for x in cmd],cwd=R,stdout=f,stderr=subprocess.STDOUT,timeout=240)
    out=(O/(label+'.log')).read_text(errors='replace');print(out[-1400:],flush=True);assert p.returncode==0,(label,out[-3000:])
assert all(sha(Path(n))==h for n,h in inputs.items())
(O/'RESULT.json').write_text(json.dumps(dict(status='PASS',scope='All32 contexts, each4 auxiliary instruments, every-cycle PCM/control versus original independent-RAM bank. No waveform coefficient changes.',inputs=inputs,programming=False),indent=2))
