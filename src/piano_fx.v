/* ============================================================
 * piano_fx.v - shared effects after the 32 voice mix
 *
 *   mix -> soundboard -> reverb -> EQ -> gain -> soft limiter -> DAC
 *
 * One instance for all voices (never one per voice).  Everything
 * runs once per 48 kHz sample, spread over a few clk cycles after
 * in_valid; every stage has its own bypass input.
 *
 * Sample format inside the chain: 32 bit signed, the 24 bit PCM
 * value shifted left by 4 (4 fraction bits, 4 bits of headroom).
 * Coefficients: 18 bit signed, Q1.16 (65536 = 1.0).
 * Products are truncated towards zero and all sums saturate.
 *
 * tools/fx_model.py is the bit-exact model (it reads the parameter
 * values from this file); sim/tb/tb_piano_fx.v compares them.
 *
 * Modules in this file:
 *   piano_fx          the chain
 *   piano_soundboard  4 resonant modes of the soundboard
 *   piano_reverb      small room, 4 delay lines (after AMY's
 *                     Stautner-Puckette reverb, shortened)
 *   piano_eq          low / high shelf, three presets
 *   piano_limiter     gain + soft limiter to 24 bit
 * ============================================================ */

module piano_fx #(
    parameter IN_W = 29,

    /* Output gain before the limiter: 0 = x1, 1 = x2, 2 = x4 */
    parameter GAIN_SHIFT = 1
)(
    input  wire                   clk,
    input  wire                   rst_n,

    /* One clk pulse per sample; in_sample is taken in this cycle */
    input  wire                   in_valid,
    input  wire signed [IN_W-1:0] in_sample,

    input  wire                   soundboard_enable,
    input  wire                   reverb_enable,

    /* 0: natural (flat), 1: warm, 2: bright */
    input  wire [1:0]             eq_preset,

    /* 1: soft limiter, 0: plain clipping at full scale */
    input  wire                   limiter_soft,

    output wire                   out_valid,
    output wire signed [23:0]     out_sample
);

/* Input: clamp to +-8 x full scale, then 4 fraction bits */

localparam signed [IN_W-1:0] IN_MAX =  (1 <<< 26) - 1;
localparam signed [IN_W-1:0] IN_MIN = -(1 <<< 26);

reg signed [31:0] x0;
reg               v0;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        x0 <= 32'sd0;
        v0 <= 1'b0;
    end
    else begin
        v0 <= in_valid;
        if (in_valid) begin
            if (in_sample > IN_MAX)
                x0 <= {IN_MAX[27:0], 4'b0000};
            else if (in_sample < IN_MIN)
                x0 <= {IN_MIN[27:0], 4'b0000};
            else
                x0 <= {in_sample[27:0], 4'b0000};
        end
    end
end

wire signed [31:0] x1;
wire               v1;

piano_soundboard u_soundboard (
    .clk        (clk),
    .rst_n      (rst_n),
    .enable     (soundboard_enable),
    .in_valid   (v0),
    .in_sample  (x0),
    .out_valid  (v1),
    .out_sample (x1)
);

wire signed [31:0] x2;
wire               v2;

piano_reverb u_reverb (
    .clk        (clk),
    .rst_n      (rst_n),
    .enable     (reverb_enable),
    .in_valid   (v1),
    .in_sample  (x1),
    .out_valid  (v2),
    .out_sample (x2)
);

wire signed [31:0] x3;
wire               v3;

piano_eq u_eq (
    .clk        (clk),
    .rst_n      (rst_n),
    .preset     (eq_preset),
    .in_valid   (v2),
    .in_sample  (x2),
    .out_valid  (v3),
    .out_sample (x3)
);

piano_limiter #(
    .GAIN_SHIFT (GAIN_SHIFT)
) u_limiter (
    .clk        (clk),
    .rst_n      (rst_n),
    .soft       (limiter_soft),
    .in_valid   (v3),
    .in_sample  (x3),
    .out_valid  (out_valid),
    .out_sample (out_sample)
);

endmodule


/* ============================================================
 * piano_soundboard
 *
 * Four second-order resonators (state variable form, which keeps
 * its accuracy at low frequencies with short coefficients):
 *
 *   hp = x/8 - lp - q*bp
 *   bp = bp + f*hp
 *   lp = lp + f*bp
 *   y  = x + sum(g * bp)
 *
 *   f = 2*sin(pi*fc/48000), q = 1/Q        (Q1.16)
 *
 * All sums saturate, so a state can never wrap around; with no
 * input the states decay to zero (tb_piano_fx checks both).
 * ============================================================ */

module piano_soundboard #(
    /* mode frequencies 110, 190, 320, 520 Hz */
    parameter signed [17:0] SB_F0 = 18'sd944,
    parameter signed [17:0] SB_F1 = 18'sd1630,
    parameter signed [17:0] SB_F2 = 18'sd2745,
    parameter signed [17:0] SB_F3 = 18'sd4459,

    /* 1/Q for Q = 10, 12, 14, 10 */
    parameter signed [17:0] SB_Q0 = 18'sd6554,
    parameter signed [17:0] SB_Q1 = 18'sd5461,
    parameter signed [17:0] SB_Q2 = 18'sd4681,
    parameter signed [17:0] SB_Q3 = 18'sd6554,

    /* how much of each mode is added to the dry signal */
    parameter signed [17:0] SB_G0 = 18'sd26214,
    parameter signed [17:0] SB_G1 = 18'sd19661,
    parameter signed [17:0] SB_G2 = 18'sd16384,
    parameter signed [17:0] SB_G3 = 18'sd9830
)(
    input  wire               clk,
    input  wire               rst_n,
    input  wire               enable,
    input  wire               in_valid,
    input  wire signed [31:0] in_sample,
    output reg                out_valid,
    output reg signed [31:0]  out_sample
);

function signed [31:0] sat32;
    input signed [39:0] v;
    begin
        if (v > 40'sd2147483647)
            sat32 = 32'sh7FFFFFFF;
        else if (v < -40'sd2147483648)
            sat32 = 32'sh80000000;
        else
            sat32 = v[31:0];
    end
endfunction

function signed [35:0] sat36;
    input signed [39:0] v;
    begin
        if (v > 40'sd34359738367)
            sat36 = 36'sh7FFFFFFFF;
        else if (v < -40'sd34359738368)
            sat36 = 36'sh800000000;
        else
            sat36 = v[35:0];
    end
endfunction

function signed [39:0] ext;
    input signed [35:0] v;
    begin
        ext = {{4{v[35]}}, v};
    end
endfunction

/*
 * (a * c) / 65536, c in Q1.16, truncated towards zero: rounding can
 * only remove energy from a feedback loop (no limit cycles).
 */
function signed [39:0] mulq;
    input signed [35:0] a;
    input signed [17:0] c;
    reg   signed [53:0] p;
    reg   [53:0]        m;
    begin
        p = a * c;
        m = p[53] ? (~p + 54'd1) : p;
        m = m >> 16;
        mulq = p[53] ? -$signed(m[39:0]) : $signed(m[39:0]);
    end
endfunction

/* v / 16 truncated towards zero */
function signed [39:0] div16;
    input signed [39:0] v;
    reg   [39:0]        m;
    begin
        m = v[39] ? (~v + 40'd1) : v;
        m = m >> 4;
        div16 = v[39] ? -$signed(m) : $signed(m);
    end
endfunction

/*
 * The resonator states are 36 bit: the chain format with 4 more
 * fraction bits.  With 32 bit states the smallest step of a low
 * mode (f = 0.014) is 70 LSB, and a state that stops inside that
 * band leaves a constant offset of 2 LSB at the output.
 */
reg signed [31:0] x_r;
reg [2:0]         ph;
reg               busy;

wire signed [35:0] xs;

/* x * 16 (4 more fraction bits) / 8 (headroom for the resonance) */
assign xs = {{3{x_r[31]}}, x_r, 1'b0};

reg signed [35:0] hp0, hp1, hp2, hp3;
reg signed [35:0] bp0, bp1, bp2, bp3;
reg signed [35:0] lp0, lp1, lp2, lp3;
reg signed [35:0] w0,  w1,  w2,  w3;

wire signed [39:0] wet_sum;

assign wet_sum = ext(w0) + ext(w1) + ext(w2) + ext(w3);

always @(posedge clk or negedge rst_n) begin

    if (!rst_n) begin

        x_r <= 32'sd0;
        ph  <= 3'd0;
        busy <= 1'b0;
        out_valid  <= 1'b0;
        out_sample <= 32'sd0;

        hp0 <= 36'sd0; hp1 <= 36'sd0; hp2 <= 36'sd0; hp3 <= 36'sd0;
        bp0 <= 36'sd0; bp1 <= 36'sd0; bp2 <= 36'sd0; bp3 <= 36'sd0;
        lp0 <= 36'sd0; lp1 <= 36'sd0; lp2 <= 36'sd0; lp3 <= 36'sd0;
        w0  <= 36'sd0; w1  <= 36'sd0; w2  <= 36'sd0; w3  <= 36'sd0;

    end

    else begin

        out_valid <= 1'b0;

        if (in_valid) begin
            x_r  <= in_sample;
            ph   <= 3'd0;
            busy <= 1'b1;
        end

        else if (busy) begin

            ph <= ph + 1'b1;

            case (ph)

                3'd0: begin
                    hp0 <= sat36(ext(xs) - ext(lp0) - mulq(bp0, SB_Q0));
                    hp1 <= sat36(ext(xs) - ext(lp1) - mulq(bp1, SB_Q1));
                    hp2 <= sat36(ext(xs) - ext(lp2) - mulq(bp2, SB_Q2));
                    hp3 <= sat36(ext(xs) - ext(lp3) - mulq(bp3, SB_Q3));
                end

                3'd1: begin
                    bp0 <= sat36(ext(bp0) + mulq(hp0, SB_F0));
                    bp1 <= sat36(ext(bp1) + mulq(hp1, SB_F1));
                    bp2 <= sat36(ext(bp2) + mulq(hp2, SB_F2));
                    bp3 <= sat36(ext(bp3) + mulq(hp3, SB_F3));
                end

                3'd2: begin
                    lp0 <= sat36(ext(lp0) + mulq(bp0, SB_F0));
                    lp1 <= sat36(ext(lp1) + mulq(bp1, SB_F1));
                    lp2 <= sat36(ext(lp2) + mulq(bp2, SB_F2));
                    lp3 <= sat36(ext(lp3) + mulq(bp3, SB_F3));
                    w0  <= sat36(mulq(bp0, SB_G0));
                    w1  <= sat36(mulq(bp1, SB_G1));
                    w2  <= sat36(mulq(bp2, SB_G2));
                    w3  <= sat36(mulq(bp3, SB_G3));
                end

                3'd3: begin
                    if (enable)
                        out_sample <= sat32($signed({{8{x_r[31]}}, x_r}) + div16(wet_sum));
                    else
                        out_sample <= x_r;
                    out_valid <= 1'b1;
                    busy      <= 1'b0;
                end

                default: busy <= 1'b0;

            endcase

        end

    end

end

endmodule


/* ============================================================
 * piano_reverb
 *
 * The reverberator AMY uses (Stautner-Puckette: four delay lines,
 * each low-pass filtered, mixed by a +1/-1 matrix), reduced for
 * the FPGA: shorter lines (28..42 ms instead of 59..86 ms, a small
 * room), no early-reflection lines, mono.  Memory: 4 x 2048 x 18
 * bit = 8 BSRAM instead of about 25 for the original sizes.
 *
 *   d   = line output
 *   s  += LPCOEF * (d - s)                 low-pass state
 *   d'  = LIVE_HALF * (s + LPGAIN * (d - s))
 *   d1' += x/16,  d2' += x/16
 *   y   = x + LEVEL * (d1' + d2')
 *   line inputs: d1'+d2'+d3'+d4', d1'-d2'+d3'-d4',
 *                d1'+d2'-d3'-d4', d1'-d2'-d3'+d4'
 *
 * LIVE_HALF is half the loop gain (the matrix has a gain of 2), so
 * LIVE_HALF < 32768 (loop gain < 1) is required for stability.
 *
 * After reset the delay memory is cleared (2048 clk); until then
 * the output is the dry signal.
 * ============================================================ */

module piano_reverb #(
    parameter [10:0] RV_LEN1 = 11'd1361,
    parameter [10:0] RV_LEN2 = 11'd1613,
    parameter [10:0] RV_LEN3 = 11'd1789,
    parameter [10:0] RV_LEN4 = 11'd2039,

    /* low-pass corner about 3 kHz: 2*pi*3000/48000 */
    parameter signed [17:0] RV_LPCOEF    = 18'sd25736,

    /* 1 - damping (0.5) */
    parameter signed [17:0] RV_LPGAIN    = 18'sd32768,

    /* loop gain 0.80 -> about 1 s decay; value is gain/2 */
    parameter signed [17:0] RV_LIVE_HALF = 18'sd26214,

    /* wet level */
    parameter signed [17:0] RV_LEVEL     = 18'sd29491
)(
    input  wire               clk,
    input  wire               rst_n,
    input  wire               enable,
    input  wire               in_valid,
    input  wire signed [31:0] in_sample,
    output reg                out_valid,
    output reg signed [31:0]  out_sample
);

function signed [31:0] sat32;
    input signed [35:0] v;
    begin
        if (v > 36'sd2147483647)
            sat32 = 32'sh7FFFFFFF;
        else if (v < -36'sd2147483648)
            sat32 = 32'sh80000000;
        else
            sat32 = v[31:0];
    end
endfunction

/*
 * (a * c) / 65536, c in Q1.16.  The result is truncated towards
 * zero, never away from it: rounding can then only remove energy
 * from a feedback loop, and every state dies away to exactly zero
 * when the input is silent (no limit cycles).
 */
function signed [35:0] mulq;
    input signed [31:0] a;
    input signed [17:0] c;
    reg   signed [49:0] p;
    reg   [49:0]        m;
    begin
        p = a * c;
        m = p[49] ? (~p + 50'd1) : p;
        m = m >> 16;
        mulq = p[49] ? -$signed(m[35:0]) : $signed(m[35:0]);
    end
endfunction

/*
 * Delay memory word = sample / 1024 (18 bit), saturating.
 * The division truncates towards zero: the stored value is never
 * larger in magnitude than the exact one, so the rounding can not
 * feed the loop and the tail dies away to exactly zero.
 */
function signed [17:0] to_mem;
    input signed [35:0] v;
    reg   [35:0]        a;
    reg   [35:0]        t;
    begin
        a = v[35] ? (~v + 36'd1) : v;
        t = a >> 10;
        if (t > 36'd131071)
            t = 36'd131071;
        to_mem = v[35] ? -$signed(t[17:0]) : $signed(t[17:0]);
    end
endfunction

function signed [35:0] ext;
    input signed [31:0] v;
    begin
        ext = {{4{v[31]}}, v};
    end
endfunction

reg [10:0] wp;
reg [11:0] clr_cnt;
wire       clearing;

assign clearing = !clr_cnt[11];

reg         ram_we;
reg  [10:0] ram_waddr;
reg  signed [17:0] ram_wd1, ram_wd2, ram_wd3, ram_wd4;
wire signed [17:0] ram_q1,  ram_q2,  ram_q3,  ram_q4;

piano_delay_ram u_ram1 (.clk(clk), .we(ram_we), .waddr(ram_waddr), .wdata(ram_wd1), .raddr(wp - RV_LEN1), .rdata(ram_q1));
piano_delay_ram u_ram2 (.clk(clk), .we(ram_we), .waddr(ram_waddr), .wdata(ram_wd2), .raddr(wp - RV_LEN2), .rdata(ram_q2));
piano_delay_ram u_ram3 (.clk(clk), .we(ram_we), .waddr(ram_waddr), .wdata(ram_wd3), .raddr(wp - RV_LEN3), .rdata(ram_q3));
piano_delay_ram u_ram4 (.clk(clk), .we(ram_we), .waddr(ram_waddr), .wdata(ram_wd4), .raddr(wp - RV_LEN4), .rdata(ram_q4));

reg signed [31:0] x_r;
reg [2:0]         ph;
reg               busy;

reg signed [31:0] d1, d2, d3, d4;
reg signed [31:0] s1, s2, s3, s4;
reg signed [31:0] u1, u2, u3, u4;
reg signed [31:0] e1, e2, e3, e4;
reg signed [31:0] wet;

wire signed [31:0] xin;

assign xin = x_r >>> 4;

wire signed [35:0] m1, m2, m3, m4;

assign m1 = ext(e1) + ext(e2) + ext(e3) + ext(e4);
assign m2 = ext(e1) - ext(e2) + ext(e3) - ext(e4);
assign m3 = ext(e1) + ext(e2) - ext(e3) - ext(e4);
assign m4 = ext(e1) - ext(e2) - ext(e3) + ext(e4);

always @(posedge clk or negedge rst_n) begin

    if (!rst_n) begin

        wp      <= 11'd0;
        clr_cnt <= 12'd0;
        ram_we  <= 1'b0;
        ram_waddr <= 11'd0;
        ram_wd1 <= 18'sd0; ram_wd2 <= 18'sd0; ram_wd3 <= 18'sd0; ram_wd4 <= 18'sd0;

        x_r  <= 32'sd0;
        ph   <= 3'd0;
        busy <= 1'b0;
        out_valid  <= 1'b0;
        out_sample <= 32'sd0;

        d1 <= 32'sd0; d2 <= 32'sd0; d3 <= 32'sd0; d4 <= 32'sd0;
        s1 <= 32'sd0; s2 <= 32'sd0; s3 <= 32'sd0; s4 <= 32'sd0;
        u1 <= 32'sd0; u2 <= 32'sd0; u3 <= 32'sd0; u4 <= 32'sd0;
        e1 <= 32'sd0; e2 <= 32'sd0; e3 <= 32'sd0; e4 <= 32'sd0;
        wet <= 32'sd0;

    end

    else begin

        out_valid <= 1'b0;
        ram_we    <= 1'b0;

        /* clear the delay memory after reset */
        if (clearing) begin
            ram_we    <= 1'b1;
            ram_waddr <= clr_cnt[10:0];
            ram_wd1   <= 18'sd0;
            ram_wd2   <= 18'sd0;
            ram_wd3   <= 18'sd0;
            ram_wd4   <= 18'sd0;
            clr_cnt   <= clr_cnt + 1'b1;
        end

        if (in_valid) begin
            x_r  <= in_sample;
            ph   <= 3'd0;
            busy <= 1'b1;
        end

        else if (busy) begin

            ph <= ph + 1'b1;

            case (ph)

                /*
                 * Line outputs (the read address was stable).
                 * While the memory is still being cleared its
                 * contents are not used.
                 */
                3'd0: begin
                    if (clearing) begin
                        d1 <= 32'sd0;
                        d2 <= 32'sd0;
                        d3 <= 32'sd0;
                        d4 <= 32'sd0;
                    end
                    else begin
                        d1 <= {{4{ram_q1[17]}}, ram_q1, 10'd0};
                        d2 <= {{4{ram_q2[17]}}, ram_q2, 10'd0};
                        d3 <= {{4{ram_q3[17]}}, ram_q3, 10'd0};
                        d4 <= {{4{ram_q4[17]}}, ram_q4, 10'd0};
                    end
                end

                3'd1: begin
                    s1 <= sat32(ext(s1) + mulq(sat32(ext(d1) - ext(s1)), RV_LPCOEF));
                    s2 <= sat32(ext(s2) + mulq(sat32(ext(d2) - ext(s2)), RV_LPCOEF));
                    s3 <= sat32(ext(s3) + mulq(sat32(ext(d3) - ext(s3)), RV_LPCOEF));
                    s4 <= sat32(ext(s4) + mulq(sat32(ext(d4) - ext(s4)), RV_LPCOEF));
                end

                3'd2: begin
                    u1 <= sat32(ext(s1) + mulq(sat32(ext(d1) - ext(s1)), RV_LPGAIN));
                    u2 <= sat32(ext(s2) + mulq(sat32(ext(d2) - ext(s2)), RV_LPGAIN));
                    u3 <= sat32(ext(s3) + mulq(sat32(ext(d3) - ext(s3)), RV_LPGAIN));
                    u4 <= sat32(ext(s4) + mulq(sat32(ext(d4) - ext(s4)), RV_LPGAIN));
                end

                3'd3: begin
                    e1 <= sat32(mulq(u1, RV_LIVE_HALF) + ext(xin));
                    e2 <= sat32(mulq(u2, RV_LIVE_HALF) + ext(xin));
                    e3 <= sat32(mulq(u3, RV_LIVE_HALF));
                    e4 <= sat32(mulq(u4, RV_LIVE_HALF));
                end

                3'd4: begin
                    wet <= sat32(ext(e1) + ext(e2));
                    if (!clearing) begin
                        ram_we    <= 1'b1;
                        ram_waddr <= wp;
                        ram_wd1   <= to_mem(m1);
                        ram_wd2   <= to_mem(m2);
                        ram_wd3   <= to_mem(m3);
                        ram_wd4   <= to_mem(m4);
                    end
                end

                3'd5: begin
                    if (enable && !clearing)
                        out_sample <= sat32(ext(x_r) + mulq(wet, RV_LEVEL));
                    else
                        out_sample <= x_r;
                    out_valid <= 1'b1;
                    busy      <= 1'b0;
                    if (!clearing)
                        wp <= wp + 1'b1;
                end

                default: busy <= 1'b0;

            endcase

        end

    end

end

endmodule


/* 2048 x 18 delay memory, one BSRAM pair per line */

module piano_delay_ram (
    input  wire               clk,
    input  wire               we,
    input  wire [10:0]        waddr,
    input  wire signed [17:0] wdata,
    input  wire [10:0]        raddr,
    output reg signed [17:0]  rdata
);

reg [17:0] mem [0:2047];

always @(posedge clk) begin
    if (we)
        mem[waddr] <= wdata;
end

always @(posedge clk) begin
    rdata <= mem[raddr];
end

endmodule


/* ============================================================
 * piano_eq
 *
 *   lo += KL * (x - lo)          one-pole low-pass, about 200 Hz
 *   hi += KH * (x - hi)          one-pole low-pass, about 3 kHz
 *   y   = x + GL * lo + GH * (x - hi)
 *
 * preset 0  natural   GL = 0      GH = 0       (y = x exactly)
 * preset 1  warm      GL = +0.26  GH = -0.30   (+2 dB below 100 Hz, -2 dB above 8 kHz)
 * preset 2  bright    GL = 0      GH = +0.50   (+2.8 dB above 8 kHz)
 * ============================================================ */

module piano_eq #(
    parameter signed [17:0] EQ_KL = 18'sd1716,
    parameter signed [17:0] EQ_KH = 18'sd25736,

    parameter signed [17:0] EQ_WARM_GL   =  18'sd17039,
    parameter signed [17:0] EQ_WARM_GH   = -18'sd19661,
    parameter signed [17:0] EQ_BRIGHT_GL =  18'sd0,
    parameter signed [17:0] EQ_BRIGHT_GH =  18'sd32768
)(
    input  wire               clk,
    input  wire               rst_n,
    input  wire [1:0]         preset,
    input  wire               in_valid,
    input  wire signed [31:0] in_sample,
    output reg                out_valid,
    output reg signed [31:0]  out_sample
);

function signed [31:0] sat32;
    input signed [39:0] v;
    begin
        if (v > 40'sd2147483647)
            sat32 = 32'sh7FFFFFFF;
        else if (v < -40'sd2147483648)
            sat32 = 32'sh80000000;
        else
            sat32 = v[31:0];
    end
endfunction

function signed [35:0] sat36;
    input signed [39:0] v;
    begin
        if (v > 40'sd34359738367)
            sat36 = 36'sh7FFFFFFFF;
        else if (v < -40'sd34359738368)
            sat36 = 36'sh800000000;
        else
            sat36 = v[35:0];
    end
endfunction

function signed [39:0] ext;
    input signed [35:0] v;
    begin
        ext = {{4{v[35]}}, v};
    end
endfunction

/*
 * (a * c) / 65536, c in Q1.16, truncated towards zero: rounding can
 * only remove energy from a feedback loop (no limit cycles).
 */
function signed [39:0] mulq;
    input signed [35:0] a;
    input signed [17:0] c;
    reg   signed [53:0] p;
    reg   [53:0]        m;
    begin
        p = a * c;
        m = p[53] ? (~p + 54'd1) : p;
        m = m >> 16;
        mulq = p[53] ? -$signed(m[39:0]) : $signed(m[39:0]);
    end
endfunction

/* v / 16 truncated towards zero */
function signed [39:0] div16;
    input signed [39:0] v;
    reg   [39:0]        m;
    begin
        m = v[39] ? (~v + 40'd1) : v;
        m = m >> 4;
        div16 = v[39] ? -$signed(m) : $signed(m);
    end
endfunction

reg signed [17:0] gl;
reg signed [17:0] gh;

always @(*) begin
    case (preset)
        2'd1:    begin gl = EQ_WARM_GL;   gh = EQ_WARM_GH;   end
        2'd2:    begin gl = EQ_BRIGHT_GL; gh = EQ_BRIGHT_GH; end
        default: begin gl = 18'sd0;       gh = 18'sd0;       end
    endcase
end

/* filter states: chain format with 4 more fraction bits */
reg signed [31:0] x_r;
reg signed [35:0] lo;
reg signed [35:0] hi;
reg               ph;
reg               busy;

wire signed [35:0] xw;

assign xw = {x_r, 4'b0000};

always @(posedge clk or negedge rst_n) begin

    if (!rst_n) begin
        x_r <= 32'sd0;
        lo  <= 36'sd0;
        hi  <= 36'sd0;
        ph  <= 1'b0;
        busy <= 1'b0;
        out_valid  <= 1'b0;
        out_sample <= 32'sd0;
    end

    else begin

        out_valid <= 1'b0;

        if (in_valid) begin
            x_r  <= in_sample;
            ph   <= 1'b0;
            busy <= 1'b1;
        end

        else if (busy) begin

            ph <= 1'b1;

            if (!ph) begin
                lo <= sat36(ext(lo) + mulq(sat36(ext(xw) - ext(lo)), EQ_KL));
                hi <= sat36(ext(hi) + mulq(sat36(ext(xw) - ext(hi)), EQ_KH));
            end
            else begin
                out_sample <= sat32(
                    $signed({{8{x_r[31]}}, x_r}) +
                    div16(mulq(lo, gl) + mulq(sat36(ext(xw) - ext(hi)), gh))
                );
                out_valid  <= 1'b1;
                busy       <= 1'b0;
            end

        end

    end

end

endmodule


/* ============================================================
 * piano_limiter
 *
 * Gain (shift), then a soft limiter and the conversion to 24 bit.
 * a = |x| / full scale:
 *
 *   a <= 0.50        y = a                     untouched
 *   0.50 .. 0.75     slope 3/4   -> 0.6875
 *   0.75 .. 1.00     slope 1/2   -> 0.8125
 *   1.00 .. 2.00     slope 1/8   -> 0.9375
 *   2.00 .. 4.00     slope 1/32  -> 1.0
 *   above            full scale
 *
 * A single note stays in the first segment; only chords reach the
 * curved part.  soft = 0 gives the plain clipping of saturator.v.
 * ============================================================ */

module piano_limiter #(
    parameter GAIN_SHIFT = 1
)(
    input  wire               clk,
    input  wire               rst_n,
    input  wire               soft,
    input  wire               in_valid,
    input  wire signed [31:0] in_sample,
    output reg                out_valid,
    output reg signed [23:0]  out_sample
);

/* full scale of the 24 bit output, with the 4 fraction bits */
localparam [35:0] FS   = 36'd134217728;      /* 2^27 */
localparam [35:0] FS_H = 36'd67108864;       /* 0.50 */
localparam [35:0] FS_Q = 36'd100663296;      /* 0.75 */

wire signed [35:0] v;
wire               neg;
wire [35:0]        a;
reg  [35:0]        y;
wire [23:0]        mag;

assign v   = $signed({{4{in_sample[31]}}, in_sample}) <<< GAIN_SHIFT;
assign neg = v[35];
assign a   = neg ? (~v + 36'd1) : v;

always @(*) begin

    if (!soft) begin
        y = (a >= FS) ? (FS - 36'd16) : a;
    end

    else if (a <= FS_H) begin
        y = a;
    end

    else if (a <= FS_Q) begin
        y = FS_H + ((a - FS_H) >> 1) + ((a - FS_H) >> 2);
    end

    else if (a <= FS) begin
        y = 36'd92274688 + ((a - FS_Q) >> 1);
    end

    else if (a <= (FS << 1)) begin
        y = 36'd109051904 + ((a - FS) >> 3);
    end

    else if (a <= (FS << 2)) begin
        y = 36'd125829120 + ((a - (FS << 1)) >> 5);
    end

    else begin
        y = FS - 36'd16;
    end

end

assign mag = (y >= FS) ? 24'h7FFFFF : y[27:4];

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out_valid  <= 1'b0;
        out_sample <= 24'sd0;
    end
    else begin
        out_valid <= in_valid;
        if (in_valid)
            out_sample <= neg ? -$signed({1'b0, mag[22:0]}) : $signed({1'b0, mag[22:0]});
    end
end

endmodule
