# Reuse the verified current synthesis netlist; never programs hardware.
set root [file normalize [file join [file dirname [info script]] ..]]
cd $root
open_project [file join $root yinyue_fashengqi.gprj]
set_option -top_module tang_mega_138k_pro_top
set_option -timing_driven 1
set_option -correct_hold_violation 1
set_option -place_option 3
set_option -route_option 0
set_option -cst_warn_to_error 1
set_option -gen_text_timing_rpt 1
run pnr
exit
