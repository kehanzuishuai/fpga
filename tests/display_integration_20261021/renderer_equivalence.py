"""Focused whole-compositor equivalence across the extra font-ROM clock."""
from pathlib import Path
import subprocess,json,hashlib,re
R=Path(__file__).resolve().parents[2];O=Path(__file__).resolve().parent/'out'
A=R/'audit/display_integration_20261021/optimization'
s=(A/'visual_renderer.before_font_rom.sv').read_text()
s=s.replace('module visual_renderer','module visual_renderer_reference')
for name in ['visual_labels','visual_scene','visual_background','visual_light_motion']:
 s=s.replace(name,name+'_reference')
(O/'visual_renderer_reference.sv').write_text(s)
extra_clocks=1+int(re.search(r'localparam SCENE_LATENCY=(\d+)',(R/'src/display/visual_renderer.sv').read_text())[1])
tb='''`timescale 1ns/1ps
module tb_renderer_equivalence;
 GSR GSR(.GSRI(1'b1));reg clk=0,rst=0;reg [11:0] x=0,y=0;reg de=0,hs=0,vs=0;
 reg [511:0] status=0;reg live=0;wire [26:0] actual,reference;
 wire [8:0] wa,ref_wa;wire [9:0] sa,ref_sa;wire wr,sr,ref_wr,ref_sr;
 visual_renderer dut(clk,rst,x,y,de,hs,vs,1'b0,1'b0,1'b0,49'd0,37'd0,
  wa,sa,wr,sr,actual[26:19],actual[18:11],actual[10:3],actual[2],actual[1],actual[0],live,status);
 visual_renderer_reference gold(clk,rst,x,y,de,hs,vs,1'b0,1'b0,1'b0,49'd0,37'd0,
  ref_wa,ref_sa,ref_wr,ref_sr,reference[26:19],reference[18:11],reference[10:3],reference[2],reference[1],reference[0],live,status);
 localparam EXTRA_CLOCKS=__EXTRA_CLOCKS__;
 integer i,k,j,seed=1729;reg [26:0] previous[0:EXTRA_CLOCKS-1];
 initial begin
  #1;rst=1;#1;rst=0;#3;clk=1;#3;clk=0;rst=1;
  for(i=0;i<1024;i=i+1)begin dut.wave[i]=16'(i*1337);gold.wave[i]=16'(i*1337);end
  for(i=0;i<512;i=i+1)begin dut.spectrum[i]=8'(i%109);gold.spectrum[i]=8'(i%109);end
  dut.phase_row=0;gold.phase_row=0;
  force dut.initialized=1;force gold.initialized=1;
  force dut.wave_initialized=1;force gold.wave_initialized=1;
  force dut.peak_hz=16'd4867;force gold.peak_hz=16'd4867;
  force dut.peak_valid=1;force gold.peak_valid=1;
  for(i=0;i<2048;i=i+1)begin
   for(k=0;k<16;k=k+1)status[k*32+:32]=$random(seed);
   status[456+:2]=2'(i%3);status[490+:3]=3'(i%8);live=(i%7)!=0;
   x=12'($unsigned($random(seed))%2200);y=12'($unsigned($random(seed))%1125);
   de=x<1920 && y<1080;hs=i%13==0;vs=i%71==0;
   #5;for(j=EXTRA_CLOCKS-1;j>0;j=j-1)previous[j]=previous[j-1];previous[0]=reference;clk=1;#5;
   if(i>EXTRA_CLOCKS+6 && actual!==previous[EXTRA_CLOCKS-1])$fatal(1,"compositor pixel/sync mismatch i=%0d xy=%0d,%0d actual=%h previous=%h",i,x,y,actual,previous[EXTRA_CLOCKS-1]);
   clk=0;
  end
  $display("PASS 2048 compositor RGB+DE/HS/VS comparisons against exact original, aligned by %0d clocks; waveform/FFT/envelope/key/text paths enabled",EXTRA_CLOCKS);$finish;
 end
endmodule
'''.replace('__EXTRA_CLOCKS__',str(extra_clocks))
(O/'tb_renderer_equivalence.sv').write_text(tb)
iv=Path('D:/gaoyun/piano_v2/codex_test/tools/iverilog/bin/iverilog.exe')
src=[R/'src/display'/s for s in ['visual_renderer.sv','visual_scene.sv','visual_labels.sv','visual_background.sv','visual_xy_plot.sv']]
src.extend(O/s for s in ['visual_renderer_reference.sv','visual_scene_reference.sv','visual_labels_reference.sv','visual_background_reference.sv','tb_renderer_equivalence.sv'])
src.append(Path('C:/Gowin2/Gowin_V1.9.12_x64/IDE/simlib/gw5a/prim_sim.v'))
source_hashes={str(p.relative_to(R)):hashlib.sha256(p.read_bytes()).hexdigest() for p in src if p.is_relative_to(R)}
for name,args in [('renderer_equivalence_compile',[iv,'-g2012','-s','tb_renderer_equivalence','-o',O/'renderer_equivalence.vvp',*src]),
 ('renderer_equivalence',[iv.with_name('vvp.exe'),O/'renderer_equivalence.vvp'])]:
 p=subprocess.run([str(x) for x in args],cwd=R,capture_output=True,text=True,timeout=240)
 (O/(name+'.log')).write_text(p.stdout+p.stderr)
 if p.returncode:raise RuntimeError(p.stdout+p.stderr)
 print(p.stdout[-1800:],flush=True)
assert all(hashlib.sha256((R/p).read_bytes()).hexdigest()==h for p,h in source_hashes.items()),'Source changed during verification; result is historical'
(O/'RENDERER_EQUIVALENCE.json').write_text(json.dumps({'status':'PASS','samples':2048,'extra_clocks':extra_clocks,
 'files':source_hashes},indent=2))
