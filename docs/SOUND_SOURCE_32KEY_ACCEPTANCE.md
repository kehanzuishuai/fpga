# 32 键音源验收目标



更新时间：2026-10-18T10:09:58.232596+08:00。本轮44音功能验证PASS，音质验收NOT_ACCEPTED。



1. 当前范围：直接MIDI48～91，共44个不同音高；主候选A48～79、B60～91。检查基频、起音RMS、Peak、衰减、基音/泛音、FX幅值、定点归零。

2. “ROM有参数”或“产生非零PCM”只算通路条件；音域应再通过固定力度响度/音色均匀性、无异常截断和盲听/实物试听验收。当前两个候选均有响度低谷风险，不能宣布32音优质通过。

3. 当前相对推荐A用于后续调整与试听，详见 SOUND_SOURCE_44_NOTE_RESULTS.md。未修改当前16键MIDI映射或音源参数。

4. 两块16键的硬件协议、物理键位、并发输入、同时32Voice触发、最坏混音余量和模拟输出音质，分别后续验收，不由本轮44个单音的结果代替。

5. 必须保留32 Voice、FFT、HDMI、PT8211和PCM5102A。禁止自动烧录。



[完整测量与推荐报告](D:/gaoyun/piano_v2_audio_fix/docs/SOUND_SOURCE_44_NOTE_RESULTS.md)

[离线试听页面](D:/gaoyun/piano_v2_audio_fix/tests/range44_20261018/LISTENING_ROOM.html)
