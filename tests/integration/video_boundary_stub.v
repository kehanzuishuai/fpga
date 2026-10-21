`timescale 1ns/1ps
// Functional substitutes only: never in .gprj, no physical timing claim.
module visual_video_clock(input clk_50m,rst_n,output reg pixel_clk,serial_clk,output wire locked);
initial begin pixel_clk=0;serial_clk=0;end
always #20 pixel_clk=~pixel_clk;
always #4 serial_clk=~serial_clk;
assign locked=rst_n;
endmodule
module visual_dvi_io(input pixel_clk,serial_clk,rst_n,input [9:0] blue,green,red,
 output [2:0] d_p,d_n,output ck_p,ck_n);
assign d_p=0;assign d_n=7;assign ck_p=pixel_clk;assign ck_n=~pixel_clk;
endmodule
