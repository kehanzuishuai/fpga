   module voice #(
    parameter SAMPLE_W = 24,
    parameter PHASE_W  = 32
)(
    input                          clk,
    input                          rst_n,
    input                          sample_tick,
    input                          start,
    input                          stop,

    input      [PHASE_W-1:0]       phase_inc_in,
    input      [6:0]               note_in,
    input      [7:0]               velocity_in,
    input      [1:0]               waveform_in,

    /* Continuous-control plane */
    input                          morph_enable,
    input      [9:0]               morph_in,

    output                         active,
    output reg                     releasing,
    output     [SAMPLE_W-1:0]      env_level,

    output reg [6:0]               note,
    output reg [PHASE_W-1:0]       phase_inc,
    output reg signed [SAMPLE_W-1:0] sample
);

/*
 * Keep 3 guard bits between the envelope multiplication
 * and the velocity multiplication.
 *
 * For SAMPLE_W = 24:
 *
 * raw × envelope:
 *     24 × 25 -> 49 bits
 *
 * After normalization:
 *     27 bits
 *
 * Velocity operand:
 *     10 bits signed
 *
 * Second multiply:
 *     27 × 10 -> fits a 27×18-class multiplier.
 */
localparam GUARD_BITS  = 3;

localparam P1_W        = (2 * SAMPLE_W) + 1;
localparam P1_NORM_W   = SAMPLE_W + GUARD_BITS;
localparam VEL_MUL_W   = 10;
localparam P2_W        = P1_NORM_W + VEL_MUL_W;

localparam FIRST_SHIFT =
    SAMPLE_W - GUARD_BITS;

localparam SECOND_SHIFT =
    7 + GUARD_BITS;

reg [7:0] velocity_reg;
reg [1:0] waveform_reg;

wire [PHASE_W-1:0] phase;
wire [SAMPLE_W-1:0] env;
wire [1:0] unused_stage;

wire signed [SAMPLE_W-1:0] sine;
wire signed [SAMPLE_W-1:0] square;
wire signed [SAMPLE_W-1:0] saw;
wire signed [SAMPLE_W-1:0] triangle;
wire signed [SAMPLE_W-1:0] morph_raw;
wire signed [SAMPLE_W-1:0] piano_raw;
wire signed [SAMPLE_W-1:0] raw;

reg [9:0] fixed_morph;
wire [9:0] effective_morph;

assign env_level = env;

function signed [SAMPLE_W-1:0] scale_audio;

    input signed [SAMPLE_W-1:0] audio_in;
    input        [SAMPLE_W-1:0] env_in;
    input        [7:0]          vel_in;


    /*
     * Velocity:
     *
     * MIDI 127 is promoted to 128 so that:
     *
     * 128 / 128 = 1.0
     */
    reg [8:0] vel_q;

    /*
     * Envelope is unsigned,
     * but multiplier is signed.
     *
     * Leading zero guarantees positive value.
     */
    reg signed [SAMPLE_W:0]
        env_signed;

    /*
     * 10-bit signed representation is required because
     * +128 does not fit in signed 8-bit.
     */
    reg signed [9:0]
        vel_signed;


    /* ========================================================
     * Stage 1:
     *
     * raw × envelope
     *
     * For 24-bit audio:
     *
     * 24 × 25 -> 49 bits
     * ======================================================== */

    reg signed [P1_W-1:0]
        p1;

    reg signed [P1_W-1:0]
        p1_shifted;


    /*
     * Normalized Stage-1 result.
     *
     * SAMPLE_W = 24
     * GUARD_BITS = 3
     *
     * therefore:
     *
     * P1_NORM_W = 27 bits
     */
    reg signed [P1_NORM_W-1:0]
        p1_norm;


    /* ========================================================
     * Stage 2:
     *
     * normalized audio × velocity
     *
     * 27 × 10 = 37 bits
     * ======================================================== */

    reg signed [P2_W-1:0]
        p2;

    reg signed [P2_W-1:0]
        p2_shifted;


    /* ========================================================
     * Saturation limits
     * ======================================================== */

    reg signed [P2_W-1:0]
        max_ext;

    reg signed [P2_W-1:0]
        min_ext;


    begin

        /* ====================================================
         * Velocity conversion
         * ==================================================== */

        if (vel_in >= 8'd127)

            vel_q =
                9'd128;

        else

            vel_q =
                {1'b0, vel_in};


        env_signed =
            $signed({
                1'b0,
                env_in
            });


        vel_signed =
            $signed({
                1'b0,
                vel_q
            });


        /* ====================================================
         * Stage 1
         *
         * audio × envelope
         *
         * This is a genuine wide variable multiplication,
         * so using DSP here is appropriate.
         * ==================================================== */

        p1 =
            audio_in
            *
            env_signed;


        /*
         * Original equation eventually divides the envelope
         * multiplication by 2^SAMPLE_W.
         *
         * Instead of carrying the full 49-bit result into
         * the next multiplier, normalize it now.
         *
         * Keep GUARD_BITS fractional bits for precision.
         *
         * SAMPLE_W = 24
         * GUARD_BITS = 3
         *
         * shift = 21
         */
        p1_shifted =
            p1 >>> FIRST_SHIFT;


        /*
         * After the shift, the numerical result is guaranteed
         * to fit into SAMPLE_W + GUARD_BITS bits.
         *
         * Explicit slice prevents implicit-width warnings.
         */
        p1_norm =
            p1_shifted[P1_NORM_W-1:0];


        /* ====================================================
         * Stage 2
         *
         * 27-bit normalized audio
         *
         * ×
         *
         * 10-bit velocity
         *
         * Instead of:
         *
         * ~49 × 10
         *
         * This should fit a 27×18-class multiplier.
         * ==================================================== */

        p2 =
            p1_norm
            *
            vel_signed;


        /*
         * We already shifted:
         *
         * SAMPLE_W - GUARD_BITS
         *
         * Therefore remaining shift is:
         *
         * 7 + GUARD_BITS
         *
         * Total:
         *
         * (SAMPLE_W - GUARD_BITS)
         * +
         * (7 + GUARD_BITS)
         *
         * = SAMPLE_W + 7
         *
         * Exactly the same total scale factor as before.
         */
        p2_shifted =
            p2 >>> SECOND_SHIFT;


        /* ====================================================
         * Output saturation
         * ==================================================== */

        max_ext =
            {
                {(P2_W-SAMPLE_W){1'b0}},
                1'b0,
                {(SAMPLE_W-1){1'b1}}
            };


        min_ext =
            {
                {(P2_W-SAMPLE_W){1'b1}},
                1'b1,
                {(SAMPLE_W-1){1'b0}}
            };


        if (p2_shifted > max_ext)

            scale_audio =
                {
                    1'b0,
                    {(SAMPLE_W-1){1'b1}}
                };


        else if (p2_shifted < min_ext)

            scale_audio =
                {
                    1'b1,
                    {(SAMPLE_W-1){1'b0}}
                };


        else

            scale_audio =
                p2_shifted[SAMPLE_W-1:0];

    end

endfunction

always @(posedge clk or negedge rst_n) begin

    if (!rst_n) begin

        note         <= 7'd0;
        phase_inc    <= {PHASE_W{1'b0}};
        velocity_reg <= 8'd0;
        waveform_reg <= 2'd0;

        releasing    <= 1'b0;

    end

    else begin

        /*
         * 新音开始：
         * 当前 Voice 不再属于 Release 状态
         */
        if (start) begin

            note         <= note_in;
            phase_inc    <= phase_inc_in;
            velocity_reg <= velocity_in;
            waveform_reg <= waveform_in;

            releasing    <= 1'b0;

        end


        /*
         * Note Off：
         * Voice进入Release阶段
         */
        else if (stop && active) begin

            releasing <= 1'b1;

        end


        /*
         * ADSR Release彻底结束
         */
        else if (!active) begin

            releasing <= 1'b0;

        end

    end

end

always @(*) begin
    case (waveform_reg)
        2'd0: fixed_morph = 10'd0;
        2'd1: fixed_morph = 10'd341;
        2'd2: fixed_morph = 10'd682;
        default: fixed_morph = 10'd1023;
    endcase
end

assign effective_morph = morph_enable ? morph_in : fixed_morph;

dds_phase_accum #(
    .PHASE_W(PHASE_W)
) u_phase (
    .clk         (clk),
    .rst_n       (rst_n),
    .sample_tick (sample_tick),
    .phase_reset (start),
    .phase_inc   (phase_inc),
    .phase       (phase)
);

piano_wavetable u_piano_wavetable (
    .addr   (phase[PHASE_W-1 -: 8]),
    .sample (piano_raw)
);

adsr_env #(
    .ENV_W(SAMPLE_W)
) u_env (
    .clk         (clk),
    .rst_n       (rst_n),
    .sample_tick (sample_tick),
    .gate_on     (start),
    .gate_off    (stop),
    .level       (env),
    .active      (active),
    .stage       (unused_stage)
);

waveform_set #(
    .SAMPLE_W(SAMPLE_W)
) u_waveforms (
    .phase    (phase),
    .sine     (sine),
    .square   (square),
    .saw      (saw),
    .triangle (triangle)
);

timbre_morph #(
    .SAMPLE_W(SAMPLE_W)
) u_morph (
    .sine     (sine),
    .square   (square),
    .saw      (saw),
    .triangle (triangle),
    .morph    (effective_morph),
    .sample   (morph_raw)
);

assign raw =
    (!morph_enable && waveform_reg == 2'd3)
    ? piano_raw
    : morph_raw;

always @(*) begin
    if (active)
        sample = scale_audio(raw, env, velocity_reg);
    else
        sample = {SAMPLE_W{1'b0}};
end

endmodule
