# 当前状态（2026-10-19）

主工程 `D:\gaoyun\piano_v2_audio_fix\yinyue_fashengqi.gprj` 已完成双16键输入扩展及32键复音功能仿真、综合、布局布线与五类时序检查。

默认原模块MIDI60～75，新增模块76～91。屏幕继续只绘制原模块16键，音频分析包含两模块总输出。

本轮仿真、Gowin综合、布局布线及五类时序全部通过。未自动烧录，上板接线/协议/真实32键演奏与音质仍待确认。

- FS：`impl/pnr/ao_0.fs`，同哈希归档 `tests/keyboard32_20261019/final_build/ao_0.fs`。
- SHA256：`18427350a26750067ee9cb54e1ea1e6ceff67adb1a347475a0f79c1b88ae6bfa`。
- 实际综合网表包含32个钢琴Voice；68个有效工程输入；没有把测试平台参与综合。
- 全部378行管脚表核对：仅原先空闲的B19、A17两行变为新增键盘接口；其余管脚字段全部不变。
- 71个受保护源文件哈希不变，包含钢琴/FX/FFT/HDMI/双DAC及完整SDC。

| 时序检查 | 最差裕量/ns |
|---|---:|
|setup|0.253|
|hold|0.005|
|recovery|0.848|
|removal|0.293|
|min_pulse_width|3.207|

Setup/Hold违规端点均为0；Recovery、Removal和最小脉宽的最差裕量均非负。

工具仍报告既有TA1132（GAO的tck_pad_i未显式建钟）及PR1014（clk_50m_d使用常规布线）警告，完整保留在日志中。本轮没有通过移除约束或放宽SDC消除警告，不能把“时序通过”理解为“没有任何工具警告”。

| 资源 | 使用/总量 |
|---|---:|
|Logic|48881/138240|
|Register|19218/139140|
|BSRAM|291/340|
|DSP|131/298|
|PLL|3/12|

- 实际本轮综合网表Loader与ROM的GW5A原语仿真：MIDI60～91共32音、12800个参数字，数学模型核对0处差异。只强制已捕获的请求音高/基准增量，不强制插值计算信号；该局部门级检查不覆盖键盘/Allocator，完整键盘通路由SYSTEM验证。
- 两块串行键盘经过真实FIFO、Loader后，对32个实际Voice RAM端口的12800次写入逐次读回，全部成功；每一路RAM参数与该路MIDI音符的数学模型一致，0处差异。
- PASS events32: 202 convergence cases, 2893 stalled cycles, all32 unique notes, 16-deep FIFO, rapid changes, reset
- PASS serial pair: 76 cases, production timing, 32 physical bits, independent frame admission/faults/raw permutations, duplicate table rejected
- PASS keyboard events: 106 convergence/map checks; 100 stalled cycles; 16-key permutation, chords 2/3/5/8/16, release, invalid frames, full FIFO, reset, 32-bit map
- PASS preserve16: 518527 clocks, 2025 PCM samples and both DAC pins bit-exact to backed-up old RTL; 4 Note events; unconnected bank2 silent
- PASS physical32 system: 12 scenarios, 44 On/40 Off, 44 allocations, max_active32, nonzero_voice_maskffffffff; PCM5102 9458 frames/PT8211 9458 words exact; FFT4, TMDS12338132 pixels, limiter-flag frames0

首次综合因GAO引用已移除的旧 `key_reader_frame_valid` 名称而停止，未产生新实现，日志/失败门禁保存在 `gowin_attempt1.log` 和 `BUILD_attempt1.json`。移除该单个旧探针后重新完整实现；两模块的完整帧接纳脉冲由 `key_bank_frame_valid[1:0]` 捕获。时序门禁没有采用首次失败时仍在磁盘上的旧报告。初次系统仿真因缺少中途进度输出被主动终止，加入仅观测用时间输出后完整重跑，最终SYSTEM.json源哈希与当前工程一致。

UNIT及原16键对照在GAO单个XML探针移除前完成，所有RTL及GPRJ哈希与最终构建一致；独立SERIAL及完整SYSTEM在最终配置下通过。此配置差异不参与Icarus编译，最终审计逐文件检查，未忽略任何RTL差异。

[完整接线与验证说明](KEYBOARD32_20261019.md)
