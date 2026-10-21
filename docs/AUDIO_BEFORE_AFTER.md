# AUDIO_BEFORE_AFTER

工作工程：`D:\gaoyun\piano_v2_audio_fix`

工程入口：`D:\gaoyun\piano_v2_audio_fix\yinyue_fashengqi.gprj`

更新：2026-10-17T19:15:59.254686+08:00；本轮记录目录：`D:\gaoyun\piano_v2_audio_fix\audit\continuation_20261017`、`D:\gaoyun\piano_v2_audio_fix\tests\continuation_20261017`。

验证层次：源码审查及依赖哈希已留证（PATH_VERSION_AUDIT.json）；本轮仿真/数据核对=PASS；Gowin实现=PASS；真实上板=未执行，协议、实体键位及模拟音频仍待验证。

数字验证：**PASS**。实物功能验收：**PENDING**。

本轮修复测试平台跨复位半帧残留，增加真实事件链GAO诊断，对齐GUI/CLI过程选项，并针对已复现的视频串行器复位恢复负裕量增加逐通道局部复位。未修改AMY参数、ROM、Loader算法、Partial算法、Allocator调度、增益或FX算法。raw bit0..15→MIDI60..75是上一轮已存在的映射，本轮保留；实体键位与实物协议仍未确认。

最后四个实体键无声：当前协议模型下未复现，不能报告实物故障已修复。原照片只证明mapper状态和组合MIDI曾显示，不能确定Note On已被FIFO接受或声音已启动；照片中的旧表MIDI为67/71/75，不能混作当前73/74/75。

本轮记录 `D:\gaoyun\piano_v2_audio_fix\audit\continuation_20261017\VALIDATION.json` 为唯一当前汇总；`audit/audio_diagnosis`、`tests/audio_diagnosis` 内既有记录是历史基线，不能替代本轮结果。原docs已备份到 `D:\gaoyun\piano_v2_audio_fix\audit\continuation_20261017\backup\docs`。

相同MIDI的新旧Voice/Gain/FX逐样本比较由continuation_analyze.py执行；不同raw排列的声音顺序可能不同。前后声学图和WAV只在本轮分析完成时有效。

数字验证：**PASS**。实物功能验收：**PENDING**。

本轮修复测试平台跨复位半帧残留，增加真实事件链GAO诊断，对齐GUI/CLI过程选项，并针对已复现的视频串行器复位恢复负裕量增加逐通道局部复位。未修改AMY参数、ROM、Loader算法、Partial算法、Allocator调度、增益或FX算法。raw bit0..15→MIDI60..75是上一轮已存在的映射，本轮保留；实体键位与实物协议仍未确认。

最后四个实体键无声：当前协议模型下未复现，不能报告实物故障已修复。原照片只证明mapper状态和组合MIDI曾显示，不能确定Note On已被FIFO接受或声音已启动；照片中的旧表MIDI为67/71/75，不能混作当前73/74/75。

本轮记录 `D:\gaoyun\piano_v2_audio_fix\audit\continuation_20261017\VALIDATION.json` 为唯一当前汇总；`audit/audio_diagnosis`、`tests/audio_diagnosis` 内既有记录是历史基线，不能替代本轮结果。原docs已备份到 `D:\gaoyun\piano_v2_audio_fix\audit\continuation_20261017\backup\docs`。

## 无声定位与诊断语义

原测试两周期定向失败：数据0、补零0、帧长度1、I²S延迟0，同时5152帧数据匹配、4482帧非零。接收模型没有reset输入，原逐键测试复位发射器却未调用pcm_check.restart，导致下一段首帧拼接上段残留右声道半帧。A/B同波形中正确调用restart的检查器全部0错。修复在每次DUT复位前调用现有restart任务；累计错误计数保留，末尾原PCM断言保留，并增加双声道PT8211、非零样本和覆盖检查。4096采样保持窗口长于原2048，覆盖50ms HDMI峰值发布，不以删断言、降低阈值或缩短完整16键测试制造PASS。

新增diagnostic_chain是可综合、复位后累计的真实观测，RTL内部16位计数模65536；最终GAO只捕获计数的低8位，按模256取差值，并保留完整24位峰值。GAO采样4096点、clk_12m288，约333us，可覆盖单键Loader约203us的加载；持续计数用于跨捕获查看。每键复位最容易判读；连续累计超过255次须按(after-before)&255取差，不能把低8位当无界总数。计数不是丢失计数或装饰值。FX前峰值取归一化混音饱和到24位后的幅值（大合奏可能饱和），FX后峰值取真实audio_out；均在sample_tick采样，直到复位保留，不能当作RMS或50ms窗口峰值。

|GAO diagnostic_chain位段|含义|
|---|---|
|7:0|Allocator接受分配/start脉冲次数，低8位|
|23:16|Loader ld_done次数，低8位|
|39:32|ld_done且Voice处于V_LOAD/引擎空闲的就绪完成次数，低8位|
|71:48|FX前累计绝对峰值|
|95:72|FX后累计绝对峰值|
|103:96|FIFO真正读出的Note On数，低8位|
|119:112|FIFO真正读出的Note Off数，低8位|

顶层key_note_on_count/key_note_off_count为FIFO真正写入计数；key_last_accepted_midi只在valid&&ready更新，key_frame_count为mapper接受帧数，key_stall_count为背压连续区段次数，key_rejected_frames记录Reader错误/mapper拒绝；这些计数均捕获低8位，MIDI保留完整7位。背压次数非零不代表丢事件。分配计数同拍产生实际Voice start脉冲；就绪完成只表示ld_done时的加载就绪条件，同拍若又发生新start，须按Voice控制优先级结合实际active和PCM判读，不能单凭此计数宣称可听播放。逐键复位后唯一Voice的非零PCM另行证明已经进入实际播放。

HDMI VOICE来自audio_telemetry对真实active_debug计数；PEAK是每2400个sample_tick发布的50ms绝对峰值。状态58位经request/ack稳定捆绑邮箱，在vblank更新；会有显示延迟。MIDI由最低被接纳key_state组合映射而来，不是最后已接受的FIFO事件，因此单看音名不证明Note On被处理。FFT/显示复位与音频就绪解耦。

物理DVI边界现为每通道一个syn_preserve/syn_keep局部复位寄存器，异步断言、像素边沿同步释放，额外一像素周期复位延迟（约40ns），不改变数据/时钟/管脚或音频。dvi_local_reset检查四种相位的断言/释放与连线；dvi_vendor使用真实Gowin OSER10/ELVDS行为模型，对动态RGB和重复复位的3000次DDR输出与原连线作有效复位对齐比较。便携整机仿真替换物理串行器边界，这项新RTL由上述专门测试、真实原语展开和最终Gowin时序另行覆盖，不把旧边界模型当作新物理边界已上板验证。

## 音高、音色与响度

本轮没有修改这些算法/参数；相同MIDI对应的新旧Voice/Gain/FX数组必须逐样本一致，才允许分析通过。报告 `D:\gaoyun\piano_v2_audio_fix\tests\continuation_20261017\NOTE_METRICS.csv` 列出目标频率、AMY实际partial1频率、谐波/自相关支持、音分差、RMS、谱质心、泛音/基频比、衰减、直流及削波。`D:\gaoyun\piano_v2_audio_fix\tests\continuation_20261017\wav` 内含逐音24位WAV与新/旧排列的序列，属于仿真音频。

音高：MIDI频率表及Loader地址/插值对照；AMY测量泛音并非严格整数谐波，允许其原有轻微失谐，应区分音名错误和AMY源频率偏移。音色：原参数的每4半音存储点与缺失泛音策略会造成自然差别；所有非零保留partial必须低于24kHz。响度：固定混音增益、FX与PT8211量化逐样本验证，不用高音补偿掩盖事件问题。

历史基线中MIDI64与68的0.1..0.5秒FX前RMS相差约13.18dB；当前应由本轮NOTE_METRICS复核。AMY源表、提取JSON、生成ROM和Loader独立对照只能证明差异来源与实现一致，不代表主观听感理想，更不能当作最后四个实体键无声的已证实根因。

录音源与副本SHA256均为18fdc4889cd3c85ecf7ac9c13ec7b19259446d1ed7240884a8520d728adcdfb1。当前分析重新从副本解码；无逐键事件标签、手机AGC/房间/负载未知，后段弱信号不能证明RTL未发声。原文件读取与照片复核在PATH_VERSION_AUDIT.json留证。

## 现象到证据

|现象|源码/复现/PCM证据|结论与动作|
|---|---|---|
|原逐键测试末尾PCM FATAL|tests/audio_diagnosis/tb_audio_note_map.sv；original_reset_repro与baseline_checker；非零PCM且只多1次长度错|测试复位管理根因证实；调用既有restart并保留完整检查|
|实体最后四键VOICE/PEAK=0|旧照片、当前完整链路与high_chord/stress、KEY_DIAGNOSTIC_TABLE|模型下不能复现实物故障；加真实计数，待正常/异常键最小GAO测量|
|第5键附近音色突变|旧顶层KEY_NOTE_TABLE与固定MIDI PCM|旧表可能造成72→61跳转，取决实体位序；本轮不重复修改已有连续表|
|响度与金属感|AMY源/ROM/810 Loader校验、同窗口PCM/WAV及指标|不盲调源参数；区分原音色特征、映射和模拟硬件，待带键号实测|

