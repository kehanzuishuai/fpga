# 特雷门琴来源与署名

`Open_Theremin_FPGA/` 为当前工程使用的 UNO 桥接源码，共 22 个文件。发布副本与本地 V17 集成版本逐文件一致；V14、V15 及 V17 中该目录的内容相同，本次没有修改采集或校准算法。

上游为 Urs Gaudenz 等人的 Open.Theremin V3 Arduino 控制软件，主要贡献者还包括 David Harvey、Michael Margolis。桥接适配保留本地音频、增加 115200 串口二进制控制帧、校准有效标记/CRC、异常与超时检查，并隔离串口调试文字。

- Open.Theremin 控制软件及标注该许可的源文件：GPL-3.0-or-later，见 [GPL-3.0.txt](licenses/GPL-3.0.txt)。
- `mcpDac.h` 保留 William Greiman / WaveHC 的版权与 GPL-3.0-or-later 头部。
- `EEPROM.h` 保留 David A. Mellis、Christopher Andrews 等的版权与 LGPL-2.1-or-later 头部，见 [LGPL-2.1.txt](licenses/LGPL-2.1.txt)。

具体文件的许可范围以各自原始头部为准；此说明不为仓库其他 FPGA IP、数据或独立代码重新指定许可。许可证全文来自 GNU 官方站点。

FPGA 中使用 `tl_uart_rx.sv`、`tl_packet_rx.sv`、`tl_link_guard.sv`、`tl_parameters.sv`、`tl_dds.sv`、`tl_sine_rom.sv`，由 `theremin_receiver.sv` 接入主工程。
