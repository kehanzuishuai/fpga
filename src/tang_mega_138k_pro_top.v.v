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

    parameter BUILD_STAGE = 3,
    parameter DISPLAY_ENABLE = 1,
    // Two physical modules must both be configured for 16-key/multi-key mode.
    // Profile 1 admits all 16 bits even for the first symmetric chord;
    // profile 0 retains the optional legacy 8-key mirror diagnostic.
    // Note mapping is independent; physical key order remains unconfirmed.
    parameter KEYBOARD_PROFILE = 1,
    parameter KEY2_BOARD_PROFILE = 1,
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
    },
    parameter KEY2_RAW_MAP_ENABLE = 0,
    parameter [63:0] KEY2_RAW_INDEX_TABLE = 64'hfedcba9876543210,
    parameter [6:0] KEY2_BASE_NOTE = KEY_BASE_NOTE+7'd16,
    parameter [111:0] KEY2_NOTE_TABLE = {
        (KEY2_BASE_NOTE+7'd15), (KEY2_BASE_NOTE+7'd14),
        (KEY2_BASE_NOTE+7'd13), (KEY2_BASE_NOTE+7'd12),
        (KEY2_BASE_NOTE+7'd11), (KEY2_BASE_NOTE+7'd10),
        (KEY2_BASE_NOTE+7'd9),  (KEY2_BASE_NOTE+7'd8),
        (KEY2_BASE_NOTE+7'd7),  (KEY2_BASE_NOTE+7'd6),
        (KEY2_BASE_NOTE+7'd5),  (KEY2_BASE_NOTE+7'd4),
        (KEY2_BASE_NOTE+7'd3),  (KEY2_BASE_NOTE+7'd2),
        (KEY2_BASE_NOTE+7'd1),  KEY2_BASE_NOTE
    }

)(

    /* ========================================================
     * Board clock / reset
     * ======================================================== */

    input  wire clk_50m,
    input  wire rst_n,
    input wire esp_uart_rx,output wire esp_uart_tx,
    input wire esp_spi_sck,esp_spi_cs_n,esp_spi_mosi,output wire esp_spi_miso,


    /* ========================================================
     * HW-136 / TTP229
     * ======================================================== */

    output wire ttp229_scl,
    input  wire ttp229_sdo,
    output wire ttp229_2_scl,
    input  wire ttp229_2_sdo,


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

// Board-clock distribution uses the existing audio PLL input-bypass output.
wire clk_50m_global;

wire clk_12m288;
wire pll_lock;


audio_PLL u_audio_pll (

    .clkin
        (clk_50m),

    .init_clk
        (clk_50m),

    .clkout0
        (clk_12m288),

    .clkout50(clk_50m_global),

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


// Legacy 16-key aliases belong only to module 1 / the existing display.
// Audio and the event scheduler use the complete 32-bit bundle.
wire [31:0] key_state32,key_accepted_raw32,key_raw_frame32,key_reader_state32;
wire [15:0] key_state=key_state32[15:0];
wire [15:0] key2_state=key_state32[31:16];
wire [15:0] key_raw_frame=key_raw_frame32[15:0];
wire [15:0] key_reader_state=key_reader_state32[15:0];
wire [15:0] key_accepted_raw=key_accepted_raw32[15:0];
wire [1:0] key_bank_frame_valid,key_bank_frame_error,key_bank_busy;
wire [1:0] key_bank_mode16,key_bank_mode8;
reg [1:0] display_banks_seen;
wire [63:0] key_bank_rejected;
wire key_mapping_error;
wire key_frame_valid=|key_bank_frame_valid;
wire key_frame_error=|key_bank_frame_error;
wire key_reader_busy=|key_bank_busy;
wire key_mode16_seen=&key_bank_mode16;
wire key_mode8_suspect=|key_bank_mode8;
wire [31:0] key_rejected_frames=key_bank_rejected[31:0];

ttp229_keyboard_pair #(
 .PROFILE0(KEYBOARD_PROFILE),.PROFILE1(KEY2_BOARD_PROFILE),
 .RAW_MAP0(KEY_RAW_MAP_ENABLE),.RAW_INDEX0(KEY_RAW_INDEX_TABLE),
 .RAW_MAP1(KEY2_RAW_MAP_ENABLE),.RAW_INDEX1(KEY2_RAW_INDEX_TABLE),
 .NOTES({KEY2_NOTE_TABLE,KEY_NOTE_TABLE})
) u_keyboards(
 .clk(clk_12m288),.rst_n(synth_rst_n),
 .scl0(ttp229_scl),.sdo0(ttp229_sdo),
 .scl1(ttp229_2_scl),.sdo1(ttp229_2_sdo),
 .key_state(key_state32),.accepted_raw(key_accepted_raw32),
 .raw_frame(key_raw_frame32),.reader_state(key_reader_state32),
 .accepted_frame(key_bank_frame_valid),.frame_error(key_bank_frame_error),
 .reader_busy(key_bank_busy),.mode16_seen(key_bank_mode16),
 .mode8_suspect(key_bank_mode8),.mapping_error(key_mapping_error),
 .rejected_frames(key_bank_rejected));

/* ============================================================
 * TTP229 -> synth Note Event
 * ============================================================ */

wire       event_valid;
wire       event_note_on;

wire [6:0] event_note;
wire [7:0] event_velocity;
wire [1:0] event_waveform;

wire       event_ready;
wire [4:0] event_key_index,fifo_level;
wire key_event_ready,bridge_reset_n,remote_tick,engine_idle,engine_clear,switching,score_playing;
wire [2:0] actual_instrument;wire [15:0] master_volume;wire [4:0] remote_fx;
wire [223:0] remote_key_map;
wire [15:0] synth_gain;
wire remote_valid,remote_on;wire [6:0] remote_note,mapped_key_note;
wire [7:0] remote_velocity;wire [1:0] remote_waveform;
wire signed [23:0] wav_left,wav_right;
wire display_score_sounding,display_score_rest;
wire [6:0] display_score_note;wire [15:0] display_score_completed;
wire [1:0] performance_mode;wire [31:0] guide_targets;wire [2:0] guide_state;wire [15:0] guide_completed;
remote_control #(.DEFAULT_KEYS({KEY2_NOTE_TABLE,KEY_NOTE_TABLE})) u_remote(
 .clk(clk_12m288),.rst_n(synth_rst_n),.sample_tick(remote_tick),
 .uart_rx(esp_uart_rx),.uart_tx(esp_uart_tx),.keys(key_state32),.keys_valid(&display_banks_seen),
 .key_valid(event_valid),.key_on(event_note_on),.key_index(event_key_index),
 .key_velocity(event_velocity),.key_waveform(event_waveform),.key_ready(key_event_ready),
 .bridge_reset_n(bridge_reset_n),.event_valid(remote_valid),.event_on(remote_on),
 .event_note(remote_note),.event_velocity(remote_velocity),.event_waveform(remote_waveform),
 .event_ready(event_ready),.engine_idle(engine_idle),.fifo_level(fifo_level),
 .instrument(actual_instrument),.switching(switching),.engine_clear(engine_clear),
 .volume(master_volume),.effects(remote_fx),.score_playing(score_playing),.mapped_key_note(mapped_key_note),.key_map(remote_key_map),.synth_gain(synth_gain),
 .display_score_sounding(display_score_sounding),.display_score_rest(display_score_rest),
 .display_score_note(display_score_note),.display_score_completed(display_score_completed),
 .performance_mode(performance_mode),.guide_targets(guide_targets),.guide_state(guide_state),.guide_completed(guide_completed));
// WAV playback removed from the contest build: the topic rules forbid playing
// prerecorded or streamed PCM. The SPI pins stay; no PCM enters the mix.
assign wav_left=24'sd0;assign wav_right=24'sd0;assign esp_spi_miso=1'b0;
// One preserved sampling register keeps the SPI inputs connected (proven CST,
// built with cst_warn_to_error); it drives nothing.
(* syn_preserve=1 *) reg unused_wav_spi;
always @(posedge clk_50m_global)unused_wav_spi<=^{esp_spi_sck,esp_spi_cs_n,esp_spi_mosi};

wire [31:0] key_reported_state32;
wire [15:0] key_reported_state=key_reported_state32[15:0];


ttp229_event_bridge #(
    .KEY_COUNT(32),
    .BASE_NOTE(KEY_BASE_NOTE),

    .USE_NOTE_TABLE(1),

    .NOTE_TABLE({KEY2_NOTE_TABLE,KEY_NOTE_TABLE}),

    .VELOCITY(8'd100)

) u_ttp229_event_bridge (

    .clk
        (clk_12m288),

    .rst_n
        (bridge_reset_n),

    .frame_valid
        (key_frame_valid),

    .key_state
        (key_state32),

    /*
     * The TTP229 has no force sensing: fixed velocity 100.
     * Used only when USE_VELOCITY_IN = 1.
     */
    .velocity_in
        (8'd100),

    .event_ready
        (key_event_ready),

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
        (key_reported_state32)

);


// Scheduled state belongs to the original bridge. This separate state counts
// only real valid/ready transfers accepted by the FIFO.
wire key_event_accepted=event_valid && key_event_ready;
reg [31:0] key_fifo_accepted_state;
reg [15:0] key_note_on_count,key_note_off_count;
(* syn_keep=1 *) reg [6:0] key_last_accepted_midi;
(* syn_keep=1 *) reg [15:0] key_frame_count,key_stall_count;
reg key_was_stalled;
always @(posedge clk_12m288 or negedge synth_rst_n)
if(!synth_rst_n)begin
 key_last_accepted_midi<=0;key_frame_count<=0;key_stall_count<=0;key_was_stalled<=0;
end else begin
 if(key_event_accepted)key_last_accepted_midi<=mapped_key_note;
 if(key_frame_valid)key_frame_count<=key_frame_count+1'b1;
 key_was_stalled<=event_valid && !event_ready;
 // Number of stall episodes, not a claim that a pending event was dropped.
 if(event_valid && !event_ready && !key_was_stalled)key_stall_count<=key_stall_count+1'b1;
end
always @(posedge clk_12m288 or negedge synth_rst_n)
if(!synth_rst_n)begin key_fifo_accepted_state<=0;key_note_on_count<=0;key_note_off_count<=0;end
else if(engine_clear)key_fifo_accepted_state<=0;
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
wire [223:0] display_voice_notes;wire signed [23:0] display_left,display_right;

wire signed [23:0]
    lissajous_x;

wire signed [23:0]
    lissajous_y;


/* ============================================================
 * Complete synthesizer
 * ============================================================ */

synth_top #(
    .REMOTE_ENABLE(1),
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
        (remote_valid),

    .event_note_on
        (remote_on),

    .event_note
        (remote_note),

    .event_velocity
        (remote_velocity),

    .event_waveform
        (remote_waveform),

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
        ((BUILD_STAGE >= 3) ? remote_fx : 5'b0_00_0_0),


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
 .display_voice_notes(display_voice_notes),.display_left(display_left),.display_right(display_right),
 .diagnostic_chain(diagnostic_chain)
    ,.instrument_id(actual_instrument),.engine_clear(engine_clear),.remote_volume(master_volume),.synth_gain(synth_gain),
    .wav_left(wav_left),.wav_right(wav_right),.remote_sample_tick(remote_tick),.engine_idle(engine_idle)

);



// Video lock never participates in audio reset or audio event readiness.
wire pixel_clk,serial_clk,video_locked,serial_reset_clk;
visual_video_clock u_video_clock(clk_50m_global,rst_n,pixel_clk,serial_clk,video_locked,serial_reset_clk);
wire video_reset_async=rst_n && synth_rst_n && video_locked;
(* async_reg="true" *) reg video_reset_meta,video_rst_n;
always @(posedge pixel_clk or negedge video_reset_async)
if(!video_reset_async)begin video_reset_meta<=0;video_rst_n<=0;end
else begin video_reset_meta<=1;video_rst_n<=video_reset_meta;end
wire display_status_ready,display_status_update;
wire [511:0] display_status_data;
always @(posedge clk_12m288 or negedge synth_rst_n)
if(!synth_rst_n)display_banks_seen<=0;
else display_banks_seen<=(display_banks_seen | key_bank_frame_valid) & ~key_bank_frame_error;
display_status_adapter u_display_status(
 .clk(clk_12m288),.rst_n(synth_rst_n),.pcm_valid(visual_pcm_valid),
 .pcm_left(display_left),.pcm_right(display_right),
 .keys_valid(&display_banks_seen),.keys(key_state32),.key_map(remote_key_map),
 .instrument(actual_instrument),.voices(active_debug),.voice_notes(display_voice_notes),
 .score_owned(score_playing),.switching(switching),.score_sounding(display_score_sounding),
 .score_rest(display_score_rest),.score_note(display_score_note),.score_completed(display_score_completed),
 .performance_mode(performance_mode),.guide_targets(guide_targets),.guide_state(guide_state),.guide_completed(guide_completed),
 .status_ready(display_status_ready),.status_update(display_status_update),.status_data(display_status_data));
wire [9:0] video_blue,video_green,video_red;
wire [31:0] fft_dropped,wave_dropped,spectrum_dropped;
generate if(DISPLAY_ENABLE!=0)begin:G_DISPLAY
visual_audio_core #(.LOGN(11),.SAMPLE_RATE(48000)) u_visual(
 .audio_clk(clk_12m288),.audio_rst_n(synth_rst_n),.pcm_valid(visual_pcm_valid),.pcm(visual_pcm),
 .xy_enable(1'b0),.xy_x(24'sd0),.xy_y(24'sd0),
 .pixel_clk(pixel_clk),.pixel_rst_n(video_rst_n),
 .tmds_blue(video_blue),.tmds_green(video_green),.tmds_red(video_red),
 .fft_dropped(fft_dropped),.wave_dropped(wave_dropped),.spectrum_dropped(spectrum_dropped),
 .status_update(display_status_update),.status_data(display_status_data),.status_ready(display_status_ready));
end else begin:G_NO_DISPLAY
 assign video_blue=10'b1101010100;assign video_green=10'b1101010100;assign video_red=10'b1101010100;
 assign fft_dropped=0;assign wave_dropped=0;assign spectrum_dropped=0;assign display_status_ready=0;
end endgenerate
visual_dvi_io u_video_io(pixel_clk,serial_clk,video_rst_n,video_blue,video_green,video_red,
 video_d_p,video_d_n,video_ck_p,video_ck_n,serial_reset_clk);

endmodule
