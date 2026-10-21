`default_nettype none
// Device-specific board boundary only. Video lock must not reset audio.
module visual_video_clock(input wire clk_50m,rst_n,
 output wire pixel_clk,serial_clk,locked);
 wire pll_lock,pll_reset;wire [5:0] icp;wire [2:0] lpf;
 visual_PLL_MOD video_pll(.clkin(clk_50m),.reset(pll_reset),.lock(pll_lock),
 .clkout0(serial_clk),.clkout1(pixel_clk),.icpsel(icp),.lpfres(lpf),.lpfcap(2'b00));
 PLL_INIT #(.CLK_PERIOD(20),.MULTI_FAC(40)) init_video(
 .CLKIN(clk_50m),.I_RST(~rst_n),.PLLLOCK(pll_lock),.O_RST(pll_reset),
 .O_LOCK(locked),.ICPSEL(icp),.LPFRES(lpf));
endmodule
`default_nettype wire
