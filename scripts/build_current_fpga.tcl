# Run with Gowin V1.9.12 gw_sh from any working directory.
set root [file normalize [file join [file dirname [info script]] ..]]
cd $root
open_project [file join $root yinyue_fashengqi.gprj]
set_option -verilog_std sysv2017
set_option -top_module tang_mega_138k_pro_top
set_option -convert_sdp32_36_to_sdp16_18 0
set_option -timing_driven 1
set_option -correct_hold_violation 1
set_option -place_option 3
set_option -route_option 2
set_option -route_maxfan 100
set_option -clock_route_order 0
set_option -replicate_resources 0
set_option -allow_duplicate_modules 0
set_option -cst_warn_to_error 1
set_option -gen_text_timing_rpt 1
run all
exit
