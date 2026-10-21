# Gowin工程文件登记与重新实现

完成时间：2026-10-18T12:03:39.711434+08:00。工程：`D:\gaoyun\piano_v2_audio_fix\yinyue_fashengqi.gprj`。

**本轮实际重新运行：综合 PASS、布局布线 PASS、五类时序检查 PASS、生成新FS。没有自动烧录。**

`.gprj`新增22个验证/分析/文档条目，全部enable=0；原63个启用条目及生产RTL保持不变。已有RTL改动继续参与综合；测试台为file.verilog，Python/Tcl/报告为file.other，均可在项目中管理但不参与综合。

本次构建的音源算法仍是当前版本：44音测量发现的响度低谷和87～89极弱尾段退出风险没有被修复；32个优质音色的音质验收仍NOT_ACCEPTED。实体最后四键无声、两块16键接入及同时32Voice仍需独立实物验收。

32 Voice、AMY、FFT、HDMI、PT8211、PCM5102A和GAO保留；顶层BUILD_STAGE=3、DISPLAY_ENABLE=1，仍为16键逻辑MIDI60～75。CST/SDC、引脚、时钟/电压配置和音源参数未改。

## 本轮时序

|检查|最差Slack(ns)|
|---|---:|
|setup|10.131|
|hold|0.143|
|recovery|2.716|
|removal|0.023|
|min_pulse_width|7.128|

Setup/Hold违反端点：{'Setup': 0, 'Hold': 0}。引脚表与构建前一致：True。Removal裕量很小，数字STA通过不代替板上复位/重启和HDMI恢复验收。

|时钟|约束MHz|报告Fmax MHz|
|---|---:|---:|
|clk_50m|50.000|239.235|
|audio_clk|12.288|33.235|
|video_pixel|25.000|33.479|
|tck_pad_i|20.000|87.296|

video_serial不具有普通内部逻辑Fmax报告，不能把其目标频率当成测得Fmax。

|资源|用量/可用|
|---|---:|
|Logic|44061/138240|
|Register|16877/139140|
|BSRAM|258/340|
|DSP|98.5/298|
|PLL|2/12|

警告基线77条，本轮77条；新增/增多0条。继承TA1132（tck_pad_i未显式创建时钟）和PR1014（clk_50m_d通用布线）仍在，时序PASS表示当前约束下所报告的检查通过，不代表零警告或板上验收。

综合网表确认G_PARTIAL.G_VOICE[0]～[31]全部存在，32个Voice保留；没有编译tb_测试台。详见SYNTHESIS_SCOPE.json。引脚逐项403行比较结果见PIN_COMPARISON.json。

## 产物

- 工程：`D:\gaoyun\piano_v2_audio_fix\yinyue_fashengqi.gprj`
- 综合：`D:\gaoyun\piano_v2_audio_fix\impl\gwsynthesis\yinyue_fashengqi_syn.rpt.html`
- 时序：`D:\gaoyun\piano_v2_audio_fix\impl\pnr\yinyue_fashengqi.tr`
- 布局布线：`D:\gaoyun\piano_v2_audio_fix\impl\pnr\yinyue_fashengqi.rpt.txt`
- 新FS：`D:\gaoyun\piano_v2_audio_fix\impl\pnr\ao_0.fs`
- SHA256：`7829d74b53b49d1384a6cd5ef57791c0a4ab0fc7dadfadafa98e1f94884a3d15`
- 本轮完整日志：`D:\gaoyun\piano_v2_audio_fix\tests\project_rebuild_20261018\gowin.log`
- 命令、输入/输出哈希、工具返回值、时序门限：`D:\gaoyun\piano_v2_audio_fix\audit\project_rebuild_20261018\BUILD.json`
- 工程新增条目：`D:\gaoyun\piano_v2_audio_fix\audit\project_rebuild_20261018\PROJECT_UPDATE.json`
- 警告逐项比较：`D:\gaoyun\piano_v2_audio_fix\audit\project_rebuild_20261018\WARNING_COMPARISON.json`。
- 构建前备份：`D:\gaoyun\piano_v2_audio_fix\audit\project_rebuild_20261018\backup`。

上一轮range44及更早BUILD/VALIDATION记录保持历史内容，不把本轮新FS覆盖成旧测试的产物。当前新FS由本轮BUILD.json关联到准确输入。

包装脚本首次引脚检查把报告生成时间也纳入比较，造成误报；原结果保留在BUILD_FIRST_PIN_HEADER_CHECK.json。已独立逐项比较全部Pin Details单元格，仅排除报告元数据，PIN_COMPARISON.json为PASS。Gowin本体返回0，综合/时序/FS均是同一次新运行的产物，未修改或重跑设计以消除该报告时间戳差异。
