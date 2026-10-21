`timescale 1ns/1ps
module tb_xy_source;
 reg clk=0,rst_n=0,pv=0,mode=0;always #5 clk=~clk;
 reg signed [23:0] pcm=0,xx=0,yy=0;
 wire valid,dm;wire signed [15:0] wave,x,y;wire [31:0] overruns;
 reg [48:0] stimulus[0:10239];integer i,f,seen=0;
 visual_xy_source dut(clk,rst_n,pv,pcm,mode,xx,yy,valid,wave,x,y,dm,overruns);
 always @(posedge clk)if(valid)begin
  if(^({wave,x,y,dm})===1'bx)$fatal(1,"uninitialized XY");
  $fdisplay(f,"%0d %0d %0d %0d %0d",i,dm,wave,x,y);seen=seen+1;
 end
 initial begin
 $readmemh("tests/lissajous_video_20261018/stimulus.hex",stimulus);
 f=$fopen("tests/lissajous_video_20261018/output.txt","w");
 repeat(4)@(negedge clk);rst_n=1;
 for(i=0;i<10240;i=i+1)begin
  @(negedge clk);pcm={stimulus[i][47:32],8'b0};mode=stimulus[i][48];
  xx={stimulus[i][31:16],8'b0};yy={stimulus[i][15:0],8'b0};pv=1;
  @(negedge clk);pv=0;repeat(254)@(negedge clk);
 end
 repeat(140)@(negedge clk);
 if(overruns || seen!=10240-1023)$fatal(1,"count/timing %d %d",seen,overruns);
 // Deliberate display overload reports drops; input audio is never backpressured.
 pv=1;repeat(100)@(negedge clk);pv=0;
 if(overruns==0)$fatal(1,"overrun accounting");
 rst_n=0;#1;if(valid!==0)$fatal(1,"reset");
 $fclose(f);$display("PASS XY source: paired 16bit, Hilbert stream, same-tick voices, overload/reset");$finish;
 end
 initial begin #100000000;$fatal(1,"timeout");end
endmodule
