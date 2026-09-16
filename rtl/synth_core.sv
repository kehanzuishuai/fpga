`default_nettype none
module synth_core #(
  parameter int SAMPLE_RATE=48000, parameter int SAMPLE_W=24, parameter int VOICES=32
) (
  input logic clk, input logic rst_n, input logic sample_tick,
  input logic note_on, note_off, input logic [6:0] midi_note,
  input logic [7:0] velocity, input logic [1:0] waveform, input logic [9:0] morph,
  input logic test_enable,
  output logic signed [SAMPLE_W-1:0] audio_out,
  output logic [VOICES-1:0] active_debug,
  output logic [$clog2(VOICES+1)-1:0] active_voice_count,
  output logic [SAMPLE_W-1:0] audio_peak,
  output logic pcm_strobe, output logic signed [SAMPLE_W-1:0] pcm_sample,
  output logic dbg_note_event, dbg_audio_onset, dbg_clip,
  output logic latency_valid, output logic [23:0] latency_samples
);
  localparam int MIX_W=SAMPLE_W+$clog2(VOICES);
  logic [VOICES*SAMPLE_W-1:0] samples;
  logic signed [MIX_W-1:0] sum;
  logic test_d; logic [$clog2(VOICES+1)-1:0] test_count;
  logic bank_on, bank_off; logic [6:0] bank_note;
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin test_d<=0; test_count<='0; end
    else if(sample_tick) begin
      test_d<=test_enable;
      if(!test_enable) test_count<='0;
      else if(!test_d) test_count<='0;
      else if(test_count<VOICES) test_count<=test_count+1'b1;
    end
  end
  always @* begin
    bank_on=note_on; bank_off=note_off; bank_note=midi_note;
    if(test_enable && test_count<VOICES) begin bank_on=sample_tick; bank_off=0; bank_note=7'd36+(test_count<<1); end
  end
  voice_bank #(.VOICES(VOICES),.SAMPLE_W(SAMPLE_W),.SAMPLE_RATE(SAMPLE_RATE)) u_bank(.clk,.rst_n,.sample_tick,.note_on(bank_on),.note_off(bank_off),.midi_note(bank_note),.velocity,.waveform,.morph,.voice_samples(samples),.voice_active(active_debug));
  tree_mixer #(.VOICES(VOICES),.SAMPLE_W(SAMPLE_W)) u_mixer(.samples,.mixed(sum));
  saturator #(.IN_W(MIX_W),.OUT_W(SAMPLE_W)) u_sat(.in(sum),.out(audio_out));
  audio_telemetry #(.VOICES(VOICES),.SAMPLE_W(SAMPLE_W)) u_telemetry(.clk,.rst_n,.sample_tick,.active_voices(active_debug),.audio(audio_out),.active_voice_count,.audio_peak,.pcm_strobe,.pcm_sample);
  latency_monitor #(.SAMPLE_W(SAMPLE_W),.COUNT_W(24)) u_latency(.clk,.rst_n,.sample_tick,.event_strobe(bank_on),.audio(audio_out),.dbg_event(dbg_note_event),.dbg_audio(dbg_audio_onset),.latency_valid,.latency_samples);
  always @(posedge clk or negedge rst_n)
    if(!rst_n) dbg_clip<=0;
    else begin dbg_clip<=0; if(sample_tick && (sum > 32'sh007f_ffff || sum < -32'sh0080_0000)) dbg_clip<=1; end
  // Test mode injects 32 two-semitone-spaced MIDI frequencies, one event/tick.
  // still passes through the normal allocator and oscillator paths.
endmodule
`default_nettype wire
