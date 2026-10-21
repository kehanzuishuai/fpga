`default_nettype none
// Two video-only PLLs: 50 -> 27 -> (371.25, 74.25) MHz.
// Both VCOs (675 /742.5 MHz) and PFDs (25 /27 MHz) stay in DS1239 range.
module visual_video_clock(input wire clk_50m,rst_n,
 output wire pixel_clk,serial_clk,locked,serial_reset_clk);
 wire ref_clk,ref_unused,ref_lock,ref_reset,ref_ready;
 wire [5:0] ref_icp;wire [2:0] ref_lpf;
 visual_ref_PLL_MOD ref_pll(.clkin(clk_50m),.reset(ref_reset),.lock(ref_lock),
 .clkout0(ref_clk),.clkout1(ref_unused),.icpsel(ref_icp),.lpfres(ref_lpf),.lpfcap(2'b00));
 PLL_INIT #(.CLK_PERIOD(20),.MULTI_FAC(27)) init_ref(
 .CLKIN(clk_50m),.I_RST(~rst_n),.PLLLOCK(ref_lock),.O_RST(ref_reset),
 .O_LOCK(ref_ready),.ICPSEL(ref_icp),.LPFRES(ref_lpf));
 // PLL readiness is an asynchronous reset request in the receiving domain.
 // Assert immediately on loss; release only through a two-flop synchronizer.
 (* async_reg="true",syn_preserve=1,syn_keep=1 *) reg ref_ready_meta,ref_ready_sync;
 always @(posedge ref_clk or negedge ref_ready)
 if(!ref_ready)begin ref_ready_meta<=0;ref_ready_sync<=0;end
 else begin ref_ready_meta<=1;ref_ready_sync<=ref_ready_meta;end
 wire pll_lock,pll_reset,video_ready;wire [5:0] icp;wire [2:0] lpf;
 visual_PLL_MOD video_pll(.clkin(ref_clk),.reset(pll_reset),.lock(pll_lock),
 .clkout0(serial_clk),.clkout1(pixel_clk),.clkout2(serial_reset_clk),.icpsel(icp),.lpfres(lpf),.lpfcap(2'b00));
 PLL_INIT #(.CLK_PERIOD(37),.MULTI_FAC(28)) init_video(
 .CLKIN(ref_clk),.I_RST(~rst_n || !ref_ready_sync),.PLLLOCK(pll_lock),.O_RST(pll_reset),
 .O_LOCK(video_ready),.ICPSEL(icp),.LPFRES(lpf));
 wire pixel_ready_async=ref_ready && video_ready;
 (* async_reg="true",syn_preserve=1,syn_keep=1 *) reg ready_pixel_meta,ready_pixel_sync;
 always @(posedge pixel_clk or negedge pixel_ready_async)
 if(!pixel_ready_async)begin ready_pixel_meta<=0;ready_pixel_sync<=0;end
 else begin ready_pixel_meta<=1;ready_pixel_sync<=ready_pixel_meta;end
 assign locked=ready_pixel_sync;
endmodule
`default_nettype wire
