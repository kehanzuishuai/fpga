"""Short scheduler/deadline diagnostic for the newly shared 32-voice bank."""
from run import ROOT,OUT,run,IVER,VVP
tb=r'''`timescale 1ns/1ps
module tb_shared_smoke;
reg clk=0,rst_n=0,tick=0,ev=0;always #5 clk=~clk;
integer cycles=0;always @(negedge clk)begin cycles=cycles+1;tick=cycles%256==0;end
reg[6:0] note=60;wire ready,valid,rejected;wire[31:0] active,overrun,clipped;wire[23:0] pcm;
yinse_aux_bank #(.VOICES(32),.MIX_SHIFT(3)) dut(clk,rst_n,tick,1'b0,ev,1'b1,3'd1,note,8'd100,ready,pcm,valid,active,overrun,clipped,rejected);
integer n,k,frames=0;reg[31:0] heard=0;
always @(posedge clk)begin #2;if(rst_n)begin
 if(cycles%512==0)begin $display("progress shared smoke cycle%0d frame%0d active%h",cycles,frames,active);$fflush();end
 if(valid)begin frames=frames+1;
  for(k=0;k<32;k=k+1)if(dut.samples[k*24+:24]!=0)heard[k]=1;
  if(|overrun || rejected || ^pcm===1'bx)$fatal(1,"shared scheduler failure");
  if(frames==16)begin if(active!=32'hffffffff || heard!=32'hffffffff)$fatal(1,"missing shared voice %h",heard);
   $display("PASS shared32 scheduler: 16 complete frames, all voices heard, zero overruns");$finish;end
 end
end end
initial begin
 #1;rst_n=1;#1;rst_n=0;repeat(5)@(negedge clk);rst_n=1;$display("progress shared smoke reset complete");$fflush();
 for(n=60;n<=91;n=n+1)begin @(negedge clk);note=7'(n);ev=1;while(!ready)@(negedge clk);@(negedge clk);ev=0;end
end
initial begin #100000;$fatal(1,"shared smoke timeout");end
endmodule
'''
(OUT/'tb_shared_smoke.sv').write_text(tb)
run('shared_smoke_compile',[IVER,'-g2012','-s','tb_shared_smoke','-o',OUT/'shared_smoke.vvp',OUT/'tb_shared_smoke.sv',*list((ROOT/'src/instruments').rglob('*.sv'))])
run('shared_smoke',[VVP,OUT/'shared_smoke.vvp'],120)
