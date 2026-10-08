# FPGA实时音频分析与J11视频输出（无复杂UI）

## 本次实现范围

本说明对应仓库内当前板级工程的硬件分析和显示链，来源于原开发工程的增量修改。保留板载PT8211和外接PCM5102A；原音频PLL、DDS、包络、分配器、混音运算不重写。电脑上的Python仅用于开发期黄金模型验证，运行时FFT、绘图、视频编码全部由RTL完成，不需要电脑或软核CPU。工程入口见[板级README](README.md)，不依赖原来的E盘路径。

运行路径：合成器最终24bit PCM → 原DAC实际捕获边界旁路取样 → 16bit定点FFT/波形快照 → 跨时钟完整帧交接 → 像素绘制 → TMDS → OSER10/差分输出 → J11显示器。

这里观察的是送DAC的数字PCM，不是DAC之后的模拟回采；不会掩盖DAC、电源或后级模拟失真。

## 已实现模块

| 文件 | 作用 |
|---|---|
| src/visual_frame_store.v | 双缓冲完整快照、req/ack同步交接、慢读整帧丢弃计数；不会反压音频 |
| src/visual_fft.sv | 基2DIT硬件FFT、位反序输入、自然序输出、实/虚部与功率；默认2048点 |
| src/visual_twiddle_rom.v | 4096组Q1.15旋转系数同步ROM，支持16～4096点FFT；不保存预录频谱 |
| src/audio_visualizer.sv | 接实时PCM、触发波形、Hann窗FFT、两个真实Voice或延迟相图、分析子系统复位 |
| src/visual_renderer.sv | 波形/相图/频谱最小绘制；垂直消隐期间复制快照，显示期间冻结 |
| src/visual_raster.v | 640×480有效区、800×525总时序、负极性HS/VS |
| src/visual_tmds.sv | 三路8bit RGB的TMDS编码、控制字符、运行差分平衡 |
| src/visual_dvi_io.v | 板级OSER10、ELVDS_OBUF；与可移植RTL隔离 |
| src/visual_video_clock.v、src/gowin_pll/visual_pll_mod.v | 独立视频PLL和器件C初始化，名义125MHz/25MHz；不替换音频PLL |

现有 synth_core/synth_event_frontend/synth_top 仅增加两个既有Voice的观测输出；synth_top另暴露DAC捕获有效信号和完整PCM。独立Voice状态保持原实现，不新增用于装饰的振荡器。

## 当前画面

- 左上：256点绿色波形，每次采集512个真实48kHz样本再取隔点，时间跨度约10.67ms。上升过零触发，100ms等待超时允许直流/静音更新；固定幅度，不做自动增益。
- 右上：256×128点阵青色轨迹。当Voice0和Voice1均活跃时，横纵轴分别取这两个Voice的真实样本；否则显示混音与约33采样延迟的相图。后者不是独立左右声道分析。首版是点轨迹，无插值、余辉、模式文字或复杂UI。
- 下方：512列实际FFT功率频谱，横轴线性0～接近24kHz。2048点时相邻两个FFT bin取最大柱高；底层仍保留1024个自然序正频率bin。柱高为log2功率近似，不冒充已校准dBFS。无32/32假标牌。

显示快照过快时允许丢弃完整显示帧，dropped计数可用于调试；不能将其误认为音频丢样。视频失锁只复位分析链，不能阻塞或复位原发声通路。

## FFT格式、速度与限制

默认LOGN=11、N=2048，输入是PCM高16bit，内部复数18bit有符号。Hann窗由系数ROM计算。每级蝶形右移1bit，FFT总尺度为1/N；旋转系数幅度32767，所有截位采用算术下取整，功率为37bit实部平方加虚部平方。输出bin0～N/2-1，不输出Nyquist bin。

48kHz下观察窗口42.667ms，FFT格点间隔23.4375Hz。仿真测得从最后一个输入样本到最后一个输出bin约64262个音频主时钟，名义12.288MHz下约5.23ms；这不是演奏声音输出延迟。显示还需要等待视频消隐和刷新。默认整块非重叠采样，不承诺5ms频谱画面响应。

FFT采用时分复用蝶形、同步存储及系数ROM，不用大规模并行三角函数计算。读写不能及时完成时丢整块分析快照并计数，不让合成器等待。N=1024/2048/4096已纳入自检；可视化绘制支持LOGN10～12。32频率峰测试使用间隔足够的已知实时测试样本，并不意味着任意32个相邻低音在2048点FFT下都能分开。

## 视频接口与接线

已按用户提供的Pro-Dock4071f原理图第8页目视核对，并对照Sipeed官方Pro例程：使用**J11，DVI_TX_A，HDMI Type-A插座**，不要插到输入接口。

| 信号 | FPGA差分引脚P/N |
|---|---|
| video_d_p[0] / video_d_n[0]，蓝色及控制 | AB24 / AC24 |
| video_d_p[1] / video_d_n[1]，绿色 | V24 / W24 |
| video_d_p[2] / video_d_n[2]，红色 | AA22 / AA23 |
| video_ck_p / video_ck_n | Y22 / Y23 |

活动CST已经加入上述差分对，未占用PCM5102A的C24/B24/H15。DVI兼容视频经HDMI线送显示器，无HDMI音频、CEC、HDCP或EDID/DDC读取。声音继续走原DAC和音箱。

名义像素25MHz、串行125MHz DDR，640×480约59.52Hz。不是严格25.175MHz/59.94Hz标准VGA；实际显示器接受情况需要实测。若屏幕不锁定，先验证标准视频时钟/彩条，不修改FFT来掩盖链路问题。

## 自检与真实像素产物

在本板级目录运行 `scripts/run_visual_tests.ps1`，输出到 `sim_out_visual`，然后自动重跑现有双DAC专项回归。先按[板级README](README.md)配置本机工具路径。已归档的运行记录见[verification/visualization.md](verification/visualization.md)及[FFT结果](verification/visualization.json)。

- 4096组旋转系数解析校验。
- FFT零输入、单音、32不同频率叠加、随机正负边界值；1024点矩形窗、2048/4096点Hann窗逐bin实部/虚部/功率bit-exact比对。
- 异步时钟稳定快照、慢消费者整帧丢弃、释放及下一帧。
- 音频侧或视频侧单独复位时，两端快照握手同时清零、各自同步释放，防止旧快照被误读。
- TMDS4096个数据字节往返解码、控制字符、运行差分；完整视频帧有效像素和同步长度。
- 真实E盘合成器四音 → 两个DAC相同捕获边界 → 硬件FFT/双Voice李萨如 → 像素/TMDS，导出实际RTL像素PPM/PNG。该PNG不是AI设计图。
- 顶层端口/层次检查用sim/visual_primitive_stubs.v，只是接口桩，**不在Gowin工程中**，不模拟PLL锁定或证明硬件串行时序。
- 严格Verilator --Wall检查新增可移植链，无warning屏蔽；Yosys通用RTL/存储综合与check -assert，不等同于厂商器件映射。
- RAM读写与异步复位控制分离，系数采用同步初始化ROM，频谱合并用独立峰值寄存器；通用综合保留11个存储单元、8个乘法单元。这是新增可视化子系统统计，不是整个工程的器件资源用量。

本机Verilator启动包装程序会输出一行 `The system cannot find the path specified.`；随后Verilator正常运行并返回0，报告中无 `%Warning`/`%Error`。这条主机启动环境提示仍保留在日志，不冒充工具全程无任何诊断。零RTL warning的范围是新增可移植显示链，未声称整个旧板级工程全部lint清零。

## 上板前必须完成

1. 在Gowin中打开本板级目录的 `yinyue_fashengqi.gprj`，确认.sv按SystemVerilog解析，重新综合和布局布线。仓库未提供含新视频功能的已验证FS，不能拿修改前的旧固件验证本次功能。
2. 检查新视频PLL两个输出频率、VCO/分频合法性、相位关系、初始化、PLL占用和OSER10时钟路由。视频PLL参数基于现有器件C封装配置增量生成，仍需厂商实现工具验证，必要时用当前Gowin IP生成器重建该视频封装。
3. 核对SDC中生成时钟节点被工具实际识别，无空对象/未约束路径；确认音频与视频异步分组正确，不能忽略约束警告。
4. 检查FFT和点阵实际映射为片上RAM、乘法器映射及布局后时序。不能用通用Yosys单元数代替真实138K资源报告；原工程时序裕量很小。
5. 用显示器确认J11视频锁定、颜色/同步和连续演奏稳定性；同时试听两路DAC，确认没有新增噪声或卡顿。
6. 通过后再进行Flash启动验证：独立供电、断开电脑冷启动，仍能触发演奏、观察波形/李萨如/频谱。当前不宣称实物脱机验证已完成。

本目录已经随最新工程提交到GitHub，包含活动源码、Gowin工程、约束、测试和归档报告。原开发机器的 `backup_before_visual_20261008` 只属于本机备份，未发布到仓库；临时日志、像素PNG/PPM和旧固件也未上传。重新运行回归可在本机生成实际RTL像素图，不应将缺少这些临时产物误认为缺少显示源码。

参考：[Sipeed Pro官方例程](https://github.com/sipeed/TangMega-138KPro-example/tree/main/simple_video_out/svo)，只参考板级IO/串行器连接和时钟组织，没有引入摄像头、DDR或CPU系统。
