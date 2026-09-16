`timescale 1ns/1ps
module tb_configs;
 logic clk=0,rst_n=0,t=0,on=0; logic[6:0] n=60; logic[7:0] v=127; logic[1:0] w=0; logic[9:0] m=0; logic signed[23:0] a4,a8,a16,a32; logic[3:0]x4;logic[7:0]x8;logic[15:0]x16;logic[31:0]x32;
 always #5 clk=~clk; always @(posedge clk)t<=~t;
 synth_core #(.VOICES(4))s4(.clk,.rst_n,.sample_tick(t),.note_on(on),.note_off(0),.midi_note(n),.velocity(v),.waveform(w),.morph(m),.test_enable(0),.audio_out(a4),.active_debug(x4),.active_voice_count(),.audio_peak(),.pcm_strobe(),.pcm_sample(),.dbg_note_event(),.dbg_audio_onset(),.dbg_clip(),.latency_valid(),.latency_samples());
 synth_core #(.VOICES(8))s8(.clk,.rst_n,.sample_tick(t),.note_on(on),.note_off(0),.midi_note(n),.velocity(v),.waveform(w),.morph(m),.test_enable(0),.audio_out(a8),.active_debug(x8),.active_voice_count(),.audio_peak(),.pcm_strobe(),.pcm_sample(),.dbg_note_event(),.dbg_audio_onset(),.dbg_clip(),.latency_valid(),.latency_samples());
 synth_core #(.VOICES(16))s16(.clk,.rst_n,.sample_tick(t),.note_on(on),.note_off(0),.midi_note(n),.velocity(v),.waveform(w),.morph(m),.test_enable(0),.audio_out(a16),.active_debug(x16),.active_voice_count(),.audio_peak(),.pcm_strobe(),.pcm_sample(),.dbg_note_event(),.dbg_audio_onset(),.dbg_clip(),.latency_valid(),.latency_samples());
 synth_core #(.VOICES(32))s32(.clk,.rst_n,.sample_tick(t),.note_on(on),.note_off(0),.midi_note(n),.velocity(v),.waveform(w),.morph(m),.test_enable(0),.audio_out(a32),.active_debug(x32),.active_voice_count(),.audio_peak(),.pcm_strobe(),.pcm_sample(),.dbg_note_event(),.dbg_audio_onset(),.dbg_clip(),.latency_valid(),.latency_samples());
 initial begin repeat(3)@(posedge clk);rst_n=1;@(negedge clk);on=1;@(negedge clk);on=0;repeat(20)@(posedge clk);if(x4!=1||x8!=1||x16!=1||x32!=1)$fatal(1,"configuration allocation failed");$display("TB_CONFIGS PASS: 4/8/16/32 Voice configurations");$finish;end
endmodule
