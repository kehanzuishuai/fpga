"""Actual mapped eight-context shared lane vs RTL, including signed DSP/KS RAMs."""
from pathlib import Path
import re,json,hashlib
from concurrent.futures import ThreadPoolExecutor
from run import ROOT,OUT,run,IVER,VVP
P=ROOT/'tests/remote_music_20261019/resource/lane/impl/gwsynthesis/probe.vg'
text=P.read_text();mods=re.findall(r'^module (\w+)',text,re.M)
renames={n:'gate_'+n for n in mods}
text=re.sub(r'\b(?:'+ '|'.join(map(re.escape,mods))+r')\b',lambda m:renames[m[0]],text)
(OUT/'gate_aux.v').write_text(text)
tb=r'''`timescale 1ns/1ps
module tb_gate_aux;
reg clk=0,rst_n=0,tick=0,ev=0,on=1,clear=0;
always #40.69 clk=~clk;
integer cycles=0;always @(negedge clk)begin cycles=cycles+1;tick=cycles%256==0;end
reg [2:0] inst=1;reg [6:0] pitch=36;reg [7:0] vel=100;
wire ra,rb,va,vb,ja,jb;wire [7:0] aa,ab,oa,ob,ca,cb;wire [23:0] a,b;
yinse_aux_bank #(.VOICES(8),.MIX_SHIFT(3)) rtl(clk,rst_n,tick,clear,ev,on,inst,pitch,vel,ra,a,va,aa,oa,ca,ja);
gate_probe_aux_bank mapped(clk,rst_n,tick,clear,ev,on,inst,pitch,vel,rb,b,vb,ab,ob,cb,jb);
GSR GSR(.GSRI(1'b1));
integer i,n,base,frames,checked=0,nonzero,only_instrument;
always @(posedge clk)begin #3;if(rst_n && cycles>10)begin
 if({ra,va,ja,aa,oa,ca,a} !== {rb,vb,jb,ab,ob,cb,b})$fatal(1,"shared-bank Gowin mismatch inst%0d cycle%0d RTL%h gate%h",inst,cycles,a,b);
end end
task automatic send(input bit note_on,input integer note);begin
 @(negedge clk);pitch=7'(note);on=note_on;ev=0;
 while(!(ra && rb))@(negedge clk);ev=1;@(negedge clk);ev=0;
end endtask
initial begin
 only_instrument=0;
 if($value$plusargs("INSTRUMENT=%d",only_instrument))begin end
 #1;rst_n=1;#1;rst_n=0;repeat(10)@(negedge clk);rst_n=1;
 for(i=1;i<=4;i=i+1)begin
  if(only_instrument==0 || only_instrument==i)begin
  @(negedge clk);clear=1;repeat(2)@(negedge clk);clear=0;inst=3'(i);
  base=i==1?60:i==2?72:i==3?48:84;
  for(n=base;n<base+8;n=n+1)send(1,n);
  frames=0;nonzero=0;
  while(frames<512)begin @(posedge clk);#4;if(tick)begin frames=frames+1;checked=checked+1;if(a!=0)nonzero=nonzero+1;end end
  if(nonzero<400 || aa!=8'hff || |oa)$fatal(1,"shared lane silent/missing/late");
  for(n=base;n<base+8;n=n+1)send(0,n);repeat(512)@(negedge clk);
  $display("PASS actual Gowin shared lane instrument %0d: 8 voices, one arithmetic engine, 512 PCM frames bit exact",i);$fflush();
  end
 end
 $display("PASS actual Gowin shared lane: %0d PCM frames, instrument selection %0d; zero cycle-by-cycle RTL mismatches; full32 tested separately in RTL",checked,only_instrument);$finish;
end
initial begin #300000000;$fatal(1,"shared gate timeout");end
endmodule
'''
(OUT/'tb_gate_aux.sv').write_text(tb)
files=list((ROOT/'src/instruments').rglob('*.sv'))
run('gate_aux_compile',[IVER,'-g2012','-s','tb_gate_aux','-o',OUT/'gate_aux.vvp',OUT/'tb_gate_aux.sv',OUT/'gate_aux.v',*files,'C:/Gowin2/Gowin_V1.9.12_x64/IDE/simlib/gw5a/prim_sim.v'])
def check_instrument(i):
 name=f'gate_aux_{i}'
 run(name,[VVP,OUT/'gate_aux.vvp',f'+INSTRUMENT={i}'],3600)
 receipt=json.loads((OUT/(name+'.json')).read_text())
 assert receipt['status']=='PASS' and receipt['inputs_unchanged']
 return name,receipt
with ThreadPoolExecutor(max_workers=4) as pool:
 parts=list(pool.map(check_instrument,range(1,5)))
assert all(p[1]['input_sha256']==parts[0][1]['input_sha256'] for p in parts)
(OUT/'gate_aux.log').write_text('\n'.join((OUT/(name+'.log')).read_text() for name,_ in parts))
receipt=dict(parts[0][1]);receipt['part_receipts']=[name+'.json' for name,_ in parts]
receipt['elapsed_s']=max(p[1]['elapsed_s'] for p in parts)
(OUT/'gate_aux.json').write_text(json.dumps(receipt,indent=2))
(OUT/'GATE_AUX_NETLIST.json').write_text(json.dumps({'status':'PASS','scope':'Four independent simulations of the actual mapped eight-context lane, one shared arithmetic engine and 16 KS RAM blocks. 512 frames per instrument (2048 total) plus cycle checks. Full32 RTL tests and production synthesis cover the four-lane integration.','netlist_sha256':hashlib.sha256(P.read_bytes()).hexdigest(),'testbench_sha256':hashlib.sha256((OUT/'tb_gate_aux.sv').read_bytes()).hexdigest(),'executable_sha256':hashlib.sha256((OUT/'gate_aux.vvp').read_bytes()).hexdigest(),'parts':{name:hashlib.sha256((OUT/(name+'.log')).read_bytes()).hexdigest() for name,_ in parts}},indent=2))
