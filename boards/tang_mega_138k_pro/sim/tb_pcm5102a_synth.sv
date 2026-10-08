`timescale 1ns/1ps
module tb_pcm5102a_synth;
 reg clk=0,rst_n=0,event_valid=0,note_on=1;
 reg [6:0] note=60;
 wire ready,ob,ow,od,nb,nw,nd;
 wire [5:0] active;
 wire [31:0] frames,nonzero_frames;
 always #40.690104167 clk=~clk;
 synth_top dut(.clk(clk),.rst_n(rst_n),.event_valid(event_valid),
 .event_note_on(note_on),.event_note(note),.event_velocity(8'd100),.event_waveform(2'd0),
 .event_ready(ready),.morph_enable(1'b0),.morph_control(10'd0),.test_enable(1'b0),
 .i2s_bclk(ob),.i2s_lrck(ow),.i2s_data(od),.pcm_bclk(nb),.pcm_lrclk(nw),.pcm_data(nd),
 .active_voice_count(active));
 i2s_checker checker1(clk,rst_n,dut.dac_frame_capture,dut.audio_out,dut.audio_out,
 nb,nw,nd,frames,nonzero_frames);
 task event_send(input onoff,input [6:0] key);
 begin
   @(negedge clk);while(!ready) @(negedge clk);
   note_on=onoff;note=key;event_valid=1;
   @(negedge clk);event_valid=0;
 end endtask
 integer i;
 initial begin
   #1;rst_n=1;#1;rst_n=0;repeat(5) @(negedge clk);rst_n=1;
   event_send(1,60);event_send(1,64);event_send(1,67);event_send(1,72);
   repeat(256*160) @(negedge clk);
   if(active!=4 || nonzero_frames<100) $fatal(1,"synth has no valid four-voice audio count=%0d frames=%0d",active,nonzero_frames);
   for(i=0;i<28;i=i+1) event_send(1,7'(36+i));
   repeat(256*160) @(negedge clk);
   if(active!=32) $fatal(1,"32 voices not active: %0d",active);
   $display("PASS existing synth -> PCM5102A: four and 32 active voices, %0d bit-exact I2S frames (%0d nonzero)",frames,nonzero_frames);
   rst_n=0;repeat(5) @(negedge clk);rst_n=1;
   repeat(256*4) @(negedge clk);
   if(active!=0 || nonzero_frames!=0) $fatal(1,"synth reset");
   $display("PASS integrated synth reset: zero voices and zero PCM");$finish;
 end
 initial begin #20000000;$fatal(1,"integration timeout");end
endmodule
