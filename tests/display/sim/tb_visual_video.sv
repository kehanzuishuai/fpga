`timescale 1ns/1ps
module tb_visual_video;
 reg clk=0,rst_n=0,de=0;reg [1:0]ctrl=0;reg [7:0]data=0;
 always #20 clk=~clk;
 wire [9:0]symbol,x,y;wire active,hs,vs,blank_start;
 visual_tmds enc(clk,rst_n,de,ctrl,data,symbol);
 visual_raster raster(clk,rst_n,x,y,active,hs,vs,blank_start);
 function [7:0] decode(input [9:0]s);
 reg [7:0]q;integer k;
 begin q=s[7:0]^{8{s[9]}};decode[0]=q[0];
 for(k=1;k<8;k=k+1)decode[k]=q[k]^q[k-1]^!s[8];end endfunction
 integer i,k,ones,rd=0,count=0,hcount=0,vcount=0,blanks=0;
 reg [9:0]expected_control;
 initial begin
   #1;rst_n=1;#1;rst_n=0;repeat(3)@(negedge clk);rst_n=1;
   for(i=0;i<4;i=i+1)begin
     @(negedge clk);de=0;ctrl=2'(i);@(posedge clk);#1;
     case(i)0:expected_control=10'b1101010100;1:expected_control=10'b0010101011;
     2:expected_control=10'b0101010100;3:expected_control=10'b1010101011;endcase
     if(symbol!==expected_control)$fatal(1,"TMDS control");
   end
   for(i=0;i<4096;i=i+1)begin
     @(negedge clk);de=1;data=8'((i*73)^(i>>4));@(posedge clk);#1;
     if(decode(symbol)!==data)$fatal(1,"TMDS decode");
     ones=0;for(k=0;k<10;k=k+1)ones=ones+integer'(symbol[k]);
     rd=rd+2*ones-10;
     if(rd>8 || rd< -8)$fatal(1,"TMDS disparity %0d",rd);
   end
   @(negedge clk);rst_n=0;repeat(3)@(negedge clk);rst_n=1;
   for(i=0;i<800*525;i=i+1)begin
     if(active)count=count+1;if(!hs)hcount=hcount+1;if(!vs)vcount=vcount+1;
     if(blank_start)blanks=blanks+1;@(negedge clk);
   end
   if(count!=640*480 || hcount!=96*525 || vcount!=2*800 || blanks!=1)$fatal(1,"raster geometry");
   $display("PASS TMDS 4096 data bytes/control/disparity, 800x525 raster,640x480 active, sync widths");$finish;
 end
endmodule
