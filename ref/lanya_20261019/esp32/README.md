# ESP32固件

GPIO17 TX、GPIO18 RX，115200/8N1，热点FPGA_MUSIC / fpga2026。打开http://192.168.4.1。

固件使用AP+STA：控制热点保留，STA用于从用户提供的HTTPS直链取文件。/api/network POST接收ssid/password并发起连接，GET返回联网及校时状态；不持久保存密码。下载使用内置CA证书包及NTP时间，不关闭证书验证；不自动跟随跳转。文件64KB上限，流写入检查总时限与网络超时。ESP32实际联网和热点切信道影响需实物验证。

- GET /api/status：真实模式/音色、已应用音量与BPM、实际曲谱数量/播放状态/版本。
- POST /api/control：表单kind=mode/timbre/volume/tempo/play，value分别0..2、0..4、0..100、30..240、0/1。
- POST /api/download：表单url，返回下载文件字节供页面解析，失败返回JSON错误；未直接覆盖FPGA表。
- POST /api/score：text/plain，每行note,velocity,base_duration_ms，1～32行。全部校验后才开始事务，逐条ACK，提交后核对数量和版本。
- /cmd?c=1..5沿用原按钮顺序；P/S现对应曲谱播放/停止。空曲谱、不安全状态或特雷门独奏时不启动。

ControlLink.h实际用于Arduino固件及C++闭环测试。ACK表示接收，不表示参数已生效；滑条等待03实际数值一致，曲谱等待04版本确认。很短曲谱可能在首次状态查询前已结束，此时提示刷新，不假报仍在播放。下载/提交串行执行，不支持多用户并发编辑。

修改页面后运行build_web.py，再运行compile.py。构建缓存和结果在sim/out；通用S3编译仍需按真实模块Flash/PSRAM设置后上传。本轮不烧录。

## 新页面与接口

- GET /keymap、/keymap.js：32键配置页面及逻辑，与主页面同源，无第三方CDN。
- GET /api/keymap：通过真实UART读取05及32条24，应答含notes[32]和revision。
- POST /api/keymap：text/plain，32行MIDI音符（36..96），完整校验后暂存/提交，再逐键回读和版本确认；不是收到HTTP请求就确认成功。
- 状态及操作JSON新增uartConnected：匹配有效UART应答即为true，即便操作被拒绝；超时或协议握手设备不匹配为false。网页HTTP请求期间显示等待应答，HTTP失败显示ESP32不可达和UART未知。
- 键位页暂不自动轮询覆盖草稿。只在进入页面、重新读取和提交后查询。配置存在FPGA RAM，不保存到ESP32 Flash。

## 异步设备接口（本轮精修）

/api/status、/api/control、/api/keymap GET/POST、/api/score、兼容/cmd均改为提交串口任务：接收返回HTTP 202 {pending:true,job:N}，通过GET /api/job?id=N查询，处理中仍为202，完成后才返回原最终JSON和200/400/503。202仅代表排队成功。单任务繁忙时503 {jobBusy:true}表示未接收，可稍后重试；已接收任务不可自动重发，编号过期返回409，须刷新实际设备状态。网页共用device-api.js处理该流程。外部调用方若使用旧同步接口，也需适配此任务查询方式。

FreeRTOS工作任务独占Music::Link，HTTP线程只在短互斥区复制结果，不等待UART；网络下载处理仍使用原HTTP逻辑。本次不改变UART帧或FPGA接口。首次握手100ms×2，普通配置重试500ms×3。队列/任务创建失败会返回服务不可用，不假报成功。

本轮19组检查PASS；通用S3编译PASS，Flash1160372/1310720、静态RAM46936/327680。固件已嵌入最新版全部网页资源，仅编译未烧录，需更新ESP32固件后上板验证。

最终曲谱模式预留：GET/POST /api/performance，POST mode=0/1/2。当前返回HTTP501 {ok:false,supported:false,mode:null,message:待设备接入}，非法参数400；未发送新UART指令。接入后须走独立UART工作队列并回读实际方式，不复用原mode。完整待办见kongzhi/README.md。
