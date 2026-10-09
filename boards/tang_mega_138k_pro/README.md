# 弦动智音：Tang Mega 138K Pro 板级工程

本目录是当前开发和上板入口，2026-10-08 从实际开发工程整理入库。工程路径为相对路径，克隆到其他盘符后也可打开，不要求存在原开发机器的 E 盘。仓库根目录保留的是独立板卡无关基线；只编译本目录 Gowin 工程列出的文件，不要混入根目录 `rtl/` 的同名模块。项目总览见[仓库首页](../../README.md)。

## 打开与运行

- Gowin 打开 [yinyue_fashengqi.gprj](yinyue_fashengqi.gprj)，器件为 GW5AST-LV138FPG676AC1/I0。
- `src/` 包含工程实际引用的 RTL、PLL 封装、CST 和 SDC；未发布未引用的旧顶层或备用约束，避免误用。
- `sim/` 是自检测试，`visual_primitive_stubs.v` 仅用于接口展开，未加入 Gowin 工程。
- `scripts/run_visual_tests.ps1` 执行工具迁移自检、独立ADC采集、音频增益/音质、显示/TMDS接收和双DAC专项回归。
- 安装Python、Icarus Verilog、Verilator和Yosys，并运行 `python -m pip install -r scripts/requirements.txt`。脚本优先使用PATH，也支持verilator-cli/yowasp-yosys包装程序；无需修改脚本中的用户或盘符路径。可通过 `FPGA_PYTHON`、`FPGA_IVERILOG`、`FPGA_VVP`、`FPGA_VERILATOR`、`FPGA_YOSYS` 明确指定工具。电脑只用于开发验证，硬件运行不调用Python。
- `backup_before_pcm5102a_20261007/i2s_tx.v` 仅是回归所需的板载 DAC 原逻辑比较基准，不是活动源码。其他本机备份、工具、临时日志、旧 FS 均未上传。

在本目录运行 `./scripts/run_visual_tests.ps1`；若只验证双DAC，运行 `./scripts/run_pcm5102a_tests.ps1`；仅验证新ADC模块运行 `./scripts/run_checks.ps1 -Suite adc`。根目录的 `scripts/run_regression.ps1` 只验证原板卡无关基线，不编译本目录Gowin工程。两种回归的结果不能互相替代。

`python scripts/run_regression.py --check-tools` 只做工具预检。完整回归先验证带空格路径迁移和工具缺失报错，再跑独立ADC、音频增益/音质、显示链与双DAC；失败返回非零，汇总写入 `sim_out_visual/regression_summary.json`，包含源码SHA256、时间戳和各专项PASS/FAIL。报告先标记RUNNING，结束后才写PASS/FAIL，并核对源码在运行期间未变化；不能将旧报告当成当前运行结果。

新增双MCP3208模块仅是未接板的独立采集层，详见[MCP3208说明](MCP3208_README.md)。ADC未加入实际板级top/GPRJ，没有因ADC改动音频/视频时钟或GPIO；后续还需确认器件供电、Bank电平与接线。2026-10-09发布前已重新执行含ADC的统一五suite完整回归，全部PASS，见[最新完整报告](verification/full_regression_20261009.md)及[机器结果/源码哈希](verification/full_regression_20261009.json)。历史四suite与ADC专项报告仍单独保留。

## 已添加功能与验证范围

保留板载 PT8211、外接 PCM5102A 和既有合成核心，新增实际 PCM 旁路采集、硬件 FFT、波形、双 Voice 李萨如/延迟相图、跨时钟快照、640×480 绘图、TMDS 及 J11 DVI TX 输出。

说明：[双 DAC](PCM5102A_README.md)、[可视化与板级风险](VISUALIZATION_README.md)。

已有验证记录：[显示链](verification/visualization.md)、[FFT 机器结果](verification/visualization.json)、[双 DAC](verification/pcm5102a.md)。这三份是 E 盘已通过运行的归档报告，不冒充每次克隆后重新运行的结果。新运行结果写入被忽略的 `sim_out_visual/`、`sim_out_pcm5102a/`。

本轮新增真实32 Voice诊断链自检，以及波形幅度/时间、频谱频率标尺和实际主峰Hz读数；验收数据见[本轮离线验证报告](verification/offline_visualization_20261008.md)。独立FFT向量测试与实际合成器PCM测试分别记录，均不等于实物显示验证。

2026-10-09继续修复增益下降滞后：顶层`MASTER_GAIN_Q15=29491`默认约0.9，保留约0.915dB headroom；按实际Voice数量归一化、立即限制过大增益并缓慢恢复，不把单音固定除32。新增完整TMDS逆向接收/图像比较、混音边界/波形/velocity/复位/FIFO专项，见[音频与TMDS报告](verification/audio_tmds_20261009.md)。开发期可用`python scripts/pcm_to_wav.py sim_out_visual/audio_quality.txt single.wav --scenario 1`导出实际单音测试PCM；运行时FPGA不读WAV。

## 未完成的实物验收

尚未生成或烧录含新视频功能的固件。必须先用 Gowin 完成综合、布局布线，验证视频 PLL、OSER10、存储/DSP 映射、SDC 时钟节点和时序，再连接 J11 显示器实测。当前 25MHz 像素时钟对应约 59.52Hz，不是严格标准 VGA 时钟；屏幕兼容性未验证。

顶层参数 `DIAGNOSTIC_MODE=0` 默认保留正常演奏；改为1并重新构建可通过原32 Voice链产生间距足够的诊断音，诊断期间屏蔽触摸事件分配，不是物理模式按钮。`morph_enable` 仍固定为0，LED教学尚未接通板级输出，UART遥测未引出。默认2048点FFT不保证分开任意相邻低音。脱机冷启动和传感器到DAC模拟输出≤5ms延迟均未实测。本目录不标记为实物验收完成版本。
