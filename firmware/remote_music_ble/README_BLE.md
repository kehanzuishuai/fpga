# ESP32-S3 固件：蓝牙 App 为主，网页备用，无 WAV（2026-10-24）

由 tools/firmware_ble_20261024/make_firmware_ble_20261024.py 从 firmware/remote_music 生成（原目录不变）。
- 蓝牙：设备名 XDZY-Piano，协议 C:/fpga/piano_app/BLE_PROTOCOL.md v1（BleBridge.h）。请求与网页共用同一个 FPGA 串口任务，一次只执行一个。
- 网页备用：仍是热点 FPGA_MUSIC / fpga2026，http://192.168.4.1；WAV 页面和 WavService 已删除。
- 录音：需要 FPGA v13 及以后（命令 0x07/0x17）；旧 FPGA 回"不支持"。
- 分区：huge_app（3 MB 程序，无 OTA）。程序 1,416,320 字节，超过默认分区的 1.25 MB，所以必须用这个分区。烧录前按实际 ESP32-S3 板的 Flash（≥4 MB）/PSRAM 选择。
- 接线不变：GPIO17 TX → FPGA esp_uart_rx（B21），GPIO18 RX ← FPGA esp_uart_tx（A20），115200 8N1，共地。SPI 四根线不再使用，可以不接。
编译：tests/remote_music_ble_20261024/esp32/esp32_compile.json（只编译，未烧录）。
