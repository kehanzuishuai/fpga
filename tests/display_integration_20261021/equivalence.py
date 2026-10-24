"""Compare optimized combinational pixels directly against archived delivery RTL."""
from pathlib import Path
import subprocess,json,hashlib,re
R=Path(__file__).resolve().parents[2];O=Path(__file__).resolve().parent/'out'
A=R/'audit/display_integration_20261021/optimization'
for module in ['visual_scene','visual_labels']:
 s=(A/(module+'.original.sv')).read_text().replace('module '+module,'module '+module+'_reference')
 if module=='visual_labels':s=s.replace('always @* begin\n  ch=','always_comb begin\n  ch=')
 if module=='visual_scene':s=s.replace('module visual_light_motion','module visual_light_motion_reference')
 (O/(module+'_reference.sv')).write_text(s)
latency_match=re.search(r'localparam PIPE_STAGES=(\d+)',(R/'src/display/visual_scene.sv').read_text())
latency=int(latency_match[1]) if latency_match else 0
label_match=re.search(r'localparam LABEL_LATENCY=(\d+)',(R/'src/display/visual_labels.sv').read_text())
label_latency=int(label_match[1]) if label_match else 1
tb='''`timescale 1ns/1ps
module tb_pixel_equivalence;
 reg clk=0;reg [11:0] x,y;reg live,peak,xd,xs,xm;reg [15:0] hz;
 reg signed [5:0] shift;reg [1:0] range_sel;reg [511:0] status;
 reg signed [9:0] dx,dy;reg [95:0] trails;reg [23:0] sharp,frost;
 wire [23:0] rgb,ref_rgb,lc,ref_lc;wire ink,ref_ink;wire [1:0] cv,ref_cv;
 visual_scene scene(x,y,live,status,rgb,dx,dy,trails,sharp,frost,clk);
 visual_scene_reference reference_scene(x,y,live,status,ref_rgb,dx,dy,trails,sharp,frost);
 visual_labels labels(x,y,peak,hz,xd,xs,xm,shift,ink,live,status,lc,cv,range_sel,clk);
 visual_labels_reference reference_labels(x,y,peak,hz,xd,xs,xm,shift,ref_ink,live,status,ref_lc,ref_cv,range_sel);
 localparam SCENE_LATENCY=__SCENE_LATENCY__;
 reg [23:0] expected_scene[0:SCENE_LATENCY-1];
 localparam LABEL_LATENCY=__LABEL_LATENCY__;
 reg [26:0] expected_label[0:LABEL_LATENCY-1];
 integer n,k,a,b,expected,j;integer seed=8675309;
 task random_inputs;begin
  for(k=0;k<16;k=k+1)status[k*32+:32]=$random(seed);
  status[456+:2]=2'(n%4);status[490+:3]=3'(n%8);
  live=(n%7)!=0;peak=$random(seed);hz=$random(seed);
  xd=$random(seed);xs=$random(seed);xm=$random(seed);shift=$random(seed);range_sel=$random(seed);
  dx=$random(seed);dy=$random(seed);trails={$random(seed),$random(seed),$random(seed)};
  sharp=$random(seed);frost=$random(seed);
 end endtask
 task compare_pixel;begin
  #1;
  for(j=SCENE_LATENCY-1;j>0;j=j-1)expected_scene[j]=expected_scene[j-1];expected_scene[0]=ref_rgb;
  for(j=LABEL_LATENCY-1;j>0;j=j-1)expected_label[j]=expected_label[j-1];expected_label[0]={ref_ink,ref_lc,ref_cv};
  clk=1;#1;
  if(n>=SCENE_LATENCY && rgb!==expected_scene[SCENE_LATENCY-1])$fatal(1,"scene mismatch n=%0d xy=%0d,%0d %h != %h",n,x,y,rgb,expected_scene[SCENE_LATENCY-1]);
  if(n>=LABEL_LATENCY && {ink,lc,cv}!==expected_label[LABEL_LATENCY-1])$fatal(1,"labels mismatch n=%0d xy=%0d,%0d actual=%h expected=%h",n,x,y,{ink,lc,cv},expected_label[LABEL_LATENCY-1]);
  clk=0;
 end endtask
 initial begin
  x=0;y=0;n=0;random_inputs();#1;
  for(a=-651;a<=1330;a=a+1)begin
   expected=a/7;if(scene.fade7(a)!==expected)$fatal(1,"signed blend mismatch %0d",a);
  end
  // All visible X coordinates and every Y row, plus random and key/rim-biased
  // coordinates. Exact coordinate bounds are exhaustively proven separately.
  for(n=0;n<4096;n=n+1)begin
   random_inputs();
   if(n<1920)begin x=12'(n);y=12'(800+n%240);end
   else if(n<3000)begin x=12'(n%1920);y=12'(n-1920);end
   else begin x=12'($unsigned($random(seed))%1920);y=12'($unsigned($random(seed))%1080);end
   compare_pixel();
  end
  $display("PASS 4096 exact scene/label pixel comparisons; all signed fade numerators");$finish;
 end
endmodule
'''.replace('__SCENE_LATENCY__',str(latency)).replace('__LABEL_LATENCY__',str(label_latency))
(O/'tb_pixel_equivalence.sv').write_text(tb)
source_hashes={str(p.relative_to(R)):hashlib.sha256(p.read_bytes()).hexdigest() for p in
 [R/'src/display/visual_scene.sv',R/'src/display/visual_labels.sv',A/'visual_scene.original.sv',A/'visual_labels.original.sv']}
iv=Path('D:/gaoyun/piano_v2/codex_test/tools/iverilog/bin/iverilog.exe')
for name,args in [('pixel_equivalence_compile',[iv,'-g2012','-s','tb_pixel_equivalence','-o',O/'pixel_equivalence.vvp',
 R/'src/display/visual_scene.sv',R/'src/display/visual_labels.sv',O/'visual_scene_reference.sv',O/'visual_labels_reference.sv',O/'tb_pixel_equivalence.sv']),
 ('pixel_equivalence',[iv.with_name('vvp.exe'),O/'pixel_equivalence.vvp'])]:
 p=subprocess.run([str(x) for x in args],cwd=R,capture_output=True,text=True,timeout=180)
 (O/(name+'.log')).write_text(p.stdout+p.stderr)
 if p.returncode:raise RuntimeError(p.stdout+p.stderr)
 print(p.stdout[-1500:],flush=True)
assert all(hashlib.sha256((R/p).read_bytes()).hexdigest()==h for p,h in source_hashes.items()),'Source changed during verification; result is historical'
(O/'PIXEL_EQUIVALENCE.json').write_text(json.dumps({'status':'PASS','pixels':4096,
 'signed_blend_inputs':1982,'selected_region_coordinates':'exhaustively checked by optimization script',
 'files':source_hashes},indent=2))
