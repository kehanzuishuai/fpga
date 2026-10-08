
module performance_mode_controller #(
    parameter ADDR_W     = 5,
    parameter DURATION_W = 24,
    parameter LED_COUNT  = 12,

    parameter [1:0] DEMO_WAVEFORM = 2'd0,
    parameter [9:0] DEMO_MORPH    = 10'd0
)(
    input                       clk,
    input                       rst_n,
    input                       sample_tick,
    input      [1:0]            mode,

    /* ========================================================
     * Live input
     * ======================================================== */
    input                       live_valid,
    input                       live_note_on,
    input      [6:0]            live_note,
    input      [7:0]            live_velocity,
    input      [1:0]            live_waveform,
    input      [9:0]            live_morph,

    output reg                  live_ready,

    /* ========================================================
     * Event output
     * ======================================================== */
    output reg                  event_valid,
    input                       event_ready,

    output reg                  event_note_on,
    output reg [6:0]            event_note,
    output reg [7:0]            event_velocity,
    output reg [1:0]            event_waveform,
    output reg [9:0]            event_morph,

    /* ========================================================
     * Teaching LED guide
     * ======================================================== */
    output     [LED_COUNT-1:0]  guide_leds,
    output                      guide_hit,

    output reg [6:0]            guide_note,
    output reg                  guide_valid,

    /* ========================================================
     * Display information
     * ======================================================== */
    output reg [1:0]            display_mode,
    output reg [ADDR_W-1:0]     display_score_address
);


/* ============================================================
 * Performance modes
 * ============================================================ */

localparam [1:0] MODE_FREE  = 2'd0;
localparam [1:0] MODE_TEACH = 2'd1;
localparam [1:0] MODE_DEMO  = 2'd2;


/* ============================================================
 * Demo state machine
 *
 * DEMO_ON
 *     ↓
 * DEMO_PLAY
 *     ↓
 * DEMO_OFF
 *     ↓
 * next note
 * ============================================================ */

localparam [1:0] DEMO_ON   = 2'd0;
localparam [1:0] DEMO_PLAY = 2'd1;
localparam [1:0] DEMO_OFF  = 2'd2;


/* ============================================================
 * Internal state
 * ============================================================ */

reg [1:0] last_mode;
reg [1:0] demo_state;


/*
 * Current score address
 */
reg [ADDR_W-1:0] score_address;


/*
 * Score ROM outputs
 */
wire [6:0]            score_note;
wire [DURATION_W-1:0] score_duration;
wire [7:0]            score_velocity;

wire                  score_rest;
wire                  score_valid;


/*
 * Current demo note
 */
reg [6:0] active_demo_note;


/*
 * Demo duration counter
 */
reg [DURATION_W-1:0] duration_remaining;


/*
 * Demo state information
 */
reg demo_note_active;
reg cancel_pending;


/*
 * Indicates that a live NOTE ON event was accepted
 */
reg accepted_live_note;


/* ============================================================
 * Score ROM
 * ============================================================ */

score_rom #(
    .ADDR_W     (ADDR_W),
    .DURATION_W (DURATION_W)
) u_score (
    .address        (score_address),
    .note           (score_note),
    .duration_ticks (score_duration),
    .velocity       (score_velocity),
    .rest           (score_rest),
    .valid          (score_valid)
);


/* ============================================================
 * Teaching LED guide
 * ============================================================ */

led_guide #(
    .LED_COUNT(LED_COUNT)
) u_led (
    .enable       (mode == MODE_TEACH),

    .target_valid (
        score_valid && !score_rest
    ),

    .target_note  (score_note),

    .note_played  (accepted_live_note),
    .played_note  (live_note),

    .leds         (guide_leds),
    .hit          (guide_hit)
);


/* ============================================================
 * Combinational output logic
 * ============================================================ */

always @(*) begin

    /* --------------------------------------------------------
     * Display information
     * -------------------------------------------------------- */

    display_mode          = mode;
    display_score_address = score_address;

    guide_note =
        score_note;

    guide_valid =
        (mode == MODE_TEACH) &&
        score_valid &&
        !score_rest;


    /* --------------------------------------------------------
     * Default values
     * -------------------------------------------------------- */

    live_ready = 1'b0;

    event_valid    = 1'b0;
    event_note_on  = 1'b0;
    event_note     = 7'd0;
    event_velocity = 8'd0;

    /*
     * Live mode default timbre parameters
     */
    event_waveform = live_waveform;
    event_morph    = live_morph;


    /* --------------------------------------------------------
     * Mode change boundary
     *
     * 当 mode 刚发生变化时，
     * 这一周期不发送任何新事件。
     * -------------------------------------------------------- */

    if (mode != last_mode) begin

        /*
         * Do nothing for one clock cycle.
         *
         * 避免旧模式的状态在模式切换瞬间
         * 产生错误事件。
         */

    end


    /* --------------------------------------------------------
     * Cancel active demo note
     *
     * 如果 Demo 正在播放时切换模式，
     * 需要先发送 NOTE OFF。
     * -------------------------------------------------------- */

    else if (cancel_pending) begin

        event_valid    = 1'b1;
        event_note_on  = 1'b0;

        event_note     = active_demo_note;
        event_velocity = 8'd0;

        event_waveform = DEMO_WAVEFORM;
        event_morph    = DEMO_MORPH;

    end


    /* --------------------------------------------------------
     * FREE / TEACH mode
     *
     * Live input passes directly to event output.
     * -------------------------------------------------------- */

    else if (
        (mode == MODE_FREE) ||
        (mode == MODE_TEACH)
    ) begin

        live_ready = event_ready;

        event_valid    = live_valid;
        event_note_on  = live_note_on;

        event_note     = live_note;
        event_velocity = live_velocity;

    end


    /* --------------------------------------------------------
     * DEMO mode
     * -------------------------------------------------------- */

    else if (
        (mode == MODE_DEMO) &&
        score_valid
    ) begin

        event_note     = score_note;
        event_velocity = score_velocity;

        event_waveform = DEMO_WAVEFORM;
        event_morph    = DEMO_MORPH;


        /*
         * Start current score note
         */
        if (
            (demo_state == DEMO_ON) &&
            !score_rest
        ) begin

            event_valid   = 1'b1;
            event_note_on = 1'b1;

        end


        /*
         * Stop current demo note
         */
        else if (demo_state == DEMO_OFF) begin

            event_valid   = 1'b1;
            event_note_on = 1'b0;

            event_note =
                active_demo_note;

        end

    end


    /* --------------------------------------------------------
     * Has a live NOTE ON actually been accepted?
     * -------------------------------------------------------- */

    accepted_live_note =
        live_valid &&
        live_ready &&
        live_note_on;

end


/* ============================================================
 * Sequential mode controller
 * ============================================================ */

always @(posedge clk or negedge rst_n) begin

    if (!rst_n) begin

        last_mode <= MODE_FREE;

        score_address <= {ADDR_W{1'b0}};

        demo_state <= DEMO_ON;

        duration_remaining <=
            {DURATION_W{1'b0}};

        active_demo_note <= 7'd0;

        demo_note_active <= 1'b0;
        cancel_pending   <= 1'b0;

    end

    else begin

        /*
         * Remember current mode
         */
        last_mode <= mode;


        /* ====================================================
         * Mode changed
         * ==================================================== */

        if (mode != last_mode) begin

            /*
             * Leaving DEMO while a note is still active:
             * request NOTE OFF.
             */
            if (
                (last_mode == MODE_DEMO) &&
                demo_note_active
            ) begin

                cancel_pending <= 1'b1;

            end


            /*
             * Restart score state
             */
            score_address <=
                {ADDR_W{1'b0}};

            demo_state <=
                DEMO_ON;

            duration_remaining <=
                {DURATION_W{1'b0}};

        end


        /* ====================================================
         * Cancel old demo note
         * ==================================================== */

        else if (cancel_pending) begin

            if (event_ready) begin

                cancel_pending   <= 1'b0;
                demo_note_active <= 1'b0;

            end

        end


        /* ====================================================
         * TEACH MODE
         *
         * Only advance when the correct note is played.
         * ==================================================== */

        else if (mode == MODE_TEACH) begin

            /*
             * End of score:
             * restart from beginning.
             */
            if (!score_valid) begin

                score_address <=
                    {ADDR_W{1'b0}};

            end


            /*
             * Rest entry:
             * teaching mode skips it.
             */
            else if (score_rest) begin

                score_address <=
                    score_address + 1'b1;

            end


            /*
             * Correct note played:
             * move to next score entry.
             */
            else if (
                accepted_live_note &&
                (live_note == score_note)
            ) begin

                score_address <=
                    score_address + 1'b1;

            end

        end


        /* ====================================================
         * DEMO MODE
         * ==================================================== */

        else if (mode == MODE_DEMO) begin


            /*
             * End of score -> restart
             */
            if (!score_valid) begin

                score_address <=
                    {ADDR_W{1'b0}};

                demo_state <=
                    DEMO_ON;

            end


            else begin

                case (demo_state)


                    /* ========================================
                     * DEMO_ON
                     *
                     * Start new note / rest
                     * ======================================== */

                    DEMO_ON: begin


                        /*
                         * Rest event
                         */
                        if (score_rest) begin

                            if (
                                score_duration ==
                                {DURATION_W{1'b0}}
                            ) begin

                                duration_remaining <=
                                    {{(DURATION_W-1){1'b0}},
                                     1'b1};

                            end

                            else begin

                                duration_remaining <=
                                    score_duration;

                            end


                            demo_state <=
                                DEMO_PLAY;

                        end


                        /*
                         * Normal note
                         */
                        else if (event_ready) begin

                            active_demo_note <=
                                score_note;

                            demo_note_active <=
                                1'b1;


                            if (
                                score_duration ==
                                {DURATION_W{1'b0}}
                            ) begin

                                duration_remaining <=
                                    {{(DURATION_W-1){1'b0}},
                                     1'b1};

                            end

                            else begin

                                duration_remaining <=
                                    score_duration;

                            end


                            demo_state <=
                                DEMO_PLAY;

                        end

                    end


                    /* ========================================
                     * DEMO_PLAY
                     *
                     * Wait for duration to expire.
                     * ======================================== */

                    DEMO_PLAY: begin

                        if (sample_tick) begin


                            /*
                             * Duration finished
                             */
                            if (
                                duration_remaining <=
                                {{(DURATION_W-1){1'b0}},
                                 1'b1}
                            ) begin


                                /*
                                 * Rest:
                                 * no NOTE OFF required.
                                 */
                                if (score_rest) begin

                                    score_address <=
                                        score_address + 1'b1;

                                    demo_state <=
                                        DEMO_ON;

                                end


                                /*
                                 * Normal note:
                                 * send NOTE OFF next.
                                 */
                                else begin

                                    demo_state <=
                                        DEMO_OFF;

                                end

                            end


                            /*
                             * Continue playing
                             */
                            else begin

                                duration_remaining <=
                                    duration_remaining - 1'b1;

                            end

                        end

                    end


                    /* ========================================
                     * DEMO_OFF
                     *
                     * NOTE OFF is generated by combinational
                     * logic. Wait until event_ready.
                     * ======================================== */

                    default: begin

                        if (event_ready) begin

                            demo_note_active <=
                                1'b0;

                            score_address <=
                                score_address + 1'b1;

                            demo_state <=
                                DEMO_ON;

                        end

                    end

                endcase

            end

        end


        /* ====================================================
         * FREE MODE
         * ==================================================== */

        else begin

            score_address <=
                {ADDR_W{1'b0}};

            demo_state <=
                DEMO_ON;

            duration_remaining <=
                {DURATION_W{1'b0}};

        end

    end

end


endmodule
