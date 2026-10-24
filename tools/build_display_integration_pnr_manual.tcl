# Run manually after the 2026-10-21 synthesis passes. Never programs hardware.
set root [file normalize [file join [file dirname [info script]] ..]]
cd $root
open_project [file join $root yinyue_fashengqi.gprj]
set_option -top_module tang_mega_138k_pro_top
# The old conversion added 35 RAM blocks (261 synthesis -> 296 PnR).
# Preserve wide RAMs to leave room for the exact background and font ROMs.
set_option -convert_sdp32_36_to_sdp16_18 0
set_option -timing_driven 1
set_option -correct_hold_violation 1
set_option -place_option 3
set_option -route_option 0
set_option -cst_warn_to_error 1
set_option -gen_text_timing_rpt 1
run pnr
exit
