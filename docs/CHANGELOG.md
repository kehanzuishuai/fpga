# CHANGELOG

工作工程：`D:\gaoyun\piano_v2_audio_fix`

工程入口：`D:\gaoyun\piano_v2_audio_fix\yinyue_fashengqi.gprj`

更新：2026-10-17T19:15:59.254686+08:00；本轮记录目录：`D:\gaoyun\piano_v2_audio_fix\audit\continuation_20261017`、`D:\gaoyun\piano_v2_audio_fix\tests\continuation_20261017`。

验证层次：源码审查及依赖哈希已留证（PATH_VERSION_AUDIT.json）；本轮仿真/数据核对=PASS；Gowin实现=PASS；真实上板=未执行，协议、实体键位及模拟音频仍待验证。

本轮五个音频/顶层RTL仅新增诊断：voice_bank新增分配/start、加载/就绪完成计数；synth_core新增真实FX前后累计峰值；frontend新增FIFO真正出队计数；synth_top透传；板级顶层新增接受MIDI/帧/背压统计。第六个RTL是src/display/visual_dvi_io.v，增加三个逐通道局部复位寄存器，处理实际报告的共享复位长路由恢复问题，数据连线不变。GAO增加对应探针并以低8位计数保留4096点深度；impl过程配置新建以匹配CLI。音色、频率、事件/Loader调度协议及管脚保持原值。

测试修复：每键复位前重启无reset端口的接收模型，累计错误断言保留；增加逐键真实握手、PCM、两声道板载解码、HDMI与诊断计数断言；统一4096样本保持窗口。增加冷启动镜像策略、低高键和弦与原失败定向复现，保留原负向结果。

逐文件完整路径、来源、原因、前后SHA256及验证映射见 `D:\gaoyun\piano_v2_audio_fix\audit\continuation_20261017\FILE_CHANGES.csv`；生产不变项及前哈希见 `D:\gaoyun\piano_v2_audio_fix\audit\continuation_20261017\before.json`。新增审计/运行/分析脚本均写在当前tools；测试源码、日志、PCM、WAV、结果及构建产物均在当前工程。旧目录只读。

