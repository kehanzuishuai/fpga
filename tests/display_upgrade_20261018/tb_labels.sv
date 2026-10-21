`timescale 1ns/1ps
module tb_labels;
reg clk=0,rst=0;always#5 clk=~clk;
reg[9:0]x=0,y=0;reg[15:0]hz=0;reg valid=0,direct=0,signal_valid=0,mixed=0;
wire a,b;reg[1:0]expected=0;integer xx,yy,mode,checks=0;
visual_labels n(x,y,valid,hz,direct,signal_valid,mixed,6'sd0,a,clk,rst);
original_labels o(x,y,valid,hz,direct,signal_valid,mixed,6'sd0,b);
always@(posedge clk)expected<={expected[0],b};
initial begin
repeat(3)@(negedge clk);rst=1;
for(mode=0;mode<4;mode=mode+1)begin
 valid=mode!=0;hz=mode==1?16'd7:mode==2?16'd24000:16'd441;
 signal_valid=mode!=0;direct=mode==2;mixed=mode==3;
 repeat(24)@(negedge clk);
 for(yy=0;yy<360;yy=yy+1)for(xx=0;xx<640;xx=xx+1)begin
  @(negedge clk);x=10'(xx);y=10'(yy);
  @(posedge clk);#1;if(a!==expected[1])$fatal(1,"font mismatch mode%0d at%0d,%0d",mode,xx,yy);checks=checks+1;
 end
end
$display("PASS %0d label pixels exactly equal supplied font with2cycle latency",checks);$finish;
end endmodule
