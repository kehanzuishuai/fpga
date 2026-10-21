/* ============================================================
 * pcm5102_i2s_tx
 *
 * Second audio output: standard (Philips) I2S for an external
 * PCM5102A DAC.  The on-board PT8211 keeps its own transmitter
 * (i2s_tx.v, not changed); both send the same final PCM.
 *
 * Format on the three wires
 *
 *   BCK   3.072 MHz = clk / 4          64 BCK per audio frame
 *   LRCK  48 kHz    = clk / 256        low = left, high = right
 *   DATA  two 32 bit slots per frame, MSB first:
 *         24 bit sample, then 8 zero bits
 *
 *   I2S rule: LRCK and DATA change on the falling edge of BCK,
 *   the DAC reads them on the rising edge; the MSB of a channel
 *   is sent one BCK after LRCK has changed.
 *
 *   slot       0    1    2  ..  24   25 .. 31   32   33   34 ..
 *   LRCK       0    0    0       0    0     0    1    1    1
 *   DATA      (r)  L23  L22 ..  L0    0  .. 0    0   R23  R22 ..
 *
 *   (r) = last (zero) bit of the right slot of the frame before.
 *
 * Everything is clocked by clk (12.288 MHz).  BCK is only an
 * output; it is not used as a clock inside the FPGA.  One slot
 * is 4 clk: BCK falls in the first, rises in the third.  LRCK
 * and DATA are therefore stable for 2 clk (163 ns) before and
 * after every rising edge of BCK.
 *
 * Which sample goes into a frame
 *
 *   sample_valid is the synthesizer's sample_tick.  The sample
 *   is taken CAPTURE_DELAY clk after the clk edge that sees
 *   sample_valid high.  With 7 that is the very clk edge on which
 *   i2s_tx.v takes its sample for the PT8211, so both DACs send
 *   the same sample in the same frame.  That edge is also slot 0
 *   of the frame here: the left and the right slot of a frame
 *   both carry the sample taken at the start of that frame.
 *
 *   sample_valid has to come every 256 clk (it does: i2s_tx.v
 *   divides clk by 256).  Should it come at another moment, the
 *   frame is restarted there.  Should it stop, frames go on and
 *   carry zero.
 *
 * Reset: BCK low, LRCK high, DATA low, no BCK until the first
 * sample has been taken.  The first frame is a complete one and
 * begins, like every frame, with a falling edge of LRCK.
 *
 * SAMPLE_W: 16 to 31.
 *
 * sim/tb/tb_pcm5102_i2s.v decodes the three wires with an
 * independent I2S receiver and compares every word.
 * ============================================================ */

module pcm5102_i2s_tx #(
    parameter       SAMPLE_W      = 24,

    /*
     * clk edges between sample_valid and taking the sample.
     * 7 = the moment i2s_tx.v takes it.  0 takes it in the
     * sample_valid cycle itself.
     */
    parameter [4:0] CAPTURE_DELAY = 5'd7
)(
    input  wire                        clk,
    input  wire                        rst_n,

    input  wire                        sample_valid,
    input  wire signed [SAMPLE_W-1:0]  left_sample,
    input  wire signed [SAMPLE_W-1:0]  right_sample,

    output reg                         pcm5102_bclk,
    output reg                         pcm5102_lrck,
    output reg                         pcm5102_data
);


/* 32 bit slot per channel: the sample first, zero bits behind it */

localparam PAD_W = 32 - SAMPLE_W;

wire [31:0] left_word;
wire [31:0] right_word;

assign left_word  = {left_sample,  {PAD_W{1'b0}}};
assign right_word = {right_sample, {PAD_W{1'b0}}};


/* ============================================================
 * When to take the sample
 * ============================================================ */

reg [4:0] delay_cnt;

wire capture;

assign capture =
    (CAPTURE_DELAY == 5'd0) ? sample_valid : (delay_cnt == 5'd1);


always @(posedge clk or negedge rst_n) begin

    if (!rst_n) begin

        delay_cnt <= 5'd0;

    end

    else begin

        if (sample_valid)
            delay_cnt <= CAPTURE_DELAY;

        else if (delay_cnt != 5'd0)
            delay_cnt <= delay_cnt - 5'd1;

    end

end


/* ============================================================
 * Frame position
 *
 * pos[7:2] = slot 0..63 (one BCK each), pos[1:0] = clk cycle
 * inside the slot.  Taking a sample is always slot 0.
 * ============================================================ */

reg        running;

reg  [7:0] frame_cnt;

wire [7:0] pos;
wire [5:0] slot;
wire [1:0] phase;

assign pos   = capture ? 8'd0 : frame_cnt;
assign slot  = pos[7:2];
assign phase = pos[1:0];


/*
 * The 64 bits of the frame, sent MSB first, one bit per slot.
 * Slot 0 still sends the last bit of the frame before (the I2S
 * one bit delay) and loads the new frame.
 */
reg [63:0] shift_reg;


always @(posedge clk or negedge rst_n) begin

    if (!rst_n) begin

        running      <= 1'b0;

        frame_cnt    <= 8'd0;
        shift_reg    <= 64'd0;

        pcm5102_bclk <= 1'b0;
        pcm5102_lrck <= 1'b1;
        pcm5102_data <= 1'b0;

    end

    else if (capture || running) begin

        running   <= 1'b1;

        frame_cnt <= pos + 8'd1;


        /* ----------------------------------------------------
         * Falling edge of BCK: next bit, LRCK
         * ---------------------------------------------------- */

        if (phase == 2'd0) begin

            pcm5102_bclk <= 1'b0;
            pcm5102_data <= shift_reg[63];

            if (slot == 6'd0) begin

                pcm5102_lrck <= 1'b0;

                if (capture)
                    shift_reg <= {left_word, right_word};
                else
                    shift_reg <= 64'd0;

            end

            else begin

                if (slot == 6'd32)
                    pcm5102_lrck <= 1'b1;

                shift_reg <= {shift_reg[62:0], 1'b0};

            end

        end


        /* ----------------------------------------------------
         * Rising edge of BCK: the DAC reads LRCK and DATA here
         * ---------------------------------------------------- */

        else if (phase == 2'd2) begin

            pcm5102_bclk <= 1'b1;

        end

    end

end


endmodule
