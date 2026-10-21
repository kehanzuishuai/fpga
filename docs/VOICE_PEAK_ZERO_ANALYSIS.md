# VOICE_PEAK_ZERO_ANALYSIS

工程：`D:\gaoyun\piano_v2_audio_fix`

入口：`D:\gaoyun\piano_v2_audio_fix\yinyue_fashengqi.gprj`

更新时间：2026-10-17T21:32:51.567579+08:00。数字验证：**PASS**；真实上板：**PENDING**。禁止自动烧录。

VOICE直接对voice_active位图计数：`D:\gaoyun\piano_v2_audio_fix\src\audio_telemetry.v` 的组合循环；`D:\gaoyun\piano_v2_audio_fix\src\piano_partial_voice.v` 的active=(vstate!=V_IDLE)，包含加载、播放和偷音淡出，不取决于音频阈值，普通衰减时可在所有Partial门控后进入IDLE。env_level在Partial引擎中为0不等于active=0。

PEAK对最终FX后audio取绝对值，累计2400个48k采样（50ms）后发布整窗最大值，再清内部peak_work。公开audio_peak保留上次已完成窗口，直到下次发布；短按后可晚出现，再随后续全零窗口清零。HDMI的58位mailbox在音频pcm_valid时尝试快照，像素vblank时更新；不是每拍直播，短于刷新周期的Active事件可能遗漏。持续0.5秒的正常高音不能仅用这种采样遗漏解释。

本轮定向RTL证明：active=80000000且audio=0时VOICE=1、PEAK=0；active=0且audio=-6789时整窗后VOICE=0、PEAK=6789；所有32位active为1时VOICE=32。第2399采样尚未发布，第2400采样发布12345。见VOICE_PEAK_DEFINITION.csv和voice_peak.log。

顶层键盘高亮与桥共用mapper的16位key_state。HDMI MIDI是最低置位逻辑键的组合音符，不等于已被FIFO接受的最后MIDI。bridge的key_reported_state可能在输出事件挂起时已前进；确认接收应看event_valid&&event_ready、key_fifo_accepted_state、key_last_accepted_midi、key_note_on_count。实际FIFO读出计数与分配/加载计数继续区分下游边界。

本轮逻辑键11(MIDI71，实体目标12)与逻辑键12(MIDI72，实体目标13)，以及逻辑12～15(MIDI72～75)均通过On/Off、分配和非零PCM。DIRECT_MIDI.csv每音write On/Off=1/1、allocation=1、load=1、read On/Off=1/1、held VOICE=1。短注入只有约10.7ms按住，50msPEAK窗口尚未完成，不能把其PEAK=0当失败；较长的既有逐键4096采样测试和本轮联合压力测试验证非零窗口及实际显示快照。

Reader保留默认镜像保护：未确认16键时，上下字节相同的镜像帧可能屏蔽高8位；冷启动直接出现FFFF也受此策略影响。单独raw1000/2000/4000/8000会证明16模式并保留高位。这不是0FFF或12位截取。逻辑层的全16键无丢事件验证不能冒充冷启动镜像帧已无条件放行。实物BIT-TREE协议/位序未知，BFM通过不等于芯片模式已证实；实测确认16键协议后可评估KEYBOARD_PROFILE=1并重跑Reader和联合测试。本轮没有无依据更改该策略。

当前不能报告已找到真实最后四个实体键的零VOICE/PEAK根因，也不能断言它们就是MIDI72～75或某一确定事件链缺陷。需要同一新FS下逐键记录raw、mapped、真实FIFO写/读、last accepted MIDI、allocation、Loader、Active、前后PCM峰值、按住/松开时序，定位第一个不增长的边界。数据表见BOARD_KEY_RECORD.csv。数字测试排除了“这些MIDI本身必然静音”，没有排除板载版本、真实输入、事件传递或显示时序差异。
