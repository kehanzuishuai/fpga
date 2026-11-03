# 当前接口、引脚与曲谱格式

## 连接

| 功能 | 模块端 | Dock / FPGA |
|---|---|---|
| 第一块 TTP229 | SCL / SDO | J26 第11 / 9脚，C21 / B20 |
| 第二块 TTP229 | SCL / SDO | J26 第7 / 5脚，B19 / A17 |
| TTP229 电源 | VCC / GND | J26 第1或2脚 3.3V / 第3或4脚 GND |
| ESP32 → FPGA | GPIO17 TX | J26 第12脚，B21 |
| FPGA → ESP32 | GPIO18 RX | J26 第10脚，A20 |
| UNO → FPGA | D1/TX 经 5V→3.3V 电平转换 | J24 第7脚，L17 |
| PCM5102A | BCK / LRCK / DIN | J24 第11 / 12 / 6脚，C24 / B24 / H15 |
| PCM5102A GND | GND | J24 第3或4脚 |
| 实体按钮 | 音色 / 声源 / 复位 | F15 / G15 / K16，低有效 |

所有模块共地。FPGA 为 3.3V 输入逻辑；UNO TX 不能直接以 5V 接入。ESP32 独立 USB 供电；PCM5102A 模块电源和格式跳线按实际模块核对。引脚最终以 `src/integrated.cst` 为准。

## ESP32 与 FPGA

UART 115200、8N1，独立于特雷门琴 UART；固定帧、请求序号、CRC、ACK 和状态回读的实际实现见 `ControlLink.h` 与 `src/remote/control/wifi_control.sv`。

| UART 命令 | 作用 |
|---|---|
| 0x01 / 0x02 / 0x03 / 0x04 | 握手、实际状态、音量/BPM、曲谱状态 |
| 0x05 / 0x24 | 键位版本与逐键读取 |
| 0x06 / 0x16 | 读取 / 设置自由、自动、指导方式 |
| 0x07 / 0x17 | 事件录音读取 / 开关 |
| 0x08 | 回读力度、滑音、颤音和版本 |
| 0x10～0x15 | 声源、音色、音量、效果、BPM、播放控制 |
| 0x18 / 0x19 / 0x1a | 力度参数 / 滑音 / 颤音，0～100 |
| 0x20～0x23 | 键位暂存、写入、提交、撤销 |
| 0x40～0x43 | 整曲 FIFO 会话、事件追加、状态、封口 |

普通曲谱分段的 UART 命令见源码，网页 `/api/score` 最多 32 项；整曲 `/api/stream` 使用独立 FIFO 流，不能将两种记录格式互换。

## HTTP 与曲谱

涉及 FPGA 的请求先返回 HTTP 202 `{pending:true,job:N}`，再轮询 `GET /api/job?id=N` 取得最终 JSON；202 仅表示接收排队。`device-api.js` 负责这个流程。

| 接口 | 内容 |
|---|---|
| GET /api/status | 实际连接、参数、曲谱与流播放状态 |
| POST /api/control | `kind` 与 `value`，支持 mode/timbre/volume/tempo/play/expressionVelocity/expressionGlide/expressionVibrato |
| GET/POST /api/performance | 0自由、1自动、2指导 |
| GET/POST /api/keymap | 32 键映射读取和事务提交 |
| POST /api/score | 单旋律分段，最多32行 `note,velocity,base_duration_ms` |
| POST /api/stream | 整曲绝对时间线，每行 `base_time_ms,note,velocity` |
| GET/POST /api/network | STA 网络状态 / SSID与密码 |
| POST /api/download | HTTPS 文件直链下载；不直接开始演奏 |

整曲上限 32,768 个事件、768KB HTTP 正文、32 个同时不同音高、MIDI 36～96，时间为 120 BPM 基准毫秒，最大 3,600,000；速度由 FPGA BPM 缩放。`velocity=0` 表示松音，其余 1～127 为起音。时间必须单调，所有起音必须有匹配松音。同一时间重触发须先松后按。

网页导入限制为 64KB；MIDI 0/1 PPQN 支持最多64轨，自动合并除打击乐外的音轨。同音高跨轨重叠按引用计数保持，最终统一使用 FPGA 当前音色。JSON 使用顺序单旋律 `[note,velocity,duration_ms]`，最多4096项；不能将整曲绝对时间事件直接保存为该 JSON。

## 特雷门琴 UART

16 字节固定帧，115200、8N1；UNO 目标每 4ms 发送一帧。多字节字段小端。

| 字节 | 内容 |
|---|---|
| 0～1 | 0xA5, 0x5A |
| 2 | 版本1 |
| 3 | 8位序号 |
| 4 | 状态 flags；可演奏正常状态0x0B |
| 5～8 | 频率整数毫赫兹，20,000～4,000,000 |
| 9～10 | 幅度0～65535 |
| 11 | 保留，0 |
| 12～13 | 发送端毫秒时间戳，16位 |
| 14～15 | CRC16，小端；覆盖字节2～13 |

CRC 为 CCITT-FALSE，初值0xFFFF、多项式0x1021。flags 位0/1标记音高/音量有效，位2校准中，位3演奏，位4异常。接收端恢复需要连续三帧有效新序号；100ms 超时、校准、异常或静音使该支路淡出。该串口不能发送调试文字或与 ESP32 串口混接。
