`timescale 1ns/1ps
// Test current src (AMY partial engine), not legacy rtl or board wavetable core.
module tb_current_piano;
 reg clk=0,rst_n=0,tick=0,on=0,off=0;
 reg [6:0] note=60;reg [7:0] vel=100;
 always #5 clk=~clk;
 integer cycle=0,nonzero=0,frames=0,i,waits;
 always @(negedge clk)begin cycle=cycle+1;tick=cycle%256==0;end
 wire ready,strobe,clip;wire signed [23:0] pcm,audio;
 wire [31:0] active;wire [5:0] count;
 synth_core dut(.clk(clk),.rst_n(rst_n),.sample_tick(tick),.note_on(on),.note_off(off),
 .midi_note(note),.velocity(vel),.waveform(2'b00),.morph_enable(1'b0),.morph(10'd0),
 .test_enable(1'b0),.hammer_enable(1'b1),.fx_ctrl(5'b10011),.event_ready(ready),
 .audio_out(audio),.active_debug(active),.active_voice_count(count),.pcm_strobe(strobe),
 .pcm_sample(pcm),.dbg_clip(clip));
 genvar g;
 generate for(g=0;g<32;g=g+1)begin : MONITOR
  always @(posedge clk)if(rst_n && dut.u_bank.G_PARTIAL.G_VOICE[g].u_voice.dbg_overrun)
   $fatal(1,"piano voice %0d exceeded 256-clock budget",g);
 end endgenerate
 always @(posedge clk)begin
  #1;if(rst_n && tick)begin
   if(^audio===1'bx)$fatal(1,"unknown current piano PCM");
   if(audio!=0)nonzero=nonzero+1;
   frames=frames+1;
  end
 end
 task event_send;
 input is_on;input [6:0] pitch;input [7:0] velocity;
 begin
  @(negedge clk);note=pitch;vel=velocity;waits=0;
  while(!ready && waits<20000)begin @(negedge clk);waits=waits+1;end
  if(!ready)$fatal(1,"piano loader backpressure stuck");
  on=is_on;off=!is_on;@(negedge clk);on=0;off=0;
 end endtask
 initial begin
  #1;rst_n=1;#1;rst_n=0;repeat(5)@(negedge clk);rst_n=1;
  for(i=0;i<32;i=i+1)event_send(1,48+i,100);
  repeat(8000)@(negedge clk);
  if(active!==32'hffffffff || count!=32)$fatal(1,"current piano not 32 voice polyphonic");
  repeat(4096*256)@(negedge clk);
  if(nonzero<100)$fatal(1,"current piano silent");
  event_send(1,84,80);repeat(30000)@(negedge clk);
  event_send(1,84,0);for(i=0;i<32;i=i+1)event_send(0,48+i,0);
  repeat(16000*256)@(negedge clk);
  if(|active)$fatal(1,"current piano stuck release");
  rst_n=0;repeat(5)@(negedge clk);rst_n=1;repeat(2048)@(negedge clk);
  if(active!=0 || audio!=0)$fatal(1,"piano reset does not clear audio");
  $display("PASS current src piano: 32 voices, loader backpressure, 256-clock budget, steal, velocity-zero/release and reset; %0d frames",frames);$finish;
 end
 initial begin #200000000;$fatal(1,"piano watchdog");end
endmodule
