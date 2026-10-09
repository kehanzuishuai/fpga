`timescale 1ns/1ps
// Full actual synth -> actual DAC PCM capture -> FFT/CDC/render/TMDS.
module tb_visual_system #(parameter DIAGNOSTIC=0);
 reg ac=0,pc=0,rst_n=0,ev=0;reg [6:0]note=60;
 always #40.690104167 ac=~ac;always #20 pc=~pc;
 wire ready,pv;wire signed [23:0]pcm;wire [5:0]voice_count;
 wire signed [23:0]vx,vy;
 synth_top synth(.clk(ac),.rst_n(rst_n),.event_valid(ev),.event_note_on(1'b1),
 .event_note(note),.event_velocity(8'd100),.event_waveform(2'd0),.event_ready(ready),
 .morph_enable(1'b0),.morph_control(10'd0),.test_enable(DIAGNOSTIC!=0),
 .visual_pcm_valid(pv),.visual_pcm(pcm),.visual_voice_x(vx),.visual_voice_y(vy),.active_voice_count(voice_count));
 wire [9:0]b,g,r;wire [31:0]fd,wd,sd;
 audio_visualizer dut(ac,rst_n,pv,pcm,1'b1,vx,vy,pc,rst_n,b,g,r,fd,wd,sd);
 wire rx_de;wire [7:0]rx_r,rx_g,rx_b;
 integer rx_pixels,rx_blanks,rx_errors;
 tmds_stream_checker receiver(pc,dut.display_rst_n,dut.de_d,dut.hs_d,dut.vs_d,
 dut.r,dut.g,dut.b,r,g,b,rx_de,rx_r,rx_g,rx_b,rx_pixels,rx_blanks,rx_errors);
 reg [1:0] de_pipe=0,hs_pipe=3,vs_pipe=3;
 always @(posedge pc)begin
 if(!dut.display_rst_n)begin de_pipe<=0;hs_pipe<=3;vs_pipe<=3;end
 else begin
 de_pipe<={de_pipe[0],dut.de};hs_pipe<={hs_pipe[0],dut.hs};vs_pipe<={vs_pipe[0],dut.vs};
 #1;if({dut.de_d,dut.hs_d,dut.vs_d}!=={de_pipe[1],hs_pipe[1],vs_pipe[1]})
   $fatal(1,"renderer timing pipeline mismatch");
 end end
 task send(input [6:0]key);
 begin @(negedge ac);while(!ready)@(negedge ac);note=key;ev=1;@(negedge ac);ev=0;end endtask
 integer samples=0,last_sample=0,cycles=0,pcmfile,fftfile,fft_frame=0;
 integer clips=0,k,statsfile;
 always @(posedge ac) if(rst_n)begin
 cycles=cycles+1;
 if(pv)begin
 if(DIAGNOSTIC)begin
   $fwrite(pcmfile,"%0d\n",$signed(pcm[23:8]));
   if(pcm==24'sh7fffff || pcm==24'sh800000)clips=clips+1;
 end
 if(samples && cycles-last_sample!=256)$fatal(1,"visualizer changed audio rate");
 last_sample=cycles;samples=samples+1;
 end
 if(DIAGNOSTIC && dut.bin_valid)begin
   $fwrite(fftfile,"%0d %0d %0d %0d %0d\n",fft_frame,dut.unused_bin_index,dut.unused_bin_re,dut.unused_bin_im,dut.power_value);
   if(dut.unused_bin_index==1023)fft_frame=fft_frame+1;
 end
 end
 integer frames=0,colored=0,pixels=0,outfile,decodedfile,decoded_pixels=0;
 always @(negedge pc)if(rst_n && dut.display_rst_n)begin
 if(dut.x==0 && dut.y==0)frames=frames+1;
 if(dut.de_d && frames==(DIAGNOSTIC?7:5))begin
   if((^{dut.r,dut.g,dut.b})===1'bx)$fatal(1,"unknown rendered pixel");
   $fwrite(outfile,"%c%c%c",dut.r,dut.g,dut.b);pixels=pixels+1;
   if(dut.g>100 || dut.b>100)colored=colored+1;
 end
 if(rx_de && frames==(DIAGNOSTIC?7:5))begin
   $fwrite(decodedfile,"%c%c%c",rx_r,rx_g,rx_b);decoded_pixels=decoded_pixels+1;
 end
 if(frames==(DIAGNOSTIC?8:6))begin
   if(voice_count!=(DIAGNOSTIC?32:4) || !dut.render.initialized || colored<100 || pixels!=640*480 || fd!=0)
      $fatal(1,"system display count=%0d colored=%0d pixels=%0d drops=%0d",voice_count,colored,pixels,fd);
   $fclose(outfile);
   $fclose(decodedfile);
   if(decoded_pixels!=640*480 || rx_errors || rx_blanks==0)
     $fatal(1,"final TMDS image/control verification failed");
   if(DIAGNOSTIC)begin
     if(fft_frame<2 || !dut.render.peak_valid)$fatal(1,"32 Voice spectrum not ready");
     $fclose(pcmfile);$fclose(fftfile);
     statsfile=$fopen("sim_out_visual/voice32_display.txt","w");
     $fwrite(statsfile,"%0d %0d %0d\n",dut.render.peak_hz,samples,clips);
     for(k=0;k<512;k=k+1)$fwrite(statsfile,"%0d\n",dut.render.spectrum[k]);
     $fclose(statsfile);
   end
   $display("PASS synth->actual DAC PCM->hardware FFT->CDC->waveform/phase/spectrum->TMDS->decoded RGB; %0d samples,%0d colored pixels,%0d recovered pixels",samples,colored,decoded_pixels);
   rst_n=0;#1;if(voice_count!==0)$fatal(1,"reset left active Voices");
   $finish;
 end
 end
 initial begin
 if(DIAGNOSTIC)outfile=$fopen("sim_out_visual/rtl_display_32.ppm","wb");
 else outfile=$fopen("sim_out_visual/rtl_display.ppm","wb");
 if(outfile==0)$fatal(1,"cannot open pixel output");
 $fwrite(outfile,"P6\n640 480\n255\n");
 if(DIAGNOSTIC)decodedfile=$fopen("sim_out_visual/tmds_display_32.ppm","wb");
 else decodedfile=$fopen("sim_out_visual/tmds_display.ppm","wb");
 if(!decodedfile)$fatal(1,"cannot open decoded TMDS output");
 $fwrite(decodedfile,"P6\n640 480\n255\n");
 if(DIAGNOSTIC)begin
 pcmfile=$fopen("sim_out_visual/voice32_pcm.txt","w");
 fftfile=$fopen("sim_out_visual/voice32_fft.txt","w");
 if(pcmfile==0 || fftfile==0)$fatal(1,"cannot open diagnostic output");end
 #1;rst_n=1;#1;rst_n=0;repeat(5)@(negedge ac);rst_n=1;
 if(!DIAGNOSTIC)begin send(60);send(64);send(67);send(72);end
 end
 initial if($test$plusargs("smoke"))begin
 #200000;
 if(rx_errors || rx_pixels<1000 || rx_blanks<100)$fatal(1,"TMDS pipeline smoke failure");
 $fclose(outfile);$fclose(decodedfile);
 $display("PASS actual board synth/display pipeline fast TMDS smoke");$finish;
 end
 initial begin #150000000;$fatal(1,"visual system timeout");end
endmodule
