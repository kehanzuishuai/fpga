cd {D:/gaoyun/piano_v2_audio_fix/tests/display_upgrade_20261018/clock_probes/clock_propagation}
open_project {D:/gaoyun/piano_v2_audio_fix/tests/display_upgrade_20261018/clock_probes/clock_propagation/probe.gprj}
set_option -verilog_std sysv2017
set_option -top_module clock_probe
set_option -gen_text_timing_rpt 1
run all
