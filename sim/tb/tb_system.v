`timescale 1ns/1ps

/* ============================================================
 * Whole design, from the touch pad to the DAC pins:
 *
 *   TTP229 model -> tang_mega_138k_pro_top (real RTL, PLL replaced
 *   by sim/models/gowin_pll_stub.v) -> PT8211 serial data
 *
 * Checks
 *   - how many voices sound after each key change, no stuck voice
 *   - no X on the audio bus, no engine overrun in any voice
 *   - the 16 bit words on the DAC pins equal audio_out[23:8]
 *   - the 24 bit words on the PCM5102A wires equal audio_out
 *   - every voice writes its own log (build/sys_voice_<n>.txt) so
 *     that tools/compare_pcm.py can check all 32 against the model
 *   - the mixed output is written to build/sys_pcm.txt
 *   (+tag=name replaces the "sys" in these file names)
 *
 * +short=1 runs only the first 70 ms (speed check).
 * +stress=1 replaces the key sequence: all sixteen keys are tapped
 *           eight times in 0.2 s (128 Note On), so that voices are
 *           reused while they still sound (voice stealing).
 * ============================================================ */

`define TOP    u_top
`define CORE   u_top.u_synth_top.u_synth.u_core
`define BANK   u_top.u_synth_top.u_synth.u_core.u_bank
`define LOADER u_top.u_synth_top.u_synth.u_core.u_bank.G_PARTIAL.u_note_loader

module tb_system;

reg clk_50m = 1'b0;
reg rst_n   = 1'b0;

always #10 clk_50m = ~clk_50m;

reg  [15:0] touch = 16'd0;
wire        scl;
wire        sdo;

ttp229_bfm #(
    .KEY16 (1),
    .MULTI (1),
    .DV_EN (1)
) u_chip (
    .touch (touch),
    .scl   (scl),
    .sdo   (sdo)
);

wire i2s_bclk;
wire i2s_lrck;
wire i2s_data;
wire audio_pa_en;

tang_mega_138k_pro_top #(.DISPLAY_ENABLE(0)) u_top (
    .clk_50m     (clk_50m),
    .rst_n       (rst_n),
    .ttp229_scl  (scl),
    .ttp229_sdo  (sdo),
    .i2s_bclk    (i2s_bclk),
    .i2s_lrck    (i2s_lrck),
    .i2s_data    (i2s_data),
    .audio_pa_en (audio_pa_en)
);

wire clk = `TOP.clk_12m288;
wire sample_tick = `TOP.u_synth_top.sample_tick;

wire signed [23:0] audio_out = `TOP.u_synth_top.audio_out;
wire [31:0] voice_active     = `BANK.voice_active;
wire [31:0] voice_releasing  = `BANK.voice_releasing;

integer tick = -1;

always @(posedge clk)
    if (sample_tick)
        tick = tick + 1;


/* ------------------------------------------------------------
 * Per-voice logs for the bit-exact comparison
 * ------------------------------------------------------------ */

integer errors = 0;
integer checks = 0;
integer overruns = 0;

genvar g;

generate
    for (g = 0; g < 32; g = g + 1) begin : LOG

        integer fd;
        reg [8*80-1:0] fname;
        reg [8*20-1:0] tag;

        initial begin
            if (!$value$plusargs("tag=%s", tag))
                tag = "sys";
            $sformat(fname, "build/%0s_voice_%0d.txt", tag, g);
            fd = $fopen(fname, "w");
        end

        always @(posedge clk) begin

            if (`BANK.G_PARTIAL.ld_done[g])
                $fdisplay(fd, "L %0d %0d %0d", tick, `LOADER.note_r, `LOADER.vel_r);

            if (`BANK.G_PARTIAL.G_VOICE[g].u_voice.dbg_sample_strobe)
                $fdisplay(fd, "S %0d %0d %0d %0d", tick,
                          $signed(`BANK.G_PARTIAL.G_VOICE[g].u_voice.sample),
                          `BANK.G_PARTIAL.G_VOICE[g].u_voice.dbg_rel,
                          `BANK.G_PARTIAL.G_VOICE[g].u_voice.dbg_fade);

            if (`BANK.G_PARTIAL.G_VOICE[g].u_voice.dbg_overrun === 1'b1)
                overruns = overruns + 1;

        end

    end
endgenerate


/* ------------------------------------------------------------
 * Mixed PCM, X check
 * ------------------------------------------------------------ */

integer fd_pcm;
integer x_count = 0;
integer peak = 0;
integer clip_count = 0;

always @(posedge clk) begin
    if (sample_tick && (tick >= 0)) begin
        $fdisplay(fd_pcm, "%0d", audio_out);
        if (^audio_out === 1'bx)
            x_count = x_count + 1;
        else begin
            if (audio_out > peak)  peak = audio_out;
            if (-audio_out > peak) peak = -audio_out;
        end
        if (`CORE.dbg_clip === 1'b1)
            clip_count = clip_count + 1;
    end
end


/* ------------------------------------------------------------
 * PT8211 receiver: 16 bit, MSB first, sampled on BCLK rising,
 * WS high = left.  The word after a rising WS must be the upper
 * 16 bit of audio_out at that moment.
 * ------------------------------------------------------------ */

reg signed [15:0] expect_word;
reg signed [15:0] rx_shift;
integer           rx_bits = 99;
integer           dac_words = 0;
integer           dac_errors = 0;

/* words that started before the reset was released are not checked */
always @(posedge i2s_lrck) begin
    expect_word = audio_out[23:8];
    rx_bits     = (tick >= 1) ? 0 : 99;
end

always @(posedge i2s_bclk) begin
    if (rx_bits < 16) begin
        rx_shift = {rx_shift[14:0], i2s_data};
        rx_bits  = rx_bits + 1;
        if (rx_bits == 16) begin
            dac_words = dac_words + 1;
            if (rx_shift !== expect_word) begin
                dac_errors = dac_errors + 1;
                if (dac_errors < 5)
                    $display("ERROR %0.2f ms: DAC word %0d, audio_out[23:8] %0d",
                             $time / 1.0e6, rx_shift, expect_word);
            end
        end
    end
end


/* ------------------------------------------------------------
 * PCM5102A wires.  The transmitter sits inside synth_top; its
 * three signals are not pins in this build (see the define in
 * the top level file), so they are read from inside.
 *
 * Decoded by sim/models/i2s_rx_model.v.  Frame n must carry, in
 * both slots, the 24 bit audio_out that the n-th PT8211 frame
 * was cut from, and eight zero bits behind it.
 * ------------------------------------------------------------ */

i2s_rx_model u_i2s_rx (
    .bclk (`TOP.u_synth_top.pcm5102_bclk),
    .lrck (`TOP.u_synth_top.pcm5102_lrck),
    .data (`TOP.u_synth_top.pcm5102_data)
);

reg signed [23:0] pcm_at_start [0:262143];

integer frame_no   = -1;
integer i2s_frames = 0;
integer i2s_errors = 0;

always @(posedge i2s_lrck) begin
    if (`TOP.u_synth_top.rst_n) begin
        frame_no               = frame_no + 1;
        pcm_at_start[frame_no] = audio_out;
    end
end

always @(u_i2s_rx.frame_event) begin
    i2s_frames = i2s_frames + 1;
    if ((u_i2s_rx.left_word  !== {pcm_at_start[u_i2s_rx.frames - 1], 8'd0}) ||
        (u_i2s_rx.right_word !== {pcm_at_start[u_i2s_rx.frames - 1], 8'd0})) begin
        i2s_errors = i2s_errors + 1;
        if (i2s_errors < 5)
            $display("ERROR %0.2f ms: PCM5102A frame %0d L %08x R %08x, audio_out %06x",
                     $time / 1.0e6, u_i2s_rx.frames - 1, u_i2s_rx.left_word, u_i2s_rx.right_word,
                     pcm_at_start[u_i2s_rx.frames - 1]);
    end
end


/* ------------------------------------------------------------
 * Checks
 * ------------------------------------------------------------ */

function integer ones;
    input [31:0] v;
    integer n;
    begin
        ones = 0;
        for (n = 0; n < 32; n = n + 1)
            ones = ones + v[n];
    end
endfunction

task expect_voices;
    input integer    held;
    input [8*40-1:0] what;
    integer got;
    begin
        got = ones(voice_active & ~voice_releasing);
        checks = checks + 1;
        if (got != held) begin
            errors = errors + 1;
            $display("ERROR %0.2f ms [%0s]: %0d voices held, expected %0d (active %b)",
                     $time / 1.0e6, what, got, held, voice_active);
        end
        else
            $display("  %0.1f ms %0s: %0d held, %0d active in total",
                     $time / 1.0e6, what, got, ones(voice_active));
    end
endtask

integer p_short;
integer p_stress;
reg [8*20-1:0] pcm_tag;
reg [8*80-1:0] pcm_name;
integer round;
integer loads = 0;
integer fades = 0;

/* count Note On loads and voices that had to fade an old note */
always @(posedge clk) begin
    if (|`BANK.G_PARTIAL.ld_done)
        loads = loads + 1;
    if (`BANK.note_on_acc && (`BANK.voice_active[`BANK.chosen] === 1'b1))
        fades = fades + 1;
end

initial begin

    if (!$value$plusargs("short=%d", p_short))
        p_short = 0;
    if (!$value$plusargs("stress=%d", p_stress))
        p_stress = 0;

    if (!$value$plusargs("tag=%s", pcm_tag))
        pcm_tag = "sys";
    $sformat(pcm_name, "build/%0s_pcm.txt", pcm_tag);
    fd_pcm = $fopen(pcm_name, "w");

    #(2000);
    rst_n = 1'b1;

    if (p_stress != 0) begin

        #(10_000_000);

        for (round = 0; round < 8; round = round + 1) begin
            touch = 16'hFFFF;
            #(13_000_000);
            touch = 16'h0000;
            #(12_000_000);
        end

        /*
         * A reused voice first fades its old note (up to 1.3 ms) and
         * is then loaded (0.2 ms), so the Note FIFO backs up during
         * the taps.  A key that goes down and up again while its
         * Note On is still waiting for FIFO space is dropped by the
         * bridge, which is intended; so the number of notes is
         * between 64 and 132, not exactly 132.
         */
        touch = 16'h8421;                   /* four keys stay down */
        #(120_000_000);
        expect_voices(4, "four keys held after the taps");

        checks = checks + 2;
        if ((loads < 64) || (loads > 132)) begin
            errors = errors + 1;
            $display("ERROR: %0d notes loaded, expected 64..132", loads);
        end
        if (fades == 0) begin
            errors = errors + 1;
            $display("ERROR: no voice was reused while active");
        end
        $display("  notes loaded %0d, of which %0d into a voice that was still sounding", loads, fades);

        touch = 16'h0000;
        #(450_000_000);
        checks = checks + 1;
        if (voice_active !== 32'd0) begin
            errors = errors + 1;
            $display("ERROR: voices still active %b", voice_active);
        end

    end

    else begin

    #(10_000_000);
    touch = 16'h0001;                       /* key 1: C4 */
    #(45_000_000);
    expect_voices(1, "key 1");

    if (p_short == 0) begin

        touch = 16'h0095;                   /* keys 1,3,5,8 */
        #(50_000_000);
        expect_voices(4, "keys 1,3,5,8");

        touch = 16'h0091;                   /* key 3 up */
        #(40_000_000);
        expect_voices(3, "key 3 released");

        touch = 16'hFFFF;                   /* all sixteen */
        #(80_000_000);
        expect_voices(16, "all sixteen keys");

        touch = 16'h0000;
        #(15_000_000);
        expect_voices(0, "all keys released");

        /* dampers: every voice has to end by itself */
        #(385_000_000);
        checks = checks + 1;
        if (voice_active !== 32'd0) begin
            errors = errors + 1;
            $display("ERROR: voices still active %b", voice_active);
        end

    end

    end

    #(15_000_000);

    $fflush(fd_pcm);
    $fclose(fd_pcm);

    checks = checks + 5;

    if (x_count != 0) begin
        errors = errors + 1;
        $display("ERROR: %0d samples with X", x_count);
    end
    if (overruns != 0) begin
        errors = errors + 1;
        $display("ERROR: engine overrun");
    end
    if (dac_errors != 0) begin
        errors = errors + 1;
        $display("ERROR: %0d wrong DAC words", dac_errors);
    end
    if ((i2s_errors != 0) || (u_i2s_rx.bit_errors != 0) || (u_i2s_rx.bad_edge != 0) ||
        (i2s_frames < frame_no - 1) || (i2s_frames < 1000)) begin
        errors = errors + 1;
        $display("ERROR: PCM5102A: %0d wrong frames of %0d (PT8211 frames %0d), %0d words not 32 bit, %0d edges not on falling BCK",
                 i2s_errors, i2s_frames, frame_no + 1, u_i2s_rx.bit_errors, u_i2s_rx.bad_edge);
    end
    if (peak == 0) begin
        errors = errors + 1;
        $display("ERROR: silence");
    end

    $display("samples %0d, peak %0d (%0.1f dBFS), clipped samples %0d, DAC words checked %0d",
             tick + 1, peak, 20.0 * $ln(peak / 8388608.0) / $ln(10.0), clip_count, dac_words);

    $display("PCM5102A frames checked %0d (24 bit, equal to audio_out), wrong %0d", i2s_frames, i2s_errors);

    if (errors == 0)
        $display("PASS: %0d checks", checks);
    else
        $display("FAIL: %0d errors in %0d checks", errors, checks);

    $finish;

end

endmodule
