`timescale 1ns/1ps
module tb_timing;
reg clk=0,rst=0,de=0;reg[1:0]ctrl=0;reg[7:0]data=0;always#5 clk=~clk;
wire[9:0]a,b;integer k,n=0;reg[31:0]rng=32'h12345678;
visual_tmds newer(clk,rst,de,ctrl,data,a);old_tmds older(clk,rst,de,ctrl,data,b);
reg[15:0]hz=0;wire ink;
visual_labels lab(.clk(clk),.rst_n(rst),.x(10'd0),.y(10'd0),.peak_valid(1'b1),.peak_hz(hz),.xy_direct(1'b0),.xy_signal(1'b0),.xy_mixed(1'b0),.xy_shift(6'sd0),.ink(ink));
function[19:0] decimal5(input integer v);integer j,t;begin t=v;decimal5=0;for(j=0;j<5;j=j+1)begin decimal5[j*4+:4]=4'(t%10);t=t/10;end end endfunction
initial begin
repeat(4)@(negedge clk);rst=1;
for(k=0;k<65536;k=k+1)begin
 @(negedge clk);rng={rng[30:0],rng[31]^rng[21]^rng[1]^rng[0]};data=k<256?8'(k):rng[7:0];de=(k%257)>3;ctrl=2'(k);
 @(posedge clk);#1;if(a!==b)$fatal(1,"TMDS changed at%0d",k);
 if(newer.disparity>8 || newer.disparity< -8)$fatal(1,"TMDS disparity");n=n+1;
end
for(k=0;k<=24000;k=k+137)begin
 @(negedge clk);hz=16'(k);repeat(20)@(negedge clk);
 if(lab.digits!==decimal5(k))$fatal(1,"BCD%0d got%h",k,lab.digits);
end
$display("PASS65536 TMDS words exactly equal old32bit encoder incl control/disparity;176 BCD frequency values exact");$finish;
end endmodule
