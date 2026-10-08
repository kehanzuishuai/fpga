
module synth_event_frontend #(
    parameter VOICES      = 32,
    parameter SAMPLE_W    = 24,
    parameter SAMPLE_RATE = 48000,
    parameter FIFO_DEPTH  = 16,
    parameter FIFO_ADDR_W = 4,
    parameter IDX_W       = 5,
    parameter LOG2_VOICES = 5,
    parameter COUNT_W     = LOG2_VOICES + 1
)(
    input                              clk,
    input                              rst_n,
    input                              sample_tick,

    input                              event_valid,
    input                              event_note_on,
    input      [6:0]                   event_note,
    input      [7:0]                   event_velocity,
    input      [1:0]                   event_waveform,

    /* Continuous control: deliberately bypasses the Note FIFO. */
    input                              morph_enable,
    input      [9:0]                   event_morph,

    output                             event_ready,
    input                              test_enable,

    output signed [SAMPLE_W-1:0]       audio_out,
    output     [VOICES-1:0]            active_debug,
    output     [FIFO_ADDR_W:0]         fifo_level,
    output     [COUNT_W-1:0]           active_voice_count,
    output     [SAMPLE_W-1:0]          audio_peak,
    output                             pcm_strobe,
    output signed [SAMPLE_W-1:0]       pcm_sample,
    output                             dbg_note_event,
    output                             dbg_audio_onset,
    output                             dbg_clip,
    output                             latency_valid,
    output     [23:0]                  latency_samples,
    output     [5:0]                   mix_gain_shift,
    output                             visual_sample_strobe,
    output signed [SAMPLE_W-1:0]       lissajous_x,
    output signed [SAMPLE_W-1:0]       lissajous_y,
    output signed [SAMPLE_W-1:0]       visual_voice_x,visual_voice_y
);

wire       out_valid;
wire       out_note_on;
wire [6:0] out_note;
wire [7:0] out_velocity;
wire [1:0] out_waveform;

note_event_fifo #(
    .DEPTH (FIFO_DEPTH),
    .ADDR_W(FIFO_ADDR_W)
) u_fifo (
    .clk          (clk),
    .rst_n        (rst_n),
    .in_valid     (event_valid),
    .in_ready     (event_ready),
    .in_note_on   (event_note_on),
    .in_note      (event_note),
    .in_velocity  (event_velocity),
    .in_waveform  (event_waveform),
    .out_valid    (out_valid),
    .out_ready    (1'b1),
    .out_note_on  (out_note_on),
    .out_note     (out_note),
    .out_velocity (out_velocity),
    .out_waveform (out_waveform),
    .level        (fifo_level)
);

synth_core #(
    .VOICES      (VOICES),
    .SAMPLE_W    (SAMPLE_W),
    .SAMPLE_RATE (SAMPLE_RATE),
    .IDX_W       (IDX_W),
    .LOG2_VOICES (LOG2_VOICES),
    .COUNT_W     (COUNT_W)
) u_core (
    .clk                 (clk),
    .rst_n               (rst_n),
    .sample_tick         (sample_tick),
    .note_on             (out_valid && out_note_on),
    .note_off            (out_valid && !out_note_on),
    .midi_note           (out_note),
    .velocity            (out_velocity),
    .waveform            (out_waveform),
    .morph_enable        (morph_enable),
    .morph               (event_morph),
    .test_enable         (test_enable),
    .audio_out           (audio_out),
    .active_debug        (active_debug),
    .active_voice_count  (active_voice_count),
    .audio_peak          (audio_peak),
    .pcm_strobe          (pcm_strobe),
    .pcm_sample          (pcm_sample),
    .dbg_note_event      (dbg_note_event),
    .dbg_audio_onset     (dbg_audio_onset),
    .dbg_clip            (dbg_clip),
    .latency_valid       (latency_valid),
    .latency_samples     (latency_samples),
    .mix_gain_shift      (mix_gain_shift),
    .visual_sample_strobe(visual_sample_strobe),
    .lissajous_x         (lissajous_x),
    .lissajous_y         (lissajous_y)
    ,.visual_voice_x(visual_voice_x),.visual_voice_y(visual_voice_y)
);

endmodule
