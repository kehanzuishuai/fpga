# ESP32 Arduino 工程

打开 [ESP32_FPGA_Music_Controller/ESP32_FPGA_Music_Controller.ino](ESP32_FPGA_Music_Controller/ESP32_FPGA_Music_Controller.ino)。

当前固件：`v21-autoplay-confirm-20261103`；Arduino-ESP32 3.3.10-cn；ESP32-S3 N32R16V，32MB OPI Flash、OPI PSRAM、huge_app。具体 FQBN 记录在 [sketch.yaml](ESP32_FPGA_Music_Controller/sketch.yaml)。

工程文件分工：

| 文件 | 职责 |
|---|---|
| `.ino` | Wi-Fi/BLE 服务、HTTP 路由、串口工作任务、PSRAM 曲谱缓存 |
| `ControlLink.h` | FPGA UART 请求、重试、确认及实际状态回读 |
| `FpgaUart.h` | 硬件串口适配，GPIO17/18 |
| `StreamScore.h` | 整曲时间线合法性校验 |
| `BleBridge.h` | BLE 文本命令、状态与事件录音 |
| `web_page.h` | 九项网页资源，由 `build_web.py` 生成 |

网页源文件在 [../shouji/](../shouji/)。修改后运行 `python firmware/remote_music_ble/esp32/build_web.py`，再编译主工程。完整步骤见 [构建说明](../../../docs/BUILD_AND_PROGRAM.md)。
