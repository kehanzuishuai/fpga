module ttp229_reader #(
    parameter HALF_TICKS = 123,
    parameter GAP_TICKS  = 36864,

    /*
     * 1:
     * SDO = 0 means pressed
     *
     * 0:
     * SDO = 1 means pressed
     *
     * If actual HW-136 polarity is reversed,
     * only change this parameter.
     */
    parameter ACTIVE_LOW = 1
)(
    input  wire        clk,
    input  wire        rst_n,

    output reg         ttp229_scl,
    input  wire        ttp229_sdo,

    output reg [15:0]  key_state,
    output reg         frame_valid
);


/* ============================================================
 * States
 * ============================================================ */

localparam STATE_GAP  = 2'd0;
localparam STATE_LOW  = 2'd1;
localparam STATE_HIGH = 2'd2;


reg [1:0] state;

reg [31:0] tick_count;
reg [4:0]  bit_index;

reg [15:0] shift_reg;


/* ============================================================
 * Synchronize SDO into FPGA clock domain
 * ============================================================ */

reg sdo_meta;
reg sdo_sync;


always @(posedge clk or negedge rst_n) begin

    if (!rst_n) begin

        sdo_meta <= 1'b1;
        sdo_sync <= 1'b1;

    end

    else begin

        sdo_meta <= ttp229_sdo;
        sdo_sync <= sdo_meta;

    end

end


/* ============================================================
 * Convert physical level to:
 *
 * 1 = pressed
 * 0 = released
 * ============================================================ */

wire pressed_bit;


assign pressed_bit =
    (ACTIVE_LOW != 0)
    ?
    ~sdo_sync
    :
    sdo_sync;


/* ============================================================
 * Serial reader
 * ============================================================ */

always @(posedge clk or negedge rst_n) begin

    if (!rst_n) begin

        state        <= STATE_GAP;

        tick_count   <= 32'd0;
        bit_index    <= 5'd0;

        shift_reg    <= 16'd0;
        key_state    <= 16'd0;

        ttp229_scl   <= 1'b1;

        frame_valid  <= 1'b0;

    end

    else begin

        frame_valid <= 1'b0;


        case (state)


            /* =================================================
             * Wait between complete 16-key scans
             *
             * ~3 ms idle.
             * ================================================= */

            STATE_GAP: begin

                ttp229_scl <= 1'b1;


                if (tick_count >= GAP_TICKS - 1) begin

                    tick_count <= 32'd0;
                    bit_index  <= 5'd0;
                    shift_reg  <= 16'd0;

                    ttp229_scl <= 1'b0;

                    state <= STATE_LOW;

                end

                else begin

                    tick_count <= tick_count + 1'b1;

                end

            end


            /* =================================================
             * SCL LOW
             * ================================================= */

            STATE_LOW: begin

                ttp229_scl <= 1'b0;


                if (tick_count >= HALF_TICKS - 1) begin

                    tick_count <= 32'd0;

                    ttp229_scl <= 1'b1;

                    state <= STATE_HIGH;

                end

                else begin

                    tick_count <= tick_count + 1'b1;

                end

            end


            /* =================================================
             * SCL HIGH
             *
             * Sample one key bit.
             * ================================================= */

            STATE_HIGH: begin

                ttp229_scl <= 1'b1;


                if (tick_count >= HALF_TICKS - 1) begin

                    tick_count <= 32'd0;


                    /*
                     * D0 -> key_state[0]
                     * ...
                     * D15 -> key_state[15]
                     */
                    shift_reg[bit_index]
                        <= pressed_bit;


                    if (bit_index == 5'd15) begin

                        /*
                         * Include the final sampled bit
                         * directly.
                         */
                        key_state <= {
                            pressed_bit,
                            shift_reg[14:0]
                        };


                        frame_valid <= 1'b1;

                        bit_index <= 5'd0;

                        ttp229_scl <= 1'b1;

                        state <= STATE_GAP;

                    end

                    else begin

                        bit_index <=
                            bit_index + 1'b1;

                        ttp229_scl <= 1'b0;

                        state <= STATE_LOW;

                    end

                end

                else begin

                    tick_count <=
                        tick_count + 1'b1;

                end

            end


            default: begin

                state       <= STATE_GAP;

                tick_count  <= 32'd0;
                bit_index   <= 5'd0;

                ttp229_scl  <= 1'b1;

                frame_valid <= 1'b0;

            end


        endcase

    end

end


endmodule
