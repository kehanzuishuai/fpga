"""Exhaust live 16-bit numbers and critical XY quantization inputs."""
from pathlib import Path
import subprocess,json,hashlib
R=Path(__file__).resolve().parents[2];O=Path(__file__).resolve().parent/'out'
original=Path(__file__).resolve().parent/'resource/core_optimized/visual_xy_plot.sv'
receipt=json.loads((R/'audit/display_integration_20261021/IMPORT.json').read_text())
assert hashlib.sha256(original.read_bytes()).hexdigest()==receipt['imported_rtl']['visual_xy_plot.sv']
(O/'visual_xy_plot_reference.sv').write_text(original.read_text().replace('module visual_xy_plot','module visual_xy_plot_reference'))
tb='''`timescale 1ns/1ps
module tb_math_equivalence;
 visual_labels labels(.x(12'd0),.y(12'd0),.status_live(1'b0),.status_data(512'd0),.clk(1'b0));
 visual_labels_reference gold_labels(.x(12'd0),.y(12'd0),.status_live(1'b0),.status_data(512'd0));
 visual_xy_plot #(.COORD_BITS(8),.SPAN(256)) xy(.clk(1'b0),.rst_n(1'b0));
 visual_xy_plot_reference #(.COORD_BITS(8),.SPAN(256)) gold_xy(.clk(1'b0),.rst_n(1'b0));
 integer v,p,s,n,seed=123;reg signed [16:0] value;reg signed [5:0] shift;
 initial begin
  #1;
  for(v=0;v<65536;v=v+1)for(p=0;p<5;p=p+1)begin
   if(labels.decimal(v,p)!==gold_labels.decimal(v,p))$fatal(1,"decimal %0d %0d",v,p);
   if(labels.decimal_trim(v,p)!==gold_labels.decimal_trim(v,p))$fatal(1,"trim %0d %0d",v,p);
  end
  for(v=36;v<=96;v=v+1)for(p=0;p<3;p=p+1)
   if(labels.note_char(v,p)!==gold_labels.note_char(v,p))$fatal(1,"MIDI label %0d %0d",v,p);
  for(v=-65536;v<=65535;v=v+1)begin
   for(p=0;p<3;p=p+1)begin
    s=p==0?-5:p==1?0:11;
    if(xy.coordinate(v,s)!==gold_xy.coordinate(v,s))$fatal(1,"XY %0d shift %0d",v,s);
   end
  end
  for(n=0;n<10000;n=n+1)begin
   value=$random(seed);shift=$random(seed);
   if(xy.coordinate(value,shift)!==gold_xy.coordinate(value,shift))$fatal(1,"XY random");
  end
  $display("PASS all 65536 live numbers x 5 places; MIDI36..96 labels; 393216 full-range XY values at shifts -5/0/11 plus 10000 random shifts");$finish;
 end
endmodule
'''
(O/'tb_math_equivalence.sv').write_text(tb)
iv=Path('D:/gaoyun/piano_v2/codex_test/tools/iverilog/bin/iverilog.exe')
src=[R/'src/display/visual_labels.sv',O/'visual_labels_reference.sv',R/'src/display/visual_xy_plot.sv',O/'visual_xy_plot_reference.sv',O/'tb_math_equivalence.sv']
for name,args in [('math_equivalence_compile',[iv,'-g2012','-s','tb_math_equivalence','-o',O/'math_equivalence.vvp',*src]),
 ('math_equivalence',[iv.with_name('vvp.exe'),O/'math_equivalence.vvp'])]:
 p=subprocess.run([str(x) for x in args],cwd=R,capture_output=True,text=True,timeout=180)
 (O/(name+'.log')).write_text(p.stdout+p.stderr)
 if p.returncode:raise RuntimeError(p.stdout+p.stderr)
 print(p.stdout[-1800:],flush=True)
(O/'MATH_EQUIVALENCE.json').write_text(json.dumps({'status':'PASS',
 'source_sha256':{str(p.relative_to(R)):hashlib.sha256(p.read_bytes()).hexdigest() for p in src}},indent=2))
