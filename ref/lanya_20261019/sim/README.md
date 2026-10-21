# 独立回归

在lanya目录执行D:\anaconda\python.exe -B sim/run_tests.py。先执行esp32/compile.py做真实Arduino-ESP32编译，不烧录；回归将核对编译产物和固件源码哈希。

回归覆盖：UART/CRC、缓存重试、参数边界、键位/曲谱原子提交、命令超时；ESP32共用ControlLink.h的ACK与实际状态区分、无应答/故障/未完成/错误CRC/旧序号/序号冲突恢复；C++生成请求→真实FPGA RTL UART接收与应答→原C++解析实际RTL返回；真实yinse_selector/yinse_switch/tl_mode_control的模式/音色、持键与淡变屏障；手机页面状态处理；严格lint、结构、接线打包、范围外哈希。

tb_bridge的外部演奏执行器是延迟模型，用来证明不能将接收ACK当完成；tb_existing_controls另用实际本地控制器验证适配。两者均为仿真，不是实物串口测量，更没有整机声音验证。输出在sim/out。report.json保存RTL哈希，esp32_compile.json另存固件哈希与编译状态。

本轮新增：真实PCM音量波形验证；120/240 BPM时长比、播放中变速不重触发、休止、停止/故障反压、待接收音符取消；共享C++设置实际音量/BPM、原子曲谱提交/版本/播放停止→RTL UART回复→原C++解析；MIDI/JSON独立格式与边界测试；滑条合并队列保留末值。报告中的ESP32实际编译校验还会核对固件源码哈希。


2026-10-19扩展：新增keymap_phone检查；共用C++/RTL闭环包含默认32键读取、整表写入、版本增加和第二块琴末键回读。tb_control覆盖只写第一块不能提交、32项原子提交、keymap_safe/播放安全条件、重复提交不加版本、越界索引与音域。浏览器使用preview_server.py模拟HTTP服务进行了两条链路独立显示、第二块琴和草稿/提交操作检查；截图在sim/out/keymap*_preview.png，不能作为实物证据。新增范围基线sim/outside_before_20261019.json记录本轮开始时717个范围外文件的SHA256，包含之前已修改的根README现状，不重置历史源码。

实物布局回归：test_keymap.js新增9白/6黑/1附加布局和草稿差异检查；test_phone.js新增请求pending/error/success顺序检查。preview_server.py提供/mobile-keymap和/mobile-control两个375px iframe预览入口，仅在本机模拟服务中存在。physical_keyboard_preview.png与control_ui_preview.png记录新版布局，不是硬件验收。
