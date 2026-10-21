`timescale 1ns/1ps
module tb_hud_pipeline;
reg clk=0,rst=0;always#5 clk=~clk;
reg[9:0]x=0,y=0;reg[57:0]s=0;wire a,b,aa,ab,oa,ob;
reg[5:0]expected=0;integer xx,yy,k,checks=0;
piano_status_overlay #(.INFO_Y(164),.DETAIL_Y(176),.KEY_X(8),.KEY_Y(198),.KEY_PITCH(24),.KEY_WIDTH(20),.KEY_HEIGHT(10)) o(x,y,s,b,ab,ob);
piano_status_overlay_pipeline #(.INFO_Y(164),.DETAIL_Y(176),.KEY_X(8),.KEY_Y(198),.KEY_PITCH(24),.KEY_WIDTH(20),.KEY_HEIGHT(10)) n(x,y,s,clk,rst,a,aa,oa);
always@(posedge clk)expected<={expected[2:0],b,ab,ob};
initial begin
repeat(3)@(negedge clk);rst=1;
for(k=0;k<16;k=k+1)begin
 @(negedge clk);s={16'(1<<k),6'(2*k+1),24'habcd12,7'(60+k),1'b1,4'(k)};
 repeat(4)@(negedge clk);
 for(yy=164;yy<208;yy=yy+1)for(xx=0;xx<640;xx=xx+1)begin
  @(negedge clk);x=10'(xx);y=10'(yy);
  @(posedge clk);#1;if({a,aa,oa}!==expected[5:3])$fatal(1,"HUD pipeline mismatch key%0d at%0d,%0d",k,xx,yy);checks=checks+1;
 end
end
$display("PASS %0d HUD pixels16notes/onehotkeys inclB;2cycle latency",checks);$finish;
end endmodule
