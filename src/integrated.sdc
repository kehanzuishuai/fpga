create_clock -name clk_50m -period 20.000 [get_ports {clk_50m}]
create_generated_clock -name audio_clk -source [get_ports {clk_50m}] -multiply_by 29 -divide_by 118 [get_pins {u_audio_pll/u_pll/PLL_inst/CLKOUT0}]
create_generated_clock -name video_ref -source [get_ports {clk_50m}] -multiply_by 27 -divide_by 50 [get_pins {u_video_clock/ref_pll/PLL_inst/CLKOUT0}]
create_generated_clock -name video_serial -source [get_pins {u_video_clock/ref_pll/PLL_inst/CLKOUT0}] -multiply_by 55 -divide_by 4 [get_pins {u_video_clock/video_pll/PLL_inst/CLKOUT0}]
create_generated_clock -name video_pixel_pll -source [get_pins {u_video_clock/ref_pll/PLL_inst/CLKOUT0}] -multiply_by 11 -divide_by 4 [get_pins {u_video_clock/video_pll/PLL_inst/CLKOUT1}]
create_generated_clock -name video_pixel -source [get_pins {u_video_clock/video_pll/PLL_inst/CLKOUT1}] -divide_by 1 [get_pins {u_video_clock/pixel_buffer/CLKOUT}]
create_generated_clock -name video_serial_global -source [get_pins {u_video_clock/video_pll/PLL_inst/CLKOUT0}] -divide_by 1 [get_pins {u_video_io/serial_buffer/CLKOUT}]
create_generated_clock -name video_serial_reset -source [get_pins {u_video_clock/video_pll/PLL_inst/CLKOUT0}] -edges {2 7 12} -edge_shift {1.278451178451 1.178451178451 1.278451178451} [get_pins {u_video_clock/video_pll/PLL_inst/CLKOUT2}]
create_generated_clock -name video_serial_reset_regional -source [get_pins {u_video_clock/video_pll/PLL_inst/CLKOUT2}] -edges {1 2 3} [get_pins {u_video_io/reset_buffer/CLKOUT}]
# All audio/pixel crossings use stable bundled-data request/ack mailboxes.
# Pixel and serial clocks remain synchronous.
set_clock_groups -asynchronous -group [get_clocks {audio_clk}] -group [get_clocks {video_ref video_pixel_pll video_pixel video_serial video_serial_global video_serial_reset video_serial_reset_regional}]
# New 50MHz WAV transport <-> audio crossings are only explicit request/ack
# mailboxes and two-stage control synchronizers in u_wav. Stereo hold_pcm stays
# fixed until the destination acknowledges it. No free-running PCM bus crosses.
set_clock_groups -asynchronous -group [get_clocks {clk_50m}] -group [get_clocks {audio_clk}]
# Strengthen same-domain pixel hold margin so routing repairs short data paths.
set_clock_uncertainty 0.150 -hold -from [get_clocks {video_pixel}] -to [get_clocks {video_pixel}]
set_false_path -to [get_pins {pll_lock_sync_0_s0/D}]
# Only asynchronous reset inputs of explicit release synchronizers are exempt.
# Their inter-stage data paths and all OSER10 RESET recovery/removal stay timed.
set_false_path -to [get_pins {u_video_clock/ref_ready_meta_*/CLEAR u_video_clock/ref_ready_sync_*/CLEAR u_video_clock/ready_pixel_meta_*/CLEAR u_video_clock/ready_pixel_sync_*/CLEAR}]
set_false_path -to [get_pins {u_video_io/reset_release_*/CLEAR u_video_io/channels*.local_rst_n_*/CLEAR}]
