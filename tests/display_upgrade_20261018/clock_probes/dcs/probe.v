module clock_probe(input wire clk_50m,rst_n,output wire [2:0] video_d_p,video_d_n,output wire video_ck_p,video_ck_n);
wire pixel_clk,serial_clk,video_locked;
visual_video_clock u_video_clock(clk_50m,rst_n,pixel_clk,serial_clk,video_locked);
reg meta,reset_n;always@(posedge pixel_clk or negedge video_locked)if(!video_locked)begin meta<=0;reset_n<=0;end else begin meta<=1;reset_n<=meta;end
reg[9:0]word_data;always@(posedge pixel_clk)word_data<=word_data+1'b1;
visual_dvi_io u_video_io(pixel_clk,serial_clk,reset_n,word_data,word_data^10'h155,word_data^10'h2aa,video_d_p,video_d_n,video_ck_p,video_ck_n);
endmodule