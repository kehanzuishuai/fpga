"""Compare an actual Gowin mapped auxiliary voice with RTL, including signed DSP/RAM."""
from pathlib import Path
import re,json,hashlib
from run import ROOT,OUT,run,IVER,VVP
P=ROOT/'tests/remote_music_20261019/resource/aux/impl/gwsynthesis/probe.vg'
text=P.read_text();mods=re.findall(r'^module (\w+)',text,re.M)
renames={n:'gate_'+n for n in mods}
text=re.sub(r'\b(?:'+ '|'.join(map(re.escape,mods))+r')\b',lambda m:renames[m[0]],text)
(OUT/'gate_aux.v').write_text(text)
tb=r'''`timescale 1ns/1ps
module tb_gate_aux;
reg clk=0,rst_n=0,tick=0,start=0,stop=0,clear=0;
always #40.69 clk=~clk;
integer cycles=0;always @(negedge clk)begin cycles=cycles+1;tick=cycles%256==0;end
reg [2:0] inst=1;reg [6:0] pitch=60;reg [7:0] vel=100;
wire ra,aa,oa,ca,rb,ab,ob,cb;wire [6:0] na,nb;wire [23:0] a,b;
yinse_aux_voice rtl(clk,rst_n,tick,start,stop,clear,inst,pitch,vel,ra,aa,a,oa,ca,na);
gate_yinse_aux_voice mapped(clk,rst_n,tick,start,stop,clear,inst,pitch,vel,rb,ab,b,ob,cb,nb);
GSR GSR(.GSRI(1'b1));
integer i,frames,checked=0,nonzero;
always @(posedge clk)begin #3;if(rst_n && cycles>10)begin
 if({ra,aa,oa,ca,na,a} !== {rb,ab,ob,cb,nb,b})$fatal(1,"Gowin mismatch inst%0d cycle%0d RTL%h gate%h ready%b%b active%b%b",inst,cycles,a,b,ra,rb,aa,ab);
end end
initial begin
 #1;rst_n=1;#1;rst_n=0;repeat(10)@(negedge clk);rst_n=1;
 for(i=1;i<=4;i=i+1)begin
  @(negedge clk);clear=1;repeat(2)@(negedge clk);clear=0;inst=3'(i);pitch=i==1?60:i==2?72:i==3?84:91;
  start=1;@(negedge clk);start=0;frames=0;nonzero=0;
  while(frames<512)begin @(posedge clk);#4;if(tick)begin frames=frames+1;checked=checked+1;if(a!=0)nonzero=nonzero+1;end end
  if(nonzero<400)$fatal(1,"mapped voice silent");
  @(negedge clk);stop=1;@(negedge clk);stop=0;repeat(512)@(negedge clk);
  $display("PASS actual Gowin auxiliary instrument %0d signed DSP/RAM, 512 PCM samples bit exact",i);$fflush();
 end
 $display("PASS actual Gowin auxiliary voice: %0d sample frames, all four instruments; zero RTL mismatches",checked);$finish;
end
endmodule
'''
(OUT/'tb_gate_aux.sv').write_text(tb)
files=list((ROOT/'src/instruments').rglob('*.sv'))
run('gate_aux_compile',[IVER,'-g2012','-s','tb_gate_aux','-o',OUT/'gate_aux.vvp',OUT/'tb_gate_aux.sv',OUT/'gate_aux.v',*files,'C:/Gowin2/Gowin_V1.9.12_x64/IDE/simlib/gw5a/prim_sim.v'])
run('gate_aux',[VVP,OUT/'gate_aux.vvp'],2400)
(OUT/'GATE_AUX_NETLIST.json').write_text(json.dumps({'status':'PASS','scope':'Isolated actual Gowin auxiliary voice, 512 samples per instrument plus cycle-by-cycle ready/active/note/flags checks','netlist_sha256':hashlib.sha256(P.read_bytes()).hexdigest()},indent=2))
