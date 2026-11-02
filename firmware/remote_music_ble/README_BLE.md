# ESP32-S3 最新固件：2026-11-02 滑音、颤音配套版

已修复滑音、颤音命令转发及实际值回读，已内嵌最新手机页面。

- [Arduino 主程序](esp32/ESP32_FPGA_Music_Controller/ESP32_FPGA_Music_Controller.ino)
- [手机页面源码](shouji/)
- [固件下载、烧录配置和完整说明](../../release/esp32_expression_20261102/README.md)
- [合并固件，偏移 0x0](../../release/esp32_expression_20261102/ESP32_expression_0x0.bin)

模块配置：ESP32-S3 N32R16V，32MB OPI Flash / OPI PSRAM，huge_app 分区。
本版配套 V21 FPGA；本次上传没有更新仓库根目录的历史 V13 FPGA 工程，不能把历史工程当成本版配套版本。
GPIO17 TX → FPGA B21，GPIO18 RX ← FPGA A20，115200 8N1，并共地。
热点 `FPGA_MUSIC`，默认密码 `fpga2026`，打开 `http://192.168.4.1`。
已编译和完成通信回归，未自动烧录；支持范围和限制见上述说明。
