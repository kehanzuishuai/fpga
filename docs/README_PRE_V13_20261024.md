# Tang Mega 138K Pro FPGA电子钢琴

主工程：**[yinyue_fashengqi.gprj](yinyue_fashengqi.gprj)**。本机路径：`D:\gaoyun\piano_v2_audio_fix\yinyue_fashengqi.gprj`。硬件为Tang Mega 138K Pro + Pro Dock。

手机ESP32 Wi-Fi控制、五音色、WAV在FPGA解码播放已集成；保留两块16键、32 Voice、原16键屏幕对应、FFT、HDMI和双DAC。

[接线与使用说明](docs/REMOTE_MUSIC_20261019.md) · [最终验证结果](docs/REMOTE_MUSIC_RESULTS_20261019.md)

完整工程综合、布局布线、五类时序和ESP32固件编译通过。本轮针对性验证通过；按用户要求停止重复的完整显示回归，未改动部分复用已有验证，改动的XY峰值及SPI CRC流水线补做短验证。未自动烧录；真实接线、Wi-Fi长时间连续播放和主观音质仍待上板确认。

实体32键固定为原来的32 Voice钢琴，不叠加其他乐器。手机五音色仅作用于MIDI/JSON曲谱，WAV保留录音原声。网页包已恢复修改前的原样，SHA256为`5428444eaa7aad9c41b0537b720fe516ef80e1186605d6154d6dbf38bfe253cf`。

- 工程：`D:\gaoyun\piano_v2_audio_fix\yinyue_fashengqi.gprj`
- FS：`impl/pnr/ao_0.fs`
- FS SHA256：`e483552fc9993df6e9464790a9ca29d7e8253e02a51002507d05ee2234884e0b`
- 固件和FS归档：`tests/remote_music_20261019/final_build`

## 功能和范围

| 功能 | 当前实现 |
|---|---|
| 实体键盘 | 两块独立16键TTP229，32个不同音高，默认MIDI60～91 |
| 实体音色 | 原钢琴，保留32 Voice，不叠加其他乐器 |
| 手机控制 | ESP32-S3 Wi-Fi热点和原网页，音量、效果、曲谱及32键音高映射 |
| 曲谱音色 | 钢琴、长笛、吉他、管风琴、钟琴，每次选择一种 |
| 曲谱格式 | MIDI格式0/1、PPQN及兼容JSON，单旋律、分段机制 |
| WAV播放 | FPGA解析未压缩PCM WAV，16/24位、单/双声道、44.1/48kHz |
| 显示 | FFT、波形、李萨如、HDMI，键位显示保持原第一块16键对应 |
| 输出 | PT8211和PCM5102双DAC，立体声、主音量及饱和保护 |

手机五音色用于MIDI/JSON重新合成；WAV保留录音原声；实体键保持钢琴。曲谱播放期间独占合成事件，停止或自然结束后恢复实体键。WAV可与实体钢琴混音。

## 目录说明

```text
yinyue_fashengqi.gprj        高云主工程
src/                        RTL、ROM、PLL、CST/SDC和调试配置
src/keyboard/               双键盘与映射
src/remote/                 UART、SPI、WAV解码及立体声混音
src/instruments/            曲谱辅助音色及共享运算
src/display/                FFT、波形、李萨如、HDMI
firmware/remote_music/      ESP32源码及网页资源
sim/、tests/                仿真模型、测试平台与验证脚本
tools/                      构建、集成和分析脚本
docs/、ref/                 文档与参考资料
audit/remote_music_20261019/ 构建及验收收据
release/latest/             GitHub发布的FS、固件与SHA256清单
```

本地还保留`impl/`、历史备份、试听音频和构建缓存。GitHub发布保留源码、工程、文档、测试入口、关键验证证据和最新产物，排除本机工具链、批量波形/音频输出及大体积中间文件。历史文档中的绝对路径和旧收据应结合日期阅读，以本README和最终报告为准。

GitHub仓库原有的`boards/tang_mega_138k_pro/`、`rtl/`、`tb/`及`scripts/`保留为历史参考；**本次最新入口是仓库根目录的GPRJ**。这些历史工程有同名模块，不要与当前`src/`混合编译。更新前的仓库首页保存在`docs/REPOSITORY_README_BEFORE_20261021.md`。

## 打开与构建FPGA工程

验证工具：**Gowin V1.9.12 x64**。器件：**GW5AST-LV138FPG676AC1/I0，版本C**。

1. 用Gowin Designer打开根目录`yinyue_fashengqi.gprj`。
2. 顶层模块为`tang_mega_138k_pro_top`，源码为`src/tang_mega_138k_pro_top.v.v`；选择SystemVerilog 2017。
3. 有效约束为`src/integrated.cst`和`src/integrated.sdc`；91个有效工程输入，测试平台不参与综合。
4. 依次执行综合、布局布线、时序分析。最终通过选项为**Placement 3 / Route 0**，Timing Driven和Hold修复开启，保持原时钟及约束。
5. 核对新生成FS和报告：Setup/Hold违例端点为0，五类时序裕量均非负。修改RTL后必须重新构建。

`tools/build_gowin.tcl`执行完整构建；`tools/remote_retime.tcl`用于复用已验证综合网表的PnR。`tests/remote_music_20261019/retime.py`先校验输入并归档，需显式提供`--archive <新目录名> --place <0..4> --route <0..2>`。Python脚本包含本机Gowin/Icarus路径，异机使用前需配置；一次性修改脚本不要批量重跑。已有FS不代表后续修改后的版本。

## ESP32代码、构建和供电

Arduino IDE主文件：[ESP32_FPGA_Music_Controller.ino](firmware/remote_music/esp32/ESP32_FPGA_Music_Controller/ESP32_FPGA_Music_Controller.ino)。请复制整个同名目录，保留全部头文件。

| 文件 | 职责 |
|---|---|
| `ESP32_FPGA_Music_Controller.ino` | 热点、网页服务、控制接口、任务调度 |
| `ControlLink.h` | UART控制、曲谱、键位事务、应答与重试 |
| `WavService.h` | HTTP二进制上传、队列及SPI工作任务 |
| `WavLink.h` | SPI包、CRC、序号、状态和反压 |
| `web_page.h` | 嵌入网页，保持已恢复的原界面 |

已验证目标`esp32:esp32:esp32s3`，Arduino-ESP32 core `3.3.10-cn`，默认4MB分区、PSRAM关闭。烧录前按实际开发板Flash/PSRAM选择配置，不绑定固定COM口。本机隔离工具链不上传；复用`compile.py`需先配置其Arduino CLI路径，也可用Arduino IDE构建。

带USB供电电路的ESP32-S3开发板可通过USB接稳定5V电源，上电自动运行已烧录程序。FPGA按原方式单独供电；**两板必须共地**。分别供电时不额外连接两板的5V/3.3V电源脚。信号使用3.3V；裸ESP32模组不能直接接5V。

## 接线

下表ESP32侧为GPIO编号，Dock侧为排针针号，请核对排针方向。

| ESP32-S3 | 方向 | FPGA信号 / 管脚 | Pro Dock |
|---|---|---|---|
| GPIO17 TX | ESP→FPGA | esp_uart_rx / B21 | J26第12脚 |
| GPIO18 RX | FPGA→ESP | esp_uart_tx / A20 | J26第10脚 |
| GPIO12 SCK | ESP→FPGA | esp_spi_sck / L17 | J24第7脚 |
| GPIO11 MOSI | ESP→FPGA | esp_spi_mosi / E25 | J24第9脚 |
| GPIO10 CS | ESP→FPGA | esp_spi_cs_n / H14 | J24第5脚 |
| GPIO13 MISO | FPGA→ESP | esp_spi_miso / D25 | J24第10脚 |
| GND | 共地 | GND | J24/J26第3或4脚 |

| 琴键模块 | SCL | SDO |
|---|---|---|
| 第一块16键 | C21 / J26第11脚 | B20 / J26第9脚 |
| 第二块16键 | B19 / J26第7脚 | A17 / J26第5脚 |

琴键模块VCC接J26第1或2脚3.3V，GND接第3或4脚。原资料UART的B19/A17与第二块键盘冲突，当前已改用B21/A20。不要将5V接入FPGA信号脚，SPI建议使用短线。

## 手机连接与音乐播放

1. 断电接线，给FPGA供电并加载匹配FS，再给已烧录固件的ESP32供电。
2. 手机连接热点 **`FPGA_MUSIC`**，密码 **`fpga2026`**。
3. 浏览器打开 **`http://192.168.4.1`**，确认FPGA连接状态，再控制或播放。
4. 上传WAV期间保持Wi-Fi连接及页面前台；上板先测试16位48kHz，再检查其他格式和长时间播放。

链路：`手机 --Wi-Fi/HTTP--> ESP32 --UART/SPI--> FPGA`。

- **UART 115200、8N1**：音量、音色、播放、键位、曲谱事件和状态。
- **SPI Mode0、4MHz，ESP32为主机**：WAV数据与状态，包含CRC-16、序号、重试去重及缓冲余量反馈，支持边传边播。

WAV原始字节由ESP32转发，FPGA解析RIFF/WAVE的`fmt`和`data`块、检查边界、还原PCM并统一为24位。单声道复制为左右声道，44.1kHz线性插值至48kHz，经跨时钟邮箱、混音和主音量送到双DAC。**不支持MP3、浮点WAV、WAVE_EXTENSIBLE。**

MIDI/JSON先由手机网页解析为音高、力度和时长等事件，再由FPGA计时、合成。目前保留单旋律及分段机制，不是任意复调MIDI原文件的FPGA解码器。仅播WAV时合成VOICE计数为0正常。

## 最新验证结果

最后通过时间：**2026-10-20 21:53（UTC+8）**。

| 时序 | 最差裕量/ns |
|---|---:|
| Setup | +0.105 |
| Hold | +0.010 |
| Recovery | +6.742 |
| Removal | +0.341 |
| 最小脉宽 | +3.272 |

Setup/Hold违例端点均为0。Logic 103455/138240，寄存器43274/139140，BSRAM 296/340，DSP 186/298，PLL 3/12。

验证包括32键钢琴隔离、曲谱切换、WAV八格式、传输异常、双DAC及实际映射Loader等。按要求复用依赖未变化的有效结果；重复的完整HDMI整帧和长WAV回归曾停止，没有将中断运行记为新的完整通过。XY峰值和SPI CRC流水线改动分别有针对性新检查。

- [最终验证报告](docs/REMOTE_MUSIC_RESULTS_20261019.md)
- [完整接线与使用说明](docs/REMOTE_MUSIC_20261019.md)
- [构建收据](audit/remote_music_20261019/BUILD.json)
- [最终验收收据](audit/remote_music_20261019/FINAL_ACCEPTANCE.json)
- [44音响度校准与限制](docs/NOTE_GAIN_CALIBRATION_20261018.md)
- [续接及历史记录](README_HANDOFF.md)

GitHub最新发布产物保存在`release/latest/`，包含FS、ESP32二进制、编译收据及SHA256清单；本机原产物和历史证据保持不变。

## 实板验收仍需完成

两块键盘的真实左右键序、32音实体演奏、Wi-Fi长时间传输、左右声道及模拟输出、屏幕和主观音质仍需实板确认。音源测量建议MIDI48～79作为更均匀的32键候选，当前默认映射仍为60～91。PCM非零或时序通过不等于音质优秀。

没有自动烧录。加载前核对板型、接线、FS哈希及ESP32 Flash/PSRAM参数；实板验收结果另行记录。

