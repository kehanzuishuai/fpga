`timescale 1ns/1ps
module tb_synth;
  localparam int CLK_PER=10; localparam int SAMPLE_DIV=2;
  logic clk=0,rst_n=0; logic sample_tick=0,note_on=0,note_off=0,test_enable=0;
  logic [6:0] midi_note=60; logic [7:0] velocity=127; logic [1:0] waveform=0; logic [9:0] morph=0;
  logic signed [23:0] audio; logic [31:0] active;
  logic dbg_clip,latency_valid; logic [23:0] latency_samples;
  int cycles=0;
  integer pcm_fd,metrics_fd,k,clip_count=0,latency_seen=0,measured_latency=0;
  function integer active_count(input logic [31:0] v);
    integer j; begin active_count=0; for(j=0;j<32;j=j+1) active_count=active_count+v[j]; end
  endfunction
  always #(CLK_PER/2) clk=~clk;
  always @(posedge clk) begin cycles<=cycles+1; sample_tick <= (cycles % SAMPLE_DIV)==0; end
  synth_core #(.VOICES(32)) dut(.clk,.rst_n,.sample_tick,.note_on,.note_off,.midi_note,.velocity,.waveform,.morph,.test_enable,.audio_out(audio),.active_debug(active),
    .active_voice_count(),.audio_peak(),.pcm_strobe(),.pcm_sample(),.dbg_note_event(),.dbg_audio_onset(),.dbg_clip,
    .latency_valid,.latency_samples);
  always @(posedge clk) if(rst_n && latency_valid) begin latency_seen<=1;measured_latency<=latency_samples;end
  task send_note(input [6:0] n); begin @(negedge clk); midi_note=n; note_on=1; @(negedge clk); note_on=0; repeat(SAMPLE_DIV); end endtask
  initial begin
    repeat(4) @(posedge clk); rst_n=1;
    // Single note and ADSR start/release.
    send_note(60); repeat(80) @(posedge clk); if(active!==32'h1) $fatal(1,"single voice did not become active");
    @(negedge clk); note_off=1; @(negedge clk); note_off=0; repeat(4000) @(posedge clk); if(active!==0) $fatal(1,"release did not complete");
    // Four voice polyphony.
    send_note(60); send_note(64); send_note(67); send_note(72); repeat(40) @(posedge clk); if(active_count(active)!==4) $fatal(1,"four-voice allocation failed");
    // Full 32 independent pitch test; frequencies enter through ordinary bank.
    @(negedge clk); test_enable=1; repeat(32*SAMPLE_DIV+40) @(posedge clk); if(active_count(active)!==32) $fatal(1,"32 voice test mode failed");
    // Export an actual mono signed-24 little-endian PCM capture for Python FFT.
    pcm_fd=$fopen("sim_out/test32_s24le.pcm","wb"); if(pcm_fd==0) $fatal(1,"cannot open PCM output");
    for(k=0;k<16384;k=k+1) begin
      @(posedge sample_tick); #1;
      $fwrite(pcm_fd,"%c%c%c",audio[7:0],audio[15:8],audio[23:16]);
      if(dbg_clip)clip_count=clip_count+1;
    end
    $fclose(pcm_fd);
    metrics_fd=$fopen("sim_out/rtl_metrics.csv","w");if(metrics_fd==0)$fatal(1,"cannot open metrics output");
    $fwrite(metrics_fd,"samples,clip_count,latency_valid,latency_samples\n%0d,%0d,%0d,%0d\n",16384,clip_count,latency_seen,measured_latency);
    $fclose(metrics_fd);
    // No free voice: allocator must retain 32 active voices after a new event.
    @(negedge clk); test_enable=0; send_note(100); repeat(20) @(posedge clk); if(active_count(active)!==32) $fatal(1,"voice stealing failed");
    if(audio===24'shx) $fatal(1,"audio unknown");
    $display("TB_SYNTH PASS: single, ADSR, 4 voices, 32 voices, test mode"); $finish;
  end
endmodule
