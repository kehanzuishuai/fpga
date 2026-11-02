# ESP32-S3 滑音、颤音配套固件 · 2026-11-02

本次上传包含已编译验证的 ESP32 源码、全部内嵌手机页面和可直接烧录的合并固件。

- [Arduino 工程](../../firmware/remote_music_ble/esp32/ESP32_FPGA_Music_Controller/ESP32_FPGA_Music_Controller.ino)
- [手机页面源码](../../firmware/remote_music_ble/shouji/)
- [合并烧录文件](ESP32_expression_0x0.bin)
- [原始 ESP32 编译收据](ESP32_BUILD.json)
- [文件校验清单](SHA256SUMS.txt)

## 烧录

验证配置为 ESP32-S3 N32R16V：32MB OPI Flash、OPI PSRAM、huge_app 分区。
使用合并文件 `ESP32_expression_0x0.bin`，起始偏移 **0x0**。
烧录后连接热点 `FPGA_MUSIC`（默认密码 `fpga2026`），打开 `http://192.168.4.1`，强制刷新页面。
GPIO17 TX → FPGA B21（UART RX），GPIO18 RX ← FPGA A20（UART TX），115200 8N1，并共地。

## 配套 FPGA 与适用范围

本 ESP32 固件配套 2026-11-02 的 V21 滑音、颤音 FPGA 版本。
对应 FPGA 烧录文件 SHA256 为 `ed1d070e1ec9839e63092b5c4ac5849ff91d11364080776861baf16dc860cf26`。
本次仅更新 ESP32 文件；仓库根目录 FPGA 工程及 `release/latest` 仍是历史 V13，不是本 ESP32 版本的完整配套包。

滑音、颤音范围 0～100，默认关闭；ESP32 通过 0x19/0x1A 转发，0x08 回读 FPGA 实际值。
配套 FPGA 的钢琴、管风琴、长笛、钟琴支持这两个效果；吉他和特雷门琴尚未接入。
力度参数目前只保存、回读，未影响声音。滑音种子覆盖 ±60 半音，首音及更大跳音直接使用目标音高。

## 构建与验证

已编译的源码与 `ESP32_BUILD.json` 内七个源码 SHA256 一致；内嵌九项网页资源与本次页面源码一致。
程序使用 1,437,254 字节、静态 RAM 使用 50,080 字节。未自动烧录，实板功能待确认。

修改网页后先在仓库根目录执行：

```sh
python firmware/remote_music_ble/esp32/build_web.py
```

使用 Arduino-ESP32 3.3.10 对应的板卡包，按 `sketch.yaml` 配置编译：

```sh
arduino-cli compile --fqbn esp32:esp32:esp32s3:FlashMode=opi,FlashSize=32M,PSRAM=opi,PartitionScheme=huge_app firmware/remote_music_ble/esp32/ESP32_FPGA_Music_Controller
```

实际编译收据来自本机已安装的 3.3.10-cn 工具链，工具链和个人构建缓存不包含在上传文件中。
运行时 `firmwareId` 沿用 `v19-polyphonic-stream-20261031` 字符串；本次固件以日期目录和 SHA256 区分。

实际通信头文件的回归测试可在有 C++11 编译器的环境运行：

```sh
g++ -std=c++11 -Ifirmware/remote_music_ble/esp32/ESP32_FPGA_Music_Controller tests/esp32_expression_20261102/expression_link.cpp -o expression_link_test
./expression_link_test
```
