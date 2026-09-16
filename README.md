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
| `waveform_set` / `waveform_gen` | 65 点四分之一正弦 LUT（含端点）及方波、锯齿、三角波；每个 Voice 只计算一套四波形 |
| `timbre_morph` | 在四种波形间连续线性交叉渐变 |
| `adsr_env` | Attack/Decay/Sustain/Release 包络，参数化步长与电平 |
| `voice` | 一条真实独立声部：相位、频率、音符、速度、ADSR 和音频输出 |
| `voice_allocator` / `voice_bank` | 空闲优先，否则按最小启动时间戳抢占最老 Voice；默认 32 路 |
| `note_event_fifo` / `synth_event_frontend` | 可回压的连续音符事件队列及合成前端，防止快速事件丢失 |
| `tree_mixer` / `saturator` | 参数化二叉并行加法树与有符号饱和限制 |
| `polyphony_gain` | 按活动 Voice 数分档的 headroom；单音 unity、满载自动衰减，并支持额外 master attenuation |
| `synth_core` | 合成顶层；`test_enable` 依次激活 C2 起的 32 个不同频率 |
| `latency_monitor` / `audio_telemetry` | allocator 事件到目标 Voice 有效样本的内部延迟、调试脉冲、活动 Voice 数、峰值和 PCM 降采样 |
| `telemetry_uart` | 无板卡依赖的遥测帧发送：活动 Voice、音频峰值、降采样 PCM 与校验和 |
| `i2s_tx` / `uart_tx` | 标准 Philips I2S（WS 后延迟 1 bit）和连续 8N1 UART 发送器 |
| `score_rom` / `led_guide` | 可替换的小型曲目 ROM 与脱机 LED 演奏指引 |
| `performance_mode_controller` | 自由演奏、正确音符才推进的 LED 教学、按曲谱 duration 产生 note_on/off 的实时 Demo |

## 关键接口约定

- 外部时钟域应提供一个周期宽的 `sample_tick`（默认每秒 48000 次）。合成音频状态仅在该 tick 演进。
- `note_on` / `note_off` 可在系统时钟任意周期到达；Voice 会立即锁存 gate，下一采样点开始/结束音频状态更新。
- `i2s_tx` 的 `CLK_HZ` 应是 `SAMPLE_RATE * 4 * SLOT_W` 的整数倍，以得到对称 BCLK 半周期；默认 12.288 MHz 对应 BCLK 3.072 MHz、LRCLK 48 kHz。实际板上时钟由后续板级模块提供。
- `tree_mixer` 的 `VOICES` 应为 2 的幂；默认 32。
- `pcm_strobe/pcm_sample` 是串口屏频谱数据预留；`lissajous_x/y` 与 `visual_sample_strobe` 是李萨如/波形数据预留，不包含具体屏幕协议。
- note event 原生携带 note、velocity、waveform、morph，多维传感器后续只需映射到这些参数；当前没有加入任何具体传感器驱动。
- `latency_samples` 只统计 allocator 接受 note_on 到目标新 Voice 首次产生有效样本的内部数字延迟，不代表传感器到 DAC 的最终端到端延迟。

## 仿真

在工程根目录运行：

```powershell
$iv = '.\bin\iverilog.exe'; $vv = '.\bin\vvp.exe'
& $iv -g2012 -s tb_synth -o tb_synth.vvp -f scripts/filelist.f tb/tb_synth.sv; & $vv tb_synth.vvp
```

回归包含 DDS/128 项音符 ROM/波形/ADSR/Morph、Voice 边界、动态混音增益、三种演奏模式、分配与同音映射、FIFO 压力、32 路端到端、I2S 频率与逐 bit、UART 完整字节流、4/8/16/32 Voice 配置和 32 复音 PCM 测试。所有测试均使用本项目的 `filelist.f`。

完整回归入口为 `scripts/run_regression.ps1`。它会先安全清理旧 `sim_out`，再运行 16 个 RTL 自检、Python 逐样本 bit-exact 黄金模型、导出 PCM/WAV、用 16384 点 FFT 验证 32/32 个独立频率峰、比较优化前后通用资源，并对 9 个公开顶层执行严格 Verilator `--Wall`、对 4 条公开路径执行 Yosys `check -assert`。最终报告位于 `sim_out/verification_report.md`。

## 还未纳入本基线的上板工作

1. 根据最终 60K/138K 时钟，增加 PLL/分频与精确的 48 kHz `sample_tick`、I2S MCLK/BCLK 时钟方案。
2. 加入所选 I2S DAC/功放、触摸/压力/ToF/手势传感器的驱动、去抖、跨时钟域和演奏事件队列。
3. 编写 Gowin 工程、时序约束、管脚约束、下载配置及资源/时序报告；评估 32 voice 在目标芯片上的 DSP/LUT 使用率。
4. 接入串口屏协议、频谱/FFT（赛题后续功能）与手机/蓝牙控制；它们刻意不在当前 RTL 范围内。
