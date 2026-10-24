"""Same-cycle clear/copy checks at actual65536depth, including reset/restart."""
from pathlib import Path
import hashlib,json,subprocess
R=Path(__file__).resolve().parents[2];A=R/'audit/routing_followup_20261022';O=A/'xy_clear';O.mkdir(exist_ok=True)
(O/'gold.sv').write_text((A/'v7_before/src/display/visual_xy_plot.sv').read_text().replace('module visual_xy_plot','module xy_before'))
tb='''`timescale 1ns/1ps
module tb;
 reg clk=0,rst=0,start=0;wire [8:0] da,ga;wire dl,gl,db,gb,dr,gr,dc,gc;wire [8:0] di,gi;
 visual_xy_plot #(.COORD_BITS(8),.SPAN(256)) dut(.clk(clk),.rst_n(rst),.start(start),.publish(1'b0),.sample_addr(da),.sample_data(49'd0),.sample_release(dl),.busy(db),.ready(dr),.copy_valid(dc),.copy_index(di),.pixel_addr(16'd0));
 xy_before #(.COORD_BITS(8),.SPAN(256)) gold(.clk(clk),.rst_n(rst),.start(start),.publish(1'b0),.sample_addr(ga),.sample_data(49'd0),.sample_release(gl),.busy(gb),.ready(gr),.copy_valid(gc),.copy_index(gi),.pixel_addr(16'd0));
 integer n,j,pass,cycles=0;
 task tick;begin
  #1;clk=1;#1;
  if({dut.state,dut.index,dut.clear_index,dut.primed,da,dl,db,dr,dc,di}!=={gold.state,gold.index,gold.clear_index,gold.primed,ga,gl,gb,gr,gc,gi})$fatal(1,"clear/copy cycle differs %0d",cycles);
  clk=0;cycles=cycles+1;
 end endtask
 initial begin
  #1;rst=1;#1;rst=0;tick();rst=1;
  // An interrupted clear must restart with a cleared prediction flag.
  start=1;tick();start=0;for(n=0;n<133;n=n+1)tick();rst=0;tick();rst=1;
  for(pass=0;pass<2;pass=pass+1)begin
   start=1;tick();start=0;
   for(n=0;n<65536;n=n+1)tick();
   if(dut.state!=2 || gold.state!=2)$fatal(1,"COPY did not start on original cycle");
   for(j=0;j<65536;j=j+1)if(dut.bitmap[{dut.back,16'(j)}]!==1'b0 || gold.bitmap[{gold.back,16'(j)}]!==1'b0)$fatal(1,"uncleared pixel %0d",j);
   repeat(5)tick();rst=0;tick();rst=1;
  end
  $display("PASS %0d exact cycles, two65536-address clears, last address and reset/restart",cycles);$finish;
 end
endmodule
''';(O/'tb.sv').write_text(tb)
iv=Path('D:/gaoyun/piano_v2/codex_test/tools/iverilog/bin/iverilog.exe');source=R/'src/display/visual_xy_plot.sv'
for name,args in [('compile',[iv,'-g2012','-s','tb','-o',O/'test.vvp',source,O/'gold.sv',O/'tb.sv']),('simulation',[iv.with_name('vvp.exe'),O/'test.vvp'])]:
 p=subprocess.run(list(map(str,args)),cwd=R,capture_output=True,text=True,timeout=120)
 (O/(name+'.log')).write_text(p.stdout+p.stderr)
 if p.returncode:raise RuntimeError((p.stdout+p.stderr)[-3000:])
 print(p.stdout[-1000:],flush=True)
r=dict(status='PASS',depth=65536,complete_clears=2,interrupted_reset_restart=True,source_sha256=hashlib.sha256(source.read_bytes()).hexdigest(),scope='All control/copy/clear addresses match every clock and both full back buffers are zero before COPY.',programming=False)
(O/'RESULT.json').write_text(json.dumps(r,indent=2));print(json.dumps(r,indent=2))
