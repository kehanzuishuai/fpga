`default_nettype none
module visual_raster(
 input wire clk,rst_n,output reg [9:0] x,y,
 output wire de,hsync,vsync,blank_start
);
 assign de=(x<640 && y<480);
 assign hsync=!(x>=656 && x<752);
 assign vsync=!(y>=490 && y<492);
 assign blank_start=(x==0 && y==480);
 always @(posedge clk or negedge rst_n)
 if(!rst_n) begin x<=0;y<=0;end
 else if(x==799) begin x<=0;if(y==524)y<=0;else y<=y+1'b1;end
 else x<=x+1'b1;
endmodule
`default_nettype wire
