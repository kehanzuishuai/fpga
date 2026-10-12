module voice #(
    parameter SAMPLE_W = 24,
    parameter PHASE_W  = 32
)(
    input                              clk,
    input                              rst_n,
    input                              sample_tick,

    input                              start,
    input                              stop,

    input      [PHASE_W-1:0]           phase_inc_in,
    input      [6:0]                   note_in,
    input      [7:0]                   velocity_in,

    /*
     * Compatibility only.
     * Piano-only engine ignores waveform selection.
     */
    input      [1:0]                   waveform_in,

    /*
     * Compatibility only.
     */
    input                              morph_enable,
    input      [9:0]                   morph_in,

    output                             active,
    output reg                         releasing,
    output     [SAMPLE_W-1:0]          env_level,

    output reg [6:0]                   note,
    output reg [PHASE_W-1:0]           phase_inc,

    output reg signed [SAMPLE_W-1:0]   sample
);


/* ============================================================
 * Voice state
 * ============================================================ */

reg [7:0]
    velocity_reg;


/* ============================================================
 * Phase
 * ============================================================ */

wire [PHASE_W-1:0]
    phase;


/* ============================================================
 * Piano envelope
 * ============================================================ */

wire [SAMPLE_W-1:0]
    piano_env;

wire [2:0]
    piano_env_stage;


assign env_level =
    piano_env;


/* ============================================================
 * Voice metadata
 * ============================================================ */

always @(posedge clk or negedge rst_n) begin

    if (!rst_n) begin

        note <=
            7'd0;

        phase_inc <=
            {PHASE_W{1'b0}};

        velocity_reg <=
            8'd0;

        releasing <=
            1'b0;

    end

    else begin

        if (start) begin

            note <=
                note_in;

            phase_inc <=
                phase_inc_in;

            velocity_reg <=
                velocity_in;

            releasing <=
                1'b0;

        end

        else if (
            stop &&
            active
        ) begin

            releasing <=
                1'b1;

        end

        else if (!active) begin

            releasing <=
                1'b0;

        end

    end

end


/* ============================================================
 * Main string phase
 * ============================================================ */

dds_phase_accum #(
    .PHASE_W(PHASE_W)
) u_phase_a (

    .clk
        (clk),

    .rst_n
        (rst_n),

    .sample_tick
        (sample_tick),

    .phase_reset
        (start),

    .phase_inc
        (phase_inc),

    .phase
        (phase)

);


/* ============================================================
 * Piano-specific envelope
 * ============================================================ */

piano_envelope #(
    .ENV_W(SAMPLE_W)
) u_piano_env (

    .clk
        (clk),

    .rst_n
        (rst_n),

    .sample_tick
        (sample_tick),

    .gate_on
        (start),

    .gate_off
        (stop),

    .level
        (piano_env),

    .active
        (active),

    .stage
        (piano_env_stage)

);


/* ============================================================
 * Piano physical / spectral model
 * ============================================================ */

wire signed [SAMPLE_W-1:0]
    piano_body;

wire signed [SAMPLE_W-1:0]
    piano_hammer;


piano_string_model #(
    .SAMPLE_W     (SAMPLE_W),
    .PHASE_W      (PHASE_W),
    .DETUNE_SHIFT (11)
) u_piano_model (

    .clk
        (clk),

    .rst_n
        (rst_n),

    .sample_tick
        (sample_tick),

    .start
        (start),

    .active
        (active),

    .phase_a
        (phase),

    .phase_inc
        (phase_inc),

    .velocity
        (velocity_reg),

    .body_sample
        (piano_body),

    .hammer_sample
        (piano_hammer)

);


/* ============================================================
 * Timing pipeline
 *
 * Wavetable is synchronous.
 * ============================================================ */

reg sample_tick_d1;
reg sample_tick_d2;

reg pipe_mul1;
reg pipe_mul2;
reg pipe_out;


always @(posedge clk or negedge rst_n) begin

    if (!rst_n) begin

        sample_tick_d1 <= 1'b0;
        sample_tick_d2 <= 1'b0;

        pipe_mul1 <= 1'b0;
        pipe_mul2 <= 1'b0;
        pipe_out  <= 1'b0;

    end

    else begin

        sample_tick_d1 <=
            sample_tick;

        sample_tick_d2 <=
            sample_tick_d1;

        pipe_mul1 <=
            sample_tick_d2;

        pipe_mul2 <=
            pipe_mul1;

        pipe_out <=
            pipe_mul2;

    end

end


/* ============================================================
 * Stage 0
 *
 * Capture:
 *
 * body
 * hammer
 * envelope
 * velocity
 * ============================================================ */

reg signed [SAMPLE_W-1:0]
    body_stage0;

reg signed [SAMPLE_W-1:0]
    hammer_stage0;

reg signed [SAMPLE_W:0]
    env_stage0;

reg signed [9:0]
    vel_stage0;

reg
    active_stage0;


always @(posedge clk or negedge rst_n) begin

    if (!rst_n) begin

        body_stage0 <=
            {SAMPLE_W{1'b0}};

        hammer_stage0 <=
            {SAMPLE_W{1'b0}};

        env_stage0 <=
            {(SAMPLE_W+1){1'b0}};

        vel_stage0 <=
            10'sd0;

        active_stage0 <=
            1'b0;

    end

    else if (sample_tick_d2) begin

        if (active) begin

            body_stage0 <=
                piano_body;

            hammer_stage0 <=
                piano_hammer;

        end

        else begin

            body_stage0 <=
                {SAMPLE_W{1'b0}};

            hammer_stage0 <=
                {SAMPLE_W{1'b0}};

        end


        env_stage0 <=

            $signed({
                1'b0,
                piano_env
            });


        if (
            velocity_reg >=
            8'd127
        ) begin

            vel_stage0 <=
                10'sd128;

        end

        else begin

            vel_stage0 <=

                $signed({
                    2'b00,
                    velocity_reg
                });

        end


        active_stage0 <=
            active;

    end

end


/* ============================================================
 * Stage 1
 *
 * BODY goes through piano envelope.
 *
 * HAMMER does NOT.
 * ============================================================ */

reg signed [(2*SAMPLE_W):0]
    body_product;


always @(posedge clk or negedge rst_n) begin

    if (!rst_n) begin

        body_product <=
            {(2*SAMPLE_W+1){1'b0}};

    end

    else if (pipe_mul1) begin

        if (active_stage0) begin

            body_product <=

                body_stage0

                *

                env_stage0;

        end

        else begin

            body_product <=
                {(2*SAMPLE_W+1){1'b0}};

        end

    end

end


/* ============================================================
 * Normalize body into 27-bit domain
 * ============================================================ */

wire signed [(2*SAMPLE_W):0]
    body_shifted;


assign body_shifted =
    body_product >>> 22;


wire signed [26:0]
    body_q;


assign body_q =
    body_shifted[26:0];


/* ============================================================
 * Hammer bypasses the body envelope.
 *
 * Full envelope would approximately create:
 *
 * sample * 4
 *
 * after the >>>22 normalization.
 *
 * Therefore hammer is shifted left by 2
 * to enter the same numerical domain.
 * ============================================================ */

wire signed [27:0]
    hammer_q_ext;


assign hammer_q_ext =

    (
        $signed({

            {4{hammer_stage0[SAMPLE_W-1]}},

            hammer_stage0

        })

        <<< 2
    );


wire signed [27:0]
    body_q_ext;


assign body_q_ext =

    $signed({

        body_q[26],

        body_q

    });


/* ============================================================
 * Combine BODY + HAMMER
 * ============================================================ */

wire signed [27:0]
    combined_ext;


assign combined_ext =

    body_q_ext

    +

    hammer_q_ext;


/* ============================================================
 * Saturate back to 27 bits
 *
 * Keeps next multiplier at 27 x 10.
 * ============================================================ */

reg signed [26:0]
    combined_q;


always @(*) begin

    if (
        combined_ext >
        28'sd67108863
    ) begin

        combined_q =
            27'sd67108863;

    end

    else if (
        combined_ext <
        -28'sd67108864
    ) begin

        combined_q =
            -27'sd67108864;

    end

    else begin

        combined_q =
            combined_ext[26:0];

    end

end


/* ============================================================
 * Stage 2
 *
 * Whole piano output x velocity
 * ============================================================ */

reg signed [36:0]
    velocity_product;


always @(posedge clk or negedge rst_n) begin

    if (!rst_n) begin

        velocity_product <=
            37'sd0;

    end

    else if (pipe_mul2) begin

        velocity_product <=

            combined_q

            *

            vel_stage0;

    end

end


/* ============================================================
 * Final scaling
 * ============================================================ */

wire signed [36:0]
    scaled_wide;


assign scaled_wide =
    velocity_product >>> 9;


localparam signed [36:0]
    SAMPLE_MAX_EXT =
        37'sd8388607;


localparam signed [36:0]
    SAMPLE_MIN_EXT =
        -37'sd8388608;


/* ============================================================
 * Final registered PCM
 * ============================================================ */

always @(posedge clk or negedge rst_n) begin

    if (!rst_n) begin

        sample <=
            {SAMPLE_W{1'b0}};

    end

    else if (pipe_out) begin

        if (!active_stage0) begin

            sample <=
                {SAMPLE_W{1'b0}};

        end

        else if (
            scaled_wide >
            SAMPLE_MAX_EXT
        ) begin

            sample <=
                {
                    1'b0,
                    {(SAMPLE_W-1){1'b1}}
                };

        end

        else if (
            scaled_wide <
            SAMPLE_MIN_EXT
        ) begin

            sample <=
                {
                    1'b1,
                    {(SAMPLE_W-1){1'b0}}
                };

        end

        else begin

            sample <=
                scaled_wide[
                    SAMPLE_W-1:0
                ];

        end

    end

end


endmodule