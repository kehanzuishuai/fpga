# 最新上板工程：Tang Mega 138K Pro

本目录为 2026-10-08 从当前 E 盘工程整理的源码快照，不替换仓库根目录的板卡无关 RTL 基线。只编译本目录 Gowin 工程列出的文件，不要混入根目录 `rtl/` 的同名模块。

## 打开与运行

- Gowin 打开 `yinyue_fashengqi.gprj`，器件为 GW5AST-LV138FPG676AC1/I0。
- `src/` 包含工程实际引用的 RTL、PLL 封装、CST 和 SDC；未发布未引用的旧顶层或备用约束，避免误用。
- `sim/` 是自检测试，`visual_primitive_stubs.v` 仅用于接口展开，未加入 Gowin 工程。
- `scripts/run_visual_tests.ps1` 执行可视化验证，再执行双 DAC 专项回归。
- 脚本保留原验证环境的本机工具路径：Icarus 在 `D:/fpga26/bin`，Verilator/Yosys 在当前用户 Python Scripts，Python 运行时在原用户的 Codex 缓存。换电脑须先安装工具并修改脚本中的路径；Python 需 numpy、Pillow。电脑只用于开发验证，硬件运行不调用 Python。
- `backup_before_pcm5102a_20261007/i2s_tx.v` 仅是回归所需的板载 DAC 原逻辑比较基准，不是活动源码。其他本机备份、工具、临时日志、旧 FS 均未上传。

## 已添加功能与验证范围

保留板载 PT8211、外接 PCM5102A 和既有合成核心，新增实际 PCM 旁路采集、硬件 FFT、波形、双 Voice 李萨如/延迟相图、跨时钟快照、640×480 绘图、TMDS 及 J11 DVI TX 输出。

说明：[双 DAC](PCM5102A_README.md)、[可视化与板级风险](VISUALIZATION_README.md)。

已有验证记录：[显示链](verification/visualization.md)、[FFT 机器结果](verification/visualization.json)、[双 DAC](verification/pcm5102a.md)。这三份是 E 盘已通过运行的归档报告，不冒充每次克隆后重新运行的结果。新运行结果写入被忽略的 `sim_out_visual/`、`sim_out_pcm5102a/`。

显示链 1024/2048/4096 点 FFT 共 14,336 个复数/功率 bin bit-exact、各 32/32 测试峰；新增可移植链严格 Verilator 无 RTL warning，Yosys check 通过。完整合成到显示集成测试为四音，32 峰 FFT 向量测试不等于已完成实物 32 Voice 频谱展示。

## 未完成的实物验收

尚未生成或烧录含新视频功能的固件。必须先用 Gowin 完成综合、布局布线，验证视频 PLL、OSER10、存储/DSP 映射、SDC 时钟节点和时序，再连接 J11 显示器实测。当前 25MHz 像素时钟对应约 59.52Hz，不是严格标准 VGA 时钟；屏幕兼容性未验证。

当前板级 `test_enable` 固定为0，LED 教学模块尚未接通板级输出；默认 2048 点 FFT 不保证分开低音区间距很小的全部测试音。脱机冷启动和传感器到 DAC 模拟输出 ≤5ms 延迟均未实测。本目录为最新开发工程，不标记为实物验收完成版本。
