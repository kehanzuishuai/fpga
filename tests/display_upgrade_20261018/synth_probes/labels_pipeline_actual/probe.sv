module display_synthesis_probe(
input wire audio_clk,pixel_clk,audio_rst_n,pixel_rst_n,pcm_valid,
input wire signed[23:0]pcm,input wire[57:0]status_audio,
output wire[9:0]b,g,r,output wire[31:0]fd,wd,sd);
audio_visualizer #(.STATUS_ENABLE(1),.MAPPING_CONFIRMED(0)) u(
.audio_clk(audio_clk),.audio_rst_n(audio_rst_n),.pcm_valid(pcm_valid),.pcm(pcm),
.xy_enable(1'b0),.xy_x(24'sd0),.xy_y(24'sd0),.pixel_clk(pixel_clk),.pixel_rst_n(pixel_rst_n),
.tmds_blue(b),.tmds_green(g),.tmds_red(r),.fft_dropped(fd),.wave_dropped(wd),.spectrum_dropped(sd),.status_audio(status_audio));
endmodule