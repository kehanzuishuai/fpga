module i2s_tx #(
    parameter CLK_HZ      = 12288000,
    parameter SAMPLE_RATE = 48000,
    parameter SAMPLE_W    = 24,
    parameter SLOT_W      = 16
)(
    input  wire                        clk,
    input  wire                        rst_n,

    input  wire signed [SAMPLE_W-1:0] left_sample,
    input  wire signed [SAMPLE_W-1:0] right_sample,

    output reg                         i2s_bclk,
    output reg                         i2s_lrck,
    output reg                         i2s_data,

    output reg                         sample_tick
);


/* ============================================================
 * PT8211-S:
 *
 * 16-bit signed PCM
 * Japanese / LSB-justified format
 *
 * WS = 1 : Left
 * WS = 0 : Right
 *
 * Data is sampled on BCLK rising edge.
 * ============================================================ */

localparam DAC_W = 16;


/* ============================================================
 * 48 kHz × 2 channels × 16 bits
 *
 * BCLK = 1.536 MHz
 * ============================================================ */

localparam BCLK_HZ =
    SAMPLE_RATE * 2 * DAC_W;


/*
 * 12.288 MHz / (2 × 1.536 MHz)
 *
 * HALF_DIV = 4
 */
localparam HALF_DIV =
    CLK_HZ / (2 * BCLK_HZ);


/* ============================================================
 * Internal registers
 * ============================================================ */

reg [7:0] div_cnt;

/*
 * 0 ... 15
 */
reg [4:0] bit_pos;


/*
 * 1 = Left
 * 0 = Right
 */
reg channel;


reg signed [DAC_W-1:0] left_reg;
reg signed [DAC_W-1:0] right_reg;


/* ============================================================
 * PT8211 transmitter
 * ============================================================ */

always @(posedge clk or negedge rst_n) begin

    if (!rst_n) begin

        div_cnt     <= 8'd0;
        bit_pos     <= 5'd0;

        channel     <= 1'b1;

        left_reg    <= 16'sd0;
        right_reg   <= 16'sd0;

        i2s_bclk    <= 1'b0;
        i2s_lrck    <= 1'b1;
        i2s_data    <= 1'b0;

        sample_tick <= 1'b0;

    end

    else begin

        /*
         * Normally low.
         * Only one clk cycle pulse.
         */
        sample_tick <= 1'b0;


        if (div_cnt == HALF_DIV - 1) begin

            div_cnt <= 8'd0;


            /* =================================================
             * BCLK rising edge
             *
             * PT8211 samples DIN here.
             * ================================================= */

            if (i2s_bclk == 1'b0) begin

                i2s_bclk <= 1'b1;

            end


            /* =================================================
             * BCLK falling edge
             *
             * Prepare next bit.
             * ================================================= */

            else begin

                i2s_bclk <= 1'b0;


                /*
                 * Near the end of the RIGHT channel,
                 * tell synth to calculate next PCM sample.
                 *
                 * This gives several 12.288 MHz clocks
                 * before we capture the new PCM.
                 */
                if ((channel == 1'b0) &&
                    (bit_pos == DAC_W - 2)) begin

                    sample_tick <= 1'b1;

                end


                /* =============================================
                 * Current 16-bit channel finished
                 * ============================================= */

                if (bit_pos == DAC_W - 1) begin

                    bit_pos <= 5'd0;


                    /* =========================================
                     * LEFT -> RIGHT
                     * ========================================= */

                    if (channel == 1'b1) begin

                        channel  <= 1'b0;

                        /*
                         * PT8211:
                         * WS low = Right channel
                         */
                        i2s_lrck <= 1'b0;


                        /*
                         * Prepare Right MSB.
                         */
                        i2s_data <= right_reg[15];

                    end


                    /* =========================================
                     * RIGHT -> new LEFT frame
                     * ========================================= */

                    else begin

                        channel  <= 1'b1;

                        /*
                         * PT8211:
                         * WS high = Left channel
                         */
                        i2s_lrck <= 1'b1;


                        /*
                         * Synth is 24-bit.
                         *
                         * PT8211 accepts 16-bit.
                         *
                         * Keep upper 16 bits:
                         *
                         * [23:8]
                         */
                        left_reg <=
                            left_sample[SAMPLE_W-1:
                                        SAMPLE_W-DAC_W];

                        right_reg <=
                            right_sample[SAMPLE_W-1:
                                         SAMPLE_W-DAC_W];


                        /*
                         * Directly prepare new Left MSB.
                         */
                        i2s_data <=
                            left_sample[SAMPLE_W-1];

                    end

                end


                /* =============================================
                 * Current channel continues
                 * ============================================= */

                else begin

                    bit_pos <= bit_pos + 1'b1;


                    if (channel == 1'b1) begin

                        i2s_data <=
                            left_reg[(DAC_W-2)-bit_pos];

                    end

                    else begin

                        i2s_data <=
                            right_reg[(DAC_W-2)-bit_pos];

                    end

                end

            end

        end

        else begin

            div_cnt <= div_cnt + 1'b1;

        end

    end

end


endmodule
