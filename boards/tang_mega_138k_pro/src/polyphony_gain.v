module polyphony_gain #(
    parameter SAMPLE_W             = 24,
    parameter LOG2_VOICES          = 5,

    /*
     * Extra master attenuation:
     *
     * 0 = /1
     * 1 = /2
     * 2 = /4
     */
    parameter [5:0] MASTER_ATTEN_SHIFT = 6'd0,

    /*
     * Q15 gain smoothing steps.
     *
     * Explicit 16-bit width avoids
     * Verilog implicit 32-bit arithmetic.
     */
    parameter [15:0] GAIN_DOWN_STEP = 16'd1024,
    parameter [15:0] GAIN_UP_STEP   = 16'd64
)(
    input wire clk,
    input wire rst_n,
    input wire sample_tick,

    /*
     * Mixed signal.
     *
     * For 32 x 24-bit voices:
     *
     * 24 + log2(32) = 29 bits
     */
    input wire signed
        [SAMPLE_W+LOG2_VOICES-1:0] mixed_in,

    /*
     * Active voice count:
     *
     * 0 ... 32
     */
    input wire
        [LOG2_VOICES:0] active_voice_count,

    /*
     * Gain-normalized output.
     */
    output reg signed
        [SAMPLE_W+LOG2_VOICES-1:0] scaled_out,

    /*
     * Debug information only.
     */
    output reg [5:0] applied_shift
);


/* ============================================================
 * Width definitions
 * ============================================================ */

localparam MIX_W =
    SAMPLE_W + LOG2_VOICES;


/*
 * current_gain is internally extended to 17-bit signed
 * before multiplication:
 *
 * {1'b0, current_gain}
 *
 * Therefore product width:
 *
 * MIX_W + 17
 */
localparam PROD_W =
    MIX_W + 17;


/*
 * Q15:
 *
 * 32767 ≈ 1.0
 */
localparam [15:0] GAIN_ONE =
    16'd32767;


/*
 * Total right shift after gain multiplication.
 */
localparam integer TOTAL_SHIFT =
    15 + MASTER_ATTEN_SHIFT;


/* ============================================================
 * Gain state
 *
 * Gain is always positive, therefore these registers
 * do not need to be signed.
 * ============================================================ */

reg [15:0] target_gain;
reg [15:0] current_gain;


/* ============================================================
 * Explicit signed multiplication operands
 * ============================================================ */

reg signed [16:0] gain_operand;

reg signed [PROD_W-1:0]
    gain_product;

reg signed [PROD_W-1:0]
    shifted_product;


/* ============================================================
 * Gain LUT
 *
 * Approximately:
 *
 * target_gain = 32768 / active_voice_count
 *
 * Q15 representation.
 * ============================================================ */

always @(*) begin

    case (active_voice_count)

        6'd0:
            target_gain = 16'd32767;

        6'd1:
            target_gain = 16'd32767;

        6'd2:
            target_gain = 16'd16384;

        6'd3:
            target_gain = 16'd10922;

        6'd4:
            target_gain = 16'd8192;

        6'd5:
            target_gain = 16'd6553;

        6'd6:
            target_gain = 16'd5461;

        6'd7:
            target_gain = 16'd4681;

        6'd8:
            target_gain = 16'd4096;

        6'd9:
            target_gain = 16'd3641;

        6'd10:
            target_gain = 16'd3277;

        6'd11:
            target_gain = 16'd2979;

        6'd12:
            target_gain = 16'd2731;

        6'd13:
            target_gain = 16'd2521;

        6'd14:
            target_gain = 16'd2340;

        6'd15:
            target_gain = 16'd2184;

        6'd16:
            target_gain = 16'd2048;

        6'd17:
            target_gain = 16'd1927;

        6'd18:
            target_gain = 16'd1820;

        6'd19:
            target_gain = 16'd1725;

        6'd20:
            target_gain = 16'd1638;

        6'd21:
            target_gain = 16'd1560;

        6'd22:
            target_gain = 16'd1489;

        6'd23:
            target_gain = 16'd1425;

        6'd24:
            target_gain = 16'd1365;

        6'd25:
            target_gain = 16'd1311;

        6'd26:
            target_gain = 16'd1260;

        6'd27:
            target_gain = 16'd1214;

        6'd28:
            target_gain = 16'd1170;

        6'd29:
            target_gain = 16'd1130;

        6'd30:
            target_gain = 16'd1092;

        6'd31:
            target_gain = 16'd1057;

        /*
         * 32 voices:
         *
         * 32768 / 32 = 1024
         */
        default:
            target_gain = 16'd1024;

    endcase

end


/* ============================================================
 * Smooth gain control
 *
 * Voice count increases:
 *     gain decreases quickly.
 *
 * Voice count decreases:
 *     gain recovers slowly.
 * ============================================================ */

always @(posedge clk or negedge rst_n) begin

    if (!rst_n) begin

        current_gain <=
            GAIN_ONE;

    end

    else if (sample_tick) begin

        /* ----------------------------------------------------
         * Gain must decrease.
         * ---------------------------------------------------- */

        if (current_gain > target_gain) begin

            if (
                (current_gain - target_gain)
                <=
                GAIN_DOWN_STEP
            ) begin

                current_gain <=
                    target_gain;

            end

            else begin

                current_gain <=
                    current_gain
                    -
                    GAIN_DOWN_STEP;

            end

        end


        /* ----------------------------------------------------
         * Gain must increase.
         * ---------------------------------------------------- */

        else if (current_gain < target_gain) begin

            if (
                (target_gain - current_gain)
                <=
                GAIN_UP_STEP
            ) begin

                current_gain <=
                    target_gain;

            end

            else begin

                current_gain <=
                    current_gain
                    +
                    GAIN_UP_STEP;

            end

        end

    end

end


/* ============================================================
 * Gain multiplication
 *
 * mixed_in
 *      ×
 * Q15 gain
 *
 * Then:
 *
 * >>> 15
 *
 * to remove the Q15 fractional bits.
 * ============================================================ */

always @(*) begin

    /*
     * Convert unsigned positive 16-bit gain into a
     * positive signed 17-bit operand.
     *
     * The leading zero is important.
     */
    gain_operand =
        $signed({
            1'b0,
            current_gain
        });


    /*
     * Full-precision signed product.
     */
    gain_product =
        $signed(mixed_in)
        *
        gain_operand;


    /*
     * Q15 normalization +
     * optional master attenuation.
     */
    shifted_product =
        gain_product
        >>>
        TOTAL_SHIFT;


    /*
     * The gain is <= 1.0, therefore a valid mixed_in
     * cannot grow beyond MIX_W after scaling.
     *
     * Explicitly select the desired bits instead of
     * relying on implicit Verilog truncation.
     */
    scaled_out =
        shifted_product[
            MIX_W-1:0
        ];


    /* ========================================================
     * Debug shift information
     * ======================================================== */

    if (active_voice_count <= 6'd1) begin

        applied_shift =
            MASTER_ATTEN_SHIFT;

    end

    else if (active_voice_count <= 6'd2) begin

        applied_shift =
            6'd1
            +
            MASTER_ATTEN_SHIFT;

    end

    else if (active_voice_count <= 6'd4) begin

        applied_shift =
            6'd2
            +
            MASTER_ATTEN_SHIFT;

    end

    else if (active_voice_count <= 6'd8) begin

        applied_shift =
            6'd3
            +
            MASTER_ATTEN_SHIFT;

    end

    else if (active_voice_count <= 6'd16) begin

        applied_shift =
            6'd4
            +
            MASTER_ATTEN_SHIFT;

    end

    else begin

        applied_shift =
            6'd5
            +
            MASTER_ATTEN_SHIFT;

    end

end


endmodule
