# FPGA电子钢琴：工程续接记录

更新时间：2026-10-20，UTC+8。本文件用于在同一工程目录中接续工作，不依赖此前聊天记录。所有相对路径均相对于 `D:\gaoyun\piano_v2_audio_fix`。

## 1. 先读这段，再进行任何操作

**2026-10-20 21:53（UTC+8）：当前工程已完成综合、布局布线及五类时序检查，最终归档校验PASS，已生成新FS。没有自动烧录。**

用户明确取消交接后，已复用通过验证的综合网表，以Placement 3 / Route 0完成PnR。Setup +0.105ns、Hold +0.010ns，违例端点均为0；Recovery +6.742ns、Removal +0.341ns、最小脉宽 +3.272ns。最终报告：`docs/REMOTE_MUSIC_RESULTS_20261019.md`；收据：`audit/remote_music_20261019/FINAL_ACCEPTANCE.json`。下文的“用户手动接手/停止”和失败尝试均为历史记录。

新FS：`impl/pnr/ao_0.fs`，SHA256 `e483552fc9993df6e9464790a9ca29d7e8253e02a51002507d05ee2234884e0b`。固件及FS归档：`tests/remote_music_20261019/final_build`。真实接线、Wi-Fi连续传输、模拟输出和主观音质仍待上板确认。

最新用户约束，优先于旧文档中的计划：

1. **ESP32网页UI不得修改。** 最近的临时UI修改已经恢复，当前网页包哈希见下文；不要重新设计界面、改标题、增加提示或改布局。
2. **少做回归及不必要的仿真。** 已通过且依赖未变化的结果复用；发生相关逻辑变化时，只运行必要的针对性检查。
3. **实体32键只发原来的钢琴音色。** 不叠加其他乐器，手机音色选择不得使实体键换音色、淡出或重新触发。
4. 手机五种音色用于MIDI/JSON曲谱：钢琴、管风琴、长笛、吉他、钟琴；WAV保留录音原声。
5. 必须保留32 Voice、FFT、HDMI、PT8211与PCM5102双DAC。屏幕继续保持原第一块16键对应。
6. 不自动烧录FPGA或ESP32。所有既有命令均只编译、仿真或实现。
7. 继续在当前目录修改有效工程，不要只修改测试副本而漏掉GPRJ，也不要修改 `E:\lanya` 原始资料。
8. 不以ROM有参数、PCM非零或数字仿真通过代替主观音质和真实硬件验收。

## 2. 唯一主工程与当前状态

| 项目 | 当前值 |
|---|---|
| 工作目录 | `D:\gaoyun\piano_v2_audio_fix` |
| 主工程 | `yinyue_fashengqi.gprj` |
| 顶层文件 / 模块 | `src/tang_mega_138k_pro_top.v.v` / `tang_mega_138k_pro_top` |
| 硬件 | Tang Mega 138K Pro + Pro Dock |
| 器件 | `GW5AST-LV138FPG676AC1/I0`，版本C |
| 工具 | Gowin V1.9.12 x64；SystemVerilog 2017 |
| 有效GPRJ输入 | 91个；测试平台未加入综合 |
| 最新综合 | 2026-10-20 16:26通过 |
| 当前自动实现状态 | PASS；构建已退出，临时防休眠请求已释放 |
| 当前实现选项 | Placement 3、Route 0、Timing Driven开启、Hold修复开启 |
| 最新完整时序验收 | 五类检查通过，Setup/Hold违例端点均为0 |

主状态收据：`audit/remote_music_20261019/BUILD.json`，`status=PASS`、`synthesis_status=PASS`、`all_timing_checks_pass=true`。`stale_previous_timing_values`仅保留旧失败报告，最新结果读取`worst_slack_ns`。

最新综合网表：`impl/gwsynthesis/yinyue_fashengqi.vg`。

```text
SHA256 = 6ceb8babb23d570ae4b1dcc3744f1ba806b5fcecae836f9a79160de1ed6d6c41
```

综合报告：`impl/gwsynthesis/yinyue_fashengqi_syn.rpt.html`；结构收据：`audit/remote_music_20261019/CURRENT_SYN_STRUCTURE.json`。

## 3. 工程已实现的功能

### 3.1 两块实体键盘与钢琴

- 两块独立16键TTP229模块，默认逻辑音高为MIDI60～75、76～91，共32个不同音高。
- 物理左右键序仍需实际逐键确认。默认逻辑顺序不等于已经验证所有实体键的排列；保留手机原有32键唯一音高映射功能。
- 实体键固定使用原钢琴32 Voice，不叠加辅助音色。
- 屏幕保留第一块16键对应，FFT、HDMI、双DAC仍在工程内。
- 原钢琴参数、音源、FX及早期音阶/尾音/显示修复均保留，不要从旧备份整套覆盖回来。

### 3.2 手机与ESP32

- 沿用ESP32-S3 Wi-Fi热点和原手机网页；此次方案不是蓝牙传输。
- 原始资料在 `ref/lanya_20261019`，工作副本在 `firmware/remote_music`。
- 热点 `FPGA_MUSIC`，密码 `fpga2026`，网页 `http://192.168.4.1`。
- UART 115200传控制与曲谱事件；SPI Mode0、4MHz传WAV数据，带CRC、序号、重复包处理、缓冲反压。
- 手机解析SMF MIDI格式0/1、PPQN和兼容JSON音符谱，按32事件分段交给FPGA计时与合成；当前仍为单旋律曲谱方案，不要宣称完整复调MIDI文件由FPGA解析。
- 音色协议ID：0钢琴、1管风琴、2长笛、3吉他、4钟琴。
- 曲谱开始需要松开琴键且音源空闲；曲谱独占音符事件，停止/自然结束清理后恢复钢琴并重新接入仍按住的实体键。曲谱播放中更改音色会停止当前曲谱，新选择用于下一次播放。
- WAV独立播放，可与实体钢琴混音，不占用合成Voice；只播WAV时VOICE=0正常。主音量作用于混音结果。

### 3.3 FPGA WAV解码

- 手机HTTP上传原始WAV，ESP32经SPI转发，FPGA解析RIFF、PCM解码并输出立体声。
- 支持PCM格式码1、16/24位、单/双声道、44.1/48kHz，共8种组合；44.1kHz在FPGA线性转换为48kHz。
- 支持未知块、奇数填充、边界/格式错误检测、CRC/重传、停止及断流处理。
- 不支持MP3、浮点WAV、WAVE_EXTENSIBLE；不要擅自扩大支持声明。
- 已修复ESP32 WebServer二进制零字节截断：使用定长RAW回调，头部 `X-WAV-Session`、`X-WAV-Offset` 携带会话及偏移；不能退回 `arg("plain")` 接收二进制。

## 4. 关键代码与本轮修改原因

| 文件 | 职责 / 注意点 |
|---|---|
| `src/keyboard/ttp229_keyboard_pair.sv`、`keyboard_state_mapper.sv` | 两组独立键盘读取及键位映射 |
| `src/ttp229_event_bridge.v` | 键状态转Note事件，注意32键位宽 |
| `src/remote/remote_control.sv` | 实体钢琴固定为0；内部`selected_instrument`保留手机曲谱选择；`score_owned`等状态管理交接 |
| `src/remote/control/wifi_control.sv`、`wifi_score_player.sv` | 原有控制协议、曲谱调度 |
| `src/remote/wav_spi_stream.sv` | SPI收发、缓冲、序号/CRC和状态包 |
| `src/remote/wav_pcm_player.sv` | RIFF/PCM解码、边界校验、重采样 |
| `src/remote/wav_remote.sv`、`stereo_master.sv` | 跨时钟立体声数据、混音和主音量 |
| `src/instruments/gongyong/yinse_aux_bank.sv`、`yinse_aux_voice.sv` | 32个辅助Voice上下文；4个共享算术引擎，每个轮询8路；32份独立状态与64块吉他KS BSRAM保留 |
| `src/display/visual_xy_plot.sv` | 成对XY去均值、共同缩放和连线；最近增加峰值比较流水级 |
| `src/integrated.cst`、`integrated.sdc` | 实际管脚与时序约束，不随意放宽 |
| `src/keyboard_debug.rao` | 保留GAO，采样深度此前由4096降为1024 |
| `firmware/remote_music/esp32/ESP32_FPGA_Music_Controller/` | 当前ESP32工程、WebServer上传接收、UART/SPI工作线程及嵌入网页 |

辅助音色采用共享算术引擎节省资源，但没有减少逻辑Voice数。已有逐帧精确等价检查和实际Gowin原语通道检查；不要因看到4个运算器就误判只有4复音或改回32套大算术模块。

### 最近两处针对时序路径的RTL修复

1. `visual_xy_plot.sv`：将`max(abs_x,abs_y)`与`max(candidate,peak)`拆成两拍，新增`PEAK_MAX`及`candidate_r`。原17位两次串联比较路径过长。10张参考位图、模式和缩放完全一致，每帧额外512个像素时钟，仍在消隐预算内。
2. `wav_spi_stream.sv`：状态包22字节CRC拆成前11字节和后11字节，并同步延迟对应body，保证状态/CRC一致。状态快照约滞后40ns，不改变SPI字节协议。8次真实4MHz状态包短检查已通过。

更早的WAV时序修复也已在生产源码中：RIFF块边界加法与比较拆阶段、缓存末帧边界，块长除法改32周期精确商/余数；不能再次运行旧“候选推广脚本”重复替换。

## 5. 时序/实现失败的准确时间线

| 实现 | 结果 | 证据 |
|---|---|---|
| 两处最新流水修复之前 | 已生成FS，但Setup −0.554ns/27端点、Hold −0.046ns/2端点，未验收 | `audit/remote_music_20261019/routed_setup_negative_0554/` |
| 最新RTL完整综合+Place4/Route2 | 综合通过；2026-10-20 16:43 PnR收尾报`PR0004`，同时显示0个未布通网络，没有新FS/TR | `audit/remote_music_20261019/routing_zero_unrouted_abort/` |
| 同一最新网表，Place4/Route1 | 仅PnR重试，无重新综合；约运行59分钟后，17:45按用户要求停止，长时间停留在Routing Phase0之后 | `tests/remote_music_20261019/out/retime.log`、主`BUILD.json` |

旧负裕量路径主要是XY峰值比较和SPI状态CRC；上述源码已修复，但**尚无新整机时序报告证明问题已经解决**。旧Hold路径包括显示BCD输入及字体RAM地址，仍需在新报告中检查。

最近失败实现的资源参考（不是成功验收）：Logic 103458/138240（75%），CLS 61314/69120（89%），BSRAM 296/340（88%），DSP 186/298（63%），逻辑锁存器0。资源与布局相关，不能保证换策略一定更快或一次通过。

约束边界：保留50MHz板时钟、12.288MHz音频、27MHz视频参考、371.25MHz串行及74.25MHz像素；保留视频复位相位和像素Hold不确定度0.150ns。不得通过降频、删除功能或放宽检查伪造通过。此前工具有GAO `tck_pad_i`未建钟及50MHz通用路由提示；既有SDC检查不等于外部JTAG及实际SPI线缆验收。

## 6. 产物版本：尤其不要拿错FS

- 此前停止时根目录FS/TR曾为旧版本；现已由21:53的新鲜实现报告和FS更新，哈希见顶部及最终收据。
- 最新VG哈希见第2节，生成时间16:26；现存根目录FS/TR来自更早的16:11实现。
- 另有此前已验收的纯32键版本：`tests/keyboard32_20261019/final_build/ao_0.fs`，SHA256为 `18427350a26750067ee9cb54e1ea1e6ceff67adb1a347475a0f79c1b88ae6bfa`。**它不包含本轮手机/WAV功能，不能当最新版交付。**
- 后续只有新实现成功、报告/FS确为本次生成、源文件和产物哈希一致，才可建立本轮最终验收和归档。

ESP32固件编译已通过，记录在 `tests/remote_music_20261019/esp32/esp32_compile.json`，二进制在同目录 `esp32_build`。目标为通用ESP32-S3，默认4MB、PSRAM未启用；手动下载前应匹配实际板型。

不得改动的恢复后UI包：`firmware/remote_music/esp32/ESP32_FPGA_Music_Controller/web_page.h`。

```text
SHA256 = 5428444eaa7aad9c41b0537b720fe516ef80e1186605d6154d6dbf38bfe253cf
```

## 7. 验证证据与复用规则

汇总：`audit/remote_music_20261019/TARGETED_VALIDATION.json`。下文的`out/`指 `tests/remote_music_20261019/out/`；表中省略`out/`前缀的测试收据也在该目录。

| 检查 | 证据 / 范围 |
|---|---|
| 最新VG钢琴Loader | `out/gate_loader32/RESULT.json`；32音、12800字、零差异；绕过键盘/分配器的隔离参数检查 |
| XY流水改动 | `out/XY_TIMING_CHECK.json`、`xy_timing.log`；10张位图精确一致、预算满足；不是完整HDMI整帧重跑 |
| SPI CRC流水改动 | `out/spi_timing.json`、`spi_timing.log`；8次4MHz状态传输、独立CRC、变化字段一致、CS内稳定 |
| 实体键固定钢琴 | `out/audio_top.json/.log`；两块真实TTP协议BFM、全部手机选择下32键仅钢琴及DAC核对 |
| 曲谱/实体键交接 | `out/score_top.json/.log`、`control.json/.log`；曲谱结束NoteOff、清理、恢复钢琴及键重接入 |
| WAV八格式/异常/双DAC | `wav_formats`、`wav_errors`、`wav_dac`对应JSON/日志 |
| 实际固件本机链路 | `native_wav`、`native_replay`、`native_http`对应JSON/日志；不等于真实无线验收 |
| 辅助音色等价 | `share_equiv`、`aux`；32上下文逐帧检查 |
| 辅助音色门级 | `GATE_AUX_NETLIST.json`、`gate_aux_1..4`；实际映射的一个8上下文共享通道，每种音色512帧；不能说成完整32路门级仿真 |
| 原钢琴与双DAC保护 | `preserve.json/.log` |

多数既有收据记录了全部源码哈希，因此会列出与测试无关的后续变化。当前允许复用的后续变化只有XY峰值与SPI状态CRC两处，均有独立新检查；除此之外应按实际依赖判断，不能简单去掉哈希断言。

**两项明确停止，不能宣称本轮通过：**

- `out/system.json` 为 `STOPPED_PER_USER`，`system.log`是部分运行。先前完成的原始收据另存在 `audit/remote_music_20261019/prior_completed_system_receipt.json`。只能在依赖匹配的范围内复用旧显示证据。
- `out/wav.json` 为 `STOPPED_TO_LIMIT_SIMULATION_PER_USER`。较长音频重播已停止，原收据归档为 `audit/remote_music_20261019/wav_before_stopped_rerun.json`。解码未改，八格式/DAC旧结果复用；本轮新SPI改动用短检查覆盖。

Icarus性能说明：`run.py`将辅助音色超宽切片总线变成独立等宽连线生成 `out/yinse_aux_bank_netview.sv`，仅改变仿真连接表示，不改变算术/寄存器/状态。四处替换和哈希在 `BANK_SIM_VIEW.json`。GPRJ使用原生产源码；不要把该视图当作生产替代文件。

## 8. 当前继续工作的顺序

1. 用户已明确取消交接并要求继续完成。已核实无残留高云进程，最新综合输入和网表哈希有效，复用同一网表执行Placement 3 / Route 0。
2. `RESUMED_EVIDENCE_CHECK.json`重新核对15个已完成测试的源码依赖、手机脚本、固件及网页哈希，不重复运行仿真。仅当后续相关逻辑变化时补必要检查。
3. 对用户提供的新实现结果，先检查文件时间、哈希、路由是否成功及是否生成新FS/TR，再分析最差路径。不要复述旧−0.554/−0.046ns为新结果。
4. 若用户重新明确授权自动实现：仅PnR选项变化可复用已验证VG；RTL/综合选项变化才重新综合。改动前保存来源和失败证据，按相关依赖选最小必要检查。
5. 完成时序验收：Setup/Hold违例端点均为0，Setup/Hold/Recovery/Removal/最小脉宽五类裕量均非负，约束覆盖合理，源/输出来自同一次有效实现。
6. 之后再更新本轮最终结果报告、FS/固件归档和首页，明确未进行自动烧录及真实硬件/主观音质仍待确认。
7. 实板验收在用户授权的手动烧录后进行：两块键盘逐键音高、32键钢琴独立性、手机曲谱音色、WAV立体声/停止/断流、双DAC、FFT、HDMI及长时间Wi-Fi连续性。

### 脚本使用陷阱

- `tests/remote_music_20261019/build.py` 会执行完整综合+PnR，耗时，不能拿它当状态查询。
- `retime.py` 会立即启动PnR，现在要求显式提供 `--archive <新目录名> --place <0..4> --route <0..2>`，归档名不可重复。
- 脚本先验证全部旧输入/网表哈希并归档前次收据、产物、Tcl、过程配置及日志，再按参数生成PnR选项并记录新Tcl哈希；源文件/网表不得在构建过程中变更。完成时从真实过程配置保存选项，检查 `BUILD_OPTIONS.json`。
- 不要直接编辑已记录的Tcl再启动，否则输入一致性检查会拒绝；应使用上述参数，不能绕过源码新鲜度验证。
- 手动Gowin运行不会自动更新Python的 `BUILD.json`。收集成功手动结果时，应建立有原始日志、时间、输入/产物哈希的真实新收据；不能直接把旧状态改成PASS。
- `finalize.py`已完成并PASS，核对源/产物哈希、固件/UI、针对性结果、32个钢琴Voice/32个辅助上下文、4个共享运算引擎、64块KS RAM、91个有效输入及378行管脚表，生成最终归档和报告。若后续改RTL，需维护受保护文件及依赖关系，不可为通过脚本而删除断言。
- `promote_wav_pipeline.py`、`repair_remaining_paths.py`、`share_aux_arithmetic.py`等是已执行过的一次性修改脚本；`wav_timing_candidate.py`依赖旧源码状态。不要批量重跑或再次覆盖当前代码。
- 不要默认重启 `regress_latest.py --parallel`、整帧显示或全部辅助音色门级长测试。

## 9. 必要时使用的工具路径

以下是本机位置，换机器要重新配置；此处列路径不代表现在应该执行。

```powershell
$TaskPython = 'C:\Users\Yan Guyao\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
# 需要运行Python脚本时使用：& $TaskPython -X utf8 -B -u <脚本路径>
```

- Gowin：`C:\Gowin2\Gowin_V1.9.12_x64\IDE\bin\gw_sh.exe`。
- Icarus：`D:\gaoyun\piano_v2\codex_test\tools\iverilog\bin\iverilog.exe`、`vvp.exe`。
- 该Windows环境的Icarus/g++/Arduino在沙箱内曾发生DLL加载问题；用户此前允许只编译/仿真在沙箱外运行，不允许烧录。新环境应按实际权限处理，不能误诊为RTL错误。
- ESP32隔离工具链：`tools/toolchains/arduino/`；编译入口 `firmware/remote_music/esp32/compile.py`。
- `tools/stop_remote_job.ps1`仅按当前工程驱动父子关系停止任务，避免全局按进程名杀掉用户的其他Gowin进程。
- `tools/keep_remote_build_awake.ps1`只在特定任务期间临时阻止自动休眠；本次停止后已释放，不需要额外调整系统电源计划。

## 10. 接线与历史资料入口

所有信号3.3V、共地，ESP32可USB供电；不要将5V接入FPGA信号。

| 功能 | FPGA / 排针 | ESP32-S3 |
|---|---|---|
| 第一块键盘SCL / SDO | C21 / J26.11；B20 / J26.9 | — |
| 第二块键盘SCL / SDO | B19 / J26.7；A17 / J26.5 | — |
| UART输入FPGA | B21 / J26.12 | GPIO17 TX |
| UART输出FPGA | A20 / J26.10 | GPIO18 RX |
| SPI SCK | L17 / J24.7 | GPIO12 |
| SPI MOSI | E25 / J24.9 | GPIO11 |
| SPI CS | H14 / J24.5 | GPIO10 |
| SPI MISO | D25 / J24.10 | GPIO13 |
| GND | J24/J26.3或.4 | GND |

参考官方Dock PDF：`ref/hardware/Pro_Dock_4071f_official.pdf`。完整说明见 `docs/REMOTE_MUSIC_20261019.md`；供人工操作的简版见 `docs/MANUAL_GOWIN_HANDOVER_20261020.md`。

历史音源与显示要求仍有效，但旧文档中的“下一步”及旧FS不应覆盖本文件最新状态：

- 44音源要求为MIDI48～91，比较A=48～79与B=60～91；不能只验证60～75或非零PCM。相关报告：`docs/SOUND_SOURCE_44_NOTE_RESULTS.md`、`SOUND_SOURCE_32KEY_ACCEPTANCE.md`、`NOTE_GAIN_CALIBRATION_20261018.md`，测试与WAV在 `tests/range44_20261018/`。
- 尾音/VOICE/PEAK及录音问题：`docs/NATURAL_TAIL_FIX_20261018.md`、`VOICE_PEAK_ZERO_ANALYSIS.md`、`RECORDING_SYNTHESIS_FIX_20261018.md`。
- 显示及李萨如：`docs/DISPLAY_UPGRADE_16KEY_20261018.md`、`LISSAJOUS_VIDEO_FIX_20261018.md`。
- 32键及原管脚验收：`docs/KEYBOARD32_20261019.md`、`audit/keyboard32_20261019/FINAL_ACCEPTANCE.json`。

同机交接时把本文件路径交给下一模型即可。异机迁移至少保留GPRJ、`src`、`firmware`、相关`ref`、`tools`配置、`tests`验证入口与收据、`audit`来源证据，以及当前综合网表/报告和过程配置；仅复制这份README无法继续工程。外部Gowin、Icarus和运行时路径需重新配置。

## 11. 历史交接说明

此前的手动交接安排已被用户最新要求撤销，继续由当前模型完成工程。本文件保留历史路径和证据；最终完成状态以新鲜实现报告和 `FINAL_ACCEPTANCE.json` 为准，不把旧FS、旧TR或中断测试当作当前版本通过证据。
