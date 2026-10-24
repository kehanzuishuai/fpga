# 演奏录音回传：实体琴键事件录音（用户 2026-10-24 选定"按键事件录音"）

分支：branches/v13_20261024 = loader_pipe_20261024 + 本改动；根目录未改。工具 tools/remote_recording_20261024.py（幂等，断言原文；第二次运行三个文件均 unchanged）。
改动（src/remote/control/wifi_control.sv、wifi_core.sv、remote_control.sv）：
- 录音源：实体琴键音符事件在被音源接收的那一拍（key_valid && key_ready）：按下/松开、按键位映射后的音高、力度、16 位毫秒时间。曲谱播放不录。
- 64 条事件缓存（分布式 RAM），满了置溢出标志。
- 新串口命令：0x17（开/关录音；开时清空缓存和溢出标志、毫秒计数从 0 开始）、0x07（读一条；空时返回溢出标志和当前毫秒，供 ESP32 展开时间）。同序号重发返回缓存应答，不会多取。
- 其余命令不变；旧控制器对 0x07/0x17 回"未知命令"（状态 2），新 ESP32 固件据此报"不支持"。
协议全文：C:/fpga/piano_app/BLE_PROTOCOL.md（FPGA 部分在文末）。

## 验证
1. 旧命令等效（audit/remote_recording_20261024/verification，tb_recording.sv）：旧 wifi_control 与新 wifi_control 并排，随机发送全部旧命令（含重发/冲突序号、非法长度、随机未知命令）、随机 cfg_ready/响应握手/状态输入，同时随机驱动录音输入：equivalence: 299998 clocks, 58583 packets accepted, 0 mismatches
2. 录音功能（同一测试台）：非法格式拒绝；关闭时不记录；开启后 10 个事件的顺序、按下/松开、音高、力度、时间单调；空应答的当前毫秒与经过时间相差不超过 1；同序号重发返回同一应答且只取一条；70 个事件只存 64 个并在取空后报溢出；重新开启清空缓存和溢出、毫秒从 0 开始；关闭后不再记录。结果：PASS recording: equivalence on old commands and recorder function
3. 整机（audit/loader_pipeline_20261024/system/v13_rec）：v13 全部源文件 + 键盘延迟测试台，强制打开录音，统计音源接收的实体键事件：每个场景开始测试台都会复位，最后一个场景（32 键齐按）32 个按下事件，缓存写入 32 条（总接收 36 = 1+1+2+32），无溢出。延迟与 loader 分支完全相同：32 键最后声部 8.028 ms，单键 PCM5102 首帧 4.577 / 4.664 ms。
4. 检查脚本第一次运行时包装模块没有 timescale，"#100" 变成 100 秒、录音从未打开（记录 0 条）；改为 0 时刻强制后重跑通过，旧结果保留为 v13_rec_force_never_applied.txt。

## 构建
v13 整机构建排在 Astra 与 loader 构建之后。
