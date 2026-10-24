from pathlib import Path
import subprocess,json,hashlib
R=Path(__file__).resolve().parents[2];O=Path(__file__).resolve().parent/'out'
A=R/'audit/display_integration_20261021/optimization'
ref=(A/'visual_background.original.sv').read_text().replace('visual_background','visual_background_reference').replace('visual_texture_plane','visual_texture_plane_reference')
(O/'visual_background_reference.sv').write_text(ref)
tb='''`timescale 1ns/1ps
module tb_background_equivalence;
 GSR GSR(.GSRI(1'b1));reg clk=0;reg [31:0] addr=0;reg [11:0] x=0,y=0;
 wire [23:0] fine[0:3],frost[0:3];reg [23:0] expected_fine[0:32911],expected_frost[0:575];
 wire [23:0] sharp,blur,ref_sharp,ref_blur;
 visual_background bg(clk,x,y,sharp,blur);
 visual_background_reference reference_bg(clk,x,y,ref_sharp,ref_blur);
'''
for i in range(4):
 tb+=f''' visual_texture_rom24_packed #(.WORDS(8228),.FILE("assets/bg_fine_{i}_packed18.hex")) fine{i}(clk,addr,fine[{i}]);
 visual_texture_rom24_packed #(.WORDS(144),.FILE("assets/bg_frost_{i}_packed18.hex")) frost{i}(clk,addr%32'd144,frost[{i}]);
'''
tb+=''' integer i,j,seed=314159;reg [47:0] previous_reference[0:3];
 initial begin
'''
for i in range(4):
 tb+=f'  $readmemh("assets/bg_fine_{i}.hex",expected_fine,{i*8228},{(i+1)*8228-1});\n'
 tb+=f'  $readmemh("assets/bg_frost_{i}.hex",expected_frost,{i*144},{(i+1)*144-1});\n'
tb+='''  #20;
  for(i=0;i<16000;i=i+1)begin
   addr=i%8228;x=12'($unsigned($random(seed))%4096);y=12'($unsigned($random(seed))%4096);
   #5;previous_reference[3]=previous_reference[2];previous_reference[2]=previous_reference[1];previous_reference[1]=previous_reference[0];previous_reference[0]={ref_sharp,ref_blur};clk=1;#5;
   for(j=0;j<4;j=j+1)begin
    if(fine[j]!==expected_fine[j*8228+addr])$fatal(1,"native fine texel bank%0d addr%0d got%h expected%h",j,addr,fine[j],expected_fine[j*8228+addr]);
    if(frost[j]!==expected_frost[j*144+addr%144])$fatal(1,"native frost texel bank%0d addr%0d",j,addr%144);
   end
   if(i>6 && {sharp,blur}!==previous_reference[3])$fatal(1,"bilinear latency/value mismatch %0d %h %h",i,{sharp,blur},previous_reference[3]);
   clk=0;
  end
  $display("PASS exact native DPX9B: every texel in 8 banks, all block boundaries; 16000 bilinear samples, four extra clocks absorbed by scene stage4");$finish;
 end
endmodule
'''
(O/'tb_background_equivalence.sv').write_text(tb)
iv=Path('D:/gaoyun/piano_v2/codex_test/tools/iverilog/bin/iverilog.exe')
for name,args in [('background_equivalence_compile',[iv,'-g2012','-s','tb_background_equivalence','-o',O/'background_equivalence.vvp',
 R/'src/display/visual_background.sv',O/'visual_background_reference.sv',O/'tb_background_equivalence.sv',
 Path('C:/Gowin2/Gowin_V1.9.12_x64/IDE/simlib/gw5a/prim_sim.v')]),
 ('background_equivalence',[iv.with_name('vvp.exe'),O/'background_equivalence.vvp'])]:
 p=subprocess.run([str(x) for x in args],cwd=R,capture_output=True,text=True,timeout=180)
 (O/(name+'.log')).write_text(p.stdout+p.stderr)
 if p.returncode:raise RuntimeError(p.stdout+p.stderr)
 print(p.stdout[-2000:],flush=True)
(O/'BACKGROUND_EQUIVALENCE.json').write_text(json.dumps({'status':'PASS','source_sha256':hashlib.sha256((R/'src/display/visual_background.sv').read_bytes()).hexdigest(),'bilinear_samples':16000,'all_texels_checked':True,'extra_clocks':4,'production_alignment':'scene BACKGROUND_LATENCY=4, RGB first consumed in stage4'},indent=2))
