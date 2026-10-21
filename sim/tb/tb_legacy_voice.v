`timescale 1ns/1ps

/* ============================================================
 * The previous piano voice (voice.v + piano_string_model.v +
 * piano_dual_wavetable.v + piano_envelope.v), unchanged, played
 * alone.  Writes one sample per line to +out= for the A/B
 * comparison, and reports the largest hammer value seen.
 *
 *   +note=60 +vel=100 +off=96000 +ticks=144000 +out=build/legacy.txt
 * ============================================================ */

module tb_legacy_voice;

reg clk   = 1'b0;
reg rst_n = 1'b0;

always #40.690 clk = ~clk;

reg [7:0] div = 8'd0;
reg       sample_tick = 1'b0;

always @(posedge clk) begin
    div         <= div + 1'b1;
    sample_tick <= (div == 8'd255);
end

integer tick = -1;

reg        start = 1'b0;
reg        stop  = 1'b0;
reg [6:0]  note_in = 7'd60;
reg [7:0]  vel_in  = 8'd100;

wire [31:0] phase_inc;

note_freq_table #(.SAMPLE_RATE(48000)) u_freq (
    .midi_note (note_in),
    .phase_inc (phase_inc)
);

wire               active;
wire               releasing;
wire [23:0]        env_level;
wire [6:0]         note;
wire [31:0]        inc_out;
wire signed [23:0] sample;

voice u_voice (
    .clk          (clk),
    .rst_n        (rst_n),
    .sample_tick  (sample_tick),
    .start        (start),
    .stop         (stop),
    .phase_inc_in (phase_inc),
    .note_in      (note_in),
    .velocity_in  (vel_in),
    .waveform_in  (2'd3),
    .morph_enable (1'b0),
    .morph_in     (10'd0),
    .active       (active),
    .releasing    (releasing),
    .env_level    (env_level),
    .note         (note),
    .phase_inc    (inc_out),
    .sample       (sample)
);

integer fd;
integer p_note, p_vel, p_off, p_ticks;
integer hammer_max = 0;
integer hammer_nonzero = 0;
integer h;

reg [8*200-1:0] out_name;

always @(posedge clk) begin
    if (sample_tick) begin
        tick = tick + 1;
        if (tick >= 0)
            $fdisplay(fd, "%0d", sample);
        h = $signed(u_voice.piano_hammer);
        if (active && (h != 0) && (h != -1))
            hammer_nonzero = hammer_nonzero + 1;
        if (h > hammer_max)  hammer_max = h;
        if (-h > hammer_max) hammer_max = -h;
    end
end

initial begin

    if (!$value$plusargs("note=%d",  p_note))  p_note  = 60;
    if (!$value$plusargs("vel=%d",   p_vel))   p_vel   = 100;
    if (!$value$plusargs("off=%d",   p_off))   p_off   = 96000;
    if (!$value$plusargs("ticks=%d", p_ticks)) p_ticks = 144000;
    if (!$value$plusargs("out=%s",   out_name)) out_name = "build/legacy.txt";

    fd = $fopen(out_name, "w");

    #(1000);
    rst_n = 1'b1;

    while (tick < 4) @(posedge clk);
    @(negedge clk);
    note_in = p_note[6:0];
    vel_in  = p_vel[7:0];
    start   = 1'b1;
    @(negedge clk);
    start   = 1'b0;

    while (tick < p_off) @(posedge clk);
    @(negedge clk);
    stop = 1'b1;
    @(negedge clk);
    stop = 1'b0;

    while (tick < p_ticks) @(posedge clk);

    $fflush(fd);
    $fclose(fd);

    $display("hammer path: largest |value| %0d, samples other than 0 / -1: %0d",
             hammer_max, hammer_nonzero);
    $display("SIM DONE");
    $finish;

end

endmodule
