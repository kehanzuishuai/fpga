# 手机端

网页由ESP32提供，不依赖CDN，不用APP或蓝牙配对。音量0～100%、速度30～240 BPM滑条使用180ms合并和最新值队列，不会因快速拖动堆满串口。显示当前值来自FPGA回读。

曲谱流程：ESP32联网→输入HTTPS文件直链下载，或直接从手机导入→选择MIDI音轨/通道→选择32事件分段→传给FPGA→播放/停止。网页解析MIDI0/1 PPQN与音符JSON；明确拒绝和弦重叠和越界音符。下载预览不改变FPGA曲谱。在线文件上限64KB；MIDI程序/踏板/弯音/中途变速不导入，统一BPM播放。

示例examples/twinkle.json是传统旋律的首句音符示例，基准时长四分音符500ms（120 BPM），bpm100表示建议演奏速度。也可使用自己的公开HTTPS JSON/MIDI直链；不支持PDF或图片。

修改index.html、app.js、score.js后运行esp32/build_web.py，再编译固件。所有资源内嵌，手机断外网仍能控制或导入本地文件。


2026-10-19：主页面新增双链路状态和音量/速度默认值按钮；键位配置独立页面keymap.html/keymap.js，每块16键。defaultMap、presetMap和validateMap不依赖DOM，可由Node测试。网页离线可打开外观，但没有ESP32 HTTP响应不能显示已连接；通过sim/preview_server.py可在127.0.0.1:8765进行明确模拟的本地交互预览，模拟结果不是硬件验证。


实物布局更新：ui.css为主页面和键位页共用样式，由build_web.py嵌入并通过/ui.css提供。keymap.js的KEY_LAYOUT定义9白/6黑/1附加键几何与逻辑K编号；保持默认映射及协议顺序不变。两块琴始终同时展示，点击与辅助K按钮选择同一位置。changedIndices按最后一次真实回读计算差异，恢复同一音符会取消修改标记。底部按钮保留安全区和页面底部空间，缩小动画、等待效果可通过系统减少动态效果偏好关闭。
