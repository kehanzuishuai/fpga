# ESP32与FPGA接线

| ESP32-S3开发板 | FPGA信号 | 球位 | Pro Dock接口 |
|---|---|---|---|
| GPIO17 TX | wifi_uart_rx 输入 | B19 | J26第7脚 |
| GPIO18 RX | wifi_uart_tx 输出 | A17 | J26第5脚 |
| GND | GND | — | J26第3或4脚 |

沿用先前本地底板原理图第16页、BTB_J3核对的预留，Bank5须为3.3V。与本地src及boards已有CST核对无B19/A17冲突；不代表其他未接入的主工程约束也已核查。

这是J26分配，与下载目录旧测试程序的J22/L22/M26不同。请按本目录接线和约束成套使用，重新核对实际底板型号、接口方向和GND丝印。双向3.3V UART，共地；两板分别供电，不将FPGA IO接5V。

把wifi_pins.cst加入有wifi_uart_rx/tx顶层端口的工程；根目录同名CST只是迁移提示，不能同时添加。不能与特雷门Arduino UART输出并线。
