module tang_mega_138k_pro_top #(

    /* ========================================================
     * Bring-up stage (docs/05_gowin_steps.md).  Change only this
     * number between builds:
     *
     * 1: new key reader, everything else as in the previous
     *    design: previous piano voice, previous mix gain,
     *    no effects
     * 2: new piano engine, constant mix gain, effects off
     * 3: new piano engine + soundboard + reverb + soft limiter
     * ======================================================== */

    parameter BUILD_STAGE = 3

)(

    /* ========================================================
     * Board clock / reset
     * ======================================================== */

    input  wire clk_50m,
    input  wire rst_n,


    /* ========================================================
     * HW-136 / TTP229
     * ======================================================== */

    output wire ttp229_scl,
    input  wire ttp229_sdo,


    /* ========================================================
     * On-board PT8211-S DAC
     * ======================================================== */

    output wire i2s_bclk,
    output wire i2s_lrck,
    output wire i2s_data,


    /* ========================================================
     * On-board headphone amplifier
     * ======================================================== */

    output wire audio_pa_en
);


/* ============================================================
 * Audio PLL
 *
 * P16:
 *      50 MHz
 *
 * Internal:
 *      ~12.288 MHz
 * ============================================================ */

wire clk_12m288;
wire pll_lock;


audio_PLL u_audio_pll (

    .clkin
        (clk_50m),

    .init_clk
        (clk_50m),

    .clkout0
        (clk_12m288),

    .lock
        (pll_lock),

    .reset
        (~rst_n)

);


/* ============================================================
 * PLL lock synchronizer
 * ============================================================ */

reg [1:0] pll_lock_sync;


always @(posedge clk_12m288
         or negedge rst_n) begin

    if (!rst_n) begin

        pll_lock_sync <=
            2'b00;

    end

    else begin

        pll_lock_sync <= {
            pll_lock_sync[0],
            pll_lock
        };

    end

end


/* ============================================================
 * Audio-domain reset
 * ============================================================ */

reg [1:0] rst_sync;


always @(posedge clk_12m288
         or negedge rst_n) begin

    if (!rst_n) begin

        rst_sync <=
            2'b00;

    end

    else if (!pll_lock_sync[1]) begin

        rst_sync <=
            2'b00;

    end

    else begin

        rst_sync <= {
            rst_sync[0],
            1'b1
        };

    end

end


wire synth_rst_n;


assign synth_rst_n =
    rst_sync[1];


/* ============================================================
 * Headphone amplifier enable
 *
 * Keep amplifier disabled while audio logic is in reset.
 * ============================================================ */

assign audio_pa_en =
    synth_rst_n;


/* ============================================================
 * TTP229 reader
 * ============================================================ */

wire [15:0] key_state;
wire        key_frame_valid;

/*
 * Keyboard diagnostics.  Internal only, no FPGA pins.
 *
 * key_frame_error : SDO not idle before a frame (wiring/polarity)
 * key_mode16_seen : upper and lower byte differed at least once
 * key_mode8_suspect : only mirrored frames -> TP2 option missing
 */
wire        key_frame_error;
wire        key_reader_busy;
wire [15:0] key_raw_frame;
wire        key_mode16_seen;
wire        key_mode8_suspect;


ttp229_reader #(

    /*
     * 12.288 MHz:
     *
     * 123 clocks ~= 10 us
     */
    .HALF_TICKS
        (123),

    /*
     * ~3 ms frame gap (TTP229 timeout is 2 ms)
     */
    .GAP_TICKS
        (36864),

    /*
     * If key polarity is reversed on the real board,
     * change this 1 to 0.
     */
    .ACTIVE_LOW
        (1)

) u_ttp229_reader (

    .clk
        (clk_12m288),

    .rst_n
        (synth_rst_n),

    .ttp229_scl
        (ttp229_scl),

    .ttp229_sdo
        (ttp229_sdo),

    .key_state
        (key_state),

    .frame_valid
        (key_frame_valid),

    .frame_error
        (key_frame_error),

    .reader_busy
        (key_reader_busy),

    .raw_frame
        (key_raw_frame),

    .mode16_seen
        (key_mode16_seen),

    .mode8_suspect
        (key_mode8_suspect)

);


/* ============================================================
 * TTP229 -> synth Note Event
 * ============================================================ */

wire       event_valid;
wire       event_note_on;

wire [6:0] event_note;
wire [7:0] event_velocity;
wire [1:0] event_waveform;

wire       event_ready;

wire [3:0]  event_key_index;
wire [15:0] key_reported_state;


ttp229_event_bridge #(
    .BASE_NOTE (7'd60),
    .VELOCITY  (8'd100)
) u_ttp229_event_bridge (

    .clk
        (clk_12m288),

    .rst_n
        (synth_rst_n),

    .frame_valid
        (key_frame_valid),

    .key_state
        (key_state),

    /*
     * The TTP229 has no force sensing: fixed velocity 100.
     * Used only when USE_VELOCITY_IN = 1.
     */
    .velocity_in
        (8'd100),

    .event_ready
        (event_ready),

    .event_valid
        (event_valid),

    .event_note_on
        (event_note_on),

    .event_note
        (event_note),

    .event_velocity
        (event_velocity),

    .event_waveform
        (event_waveform),

    .event_key_index
        (event_key_index),

    .reported_state
        (key_reported_state)

);


/* ============================================================
 * Continuous controls
 *
 * Temporarily disabled.
 * They can be connected to real expression sensors later.
 * ============================================================ */

wire       morph_enable;
wire [9:0] morph_control;

wire       test_enable;


assign morph_enable =
    1'b0;

assign morph_control =
    10'd0;

assign test_enable =
    1'b0;


/* ============================================================
 * Internal debug signals
 *
 * Not FPGA external pins.
 * ============================================================ */

wire uart_tx;
wire uart_busy;

wire [31:0] active_debug;
wire [5:0]  active_voice_count;
wire [4:0]  fifo_level;
wire [23:0] audio_peak;

wire dbg_note_event;
wire dbg_audio_onset;
wire dbg_clip;

wire        latency_valid;
wire [23:0] latency_samples;
wire [5:0]  mix_gain_shift;

wire visual_sample_strobe;

wire signed [23:0]
    lissajous_x;

wire signed [23:0]
    lissajous_y;


/* ============================================================
 * Complete synthesizer
 * ============================================================ */

synth_top #(

    .CLK_HZ
        (12288000),

    .SAMPLE_RATE
        (48000),

    .VOICES
        (32),

    .SAMPLE_W
        (24),

    .FIFO_DEPTH
        (16),

    .FIFO_ADDR_W
        (4),

    .IDX_W
        (5),

    .LOG2_VOICES
        (5),

    .COUNT_W
        (6),

    /* 1: new partial piano, 0: previous wavetable piano */
    .PIANO_ENGINE
        ((BUILD_STAGE >= 2) ? 1 : 0),

    /* 1: mix gain 1/N of the active voices (previous) */
    .POLY_NORMALIZE
        ((BUILD_STAGE == 1) ? 1 : 0),

    /* 1: piano_fx after the mix, 0: previous saturator only */
    .FX_ENABLE
        ((BUILD_STAGE >= 2) ? 1 : 0)

) u_synth_top (

    .clk
        (clk_12m288),

    .rst_n
        (synth_rst_n),


    /* Note Event */

    .event_valid
        (event_valid),

    .event_note_on
        (event_note_on),

    .event_note
        (event_note),

    .event_velocity
        (event_velocity),

    .event_waveform
        (event_waveform),

    .event_ready
        (event_ready),


    /* Continuous control */

    .morph_enable
        (morph_enable),

    .morph_control
        (morph_control),


    /* Test */

    .test_enable
        (test_enable),

    /* Piano hammer noise: 1 = on.  Set to 1'b0 for an A/B check. */
    .hammer_enable
        (1'b1),

    /*
     * Effects, fixed here until the board has controls for them:
     *   bit 0    soundboard resonance   1 = on
     *   bit 1    reverb                 1 = on
     *   bit 3:2  EQ   0 natural, 1 warm, 2 bright
     *   bit 4    1 soft limiter, 0 plain clipping
     * 5'b0_00_0_0 switches every effect off (A/B check).
     * Stage 2 uses that: output = mix x2, plain clipping.
     */
    .fx_ctrl
        ((BUILD_STAGE >= 3) ? 5'b1_00_1_1 : 5'b0_00_0_0),


    /* Board PT8211 */

    .i2s_bclk
        (i2s_bclk),

    .i2s_lrck
        (i2s_lrck),

    .i2s_data
        (i2s_data),


    /* UART */

    .uart_tx
        (uart_tx),

    .uart_busy
        (uart_busy),


    /* Debug */

    .active_debug
        (active_debug),

    .active_voice_count
        (active_voice_count),

    .fifo_level
        (fifo_level),

    .audio_peak
        (audio_peak),

    .dbg_note_event
        (dbg_note_event),

    .dbg_audio_onset
        (dbg_audio_onset),

    .dbg_clip
        (dbg_clip),

    .latency_valid
        (latency_valid),

    .latency_samples
        (latency_samples),

    .mix_gain_shift
        (mix_gain_shift),


    /* Visualization */

    .visual_sample_strobe
        (visual_sample_strobe),

    .lissajous_x
        (lissajous_x),

    .lissajous_y
        (lissajous_y)

);


endmodule