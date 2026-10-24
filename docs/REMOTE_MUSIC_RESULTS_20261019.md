# 本轮最终验证结果

完整工程综合、布局布线、五类时序和ESP32固件编译通过。本轮针对性验证通过；按用户要求停止重复的完整显示回归，未改动部分复用已有验证，改动的XY峰值及SPI CRC流水线补做短验证。未自动烧录；真实接线、Wi-Fi长时间连续播放和主观音质仍待上板确认。

实体32键固定为原来的32 Voice钢琴，不叠加其他乐器。手机五音色仅作用于MIDI/JSON曲谱，WAV保留录音原声。网页包已恢复修改前的原样，SHA256为`5428444eaa7aad9c41b0537b720fe516ef80e1186605d6154d6dbf38bfe253cf`。

- 工程：`D:\gaoyun\piano_v2_audio_fix\yinyue_fashengqi.gprj`
- 本次验证的FS归档：`release/latest/ao_0.fs`（也保存在下述final_build目录）
- FS SHA256：`e483552fc9993df6e9464790a9ca29d7e8253e02a51002507d05ee2234884e0b`
- 固件和FS归档：`tests/remote_music_20261019/final_build`

| 时序 | 最差裕量/ns |
|---|---:|
|setup|0.105|
|hold|0.010|
|recovery|6.742|
|removal|0.341|
|min_pulse_width|3.272|

Setup/Hold违规端点均为0。

最终实现复用了本轮完整综合的同一综合网表，仅重新布局布线；源文件、时钟频率和SDC未改变。最终PnR选项为{"place_option": 3, "route_option": 0, "timing_driven": 1, "correct_hold_violation": 1}。原始综合及前次实现结果收据保存在`audit\remote_music_20261019\routing_place3_route0_20261020\BUILD.json`，最终收据保存复用关系及网表哈希。

| 资源 | 使用/总量 |
|---|---:|
|Logic|103455/138240|
|Register|43274/139140|
|BSRAM|296/340|
|DSP|186/298|
|PLL|3/12|

有效GPRJ输入91个，原有25个端口属性不变；全部378行物理管脚表核对，仅6个空闲管脚新增ESP32接口。实际综合网表保留32个钢琴Voice及32个辅助Voice；每次选择一个音色，共32个逻辑演奏Voice。

- phone：PASS phone: WAV format rejection, byte-exact long upload with backpressure, FPGA completion feedback; real SMF0/1 tempo/running-status/rest conversion, chord/truncation rejection, JSON 32-event segmentation and distinct32 defaults
- share_equiv（复用先前结果；后续两处流水改动单独验证）：PASS shared arithmetic instrument 1: all 61 supported pitches, 32 voice samples/notes/masks and PCM frame-exact；PASS shared arithmetic instrument 2: all 61 supported pitches, 32 voice samples/notes/masks and PCM frame-exact；PASS shared arithmetic instrument 3: all 61 supported pitches, 32 voice samples/notes/masks and PCM frame-exact；PASS shared arithmetic instrument 4: all 61 supported pitches, 32 voice samples/notes/masks and PCM frame-exact；PASS time-shared arithmetic: 2048 checked PCM frames plus note transitions, zero per-voice frame differences; internal computation latency intentionally differs
- wav_formats（复用先前结果；后续两处流水改动单独验证）：PASS WAV mono24_44100: 378 raw bytes, 106 exact stereo output frames, CRC rejection and retry；PASS WAV mono24_48000: 378 raw bytes, 97 exact stereo output frames, CRC rejection and retry；PASS WAV mono16_48000: 280 raw bytes, 97 exact stereo output frames, CRC rejection and retry；PASS WAV stereo16_44100: 474 raw bytes, 106 exact stereo output frames, CRC rejection and retry；PASS WAV stereo24_44100: 668 raw bytes, 106 exact stereo output frames, CRC rejection and retry；PASS remaining five WAV formats: all eight PCM width/channel/rate combinations covered
- wav_errors（复用先前结果；后续两处流水改动单独验证）：PASS compressed WAV rejection and invalid SPI sequence；PASS malformed RIFF data length rejected；PASS truncated upload rejected and abort flushes bytes/PCM；PASS starved stream reports underrun and silences both channels after 1523 frames；PASS WAV error paths
- wav_dac（复用先前结果；后续两处流水改动单独验证）：PASS WAV stereo24_dac: 1622 raw bytes, 256 exact stereo output frames, CRC rejection and retry；PASS stereo WAV through real async mailbox and actual dual DAC transmitters: 256 exact WAV captures, 636 PCM5102 frames, 1272 PT8211 words；PASS WAV integration
- native_wav（复用先前结果；后续两处流水改动单独验证）：PASS real WavLink.h: sequence wrap, lost ACK retry, byte-exact 1622 bytes, status CRC rejection, cancellation; actual transfers recorded for RTL replay
- native_replay（复用先前结果；后续两处流水改动单独验证）：PASS actual firmware C++ SPI-byte replay -> production RIFF/PCM/CDC -> dual DAC: 256 exact stereo WAV frames, 614 PCM5102 frames, 1229 PT8211 words; retry caused no duplicated PCM
- native_http（复用先前结果；后续两处流水改动单独验证）：PASS actual WavService RAW callbacks: 8192-byte NUL/all-byte bodies exact, header metadata without query args, duplicate/CRC/queue backpressure, overflow/truncation/abort/multipart/stale-session rejection and END retries
- control（复用先前结果；后续两处流水改动单独验证）：PASS real UART control: physical keys remain piano under all phone timbre selections, score-only timbre and final NoteOff/piano rearm, volume, FX, duplicate map rejection, atomic 32-key commit/retry and busy rejection
- aux（复用先前结果；后续两处流水改动单独验证）：PASS instrument 1: all 32 notes active, 4095 nonzero frames, zero scheduler overruns；PASS instrument 2: all 32 notes active, 4095 nonzero frames, zero scheduler overruns；PASS instrument 3: all 32 notes active, 4094 nonzero frames, zero scheduler overruns；PASS instrument 4: all 32 notes active, 4095 nonzero frames, zero scheduler overruns；PASS auxiliary32 integration
- preserve（复用先前结果；后续两处流水改动单独验证）：PASS preserve16: 518527 clocks, 2025 PCM samples and both DAC pins bit-exact to backed-up old RTL; 4 Note events; unconnected bank2 and ESP32 silent
- gate_aux（复用先前结果；后续两处流水改动单独验证）：PASS actual Gowin shared lane instrument 1: 8 voices, one arithmetic engine, 512 PCM frames bit exact；PASS actual Gowin shared lane: 512 PCM frames, instrument selection 1; zero cycle-by-cycle RTL mismatches; full32 tested separately in RTL；PASS actual Gowin shared lane instrument 2: 8 voices, one arithmetic engine, 512 PCM frames bit exact；PASS actual Gowin shared lane: 512 PCM frames, instrument selection 2; zero cycle-by-cycle RTL mismatches; full32 tested separately in RTL；PASS actual Gowin shared lane instrument 3: 8 voices, one arithmetic engine, 512 PCM frames bit exact；PASS actual Gowin shared lane: 512 PCM frames, instrument selection 3; zero cycle-by-cycle RTL mismatches; full32 tested separately in RTL；PASS actual Gowin shared lane instrument 4: 8 voices, one arithmetic engine, 512 PCM frames bit exact；PASS actual Gowin shared lane: 512 PCM frames, instrument selection 4; zero cycle-by-cycle RTL mismatches; full32 tested separately in RTL
- audio_top（复用先前结果；后续两处流水改动单独验证）：PASS physical32 piano under phone selection 0: all 32 piano voices heard, auxiliary masks zero, no fade/reset；PASS physical32 piano under phone selection 1: all 32 piano voices heard, auxiliary masks zero, no fade/reset；PASS physical32 piano under phone selection 2: all 32 piano voices heard, auxiliary masks zero, no fade/reset；PASS physical32 piano under phone selection 3: all 32 piano voices heard, auxiliary masks zero, no fade/reset；PASS physical32 piano under phone selection 4: all 32 piano voices heard, auxiliary masks zero, no fade/reset；PASS full board physical32 piano only under all five phone score selections; master mute; 2889 exact PCM5102 frames
- score_top（复用先前结果；后续两处流水改动单独验证）：PASS phone-only flute score, exclusive ownership, graceful final NoteOff, clear auxiliary bank, then all 32 held physical keys rearmed as piano; 2752 exact PCM5102 frames
- xy_timing：PASS XY bitmap: circle/line/ratio/low-level/high-frequency/DC/silence/mixed/extremes; connected segments within vblank
- spi_timing：PASS SPI timing pipeline: 8 real 4MHz status transactions, independent CRC, moving fields coherent, CS snapshot stable
- gate_loader32：Actual current integrated piano Loader/ROM: 32 notes, 12800 words, zero model mismatches; captured request pitch/inc forced, keyboard/allocator outside this isolated scope

完整system仿真本轮已按用户要求停止，当前没有新的整帧HDMI通过结论。旧完整显示结果仅按显示模块依赖哈希复用；XY新增流水级的10张位图与此前完全一致，每帧增加512个像素时钟，仍在消隐预算内。

`audit/remote_music_20261019/FINAL_ACCEPTANCE.json`保存源文件/产物哈希、资源、管脚及完整结果。原始输入与修改前备份均保留。完整工具警告见`tests/remote_music_20261019/out/gowin.log`；通过不等同于零警告。

键索引和FIFO计数已提前显式声明，本轮EX3638前向隐式声明警告为0。综合仍保留EX3791原有位宽截取和NL0002层级/未用逻辑优化；EX3791所涉及的PLL、钢琴参数/分音及显示标签源码与修改前一致。

时序/实现工具提示：

- WARN  (PR1014) : Generic routing resource will be used to clock signal 'clk_50m_d' by the specified constraint. And then it may lead to the excessive delay or skew
- WARN  (TA1132) :  'tck_pad_i' was determined to be a clock but was not created.

其中GAO的`tck_pad_i`是未显式建钟的调试接口；本次五类时序通过指当前SDC覆盖的设计时钟检查，不包含外部JTAG时序验收。新SPI接口采用50MHz过采样同步器，上板线长、IO延迟及真实传输连续性仍需实测。
