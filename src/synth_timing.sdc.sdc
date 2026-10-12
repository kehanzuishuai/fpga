create_clock -name clk_50m -period 20.000 [get_ports {clk_50m}]

set_false_path -to [get_pins {pll_lock_sync_0_s0/D}]