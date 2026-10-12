module ttp229_reader #(
    /*
     * Half SCL period in clk cycles.
     * 12.288 MHz: 123 clocks ~= 10 us -> F_SCL ~= 50 kHz
     * (TTP229-BSF: 1 kHz .. 512 kHz)
     */
    parameter HALF_TICKS = 123,

    /*
     * Idle time between two frames in clk cycles.
     * Must be longer than the TTP229 timeout Tout = 2 ms, so that
     * the chip is back in stand-by and its bit counter is at D0.
     * 36864 clocks ~= 3 ms.
     */
    parameter GAP_TICKS  = 36864,

    /*
     * 1: SDO = 0 means pressed (TP1 open, module default)
     * 0: SDO = 1 means pressed (TP1 option fitted)
     */
    parameter ACTIVE_LOW = 1,

    /*
     * SDO has to stay at its idle level for this many clk cycles
     * before a frame is started.  Keeps the 16 clocks away from the
     * 93 us DV pulse the chip sends when a key changes.
     * 246 clocks ~= 20 us (Tw >= 10 us).
     */
    parameter IDLE_TICKS = 246,

    /*
     * What to do when SDO does not become idle within GAP_TICKS:
     * 0: read the frame anyway, as the old reader always did;
     *    frame_error pulses.  Default: on the board this can never
     *    be worse than the reader that is known to work.
     * 1: drop the frame, frame_error pulses, key_state keeps its
     *    last good value.  A stuck or unplugged SDO then plays
     *    nothing instead of all keys.
     */
    parameter STRICT_IDLE = 0,

    /*
     * 1: a key bit is accepted when two consecutive frames agree.
     *    Costs one frame (~3.3 ms) of latency.
     * 0: every frame is taken as it is.
     */
    parameter CONFIRM = 1,

    /*
     * 1: as long as no frame with different upper and lower byte
     *    has been seen, the upper byte is ignored.  A TTP229 left
     *    in 8 key mode answers 16 clocks with D0..D7 twice; without
     *    this guard key n also plays the note of key n+8.
     * 0: all 16 bits are always used.
     */
    parameter MIRROR_GUARD = 1,

    /*
     * 0: sample SDO at the end of the SCL high phase (old reader,
     *    proven on the board)
     * 1: sample SDO at the end of the SCL low phase
     */
    parameter SAMPLE_LOW = 0
)(
    input  wire        clk,
    input  wire        rst_n,

    output reg         ttp229_scl,
    input  wire        ttp229_sdo,

    /*
     * Complete 16 key snapshot, 1 = pressed.
     * Only changes together with frame_valid.
     */
    output reg [15:0]  key_state,
    output reg         frame_valid,

    /* One clk pulse: frame dropped or read without idle SDO */
    output reg         frame_error,

    /* 1 while the 16 clocks are being sent */
    output wire        reader_busy,

    /* Last frame exactly as it was shifted in (debug) */
    output reg [15:0]  raw_frame,

    /* A frame with upper byte != lower byte was seen: 16 key mode */
    output reg         mode16_seen,

    /* Only mirrored frames so far: chip is probably in 8 key mode */
    output reg         mode8_suspect
);


/* ============================================================
 * States
 * ============================================================ */

localparam STATE_GAP  = 2'd0;
localparam STATE_IDLE = 2'd1;
localparam STATE_LOW  = 2'd2;
localparam STATE_HIGH = 2'd3;

reg [1:0]  state;

reg [31:0] tick_count;
reg [31:0] idle_count;
reg [4:0]  bit_index;

reg [15:0] shift_reg;
reg [15:0] prev_frame;

reg [2:0]  mirror_count;

assign reader_busy =
    (state == STATE_LOW) ||
    (state == STATE_HIGH);


/* ============================================================
 * Synchronize SDO into the FPGA clock domain
 * ============================================================ */

localparam SDO_IDLE = (ACTIVE_LOW != 0) ? 1'b1 : 1'b0;

reg sdo_meta;
reg sdo_sync;

always @(posedge clk or negedge rst_n) begin

    if (!rst_n) begin
        sdo_meta <= SDO_IDLE;
        sdo_sync <= SDO_IDLE;
    end

    else begin
        sdo_meta <= ttp229_sdo;
        sdo_sync <= sdo_meta;
    end

end

wire pressed_bit;

assign pressed_bit =
    (ACTIVE_LOW != 0) ? ~sdo_sync : sdo_sync;


/* ============================================================
 * Frame post-processing (combinational)
 *
 * frame_now     : the 16 bits of the frame that is ending
 * confirmed_now : per key, taken over when two frames agree
 * guarded_now   : upper byte removed while 8 key mode is still
 *                 possible
 *
 * With SAMPLE_LOW = 0 the last bit is still on the wire when the
 * frame ends, so shift_reg is completed with the current bit.
 * With SAMPLE_LOW = 1 all 16 bits are already in shift_reg.
 * ============================================================ */

/*
 * Confirmed state before the mirror guard.  Kept separately so that
 * keys which are held stay known when the guard is lifted.
 */
reg  [15:0] key_state_full;

reg  [15:0] full_frame;

always @(*) begin

    full_frame =
        shift_reg;

    full_frame[bit_index[3:0]] =
        pressed_bit;

end


wire [15:0] frame_now;
wire [15:0] confirmed_now;
wire [15:0] guarded_now;
wire        mirrored_now;
wire        proves16_now;

assign frame_now =
    (SAMPLE_LOW != 0) ? shift_reg : full_frame;

assign confirmed_now =
    (CONFIRM != 0)
    ?
    (
        (frame_now & prev_frame) |
        (key_state_full & (frame_now ^ prev_frame))
    )
    :
    frame_now;

assign mirrored_now =
    (confirmed_now[15:8] == confirmed_now[7:0]) &&
    (confirmed_now[7:0] != 8'h00);

assign proves16_now =
    (confirmed_now[15:8] != confirmed_now[7:0]);

assign guarded_now =
    ((MIRROR_GUARD != 0) && !mode16_seen && !proves16_now)
    ?
    {8'h00, confirmed_now[7:0]}
    :
    confirmed_now;


/* ============================================================
 * Serial reader
 * ============================================================ */

always @(posedge clk or negedge rst_n) begin

    if (!rst_n) begin

        state          <= STATE_GAP;

        tick_count     <= 32'd0;
        idle_count     <= 32'd0;
        bit_index      <= 5'd0;

        shift_reg      <= 16'd0;
        prev_frame     <= 16'd0;
        key_state      <= 16'd0;
        key_state_full <= 16'd0;
        raw_frame      <= 16'd0;

        ttp229_scl     <= 1'b1;

        frame_valid    <= 1'b0;
        frame_error    <= 1'b0;

        mode16_seen    <= 1'b0;
        mode8_suspect  <= 1'b0;
        mirror_count   <= 3'd0;

    end

    else begin

        frame_valid <= 1'b0;
        frame_error <= 1'b0;


        case (state)


            /* =================================================
             * Wait between two frames (> Tout = 2 ms)
             * ================================================= */

            STATE_GAP: begin

                ttp229_scl <= 1'b1;

                if (tick_count >= GAP_TICKS - 1) begin

                    tick_count <= 32'd0;
                    idle_count <= 32'd0;

                    state <= STATE_IDLE;

                end

                else begin

                    tick_count <= tick_count + 1'b1;

                end

            end


            /* =================================================
             * Wait until SDO is idle (no DV pulse in progress)
             * ================================================= */

            STATE_IDLE: begin

                ttp229_scl <= 1'b1;

                if (sdo_sync == SDO_IDLE)
                    idle_count <= idle_count + 1'b1;
                else
                    idle_count <= 32'd0;


                if (
                    (sdo_sync == SDO_IDLE) &&
                    (idle_count >= IDLE_TICKS - 1)
                ) begin

                    tick_count <= 32'd0;
                    bit_index  <= 5'd0;
                    shift_reg  <= 16'd0;

                    ttp229_scl <= 1'b0;

                    state <= STATE_LOW;

                end

                /* SDO stuck at the active level: wiring, polarity */
                else if (tick_count >= GAP_TICKS - 1) begin

                    tick_count  <= 32'd0;
                    frame_error <= 1'b1;

                    if (STRICT_IDLE != 0) begin

                        state <= STATE_GAP;

                    end

                    else begin

                        bit_index  <= 5'd0;
                        shift_reg  <= 16'd0;

                        ttp229_scl <= 1'b0;

                        state <= STATE_LOW;

                    end

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

                    if (SAMPLE_LOW != 0)
                        shift_reg[bit_index[3:0]] <= pressed_bit;

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
             * D0 -> bit 0 ... D15 -> bit 15
             * ================================================= */

            STATE_HIGH: begin

                ttp229_scl <= 1'b1;

                if (tick_count >= HALF_TICKS - 1) begin

                    tick_count <= 32'd0;

                    if (SAMPLE_LOW == 0)
                        shift_reg[bit_index[3:0]] <= pressed_bit;


                    if (bit_index == 5'd15) begin

                        /*
                         * Frame complete: everything below changes
                         * in this one clock, together with
                         * frame_valid.
                         */

                        raw_frame      <= frame_now;
                        prev_frame     <= frame_now;
                        key_state_full <= confirmed_now;
                        key_state      <= guarded_now;

                        frame_valid <= 1'b1;


                        if (proves16_now) begin

                            mode16_seen   <= 1'b1;
                            mode8_suspect <= 1'b0;

                        end

                        else if (mirrored_now && !mode16_seen) begin

                            if (mirror_count == 3'd7)
                                mode8_suspect <= 1'b1;
                            else
                                mirror_count <= mirror_count + 1'b1;

                        end


                        bit_index <= 5'd0;

                        state <= STATE_GAP;

                    end

                    else begin

                        bit_index <= bit_index + 1'b1;

                        ttp229_scl <= 1'b0;

                        state <= STATE_LOW;

                    end

                end

                else begin

                    tick_count <= tick_count + 1'b1;

                end

            end


            default: begin

                state       <= STATE_GAP;
                tick_count  <= 32'd0;
                bit_index   <= 5'd0;
                ttp229_scl  <= 1'b1;

            end


        endcase

    end

end


endmodule
