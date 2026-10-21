`default_nettype none
// CEA 1920x1080p30: 74.25MHz / (2200*1125) = 30Hz, positive HS/VS.
module visual_raster(input wire clk,rst_n,output reg [11:0] x,y,
 output wire de,hsync,vsync,blank_start);
 assign de=x<1920 && y<1080;
 assign hsync=x>=2008 && x<2052;
 assign vsync=y>=1084 && y<1089;
 assign blank_start=x==0 && y==1080;
 always @(posedge clk or negedge rst_n)
 if(!rst_n)begin x<=0;y<=0;end
 else if(x==2199)begin x<=0;if(y==1124)y<=0;else y<=y+1'b1;end
 else x<=x+1'b1;
endmodule
`default_nettype wire
