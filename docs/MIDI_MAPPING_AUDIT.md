# MIDI_MAPPING_AUDIT

工作工程：`D:\gaoyun\piano_v2_audio_fix`

工程入口：`D:\gaoyun\piano_v2_audio_fix\yinyue_fashengqi.gprj`

更新：2026-10-17T19:15:59.244408+08:00；本轮记录目录：`D:\gaoyun\piano_v2_audio_fix\audit\continuation_20261017`、`D:\gaoyun\piano_v2_audio_fix\tests\continuation_20261017`。

验证层次：源码审查及依赖哈希已留证（PATH_VERSION_AUDIT.json）；本轮仿真/数据核对=PASS；Gowin实现=PASS；真实上板=未执行，协议、实体键位及模拟音频仍待验证。

## 映射与实物证据

当前连续表：raw bit i -> MIDI60+i，i=0..15；RAW_MAP_ENABLE=0，未添加实体位序置换。KEY_MAPPING_CONFIRMED=0继续显示MAP=0。

旧keyboard_v2表按raw bit0..15为60,64,68,72,61,65,69,73,62,66,70,74,63,67,71,75。若实体序等于raw位序，第四到第五键将由72跳到61，下降11半音，能造成音区和音色突变；这是条件推论，未测实体顺序，不能称为唯一实物根因。上一轮已经去掉这个排列，本轮未再改音高表。

本轮再次读取四张原图：2000/067、2000/067、4000/071、8000/075，VOICE/PEAK均0。前两张是同一raw，照片未覆盖bit12或全16实体键；它们与旧表相符。当前同raw13/14/15应为73/74/75。原图路径和SHA256见PATH_VERSION_AUDIT.json。

|本轮项目|状态|日志 / 完整命令、cwd、时间、退出码、哈希记录|
|---|---|---|
|baseline_checker|PASS|`D:\gaoyun\piano_v2_audio_fix\tests\continuation_20261017\baseline_checker.log`；`D:\gaoyun\piano_v2_audio_fix\tests\continuation_20261017\baseline_checker.json`|
|mapping_final|PASS|`D:\gaoyun\piano_v2_audio_fix\tests\continuation_20261017\mapping_final.log`；`D:\gaoyun\piano_v2_audio_fix\tests\continuation_20261017\mapping_final.json`|
|keyboard_unit|PASS|`D:\gaoyun\piano_v2_audio_fix\tests\continuation_20261017\keyboard_unit.log`；`D:\gaoyun\piano_v2_audio_fix\tests\continuation_20261017\keyboard_unit.json`|
|keyboard_status|PASS|`D:\gaoyun\piano_v2_audio_fix\tests\continuation_20261017\keyboard_status.log`；`D:\gaoyun\piano_v2_audio_fix\tests\continuation_20261017\keyboard_status.json`|
|display|PASS|`D:\gaoyun\piano_v2_audio_fix\tests\continuation_20261017\display.log`；`D:\gaoyun\piano_v2_audio_fix\tests\continuation_20261017\display.json`|
|hardware_syntax|PASS|`D:\gaoyun\piano_v2_audio_fix\tests\continuation_20261017\hardware_syntax.log`；`D:\gaoyun\piano_v2_audio_fix\tests\continuation_20261017\hardware_syntax.json`|
|dvi_local_reset|PASS|`D:\gaoyun\piano_v2_audio_fix\tests\continuation_20261017\dvi_local_reset.log`；`D:\gaoyun\piano_v2_audio_fix\tests\continuation_20261017\dvi_local_reset.json`|
|dvi_vendor|PASS|`D:\gaoyun\piano_v2_audio_fix\tests\continuation_20261017\dvi_vendor.log`；`D:\gaoyun\piano_v2_audio_fix\tests\continuation_20261017\dvi_vendor.json`|
|mirror_policy|PASS|`D:\gaoyun\piano_v2_audio_fix\tests\continuation_20261017\mirror_policy.log`；`D:\gaoyun\piano_v2_audio_fix\tests\continuation_20261017\mirror_policy.json`|
|high_chord|PASS|`D:\gaoyun\piano_v2_audio_fix\tests\continuation_20261017\high_chord.log`；`D:\gaoyun\piano_v2_audio_fix\tests\continuation_20261017\high_chord.json`|
|stress|PASS|`D:\gaoyun\piano_v2_audio_fix\tests\continuation_20261017\stress.log`；`D:\gaoyun\piano_v2_audio_fix\tests\continuation_20261017\stress.json`|
|full_regression|PASS|`D:\gaoyun\piano_v2_audio_fix\tests\continuation_20261017\full_regression.log`；`D:\gaoyun\piano_v2_audio_fix\tests\continuation_20261017\full_regression.json`|
|loader|PASS|`D:\gaoyun\piano_v2_audio_fix\tests\continuation_20261017\loader.log`；`D:\gaoyun\piano_v2_audio_fix\tests\continuation_20261017\loader.json`|
|audio_static_audit|PASS|`D:\gaoyun\piano_v2_audio_fix\tests\continuation_20261017\audio_static_audit.log`；`D:\gaoyun\piano_v2_audio_fix\tests\continuation_20261017\audio_static_audit.json`|
|audio_source_audit|PASS|`D:\gaoyun\piano_v2_audio_fix\tests\continuation_20261017\audio_source_audit.log`；`D:\gaoyun\piano_v2_audio_fix\tests\continuation_20261017\audio_source_audit.json`|
|nyquist_audit|PASS|`D:\gaoyun\piano_v2_audio_fix\tests\continuation_20261017\nyquist_audit.log`；`D:\gaoyun\piano_v2_audio_fix\tests\continuation_20261017\nyquist_audit.json`|
|chain_audit|PASS|`D:\gaoyun\piano_v2_audio_fix\tests\continuation_20261017\chain_audit.log`；`D:\gaoyun\piano_v2_audio_fix\tests\continuation_20261017\chain_audit.json`|
|21音符各3秒 Voice/FX 逐样本|PASS|`D:\gaoyun\piano_v2_audio_fix\tests\continuation_20261017\notes\RESULTS.json`，每音每阶段命令见 `note_*.json`|
|16键逐级与PCM表|PASS|`D:\gaoyun\piano_v2_audio_fix\tests\continuation_20261017\KEY_DIAGNOSTIC_TABLE.csv`|
|Gowin综合/布局布线/FS|PASS|`D:\gaoyun\piano_v2_audio_fix\tests\continuation_20261017\gowin.log`；`D:\gaoyun\piano_v2_audio_fix\audit\continuation_20261017\BUILD.json`|
|管脚及Bank配置与基线|PASS|`D:\gaoyun\piano_v2_audio_fix\audit\continuation_20261017\PIN_AUDIT.json`|
|原PCM失败定向复现|EXPECTED_FAIL_REPRODUCED|`D:\gaoyun\piano_v2_audio_fix\tests\continuation_20261017\original_reset_repro.log`，保留FAIL，不计成DUT通过|
|实物协议、16实体键、模拟输出|NOT_RUN / 待用户上板|不自动下载或改变开发板状态|
|首次新增PCM导出边界检查|FAIL（已定位并修正后全16键重跑）|`D:\gaoyun\piano_v2_audio_fix\tests\continuation_20261017\capture_window_attempt1_check.log`；首次观察少1点，实际4095点，不缩小分析窗口。源码和数据保存在 `D:\gaoyun\piano_v2_audio_fix\audit\continuation_20261017\capture_window_attempt1`|
|Gowin尝试1|实现PASS，FIFO写计数探针未齐|`D:\gaoyun\piano_v2_audio_fix\audit\continuation_20261017\build_attempt1`，不是最终镜像|
|Gowin尝试2|FAIL，3条视频复位恢复负裕量，最差-0.469ns|`D:\gaoyun\piano_v2_audio_fix\audit\continuation_20261017\build_attempt2`，不推荐加载其FS|
|奈奎斯特审计首次解析|FAIL，解析器漏取MIDI127的default分支|`D:\gaoyun\piano_v2_audio_fix\audit\continuation_20261017\nyquist_parser_attempt1`；补全解析后全1215项通过，生产ROM未改|
|初次Icarus沙箱启动|工具异常，未运行RTL|`D:\gaoyun\piano_v2_audio_fix\audit\continuation_20261017\SANDBOX_TOOL_FAILURE.json`；原始开始时刻未留存，不伪造；正常审批后重跑通过|

