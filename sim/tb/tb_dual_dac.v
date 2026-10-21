`timescale 1ns/1ps

/* ============================================================
 * Board top with both audio outputs.
 *
 *   touch pad model -> tang_mega_138k_pro_top -> PT8211 pins
 *                                             -> PCM5102A wires
 *
 * PT8211 pins (always)
 *   - decoded as the PT8211 reads them (16 bit, WS high = left,
 *     MSB with the WS edge); every word must be audio_out[23:8]
 *   - BCLK 8 clk, 32 BCLK per frame
 *   - a signature over the three pins at every 12.288 MHz clock
 *     edge and a file with all decoded words, so that two builds
 *     can be compared (+tag=name -> build/dualdac_<name>_pt8211.txt)
 *
 * PCM5102A wires (not in a build from before the transmitter)
 *   - decoded by sim/models/i2s_rx_model.v; every frame must be
 *     the 24 bit audio_out that the PT8211 frame with the same
 *     number was cut from, in both slots, pad bits zero
 *   - 64 BCK per frame, wire timing
 *
 * Compile with
 *   -DEXT_PCM5102      the top has the three PCM5102A ports
 *                      (same define as in the top level file)
 *   -DPCM5102_INSIDE   the ports are switched off (default
 *                      build): look at the transmitter inside
 *   neither            sources from before the transmitter
 *
 *   -Ptb_dual_dac.STAGE=1|2|3   BUILD_STAGE of the top
 * ============================================================ */

`ifdef EXT_PCM5102
    `define HAVE_PCM5102
`endif
`ifdef PCM5102_INSIDE
    `define HAVE_PCM5102
`endif

module tb_dual_dac;

parameter STAGE = 3;

localparam real TCLK = 81.380;

reg clk_50m = 1'b0;
reg rst_n   = 1'b0;

always #10 clk_50m = ~clk_50m;

reg  [15:0] touch = 16'd0;
wire        scl;
wire        sdo;

ttp229_bfm #(
    .KEY16 (1),
    .MULTI (1)
) u_chip (
    .touch (touch),
    .scl   (scl),
    .sdo   (sdo)
);

wire i2s_bclk;
wire i2s_lrck;
wire i2s_data;
wire audio_pa_en;

`ifdef EXT_PCM5102
wire pcm_bclk;
wire pcm_lrck;
wire pcm_data;
`endif

tang_mega_138k_pro_top #(
    .BUILD_STAGE (STAGE),
    .DISPLAY_ENABLE(0)
) u_top (
    .clk_50m      (clk_50m),
    .rst_n        (rst_n),
    .ttp229_scl   (scl),
    .ttp229_sdo   (sdo),
    .i2s_bclk     (i2s_bclk),
    .i2s_lrck     (i2s_lrck),
    .i2s_data     (i2s_data),
`ifdef EXT_PCM5102
    .pcm5102_bclk (pcm_bclk),
    .pcm5102_lrck (pcm_lrck),
    .pcm5102_data (pcm_data),
`endif
    .audio_pa_en  (audio_pa_en)
);

`ifdef PCM5102_INSIDE
wire pcm_bclk = u_top.u_synth_top.pcm5102_bclk;
wire pcm_lrck = u_top.u_synth_top.pcm5102_lrck;
wire pcm_data = u_top.u_synth_top.pcm5102_data;
`endif

wire clk         = u_top.clk_12m288;
wire sample_tick = u_top.u_synth_top.sample_tick;

wire signed [23:0] audio_out = u_top.u_synth_top.audio_out;

integer errors = 0;


/* ------------------------------------------------------------
 * Signature of the PT8211 pins, one step per clock edge
 * ------------------------------------------------------------ */

reg [63:0] sig = 64'h1;
integer    sig_edges = 0;

always @(posedge clk) if (u_top.synth_rst_n === 1'b1) begin
    if ((^{i2s_bclk,i2s_lrck,i2s_data}) === 1'bx)
        $fatal(1,"unknown PT8211 pins after audio reset released");
    sig = {sig[62:0], sig[63] ^ sig[62] ^ sig[60] ^ sig[59]}
          ^ {61'd0, i2s_bclk, i2s_lrck, i2s_data};
    sig_edges = sig_edges + 1;
end


/* ------------------------------------------------------------
 * PT8211 receiver.  A frame starts with the rising edge of WS.
 * audio_out is noted at that moment: it is what both outputs
 * have to carry in this frame.
 * ------------------------------------------------------------ */

reg signed [23:0] pcm_at_start [0:16383];
reg        [15:0] pt_left      [0:16383];
reg        [15:0] pt_right     [0:16383];

integer pt_frames = -1;       /* number of the frame on the pins */
integer pt_bits   = 99;
integer pt_done   = 0;
integer pt_errors = 0;
reg [15:0] pt_shift;

integer fd_pt;

always @(posedge i2s_lrck) begin
    if (u_top.u_synth_top.rst_n) begin
        pt_frames               = pt_frames + 1;
        pcm_at_start[pt_frames] = audio_out;
        pt_bits                 = 0;
    end
end

always @(posedge i2s_bclk) begin
    if (pt_bits < 32) begin
        pt_shift = {pt_shift[14:0], i2s_data};
        pt_bits  = pt_bits + 1;
        if (pt_bits == 16) begin
            pt_left[pt_frames] = pt_shift;
            if (i2s_lrck !== 1'b1)
                pt_errors = pt_errors + 1;
        end
        if (pt_bits == 32) begin
            pt_right[pt_frames] = pt_shift;
            pt_done             = pt_done + 1;
            $fdisplay(fd_pt, "%0d %0d", $signed(pt_left[pt_frames]), $signed(pt_shift));
            if (i2s_lrck !== 1'b0)
                pt_errors = pt_errors + 1;
            if ((pt_left[pt_frames] !== pcm_at_start[pt_frames][23:8]) ||
                (pt_shift           !== pcm_at_start[pt_frames][23:8])) begin
                pt_errors = pt_errors + 1;
                if (pt_errors < 5)
                    $display("ERROR PT8211 frame %0d: L %04x R %04x, audio_out[23:8] %04x", pt_frames,
                             pt_left[pt_frames], pt_shift, pcm_at_start[pt_frames][23:8]);
            end
        end
    end
end

/* BCLK and WS of the PT8211 */

realtime pt_t_rise = -1.0;
realtime pt_t_ws   = -1.0;
integer  pt_timing_errors = 0;

always @(posedge i2s_bclk) begin
    if ((pt_frames >= 0) && (pt_t_rise >= 0.0) &&
        ((($realtime - pt_t_rise) < 8.0 * TCLK - 0.002) || (($realtime - pt_t_rise) > 8.0 * TCLK + 0.002)))
        pt_timing_errors = pt_timing_errors + 1;
    pt_t_rise = $realtime;
end

always @(posedge i2s_lrck) begin
    if ((pt_frames >= 1) && (pt_t_ws >= 0.0) &&
        ((($realtime - pt_t_ws) < 256.0 * TCLK - 0.01) || (($realtime - pt_t_ws) > 256.0 * TCLK + 0.01)))
        pt_timing_errors = pt_timing_errors + 1;
    pt_t_ws = $realtime;
end


/* ------------------------------------------------------------
 * When does audio_out change, counted in clk after sample_tick
 * ------------------------------------------------------------ */

reg signed [23:0] audio_prev = 24'sd0;
integer since_tick = 0;
integer change_min = 9999;
integer change_max = -1;
integer peak = 0;
integer x_count = 0;
integer neg_count = 0;

always @(posedge clk) begin
    if (sample_tick)
        since_tick = 0;
    else
        since_tick = since_tick + 1;
    if ((audio_out !== audio_prev) && u_top.u_synth_top.rst_n) begin
        if (since_tick < change_min) change_min = since_tick;
        if (since_tick > change_max) change_max = since_tick;
    end
    audio_prev = audio_out;
    if (sample_tick && u_top.u_synth_top.rst_n) begin
        if (^audio_out === 1'bx)
            x_count = x_count + 1;
        else begin
            if (audio_out > peak)  peak = audio_out;
            if (-audio_out > peak) peak = -audio_out;
            if (audio_out < 0)     neg_count = neg_count + 1;
        end
    end
end


/* ------------------------------------------------------------
 * PCM5102A wires
 * ------------------------------------------------------------ */

`ifdef HAVE_PCM5102

i2s_rx_model u_rx (
    .bclk (pcm_bclk),
    .lrck (pcm_lrck),
    .data (pcm_data)
);

integer i2s_ok      = 0;
integer i2s_errors  = 0;
integer i2s_nonzero = 0;
integer n;

always @(u_rx.frame_event) begin

    n = u_rx.frames - 1;

    if ((u_rx.left_word[31:8]  !== pcm_at_start[n]) ||
        (u_rx.right_word[31:8] !== pcm_at_start[n]) ||
        (u_rx.left_word[7:0]   !== 8'd0) ||
        (u_rx.right_word[7:0]  !== 8'd0) ||
        (u_rx.left_word[31:16] !== pt_left[n]) ||
        (u_rx.right_word[31:16] !== pt_right[n])) begin
        i2s_errors = i2s_errors + 1;
        if (i2s_errors < 5)
            $display("ERROR frame %0d: PCM5102A L %08x R %08x, audio_out %06x, PT8211 L %04x R %04x", n,
                     u_rx.left_word, u_rx.right_word, pcm_at_start[n], pt_left[n], pt_right[n]);
    end
    else begin
        i2s_ok = i2s_ok + 1;
        if (pcm_at_start[n] != 24'sd0)
            i2s_nonzero = i2s_nonzero + 1;
    end

end

/* first frame: both outputs must start at the same clock edge */

realtime t_first_pt  = -1.0;
realtime t_first_i2s = -1.0;

always @(posedge i2s_lrck)
    if (u_top.u_synth_top.rst_n && (t_first_pt < 0.0))
        t_first_pt = $realtime;

always @(negedge pcm_lrck)
    if (u_top.u_synth_top.rst_n && (t_first_i2s < 0.0))
        t_first_i2s = $realtime;

`endif


/* ------------------------------------------------------------
 * Keys
 * ------------------------------------------------------------ */

reg [8*20-1:0]  tag;
reg [8*80-1:0]  fname;

initial begin

    if (!$value$plusargs("tag=%s", tag))
        tag = "run";
    $sformat(fname, "build/dualdac_%0s_pt8211.txt", tag);
    fd_pt = $fopen(fname, "w");

    #(2000);
    rst_n = 1'b1;
    #(8_000_000);

    touch = 16'h0091;           /* keys 1, 5, 8 */
    #(45_000_000);
    touch = 16'h0000;
    #(15_000_000);
    touch = 16'hFFFF;           /* all sixteen */
    #(45_000_000);
    touch = 16'h0000;
    #(12_000_000);

    $fflush(fd_pt);
    $fclose(fd_pt);

    $display("stage %0d: %0d clock edges, PT8211 pin signature %016x", STAGE, sig_edges, sig);
    $display("stage %0d: PT8211 frames %0d, peak %0d, negative samples %0d, wrong %0d, timing errors %0d",
             STAGE, pt_done, peak, neg_count, pt_errors, pt_timing_errors);
    $display("stage %0d: audio_out changes %0d..%0d clk after sample_tick; both outputs take it 8 clk after",
             STAGE, change_min, change_max);

    if ((pt_errors != 0) || (pt_timing_errors != 0) || (x_count != 0) || (pt_done < 5000) || (peak < 100000))
        errors = errors + 1;

`ifdef HAVE_PCM5102

    $display("stage %0d: PCM5102A frames %0d equal to audio_out and to the PT8211 frame (%0d not zero), %0d wrong",
             STAGE, i2s_ok, i2s_nonzero, i2s_errors);
    $display("stage %0d: PCM5102A BCK %0.3f..%0.3f ns, stable %0.3f ns before / %0.3f ns after the rising edge, words not 32 bit %0d, edges not on falling BCK %0d",
             STAGE, u_rx.bck_period_min, u_rx.bck_period_max, u_rx.setup_min, u_rx.hold_min,
             u_rx.bit_errors, u_rx.bad_edge);
    $display("stage %0d: first frame starts %0.3f ns (PT8211) and %0.3f ns (PCM5102A)",
             STAGE, t_first_pt, t_first_i2s);

    if ((i2s_errors != 0) || (i2s_ok < 5000) || (i2s_nonzero < 1000) ||
        (i2s_ok < pt_done - 2) || (i2s_ok > pt_done) ||
        (u_rx.bit_errors != 0) || (u_rx.bad_edge != 0) ||
        (u_rx.bck_period_min < 4.0 * TCLK - 0.002) || (u_rx.bck_period_max > 4.0 * TCLK + 0.002) ||
        (u_rx.setup_min < 2.0 * TCLK - 0.002) || (u_rx.hold_min < 2.0 * TCLK - 0.002) ||
        (t_first_pt != t_first_i2s))
        errors = errors + 1;

`endif

    if (errors == 0)
        $display("PASS");
    else
        $display("FAIL");

    $finish;

end

endmodule
