# KEYBOARD_EVENT_AUDIT

工作工程：`D:\gaoyun\piano_v2_audio_fix`

工程入口：`D:\gaoyun\piano_v2_audio_fix\yinyue_fashengqi.gprj`

更新：2026-10-17T19:15:59.244408+08:00；本轮记录目录：`D:\gaoyun\piano_v2_audio_fix\audit\continuation_20261017`、`D:\gaoyun\piano_v2_audio_fix\tests\continuation_20261017`。

验证层次：源码审查及依赖哈希已留证（PATH_VERSION_AUDIT.json）；本轮仿真/数据核对=PASS；Gowin实现=PASS；真实上板=未执行，协议、实体键位及模拟音频仍待验证。

## 源码审查

- Reader使用5位bit_index，0..15共16次；每一完整帧在bit15完成时发布。高4位没有12键边界。CONFIRM=1逐位要求两帧一致；默认SAMPLE_LOW=0，在SCL高相末端采样同步后的SDO。
- 默认STRICT_IDLE=1拒绝SDO持续有效电平。MIRROR_GUARD=1在未见上下字节不同的确认帧时屏蔽上字节；F000单独按下可证明16位并解除保护。首次FFFF或0101等对称和弦可能被屏蔽上字节；这是模型已复现的保守策略限制，不是照片所示单个高位被接纳后无声的证实根因。未未经实物确认关闭保护或切换I²C。
- mapper只在frame_valid && !frame_error && !mapping_error时更新key_state和accepted_raw；输出valid由非阻塞赋值产生，下游在下一拍读取稳定的整帧；16位保持完整。
- Bridge的reported_state表示已排入其输出寄存器的状态。真正接受点是event_valid && event_ready；背压时负载保持，Off优先，再发On。短于两帧确认窗口的触摸可能不被接纳，不承诺捕获每个模拟短脉冲。
- FIFO只有in_valid&&in_ready才写，out_valid&&core_ready才读；满时停写，保持事件次序，没有越过满状态静默覆盖。满且同拍读时会留一拍写入空隙，属于吞吐限制。
- core_ready=!ld_busy，Loader忙时On和Off均不出队；Allocator选择空闲、释放中、再抢占Voice。Loader锁存MIDI、velocity及基础相位增量，写400字/音后对所选Voice发ld_done。
- Voice在V_LOAD接收ld_done后进入V_PLAY；active包含LOAD/FADE/PLAY，故active非零不等于已经输出PCM。stop可以在加载/播放期间设置释放；新start优先。32条独立Voice RAM和调度均保留。
- MIDI60..75在有效区间；Loader将超出24..104的音色索引钳位，频率表仍按实际MIDI。MIDI参数不依赖实体键号。原旧表也是16个唯一有效音，不能单凭其排列解释四键全部零Voice。

## 仿真覆盖层级

直接注入事件：原钢琴Voice/Loader、系统、抢占/重触发、短按/加载中释放、长音与FX回归。mapper输入注入：keyboard_events，覆盖16键、和弦2/3/5/8/16、独立松键、快速切换、无效帧、FIFO满背压及复位。模拟串行SDO：逐键mapping、默认stress、high_chord和mirror_policy，真实Reader/mapper/FIFO/32Voice/FX连接。仿真BFM假定TTP229-BSF式低有效16键串行；不等于BIT-TREE实物协议已确认。

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

