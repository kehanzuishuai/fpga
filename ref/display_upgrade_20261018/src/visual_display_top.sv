`default_nettype none
// Board-boundary adapter: feed final PCM at the actual DAC capture boundary.
module visual_display_top(
 input wire clk_50m,rst_n,audio_clk,audio_rst_n,pcm_valid,
 input wire signed [23:0] pcm,input wire xy_enable,
 input wire signed [23:0] xy_x,xy_y,
 output wire [2:0] video_d_p,video_d_n,output wire video_ck_p,video_ck_n
);
 wire pixel_clk,serial_clk,locked;
 visual_video_clock u_video_clock(clk_50m,rst_n,pixel_clk,serial_clk,locked);
 wire video_reset_async=rst_n && locked;
 reg release_meta,video_rst_n;
 always @(posedge pixel_clk or negedge video_reset_async)
 if(!video_reset_async)begin release_meta<=0;video_rst_n<=0;end
 else begin release_meta<=1;video_rst_n<=release_meta;end
 wire [9:0] blue,green,red;wire [31:0] unused_fft,unused_wave,unused_spec;
 audio_visualizer u_visualizer(audio_clk,audio_rst_n,pcm_valid,pcm,xy_enable,xy_x,xy_y,
 pixel_clk,video_rst_n,blue,green,red,unused_fft,unused_wave,unused_spec);
 visual_dvi_io u_dvi(pixel_clk,serial_clk,video_rst_n,blue,green,red,
 video_d_p,video_d_n,video_ck_p,video_ck_n);
endmodule
`default_nettype wire
