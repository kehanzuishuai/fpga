`timescale 1ns/1ps

/* ============================================================
 * Simulation stand-in for the Gowin audio PLL IP (audio_PLL).
 * Same ports.  12.288 MHz out, lock after 2 us.
 * The real PLL (src/gowin_pll) is not simulated.
 * ============================================================ */

module audio_PLL (
    input  wire clkin,
    input  wire init_clk,
    output reg  clkout0,
    output reg  lock,
    input  wire reset
);

initial begin
    clkout0 = 1'b0;
    lock    = 1'b0;
end

always #40.690 clkout0 = ~clkout0;

always @(posedge clkin or posedge reset) begin
    if (reset)
        lock <= 1'b0;
    else
        lock <= #2000 1'b1;
end

endmodule
