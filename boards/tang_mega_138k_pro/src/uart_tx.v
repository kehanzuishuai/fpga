

module uart_tx #(
    parameter CLK_HZ = 12000000,
    parameter BAUD   = 115200
)(
    input        clk,
    input        rst_n,
    input        valid,
    input  [7:0] data,

    output       ready,
    output reg   tx
);


/* ============================================================
 * Classic Verilog clog2
 * ============================================================ */
function integer clog2;
    input integer value;
    integer temp;

    begin
        temp = value - 1;
        clog2 = 0;

        while (temp > 0) begin
            temp = temp >> 1;
            clog2 = clog2 + 1;
        end
    end
endfunction


/* ============================================================
 * Baud-rate divider
 * ============================================================ */

localparam DIV_RAW =
    CLK_HZ / BAUD;

localparam DIV =
    (DIV_RAW < 1) ? 1 : DIV_RAW;

localparam CW =
    (DIV <= 1) ? 1 : clog2(DIV);

localparam [CW-1:0] DIV_LAST =
    DIV - 1;


/* ============================================================
 * Internal registers
 * ============================================================ */

reg [CW-1:0] count;

reg [3:0] bit_idx;

/*
 * UART frame:
 *
 * bit 0     : start bit = 0
 * bit 1~8   : data
 * bit 9     : stop bit = 1
 */
reg [9:0] frame;

reg busy;


/* ============================================================
 * Ready indication
 * ============================================================ */

assign ready = !busy;


/* ============================================================
 * UART transmitter
 * ============================================================ */

always @(posedge clk or negedge rst_n) begin

    if (!rst_n) begin

        count   <= {CW{1'b0}};
        bit_idx <= 4'd0;

        frame   <= 10'h3FF;

        busy    <= 1'b0;

        /*
         * UART idle level = 1
         */
        tx      <= 1'b1;

    end


    /* ========================================================
     * Idle state
     * ======================================================== */

    else if (!busy) begin

        /*
         * UART line stays high while idle
         */
        tx <= 1'b1;


        /*
         * Start transmitting when valid = 1
         */
        if (valid) begin

            /*
             * UART frame:
             *
             * {stop, data[7:0], start}
             *
             * start = 0
             * stop  = 1
             */
            frame <= {
                1'b1,
                data,
                1'b0
            };

            busy <= 1'b1;

            bit_idx <= 4'd0;

            count <= {CW{1'b0}};

            /*
             * Immediately output start bit
             */
            tx <= 1'b0;

        end

    end


    /* ========================================================
     * Busy transmitting
     * ======================================================== */

    else if (count == DIV_LAST) begin

        /*
         * One UART bit period completed
         */
        count <= {CW{1'b0}};


        /*
         * bit_idx == 9:
         *
         * stop bit has completed
         */
        if (bit_idx == 4'd9) begin

            busy <= 1'b0;

            /*
             * Return to UART idle level
             */
            tx <= 1'b1;

        end


        else begin

            /*
             * Move to next bit
             */
            bit_idx <= bit_idx + 1'b1;


            /*
             * Output next UART frame bit
             */
            tx <= frame[bit_idx + 1'b1];

        end

    end


    else begin

        /*
         * Continue timing current UART bit
         */
        count <= count + 1'b1;

    end

end


endmodule
