module synth_top #(
    parameter CLK_HZ         = 12288000,
    parameter SAMPLE_RATE    = 48000,

    parameter VOICES         = 32,
    parameter SAMPLE_W       = 24,

    parameter FIFO_DEPTH     = 16,
    parameter FIFO_ADDR_W    = 4,

    parameter IDX_W          = 5,
    parameter LOG2_VOICES    = 5,
    parameter COUNT_W        = 6
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


    /* ========================================================
     * Onboard PT8211 and external PCM5102A outputs
     * ======================================================== */

    output                          i2s_bclk,

    output                          i2s_lrck,

    output                          i2s_data,

    // External PCM5102A: standard 24-bit I2S in 32-bit stereo slots.
    output                          pcm_bclk,
    output                          pcm_lrclk,
    output                          pcm_data,


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
    // Actual DAC capture boundary, full-rate PCM for non-blocking analysis.
    output                          visual_pcm_valid,
    output signed [SAMPLE_W-1:0]    visual_pcm,
    output signed [SAMPLE_W-1:0]    visual_voice_x,visual_voice_y,

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
wire dac_frame_capture;


/*
 * Synth最终24bit PCM
 */
wire signed [SAMPLE_W-1:0] audio_out;
assign visual_pcm_valid = dac_frame_capture;
assign visual_pcm = audio_out;


/*
 * Telemetry输出
 */
wire pcm_strobe;

wire signed [SAMPLE_W-1:0] pcm_sample;


/* ============================================================
 * I2S Transmitter
 *
 * Existing PT8211 output remains the ONLY source of sample_tick.
 * The external DAC snapshots the same PCM on its capture boundary.
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

    .sample_tick  (sample_tick),
    .frame_capture(dac_frame_capture)
);

pcm5102_i2s_tx #(
    .CLK_HZ(CLK_HZ), .SAMPLE_RATE(SAMPLE_RATE),
    .SAMPLE_W(SAMPLE_W), .SLOT_W(32)
) u_pcm5102_tx (
    .clk(clk), .rst_n(rst_n), .sample_valid(dac_frame_capture),
    .left_sample(audio_out), .right_sample(audio_out),
    .bclk(pcm_bclk), .lrclk(pcm_lrclk), .sdata(pcm_data)
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

    .COUNT_W     (COUNT_W)
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
    ,.visual_voice_x(visual_voice_x),.visual_voice_y(visual_voice_y)
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
