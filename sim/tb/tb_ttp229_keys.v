`timescale 1ns/1ps

/* ============================================================
 * Self-checking test of ttp229_reader + ttp229_event_bridge
 * + note_event_fifo (the real Note Event path up to the FIFO).
 *
 * The test bench keeps its own list of sounding notes, built only
 * from the events that leave the FIFO, and compares it with the
 * pads that are touched.  It also rejects
 *   - a Note On for a note that is already on  (double trigger)
 *   - a Note Off for a note that is not on
 *
 * Scenario sets, chosen with +define+:
 *   (none)          TTP229 in 16 key multi mode
 *   MODE8           TTP229 left in 8 key mode (module default)
 *   SINGLE          TTP229 in 16 key single-key mode
 *   STUCK           SDO held at the active level (broken wiring),
 *                   reader with STRICT_IDLE = 1: nothing plays
 *   STUCK_READ      the same with STRICT_IDLE = 0 (default): the
 *                   frame is read anyway, like the old reader did
 * ============================================================ */

module tb_ttp229_keys;

reg clk   = 1'b0;
reg rst_n = 1'b0;

always #40.690 clk = ~clk;          /* 12.288 MHz */

`ifdef MODE8
localparam CHIP_KEY16 = 0;
localparam CHIP_MULTI = 0;
`else
`ifdef SINGLE
localparam CHIP_KEY16 = 1;
localparam CHIP_MULTI = 0;
`else
localparam CHIP_KEY16 = 1;
localparam CHIP_MULTI = 1;
`endif
`endif

reg  [15:0] touch = 16'd0;
wire        scl;
wire        sdo_chip;
wire        sdo;

reg         force_sdo_low = 1'b0;

assign sdo = force_sdo_low ? 1'b0 : sdo_chip;

ttp229_bfm #(
    .KEY16 (CHIP_KEY16),
    .MULTI (CHIP_MULTI),
    .DV_EN (1)
) u_chip (
    .touch (touch),
    .scl   (scl),
    .sdo   (sdo_chip)
);


/* ------------------------------------------------------------
 * DUT: reader -> bridge -> Note FIFO
 * ------------------------------------------------------------ */

wire [15:0] key_state;
wire        frame_valid;
wire        frame_error;
wire        reader_busy;
wire [15:0] raw_frame;
wire        mode16_seen;
wire        mode8_suspect;

`ifdef STUCK
localparam READER_STRICT = 1;
`else
localparam READER_STRICT = 0;
`endif

ttp229_reader #(
    .HALF_TICKS  (123),
    .GAP_TICKS   (36864),
    .ACTIVE_LOW  (1),
    .STRICT_IDLE (READER_STRICT)
) u_reader (
    .clk           (clk),
    .rst_n         (rst_n),
    .ttp229_scl    (scl),
    .ttp229_sdo    (sdo),
    .key_state     (key_state),
    .frame_valid   (frame_valid),
    .frame_error   (frame_error),
    .reader_busy   (reader_busy),
    .raw_frame     (raw_frame),
    .mode16_seen   (mode16_seen),
    .mode8_suspect (mode8_suspect)
);

wire       ev_valid;
wire       ev_on;
wire [6:0] ev_note;
wire [7:0] ev_velocity;
wire [1:0] ev_waveform;
wire [3:0] ev_key;
wire       ev_ready;
wire [15:0] reported_state;

ttp229_event_bridge #(
    .BASE_NOTE (7'd60),
    .VELOCITY  (8'd100)
) u_bridge (
    .clk             (clk),
    .rst_n           (rst_n),
    .frame_valid     (frame_valid),
    .key_state       (key_state),
    .velocity_in     (8'd100),
    .event_ready     (ev_ready),
    .event_valid     (ev_valid),
    .event_note_on   (ev_on),
    .event_note      (ev_note),
    .event_velocity  (ev_velocity),
    .event_waveform  (ev_waveform),
    .event_key_index (ev_key),
    .reported_state  (reported_state)
);

reg        consumer_ready = 1'b1;

wire       out_valid;
wire       out_on;
wire [6:0] out_note;
wire [7:0] out_velocity;
wire [1:0] out_waveform;
wire [4:0] fifo_level;

note_event_fifo #(
    .DEPTH  (16),
    .ADDR_W (4)
) u_fifo (
    .clk          (clk),
    .rst_n        (rst_n),
    .in_valid     (ev_valid),
    .in_ready     (ev_ready),
    .in_note_on   (ev_on),
    .in_note      (ev_note),
    .in_velocity  (ev_velocity),
    .in_waveform  (ev_waveform),
    .out_valid    (out_valid),
    .out_ready    (consumer_ready),
    .out_note_on  (out_on),
    .out_note     (out_note),
    .out_velocity (out_velocity),
    .out_waveform (out_waveform),
    .level        (fifo_level)
);


/* ------------------------------------------------------------
 * Scoreboard
 * ------------------------------------------------------------ */

reg [127:0] sounding = 128'd0;

integer on_count    = 0;
integer off_count   = 0;
integer errors      = 0;
integer checks      = 0;
integer err_frames  = 0;
integer max_level   = 0;
integer verbose     = 0;

always @(posedge clk) begin

    if (!rst_n) begin
        sounding = 128'd0;
    end

    else begin

        if (frame_error)
            err_frames = err_frames + 1;

        if (fifo_level > max_level)
            max_level = fifo_level;

        if (out_valid && consumer_ready) begin

            if (verbose)
                $display("    %0.2f ms %s note %0d",
                         $time / 1.0e6,
                         out_on ? "ON " : "OFF", out_note);

            if (out_on) begin
                on_count = on_count + 1;
                if (sounding[out_note]) begin
                    errors = errors + 1;
                    $display("ERROR %0.2f ms: Note On for note %0d that is already on",
                             $time / 1.0e6, out_note);
                end
                if (out_velocity != 8'd100) begin
                    errors = errors + 1;
                    $display("ERROR: velocity %0d", out_velocity);
                end
                sounding[out_note] = 1'b1;
            end

            else begin
                off_count = off_count + 1;
                if (!sounding[out_note]) begin
                    errors = errors + 1;
                    $display("ERROR %0.2f ms: Note Off for note %0d that is not on",
                             $time / 1.0e6, out_note);
                end
                sounding[out_note] = 1'b0;
            end

        end

    end

end


/* Expected sounding notes for a pad pattern: pad n -> note 60+n */
function [127:0] notes_of;
    input [15:0] pads;
    integer n;
    begin
        notes_of = 128'd0;
        for (n = 0; n < 16; n = n + 1)
            if (pads[n])
                notes_of[60 + n] = 1'b1;
    end
endfunction

task settle;
    begin
        #(15_000_000);
    end
endtask

task expect_sounding;
    input [15:0]    pads;
    input [8*40-1:0] what;
    begin
        checks = checks + 1;
        if (sounding !== notes_of(pads)) begin
            errors = errors + 1;
            $display("ERROR %0.2f ms [%0s]: sounding keys %b, expected %b",
                     $time / 1.0e6, what, sounding[75:60], pads);
        end
    end
endtask

task expect_counts;
    input integer    n_on;
    input integer    n_off;
    input [8*40-1:0] what;
    begin
        checks = checks + 1;
        if ((on_count != n_on) || (off_count != n_off)) begin
            errors = errors + 1;
            $display("ERROR [%0s]: %0d Note On / %0d Note Off, expected %0d / %0d",
                     what, on_count, off_count, n_on, n_off);
        end
        on_count  = 0;
        off_count = 0;
    end
endtask

task set_pads;
    input [15:0]     pads;
    input [15:0]     expected;
    input [8*40-1:0] what;
    begin
        touch = pads;
        settle;
        expect_sounding(expected, what);
    end
endtask


integer i;
integer j;
reg [15:0] pat;
reg [15:0] lfsr;

initial begin

    #(1000);
    rst_n = 1'b1;
    #(8_000_000);


`ifdef STUCK_READ

    /* --------------------------------------------------------
     * SDO shorted to the active level, STRICT_IDLE = 0: the
     * reader waits one more gap, then reads the frame anyway and
     * flags it.  All bits read "pressed"; as no 16 key frame has
     * been seen yet, the mirror guard keeps the upper byte out,
     * so keys 1..8 sound.  The old reader played all 16.
     * -------------------------------------------------------- */

    $display("=== SDO stuck at the active level, frames read anyway ===");

    force_sdo_low = 1'b1;
    #(60_000_000);

    expect_sounding(16'h00FF, "stuck SDO reads as keys down");

    checks = checks + 1;
    if (err_frames == 0) begin
        errors = errors + 1;
        $display("ERROR: frame_error never pulsed");
    end

    force_sdo_low = 1'b0;
    #(30_000_000);
    expect_sounding(16'h0000, "released after repair");
    set_pads(16'h0100, 16'h0100, "key 9 after repair");
    set_pads(16'h0000, 16'h0000, "release");

`else
`ifdef STUCK

    /* --------------------------------------------------------
     * SDO shorted to the active level, STRICT_IDLE = 1:
     * no notes, error flag
     * -------------------------------------------------------- */

    $display("=== SDO stuck at the active level ===");

    force_sdo_low = 1'b1;
    #(40_000_000);

    expect_sounding(16'h0000, "stuck SDO plays nothing");
    expect_counts(0, 0, "stuck SDO");

    checks = checks + 1;
    if (err_frames == 0) begin
        errors = errors + 1;
        $display("ERROR: frame_error never pulsed");
    end

    /* Wire repaired: keys work again */
    force_sdo_low = 1'b0;
    #(10_000_000);
    set_pads(16'h0001, 16'h0001, "key 1 after repair");
    set_pads(16'h0000, 16'h0000, "release after repair");
    expect_counts(1, 1, "after repair");

`else
`ifdef MODE8

    /* --------------------------------------------------------
     * Chip left in 8 key mode: every key plays exactly one note,
     * the misconfiguration is reported
     * -------------------------------------------------------- */

    $display("=== TTP229 in 8 key mode (TP2 open) ===");

    for (i = 0; i < 8; i = i + 1) begin
        pat = 16'd1 << i;
        set_pads(pat, pat, "8 key mode: one key, one note");
        set_pads(16'h0000, 16'h0000, "8 key mode: release");
        expect_counts(1, 1, "8 key mode: one On, one Off");
    end

    /* pads 9..16 do not exist for the chip in this mode */
    set_pads(16'h0100, 16'h0000, "8 key mode: pad 9 is dead");
    set_pads(16'h0000, 16'h0000, "release");
    expect_counts(0, 0, "8 key mode: pad 9");

    checks = checks + 1;
    if (!mode8_suspect || mode16_seen) begin
        errors = errors + 1;
        $display("ERROR: 8 key mode not reported (mode8_suspect=%b mode16_seen=%b)",
                 mode8_suspect, mode16_seen);
    end

`else
`ifdef SINGLE

    /* --------------------------------------------------------
     * 16 key single-key mode: single keys work, chords do not.
     * This is what the hardware does with TP3/TP4 left open.
     * -------------------------------------------------------- */

    $display("=== TTP229 in 16 key single-key mode (TP3/TP4 open) ===");

    for (i = 0; i < 16; i = i + 1) begin
        pat = 16'd1 << i;
        set_pads(pat, pat, "single mode: one key");
        set_pads(16'h0000, 16'h0000, "single mode: release");
        expect_counts(1, 1, "single mode: one On, one Off");
    end

    /* A chord: the chip itself reports one key only */
    set_pads(16'h0095, 16'h0001, "single mode: chord gives one note");
    set_pads(16'h0000, 16'h0000, "release");
    expect_counts(1, 1, "single mode: chord");

`else

    /* --------------------------------------------------------
     * 16 key multi mode: the target configuration
     * -------------------------------------------------------- */

    $display("=== TTP229 in 16 key multi-key mode ===");

    /* 16 keys one after the other */
    for (i = 0; i < 16; i = i + 1) begin
        pat = 16'd1 << i;
        set_pads(pat, pat, "one key");
        set_pads(16'h0000, 16'h0000, "release");
        expect_counts(1, 1, "one key: one On, one Off");
    end

    checks = checks + 1;
    if (!mode16_seen || mode8_suspect) begin
        errors = errors + 1;
        $display("ERROR: 16 key mode not recognised");
    end

    /* key 1 / key 9 and key 8 / key 16 must not be confused */
    set_pads(16'h0001, 16'h0001, "key 1 only");
    set_pads(16'h0100, 16'h0100, "key 9 only");
    set_pads(16'h0080, 16'h0080, "key 8 only");
    set_pads(16'h8000, 16'h8000, "key 16 only");
    set_pads(16'h0101, 16'h0101, "keys 1 and 9 together");
    set_pads(16'h8080, 16'h8080, "keys 8 and 16 together");
    set_pads(16'h0000, 16'h0000, "all zero");
    expect_counts(8, 8, "1/9/8/16");

    /* 2, 4, 8, 16 keys at the same time */
    set_pads(16'h0011, 16'h0011, "two keys");
    set_pads(16'h0000, 16'h0000, "release");
    set_pads(16'h0095, 16'h0095, "keys 1,3,5,8");
    expect_counts(6, 2, "chord of four: four Note On");

    /* partial release: only key 3 goes */
    set_pads(16'h0091, 16'h0091, "release key 3 only");
    expect_counts(0, 1, "partial release: one Note Off");
    set_pads(16'h0000, 16'h0000, "release");
    set_pads(16'h5555, 16'h5555, "eight keys");
    set_pads(16'hFFFF, 16'hFFFF, "all sixteen keys");
    set_pads(16'h0000, 16'h0000, "all zero");
    expect_counts(16, 19, "8 and 16 keys");

    /* one scan, sixteen events */
    touch = 16'hFFFF;
    settle;
    expect_sounding(16'hFFFF, "16 Note On from one scan");
    expect_counts(16, 0, "16 Note On from one scan");
    touch = 16'h0000;
    settle;
    expect_counts(0, 16, "16 Note Off from one scan");

    /* fast alternating touches, faster than the settle time */
    for (i = 0; i < 20; i = i + 1) begin
        touch = (i[0]) ? 16'h0204 : 16'h4020;
        #(9_000_000);
    end
    touch = 16'h0000;
    settle;
    expect_sounding(16'h0000, "after fast touches");
    on_count  = 0;
    off_count = 0;

    /* pseudo random patterns, changing every 5 ms */
    lfsr = 16'hACE1;
    for (i = 0; i < 60; i = i + 1) begin
        lfsr  = {lfsr[14:0], lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10]};
        touch = lfsr;
        #(5_000_000);
    end
    settle;
    expect_sounding(lfsr, "after random patterns");
    touch = 16'h0000;
    settle;
    expect_sounding(16'h0000, "release after random patterns");
    on_count  = 0;
    off_count = 0;

    /* FIFO full: nobody takes events for 60 ms while keys move */
    consumer_ready = 1'b0;
    touch = 16'hFFFF;
    #(20_000_000);
    touch = 16'h00FF;
    #(20_000_000);
    touch = 16'hF00F;
    #(20_000_000);
    checks = checks + 1;
    if (fifo_level != 5'd16) begin
        errors = errors + 1;
        $display("ERROR: FIFO did not fill (level %0d)", fifo_level);
    end
    consumer_ready = 1'b1;
    settle;
    expect_sounding(16'hF00F, "state after FIFO back-pressure");
    touch = 16'h0000;
    settle;
    expect_sounding(16'h0000, "no stuck note after back-pressure");
    on_count  = 0;
    off_count = 0;

    /* slow consumer: one event per 2 ms */
    touch = 16'hFFFF;
    for (i = 0; i < 40; i = i + 1) begin
        consumer_ready = 1'b0;
        #(2_000_000);
        @(negedge clk) consumer_ready = 1'b1;
        @(negedge clk) consumer_ready = 1'b0;
    end
    consumer_ready = 1'b1;
    settle;
    expect_sounding(16'hFFFF, "slow consumer: all sixteen on");
    touch = 16'h0000;
    settle;
    expect_sounding(16'h0000, "slow consumer: all off");
    on_count  = 0;
    off_count = 0;

    /* touch during reset: note starts after reset, once */
    rst_n = 1'b0;
    touch = 16'h0003;
    #(10_000_000);
    rst_n = 1'b1;
    settle;
    expect_sounding(16'h0003, "keys held through reset");
    expect_counts(2, 0, "keys held through reset");
    touch = 16'h0000;
    settle;
    expect_counts(0, 2, "release after reset");

    /* SDO glitch during one frame must not make a note */
    touch = 16'h0000;
    settle;
    @(posedge reader_busy);
    force_sdo_low = 1'b1;
    @(negedge reader_busy);
    force_sdo_low = 1'b0;
    settle;
    expect_sounding(16'h0000, "one corrupted frame");
    expect_counts(0, 0, "one corrupted frame");

`endif
`endif
`endif
`endif

    $display("max FIFO level %0d, frame_error pulses %0d", max_level, err_frames);

    if (errors == 0)
        $display("PASS: %0d checks", checks);
    else
        $display("FAIL: %0d errors in %0d checks", errors, checks);

    $finish;

end

endmodule
