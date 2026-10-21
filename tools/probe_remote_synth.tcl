set root [file normalize [file join [file dirname [info script]] ..]]
cd $root
open_project [file join $root yinyue_fashengqi.gprj]
set_option -verilog_std sysv2017
set_option -top_module tang_mega_138k_pro_top
set_option -allow_duplicate_modules 0
run syn
