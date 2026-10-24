"""Recheck the pre-integration bounded encoder against the imported integer RTL."""
from pathlib import Path
import subprocess,json,hashlib
R=Path(__file__).resolve().parents[2];O=Path(__file__).resolve().parent/'out'
old=R/'audit/display_integration_20261021/timing_repair/visual_tmds.imported_integer.sv'
# Match combinational hardware at time0 even when the first byte stays0.
(O/'integer_tmds.sv').write_text(old.read_text().replace('module visual_tmds(','module integer_tmds(').replace('always @* begin','always_comb begin'))
tb='''`timescale 1ns/1ps
module tb_tmds_equivalence;
 reg clk=0,rst=0,de=0;reg [1:0] control=0;reg [7:0] data=0;always #5 clk=~clk;
 wire [9:0] actual,reference;
 visual_tmds dut(clk,rst,de,control,data,actual);
 integer_tmds gold(clk,rst,de,control,data,reference);
 integer i,rd,n=0;reg [31:0] rng=32'h98765432;
 task check;begin
  @(posedge clk);#1;
  if(actual!==reference || integer'($signed(dut.disparity))!==gold.disparity)$fatal(1,"TMDS mismatch data%h rd%0d symbols%h/%h next%0d/%0d",data,rd,actual,reference,$signed(dut.disparity),gold.disparity);
  if($signed(dut.disparity)< -8 || $signed(dut.disparity)>8)$fatal(1,"TMDS bound");n=n+1;
 end endtask
 initial begin
  #1;rst=1;#1;rst=0;repeat(3)@(negedge clk);rst=1;
  for(rd=-8;rd<=8;rd=rd+2)for(i=0;i<256;i=i+1)begin
   @(negedge clk);dut.disparity=6'(rd);gold.disparity=rd;de=1;data=8'(i);check;
  end
  for(i=0;i<65536;i=i+1)begin
   @(negedge clk);rng={rng[30:0],rng[31]^rng[21]^rng[1]^rng[0]};data=rng[7:0];de=i%257>3;control=2'(i);check;
  end
  @(negedge clk);rst=0;#1;if(actual!==reference)$fatal(1,"TMDS reset");
  $display("PASS TMDS all9 reachable disparity states x256 data,65536 continuous/control words and reset: %0d exact symbols/disparity",n);$finish;
 end
endmodule
'''
(O/'tb_tmds_equivalence.sv').write_text(tb)
files=[R/'src/display/visual_tmds.sv',O/'integer_tmds.sv',O/'tb_tmds_equivalence.sv']
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
before={p.relative_to(R).as_posix():sha(p) for p in files}
iv=Path('D:/gaoyun/piano_v2/codex_test/tools/iverilog/bin/iverilog.exe')
for name,args in [('tmds_equivalence_compile',[iv,'-g2012','-s','tb_tmds_equivalence','-o',O/'tmds_equivalence.vvp',*files]),('tmds_equivalence',[iv.with_name('vvp.exe'),O/'tmds_equivalence.vvp'])]:
 p=subprocess.run(list(map(str,args)),cwd=R,capture_output=True,text=True,timeout=90)
 (O/(name+'.log')).write_text(p.stdout+p.stderr)
 if p.returncode:raise RuntimeError((p.stdout+p.stderr)[-2500:])
 print(p.stdout.strip(),flush=True)
assert before=={p.relative_to(R).as_posix():sha(p) for p in files},'Inputs changed'
(O/'TMDS_EQUIVALENCE.json').write_text(json.dumps({'status':'PASS','exhaustive_state_data_pairs':2304,'continuous_control_words':65536,'restored_pre_integration_encoder':True,'files':before},indent=2))
