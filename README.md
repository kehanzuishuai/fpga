# 弦动智音系统：板卡无关 RTL 基线

这是一个不依赖高云专用 IP、PLL、约束文件或具体 Tang 型号的 SystemVerilog 合成引擎。默认目标为 48 kHz、24-bit 立体声音频、32 个真正独立的 Voice。

## 目录

```text
rtl/       可综合的硬件模块
tb/        Icarus Verilog 自检 testbench
scripts/   filelist.f：统一编译源文件列表
bin/       本地仿真使用的便携式 Icarus 工具（不属于上板 RTL）
```

## 模块

| 模块 | 职责 |
|---|---|
| `note_freq_table` / `dds_phase_accum` | MIDI 音符到 32-bit 相位增量、每采样点 DDS 累加 |
| `waveform_gen` | 正弦（64 点四分之一波表）、方波、锯齿、三角波 |
| `timbre_morph` | 在四种波形间连续线性交叉渐变 |
| `adsr_env` | Attack/Decay/Sustain/Release 包络，参数化步长与电平 |
| `voice` | 一条真实独立声部：相位、频率、音符、速度、ADSR 和音频输出 |
| `voice_allocator` / `voice_bank` | 空闲优先，否则按最小启动时间戳抢占最老 Voice；默认 32 路 |
| `tree_mixer` / `saturator` | 参数化二叉并行加法树与有符号饱和限制 |
| `synth_core` | 合成顶层；`test_enable` 依次激活 C2 起的 32 个不同频率 |
| `latency_monitor` / `audio_telemetry` | 采样域事件到可闻音频延迟、调试脉冲、活动 Voice 数、峰值和 PCM 降采样 |
| `telemetry_uart` | 无板卡依赖的遥测帧发送：活动 Voice、音频峰值、降采样 PCM 与校验和 |
| `i2s_tx` / `uart_tx` | 不含 PLL 的通用 I2S 和 8N1 UART 发送器 |
| `score_rom` / `led_guide` | 可替换的小型曲目 ROM 与脱机 LED 演奏指引 |

## 关键接口约定

- 外部时钟域应提供一个周期宽的 `sample_tick`（默认每秒 48000 次）。合成音频状态仅在该 tick 演进。
- `note_on` / `note_off` 可在系统时钟任意周期到达；Voice 会立即锁存 gate，下一采样点开始/结束音频状态更新。
- `i2s_tx` 的 `CLK_HZ` 必须是 `SAMPLE_RATE * 2 * SLOT_W` 的整数倍；实际板上由后续 PLL/时钟模块提供。
- `tree_mixer` 的 `VOICES` 应为 2 的幂；默认 32。

## 仿真

在工程根目录运行：

```powershell
$iv = '.\bin\iverilog.exe'; $vv = '.\bin\vvp.exe'
& $iv -g2012 -s tb_synth -o tb_synth.vvp -f scripts/filelist.f tb/tb_synth.sv; & $vv tb_synth.vvp
```

另有 `tb_allocator`、`tb_mixer`、`tb_i2s`。所有测试均使用本项目的 `filelist.f`。

完整回归入口为 `scripts/run_regression.ps1`。它会运行各 RTL 自检、导出 `sim_out/test32_s24le.pcm`、以 Python FFT 验证 32 个独立频率峰，并运行 Verilator lint 与 Yosys 的通用结构/综合检查。

## 还未纳入本基线的上板工作

1. 根据最终 60K/138K 时钟，增加 PLL/分频与精确的 48 kHz `sample_tick`、I2S MCLK/BCLK 时钟方案。
2. 加入所选 I2S DAC/功放、触摸/压力/ToF/手势传感器的驱动、去抖、跨时钟域和演奏事件队列。
3. 编写 Gowin 工程、时序约束、管脚约束、下载配置及资源/时序报告；评估 32 voice 在目标芯片上的 DSP/LUT 使用率。
4. 接入串口屏协议、频谱/FFT（赛题后续功能）与手机/蓝牙控制；它们刻意不在当前 RTL 范围内。
