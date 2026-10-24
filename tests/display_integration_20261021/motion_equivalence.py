"""Exhaustively compare ROM motion with the original integer easing."""
from pathlib import Path
import subprocess,json,hashlib
R=Path(__file__).resolve().parents[2];O=Path(__file__).resolve().parent/'out'
tb='''`timescale 1ns/1ps
module tb_motion_equivalence;
 reg clk=0,rst_n=0,tick=0;wire signed [9:0] dx,dy,rx,ry;
 visual_light_motion dut(clk,rst_n,tick,dx,dy);
 visual_light_motion_reference gold(clk,rst_n,tick,rx,ry);
 integer n;reg signed [9:0] ex,ey;
 initial begin
  #1;rst_n=1;#1;rst_n=0;#1;clk=1;#1;clk=0;rst_n=1;
  for(n=0;n<9570;n=n+1)begin
   // Test both complete phase cycles many times, including wraps.
   tick=1;#1;ex=rx;ey=ry;clk=1;#1;
   if(dx!==ex || dy!==ey)$fatal(1,"motion phase %0d: %0d,%0d != %0d,%0d",n,dx,dy,ex,ey);
   clk=0;tick=0;#1;clk=1;#1;
   if(dx!==rx || dy!==ry)$fatal(1,"motion failed to settle in vertical blank %0d",n);
   clk=0;
  end
  $display("PASS 9570 exact motion phases including wraps; one-clock ROM settles in vertical blank");$finish;
 end
endmodule
'''
(O/'tb_motion_equivalence.sv').write_text(tb)
iv=Path('D:/gaoyun/piano_v2/codex_test/tools/iverilog/bin/iverilog.exe')
for name,args in [('motion_equivalence_compile',[iv,'-g2012','-s','tb_motion_equivalence','-o',O/'motion.vvp',R/'src/display/visual_scene.sv',O/'visual_scene_reference.sv',O/'tb_motion_equivalence.sv']),
 ('motion_equivalence',[iv.with_name('vvp.exe'),O/'motion.vvp'])]:
 p=subprocess.run([str(x) for x in args],cwd=R,capture_output=True,text=True,timeout=60)
 (O/(name+'.log')).write_text(p.stdout+p.stderr)
 if p.returncode:raise RuntimeError(p.stdout+p.stderr)
 print(p.stdout[-1200:],flush=True)
(O/'MOTION_EQUIVALENCE.json').write_text(json.dumps({'status':'PASS','phases':9570,'rom_latency':1,
 'files':{str(p.relative_to(R)):hashlib.sha256(p.read_bytes()).hexdigest() for p in [R/'src/display/visual_scene.sv',R/'assets/display_drift_x.hex',R/'assets/display_drift_y.hex']}},indent=2))
