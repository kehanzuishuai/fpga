# 弦动智音：FPGA 实时多音色电子乐器

当前完整发布：**V21，2026-11-03**。仓库根目录已更新为配套的 FPGA、ESP32-S3 和特雷门琴 UNO 工程。FPGA 使用 11 月 2 日完成综合、布局布线和时序检查的版本；ESP32 使用 11 月 3 日曲谱导入提示与播放确认修订版。

## 工程入口

| 内容 | 入口 |
|---|---|
| 高云 FPGA 主工程 | [yinyue_fashengqi.gprj](yinyue_fashengqi.gprj) |
| FPGA RTL、IP、引脚与时序约束 | [src/](src/)、[integrated.cst](src/integrated.cst)、[integrated.sdc](src/integrated.sdc) |
| ROM、字体与显示初始化数据 | [assets/](assets/) |
| ESP32-S3 完整 Arduino 工程 | [ESP32_FPGA_Music_Controller.ino](firmware/remote_music_ble/esp32/ESP32_FPGA_Music_Controller/ESP32_FPGA_Music_Controller.ino) |
| 手机网页及嵌入工具 | [shouji/](firmware/remote_music_ble/shouji/)、[build_web.py](firmware/remote_music_ble/esp32/build_web.py) |
| 特雷门琴 UNO 完整 Arduino 工程 | [Open_Theremin_FPGA.ino](firmware/theremin/Open_Theremin_FPGA/Open_Theremin_FPGA.ino) |
| 特雷门琴 FPGA 接收与发声模块 | [src/theremin/](src/theremin/) |
| 本次烧录文件、时序报告与校验清单 | [release/v21_20261103/](release/v21_20261103/) |
| 最新多音轨《卡农》 | [MIDI 文件](scores/卡农_最新ESP32_20261103/卡农_多音轨_20261103.mid)、[操作说明](scores/卡农_最新ESP32_20261103/使用说明.txt) |
| 构建与烧录 | [BUILD_AND_PROGRAM.md](docs/BUILD_AND_PROGRAM.md) |
| 接线与协议 | [CURRENT_INTERFACES.md](docs/CURRENT_INTERFACES.md) |

克隆后保留目录结构；FPGA 工程需要 `src/`、`assets/` 和 `impl/yinyue_fashengqi_process_config.json`。Arduino 草图需要同目录的全部 `.h`、`.c`、`.cpp` 文件，不能只复制 `.ino`。

## 系统分工

```text
两块 TTP229 ──> FPGA 32 声部合成 ──┐
                                 ├─> 音频混合/效果 ─> PT8211 + PCM5102A
天线/UNO ─UART─> FPGA 特雷门琴 DDS ─┘           └─> 波形/FFT/HDMI
                      ↑
手机网页/蓝牙 ─> ESP32-S3 ─UART─> 参数、曲谱事件、状态回读
```

UNO 负责天线测量与校准；ESP32 负责手机交互、联网和曲谱缓存；FPGA 逐采样合成声音、调度声部、混音和显示。多音轨 MIDI 传输的是起音与松音事件，音频在 FPGA 内生成。

## 功能与实现

- **32 键、32 复音**：两块 16 键 TTP229 独立接入；音符范围 MIDI 36～96。声部有独立音高和包络，计算与存储资源复用。
- **五种音色**：钢琴用 15 个正弦分音与击槌噪声合成；管风琴用加法合成；简化长笛用基音、少量谐波与气息噪声；吉他用 Karplus–Strong 延迟反馈；钟琴用 FM 合成。
- **DSP 与块 RAM 管理**：钢琴在每声部的分音时隙内复用乘法器；相位、增量和包络参数存于声部 RAM，滑音状态使用块 RAM。辅助音色按四条通道、每通道八个上下文调度；吉他延迟线按 24 位数据打包进块 RAM。
- **三种声源模式**：琴键、特雷门琴、合奏。F15 实体键循环切换五音色，G15 实体键循环切换声源模式；手机可设置并回读实际状态。
- **音色切换**：先淡出、清理旧声部与效果、等待完成，再切换并淡入；单侧淡变约 5.3 ms。切换时已按住的琴键需释放后重新触发。
- **滑音、颤音**：钢琴、管风琴、长笛、钟琴支持 0～100 调节；每声部独立滑音，共用约 5 Hz 颤音 LFO。滑音从前一个接受的音符起步，覆盖 ±60 半音；首音及更大跳音直接使用目标音高。
- **特雷门琴**：UNO 输出连续目标频率、音量和状态；FPGA 平滑参数并以独立正弦 DDS 发声。接收端检测 CRC、序号、校准和传感状态；100 ms 失联淡出，连续三帧有效数据后恢复，合奏中的琴键支路继续运行。
- **手机与曲谱**：Wi-Fi 网页、BLE 控制、32 键映射、MIDI 0/1 与音符 JSON、整曲多轨复调播放、指导分段、事件录音。网页支持“自由演奏／自动演奏／指导模式”。
- **音视频**：标称 48 kHz、内部 24 位；PT8211 输出 16 位，PCM5102A 输出 24 位；1920×1080、30 Hz 视频，包含 2048 点 FFT、波形及状态显示。

功能边界：吉他和特雷门琴不使用本版手机滑音、颤音参数；手机“力度”参数目前仅保存与回读。多轨曲谱合并后统一使用当前选中的音色，不按 MIDI 通道配置不同乐器。手机页面不导入踏板、弯音、音色指令和中途变速。网页整曲传输与指导单旋律分段采用不同数据路径，不能混用。

## 直接使用

1. 下载并解压 [FPGA 烧录压缩包](release/v21_20261103/FPGA_expression.fs.zip)，在 FPGA Programmer 选择其中的 `FPGA_expression.fs`。
2. ESP32-S3 **N32R16V** 使用 [ESP32_autoplay_0x0.bin](release/v21_20261103/ESP32_autoplay_0x0.bin)，完整合并文件烧录偏移 **0x0**；配置为 32MB OPI Flash、OPI PSRAM、huge_app。
3. 特雷门琴使用经典 **Arduino UNO / ATmega328P、16 MHz**，打开并上传 [完整草图](firmware/theremin/Open_Theremin_FPGA/)。首次使用桥接固件需重新校准，详见 [特雷门琴说明](firmware/theremin/README.md)。
4. 连接热点 **FPGA_MUSIC**，密码 **fpga2026**，打开 `http://192.168.4.1`；更新 ESP32 后强制刷新页面。BLE 设备名为 **XDZY-Piano**。

播放《卡农》：选择“琴键”或“合奏”声源及“自动演奏” → 导入 `.mid` → 选择“全部旋律音轨（不含打击乐）” → 点击 **“传入设备”** → 出现 **“整曲已缓存，点击播放”** 后播放。文件只导入手机时，设备仍无曲谱；重启设备后需重新传入。

新《卡农》包含 7 个有声部的音轨，87 BPM，约 5 分 14 秒；合并为 4286 个事件，最多 11 个不同音高同时发声。文件 30,489 字节，已通过最新网页导入、ESP32 解析和 FPGA 整曲播放仿真。

## 接线摘要

以下 FPGA 管脚为封装管脚；Dock 排针按 Pro Dock4071f rev1.2 核对。各模块共地。

| 连接 | Dock / FPGA |
|---|---|
| TTP229 第一块 SCL / SDO | J26 第11 / 9脚，C21 / B20 |
| TTP229 第二块 SCL / SDO | J26 第7 / 5脚，B19 / A17 |
| ESP32 GPIO17 TX → FPGA RX | J26 第12脚，B21 |
| ESP32 GPIO18 RX ← FPGA TX | J26 第10脚，A20 |
| UNO D1/TX → 电平转换 → FPGA RX | J24 第7脚，L17；UNO 5V 逻辑须转换为 3.3V |
| PCM5102A BCK / LRCK / DIN | J24 第11 / 12 / 6脚，C24 / B24 / H15 |
| 音色键 / 声源模式键 / 复位键 | F15 / G15 / K16，低有效 |
| 视频输出 | Dock J11 / DVI A（TX） |

UART 两端均为 **115200、8N1**。TTP229 使用 3.3V 供电及 16 键多键模式；ESP32 使用自己的 USB 供电并共地。板载 PT8211 不需额外接线；SPI/WAV 历史接口不用于当前曲谱播放。

## 构建与验证记录

- FPGA：Gowin **V1.9.12 64-bit**，`GW5AST-LV138FPG676AC1/I0`、Device Version C，顶层 `tang_mega_138k_pro_top`，SystemVerilog 2017。Place=3、Route=2、Maxfan=100、Timing-driven=1、Correct-hold=1。现成 FS 生成于 **2026-11-02 16:19:47 UTC+8**。
- ESP32：Arduino-ESP32 **3.3.10-cn**；FQBN 见 [sketch.yaml](firmware/remote_music_ble/esp32/ESP32_FPGA_Music_Controller/sketch.yaml)，标识 `v21-autoplay-confirm-20261103`。11 月 3 日编译通过。
- 特雷门琴：`arduino:avr:uno`、Arduino AVR **1.8.8**；本次从仓库副本重新编译通过，Flash 26,380 / 32,256 字节，静态 RAM 265 / 2048 字节。

| FPGA 时序项目 | 最差裕量 |
|---|---:|
| Setup | +1.472 ns |
| Hold | +0.001 ns |
| Recovery | +8.464 ns |
| Removal | +0.257 ns |
| Minimum pulse width | +2.893 ns |

Setup/Hold 违规端点均为 0。实际 PnR 占用：Logic 114306/138240、Register 42732/139140、CLS 62113/69120、BSRAM 316/340、DSP 237.5/298；原始报告在 [发布目录](release/v21_20261103/)。

关闭滑音、颤音的 21,911 帧 PCM 与 V20 基线逐字节一致；开启效果的 21,913 帧通过实际声部库、混音、效果和双 DAC 回归。该仿真使用 ROM/PLL 模型、关闭显示、三音和弦及独立松音，不能当作实板 32 键同时发声或端到端延迟测量。48 kHz 的 20.8 μs 采样间隔也不能等同于触摸到扬声器的延迟。

本次发布复核源码与已验收产物的 SHA256，重新编译 UNO，并执行网页和 FPGA 曲谱回归；没有替设备烧录或新增实板性能测量。修改 RTL、约束、IP 或初始化数据后，应重新综合、布局布线和检查时序。

## 版本与来源

- [release/latest/](release/latest/) 只作为当前版本导航；[release/v13_20261024/](release/v13_20261024/) 保留历史 V13 产物。
- `boards/`、`rtl/`、`ref/`、早期 `docs/` 与 `firmware/remote_music/` 为历史或参考资料；当前入口以本 README、根目录 GPRJ 和本次发布目录为准。
- 特雷门琴代码保留 Open.Theremin、WaveHC、Arduino EEPROM 原作者署名和许可证，见 [SOURCES.md](firmware/theremin/SOURCES.md)。仓库中的第三方 IP、数据与资料按各自原有许可管理。
