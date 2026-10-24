# V13 + ESP32-S3 BLE 发布文件（2026-10-24）

- `ao_0.fs`：V13 FPGA文件，已通过本次完整STA。由Programmer手动选择；SRAM临时加载与Flash固化是不同操作。
- `ESP32_FPGA_Music_Controller.ino.merged.bin`：由本次ESP32-S3 4MB Flash / huge_app构建导出的合并映像，只有板型、Flash容量和分区匹配时才使用。
- `ESP32_FPGA_Music_Controller.ino.bin`：应用映像；`*.bootloader.bin`、`*.partitions.bin`、`boot_app0.bin`为配套组件，不要单独当作完整固件。优先用Arduino打开本仓库BLE版本源码，匹配实物选项后编译上传；此处不猜测独立组件烧录偏移。
- `FPGA_BUILD.json`、`esp32_compile.json`保留原始构建收据，原构建绝对路径属于历史来源；大型数据库和中间文件未打包。
- `RELEASE.json`记录此次发布的源码/固件哈希，`SHA256SUMS.txt`校验当前目录文件。

本次只整理并发布已有通过的构建结果，未重新综合、未执行任何FPGA或ESP32烧录。时序通过及ESP32编译通过不等于全部实板功能验收完成。
