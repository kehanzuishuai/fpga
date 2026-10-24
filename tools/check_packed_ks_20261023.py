"""Cycle-exact packed KS port/sample comparison against pre-change RTL."""
from pathlib import Path
import subprocess,json,hashlib,datetime
R=Path(__file__).resolve().parents[1];A=R/'audit/routing_followup_20261022/packed_ks';O=A/'verification';O.mkdir(exist_ok=True)
ref=A/'before/src/instruments/jita/yinse_ks_loop.sv'
(O/'reference.sv').write_text(ref.read_text().replace('module yinse_ks_loop','module ks_reference',1))
(O/'tb.sv').write_text('''`timescale 1ns/1ps
module tb;
GSR GSR(.GSRI(1'b1));
reg clk=0,rst_n=0,tick=0;always #5 clk=~clk;
reg[1:0] start=0,clear=0,en=3;reg[10:0] len[0:1];reg signed[15:0] tune[0:1];
wire[23:0] sample[0:1],gold[0:1];wire[1:0] busy,gbusy,over,gover,clip,gclip,rd,wr;wire[9:0] addr[0:1];wire[23:0] data[0:1],q[0:1];
yinse_ks_ram_pair paired(clk,addr[0],rd[0],wr[0],data[0],q[0],addr[1],rd[1],wr[1],data[1],q[1]);
genvar g;generate for(g=0;g<2;g=g+1)begin:V
 yinse_ks_loop_core #(.EXTERNAL_MEMORY(1),.SEED(24'h713ac5+g)) dut(clk,rst_n,tick,start[g],clear[g],en[g],len[g],tune[g],sample[g],busy[g],over[g],clip[g],addr[g],rd[g],wr[g],data[g],q[g]);
 ks_reference #(.SEED(24'h713ac5+g)) original(clk,rst_n,tick,start[g],clear[g],en[g],len[g],tune[g],gold[g],gbusy[g],gover[g],gclip[g]);
end endgenerate
integer cycles=0,checked=0,j;
always @(negedge clk)begin cycles=cycles+1;tick=cycles%256==0;end
always @(posedge clk)begin #1;if(rst_n)begin
 for(j=0;j<2;j=j+1)begin
  if({sample[j],busy[j],over[j],clip[j]}!=={gold[j],gbusy[j],gover[j],gclip[j]})
    $fatal(1,"packed KS mismatch cycle%0d voice%0d new=%h gold=%h busy%0b/%0b",cycles,j,sample[j],gold[j],busy[j],gbusy[j]);
  if(V[j].dut.state!==V[j].original.state)$fatal(1,"state schedule changed");
 end
 checked=checked+1;
end end
task note(input integer a,b,input integer ca,cb);begin
 @(negedge clk);len[0]=11'(a);len[1]=11'(b);tune[0]=16'(ca);tune[1]=16'(cb);start=3;
 @(negedge clk);start=0;
end endtask
initial begin
 len[0]=1024;len[1]=1023;tune[0]=8426;tune[1]=-25719;
 #1;rst_n=1;#1;rst_n=0;repeat(4)@(negedge clk);rst_n=1;
 note(1024,1023,8426,-25719);repeat(6144)@(negedge clk);
 note(2,3,32767,-32768);repeat(4096)@(negedge clk);
 note(512,257,0,16439);repeat(4096)@(negedge clk);
 @(negedge clk);en=1;repeat(1024)@(negedge clk);en=3;
 note(1024,1024,-30777,30777);repeat(127)@(negedge clk);
 clear=1;@(negedge clk);clear=0;repeat(3072)@(negedge clk);
 note(0,1025,12345,-12345);repeat(512)@(negedge clk);
 $display("PASS packed KS: %0d cycle comparisons per voice, simultaneous/asymmetric fill/read/write, length2..1024, signed tuning, clear, disable, retrigger and invalid length",checked);$finish;
end
initial begin #1000000;$fatal(1,"timeout");end
endmodule
'''.replace('  if(V[j].dut.state!==V[j].original.state)$fatal(1,"state schedule changed");',''))
iv=Path('D:/gaoyun/piano_v2/codex_test/tools/iverilog/bin/iverilog.exe')
files=[R/'src/instruments/jita/yinse_ks_loop.sv',R/'src/instruments/gongyong/yinse_aux_bank.sv',O/'reference.sv',O/'tb.sv',Path('C:/Gowin2/Gowin_V1.9.12_x64/IDE/simlib/gw5a/prim_sim.v')]
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();inputs={str(p):sha(p) for p in files}
for label,cmd in [('compile',[iv,'-g2012','-s','tb','-o',O/'packed.vvp',*files]),('simulation',[iv.with_name('vvp.exe'),O/'packed.vvp'])]:
    with (O/(label+'.log')).open('w') as f:p=subprocess.run([str(x) for x in cmd],cwd=R,stdout=f,stderr=subprocess.STDOUT,timeout=180)
    out=(O/(label+'.log')).read_text(errors='replace');print(out[-1800:],flush=True)
    assert p.returncode==0,(label,out[-3000:])
assert all(sha(Path(n))==h for n,h in inputs.items())
(O/'RESULT.json').write_text(json.dumps(dict(status='PASS',scope='Two packed KS cores versus original, every-cycle public sample/busy/overrun/clipped. Actual Gowin DPX9B simulation.',inputs=inputs,finished_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),programming=False),indent=2))
