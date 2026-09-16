`default_nettype none
// Optional lossless event front-end; leaves synth_core's established interface intact.
module synth_event_frontend #(
  parameter int VOICES=32, parameter int SAMPLE_W=24, parameter int SAMPLE_RATE=48000, parameter int FIFO_DEPTH=16
) (
  input logic clk,rst_n,sample_tick, input logic event_valid,event_note_on,
  input logic [6:0] event_note, input logic [7:0] event_velocity, input logic [1:0] event_waveform, input logic [9:0] event_morph,
  output logic event_ready, input logic test_enable,
  output logic signed [SAMPLE_W-1:0] audio_out, output logic [VOICES-1:0] active_debug
);
  logic out_valid,out_note_on; logic [6:0] out_note; logic [7:0] out_velocity; logic [1:0] out_waveform; logic [9:0] out_morph;
  note_event_fifo #(.DEPTH(FIFO_DEPTH)) fifo(.clk,.rst_n,.in_valid(event_valid),.in_ready(event_ready),.in_note_on(event_note_on),.in_note(event_note),.in_velocity(event_velocity),.in_waveform(event_waveform),.in_morph(event_morph),.out_valid,.out_ready(1'b1),.out_note_on,.out_note,.out_velocity,.out_waveform,.out_morph,.level());
  synth_core #(.VOICES(VOICES),.SAMPLE_W(SAMPLE_W),.SAMPLE_RATE(SAMPLE_RATE)) core(.clk,.rst_n,.sample_tick,.note_on(out_valid&&out_note_on),.note_off(out_valid&&!out_note_on),.midi_note(out_note),.velocity(out_velocity),.waveform(out_waveform),.morph(out_morph),.test_enable,.audio_out,.active_debug,.active_voice_count(),.audio_peak(),.pcm_strobe(),.pcm_sample(),.dbg_note_event(),.dbg_audio_onset(),.dbg_clip(),.latency_valid(),.latency_samples());
endmodule
`default_nettype wire
