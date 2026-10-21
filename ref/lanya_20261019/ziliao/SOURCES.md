# 参考

- 用户原测试程序：C:/Users/GAOKEHAN/Downloads/ESP32_FPGA_Music_Controller/ESP32_FPGA_Music_Controller/ESP32_FPGA_Music_Controller.ino。仅阅读，保留热点名、GPIO17/18与旧按钮兼容映射，原文件未改。
- Espressif Arduino-ESP32 Wi-Fi AP：https://docs.espressif.com/projects/arduino-esp32/en/latest/api/wifi.html
- Espressif HardwareSerial，实际编译依赖本机Arduino-ESP32 3.3.12的HardwareSerial.h/.cpp、WiFi、WebServer；未引入第三方网络库。
- 通用UART/CRC、请求缓存、事务存储沿用本项目上轮已测试RTL并重命名wifi_；没有复制第三方整套顶层。
- 适配器参考本地yinse_selector/yinse_switch与tl_mode_control接口和切换时序；原文件只读，回归对原模块直接实例化。

本轮格式与联网参考：
- MIDI Association Standard MIDI Files：https://midi.org/standard-midi-files （格式0/1、分轨及时间信息）；本项目自己实现受限单旋律解析，不复制外部解析器。
- Espressif AP/STA与本机Arduino-ESP32 3.3.12 NetworkClientSecure.useBuiltinCACertBundle、HTTPClient.writeToStream的实际源码/API。下载必须有外网及校时，不使用setInsecure。
- 在线解析连通性样本：https://raw.githubusercontent.com/Tonejs/Midi/master/test/midi/pitchBendTest.mid ，仅用于主机端真实下载与解析验证；本机解析不执行其中弯音指令，不将其当完整乐器演奏验收。来源项目：https://github.com/Tonejs/Midi 。
