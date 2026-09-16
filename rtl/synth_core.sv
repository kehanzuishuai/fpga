`default_nettype none
module synth_core #(
  parameter int SAMPLE_RATE=48000,parameter int SAMPLE_W=24,parameter int VOICES=32,
  parameter int MASTER_ATTEN_SHIFT=0
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
  output logic latency_valid, output logic [23:0] latency_samples,
  output logic [5:0] mix_gain_shift,
  output logic visual_sample_strobe,
  output logic signed [SAMPLE_W-1:0] lissajous_x,lissajous_y
);
  localparam int MIX_W=SAMPLE_W+$clog2(VOICES);
  localparam logic signed [MIX_W-1:0] CLIP_MAX={{(MIX_W-SAMPLE_W){1'b0}},1'b0,{(SAMPLE_W-1){1'b1}}};
  localparam logic signed [MIX_W-1:0] CLIP_MIN={{(MIX_W-SAMPLE_W){1'b1}},1'b1,{(SAMPLE_W-1){1'b0}}};
  logic [VOICES*SAMPLE_W-1:0] samples;
  logic signed [MIX_W-1:0] sum;
  logic signed [MIX_W-1:0] normalized_sum;
  logic test_d; logic [$clog2(VOICES+1)-1:0] test_count;
  localparam int TEST_COUNT_W=$clog2(VOICES+1);
  localparam logic [TEST_COUNT_W-1:0] TEST_VOICES=VOICES[TEST_COUNT_W-1:0];
  logic bank_on, bank_off; logic [6:0] bank_note;
  logic test_force; logic [6:0] test_note;
  logic allocation_valid;logic [$clog2(VOICES)-1:0] allocation_index;
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin test_d<=0; test_count<='0; end
    else if(sample_tick) begin
      test_d<=test_enable;
      if(!test_enable) test_count<='0;
      else if(!test_d) test_count<={{(TEST_COUNT_W-1){1'b0}},1'b1};
      else if(test_count<TEST_VOICES) test_count<=test_count+1'b1;
    end
  end
  test_mode #(.VOICES(VOICES)) u_test_mode(
    .enable(test_enable && test_count<TEST_VOICES),
    .index(test_count[$clog2(VOICES)-1:0]),.force_start(test_force),.midi_note(test_note));
  always @* begin
    bank_on=note_on; bank_off=note_off; bank_note=midi_note;
    if(test_force) begin bank_on=sample_tick; bank_off=0; bank_note=test_note; end
  end
  voice_bank #(.VOICES(VOICES),.SAMPLE_W(SAMPLE_W),.SAMPLE_RATE(SAMPLE_RATE)) u_bank(.clk,.rst_n,.sample_tick,.note_on(bank_on),.note_off(bank_off),.midi_note(bank_note),.velocity,.waveform,.morph,.voice_samples(samples),.voice_active(active_debug),.allocation_valid,.allocation_index);
  tree_mixer #(.VOICES(VOICES),.SAMPLE_W(SAMPLE_W)) u_mixer(.samples,.mixed(sum));
  polyphony_gain #(.VOICES(VOICES),.SAMPLE_W(SAMPLE_W),.MASTER_ATTEN_SHIFT(MASTER_ATTEN_SHIFT)) u_gain(
    .mixed_in(sum),.active_voice_count,.scaled_out(normalized_sum),.applied_shift(mix_gain_shift));
  saturator #(.IN_W(MIX_W),.OUT_W(SAMPLE_W)) u_sat(.in(normalized_sum),.out(audio_out));
  audio_telemetry #(.VOICES(VOICES),.SAMPLE_W(SAMPLE_W)) u_telemetry(.clk,.rst_n,.sample_tick,.active_voices(active_debug),.audio(audio_out),.active_voice_count,.audio_peak,.pcm_strobe,.pcm_sample);
  latency_monitor #(.SAMPLE_W(SAMPLE_W),.COUNT_W(24),.VOICES(VOICES)) u_latency(.clk,.rst_n,.sample_tick,.event_strobe(allocation_valid),.event_voice_index(allocation_index),.voice_samples(samples),.dbg_event(dbg_note_event),.dbg_audio(dbg_audio_onset),.latency_valid,.latency_samples);
  always @* begin visual_sample_strobe=sample_tick;lissajous_x=audio_out;end
  always @(posedge clk or negedge rst_n)
    if(!rst_n)lissajous_y<='0;
    else if(sample_tick)lissajous_y<=audio_out;
  always @(posedge clk or negedge rst_n)
    if(!rst_n) dbg_clip<=0;
    else begin dbg_clip<=0; if(sample_tick && (normalized_sum > CLIP_MAX || normalized_sum < CLIP_MIN)) dbg_clip<=1; end
  // Test mode injects 32 two-semitone-spaced MIDI frequencies, one event/tick.
  // still passes through the normal allocator and oscillator paths.
endmodule
`default_nettype wire
