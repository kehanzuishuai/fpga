# BOARD_VALIDATION_GUIDE

工程：`D:\gaoyun\piano_v2_audio_fix`

入口：`D:\gaoyun\piano_v2_audio_fix\yinyue_fashengqi.gprj`

更新时间：2026-10-17T21:32:51.567579+08:00。数字验证：**PASS**；真实上板：**PENDING**。禁止自动烧录。

工程 `D:\gaoyun\piano_v2_audio_fix\yinyue_fashengqi.gprj`；最新候选FS `D:\gaoyun\piano_v2_audio_fix\impl\pnr\ao_0.fs`；SHA256 `d5558ec0ec34cd610896238ddf9f3d9283f8dbb3b5c497520071bb017e66b5db`；本轮实现状态 **PASS**。只在数字门禁PASS后由用户手动决定加载。本工具链没有自动烧录步骤。

1. 手离键盘复位，确认RAWS=0000、STAGE=3、MAP=0，检查工程与FS路径和哈希。每个实体键按住0.5～1秒、放开0.5秒，先正常键再异常键，每键重置计数或用模256差值。
2. 按实体1～16顺序填写 `D:\gaoyun\piano_v2_audio_fix\tests\scale_decay_20261017\BOARD_KEY_RECORD.csv`；记录one-hot raw与mapped，不能预设实体键1=raw0。目标MIDI为60+(实体编号-1)；当前raw顺序只是一份待验证配置。记录目标12/13键的边界，再核对最后四键。
3. GAO当前采样clk_12m288、深度4096（约333us），默认key_event_accepted触发。观察key_raw_frame、key_state、key_reported_state、key_fifo_accepted_state、event_valid/ready/on/note、key_last_accepted_midi、key_note_on/off_count、active_voice_count、audio_peak及diagnostic_chain。如果异常键不触发，触摸后手动force capture看保持计数和raw。
   该短窗口用于事件和约0.2ms加载过程；含预触发时未必覆盖首次PCM，更不覆盖50ms PEAK窗口。持续按住0.5秒后再force capture读sticky前后峰值和audio_peak，避免把采集窗口不覆盖误判为数字静音。
4. 每次正常按下writeOn、readOn、allocation/start、ld_done、ld_done&ld_ready应各+1；保持后pre/post峰值非零，松开writeOff/readOff各+1。GAO计数器捕获低8位，原RTL是16位；比较差值 `(after-before)&255`。diagnostic_chain [7:0]分配、[23:16]done、[39:32]done且ready、[71:48]pre峰、[95:72]post峰、[103:96]读On、[119:112]读Off。done且ready是完成时的资格计数，实际播放还需Active/PCM证据。
5. 沿第一个断点定位：raw存在但mapped无→Reader/Mapper；mapped存在但writeOn不增→Bridge/背压；write增read不增→FIFO/Core-ready；read增分配不增→Allocator；分配增done不增→Loader；正常Active但pre为0→Partial数值；pre非零post为0→Gain/FX；PCM非零而显示0→状态窗口/CDC；数字输出非零但听不见→DAC/模拟路径。不要仅凭琴键高亮判断已接收NoteOn。
6. 保存16键实测位序后，只配置KEY_RAW_MAP_ENABLE=1及KEY_RAW_INDEX_TABLE（每个逻辑键对应的raw索引从低位4bit起）；再跑三组mapping/keyboard/stress并重建。确认后才把KEY_MAPPING_CONFIRMED设为1；不要用旧profile0跳跃音符表补偿未知排列。
7. 对MIDI72～75按住两秒，比较FX关/开的WAV和板上输出，记录从NoteOn至Active/首次声响、松键时间；自然长衰减不能改成永不停止。分别听PT8211和PCM5102；进行反复复位和HDMI恢复测试，保留三通道local_rst_n修复。当前无法代替这些实物步骤。

回退：本轮前完整快照 `D:\gaoyun\piano_v2_audio_fix\audit\scale_decay_20261017\backup`、清单 `D:\gaoyun\piano_v2_audio_fix\audit\scale_decay_20261017\BEFORE.json`。只把备份中的顶层恢复到当前副本对应路径即可回退本轮生产代码；其他本轮新测试/文档可保留或移入当前副本内的归档目录。恢复FS只从该备份取，不覆盖旧正式工程。不要调用历史finalize脚本覆盖本轮报告。
