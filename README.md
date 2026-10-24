# Tang Mega 138K Pro 电子钢琴 · V13

更新：2026-10-24。本仓库根目录现在是 **V13 FPGA工程**，配套ESP32-S3代码为 `firmware/remote_music_ble`。原Wi-Fi/WAV版本保留在Git历史和 `firmware/remote_music`，不作为本版固件入口。

## 快速入口

| 内容 | 位置 |
|---|---|
| 高云工程 | [yinyue_fashengqi.gprj](yinyue_fashengqi.gprj) |
| FPGA源代码、IP、约束及GAO配置 | [src/](src/) |
| 字体、背景等初始化数据 | [assets/](assets/) |
| 最新FPGA烧录文件 | [release/latest/ao_0.fs](release/latest/ao_0.fs) |
| 最新ESP32-S3主程序 | [ESP32_FPGA_Music_Controller.ino](firmware/remote_music_ble/esp32/ESP32_FPGA_Music_Controller/ESP32_FPGA_Music_Controller.ino) |
| ESP32使用说明 | [README_BLE.md](firmware/remote_music_ble/README_BLE.md) |
| 编译好的ESP32固件及校验值 | [release/latest/](release/latest/) |
| 实际时序报告 | [yinyue_fashengqi.tr](release/latest/yinyue_fashengqi.tr) |
| 实际资源及管脚报告 | [yinyue_fashengqi.rpt.txt](release/latest/yinyue_fashengqi.rpt.txt) |
| 原始构建收据 | [FPGA_BUILD.json](release/latest/FPGA_BUILD.json) |
| 发布清单及输入哈希 | [RELEASE.json](release/latest/RELEASE.json) |

复制或克隆时保留工程相对目录。GPRJ是文件清单，必须和 `src/`、`assets/`、`impl/yinyue_fashengqi_process_config.json`一起使用。

本机发布源为 `D:/gaoyun/piano_v2_audio_fix/branches/v13_20261024`，源目录未移动；GitHub发布副本将该分支放在仓库根目录。手机App旧记录位置 `C:/fpga/piano_app` 本次检查不存在，App源码/安装包未包含在此次发布中。

## 当前功能

- 两块独立16键TTP229，32个逻辑键，默认MIDI60～91；实体琴键固定使用32 Voice钢琴，不叠加其他乐器。实际左右顺序按模块与映射确认。
- 手机曲谱兼容MIDI/音符JSON，可选钢琴、长笛、吉他、管风琴、钟琴五种合成音色。
- ESP32-S3蓝牙App为主、Wi-Fi网页备用；ESP32与FPGA使用UART。
- HDMI/DVI、32键状态、指导模式、FFT频谱、波形、李萨如图、板载PT8211与外接PCM5102A双DAC。
- V13增加音符装载器流水化及实体按键事件录音；录音包含On/Off、音高、力度和时间，不是麦克风或PCM录音。FPGA缓存64条事件，需要及时读取，溢出有标志。
- **V12起已移除预录WAV播放**，SPI端口保留但不用于本版音乐传输。旧文档的SPI/WAV说明属于历史版本。

## 高云构建与下载

- 工具：Gowin V1.9.12（64-bit），GowinSynthesis，SystemVerilog 2017。
- 器件：`GW5AST-LV138FPG676AC1/I0`，Device Version C。
- 顶层：`tang_mega_138k_pro_top`，文件 [tang_mega_138k_pro_top.v.v](src/tang_mega_138k_pro_top.v.v)。
- 约束：[integrated.cst](src/integrated.cst)、[integrated.sdc](src/integrated.sdc)。
- 已通过构建：Place=3、Route=0、Clock route order=0、Timing driven=1、Correct hold=1、Replicate=0；见 [工程配置](impl/yinyue_fashengqi_process_config.json)。

打开仓库根目录GPRJ修改和构建。发布包不含个人 `.gprj.user` GUI缓存或大型布局数据库；使用现成FS时，在Programmer中手动选择 `release/latest/ao_0.fs`。若从工程入口提示 `Bitstream file does not exist`，不要误选旧FS：直接用Programmer选择上述文件，或完成一次当前源码的构建后使用生成的 `impl/pnr/ao_0.fs`。

修改RTL、资源或约束后必须重新综合、布局布线和检查实际STA；原FS不会自动包含修改。`SRAM Program`临时加载断电不保留，Flash固化由用户在整机验收后决定。本次发布没有执行任何下载。

## 已完成的时序和资源检查

完整构建 `v13_p3_r0` 于2026-10-24 14:04完成。Setup/Hold违规端点均为0，全部五类时序通过。

| 时序项目 | 最差裕量 |
|---|---:|
| Setup | +0.164 ns |
| Hold | +0.003 ns |
| Recovery | +6.263 ns |
| Removal | +0.378 ns |
| Minimum pulse width | +3.128 ns |

Hold余量很小；修改源码、约束或设置后须重新验证，不能把本次结果套用到新版本。

| 资源 | 使用量 / 总量 |
|---|---:|
| Logic | 93,875 / 138,240（68%） |
| Register | 36,452 / 139,140（27%） |
| CLS | 57,907 / 69,120（84%） |
| BSRAM | 308 / 340（91%） |
| DSP | 217 / 298（73%） |

FPGA FS SHA256：`bec2b041c230e20e19b0252a7d61dce7b9a9eed0a92b03fee85701e476be1377`。其他文件见 [SHA256SUMS.txt](release/latest/SHA256SUMS.txt)。

## 接线

按Pro Dock4071f rev1.2排针号及实物丝印接线。C21等是FPGA封装管脚，不是排针序号。信号为3.3V逻辑，所有模块共地。

| 模块端 | Dock位置 | FPGA管脚 |
|---|---|---|
| 第一块TTP229 SCL / SDO | J26第11脚 / 第9脚 | C21 / B20 |
| 第二块TTP229 SCL / SDO | J26第7脚 / 第5脚 | B19 / A17 |
| 两块TTP229 VCC / GND | J26第1或2脚（3.3V）/ 第3或4脚 | — |
| ESP32 GPIO17 TX → FPGA RX | J26第12脚 | B21 |
| ESP32 GPIO18 RX ← FPGA TX | J26第10脚 | A20 |
| ESP32 GND | J26第3或4脚 | — |
| PCM5102A BCK / LRCK / DIN | J24第11脚 / 第12脚 / 第6脚 | C24 / B24 / H15 |
| PCM5102A GND | J24第3或4脚 | — |

两块琴键使用各自独立SCL/SDO，并配置为16键/多键模式。ESP32用自己的USB供电并接共地线，UART **115200、8N1**；本版无需连接SPI四根线。外接DAC的VIN电压及格式/静音跳线按具体模块确认。板载PT8211无需杜邦线，屏幕接Dock **J11 / DVI A（TX）**输出口。

## ESP32-S3使用

复制整个 [ESP32主程序目录](firmware/remote_music_ble/esp32/ESP32_FPGA_Music_Controller/)并打开 `.ino`，保留同目录所有头文件。

- 蓝牙设备名：`XDZY-Piano`。
- 备用Wi-Fi热点：`FPGA_MUSIC`，密码 `fpga2026`，网页 `http://192.168.4.1`。
- 编译配置：`esp32:esp32:esp32s3:PartitionScheme=huge_app`，**Huge APP（3MB，无OTA）**，4MB Flash配置；实际Flash/PSRAM设置须匹配实物。
- 现成固件见 `release/latest/`；各个 `.bin`作用不同，不要把应用、引导器、分区表和合并固件混用。优先用Arduino按上述配置编译上传，预编译文件的说明见 [发布说明](release/latest/README.md)。
- [本轮编译收据](tests/remote_music_ble_20261024/esp32/esp32_compile.json)为PASS；编译通过不等于ESP32已烧录或手机链路已实测通过。

## 验证与待办

- [字符逐行引擎验证](audit/labels_line_engine_20261024/RESULT_SUMMARY.md)：2,475,199时钟、0失配。
- [装载器流水化验证](audit/loader_pipeline_20261024/RESULT_SUMMARY.md)：600次快速ROM和40次真实ROM装载，参数/RAM内容等价。
- [事件录音验证](audit/remote_recording_20261024/RESULT_SUMMARY.md)：58,583个旧控制包等价，录音顺序、重试、空缓存及溢出测试通过。
- 既有本地记录显示V13约15:20曾做SRAM加载和屏幕预览，但未完成采集卡逐像素比对，也没有据此证明全部音频及手机功能通过。
- 数字仿真单键至PCM5102首帧约4.577～4.664ms；32键齐按最后声部首次非零为8.028ms（原10.965ms），**尚未达到全部声部5ms目标**。该测量不含触摸模块内部检测及模拟音频链路；屏幕刷新不强行按5ms验收。

仍需验收实际键位映射、32路同时演奏、音质/响度、双DAC声音、手机控制/曲谱/录音持续回传、长时间稳定性及Flash断电启动。时序通过不代表这些实板项目全部通过。

部分验证脚本和原始收据保留了构建电脑的工具/工程路径；迁移后按本机环境调整。仓库保留必要源码、工具、验证收据和发布文件，省略工具链缓存、大样本轨迹及大型实现数据库。历史README见 [README_PRE_V13_20261024.md](docs/README_PRE_V13_20261024.md)；带旧日期的说明不覆盖本页当前状态。
