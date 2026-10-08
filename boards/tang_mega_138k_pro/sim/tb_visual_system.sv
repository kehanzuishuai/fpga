`timescale 1ns/1ps
// Full actual synth -> actual DAC PCM capture -> FFT/CDC/render/TMDS.
module tb_visual_system;
 reg ac=0,pc=0,rst_n=0,ev=0;reg [6:0]note=60;
 always #40.690104167 ac=~ac;always #20 pc=~pc;
 wire ready,pv;wire signed [23:0]pcm;wire [5:0]voice_count;
 wire signed [23:0]vx,vy;
 synth_top synth(.clk(ac),.rst_n(rst_n),.event_valid(ev),.event_note_on(1'b1),
 .event_note(note),.event_velocity(8'd100),.event_waveform(2'd0),.event_ready(ready),
 .morph_enable(1'b0),.morph_control(10'd0),.test_enable(1'b0),
 .visual_pcm_valid(pv),.visual_pcm(pcm),.visual_voice_x(vx),.visual_voice_y(vy),.active_voice_count(voice_count));
 wire [9:0]b,g,r;wire [31:0]fd,wd,sd;
 audio_visualizer dut(ac,rst_n,pv,pcm,1'b1,vx,vy,pc,rst_n,b,g,r,fd,wd,sd);
 task send(input [6:0]key);
 begin @(negedge ac);while(!ready)@(negedge ac);note=key;ev=1;@(negedge ac);ev=0;end endtask
 integer samples=0,last_sample=0,cycles=0;
 always @(posedge ac) if(rst_n)begin
 cycles=cycles+1;
 if(pv)begin
 if(samples && cycles-last_sample!=256)$fatal(1,"visualizer changed audio rate");
 last_sample=cycles;samples=samples+1;
 end end
 integer frames=0,colored=0,pixels=0,outfile;
 always @(negedge pc)if(rst_n && dut.display_rst_n)begin
 if(dut.x==0 && dut.y==0)frames=frames+1;
 if(dut.de_d && frames==5)begin
   if((^{dut.r,dut.g,dut.b})===1'bx)$fatal(1,"unknown rendered pixel");
   $fwrite(outfile,"%c%c%c",dut.r,dut.g,dut.b);pixels=pixels+1;
   if(dut.g>100 || dut.b>100)colored=colored+1;
 end
 if(frames==6)begin
   if(voice_count!=4 || !dut.render.initialized || colored<100 || pixels!=640*480 || fd!=0)
      $fatal(1,"system display count=%0d colored=%0d pixels=%0d drops=%0d",voice_count,colored,pixels,fd);
   $fclose(outfile);
   $display("PASS synth->actual DAC PCM->hardware FFT->CDC->waveform/phase/spectrum->TMDS; %0d samples,%0d colored pixels",samples,colored);
   $finish;
 end
 end
 initial begin
 outfile=$fopen("sim_out_visual/rtl_display.ppm","wb");$fwrite(outfile,"P6\n640 480\n255\n");
 #1;rst_n=1;#1;rst_n=0;repeat(5)@(negedge ac);rst_n=1;
 send(60);send(64);send(67);send(72);
 end
 initial begin #150000000;$fatal(1,"visual system timeout");end
endmodule
