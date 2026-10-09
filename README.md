# 弦动智音：FPGA 实时多音色合成与视听演示系统

基于FPGA的实时电子乐器：独立Voice逐样本合成，经板载PT8211和外接PCM5102A输出声音，由FPGA内部计算FFT、绘制波形和李萨如图，经J11视频输出到显示器。运行时不依赖电脑计算FFT或绘图，不播放预录PCM。

**当前开发入口是 [Tang Mega 138K Pro 板级工程](boards/tang_mega_138k_pro/README.md)，不是根目录的旧板卡无关基线。** 板级工程整理于2026-10-08，包含Gowin工程、PLL封装、管脚/时序约束、测试和验证报告。新视频功能尚未完成Gowin布局布线和显示器实测，没有提供已验收的新固件。

## 当前功能与状态

| 功能 | 当前状态 |
|---|---|
| 多声部合成 | 保留默认32个独立Voice的phase、frequency、ADSR、note、velocity状态，以及事件FIFO、分配和混音链 |
| 混音增益 | 按实际Voice数量归一化，立即限制过大增益、缓慢恢复；参数化Q15 master默认0.9，单音不固定除32 |
| 触摸输入 | 已有TTP229读取和音符事件转换；不代表多维表情交互已全部完成 |
| 板载DAC | 保留PT8211的16bit输出和原有合成节拍来源 |
| 外接DAC | PCM5102A标准I2S，默认24bit、双声道32bit slot；与板载同时工作，当前同一单声道混音复制到左右声道 |
| 波形 | 旁路采集实际送DAC的数字PCM，过零触发显示；不是模拟输出回采 |
| 频谱 | FPGA定点FFT，默认2048点/Hann窗；系数查表不是预制频谱 |
| 李萨如/相图 | Voice0/1均活跃时使用真实双Voice输出，否则显示混音与延迟信号的相图 |
| 视频 | 已加入640×480绘图、TMDS和J11 DVI TX，经HDMI线传视频；不传HDMI音频，实物待验证 |
| LED教学、连续Morph、测试模式 | LED教学尚未接通板级输出，Morph固定关闭；编译期DIAGNOSTIC_MODE可开启真实32 Voice诊断音，默认关闭 |

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
- [磁轴/Hall校准、滤波与按键力度识别（尚未接板/发声）](boards/tang_mega_138k_pro/HALL_KEYS_README.md)
- [新增Hall解释后的六项完整回归报告](boards/tang_mega_138k_pro/verification/hall_keys_20261009.md)

接线和供电先阅读上述说明。PCM5102A的VIN未指定，不能接到GPIO；J11是视频输出口，不要接到输入口。下载前必须重新综合、布局布线，确认PLL、约束、资源和时序；没有可直接代表本次新功能的已验证FS文件。

## 验证与复现

先安装Icarus Verilog、Verilator、Yosys和Python，运行板级 `scripts/requirements.txt` 安装numpy/Pillow。脚本从PATH发现工具，也可用 `FPGA_PYTHON/FPGA_IVERILOG/FPGA_VVP/FPGA_VERILATOR/FPGA_YOSYS` 指定；不再要求修改原开发机器路径。仓库不自带工具或Python运行时。

从仓库根目录运行：

```powershell
Set-Location .\boards\tang_mega_138k_pro
.\scripts\run_visual_tests.ps1
```

此入口先做脚本迁移自检，再跑独立ADC采集、音频增益/音质、显示/TMDS接收和双DAC专项回归。ADC当前仅完成未接板的原始采集层，见[MCP3208说明](boards/tang_mega_138k_pro/MCP3208_README.md)，没有改动现有声音/显示链。音视频证据见[音频与TMDS报告](boards/tang_mega_138k_pro/verification/audio_tmds_20261009.md)，前一轮见[32 Voice离线验证](boards/tang_mega_138k_pro/verification/offline_visualization_20261008.md)。原始归档仍保留：[显示链报告](boards/tang_mega_138k_pro/verification/visualization.md)、[FFT机器结果](boards/tang_mega_138k_pro/verification/visualization.json)、[双DAC报告](boards/tang_mega_138k_pro/verification/pcm5102a.md)。

- 1024/2048/4096点硬件FFT测试共14,336个复数/功率bin与黄金模型bit-exact一致，每种配置检出32/32个已知、间距足够的测试峰。
- 合成器到显示分别测试四音和32 Voice；32 Voice实际PCM进入RTL FFT，并逐bin比对黄金模型、核对512列柱高和主峰Hz读数。双DAC另验证四音/32音与I2S逐bit数据。
- CDC快照、单侧复位、TMDS编码和视频帧时序自检通过。
- 增益、波形/velocity定点缩放、FIFO随机反压及完整TMDS反向接收纳入回归；接收端还原两幅640×480画面，与原始像素逐字节核对。该检查位于OSER10之前，不代表物理HDMI线路已通过。
- 新增可移植显示链和PCM5102A发送器严格Verilator检查无RTL warning，Yosys通用检查通过；不代表整个板级工程零warning或厂商布局布线通过。

**区分两种FFT：** 根目录基线回归中的16384点Python FFT是开发期音频验证工具；板级2048点RTL FFT才是运行时显示的数据来源。32/32测试向量峰不等于已完成实物32 Voice频谱展示。

每次本地回归产物写入板级目录的 `sim_out_visual/`、`sim_out_pcm5102a/`、`sim_out_adc/`、`sim_out_keys/`，不会自动上传。完整汇总记录PASS/FAIL、源码SHA256和运行时间，尚在执行时标记RUNNING；历史归档不能代替当前源码回归。上一轮发布前五suite结果见[历史完整报告](boards/tang_mega_138k_pro/verification/full_regression_20261009.md)，新增Hall解释后的最新六suite结果见[本轮完整报告](boards/tang_mega_138k_pro/verification/hall_keys_20261009.md)，均限定仿真与实物验收的范围。

## 仍需完成

1. Gowin原生综合和布局布线，验证视频PLL、OSER10、RAM/DSP映射、SDC节点及实际时序。
2. 显示器锁定和双DAC同时发声实测。当前25MHz像素时钟对应约59.52Hz，显示器兼容性尚未验证。
3. 用编译期32 Voice诊断模式实测屏幕频谱，确认实物32峰与离线结果一致；目前没有物理模式切换按钮。
4. 接通LED教学、所需表情控制和明确的音色切换；已有模块不等于已完成物理交互。
5. 断开电脑冷启动演示，并实测控制输入到DAC模拟输出的延迟。默认FFT观察窗约42.7ms，不是发声延迟；内部数字计数不能证明赛题端到端≤5ms。

本阶段不以新增蓝牙、App或复杂UI替代上述验证。原板卡无关接口、模块和回归说明见[独立基线参考](docs/PORTABLE_RTL_BASELINE.md)。
