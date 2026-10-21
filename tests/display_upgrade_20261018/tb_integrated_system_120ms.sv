`timescale 1ns/1ps
module tb_integrated_system;
reg clk=0,rst_n=0;always #10 clk=~clk;
reg [15:0] touch=0;wire scl_new,scl_old,sdo;
ttp229_bfm #(.KEY16(1),.MULTI(1)) keyboard(touch,scl_new,sdo);
wire [2:0] audio_new,audio_old,pcm_new,pcm_old;
wire pa_new,pa_old;wire [2:0] vp,vn;wire cp,cn;
tang_mega_138k_pro_top u_new(
.clk_50m(clk),.rst_n(rst_n),.ttp229_scl(scl_new),.ttp229_sdo(sdo),
.i2s_bclk(audio_new[2]),.i2s_lrck(audio_new[1]),.i2s_data(audio_new[0]),
.pcm5102_bclk(pcm_new[2]),.pcm5102_lrck(pcm_new[1]),.pcm5102_data(pcm_new[0]),
.audio_pa_en(pa_new),.video_d_p(vp),.video_d_n(vn),.video_ck_p(cp),.video_ck_n(cn));
baseline_board u_old(
.clk_50m(clk),.rst_n(rst_n),.ttp229_scl(scl_old),.ttp229_sdo(sdo),
.i2s_bclk(audio_old[2]),.i2s_lrck(audio_old[1]),.i2s_data(audio_old[0]),
.pcm5102_bclk(pcm_old[2]),.pcm5102_lrck(pcm_old[1]),.pcm5102_data(pcm_old[0]),
.audio_pa_en(pa_old));
integer cycles=0,captures=0,nonzero=0,fftframes=0;
always @(posedge u_new.clk_12m288)if(u_new.synth_rst_n)begin
cycles=cycles+1;
if(u_new.visual_pcm_valid!==u_new.u_synth_top.u_pcm5102_tx.capture)$fatal(1,"DAC capture edge mismatch");
if(u_new.visual_pcm_valid)begin
 captures=captures+1;
 if(u_new.visual_pcm!==u_new.u_synth_top.audio_out)$fatal(1,"final PCM tap mismatch");
 if(u_new.visual_pcm!=0)nonzero=nonzero+1;
end
#0.001;
if({audio_new,pcm_new,pa_new,scl_new}!=={audio_old,pcm_old,pa_old,scl_old})
 $fatal(1,"original/integrated DAC or keyboard pins differ at cycle %0d",cycles);
if(u_new.u_synth_top.audio_out!==u_old.u_synth_top.audio_out)$fatal(1,"original/integrated PCM differs");
end
always @(posedge u_new.clk_12m288)
if(u_new.G_DISPLAY.u_visual.bin_valid && &u_new.G_DISPLAY.u_visual.unused_bin_index)fftframes=fftframes+1;
wire rxde;wire [7:0] rr,rg,rb;integer pixels,blanks,errors;
tmds_stream_checker checker_rx(
.clk(u_new.pixel_clk),.rst_n(u_new.G_DISPLAY.u_visual.display_rst_n),
.source_de(u_new.G_DISPLAY.u_visual.de_d),.source_hs(u_new.G_DISPLAY.u_visual.hs_d),
.source_vs(u_new.G_DISPLAY.u_visual.vs_d),
.source_r(u_new.G_DISPLAY.u_visual.hr),.source_g(u_new.G_DISPLAY.u_visual.hg),
.source_b(u_new.G_DISPLAY.u_visual.hb),
.red_word(u_new.video_red),.green_word(u_new.video_green),.blue_word(u_new.video_blue),
.rx_de(rxde),.rx_r(rr),.rx_g(rg),.rx_b(rb),.pixels(pixels),.blank_pixels(blanks),.errors(errors));
initial begin
#1;rst_n=1;#1;rst_n=0;#1000;rst_n=1;
#1000000;touch=16'h0003;
#9000000;force u_new.video_locked=0;
#200000;release u_new.video_locked;
#109800000;
if(captures<3000 || nonzero<1000 || fftframes<1)$fatal(1,"missing real audio/FFT activity");
if(u_new.active_voice_count!=2)$fatal(1,"voices not sounding");
if(u_new.G_DISPLAY.u_visual.status_pixel[57:42]!=16'h0003)$fatal(1,"display keys not real");
if(u_new.G_DISPLAY.u_visual.status_pixel[41:36]!=6'd2)$fatal(1,"display voice count");
if(u_new.G_DISPLAY.u_visual.status_pixel[35:12]==0)$fatal(1,"display amplitude not real");
if(u_new.G_DISPLAY.u_visual.status_pixel[11:5]!=7'd60 || !u_new.G_DISPLAY.u_visual.status_pixel[4])
 $fatal(1,"display note source");
if(!u_new.G_DISPLAY.u_visual.render.initialized || !u_new.G_DISPLAY.u_visual.render.peak_valid)
 $fatal(1,"actual PCM spectrum not displayed");
if(errors || pixels<640*480 || u_new.fft_dropped!=0)$fatal(1,"TMDS/data throughput");
$display("PASS integrated system: %0d audio clocks, %0d DAC captures, %0d nonzero frames, %0d FFT frames; %0d TMDS pixels; video relock leaves original PCM and both DACs bit-identical",cycles,captures,nonzero,fftframes,pixels);
$finish;
end
initial begin #140000000;$fatal(1,"integration timeout");end
endmodule

