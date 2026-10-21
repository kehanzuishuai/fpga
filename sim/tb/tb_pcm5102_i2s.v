`timescale 1ns/1ps

/* ============================================================
 * pcm5102_i2s_tx alone.
 *
 * The three wires are decoded by sim/models/i2s_rx_model.v (a
 * receiver written from the I2S rule) and every 24 bit word is
 * compared with the sample the transmitter had to take.
 *
 * Two transmitters run side by side: CAPTURE_DELAY = 7 (the
 * value used in the design) and CAPTURE_DELAY = 0.
 *
 * Phases
 *   A  reset state, nothing on the wires before the first sample
 *   B  chosen values: zero, +1/-1, largest, smallest, bit patterns,
 *      one bit at a time; left and right differ, so a swapped
 *      channel or a wrong LRCK polarity shows
 *   C  values that change every frame; the input changes at
 *      different moments after sample_valid (0 .. 248 clk)
 *   D  reset in the middle of a frame, first frame after it
 *   E  sample_valid stops for some frames, then returns
 *   F  +frames=N frames of pseudo random data (default 48000 = 1 s)
 *
 * Wire timing is measured over the whole run.
 * ============================================================ */


/* ------------------------------------------------------------
 * One transmitter output: receiver + expected values + compare
 * ------------------------------------------------------------ */

module pcm5102_frame_check #(
    parameter integer DELAY = 7
)(
    input wire               clk,
    input wire               rst_n,
    input wire               sample_valid,
    input wire signed [23:0] left_in,
    input wire signed [23:0] right_in,
    input wire               bclk,
    input wire               lrck,
    input wire               data
);

i2s_rx_model u_rx (
    .bclk (bclk),
    .lrck (lrck),
    .data (data)
);


/*
 * What has to be on the wires: the inputs as they are DELAY clk
 * edges after the edge that sees sample_valid.  A frame without
 * a new sample carries zero.
 */

reg  [23:0] exp_l [0:131071];
reg  [23:0] exp_r [0:131071];

integer exp_wr = 0;
integer exp_rd = 0;

integer edge_cnt   = 0;
integer take_at    = -1;
integer frame_pos  = 0;
reg     run        = 1'b0;
reg     take;

always @(posedge clk) begin

    if (!rst_n) begin
        take_at   = -1;
        run       = 1'b0;
        frame_pos = 0;
        exp_rd    = exp_wr;
    end

    else begin

        edge_cnt = edge_cnt + 1;

        if (sample_valid)
            take_at = edge_cnt + DELAY;

        take = (edge_cnt == take_at);

        if (take) begin
            exp_l[exp_wr] = left_in;
            exp_r[exp_wr] = right_in;
            exp_wr        = exp_wr + 1;
            run           = 1'b1;
            frame_pos     = 1;
        end

        else if (run) begin

            if (frame_pos == 0) begin
                exp_l[exp_wr] = 24'd0;
                exp_r[exp_wr] = 24'd0;
                exp_wr        = exp_wr + 1;
            end

            frame_pos = (frame_pos + 1) % 256;

        end

    end

end


/* ------------------------------------------------------------
 * Every decoded frame against the expected one
 * ------------------------------------------------------------ */

integer frames_ok   = 0;
integer errors      = 0;
integer pad_errors  = 0;
integer len_errors  = 0;
integer lj_differs  = 0;      /* frames a left-justified reading gets wrong */
integer nonzero     = 0;
integer negative    = 0;

reg        last_bit_before = 1'b0;
reg [31:0] lj_left;

always @(u_rx.frame_event) begin

    if (exp_rd >= exp_wr) begin
        errors = errors + 1;
        if (errors < 6)
            $display("ERROR (delay %0d) frame %0d on the wires without an expected sample", DELAY, u_rx.frames);
    end

    else begin

        if ((u_rx.left_word[31:8]  !== exp_l[exp_rd]) ||
            (u_rx.right_word[31:8] !== exp_r[exp_rd])) begin
            errors = errors + 1;
            if (errors < 6)
                $display("ERROR (delay %0d) frame %0d: got L %06x R %06x, expected L %06x R %06x",
                         DELAY, exp_rd, u_rx.left_word[31:8], u_rx.right_word[31:8],
                         exp_l[exp_rd], exp_r[exp_rd]);
        end
        else
            frames_ok = frames_ok + 1;

        if ((u_rx.left_word[7:0] !== 8'd0) || (u_rx.right_word[7:0] !== 8'd0))
            pad_errors = pad_errors + 1;

        if ((u_rx.left_bits != 32) || (u_rx.right_bits != 32))
            len_errors = len_errors + 1;

        /* the same wires read without the one bit delay */
        lj_left = {last_bit_before, u_rx.left_word[31:1]};
        if (lj_left[31:8] !== exp_l[exp_rd])
            lj_differs = lj_differs + 1;

        if (exp_l[exp_rd] != 24'd0)
            nonzero = nonzero + 1;
        if (exp_l[exp_rd][23])
            negative = negative + 1;

        last_bit_before = u_rx.right_word[0];
        exp_rd          = exp_rd + 1;

    end

end


/* ------------------------------------------------------------
 * The one bit delay, read straight from the wires: after LRCK
 * has fallen, the first rising edge of BCK still shows the pad
 * bit of the frame before, the second one the MSB of the left
 * sample; the same for the right sample after LRCK has risen.
 * ------------------------------------------------------------ */

integer delay_checks = 0;
integer delay_errors = 0;
integer gen          = 0;     /* counts resets, see restart */
integer idx_l, gen_l;
integer idx_r, gen_r;

always @(negedge lrck) begin
    if (rst_n && run) begin
        idx_l = exp_wr - 1;
        gen_l = gen;
        @(posedge bclk);
        if ((gen == gen_l) && (data !== 1'b0))
            delay_errors = delay_errors + 1;
        @(posedge bclk);
        if ((gen == gen_l) && (data !== exp_l[idx_l][23]))
            delay_errors = delay_errors + 1;
        if (gen == gen_l)
            delay_checks = delay_checks + 1;
    end
end

always @(posedge lrck) begin
    if (rst_n && run) begin
        idx_r = exp_wr - 1;
        gen_r = gen;
        @(posedge bclk);
        if ((gen == gen_r) && (data !== 1'b0))
            delay_errors = delay_errors + 1;
        @(posedge bclk);
        if ((gen == gen_r) && (data !== exp_r[idx_r][23]))
            delay_errors = delay_errors + 1;
    end
end


/* ------------------------------------------------------------
 * LRCK: period, low time, BCK edges per frame
 * ------------------------------------------------------------ */

realtime t_lr_fall = -1.0;

realtime lr_period_min = 1.0e12;
realtime lr_period_max = 0.0;
realtime lr_low_min    = 1.0e12;
realtime lr_low_max    = 0.0;

integer  bck_at_fall   = 0;
integer  bck_per_frame_bad = 0;

always @(negedge lrck) begin
    if (rst_n) begin
        if (t_lr_fall >= 0.0) begin
            if (($realtime - t_lr_fall) < lr_period_min) lr_period_min = $realtime - t_lr_fall;
            if (($realtime - t_lr_fall) > lr_period_max) lr_period_max = $realtime - t_lr_fall;
            if ((u_rx.bck_edges - bck_at_fall) != 64)
                bck_per_frame_bad = bck_per_frame_bad + 1;
        end
        t_lr_fall   = $realtime;
        bck_at_fall = u_rx.bck_edges;
    end
end

always @(posedge lrck) begin
    if (rst_n && (t_lr_fall >= 0.0)) begin
        if (($realtime - t_lr_fall) < lr_low_min) lr_low_min = $realtime - t_lr_fall;
        if (($realtime - t_lr_fall) > lr_low_max) lr_low_max = $realtime - t_lr_fall;
    end
end


/* called just before the test bench pulls reset */
task restart;
    begin
        u_rx.restart;
        t_lr_fall = -1.0;
        gen       = gen + 1;
    end
endtask

endmodule


/* ------------------------------------------------------------
 * Test bench
 * ------------------------------------------------------------ */

module tb_pcm5102_i2s;

localparam real TCLK = 81.380;          /* 12.288 MHz */

reg clk   = 1'b0;
reg rst_n = 1'b0;

always #(TCLK / 2.0) clk = ~clk;


/* stand-in for the synthesizer: sample_valid every 256 clk */

reg  [7:0] div;
reg        tick_en = 1'b1;
reg        sample_valid;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        div          <= 8'd0;
        sample_valid <= 1'b0;
    end
    else begin
        div          <= div + 8'd1;
        sample_valid <= tick_en && (div == 8'd200);
    end
end

reg signed [23:0] left_in  = 24'sd0;
reg signed [23:0] right_in = 24'sd0;

wire bclk7, lrck7, data7;
wire bclk0, lrck0, data0;

pcm5102_i2s_tx u_tx7 (
    .clk          (clk),
    .rst_n        (rst_n),
    .sample_valid (sample_valid),
    .left_sample  (left_in),
    .right_sample (right_in),
    .pcm5102_bclk (bclk7),
    .pcm5102_lrck (lrck7),
    .pcm5102_data (data7)
);

pcm5102_i2s_tx #(
    .CAPTURE_DELAY (5'd0)
) u_tx0 (
    .clk          (clk),
    .rst_n        (rst_n),
    .sample_valid (sample_valid),
    .left_sample  (left_in),
    .right_sample (right_in),
    .pcm5102_bclk (bclk0),
    .pcm5102_lrck (lrck0),
    .pcm5102_data (data0)
);

pcm5102_frame_check #(.DELAY(7)) u_chk7 (
    .clk(clk), .rst_n(rst_n), .sample_valid(sample_valid),
    .left_in(left_in), .right_in(right_in),
    .bclk(bclk7), .lrck(lrck7), .data(data7)
);

pcm5102_frame_check #(.DELAY(0)) u_chk0 (
    .clk(clk), .rst_n(rst_n), .sample_valid(sample_valid),
    .left_in(left_in), .right_in(right_in),
    .bclk(bclk0), .lrck(lrck0), .data(data0)
);


integer errors = 0;
integer upd    = 0;       /* clk between sample_valid and the new input */
integer k;
integer n_long;
integer sent   = 0;

reg [23:0] lfsr;

/* wait for the next sample_valid, then change the inputs */
task send;
    input [23:0] l;
    input [23:0] r;
    begin
        @(posedge clk);
        while (!sample_valid)
            @(posedge clk);
        repeat (upd) @(posedge clk);
        left_in  <= l;
        right_in <= r;
        sent = sent + 1;
    end
endtask

task expect_idle;
    input [8*40-1:0] what;
    begin
        if ((bclk7 !== 1'b0) || (lrck7 !== 1'b1) || (data7 !== 1'b0) ||
            (bclk0 !== 1'b0) || (lrck0 !== 1'b1) || (data0 !== 1'b0)) begin
            errors = errors + 1;
            $display("ERROR %0s: wires are not BCK 0, LRCK 1, DATA 0", what);
        end
    end
endtask

task check_timing;
    input integer which;
    input realtime per_min;
    input realtime per_max;
    input realtime high_min;
    input realtime high_max;
    input realtime setup;
    input realtime hold;
    input realtime lr_min;
    input realtime lr_max;
    input realtime low_min;
    input realtime low_max;
    begin
        $display("delay %0d: BCK period %0.3f..%0.3f ns (%0.4f MHz), high %0.3f..%0.3f ns",
                 which, per_min, per_max, 1000.0 / per_min, high_min, high_max);
        $display("delay %0d: LRCK period %0.2f..%0.2f ns (%0.2f Hz), low %0.2f..%0.2f ns",
                 which, lr_min, lr_max, 1.0e9 / lr_min, low_min, low_max);
        $display("delay %0d: LRCK/DATA stable %0.3f ns before and %0.3f ns after the rising edge of BCK",
                 which, setup, hold);
        if ((per_min < 4.0 * TCLK - 0.002) || (per_max > 4.0 * TCLK + 0.002) ||
            (high_min < 2.0 * TCLK - 0.002) || (high_max > 2.0 * TCLK + 0.002) ||
            (lr_min < 256.0 * TCLK - 0.01) || (lr_max > 256.0 * TCLK + 0.01) ||
            (low_min < 128.0 * TCLK - 0.01) || (low_max > 128.0 * TCLK + 0.01) ||
            (setup < 2.0 * TCLK - 0.002) || (hold < 2.0 * TCLK - 0.002)) begin
            errors = errors + 1;
            $display("ERROR delay %0d: wire timing is not 4 clk per BCK, 256 clk per frame", which);
        end
    end
endtask

task report;
    input integer which;
    input integer frames_ok;
    input integer e;
    input integer pad;
    input integer len;
    input integer bit_e;
    input integer bad_edge;
    input integer per_frame_bad;
    input integer dchk;
    input integer derr;
    input integer lj;
    input integer nz;
    input integer neg;
    input integer left_over;
    begin
        $display("delay %0d: %0d frames equal (%0d not zero, %0d negative), %0d wrong, pad bits wrong in %0d, word length wrong in %0d",
                 which, frames_ok, nz, neg, e, pad, len + bit_e);
        $display("delay %0d: one bit delay read from the wires in %0d frames, %0d wrong; read as left-justified %0d frames would be wrong",
                 which, dchk, derr, lj);
        if ((e != 0) || (pad != 0) || (len != 0) || (bit_e != 0) || (bad_edge != 0) ||
            (per_frame_bad != 0) || (derr != 0) || (left_over > 1) || (frames_ok < 1000) || (lj == 0)) begin
            errors = errors + 1;
            $display("ERROR delay %0d: wrong %0d, pad %0d, length %0d/%0d, edges not on falling BCK %0d, frames without 64 BCK %0d, one bit delay %0d, expected frames never seen %0d",
                     which, e, pad, len, bit_e, bad_edge, per_frame_bad, derr, left_over);
        end
    end
endtask


initial begin

    if (!$value$plusargs("frames=%d", n_long))
        n_long = 48000;


    /* ---------------- A: reset ---------------- */

    repeat (20) @(posedge clk);
    expect_idle("in reset");

    @(negedge clk);
    rst_n = 1'b1;

    /* sample_valid comes 201 clk after reset; nothing before it */
    repeat (150) @(posedge clk);
    expect_idle("after reset, before the first sample");
    if ((u_chk7.u_rx.bck_edges != 0) || (u_chk0.u_rx.bck_edges != 0)) begin
        errors = errors + 1;
        $display("ERROR: BCK moved before the first sample");
    end


    /* ---------------- B: chosen values ---------------- */

    upd = 0;

    send(24'h000000, 24'h000000);
    send(24'h000001, 24'hFFFFFF);
    send(24'hFFFFFF, 24'h000001);
    send(24'h7FFFFF, 24'h800000);
    send(24'h800000, 24'h7FFFFF);
    send(24'h123456, 24'hEDCBAA);
    send(24'hEDCBAA, 24'h123456);
    send(24'hAAAAAA, 24'h555555);
    send(24'h555555, 24'hAAAAAA);
    send(24'h000080, 24'hFFFF7F);
    send(24'h7FFFFF, 24'h7FFFFF);
    send(24'h800000, 24'h800000);
    send(24'h000000, 24'h000000);

    for (k = 0; k < 24; k = k + 1)
        send(24'd1 << k, ~(24'd1 << k));

    for (k = 0; k < 24; k = k + 1)
        send(~(24'd1 << k), 24'd1 << k);


    /* ---------------- C: changing values, input moment varies ---------------- */

    for (k = 0; k < 4000; k = k + 1) begin
        case (k / 500)
            0: upd = 0;
            1: upd = 3;
            2: upd = 6;
            3: upd = 7;
            4: upd = 8;
            5: upd = 100;
            6: upd = 200;
            default: upd = 248;
        endcase
        send(k * 4099 + 17, 24'd0 - (k * 4099 + 17));
    end

    upd = 40;

    for (k = 0; k < 500; k = k + 1)
        send(k * 33331, k * 33331);


    /* ---------------- D: reset in the middle of a frame ---------------- */

    repeat (777) @(posedge clk);
    #7;
    u_chk7.restart;
    u_chk0.restart;
    rst_n = 1'b0;
    #1;
    expect_idle("right after reset went low");

    repeat (1000) @(posedge clk);
    expect_idle("during the second reset");

    k = u_chk7.u_rx.bck_edges;

    @(negedge clk);
    rst_n = 1'b1;

    repeat (150) @(posedge clk);
    expect_idle("after the second reset, before the first sample");
    if (u_chk7.u_rx.bck_edges != k) begin
        errors = errors + 1;
        $display("ERROR: BCK moved in or right after the second reset");
    end

    for (k = 0; k < 300; k = k + 1)
        send(24'h400000 + k * 1021, 24'hC00000 - k * 1021);


    /* ---------------- E: sample_valid stops, frames go on with zero ---------------- */

    repeat (300) @(posedge clk);
    tick_en = 1'b0;
    repeat (256 * 6) @(posedge clk);
    tick_en = 1'b1;

    for (k = 0; k < 300; k = k + 1)
        send(24'h200000 + k * 2053, 24'hE00000 - k * 2053);


    /* ---------------- F: long run ---------------- */

    lfsr = 24'hACE1B5;

    for (k = 0; k < n_long; k = k + 1) begin
        /* x^24 + x^23 + x^22 + x^17 + 1 */
        lfsr = {lfsr[22:0], lfsr[23] ^ lfsr[22] ^ lfsr[21] ^ lfsr[16]};
        send(lfsr, {lfsr[11:0], lfsr[23:12]});
    end

    repeat (600) @(posedge clk);


    /* ---------------- results ---------------- */

    $display("samples sent: %0d", sent);

    report(7, u_chk7.frames_ok, u_chk7.errors, u_chk7.pad_errors, u_chk7.len_errors,
           u_chk7.u_rx.bit_errors, u_chk7.u_rx.bad_edge, u_chk7.bck_per_frame_bad,
           u_chk7.delay_checks, u_chk7.delay_errors, u_chk7.lj_differs,
           u_chk7.nonzero, u_chk7.negative, u_chk7.exp_wr - u_chk7.exp_rd);

    check_timing(7, u_chk7.u_rx.bck_period_min, u_chk7.u_rx.bck_period_max,
                 u_chk7.u_rx.bck_high_min, u_chk7.u_rx.bck_high_max,
                 u_chk7.u_rx.setup_min, u_chk7.u_rx.hold_min,
                 u_chk7.lr_period_min, u_chk7.lr_period_max,
                 u_chk7.lr_low_min, u_chk7.lr_low_max);

    report(0, u_chk0.frames_ok, u_chk0.errors, u_chk0.pad_errors, u_chk0.len_errors,
           u_chk0.u_rx.bit_errors, u_chk0.u_rx.bad_edge, u_chk0.bck_per_frame_bad,
           u_chk0.delay_checks, u_chk0.delay_errors, u_chk0.lj_differs,
           u_chk0.nonzero, u_chk0.negative, u_chk0.exp_wr - u_chk0.exp_rd);

    check_timing(0, u_chk0.u_rx.bck_period_min, u_chk0.u_rx.bck_period_max,
                 u_chk0.u_rx.bck_high_min, u_chk0.u_rx.bck_high_max,
                 u_chk0.u_rx.setup_min, u_chk0.u_rx.hold_min,
                 u_chk0.lr_period_min, u_chk0.lr_period_max,
                 u_chk0.lr_low_min, u_chk0.lr_low_max);

    if (errors == 0)
        $display("PASS: %0d frames decoded and equal", u_chk7.frames_ok);
    else
        $display("FAIL: %0d errors", errors);

    $finish;

end

endmodule
