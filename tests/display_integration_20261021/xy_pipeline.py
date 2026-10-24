"""Compare complete rendered XY bitmaps, independent of engine cycle count."""
from pathlib import Path
import math,json,hashlib,subprocess
R=Path(__file__).resolve().parents[2];O=Path(__file__).resolve().parent/'out'
old=R/'audit/display_integration_20261021/timing_repair/visual_xy_plot.before_pipeline.sv'
ref=O/'xy_engine_reference.sv';ref.write_text(old.read_text().replace('module visual_xy_plot','module visual_xy_plot_reference'))
frames=[]
for kind in range(3):
 for i in range(512):
  if kind==0:x=round(11000*math.cos(i*math.tau/512)+3500);y=round(6300*math.sin(i*math.tau/512)-2100);mode=1
  elif kind==1:x=32767 if i%4<2 else -32768;y=28000 if i%8<4 else -31000;mode=0
  else:x=1234;y=-1729;mode=i%2
  frames.append((mode<<32)|((x&65535)<<16)|(y&65535))
(O/'xy_frames.hex').write_text(''.join(f'{n:013x}\n' for n in frames))
tb='''`timescale 1ns/1ps
module tb_xy_pipeline;
 reg clk=0,rst_n=0,start=0,publish=0;always #5 clk=~clk;
 wire [8:0] da,ga;reg [48:0] dd=0,gd=0;reg [48:0] frames[0:1535];
 wire db,dr,gb,gr,dc,gc,dp,gp,ds,gs,dm,gm,dx,gx,dl,gl;
 wire [8:0] di,gi;wire signed [5:0] dshift,gshift;integer frame=0,cycles,j;integer copied_d=0,copied_g=0;
 visual_xy_plot #(.COORD_BITS(8),.SPAN(256)) dut(clk,rst_n,start,publish,da,dd,dl,db,dr,dc,di,16'd0,dp,ds,dm,dx,dshift);
 visual_xy_plot_reference #(.COORD_BITS(8),.SPAN(256)) gold(clk,rst_n,start,publish,ga,gd,gl,gb,gr,gc,gi,16'd0,gp,gs,gm,gx,gshift);
 always @(posedge clk)begin dd<=frames[frame*512+da];gd<=frames[frame*512+ga];if(dc)copied_d<=copied_d+1;if(gc)copied_g<=copied_g+1;end
 initial begin
  $readmemh("tests/display_integration_20261021/out/xy_frames.hex",frames);
  #1;rst_n=1;#1;rst_n=0;#10;rst_n=1;
  for(frame=0;frame<3;frame=frame+1)begin
   @(negedge clk);start=1;@(negedge clk);start=0;cycles=0;
   while(!(dr && gr) && cycles<500000)begin @(negedge clk);cycles=cycles+1;end
   if(!(dr && gr))$fatal(1,"XY timeout frame=%0d states=%0d/%0d",frame,dut.state,gold.state);
   for(j=0;j<65536;j=j+1)
    if(dut.bitmap[{dut.back,16'(j)}]!==gold.bitmap[{gold.back,16'(j)}])$fatal(1,"XY bitmap frame=%0d pixel=%0d",frame,j);
   if({dut.ready_signal,dut.ready_mode,dut.ready_mixed,dut.ready_shift}!=={gold.ready_signal,gold.ready_mode,gold.ready_mixed,gold.ready_shift})$fatal(1,"XY pending status differs frame=%0d",frame);
   publish=1;@(negedge clk);publish=0;
   if({ds,dm,dx,dshift}!=={gs,gm,gx,gshift})$fatal(1,"XY published metadata differs frame=%0d",frame);
  end
  if(copied_d!=1536 || copied_g!=1536)$fatal(1,"XY copy count differs");
  $display("PASS three exact 256x256 XY bitmaps: DC-offset ellipse, extreme jumps, silence/mixed; independent engine completion and atomic publication");$finish;
 end
endmodule
'''
(O/'tb_xy_pipeline.sv').write_text(tb)
iv=Path('D:/gaoyun/piano_v2/codex_test/tools/iverilog/bin/iverilog.exe')
inputs=[R/'src/display/visual_xy_plot.sv',ref,O/'tb_xy_pipeline.sv']
hashes={str(p.relative_to(R)):hashlib.sha256(p.read_bytes()).hexdigest() for p in inputs}
for name,args in [('xy_pipeline_compile',[iv,'-g2012','-s','tb_xy_pipeline','-o',O/'xy_pipeline.vvp',*inputs]),('xy_pipeline',[iv.with_name('vvp.exe'),O/'xy_pipeline.vvp'])]:
 p=subprocess.run([str(x) for x in args],cwd=R,capture_output=True,text=True,timeout=120)
 (O/(name+'.log')).write_text(p.stdout+p.stderr)
 if p.returncode:raise RuntimeError(p.stdout+p.stderr)
 print(p.stdout[-1200:],flush=True)
assert all(hashlib.sha256((R/p).read_bytes()).hexdigest()==h for p,h in hashes.items())
for span in [128,256]:
 bound=(span//2-1)*63;shift=(bound*62).bit_length();magic=((1<<shift)+62)//63
 assert all((n*magic)>>shift==n//63 for n in range(bound+1))
(O/'XY_ENGINE_EQUIVALENCE.json').write_text(json.dumps({'status':'PASS','frames':3,'pixels_per_frame':65536,'files':hashes},indent=2))
