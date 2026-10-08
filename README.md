# 弦动智音：FPGA 实时多音色合成与视听演示系统

基于FPGA的实时电子乐器：独立Voice逐样本合成，经板载PT8211和外接PCM5102A输出声音，由FPGA内部计算FFT、绘制波形和李萨如图，经J11视频输出到显示器。运行时不依赖电脑计算FFT或绘图，不播放预录PCM。

**当前开发入口是 [Tang Mega 138K Pro 板级工程](boards/tang_mega_138k_pro/README.md)，不是根目录的旧板卡无关基线。** 板级工程整理于2026-10-08，包含Gowin工程、PLL封装、管脚/时序约束、测试和验证报告。新视频功能尚未完成Gowin布局布线和显示器实测，没有提供已验收的新固件。

## 当前功能与状态

| 功能 | 当前状态 |
|---|---|
| 多声部合成 | 保留默认32个独立Voice的phase、frequency、ADSR、note、velocity状态，以及事件FIFO、分配和混音链 |
| 触摸输入 | 已有TTP229读取和音符事件转换；不代表多维表情交互已全部完成 |
| 板载DAC | 保留PT8211的16bit输出和原有合成节拍来源 |
| 外接DAC | PCM5102A标准I2S，默认24bit、双声道32bit slot；与板载同时工作，当前同一单声道混音复制到左右声道 |
| 波形 | 旁路采集实际送DAC的数字PCM，过零触发显示；不是模拟输出回采 |
| 频谱 | FPGA定点FFT，默认2048点/Hann窗；系数查表不是预制频谱 |
| 李萨如/相图 | Voice0/1均活跃时使用真实双Voice输出，否则显示混音与延迟信号的相图 |
| 视频 | 已加入640×480绘图、TMDS和J11 DVI TX，经HDMI线传视频；不传HDMI音频，实物待验证 |
| LED教学、连续Morph、测试模式 | 有相关模块；LED教学尚未接通板级输出，板级Morph和test_enable目前固定关闭 |

## 工程目录

```text
boards/tang_mega_138k_pro/        最新板级工程，当前开发和上板入口
  yinyue_fashengqi.gprj          Gowin工程，GW5AST-LV138FPG676AC1/I0
  src/                          活动RTL、PLL封装、CST和SDC
  sim/                          双DAC、FFT、CDC、复位、视频及集成自检
  scripts/                      板级专项回归入口与Python黄金模型
  verification/                 已通过运行的归档报告与FFT结果
rtl/                            独立保留的板卡无关RTL基线
tb/                             仅对应根目录基线的testbench
scripts/                        仅对应根目录基线的回归和模型
docs/PORTABLE_RTL_BASELINE.md     基线模块与接口参考
```

两套工程有同名模块，**不要混合编译**。根目录的 `scripts/filelist.f` 不用于编译最新板级工程。本机工具、临时仿真产物、原理图附件、旧固件和Gowin用户设置不随仓库发布。

## 打开最新工程

在Gowin中打开 [yinyue_fashengqi.gprj](boards/tang_mega_138k_pro/yinyue_fashengqi.gprj)。工程使用相对路径，克隆后不要求保留原来的E盘路径。

- [板级工程入口与工具配置](boards/tang_mega_138k_pro/README.md)
- [PCM5102A接线、I2S时序及双DAC说明](boards/tang_mega_138k_pro/PCM5102A_README.md)
- [FFT、波形、李萨如、J11接线与视频时钟风险](boards/tang_mega_138k_pro/VISUALIZATION_README.md)

接线和供电先阅读上述说明。PCM5102A的VIN未指定，不能接到GPIO；J11是视频输出口，不要接到输入口。下载前必须重新综合、布局布线，确认PLL、约束、资源和时序；没有可直接代表本次新功能的已验证FS文件。

## 验证与复现

先安装Icarus Verilog、Verilator、Yosys、Python及numpy/Pillow，并调整板级 `scripts/` 中原开发机器的工具路径。仓库不自带 `bin/` 或Python运行时。

从仓库根目录运行：

```powershell
Set-Location .\boards\tang_mega_138k_pro
.\scripts\run_visual_tests.ps1
```

此入口先跑显示链，再跑双DAC专项回归。归档证据：[显示链报告](boards/tang_mega_138k_pro/verification/visualization.md)、[FFT机器结果](boards/tang_mega_138k_pro/verification/visualization.json)、[双DAC报告](boards/tang_mega_138k_pro/verification/pcm5102a.md)。

- 1024/2048/4096点硬件FFT测试共14,336个复数/功率bin与黄金模型bit-exact一致，每种配置检出32/32个已知、间距足够的测试峰。
- 合成器到显示的完整集成测试为四音；双DAC专项另验证四音/32音与I2S逐bit数据。
- CDC快照、单侧复位、TMDS编码和视频帧时序自检通过。
- 新增可移植显示链和PCM5102A发送器严格Verilator检查无RTL warning，Yosys通用检查通过；不代表整个板级工程零warning或厂商布局布线通过。

**区分两种FFT：** 根目录基线回归中的16384点Python FFT是开发期音频验证工具；板级2048点RTL FFT才是运行时显示的数据来源。32/32测试向量峰不等于已完成实物32 Voice频谱展示。

归档报告不代表本次文档更新重新运行了仿真。新本地回归产物写入板级目录的 `sim_out_visual/`、`sim_out_pcm5102a/`，不会自动上传。

## 仍需完成

1. Gowin原生综合和布局布线，验证视频PLL、OSER10、RAM/DSP映射、SDC节点及实际时序。
2. 显示器锁定和双DAC同时发声实测。当前25MHz像素时钟对应约59.52Hz，显示器兼容性尚未验证。
3. 接通板级32 Voice诊断模式，按FFT分辨率选择可分离频率，完成真实合成到屏幕的32峰展示。
4. 接通LED教学、所需表情控制和明确的音色切换；已有模块不等于已完成物理交互。
5. 断开电脑冷启动演示，并实测控制输入到DAC模拟输出的延迟。默认FFT观察窗约42.7ms，不是发声延迟；内部数字计数不能证明赛题端到端≤5ms。

本阶段不以新增蓝牙、App或复杂UI替代上述验证。原板卡无关接口、模块和回归说明见[独立基线参考](docs/PORTABLE_RTL_BASELINE.md)。
