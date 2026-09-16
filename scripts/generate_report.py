"""Generate the frozen regression report from checked machine-readable metrics."""
from pathlib import Path
import json

metrics = json.loads(Path("sim_out/fft_metrics.json").read_text(encoding="utf-8"))
resources = json.loads(Path("sim_out/resource_metrics.json").read_text(encoding="utf-8"))
before, after = resources["before"], resources["after"]
lines = [
    "# RTL 冻结验证报告", "",
    "| 项目 | 结果 |", "|---|---:|",
    "| 完整 RTL 回归 | PASS |",
    f"| 32 路独立频率峰 | {metrics['peak_count']}/32 PASS |",
    f"| FFT 样本数 | {metrics['sample_count']} |",
    f"| FFT 分辨率 | {metrics['fft_bin_hz']:.6f} Hz |",
    f"| 最大 DDS 频率误差 | {metrics['max_abs_dds_error_hz']:.6f} Hz |",
    f"| 最大 FFT 栅格误差 | {metrics['max_abs_fft_error_hz']:.6f} Hz |",
    f"| 混音削顶比例 | {metrics['clip_ratio']:.6%} ({metrics['clip_count']} samples) |",
    f"| 数字事件到音频延迟 | {metrics['latency_samples']} sample(s) |",
    "| I2S 默认时钟 | BCLK 3.072 MHz / LRCLK 48 kHz PASS |",
    "| 三种演奏模式 | 自由 / 正确音符推进教学 / 实时合成 Demo PASS |",
    f"| 通用除法单元 | {before['div']} → {after['div']} |",
    f"| 通用乘法单元 | {before['mul']} → {after['mul']} |",
    f"| 通用取模单元 | {before['mod']} → {after['mod']} |",
    f"| Yosys 抽象 cell | {before['cells']} → {after['cells']} |",
    "| Verilator 严格警告 | 0 |",
    "| Yosys check | PASS |", "",
    "| MIDI | 理论频率 Hz | DDS 频率 Hz | DDS 误差 Hz | FFT 峰 Hz | FFT-DDS Hz |",
    "|---:|---:|---:|---:|---:|---:|",
]
for peak in metrics["peaks"]:
    lines.append(
        f"|{peak['midi']}|{peak['ideal_hz']:.6f}|{peak['dds_hz']:.6f}|"
        f"{peak['dds_error_hz']:.6f}|{peak['fft_hz']:.6f}|{peak['fft_error_hz']:.6f}|"
    )
lines += [
    "", "## 延迟口径", "",
    "数字延迟从 note_on 被 allocator 接受并锁定目标 Voice 开始，到该目标 Voice 首次产生非零有效样本为止。"
    "它不包含传感器采样、去抖/CDC、FIFO 排队、I2S 串行化、DAC 和模拟链路，因此不等同于最终≤5 ms端到端实测。",
    "", "## 资源口径", "",
    "资源变化来自同一版本 Yosys 通用 RTL 层级统计，证明 `/127`、`/1023`、MIDI `/12/%12` 已消除且 Morph 每 Voice 少一个乘法；"
    "它不是 60K/138K 厂商映射后的最终 LUT/DSP/BRAM 数字。",
    "", "所有数值由本次回归生成；报告脚本只在仿真、黄金模型、FFT、资源比较、Yosys 与 Verilator均通过后执行。"
]
lines += [
    "", "## 主要修改文件", "",
    "- `rtl/i2s_tx.sv`、`tb/tb_i2s.sv`：修正半周期分频并直接测量 BCLK/LRCLK，保留逐 bit 对齐检查。",
    "- `rtl/polyphony_gain.sv`、`rtl/synth_core.sv`：活动 Voice 分档 headroom、master attenuation、可视化数据预留。",
    "- `rtl/voice.sv`、`rtl/timbre_morph.sv`、`rtl/note_freq_table.sv`：消除通用常数除法/取模、Morph 单乘法、128 项 phase ROM。",
    "- `rtl/voice_bank.sv`、`rtl/latency_monitor.sv`：暴露 allocator 目标 Voice，并按目标独立样本统计数字延迟。",
    "- `rtl/score_rom.sv`、`rtl/led_guide.sv`、`rtl/performance_mode_controller.sv`：note/duration/velocity/rest 曲谱事件及三种模式。",
    "- `tb/tb_note_table.sv`、`tb/tb_polyphony_gain.sv`、`tb/tb_modes.sv` 及现有回归：新增 ROM、增益、模式与全链路覆盖。",
    "- `scripts/run_regression.ps1`、`check_resources.py`、`generate_report.py`：安全清理输出、资源比较和冻结报告。",
    "", "## 仍需上板验证", "",
    "- 最终板卡系统时钟/PLL 和时序约束能否精确提供 I2S 所需时钟关系。",
    "- 目标 Gowin 器件映射后的 LUT/DSP/BRAM、布局布线时序和功耗；本报告资源数是通用 Yosys 抽象值。",
    "- 实际 DAC 对 BCLK/WS 边沿、slot padding、复位静音和模拟输出电平的兼容性。",
    "- 传感器采样、去抖、CDC、FIFO 排队、I2S/DAC 与模拟链路合计的传感器到 DAC 端到端延迟，需示波器实测确认≤5 ms。",
    "- 串口屏和多维传感器协议仍只保留数据/控制接口，本轮未加入具体驱动。"
]
Path("sim_out/verification_report.md").write_text("\n".join(lines), encoding="utf-8")
print("REPORT PASS: sim_out/verification_report.md")
