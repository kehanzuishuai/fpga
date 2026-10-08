create_clock -name clk_50m -period 20.000 [get_ports {clk_50m}]

set_false_path -to [get_pins {pll_lock_sync_0_s0/D}]

# Existing audio PLL unchanged: 50MHz *14.5/59. Constrain the actual audio core.
create_generated_clock -name audio_clk -source [get_ports {clk_50m}] -multiply_by 29 -divide_by 118 [get_pins {u_audio_pll/u_pll/PLL_inst/CLKOUT0}]
# One video PLL provides phase-related125MHz serializer /25MHz pixel clocks.
create_generated_clock -name video_serial -source [get_ports {clk_50m}] -multiply_by 5 -divide_by 2 [get_pins {u_video_clock/video_pll/PLL_inst/CLKOUT0}]
create_generated_clock -name video_pixel -source [get_ports {clk_50m}] -divide_by 2 [get_pins {u_video_clock/video_pll/PLL_inst/CLKOUT1}]
# Snapshot RAM ownership crosses ONLY via req/ack synchronizers.
set_clock_groups -asynchronous -group {audio_clk} -group {video_pixel video_serial}
