`default_nettype none
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
     * Q15 master gain and recovery step.
     *
     * Explicit 16-bit width avoids
     * Verilog implicit 32-bit arithmetic.
     */
    parameter [15:0] MASTER_GAIN_Q15 = 16'd29491, // 0.9, -0.915 dB headroom
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
 * 32767 ≈ 1.0; default master is29491 (0.9)
 */
localparam [15:0] GAIN_ONE =
    MASTER_GAIN_Q15;


/*
 * Total right shift after gain multiplication.
 */
localparam integer TOTAL_SHIFT =
    15 + {26'd0,MASTER_ATTEN_SHIFT};


/* ============================================================
 * Gain state
 *
 * Gain is always positive, therefore these registers
 * do not need to be signed.
 * ============================================================ */

reg [15:0] target_gain;
reg [15:0] current_gain;
// Count can change between sample enables: never apply a stale excessive gain.
wire [15:0] effective_gain = (current_gain < target_gain) ? current_gain : target_gain;
wire [5:0] voice_count_extended = {{(5-LOG2_VOICES){1'b0}},active_voice_count};
`ifndef SYNTHESIS
initial if(LOG2_VOICES<2 || LOG2_VOICES>5 || MASTER_GAIN_Q15>16'd32767)
    $fatal(1,"gain supports4..32 Voices, MASTER_GAIN_Q15<=32767");
`endif


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
 * target_gain = MASTER_GAIN_Q15 / active_voice_count
 *
 * Q15 representation.
 * ============================================================ */

// All divisions have constant parameter operands and fold into a small LUT.
// Floor rounding ensures n * target_gain <= MASTER_GAIN_Q15.
always @(*) begin
    case(voice_count_extended)
        6'd0: target_gain = GAIN_ONE;
        6'd1: target_gain = MASTER_GAIN_Q15 / 16'd1;
        6'd2: target_gain = MASTER_GAIN_Q15 / 16'd2;
        6'd3: target_gain = MASTER_GAIN_Q15 / 16'd3;
        6'd4: target_gain = MASTER_GAIN_Q15 / 16'd4;
        6'd5: target_gain = MASTER_GAIN_Q15 / 16'd5;
        6'd6: target_gain = MASTER_GAIN_Q15 / 16'd6;
        6'd7: target_gain = MASTER_GAIN_Q15 / 16'd7;
        6'd8: target_gain = MASTER_GAIN_Q15 / 16'd8;
        6'd9: target_gain = MASTER_GAIN_Q15 / 16'd9;
        6'd10: target_gain = MASTER_GAIN_Q15 / 16'd10;
        6'd11: target_gain = MASTER_GAIN_Q15 / 16'd11;
        6'd12: target_gain = MASTER_GAIN_Q15 / 16'd12;
        6'd13: target_gain = MASTER_GAIN_Q15 / 16'd13;
        6'd14: target_gain = MASTER_GAIN_Q15 / 16'd14;
        6'd15: target_gain = MASTER_GAIN_Q15 / 16'd15;
        6'd16: target_gain = MASTER_GAIN_Q15 / 16'd16;
        6'd17: target_gain = MASTER_GAIN_Q15 / 16'd17;
        6'd18: target_gain = MASTER_GAIN_Q15 / 16'd18;
        6'd19: target_gain = MASTER_GAIN_Q15 / 16'd19;
        6'd20: target_gain = MASTER_GAIN_Q15 / 16'd20;
        6'd21: target_gain = MASTER_GAIN_Q15 / 16'd21;
        6'd22: target_gain = MASTER_GAIN_Q15 / 16'd22;
        6'd23: target_gain = MASTER_GAIN_Q15 / 16'd23;
        6'd24: target_gain = MASTER_GAIN_Q15 / 16'd24;
        6'd25: target_gain = MASTER_GAIN_Q15 / 16'd25;
        6'd26: target_gain = MASTER_GAIN_Q15 / 16'd26;
        6'd27: target_gain = MASTER_GAIN_Q15 / 16'd27;
        6'd28: target_gain = MASTER_GAIN_Q15 / 16'd28;
        6'd29: target_gain = MASTER_GAIN_Q15 / 16'd29;
        6'd30: target_gain = MASTER_GAIN_Q15 / 16'd30;
        6'd31: target_gain = MASTER_GAIN_Q15 / 16'd31;
        default: target_gain = MASTER_GAIN_Q15 / 16'd32;
    endcase
end


/* ============================================================
 * Smooth gain control
 *
 * Voice count increases:
 *     gain is capped immediately, before the next sample enable.
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
            // Downward safety clamp is immediate; only recovery is smoothed.
            current_gain <= target_gain;
        end

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
            effective_gain
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
     * Count-band estimate only, excludes Q15 headroom/recovery.
     * Debug shift information
     * ======================================================== */

    if (voice_count_extended <= 6'd1) begin

        applied_shift =
            MASTER_ATTEN_SHIFT;

    end

    else if (voice_count_extended <= 6'd2) begin

        applied_shift =
            6'd1
            +
            MASTER_ATTEN_SHIFT;

    end

    else if (voice_count_extended <= 6'd4) begin

        applied_shift =
            6'd2
            +
            MASTER_ATTEN_SHIFT;

    end

    else if (voice_count_extended <= 6'd8) begin

        applied_shift =
            6'd3
            +
            MASTER_ATTEN_SHIFT;

    end

    else if (voice_count_extended <= 6'd16) begin

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


// The discarded bits must be sign extension, never overflow. Also exercise
// this invariant in simulation rather than hiding an unused-width warning.
`ifndef SYNTHESIS
always @(posedge clk or negedge rst_n)begin
  if(!rst_n)begin end
  else if(sample_tick)
    if(shifted_product !== {{(PROD_W-MIX_W){scaled_out[MIX_W-1]}},scaled_out})
        $fatal(1,"gain normalization lost significant bits");
end
`endif
endmodule
`default_nettype wire
