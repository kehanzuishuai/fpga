module tang_mega_138k_pro_top (

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

    // External PCM5102A on PMOD1/J24; onboard PT8211 remains connected.
    output wire pcm_bclk,
    output wire pcm_lrclk,
    output wire pcm_data,


    /* ========================================================
     * On-board headphone amplifier
     * ======================================================== */

    output wire audio_pa_en,
    // J11 DVI_TX_A: RGB video only; audio remains on both existing DACs.
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

wire [15:0] key_state;
wire        key_frame_valid;


ttp229_reader #(

    /*
     * 12.288 MHz:
     *
     * 123 clocks ~= 10 us
     */
    .HALF_TICKS
        (123),

    /*
     * ~3 ms frame gap
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
        (key_frame_valid)

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
        (event_waveform)

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
wire visual_pcm_valid;
wire signed [23:0] visual_pcm;
wire signed [23:0] visual_voice_x,visual_voice_y;

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
        (6)

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


    /* Board PT8211 */

    .i2s_bclk
        (i2s_bclk),

    .i2s_lrck
        (i2s_lrck),

    .i2s_data
        (i2s_data),

    .pcm_bclk(pcm_bclk),
    .pcm_lrclk(pcm_lrclk),
    .pcm_data(pcm_data),
    .visual_pcm_valid(visual_pcm_valid),
    .visual_pcm(visual_pcm),
    .visual_voice_x(visual_voice_x),.visual_voice_y(visual_voice_y),


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


wire pixel_clk,serial_clk,video_locked;
visual_video_clock u_video_clock(clk_50m,rst_n,pixel_clk,serial_clk,video_locked);
reg [1:0] video_reset_pipe;
wire video_reset_async=rst_n && video_locked && rst_sync[1];
always @(posedge pixel_clk or negedge video_reset_async)
if(!video_reset_async)video_reset_pipe<=0;
else video_reset_pipe<={video_reset_pipe[0],1'b1};
wire [9:0] video_blue,video_green,video_red;
wire [31:0] unused_fft_dropped,unused_wave_dropped,unused_spectrum_dropped;
audio_visualizer u_visualizer(.audio_clk(clk_12m288),.audio_rst_n(rst_sync[1]),
 .pcm_valid(visual_pcm_valid),.pcm(visual_pcm),.pixel_clk(pixel_clk),
 .xy_enable(active_debug[0] && active_debug[1]),.xy_x(visual_voice_x),.xy_y(visual_voice_y),
 .pixel_rst_n(video_reset_pipe[1]),.tmds_blue(video_blue),.tmds_green(video_green),.tmds_red(video_red),
 .fft_dropped(unused_fft_dropped),.wave_dropped(unused_wave_dropped),.spectrum_dropped(unused_spectrum_dropped));
visual_dvi_io u_video_io(pixel_clk,serial_clk,video_reset_pipe[1],video_blue,video_green,video_red,
 video_d_p,video_d_n,video_ck_p,video_ck_n);
endmodule
