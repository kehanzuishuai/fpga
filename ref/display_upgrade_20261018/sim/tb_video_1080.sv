`timescale 1ns/1ps
module tb_video_1080;
 reg clk=0,rst_n=0,de=0;reg [1:0] ctrl=0;reg [7:0] data=0;
 always #5 clk=~clk;
 wire [9:0] symbol;wire [11:0] x,y;wire active,hs,vs,blank;
 visual_raster raster(clk,rst_n,x,y,active,hs,vs,blank);
 visual_tmds encoder(clk,rst_n,de,ctrl,data,symbol);
 function [7:0] decode(input [9:0] s);
 reg [7:0] q;integer k;begin q=s[7:0]^{8{s[9]}};decode[0]=q[0];for(k=1;k<8;k=k+1)decode[k]=q[k]^q[k-1]^!s[8];end endfunction
 integer i,k,count=0,hcount=0,vcount=0,blanks=0,ones,rd=0;
 initial begin
 repeat(3)@(negedge clk);rst_n=1;
 for(i=0;i<2200*1125;i=i+1)begin
  if(active)count=count+1;if(hs)hcount=hcount+1;if(vs)vcount=vcount+1;if(blank)blanks=blanks+1;
  @(negedge clk);
 end
 if(count!=1920*1080 || hcount!=44*1125 || vcount!=5*2200 || blanks!=1 || x!=0 || y!=0)$fatal(1,"1080p geometry");
 for(i=0;i<4096;i=i+1)begin
  de=1;data=8'((i*73)^(i>>4));@(posedge clk);#1;if(decode(symbol)!==data)$fatal(1,"TMDS data");
  ones=0;for(k=0;k<10;k=k+1)ones=ones+integer'(symbol[k]);rd=rd+2*ones-10;
  if(rd>8 || rd< -8)$fatal(1,"disparity");@(negedge clk);
 end
 de=0;
 for(i=0;i<4;i=i+1)begin ctrl=2'(i);@(posedge clk);#1;
 case(i)
 0:if(symbol!=10'b1101010100)$fatal(1,"control0");1:if(symbol!=10'b0010101011)$fatal(1,"control1");
 2:if(symbol!=10'b0101010100)$fatal(1,"control2");3:if(symbol!=10'b1010101011)$fatal(1,"control3");endcase
 @(negedge clk);end
 $display("PASS 2200x1125,1920x1080 active,44/5 positive sync,30Hz at74.25MHz,4096 TMDS words");$finish;
 end
endmodule
