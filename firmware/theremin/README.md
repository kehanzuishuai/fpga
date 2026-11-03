# 特雷门琴端：UNO 采集与 FPGA 连续音源

## 工程与硬件

完整草图：[Open_Theremin_FPGA/](Open_Theremin_FPGA/)，22 个源文件。目标为经典 Arduino UNO / ATmega328P、16 MHz，Arduino AVR 1.8.8；配套 Open.Theremin V3 天线扩展板。它不是 ESP32 或 UNO R4 程序。

UNO 读取音高、音量天线，完成校准、旋钮及本地 DAC 处理；`fpga_bridge.cpp` 发送频率、幅度和状态。FPGA 接收端在 [src/theremin/](../../src/theremin/)，使用独立正弦 DDS，不复制 UNO 本地的八种波表音色。

## 编译、连接与校准

在仓库根目录运行：

```shell
arduino-cli compile --fqbn arduino:avr:uno --build-path build/uno firmware/theremin/Open_Theremin_FPGA
```

也可在 Arduino IDE 选择 Arduino Uno，打开 `.ino` 并上传；同目录的全部文件必须保留。本次从发布副本编译通过：程序 26,380 字节，静态 RAM 265 字节。编译记录和 HEX 在 [发布目录](../../release/v21_20261103/)。

UNO D1/TX → 合适的 **5V 转 3.3V 电平转换** → Dock J24 第7脚 / FPGA L17，并连接 GND。UART 为 115200、8N1；只需 UNO→FPGA 单向控制线。不要把 UNO 模拟音频接到 FPGA 数字输入。

首次使用桥接程序需要重新校准：保留天线扩展板原有供电和接地方式，预热后将 PITCH/VOLUME 置中、REGISTER/TIMBRE 向左；长按 FUNCTION 约 2 秒开始校准，松开并远离天线。短按 FUNCTION 切换本地演奏/静音。校准及传感异常时不输出可演奏控制；正常后 FPGA 需连续三帧有效新数据才恢复。

FPGA 使用“特雷门琴”或“合奏”声源模式。合奏时失联、静音或校准只使特雷门琴支路淡出，不清除琴键声部。当前手机滑音、颤音参数不作用于这一路；连续音高已有独立平滑控制。

## 协议

固定 16 字节、目标每 4 ms 一帧；频率范围 20～4000 Hz，字段使用整数毫赫兹；幅度 0～65535。CRC16-CCITT-FALSE，详情见 [CURRENT_INTERFACES.md](../../docs/CURRENT_INTERFACES.md)。FPGA 检查序号、CRC、有效状态，100 ms 未收到有效新帧时淡出。

原作者与许可见 [SOURCES.md](SOURCES.md)；每个源文件头部保留原许可。
