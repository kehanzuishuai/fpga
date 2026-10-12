module synth_top #(
    parameter CLK_HZ         = 12288000,
    parameter SAMPLE_RATE    = 48000,

    parameter VOICES         = 32,
    parameter SAMPLE_W       = 24,

    parameter FIFO_DEPTH     = 16,
    parameter FIFO_ADDR_W    = 4,

    parameter IDX_W          = 5,
    parameter LOG2_VOICES    = 5,
    parameter COUNT_W        = 6,

    /* 1: AMY style partial piano, 0: previous wavetable piano */
    parameter PIANO_ENGINE   = 1,

    /* 1: mix gain 1/N of the active voices (previous), 0: constant */
    parameter POLY_NORMALIZE = 0,

    /* 1: soundboard / reverb / EQ / limiter after the mix */
    parameter FX_ENABLE      = 1,

    /* effects output gain: 0 = x1, 1 = x2 */
    parameter FX_GAIN_SHIFT  = 1
)(
    /* ========================================================
     * System clock / reset
     *
     * clk要求：
     * 当前设计默认使用12.288 MHz音频主时钟
     * ======================================================== */
    input                           clk,
    input                           rst_n,


    /* ========================================================
     * Note Event 输入
     *SSS
     * 后面按键 / MIDI / 演奏控制器都可以接到这里
     * ======================================================== */

    input                           event_valid,

    input                           event_note_on,

    input      [6:0]                event_note,

    input      [7:0]                event_velocity,

    input      [1:0]                event_waveform,

    output                          event_ready,


    /* ========================================================
     * Continuous Control
     *
     * morph不进入Note FIFO
     * ======================================================== */

    input                           morph_enable,

    input      [9:0]                morph_control,


    /* ========================================================
     * Internal 32-voice test mode
     * ======================================================== */

    input                           test_enable,

    /* 0: piano hammer noise muted */
    input                           hammer_enable,

    /*
     * Effects after the mix (piano_fx.v):
     *   bit 0    soundboard resonance on
     *   bit 1    reverb on
     *   bit 3:2  EQ preset, 0 natural, 1 warm, 2 bright
     *   bit 4    1 soft limiter, 0 plain clipping
     */
    input      [4:0]                fx_ctrl,


    /* ========================================================
     * PCM5102A I2S
     * ======================================================== */

    output                          i2s_bclk,

    output                          i2s_lrck,

    output                          i2s_data,


    /* ========================================================
     * Telemetry UART
     * ======================================================== */

    output                          uart_tx,

    output                          uart_busy,


    /* ========================================================
     * Debug outputs
     * ======================================================== */

    output     [VOICES-1:0]         active_debug,

    output     [COUNT_W-1:0]        active_voice_count,

    output     [FIFO_ADDR_W:0]      fifo_level,

    output     [SAMPLE_W-1:0]       audio_peak,

    output                          dbg_note_event,

    output                          dbg_audio_onset,

    output                          dbg_clip,

    output                          latency_valid,

    output     [23:0]               latency_samples,

    output     [5:0]                mix_gain_shift,


    /* ========================================================
     * Visualization
     * ======================================================== */

    output                          visual_sample_strobe,

    output signed [SAMPLE_W-1:0]    lissajous_x,

    output signed [SAMPLE_W-1:0]    lissajous_y
);


/* ============================================================
 * Internal Audio Signals
 * ============================================================ */


/*
 * 48kHz sample enable
 *
 * 由I2S模块统一产生。
 *
 * DDS / ADSR / Morph / Mixer
 * 全部使用同一个sample_tick。
 */
wire sample_tick;


/*
 * Synth最终24bit PCM
 */
wire signed [SAMPLE_W-1:0] audio_out;


/*
 * Telemetry输出
 */
wire pcm_strobe;

wire signed [SAMPLE_W-1:0] pcm_sample;


/* ============================================================
 * I2S Transmitter
 *
 * 它不仅负责PCM5102A，
 * 同时负责产生整个音频系统的sample_tick。
 * ============================================================ */

i2s_tx #(
    .CLK_HZ      (CLK_HZ),
    .SAMPLE_RATE (SAMPLE_RATE),
    .SAMPLE_W    (SAMPLE_W),
    .SLOT_W      (32)
) u_i2s_tx (
    .clk          (clk),
    .rst_n        (rst_n),

    /*
     * 当前先做Mono：
     *
     * 左右声道发送同一个audio_out
     */
    .left_sample  (audio_out),

    .right_sample (audio_out),

    .i2s_bclk     (i2s_bclk),

    .i2s_lrck     (i2s_lrck),

    .i2s_data     (i2s_data),

    .sample_tick  (sample_tick)
);


/* ============================================================
 * Main Synthesizer
 * ============================================================ */

synth_event_frontend #(
    .VOICES      (VOICES),

    .SAMPLE_W    (SAMPLE_W),

    .SAMPLE_RATE (SAMPLE_RATE),

    .FIFO_DEPTH  (FIFO_DEPTH),

    .FIFO_ADDR_W (FIFO_ADDR_W),

    .IDX_W       (IDX_W),

    .LOG2_VOICES (LOG2_VOICES),

    .COUNT_W     (COUNT_W),

    .PIANO_ENGINE   (PIANO_ENGINE),

    .POLY_NORMALIZE (POLY_NORMALIZE),

    .FX_ENABLE      (FX_ENABLE),

    .FX_GAIN_SHIFT  (FX_GAIN_SHIFT)
) u_synth (
    .clk                 (clk),

    .rst_n               (rst_n),

    .sample_tick         (sample_tick),


    /* --------------------------------------------------------
     * Note Event
     * -------------------------------------------------------- */

    .event_valid         (event_valid),

    .event_note_on       (event_note_on),

    .event_note          (event_note),

    .event_velocity      (event_velocity),

    .event_waveform      (event_waveform),

    .event_ready         (event_ready),


    /* --------------------------------------------------------
     * Continuous Control
     * -------------------------------------------------------- */

    .morph_enable        (morph_enable),

    .event_morph         (morph_control),


    /* --------------------------------------------------------
     * Test
     * -------------------------------------------------------- */

    .test_enable         (test_enable),

    .hammer_enable       (hammer_enable),

    .fx_ctrl             (fx_ctrl),


    /* --------------------------------------------------------
     * Audio
     * -------------------------------------------------------- */

    .audio_out           (audio_out),


    /* --------------------------------------------------------
     * Debug / Telemetry
     * -------------------------------------------------------- */

    .active_debug        (active_debug),

    .fifo_level          (fifo_level),

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


    /* --------------------------------------------------------
     * Visualization
     * -------------------------------------------------------- */

    .visual_sample_strobe(visual_sample_strobe),

    .lissajous_x         (lissajous_x),

    .lissajous_y         (lissajous_y)
);


/* ============================================================
 * Telemetry UART
 *
 * audio_telemetry产生pcm_strobe，
 * 每次strobe就发一包监控数据。
 * ============================================================ */

telemetry_uart #(
    .CLK_HZ        (CLK_HZ),

    .BAUD          (115200),

    .VOICE_COUNT_W (COUNT_W),

    .SAMPLE_W      (SAMPLE_W)
) u_telemetry_uart (
    .clk                (clk),

    .rst_n              (rst_n),

    .report_strobe      (pcm_strobe),

    .active_voice_count (active_voice_count),

    .audio_peak         (audio_peak),

    .pcm_sample         (pcm_sample),

    .tx                 (uart_tx),

    .busy               (uart_busy)
);


endmodule