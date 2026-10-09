# 混音音质与最终TMDS离线验证（2026-10-09）

状态：**PASS（本轮约定的当前板级工程离线验证）**。2026-10-09北京时间08:29:41～08:52:49完成冻结源码完整回归，进程exit0；四个suite均PASS，76个src/sim/scripts文件SHA256运行前后完全一致。未上板，不代表全工程硬件冻结。

机器报告：[audio_tmds_20261009.json](audio_tmds_20261009.json)，包含源码哈希、各场景数据、FFT峰和工具结果。原2026-10-08历史报告保留不变。

## 最终回归汇总

| 检查 | 结果 |
|---|---|
| 工具发现/迁移/错误覆盖自检 | PASS |
| 音频质量、整数黄金模型、4/8/16/32配置及FIFO | PASS |
| 显示CDC、视频/复位/读数、FFT及TMDS全链 | PASS |
| PCM5102A逐位、双DAC同时输出、当前合成核心集成 | PASS |
| 最终TMDS整屏反解码 | 四音及32音各307200像素；两幅640×480 RGB逐字节一致 |
| 实际32 Voice PCM削顶 | **0/5644=0%**，修改前8/5644=0.141743% |
| 实际32 Voice频谱 | **32/32独立峰**；2048个复数/功率bin、512根显示柱与黄金模型一致 |
| 1024/2048/4096点FFT专项 | 总计14336个复数/功率bin bit-exact；各32/32峰 |
| 32音最大DDS ROM量化误差 | 0.000005408474Hz（标称48kHz，不含实际时钟误差） |
| 32音最大FFT格点误差 | 12.020455303Hz；2048点/48kHz格点23.4375Hz，不是DDS误差 |
| I2S时钟/数据 | 测量每BCLK4个输入周期、每LRCLK256个输入周期；12.288MHz输入对应3.072MHz/48kHz；逐bit测试PASS |
| Verilator严格--Wall | gain四配置、visualizer、test_mode、PCM sender均0 warning；未屏蔽 |
| Yosys | gain、visualizer、PCM sender check均0结构问题；gain无运行时除法器 |

已人工查看本轮两幅TMDS还原PNG，确认波形、XY与真实频谱均显示。它们来自RTL仿真最终TMDS字流，不是Python替代FPGA生成FFT。可重新生成的画面/WAV位于`sim_out_visual/tmds_display.png`、`tmds_display_32.png`、`audio_scenario_0.wav`～`audio_scenario_12.wav`。

通用资源统计：增益1个`$mul`、无运行时`$div`；显示链12个memory cell、10个`$mul`，与上轮已加入完整功率读数后的结构相同（早期display-only基线11/8）。这是通用Yosys结构，不能换算成高云实际DSP/BRAM数量。本轮未改音频管线级数，也未新增传感器到DAC延迟测量；不重新声称端到端延迟验收。

## 音频专项最终数据

最终回归中的音频专项已通过：28,800个增益输出样本bit-exact（TB另检查采样前数量变化），53,888个真实核心样本零满幅端点命中；13个核心场景均通过。原始512样本混音与修改前fixture逐位一致，原8个削顶样本全部消除。

| 指标 | 数据 |
|---|---|
| 4/8/16 Voice同相等幅稳态RMS / 单音RMS | 0.999898287 |
| 32 Voice同相等幅稳态RMS / 单音RMS | 0.999355756 |
| 默认master幅度 | 29491/32768，-0.915208716dB |
| 正弦相位表与解析参考最大误差 | 0（4352个测试相位，24bit输出LSB） |
| 9216组包络/velocity缩放 | 当前定点公式bit-exact；相对直接全精度乘法最多1个24bit LSB |
| 正弦前20次谐波THD | 0.000113281%，仅数字相干测试向量 |
| 正弦全带非基波/基波RMS | 0.707141958%，包含8bit相位查表保持镜像，不能当作模拟THD |
| 440Hz单音FFT格点读数 | 441.964286Hz，窗长7168采样，格点6.696429Hz；非DDS本身误差 |
| Verilator增益检查 | 4/8/16/32配置严格--Wall，0 warning |
| Yosys增益检查 | 0结构问题，无运行时除法器 |

所有场景的峰值、相邻样本最大跳变和样本数量见最终机器报告；方波/锯齿跳变不作为异常爆音判据。以上不等于全工程lint清零或模拟输出验收。

## 本轮修改

- `src/polyphony_gain.v`：修复快速增加Voice时增益滞后造成的启动削顶。即时应用`min(current_gain,target_gain)`，下降立即记入状态、上升按64 Q15单位/采样缓慢恢复。将互易数按向下取整生成编译期常量LUT，不实例化运行时除法器。
- `src/synth_core.v`、`synth_event_frontend.v`、`synth_top.v`、板级顶层：逐级传递`MASTER_GAIN_Q15`，默认29491/32768≈0.9（-0.915dB）。单音保持接近master设定的音量，不固定除32；同时同相多音按实际Voice数量归一化。原`MASTER_ATTEN_SHIFT`仍是额外2幂衰减；`mix_gain_shift`仅为数量分档估计，不代表精确瞬时Q15增益。
- 删除未被当前工程其他模块使用的`GAIN_DOWN_STEP`参数：安全下降不再等待固定步长。保留`GAIN_UP_STEP`调节恢复，增加高位截断必须为符号扩展的仿真断言。
- `sim/tmds_stream_checker.sv`：独立逆向TMDS解码，检查RGB、控制词、通道顺序和运行差分；比较编码器采样前的像素，不能拿编码后同时刻已前进的像素比较。
- `sim/tb_visual_system.sv`：检查renderer两拍时序管线，导出最终TMDS解码还原的PPM；四音/32音整屏与原始像素逐字节比较。
- 新增`tb_mix_gain`、`tb_audio_quality`、`tb_waveform_quality`、`tb_note_fifo`、`tb_tmds_receiver`及增益修改前的512样本fixture。新增`verify_audio_quality.py`、24bit PCM/WAV工具，接入统一回归。

未修改PLL、CST、SDC、OSER10封装、两个DAC发送器、Voice独立状态、DDS、ADSR、波形表、Morph及allocator/FIFO逻辑。整个旧核心没有因此被宣称重新冻结。

## 削顶根因及修复原则

上轮真实DAC捕获PCM在索引17～24命中满幅，共8/5644=0.141743%。修改前内部512采样fixture重现同样的8个位置：Voice数量每采样增加，但旧Q15增益只下降1024/采样，数个Voice已累加时仍使用过大的历史增益。稳态并不削顶，因此修复需要覆盖数量变化瞬间，而不只是稳态增益。

新增益在Voice数量变化后立即限制到安全上限，同时记入状态，减少Voice后再缓慢恢复。默认保留约0.915dB headroom。fixture逐样本对比原始混音和Voice数量，必须保持相同；因此消除削顶不是修改音符频率、包络或降低各Voice幅度得到的。

## 专项验证定义

本轮统一入口为`scripts/run_visual_tests.ps1`，依次执行工具发现自检、音频质量、完整显示/FFT/TMDS、双DAC四个suite。范围是当前`boards/tang_mega_138k_pro`工程，不包含仓库旧版同名基线的全部历史测试。板级top采用vendor原语端口stub只验证层级展开，不证明PLL或OSER10硬件行为；严格lint针对增益、visualizer、test_mode和PCM5102A sender，不宣称全板顶层lint零warning。

24种增益配置覆盖4/8/16/32路、16/24bit、default/unity/mute master、额外衰减、同相正/负满幅、正负抵消、随机输入、采样前数量变化及复位。每配置1200个输出样本，TB同时检查采样前和采样后安全上限，Python再做整数bit-exact比对。

真实24bit核心包含13种场景：诊断启动、单音、同相4/8/16/32路、方波/锯齿/钢琴音色、velocity0/1/127/255、Morph0→1023、重复同音与快速on/off、release归零和reset。其sample enable人为加速以缩短仿真；不是DAC主时钟频率验证，实际DAC频率由独立I2S回归确认。

4352个相位核对现有四分之一sine角度/幅度，以及square/saw/triangle边界；9216组raw×envelope×velocity验证24bit缩放，包含所有256个velocity值和正负极值。与不保留3个guard bit的直接无限精度乘法相比，截位误差允许至多1个24bit LSB，必须与当前RTL定点公式逐位相同。

FIFO新增depth1/3/16，包括非2幂深度、连续随机事件、满/空、反压时数据保持、读写绕回和复位丢弃旧队列。生产者遵守ready/valid；不把合法的满队列反压气泡当作事件丢失。

## 音质指标的边界

方波、锯齿、钢琴的谐波是音色组成，不能用纯正弦低THD要求判它们失真。当前正弦只有8bit相位寻址精度，数字全带非基波能量包含查表保持镜像；24bit输出格式不代表24bit有效音质。记录离散谐波与全带指标，不冒充模拟DAC THD或SNR。

相邻样本最大跳变包含方波本身的合法跳变，不能直接等同于启停爆音。测试验证零velocity静音和release归零，并记录转换场景跳变；不承诺任意抢占/音色切换绝对无点击声。

WAV为开发期实际RTL PCM导出，单声道24bit小端48kHz，已用正负端点往返验证；FPGA运行时不播放这些文件。

## 视频验证范围

接收器从`audio_visualizer`最终三路10bit TMDS字开始反向解码，覆盖颜色、DE、消隐HS/VS控制、通道映射、差分平衡和前级像素管线。故意交换颜色通道、翻转数据位及篡改消隐控制时必须检出错误，并测试活动区/消隐区复位恢复。

这是**OSER10之前的数字字流验证**。没有使用行为模型假装验证真实OSER10 DDR边沿、差分电气、PLL相位或HDMI线缆，仍需Gowin布局布线和显示器实测。

## 仍需上板

检查Gowin实际RAM/DSP/常量LUT映射、增益组合路径及视频时序；PLL锁定、SDC节点、OSER10路由、J11显示兼容性；双DAC同时试听、模拟噪声/失真、音符启停听感和传感器到DAC延迟；独立供电冷启动。没有板子时不能宣称这些已完成。本轮不自动commit/push。
