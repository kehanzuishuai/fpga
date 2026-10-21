/* ============================================================
 * External PCM5102A DAC (second audio output)
 *
 * The transmitter is always there (synth_top, pcm5102_i2s_tx).
 * The line below decides whether its three signals become pins
 * of the FPGA.
 *
 * Off (as delivered): the design has the same eight pins as the
 * build of 2026-10-12.
 *
 * Switch it on only together with the three pin lines in the
 * .cst (src/pcm5102a_pins_pending.cst, docs/PINOUT_AND_WIRING.md).
 * A port without a pin line is put on a pin of the tool's own
 * choice.
 * ============================================================ */

`define EXT_PCM5102


module baseline_board #(

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

    parameter BUILD_STAGE = 3,
    parameter DISPLAY_ENABLE = 0,
    // Reader policy only: 0 conservative mirror guard, 1 TTP16 diagnostic.
    // Note mapping is independent; physical key order remains unconfirmed.
    parameter KEYBOARD_PROFILE = 0,
    parameter KEY_RAW_MAP_ENABLE = 0,
    parameter [63:0] KEY_RAW_INDEX_TABLE = 64'hfedcba9876543210,
    parameter KEY_MAPPING_CONFIRMED = 0,
    // Logical key i -> KEY_BASE_NOTE+i; independent of reader profile/raw order.
    // Set RAW_MAP_ENABLE/INDEX_TABLE only from measured physical key order.
    parameter [6:0] KEY_BASE_NOTE = 7'd60,
    // A custom table may still override this chromatic default explicitly.
    parameter [111:0] KEY_NOTE_TABLE = {
        (KEY_BASE_NOTE+7'd15), (KEY_BASE_NOTE+7'd14),
        (KEY_BASE_NOTE+7'd13), (KEY_BASE_NOTE+7'd12),
        (KEY_BASE_NOTE+7'd11), (KEY_BASE_NOTE+7'd10),
        (KEY_BASE_NOTE+7'd9),  (KEY_BASE_NOTE+7'd8),
        (KEY_BASE_NOTE+7'd7),  (KEY_BASE_NOTE+7'd6),
        (KEY_BASE_NOTE+7'd5),  (KEY_BASE_NOTE+7'd4),
        (KEY_BASE_NOTE+7'd3),  (KEY_BASE_NOTE+7'd2),
        (KEY_BASE_NOTE+7'd1),  KEY_BASE_NOTE
    }

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


`ifdef EXT_PCM5102

    /* ========================================================
     * External PCM5102A DAC, standard I2S, 24 bit
     * ======================================================== */

    output wire pcm5102_bclk,
    output wire pcm5102_lrck,
    output wire pcm5102_data,

`endif


    /* ========================================================
     * On-board headphone amplifier
     * ======================================================== */

    output wire audio_pa_en,
    output wire [2:0] video_d_p,video_d_n,
    output wire video_ck_p,video_ck_n
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


wire [15:0] key_state,key_reader_state,key_accepted_raw;
wire key_reader_frame_valid,key_mapping_error;
wire [31:0] key_rejected_frames;
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
    .ACTIVE_LOW(1),
    // Reject stuck-active idle rather than publish a fabricated all-key frame.
    .STRICT_IDLE(1),
    .MIRROR_GUARD((KEYBOARD_PROFILE==0) ? 1 : 0)

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
        (key_reader_state),

    .frame_valid
        (key_reader_frame_valid),

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


// One accepted snapshot is the sole source for both events and the display.
keyboard_state_mapper #(.KEYS(16),.INDEX_W(4),
 .RAW_MAP_ENABLE(KEY_RAW_MAP_ENABLE),.RAW_INDEX_TABLE(KEY_RAW_INDEX_TABLE),
 .CHECK_NOTE_UNIQUE(1),.NOTE_TABLE(KEY_NOTE_TABLE)) u_keyboard_map(
 .clk(clk_12m288),.rst_n(synth_rst_n),
 .frame_valid(key_reader_frame_valid),.frame_error(key_frame_error),
 .raw_keys(key_reader_state),.key_state(key_state),.accepted_raw(key_accepted_raw),
 .accepted_frame(key_frame_valid),.mapping_error(key_mapping_error),
 .rejected_frames(key_rejected_frames));

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
    .BASE_NOTE(KEY_BASE_NOTE),

    .USE_NOTE_TABLE(1),

    .NOTE_TABLE(KEY_NOTE_TABLE),

    .VELOCITY(8'd100)

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


// Scheduled state belongs to the original bridge. This separate state counts
// only real valid/ready transfers accepted by the FIFO.
wire key_event_accepted=event_valid && event_ready;
reg [15:0] key_fifo_accepted_state;
reg [15:0] key_note_on_count,key_note_off_count;
(* syn_keep=1 *) reg [6:0] key_last_accepted_midi;
(* syn_keep=1 *) reg [15:0] key_frame_count,key_stall_count;
reg key_was_stalled;
always @(posedge clk_12m288 or negedge synth_rst_n)
if(!synth_rst_n)begin
 key_last_accepted_midi<=0;key_frame_count<=0;key_stall_count<=0;key_was_stalled<=0;
end else begin
 if(key_event_accepted)key_last_accepted_midi<=event_note;
 if(key_frame_valid)key_frame_count<=key_frame_count+1'b1;
 key_was_stalled<=event_valid && !event_ready;
 // Number of stall episodes, not a claim that a pending event was dropped.
 if(event_valid && !event_ready && !key_was_stalled)key_stall_count<=key_stall_count+1'b1;
end
always @(posedge clk_12m288 or negedge synth_rst_n)
if(!synth_rst_n)begin key_fifo_accepted_state<=0;key_note_on_count<=0;key_note_off_count<=0;end
else if(key_event_accepted)begin
 key_fifo_accepted_state[event_key_index]<=event_note_on;
 if(event_note_on)key_note_on_count<=key_note_on_count+1'b1;
 else key_note_off_count<=key_note_off_count+1'b1;
end

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
(* syn_keep=1 *) wire [127:0] diagnostic_chain;

wire dbg_note_event;
wire dbg_audio_onset;
wire dbg_clip;

wire        latency_valid;
wire [23:0] latency_samples;
wire [5:0]  mix_gain_shift;

wire visual_sample_strobe;
wire visual_pcm_valid;
wire signed [23:0] visual_pcm;

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


    /* External PCM5102A */

`ifdef EXT_PCM5102

    .pcm5102_bclk
        (pcm5102_bclk),

    .pcm5102_lrck
        (pcm5102_lrck),

    .pcm5102_data
        (pcm5102_data),

`else

    .pcm5102_bclk
        (),

    .pcm5102_lrck
        (),

    .pcm5102_data
        (),

`endif


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
        (lissajous_y),
 .visual_pcm(visual_pcm),.visual_pcm_valid(visual_pcm_valid),
 .diagnostic_chain(diagnostic_chain)
);



// Video lock never participates in audio reset or audio event readiness.
wire pixel_clk,serial_clk,video_locked,serial_reset_clk;
visual_video_clock u_video_clock(clk_50m,rst_n,pixel_clk,serial_clk,video_locked,serial_reset_clk);
wire video_reset_async=rst_n && synth_rst_n && video_locked;
(* async_reg="true" *) reg video_reset_meta,video_rst_n;
always @(posedge pixel_clk or negedge video_reset_async)
if(!video_reset_async)begin video_reset_meta<=0;video_rst_n<=0;end
else begin video_reset_meta<=1;video_rst_n<=video_reset_meta;end
reg [6:0] status_note;reg status_note_valid;integer status_key;
always @* begin
 status_note=0;status_note_valid=0;
 for(status_key=15;status_key>=0;status_key=status_key-1)
 if(key_state[status_key])begin
  status_note=KEY_NOTE_TABLE[status_key*7+:7];status_note_valid=1;
 end
end
wire [57:0] status_audio={key_state,active_voice_count,audio_peak,
 status_note,status_note_valid,4'(BUILD_STAGE)};
wire [9:0] video_blue,video_green,video_red;
wire [31:0] fft_dropped,wave_dropped,spectrum_dropped;
generate if(DISPLAY_ENABLE!=0)begin:G_DISPLAY
audio_visualizer #(.LOGN(11),.SAMPLE_RATE(48000),.STATUS_ENABLE(1),.MAPPING_CONFIRMED(KEY_MAPPING_CONFIRMED)) u_visual(
 .audio_clk(clk_12m288),.audio_rst_n(synth_rst_n),.pcm_valid(visual_pcm_valid),.pcm(visual_pcm),
 .xy_enable(1'b0),.xy_x(24'sd0),.xy_y(24'sd0),
 .pixel_clk(pixel_clk),.pixel_rst_n(video_rst_n),
 .tmds_blue(video_blue),.tmds_green(video_green),.tmds_red(video_red),
 .fft_dropped(fft_dropped),.wave_dropped(wave_dropped),.spectrum_dropped(spectrum_dropped),
 .status_audio(status_audio));
end else begin:G_NO_DISPLAY
 assign video_blue=10'b1101010100;assign video_green=10'b1101010100;assign video_red=10'b1101010100;
 assign fft_dropped=0;assign wave_dropped=0;assign spectrum_dropped=0;
end endgenerate
visual_dvi_io u_video_io(pixel_clk,serial_clk,video_rst_n,video_blue,video_green,video_red,
 video_d_p,video_d_n,video_ck_p,video_ck_n,serial_reset_clk);

endmodule
