# 多音色独立模块（yinse）

本轮只在 `D:\fpga26\yinse` 新增或修改文件。现有 `src`、主工程 `.gprj`、管脚、PLL、键盘读取、钢琴核心、DAC 和显示工程均未修改。

这里是可独立仿真的多音色模块包，不是已经接好按键或已经下载到板子的工程。原钢琴保持在 `src` 中。本包的 ID 0 表示原钢琴，不包含另一套钢琴音源。

## 目录

| 目录 | 职责 |
|---|---|
| anjian | 两级同步、稳定按下/松开消抖、单次按下事件 |
| qiehuan | 上一个/下一个编号、切换屏障、淡出/淡入、控制层封装 |
| yushe | 乐器编号、包络增量、建议效果参数 |
| guanfengqin | 九音栓比例、权重、超奈奎斯特分音静音 |
| jianhuachangdi | 简化长笛三分音配置 |
| jita | KS 环形 RAM、噪声激励、损耗反馈和全通调音 |
| zhongqin | 一对 FM 算子的频率比配置 |
| gongyong | 共享声部调度、包络、正弦表、音高/调音表、辅助复音组、PCM 选择 |
| xianshi | 当前生效音色的 16 字节 ASCII 名称及忙状态 |
| sim | 独立测试、数学表生成、报告和试听音频 |

新增的三个目录为 `zhongqin`、`gongyong`、`sim`。全部模块使用 `yinse_` 前缀。

## 当前音色及参考

固定顺序：`0 PIANO → 1 ORGAN → 2 FLUTE → 3 GUITAR → 4 FM BELL → 0`，上一个按键反向循环。

| 音色 | 参考 | 本包实现 |
|---|---|---|
| 钢琴 | 原 src + AMY | 不修改、不复制钢琴；PCM mux 满增益时逐位透传输入 |
| 管风琴 | SynthoWheel + vibeboard | 九个音栓比例，持续包络；复用一个正弦读取/分音调度器 |
| 简化长笛 | vibeboard + STK | 三个分音、缓起音、少量噪声、5 Hz 轻微颤音；不是管道物理模型 |
| 木吉他 | htfab/ks-guitar + AMY | 环形 RAM、噪声拨弦、二抽头损耗滤波和一阶全通小数延迟校正 |
| FM 钟琴 | STK TubeBell + russell-merrick/fpga-synth | 一对算子，调制比约 sqrt(2)，独立调制深度衰减；不是完整 STK 四算子模型 |

精确来源和代码位置见 [SOURCES.md](SOURCES.md)。RTL 是按上述算法思路编写的独立定点实现，没有整份复制第三方顶层、时钟或 DAC。
这些名称是设计目标，音色是否像真实乐器还需要试听调参。

## 独立验证

```powershell
# Python 需有 NumPy；Icarus Verilog 和 Verilator 需在 PATH 或通过变量指定。
$env:FPGA_IVERILOG = 'D:\fpga26\bin\iverilog.exe'
$env:FPGA_VVP = 'D:\fpga26\bin\vvp.exe'
D:\anaconda\python.exe -B D:\fpga26\yinse\sim\run_tests.py
```

所有输出位于 `sim/out`。`report.md` / `report.json` 只有完整通过后才标记 PASS。
测试包括按键、切换屏障、钢琴选择口透明性、音高、频谱、复音、松键释放、越界音符、复位、严格 lint 和 Yosys 通用 RTL/存储结构检查。
通用结构检查需要 Yosys 或 yowasp-yosys 在 PATH，也可设置 FPGA_YOSYS。
`audio_*.wav` 和 `poly_*.wav` 是 RTL 产生的试听样本，不是被 FPGA 播放的乐器录音。
`generate_tables.py` 只在开发阶段生成数学正弦表及音高/调音常量，硬件运行不需要 Python。

## 接口契约

### 音频时钟与数值

- 全部状态运行在同一个音频 `clk` 上，`sample_tick` 为一个周期的采样使能；不把 LRCK 当逻辑时钟。
- 当前常量仅用于 **48 kHz** 采样率，名义时钟 **12.288 MHz**，每帧 256 个时钟。不是任意采样率模块。
- PCM 为有符号 24 位，约定满量程范围 -8388608..8388607；单声部增益留有余量。
- 音高表支持 **MIDI 36..96**。越界音符会被接受后拒绝并置 `rejected`，避免上游一直等待；不会随意截断音高。
- 新增正弦表为 256 点 Q1.15，阶梯查表及 FM 可能产生杂散。谱图是数字验证，不等于模拟音质验证。

### yinse_aux_bank：辅助复音

默认 16 个独立声部，可设为 1/2/4/8/16/32。每个声部保存自己的乐器、音高、相位、包络和 KS 状态。
管风琴、长笛和钟琴共用声部内部的振荡器与调度逻辑，吉他有单独环形 RAM；没有复制四套 16 声部组。

输入使用 `event_valid && event_ready` 握手。`event_note_on=1` 且力度 0 等价于松键；力度最大限制为 127。
上游等待 `event_ready` 时必须保持事件字段。辅助组只接 ID 1..4，钢琴 ID 0 由原 src 接收。
同音重复按下优先重触发已有声部，空闲声部优先，满载时循环选择可用声部。
**满载抢占目前为直接重触发，不保证无点击声**；第一版切换淡出与声部抢占是两件事。

`all_notes_off` 清空辅助声部、输出和诊断状态，但不清 RAM；下次拨弦先初始化需要的地址。
KS 初始化期间该声部不 ready，但其他声部可接事件。默认 RAM 长度 1024，最慢支持音符约需 734 个初始化时钟。
`MAX_DELAY` 可以减小，但必须仍覆盖音高表最大长度，否则相关音符置 overrun 并不发声。

`pcm_valid` 在每个 sample_tick 后产生脉冲，`pcm` 锁存上一帧已完成的声部输出，具有固定的帧级延迟。
它是**辅助组内部样本有效信号，不等于现有 DAC 锁存脉冲**。未来接入应保留现有输出捕获关系，再验证端到端延迟。
当前采用固定 `1/VOICES` 混音衰减，减少多音削顶并避免随着按键数量改变响度；单音较轻，可后续校准整体增益。
`overrun_mask` 和 `clipped_mask` 是粘滞诊断，all_notes_off 或复位清除。

### yinse_controls：按键及切换

按键默认低有效，默认消抖 122880 音频时钟（名义 10 ms），完整松开后才重新接受一次按下。
默认淡出和淡入各约 240 个采样（5 ms）。复位直接恢复 ID 0 钢琴、满增益。
两个稳定按键同时按下不改变目标；转换中的额外点击更新最新目标，允许中间音色被合并跳过。

切换步骤：

1. `requested_id` 改变，阻止新 Note On，并请求清理旧队列。
2. 在 sample_tick 边界淡出到零。
3. 等待 `keys_down==0` 且 `loader_busy==0`；保持静音，不超时强行提交。
4. 提交最新编号，发出 `committed`、`clear_aux` 和 `flush_events`。
5. 新音色提交且清理脉冲结束后，淡入期间也允许新 Note On；其声音随增益渐入。原来按住的琴键必须松开再按。不要额外用 switching 屏蔽淡入期间的按键。

**block_events 应用于阻止新 Note On；键盘状态采集和旧音符 Note Off 仍需继续处理。**
否则显示保持“按住”、钢琴迟迟得不到松键事件，切换屏障可能无法结束。
`keys_down`、`loader_busy`、按键控制及选择音色必须位于同一音频时钟域；其他时钟域输入须先做一致的 CDC 接口。
根 synth_top/synth_event_frontend 的外部 event_ready 表示输入 FIFO 能接收事件，不表示钢琴加载器空闲。切换控制需要真正的 ld_busy，或 frontend 内部 core_ready 的反相；不能从顶层 event_ready 推断加载完成。

`flush_events`、`clear_aux` 是请求脉冲，本轮没有接到原工程：

- flush 不能复位 PLL、DAC 或整个 synth_top。
- clear_aux 只接辅助组 all_notes_off。
- 提交时必须另外清理旧钢琴声部，且保证加载器已经空闲。原 synth_core 尚无通用运行时 all_notes_off 输入，需要下一轮明确增加最小接口。
- 音色切换需要处理混响/音板残留状态；本包没有假装已经清理原 piano_fx 的内部延迟 RAM。

### 预设、PCM 选择与显示

`yinse_preset` 输出包络步长与建议 fx_ctrl。辅助声部读取包络，效果参数目前只是元数据，**没有加入第二套效果器**。
钢琴建议 fx_ctrl 与现有 Stage 3 保持一致；其他乐器关闭钢琴音板，混响和软限幅可继续使用。
实际效果切换及状态清理留给下一轮集成。

`yinse_audio_mux` 以 current_id 选择原钢琴或辅助 PCM，并应用淡入淡出增益。gain=65535 时钢琴逐位透明。
此模块只处理数值，要求两个输入已按未来公共捕获边界对齐；没有改动任何 DAC 发送时序。
`yinse_display_info` 输出 ASCII 名称，左侧字符在最高字节。显示 current_id，而不是尚未生效的 requested_id。
它不是像素/TMDS 模块，应接入现有文字绘制层。
若文字绘制位于像素时钟域，应把音色编号与忙状态经现有快照/握手接口一起传过去；不要直接异步读取多位编号，也不要逐位独立同步后拼接。

数值音频测试用每采样16个逻辑时钟加速仿真；采样率仍按48000个采样/秒分析。这不是目标器件时序结论。
另有每种音色16声部、每采样256个时钟的预算检查，检查计算完成与样本状态；目标 Fmax 仍需 Gowin 布局布线验证。

## 下一轮接入现有 src 的边界

本轮不自动加入主 `.gprj`，不分配两个按键的实际管脚。

下一轮应逐项确认：

1. 现有板级顶层增加两个经原理图确认的用户按键输入，并连接 controls。
2. 复用已有音符输入/FIFO；切换期间仅阻止新 Note On，保证旧 Note Off 可送达。增加有明确优先级的 FIFO 清理接口。
3. 把 event_ready 路由到当前音源；为钢琴添加 loader_busy/安全 all_notes_off 的最小接口。
4. 把原钢琴输出与辅助输出按实际 DAC 捕获沿对齐；满增益选择钢琴时，必须重新做原 PCM 逐样本回归。
5. 原 PT8211 / PCM5102A / PLL 和视频时序保持原结构。显示从最终被 DAC 捕获的混音采样取数。
6. 合并音色名称到原显示；切换效果状态时验证旧尾音不回流。
7. Gowin 综合、映射和布局布线后核对 DSP、BSRAM、Fmax、CDC 及 IO，再上板。

16 个 KS RAM 的原始存储约 16×1024×24 = 393216 bit（48 KiB）；这不是 Gowin BSRAM 最终计数。
乘法器和 ROM 的映射也未在目标器件验证。不能仅凭 RTL 仿真确认加入现有 32 钢琴声部后一定满足资源预算。
尚未进行原钢琴与辅助源的端到端集成，也没有实物按键或声音验证。

## 资源与完整回归追加审计

本轮的汇总位于 [sim/audit/README.md](sim/audit/README.md)，机器可读结果为 sim/audit/summary.json。yinse完整回归42条结果通过、旧rtl与板级六套回归通过；当前src仍有零力度NoteOn松键失败和严格lint诊断，整套状态为OPEN_ISSUES。资源评估已计入当前32钢琴、16辅助和既有显示等，但用户确认未安装Gowin，实际器件映射/时序按要求跳过，不能据此承诺资源必定满足。
