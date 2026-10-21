`timescale 1ns/1ps
module tb_aux;
 reg clk=0,rst_n=0,tick=0,clear=0,ev=0,on=1;
 always #5 clk=~clk;
 integer cycles=0;always @(negedge clk)begin cycles=cycles+1;tick=cycles%256==0;end
 reg [2:0] instrument=1;reg [6:0] note=60;reg [7:0] velocity=100;
 wire ready,valid,rejected;wire signed [23:0] pcm;wire [31:0] active,overrun,clipped;
 yinse_aux_bank #(.VOICES(32),.MIX_SHIFT(3)) dut(clk,rst_n,tick,clear,ev,on,instrument,note,velocity,ready,pcm,valid,active,overrun,clipped,rejected);
 integer inst,n,frames,heard,fd;
 task automatic send(input bit is_on,input integer pitch);
  begin
   @(negedge clk);ev=1;on=is_on;note=7'(pitch);
   while(!ready)@(negedge clk);
   @(negedge clk);ev=0;
  end
 endtask
 initial begin
  #1;rst_n=1;#1;rst_n=0;repeat(5)@(negedge clk);rst_n=1;
  for(inst=1;inst<=4;inst=inst+1)begin
   @(negedge clk);clear=1;repeat(2)@(negedge clk);clear=0;instrument=3'(inst);
   for(n=60;n<=91;n=n+1)send(1,n);
   frames=0;heard=0;
   while(frames<4096)begin @(posedge clk);#1;if(valid)begin
    frames=frames+1;if(pcm!=0)heard=heard+1;
    if(^pcm===1'bx || |overrun || rejected)$fatal(1,"aux failure inst%0d overruns%h rejected%b",inst,overrun,rejected);
   end end
   if(active!==32'hffffffff || heard<4000)$fatal(1,"32-voice allocation/audio failure %h %d",active,heard);
   $display("PASS instrument %0d: all 32 notes active, %0d nonzero frames, zero scheduler overruns",inst,heard);$fflush();
   for(n=60;n<=91;n=n+1)send(0,n);
   frames=0;while(frames<6000)begin @(posedge clk);#1;if(valid)frames=frames+1;end
   if(active!=0)$fatal(1,"stuck auxiliary voices %h",active);
  end
  $display("PASS auxiliary32 integration");$finish;
 end
 initial begin #300000000;$fatal(1,"timeout");end
endmodule
