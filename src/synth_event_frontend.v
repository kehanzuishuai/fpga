
module synth_event_frontend #(
    parameter REMOTE_ENABLE = 0,
    parameter VOICES      = 32,
    parameter SAMPLE_W    = 24,
    parameter SAMPLE_RATE = 48000,
    parameter FIFO_DEPTH  = 16,
    parameter FIFO_ADDR_W = 4,
    parameter IDX_W       = 5,
    parameter LOG2_VOICES = 5,
    parameter COUNT_W     = LOG2_VOICES + 1,
    parameter PIANO_ENGINE   = 1,
    parameter POLY_NORMALIZE = 0,
    parameter FX_ENABLE      = 1,
    parameter FX_GAIN_SHIFT  = 1
)(
    input                              clk,
    input                              rst_n,
    input                              sample_tick,
    input [2:0] instrument_id,
    output wire engine_idle,

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
    input                              hammer_enable,
    input      [4:0]                   fx_ctrl,

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
    output wire [127:0]               diagnostic_chain,
    output wire [VOICES*7-1:0] display_voice_notes
);

wire       out_valid;
wire       out_note_on;
wire [6:0] out_note;
wire [7:0] out_velocity;
wire [1:0] out_waveform;

/*
 * The FIFO only hands over an event in a clk cycle in which the
 * voice bank can take it (the note loader is free).  Note On and
 * Note Off stay in order.
 */
wire       core_ready;
assign engine_idle=core_ready && fifo_level==0;
wire [95:0] diagnostic_audio;
reg [15:0] diagnostic_read_on,diagnostic_read_off;
assign diagnostic_chain={diagnostic_read_off,diagnostic_read_on,diagnostic_audio};
always @(posedge clk or negedge rst_n)
if(!rst_n)begin diagnostic_read_on<=0;diagnostic_read_off<=0;end
else if(out_valid && core_ready)begin
 if(out_note_on)diagnostic_read_on<=diagnostic_read_on+1'b1;
 else diagnostic_read_off<=diagnostic_read_off+1'b1;
end

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
    .out_ready    (core_ready),
    .out_note_on  (out_note_on),
    .out_note     (out_note),
    .out_velocity (out_velocity),
    .out_waveform (out_waveform),
    .level        (fifo_level)
);

synth_core #(
    .REMOTE_ENABLE(REMOTE_ENABLE),    .VOICES      (VOICES),
    .SAMPLE_W    (SAMPLE_W),
    .SAMPLE_RATE (SAMPLE_RATE),
    .IDX_W       (IDX_W),
    .LOG2_VOICES (LOG2_VOICES),
    .COUNT_W     (COUNT_W),
    .PIANO_ENGINE   (PIANO_ENGINE),
    .POLY_NORMALIZE (POLY_NORMALIZE),
    .FX_ENABLE      (FX_ENABLE),
    .FX_GAIN_SHIFT  (FX_GAIN_SHIFT)
) u_core (
    .clk                 (clk),
    .rst_n               (rst_n),
    .sample_tick         (sample_tick),
    .instrument_id(instrument_id),
    .note_on             (out_valid && core_ready && out_note_on),
    .note_off            (out_valid && core_ready && !out_note_on),
    .midi_note           (out_note),
    .velocity            (out_velocity),
    .waveform            (out_waveform),
    .morph_enable        (morph_enable),
    .morph               (event_morph),
    .test_enable         (test_enable),
    .hammer_enable       (hammer_enable),
    .fx_ctrl             (fx_ctrl),
    .event_ready         (core_ready),
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
    .lissajous_y         (lissajous_y),
    .diagnostic_audio    (diagnostic_audio),
    .display_voice_notes(display_voice_notes)
);

endmodule
