# 离线显示链增量验证（2026-10-08）

状态：**本轮离线回归全部PASS，实物未验收。** 最终完整运行时间为北京时间2026-10-08 23:45:01～23:57:17，启动脚本退出码0。67个src/sim/scripts文件的开始/结束SHA256一致，完整机器结果见[offline_visualization_20261008.json](offline_visualization_20261008.json)。没有用初步运行或中断运行代替这次结果。

## 最终测试结果

| 检查 | 结果 |
|---|---|
| 带空格路径迁移、工具覆盖、缺失工具失败返回 | PASS |
| 波形/频谱标尺、主峰、DC排除、同柱高不同功率、末端bin、静音、BCD、48k/96k标签、N字形像素 | PASS |
| 独立1024/2048/4096点FFT向量 | 14,336个实部/虚部/功率bin bit-exact；三种配置均32/32峰 |
| 真实四音和32 Voice→实际DAC PCM→RTL FFT→快照→像素/TMDS | 两种集成测试PASS，各640×480有效像素、无X像素；FFT丢帧0 |
| 真实32 Voice连续PCM的黄金模型比较 | 两帧共2,048个实部/虚部/功率bin bit-exact |
| 真实32 Voice独立频率峰和显示柱高 | 32/32独立峰；全部512列池化柱高与实际RTL功率一致 |
| 主峰整数读数 | 469Hz，与最大非DC功率bin对应；四音图为328Hz |
| 32 Voice PCM削顶端点命中 | 8/5,644 = 0.141743%，不是零削顶 |
| 32音最大FFT格点频率误差 | 12.020455Hz；默认bin间隔23.4375Hz |
| 诊断音DDS ROM最大量化误差 | 0.000005408474Hz，名义48kHz下计算，不是模拟实测 |
| CDC快照、单侧复位、TMDS及完整视频帧 | PASS |
| PCM5102A、双DAC、实际4/32音I2S逐bit回归 | 全部PASS；BCLK=4主时钟/周期，LRCLK=256主时钟/帧，名义3.072MHz/48kHz |
| Verilator严格--Wall | audio_visualizer、test_mode、pcm5102_i2s_tx均0 warning，无屏蔽选项 |
| Yosys | 显示链及I2S发送器check -assert均0问题；显示链无warning或意外RAM展开 |
| PT8211历史对比、GPIO约束检查 | PASS，原发送时序未变 |

这不是整个旧核心的全模块零warning声明；未重新冻结或重写原UART、ADSR、allocator等模块。板级顶层仅用仿真原语接口桩做展开检查，不能证明PLL或OSER10硬件行为。

最终本机产物：`sim_out_visual/regression_summary.json`、`verification_report.md`、`rtl_display.png`、`rtl_display_32.png`、`voice32_pcm.txt`、`voice32_fft.txt`、`voice32_display.txt`，以及`sim_out_pcm5102a/verification_report.md`。PNG由实际RTL像素导出并已目视检查，不是AI效果图；临时产物不自动上传。

## 修改范围

- `src/test_mode.v`：32个诊断MIDI音符，频率间隔至少4个默认FFT bin，经原独立Voice链合成。
- `src/tang_mega_138k_pro_top.v.v`：默认关闭的DIAGNOSTIC_MODE参数，诊断期间屏蔽触摸分配；默认正常演奏保持不变。
- `src/audio_visualizer.sv`、`src/visual_renderer.sv`：完整37bit功率跨域快照、排除DC的主峰Hz计算、采样率参数化标尺和触发超时。
- `src/visual_labels.sv`、工程文件：小型字体和double-dabble十进制转换，不使用电脑运行时绘图。
- `sim/tb_visual_system.sv`、`sim/tb_visual_readout.sv`：真实32 Voice PCM/FFT/柱高导出比对，标尺/主峰/静音/边界像素断言。
- `scripts/toolchain.py`、`run_regression.py`、`run_checks.ps1`、`test_toolchain.py`及两个专项入口：自动工具发现、路径迁移、依赖检查、非零失败返回、源码哈希和时间戳报告。
- 根目录和板级README：更新入口、模式、资源和验证范围；保留原始归档报告不覆盖。

未修改音频PLL、视频PLL、CST、SDC、DDS/ADSR/allocator/mixer核心、PT8211时序或PCM5102A发送器。

## 资源与测量定义

旧显示链通用Yosys统计为11个存储单元/8个乘法单元。最终本轮为12/10；这不是Gowin BRAM/DSP数量，不代表整个工程资源用量。默认两个频谱快照从8bit柱高改为37bit功率，增加2×1024×29 = 59,392bit逻辑存储，以保证主峰选择不受柱高量化影响。

主峰Hz由最大非DC FFT bin计算并取整，受23.4375Hz格点限制；DDS误差是MIDI ROM相位增量对名义48kHz的量化误差。削顶率统计实际24bit PCM端点命中，不是DAC模拟失真测量。

## 回归方法与修复记录

独立FFT使用零输入、单音、32音叠加、随机正负边界，检查1024点矩形窗及2048/4096点Hann窗。真实合成器测试另采集32路Voice的实际PCM，将连续2048采样块输入整数黄金模型，对RTL实部、虚部、功率逐bin比对；再从功率中检查32个互不重复局部峰，并核对512列池化柱高及主峰读数。不会用独立向量的32峰结果代替真实Voice结果。

专项还覆盖完整视频帧/TMDS、异步快照及单侧reset、静音/末端bin/DC排除、48k/96k参数化标签，以及双DAC连续I2S数据和边沿。脚本迁移测试复制工程到带空格目录，显式测试工具缺失必须失败。最终汇总同时核对开始/结束源码SHA256，运行中修改源码将判FAIL。

首轮发现Icarus对不同长度字符串三目表达式传入`$fopen`的兼容性问题，已改显式分支并加文件打开断言。实际像素检查发现SPAN缺少N字形，已补ROM字形和非空像素断言。新增`.v`诊断模块使用显式零扩展，另通过Verilog-2005编译检查。所有问题修复后重新执行最终回归；保留失败日志，不冒充首轮即通过。

默认2048点/Hann窗观察时间42.667ms，最后输入到最后FFT bin约5.23ms，另加显示快照与刷新等待；这不是演奏声音的输入到DAC延迟，也不能证明≤5ms端到端指标。

## 仍需上板验收

Gowin原生综合、布局布线、实际RAM/DSP映射与时序；PLL锁定/OSER10路由/SDC节点；J11显示器兼容性（当前25MHz像素、约59.52Hz）；双DAC同时试听；脱机冷启动；传感器到模拟DAC输出延迟。当前没有板子，不能声称这些已通过。

本轮未自动commit或push。运行时FFT和绘图均在FPGA；Python仅为开发期黄金模型。
