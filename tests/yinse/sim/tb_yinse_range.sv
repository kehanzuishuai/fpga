`timescale 1ns/1ps
module tb_yinse_range;
 reg clk=0,rst_n=0,tick=0,clear=0,event_valid=0,event_on=1;
 reg [2:0] instrument=1;reg [6:0] note=36;reg [7:0] velocity=100;
 always #5 clk=~clk;
 integer cycles=0;
 always @(negedge clk)begin cycles=cycles+1;tick=cycles%16==0;end
 wire ready,valid,rejected;wire signed [23:0] pcm;
 wire [0:0] active,overrun,clip;
 yinse_aux_bank #(.VOICES(1)) dut(clk,rst_n,tick,clear,event_valid,event_on,
 instrument,note,velocity,ready,pcm,valid,active,overrun,clip,rejected);
 integer inst,pitch,frame,heard,accepted=0;
 initial begin
  #1;rst_n=1;#1;rst_n=0;repeat(5)@(negedge clk);rst_n=1;
  for(inst=1;inst<=4;inst=inst+1)for(pitch=36;pitch<=96;pitch=pitch+1)begin
   @(negedge clk);clear=1;repeat(2)@(negedge clk);clear=0;
   instrument=3'(inst);note=7'(pitch);
   case(pitch%3)0:velocity=1;1:velocity=127;2:velocity=255;endcase
   event_valid=1;@(posedge clk);
   if(!ready)$fatal(1,"supported note not acknowledged inst=%0d pitch=%0d",inst,pitch);
   #1;if(rejected)$fatal(1,"supported note rejected inst=%0d pitch=%0d",inst,pitch);
   @(negedge clk);event_valid=0;
   frame=0;heard=0;
   while(frame<768)begin @(posedge clk);#1;
    if(valid)begin
     frame=frame+1;
     if(^pcm===1'bx || |overrun || |clip)$fatal(1,"range error inst=%0d pitch=%0d velocity=%0d",inst,pitch,velocity);
     if(pcm!=0)heard=heard+1;
    end
   end
   if(!active || heard<10)$fatal(1,"supported note silent inst=%0d pitch=%0d",inst,pitch);
   accepted=accepted+1;
  end
  $display("PASS full supported range: %0d instrument/note cases MIDI36..96, velocity1/127/255, KS fill, clear, nonzero and no X/clip/overrun",accepted);$finish;
 end
 initial begin #100000000;$fatal(1,"range watchdog");end
endmodule
