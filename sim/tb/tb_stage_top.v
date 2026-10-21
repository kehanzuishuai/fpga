`timescale 1ns/1ps

/* ============================================================
 * Bring-up stages 1 and 2 of the board top (BUILD_STAGE):
 *
 *   1  new key reader with the previous sound (previous voice,
 *      1/N mix gain, no effects)
 *   2  new piano engine with the effects switched off
 *
 * Checks that each stage builds and plays with the touch pad
 * still in its factory mode (8 keys): key 1 gives exactly one
 * voice and sound on the audio bus, key 9 gives nothing.
 *
 *   -Ptb_stage_top.STAGE=1   or   =2
 * ============================================================ */

module tb_stage_top;

parameter STAGE = 1;

reg clk_50m = 1'b0;
reg rst_n   = 1'b0;

always #10 clk_50m = ~clk_50m;

reg  [15:0] touch = 16'd0;
wire        scl, sdo, i2s_bclk, i2s_lrck, i2s_data, audio_pa_en;

ttp229_bfm #(.KEY16(0), .MULTI(0)) u_chip (.touch(touch), .scl(scl), .sdo(sdo));

tang_mega_138k_pro_top #(
    .BUILD_STAGE (STAGE),
    .DISPLAY_ENABLE(0)
) u_top (
    .clk_50m(clk_50m), .rst_n(rst_n), .ttp229_scl(scl), .ttp229_sdo(sdo),
    .i2s_bclk(i2s_bclk), .i2s_lrck(i2s_lrck), .i2s_data(i2s_data), .audio_pa_en(audio_pa_en)
);

wire signed [23:0] audio_out    = u_top.u_synth_top.audio_out;
wire [31:0]        voice_active = u_top.u_synth_top.u_synth.u_core.u_bank.voice_active;

integer peak = 0;
integer x_count = 0;
integer n_active;
integer k;
integer errors = 0;

always @(posedge u_top.clk_12m288) begin
    if (u_top.u_synth_top.sample_tick && rst_n) begin
        if (^audio_out === 1'bx)
            x_count = x_count + 1;
        else begin
            if (audio_out > peak)  peak = audio_out;
            if (-audio_out > peak) peak = -audio_out;
        end
    end
end

task count_active;
    begin
        n_active = 0;
        for (k = 0; k < 32; k = k + 1)
            n_active = n_active + voice_active[k];
    end
endtask

initial begin
    #(2000);
    rst_n = 1'b1;
    #(10_000_000);

    touch = 16'h0001;
    #(40_000_000);
    count_active;
    $display("stage %0d, chip in 8 key mode, key 1: %0d voice active, peak %0d", STAGE, n_active, peak);
    if ((n_active != 1) || (peak < 100000))
        errors = errors + 1;

    touch = 16'h0000;
    #(15_000_000);
    touch = 16'h0100;
    #(30_000_000);
    if (voice_active & ~u_top.u_synth_top.u_synth.u_core.u_bank.voice_releasing) begin
        errors = errors + 1;
        $display("ERROR: key 9 started a voice although the chip is in 8 key mode");
    end

    if (x_count != 0) begin
        errors = errors + 1;
        $display("ERROR: %0d samples with X", x_count);
    end

    if (errors == 0)
        $display("PASS");
    else
        $display("FAIL");
    $finish;
end

endmodule
