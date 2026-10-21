`timescale 1ns/1ps

/* ============================================================
 * piano_fx driven from a file of mix samples.
 *
 *   +in=build/fx_in.txt     one signed decimal sample per line
 *   +out=build/fx_out.txt   one output sample per line
 *   +sb=1 +rev=1 +eq=0 +soft_mode=1
 *
 * GAIN_SHIFT is a compile time value: -Ptb_piano_fx.GAIN=0
 *
 * tools/fx_check.py generates the inputs, runs fx_model.py on
 * them and compares.
 * ============================================================ */

module tb_piano_fx;

parameter GAIN = 1;

reg clk   = 1'b0;
reg rst_n = 1'b0;

always #40.690 clk = ~clk;

reg                in_valid = 1'b0;
reg signed [28:0]  in_sample = 29'sd0;

reg        sb_en;
reg        rev_en;
reg [1:0]  eq;
reg        soft_mode;

wire               out_valid;
wire signed [23:0] out_sample;

piano_fx #(
    .IN_W       (29),
    .GAIN_SHIFT (GAIN)
) u_fx (
    .clk               (clk),
    .rst_n             (rst_n),
    .in_valid          (in_valid),
    .in_sample         (in_sample),
    .soundboard_enable (sb_en),
    .reverb_enable     (rev_en),
    .eq_preset         (eq),
    .limiter_soft      (soft_mode),
    .out_valid         (out_valid),
    .out_sample        (out_sample)
);

integer fin, fout, code, value, n_in, n_out, x_count, i;
integer p_sb, p_rev, p_eq, p_soft;
integer latency, max_latency;

reg [8*200-1:0] in_name;
reg [8*200-1:0] out_name;

always @(posedge clk) begin
    if (out_valid) begin
        $fdisplay(fout, "%0d", out_sample);
        n_out = n_out + 1;
        if (^out_sample === 1'bx)
            x_count = x_count + 1;
        if (latency > max_latency)
            max_latency = latency;
    end
    if (in_valid)
        latency = 0;
    else
        latency = latency + 1;
end

initial begin

    if (!$value$plusargs("in=%s",  in_name))  in_name  = "build/fx_in.txt";
    if (!$value$plusargs("out=%s", out_name)) out_name = "build/fx_out.txt";
    if (!$value$plusargs("sb=%d",   p_sb))    p_sb   = 1;
    if (!$value$plusargs("rev=%d",  p_rev))   p_rev  = 1;
    if (!$value$plusargs("eq=%d",   p_eq))    p_eq   = 0;
    if (!$value$plusargs("soft=%d", p_soft))  p_soft = 1;

    sb_en  = (p_sb != 0);
    rev_en = (p_rev != 0);
    eq     = p_eq[1:0];
    soft_mode   = (p_soft != 0);

    n_in = 0;
    n_out = 0;
    x_count = 0;
    latency = 0;
    max_latency = 0;

    fin  = $fopen(in_name, "r");
    fout = $fopen(out_name, "w");

    #(1000);
    rst_n = 1'b1;

    /* the reverb clears its delay memory first: 2048 clk */
    repeat (2100) @(posedge clk);

    code = $fscanf(fin, "%d", value);

    while (code == 1) begin

        @(negedge clk);
        in_sample = value;
        in_valid  = 1'b1;
        @(negedge clk);
        in_valid  = 1'b0;
        n_in = n_in + 1;

        /* 32 clk per sample here; the design gets 256 */
        repeat (30) @(negedge clk);

        code = $fscanf(fin, "%d", value);

    end

    repeat (40) @(posedge clk);

    $fflush(fout);
    $fclose(fout);

    $display("samples in %0d, out %0d, X %0d, latency %0d clk",
             n_in, n_out, x_count, max_latency);

    if ((n_in == n_out) && (x_count == 0) && (n_in > 0))
        $display("SIM DONE");
    else
        $display("FAIL");

    $finish;

end

endmodule
