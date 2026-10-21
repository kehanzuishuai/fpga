# AUDIO_FIX_CHANGELOG

工程：`D:\gaoyun\piano_v2_audio_fix`

入口：`D:\gaoyun\piano_v2_audio_fix\yinyue_fashengqi.gprj`

更新时间：2026-10-17T21:32:51.567579+08:00。数字验证：**PASS**；真实上板：**PENDING**。禁止自动烧录。

本轮生产RTL只改 `D:\gaoyun\piano_v2_audio_fix\src\tang_mega_138k_pro_top.v.v`：43行新增KEY_BASE_NOTE，45行生成连续逻辑音阶默认表，337行桥BASE_NOTE复用。默认音阶在本轮开始前已修正为连续，因此本轮改变的是配置表达与可测试性，默认输出未变。KEYBOARD_PROFILE、raw配置和物理未确认标记保留。

新增独立映射、32Voice直接MIDI、VOICE/PEAK窗口测试与数值分析脚本，完整路径和SHA见 `D:\gaoyun\piano_v2_audio_fix\audit\scale_decay_20261017\FILE_CHANGES.json`。没有修改AMY/ROM/Loader/Partial/Allocator/Gain/FX/双DAC/FFT/HDMI算法、引脚、电压或时钟；DVI局部复位修复保留。报告中的自然衰减及门限不作为错误进行主观调音。

开始前备份204个文件，最近可用FS哈希 `accb0d9b529278de59717c678e50b787b297aa367da85794ff0efce467870a96`，新FS哈希 `d5558ec0ec34cd610896238ddf9f3d9283f8dbb3b5c497520071bb017e66b5db`。回退到 `D:\gaoyun\piano_v2_audio_fix\audit\scale_decay_20261017\backup` 中对应顶层及已保存FS，仍只写当前副本。每份测试meta保留命令、起止、返回值和输入哈希；唯一当前汇总 `D:\gaoyun\piano_v2_audio_fix\audit\scale_decay_20261017\VALIDATION.json`；历史continuation目录保留，不运行其finalize覆盖当前结论。
