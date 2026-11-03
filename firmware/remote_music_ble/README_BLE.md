# ESP32-S3：手机交互、BLE 与 FPGA 串口桥

当前代码：2026-11-03，`v21-autoplay-confirm-20261103`，配套 FPGA V21。

主程序：[ESP32_FPGA_Music_Controller.ino](esp32/ESP32_FPGA_Music_Controller/ESP32_FPGA_Music_Controller.ino)。保留同目录全部头文件。网页位于 [shouji/](shouji/)，通过 [build_web.py](esp32/build_web.py) 嵌入固件；网页修改后需要重新生成头文件、编译并更新 ESP32，再强制刷新手机页面。

- 模块：ESP32-S3 N32R16V，32MB OPI Flash、OPI PSRAM，Huge APP 分区。
- 热点：`FPGA_MUSIC` / `fpga2026`，网页 `http://192.168.4.1`。
- BLE：`XDZY-Piano`；网页与 BLE 共用独占 FPGA UART 的工作任务。
- GPIO17 TX → FPGA B21；GPIO18 RX ← FPGA A20，115200 8N1，共地。
- STA 联网用于 HTTPS 曲谱下载；控制热点保留。程序不持久保存用户输入的 Wi-Fi 密码。

手机提供五音色、三种声源模式、自由/自动/指导演奏、音量、BPM、滑音、颤音、键位映射和曲谱操作。钢琴/管风琴/长笛/钟琴支持滑音、颤音；力度滑条目前只保存和回读。BLE 保留原文本命令与事件录音，整曲多轨上传使用网页路径。

导入 MIDI/JSON 后必须再点击“传入设备”；看到“整曲已缓存，点击播放”后才播放。整曲缓存放在 ESP32 PSRAM，按 FPGA FIFO 余量持续供谱；设备重启后需重新传入。MIDI 的同音高重叠由网页引用计数合并，各轨统一使用 FPGA 当前音色。

HTTP 202 表示任务已排队；页面通过 `/api/job?id=N` 取得最终结果。UART ACK 与实际状态回读共同决定是否显示成功，不能把请求已发送当作已经生效。

构建命令、现成烧录文件和校验说明见 [BUILD_AND_PROGRAM.md](../../docs/BUILD_AND_PROGRAM.md)，API 和协议见 [CURRENT_INTERFACES.md](../../docs/CURRENT_INTERFACES.md)。
