`timescale 1ns/1ps
module tb_volume;
 reg clk=0;always #5 clk=~clk;reg rst_n=0,tick=0,cv=0,pv=0;
 reg [15:0] value=0;reg signed [23:0] pcm=0;wire ready,ov;wire [15:0] gain;wire signed [23:0] out;
 wifi_volume #(.GAIN_STEP(256)) dut(clk,rst_n,tick,cv,value,ready,gain,pv,pcm,ov,out);
 task apply(input [15:0] v);begin @(negedge clk);tick=1;cv=1;value=v;@(negedge clk);cv=0;repeat(258)@(negedge clk);tick=0;end endtask
 task sample(input signed [23:0] v,input signed [23:0] expected);begin @(negedge clk);pcm=v;pv=1;@(negedge clk);if(!ov||out!==expected)$fatal(1,"scaled PCM got=%d expected=%d",out,expected);pv=0;end endtask
 initial begin
  repeat(3)@(negedge clk);rst_n=1;
  sample(24'sd8388607,24'sd8388607);sample(-24'sd8388608,-24'sd8388608);
  apply(32768);if(gain!=32768)$fatal(1,"half gain");sample(24'sd8000000,24'sd4000000);sample(-24'sd8000000,-24'sd4000000);
  apply(0);if(gain!=0)$fatal(1,"mute");sample(24'sd8388607,24'sd0);
  apply(65535);sample(-24'sd8388608,-24'sd8388608);
  // Config waits for a sample boundary and cannot jump applied gain directly.
  @(negedge clk);cv=1;value=0;repeat(4)@(negedge clk);if(ready||gain!=65535)$fatal(1,"non-boundary apply");
  tick=1;@(negedge clk);cv=0;@(negedge clk);if(gain!=65279)$fatal(1,"gain ramp");
  $display("PASS real PCM volume: signed extremes, unity, half, mute, one-clock output and sample-boundary ramp");$finish;
 end
endmodule
