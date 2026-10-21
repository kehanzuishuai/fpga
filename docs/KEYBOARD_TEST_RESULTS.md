# KEYBOARD_TEST_RESULTS

工作工程：`D:\gaoyun\piano_v2_audio_fix`

工程入口：`D:\gaoyun\piano_v2_audio_fix\yinyue_fashengqi.gprj`

更新：2026-10-17T19:15:59.254686+08:00；本轮记录目录：`D:\gaoyun\piano_v2_audio_fix\audit\continuation_20261017`、`D:\gaoyun\piano_v2_audio_fix\tests\continuation_20261017`。

验证层次：源码审查及依赖哈希已留证（PATH_VERSION_AUDIT.json）；本轮仿真/数据核对=PASS；Gowin实现=PASS；真实上板=未执行，协议、实体键位及模拟音频仍待验证。

数字验证：**PASS**。实物功能验收：**PENDING**。

本轮修复测试平台跨复位半帧残留，增加真实事件链GAO诊断，对齐GUI/CLI过程选项，并针对已复现的视频串行器复位恢复负裕量增加逐通道局部复位。未修改AMY参数、ROM、Loader算法、Partial算法、Allocator调度、增益或FX算法。raw bit0..15→MIDI60..75是上一轮已存在的映射，本轮保留；实体键位与实物协议仍未确认。

最后四个实体键无声：当前协议模型下未复现，不能报告实物故障已修复。原照片只证明mapper状态和组合MIDI曾显示，不能确定Note On已被FIFO接受或声音已启动；照片中的旧表MIDI为67/71/75，不能混作当前73/74/75。

本轮记录 `D:\gaoyun\piano_v2_audio_fix\audit\continuation_20261017\VALIDATION.json` 为唯一当前汇总；`audit/audio_diagnosis`、`tests/audio_diagnosis` 内既有记录是历史基线，不能替代本轮结果。原docs已备份到 `D:\gaoyun\piano_v2_audio_fix\audit\continuation_20261017\backup\docs`。

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

|资源|历史audio_fix基线|本轮|差值|
|---|---:|---:|---:|
|Logic|43819|44061.0|242.0|
|Register|16238|16877.0|639.0|
|BSRAM|226|258.0|32.0|
|DSP|98.5|98.5|0.0|
|PLL|2|2.0|0.0|

基线时序：`{"fmax_MHz": {"clk_50m": 291.253, "audio_clk": 30.258, "video_pixel": 34.426, "tck_pad_i": 90.693}, "worst_listed_setup_ns": 10.953, "worst_listed_hold_ns": 0.141, "worst_listed_recovery_ns": 1.366, "worst_listed_removal_ns": 0.378, "worst_listed_pulse_width_slack_ns": 7.072, "zero_setup_hold_violations": true, "all_listed_timing_nonnegative": true, "video_serial_fmax": "No internal timing paths; do not invent Fmax"}`

本轮时序：`{"fmax_MHz": {"clk_50m": 239.235, "audio_clk": 33.235, "video_pixel": 33.479, "tck_pad_i": 87.296}, "worst_listed_setup_ns": 10.131, "worst_listed_hold_ns": 0.143, "worst_listed_recovery_ns": 2.716, "worst_listed_removal_ns": 0.023, "worst_listed_pulse_width_slack_ns": 7.128, "zero_setup_hold_violations": true, "all_listed_timing_nonnegative": true, "video_serial_fmax": "No internal timing paths; do not invent Fmax"}`。SDC声明的异步邮箱路径属于显式时钟分组，不能把这些跨域路径未做同步时序分析解释为物理CDC已上板验证。video_serial没有普通内部路径的Fmax数值，不虚构125MHz逻辑裕量。

## 参数、命令与范围

每组实际命令、cwd、开始/结束时间、returncode、运行时源码/约束哈希和完整日志均在同名JSON。原全回归由原sim/run_tests.py all执行，保留原长音时长和检查；组内细节由已哈希运行器和docs/test_manifest_all.txt追溯。测试元数据中的inputs_unchanged包含工具脚本与实现配置，期间新增审计脚本或GAO探针可能使其为false；本轮额外逐项核对仿真实际使用的.v/.sv及gprj是否仍与已测输入一致；CST/SDC/GAO及过程配置由最终Gowin构建的完整输入哈希另行核对。仿真不加载GAO电路，不能宣称仿真验证了GAO硬件，不能将脚本变动伪装成RTL已重测。

16键mapping在实际默认顶层模拟串行Reader输入，每键完整按/持/松，4096 PCM样本；trace包含扫描/mapper/FIFO写/分配，control表包含FIFO读/Loader/播放/active时长/串行输出/HDMI。独立音色测试velocity100、48kHz、NoteOff=96000tick、每音144000样本（3秒），输出21个音符；MIDI60..75统一0.1..0.5s频谱/RMS窗口，两条FX链，另测32Voice混合压力。Loader用实际生产case ROM跑810请求、324000字，再和独立整数插值核对；原回归还穷举所有地址验证array-ROM等价。

便携长仿真使用同接口、同延迟且逐地址验证过的array-ROM，PLL和物理串行器边界使用名义模型；真实ROM/原语另做hardware_syntax及Gowin实现。数字串行解码通过不等于板载模拟输出、PLL锁定实测或HDMI线缆眼图通过。没有安装软件。

保留历史mapping_after_run.log的FATAL，不把其中16条子检查PASS说成整体PASS。当前负向复现也是FAIL证据。沙箱内第一次Icarus编译曾以0xC0000005退出，之后经正常权限审批使用同一现有工具执行；不是RTL功能失败。未完成或失败项不会生成最终全功能PASS。

历史第三次Gowin也为FAIL：最差视频复位恢复-0.020ns，完整记录 `D:\gaoyun\piano_v2_audio_fix\audit\continuation_20261017\build_attempt3`。随后修改真实DVI边界的复位扇出，新增复位测试及3000个真实OSER10/ELVDS模型DDR边沿对照均PASS；当前第四次实现状态为 PASS。此前便携音频联合测试实际替换物理DVI边界，新边界另行核对，不冒充已上板验证。

