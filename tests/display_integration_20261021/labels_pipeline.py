"""Exercise every original text rectangle with changing real metadata."""
from pathlib import Path
import re,subprocess,json,hashlib
R=Path(__file__).resolve().parents[2];O=Path(__file__).resolve().parent/'out'
s=(R/'src/display/visual_labels.sv').read_text();ref=O/'visual_labels_reference.sv'
gold=(R/'audit/display_integration_20261021/optimization/visual_labels.original.sv').read_text()
gold=gold.replace('module visual_labels','module visual_labels_reference').replace('always @* begin\n  ch=','always_comb begin\n  ch=')
ref.write_text(gold)
rects=re.findall(r"wire hit_(\d+)=.*?x>=(\d+) && x<(\d+) && y>=(\d+) && y<(\d+)",s)
assert len(rects)==90
cases='\n'.join(f'{n}:begin x=12\'({x0}+($unsigned($random(seed))%{int(x1)-int(x0)}));y=12\'({y0}+($unsigned($random(seed))%{int(y1)-int(y0)}));end' for n,x0,x1,y0,y1 in rects)
tb='''`timescale 1ns/1ps
module tb_labels_pipeline;
 reg clk=0;reg [11:0] x=0,y=0;reg live=0,pv=0,xd=0,xs=0,xm=0;reg [15:0] hz=0;
 reg signed [5:0] shift=0;reg [1:0] range_sel=0;reg [511:0] status=0;
 wire ink,ri;wire [23:0] color,rc;wire [1:0] coverage,rv;
 visual_labels dut(x,y,pv,hz,xd,xs,xm,shift,ink,live,status,color,coverage,range_sel,clk);
 visual_labels_reference gold(x,y,pv,hz,xd,xs,xm,shift,ri,live,status,rc,rv,range_sel);
 reg [26:0] pixels[0:20];reg [15:0] chars[0:17];
 reg [39:0] attr_history[0:17];reg [511:0] status_history[0:17];
 integer n,k,j,v,d;integer seed=7391;reg [35:0] bcd;reg [19:0] expected_bcd;integer tmp;
 initial begin
  for(v=0;v<65536;v=v+1)begin
   bcd={16'(v),20'd0};for(k=0;k<16;k=k+1)bcd=dut.bcd_step(bcd);
   tmp=v;for(k=0;k<5;k=k+1)begin expected_bcd[k*4+:4]=4'(tmp%10);tmp=tmp/10;end
   if(bcd[19:0]!==expected_bcd)$fatal(1,"BCD mismatch %0d",v);
  end
  for(n=0;n<2912;n=n+1)begin
   for(k=0;k<16;k=k+1)status[k*32+:32]=$random(seed);
   status[6:0]=7'h7f;status[0]=(n%5)!=0;status[1]=(n%3)!=0;
   status[8+:3]=3'(n%6);status[11+:7]=7'(36+n%61);
   for(k=0;k<32;k=k+1)status[82+k*7+:7]=7'(36+(k+n)%61);
   status[455]=1;status[456+:2]=2'(n%3);status[490+:3]=3'(n%8);
   live=(n%7)!=0;pv=(n%4)!=0;hz=$random(seed);xd=n%2;xs=n%3!=0;xm=n%5==0;range_sel=2'(n%4);
   case((n/32)%90)
__CASES__
   endcase
   #1;
   for(j=20;j>0;j=j-1)pixels[j]=pixels[j-1];pixels[0]={ri,rc,rv};
   for(j=17;j>0;j=j-1)chars[j]=chars[j-1];chars[0]=gold.ch;
   for(j=17;j>0;j=j-1)begin attr_history[j]=attr_history[j-1];status_history[j]=status_history[j-1];end
   attr_history[0]=gold.attributes;status_history[0]=status;
   clk=1;#1;
   if(n>21 && {ink,color,coverage}!==pixels[20])$fatal(1,"label raster n=%0d region=%0d actual=%h expected=%h",n,(n/32)%90,{ink,color,coverage},pixels[20]);
   if(n>18 && dut.ch!==chars[17])begin
    $display("char attrs previous=%h actual_glyph=%h status_prev=%h current_meta=%h live=%b map=%b",attr_history[17],dut.attr_glyph,status_history[17],dut.char_status,dut.char_live,dut.c_mapping_valid);
    $fatal(1,"label character n=%0d region=%0d actual=%h expected=%h",n,(n/32)%90,dut.ch,chars[17]);end
   clk=0;
  end
  $display("PASS all 65536 BCD inputs; 2912 text pixels/characters across all 90 regions with changing key maps, modes, notes, counts and peak frequencies");$finish;
 end
endmodule
'''.replace('__CASES__',cases)
(O/'tb_labels_pipeline.sv').write_text(tb)
iv=Path('D:/gaoyun/piano_v2/codex_test/tools/iverilog/bin/iverilog.exe')
inputs=[R/'src/display/visual_labels.sv',ref,O/'tb_labels_pipeline.sv']
hashes={str(p.relative_to(R)):hashlib.sha256(p.read_bytes()).hexdigest() for p in inputs}
for name,args in [('labels_pipeline_compile',[iv,'-g2012','-s','tb_labels_pipeline','-o',O/'labels_pipeline.vvp',*inputs]),('labels_pipeline',[iv.with_name('vvp.exe'),O/'labels_pipeline.vvp'])]:
 p=subprocess.run([str(x) for x in args],cwd=R,capture_output=True,text=True,timeout=180)
 (O/(name+'.log')).write_text(p.stdout+p.stderr)
 if p.returncode:raise RuntimeError(p.stdout+p.stderr)
 print(p.stdout[-1400:],flush=True)
assert all(hashlib.sha256((R/p).read_bytes()).hexdigest()==h for p,h in hashes.items())
(O/'LABELS_EQUIVALENCE.json').write_text(json.dumps({'status':'PASS','regions':90,'pixels':2912,'bcd_inputs':65536,'latency':21,'files':hashes},indent=2))
