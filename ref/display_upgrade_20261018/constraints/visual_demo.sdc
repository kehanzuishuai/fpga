create_clock -name clk_50m -period 20.000 [get_ports {clk_50m}]
# Exact ratios; verify node names and timing reports after Gowin synthesis.
create_generated_clock -name video_ref -source [get_ports {clk_50m}] -multiply_by 27 -divide_by 50 [get_pins {display/u_video_clock/ref_pll/PLL_inst/CLKOUT0}]
create_generated_clock -name video_serial -source [get_pins {display/u_video_clock/ref_pll/PLL_inst/CLKOUT0}] -multiply_by 55 -divide_by 4 [get_pins {display/u_video_clock/video_pll/PLL_inst/CLKOUT0}]
create_generated_clock -name video_pixel -source [get_pins {display/u_video_clock/ref_pll/PLL_inst/CLKOUT0}] -multiply_by 11 -divide_by 4 [get_pins {display/u_video_clock/video_pll/PLL_inst/CLKOUT1}]
# Analyze/source clock domain is clk_50m in THIS demo; related video clocks kept together.
set_clock_groups -asynchronous -group {clk_50m} -group {video_ref video_pixel video_serial}
