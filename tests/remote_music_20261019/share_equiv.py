"""Compare every frame/voice with original arithmetic for all supported notes."""
from run import ROOT,OUT,run,IVER,VVP
from pathlib import Path
import re
table=(ROOT/'src/instruments/gongyong/yinse_note_table.sv').read_text()
increments={int(n):int(i) for n,i in re.findall(r"7'd(\d+):begin increment=32'd(\d+)",table)}
assert set(increments)==set(range(36,97)) and max(increments.values())*8 < 2**31
print('PASS all accepted note increments keep every 8x-or-lower partial below Nyquist',flush=True)
snap=OUT/'pre_share';old=OUT/'pre_share_renamed';old.mkdir(exist_ok=True)
files=[]
for p in snap.rglob('*.sv'):
 q=old/p.relative_to(snap);q.parent.mkdir(parents=True,exist_ok=True)
 q.write_text(re.sub(r'\byinse_\w+',lambda m:'pre_'+m[0],p.read_text()))
 files.append(q)
tb=r'''`timescale 1ns/1ps
module tb_share_equiv;
reg clk=0,rst_n=0,tick=0,clear=0,ev=0,on=1;always #5 clk=~clk;
integer cycles=0;always @(negedge clk)begin cycles=cycles+1;tick=cycles%256==0;end
reg [2:0] inst=1;reg [6:0] note=60;wire ra,rb,va,vb,ja,jb;
wire signed [23:0] a,b;wire [31:0] aa,ab,oa,ob,ca,cb;
yinse_aux_bank #(.VOICES(32),.MIX_SHIFT(3)) after_bank(clk,rst_n,tick,clear,ev,on,inst,note,8'd100,ra,a,va,aa,oa,ca,ja);
pre_yinse_aux_bank #(.VOICES(32),.MIX_SHIFT(3)) before_bank(clk,rst_n,tick,clear,ev,on,inst,note,8'd100,rb,b,vb,ab,ob,cb,jb);
integer n,k,frames,checked=0;
always @(posedge clk)begin #2;if(rst_n && tick)begin
 if({va,ja,aa,oa,ca,a}!=={vb,jb,ab,ob,cb,b} || after_bank.samples!==before_bank.samples || after_bank.notes!==before_bank.notes)
  $fatal(1,"shared arithmetic frame difference inst%0d cycle%0d PCM%h/%h",inst,cycles,a,b);
end end
task automatic send(input bit is_on,input integer pitch);begin
 @(negedge clk);#1;ev=0;on=is_on;note=7'(pitch);
 while(!(ra && rb && cycles%256>=200 && cycles%256<240))begin @(negedge clk);#1;end
 ev=1;@(negedge clk);ev=0;
end endtask
initial begin
 #1;rst_n=1;#1;rst_n=0;repeat(5)@(negedge clk);rst_n=1;
 for(k=1;k<=4;k=k+1)begin
  @(negedge clk);clear=1;repeat(2)@(negedge clk);clear=0;inst=3'(k);
  for(n=36;n<=96;n=n+1)send(1,n);
  $display("progress shared arithmetic instrument%0d: all 61 note requests accepted at cycle%0d",k,cycles);$fflush();
  frames=0;while(frames<512)begin @(posedge clk);if(tick)begin frames=frames+1;checked=checked+1;
   if(frames%128==0)begin $display("progress shared arithmetic instrument%0d frame%0d cycle%0d",k,frames,cycles);$fflush();end
  end end
  for(n=36;n<=96;n=n+1)send(0,n);
  frames=0;while(frames<128)begin @(posedge clk);if(tick)frames=frames+1;end
  $display("PASS shared arithmetic instrument %0d: all 61 supported pitches, 32 voice samples/notes/masks and PCM frame-exact",k);$fflush();
 end
 $display("PASS time-shared arithmetic: %0d checked PCM frames plus note transitions, zero per-voice frame differences; internal computation latency intentionally differs",checked);$finish;
end
initial begin #20000000;$fatal(1,"shared arithmetic test timeout cycle%0d inst%0d",cycles,inst);end
endmodule
'''
(OUT/'tb_share_equiv.sv').write_text(tb)
run('share_equiv_compile',[IVER,'-g2012','-s','tb_share_equiv','-o',OUT/'share_equiv.vvp',OUT/'tb_share_equiv.sv',*list((ROOT/'src/instruments').rglob('*.sv')),*files])
run('share_equiv',[VVP,OUT/'share_equiv.vvp'],1800)
