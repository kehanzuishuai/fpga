set root [file normalize [file join [file dirname [info script]] ..]]
cd $root
open_project [file join $root yinyue_fashengqi.gprj]
saveto -all_options [file join $root audit continuation_20261017 GUI_ON_OPEN.tcl]
set_option -verilog_std sysv2017
set_option -top_module tang_mega_138k_pro_top
set_option -allow_duplicate_modules 0
set_option -cst_warn_to_error 1
set_option -gen_text_timing_rpt 1
saveto -all_options [file join $root audit continuation_20261017 CLI_EFFECTIVE.tcl]
puts "Option snapshots exported; no synthesis or PnR requested."
