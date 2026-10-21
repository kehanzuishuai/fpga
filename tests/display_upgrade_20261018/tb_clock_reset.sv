`timescale 1ns/1ps
module tb_clock_reset;
reg clk=0,rst=0;always#10 clk=~clk;wire pc,sc,locked,rc;real last_edge=-100;integer k;
GSR GSR(.GSRI(1'b1));
visual_video_clock d(clk,rst,pc,sc,locked,rc);
always@(posedge pc)last_edge=$realtime;
always@(posedge locked)if($realtime-last_edge>0.001)$fatal(1,"lock release outside pixel edge");
initial begin
repeat(4)@(negedge clk);rst=1;
for(k=0;k<40;k=k+1)begin
 #7.111;d.ref_pll.test_lock=1;
 @(posedge d.ref_clk);#0.001;if(d.ref_ready_sync)$fatal(1,"ref synchronizer too early");
 repeat(4)@(posedge d.ref_clk);d.video_pll.test_lock=1;
 @(posedge pc);#0.001;if(locked)$fatal(1,"pixel synchronizer too early");
 repeat(4)@(posedge pc);#0.001;if(!locked)$fatal(1,"lock never released");
 #1.123;d.video_pll.test_lock=0;#0.001;if(locked)$fatal(1,"video lock loss not immediate");
 d.ref_pll.test_lock=0;#0.001;if(d.ref_ready_sync || locked)$fatal(1,"reference loss not immediate");
 repeat(4)@(posedge pc);
end
$display("PASS40ref/video relocks immediate reset assertion, synchronized release");$finish;
end endmodule
module PLL_INIT #(parameter CLK_PERIOD=20,MULTI_FAC=1)(input CLKIN,I_RST,PLLLOCK,output O_RST,O_LOCK,output[5:0]ICPSEL,output[2:0]LPFRES);
assign O_RST=I_RST;assign O_LOCK=PLLLOCK&&!I_RST;assign ICPSEL=0;assign LPFRES=0;endmodule
module visual_ref_PLL_MOD(input clkin,reset,output lock,output reg clkout0,output clkout1,input[5:0]icpsel,input[2:0]lpfres,input[1:0]lpfcap);
reg test_lock=0;initial clkout0=0;assign lock=test_lock;assign clkout1=0;always#18.518 clkout0=~clkout0;endmodule
module visual_PLL_MOD(input clkin,reset,output lock,output reg clkout0,clkout1,clkout2,input[5:0]icpsel,input[2:0]lpfres,input[1:0]lpfcap);
reg test_lock=0;initial begin clkout0=0;clkout1=0;clkout2=0;end assign lock=test_lock;always#1.347 clkout0=~clkout0;always#6.734 clkout1=~clkout1;always#6.734 clkout2=~clkout2;endmodule
