# KEY_MAPPING_FIX

工程：`D:\gaoyun\piano_v2_audio_fix`

入口：`D:\gaoyun\piano_v2_audio_fix\yinyue_fashengqi.gprj`

更新时间：2026-10-17T21:32:51.567579+08:00。数字验证：**PASS**；真实上板：**PENDING**。禁止自动烧录。

旧 `keyboard_v2` 顶层在 KEYBOARD_PROFILE=0 时选择 60,64,68,72,61,65,69,73,62,66,70,74,63,67,71,75。当前 audio_fix 本轮开始前已是60～75，上一版 FS 的全部启用输入哈希与本轮快照一致。因此此前两个结论来自不同源码版本；未发现 gprj、构建 Tcl 或 GUI 配置覆盖这些参数。旧照片 raw2000→MIDI67 与旧表一致，当前配置为73。不能从旧照片推断已加载当前FS。

实际代码变更位于 `D:\gaoyun\piano_v2_audio_fix\src\tang_mega_138k_pro_top.v.v`：第43行新增7位 KEY_BASE_NOTE=60；第45行把默认表明确写为16个 KEY_BASE_NOTE+i；第337行把桥的BASE_NOTE连接到同一参数。默认输出本轮前后均为60～75，不能把本轮配置改进宣称为再次修复默认跳跃音阶。

KEYBOARD_PROFILE=0仅选择Reader镜像保护；KEY_RAW_MAP_ENABLE=0；默认 RAW_INDEX_TABLE=fedcba9876543210，关闭重排时不参与计算。开启时，表的第 i 个低位4bit字段选择逻辑键 i 对应的 raw bit。KEY_NOTE_TABLE可显式覆盖默认音阶；使用连续默认表时 KEY_BASE_NOTE可用范围0～112。Event Bridge始终USE_NOTE_TABLE=1，直接接收16位mapper状态；本轮未修改桥、Reader或Mapper算法。

| 目标实体键（未实测） | 配置raw bit | 逻辑键 | 旧profile0 MIDI | 本轮开始前 MIDI | 当前RTL仿真 MIDI | 目标音符 | 目标Hz |
|---|---|---|---|---|---|---|---|
| 1 | 0 | 0 | 60 | 60 | 60 | C4 | 261.625565 |
| 2 | 1 | 1 | 64 | 61 | 61 | C#4 | 277.182631 |
| 3 | 2 | 2 | 68 | 62 | 62 | D4 | 293.664768 |
| 4 | 3 | 3 | 72 | 63 | 63 | D#4 | 311.126984 |
| 5 | 4 | 4 | 61 | 64 | 64 | E4 | 329.627557 |
| 6 | 5 | 5 | 65 | 65 | 65 | F4 | 349.228231 |
| 7 | 6 | 6 | 69 | 66 | 66 | F#4 | 369.994423 |
| 8 | 7 | 7 | 73 | 67 | 67 | G4 | 391.995436 |
| 9 | 8 | 8 | 62 | 68 | 68 | G#4 | 415.304698 |
| 10 | 9 | 9 | 66 | 69 | 69 | A4 | 440.000000 |
| 11 | 10 | 10 | 70 | 70 | 70 | A#4 | 466.163762 |
| 12 | 11 | 11 | 74 | 71 | 71 | B4 | 493.883301 |
| 13 | 12 | 12 | 63 | 72 | 72 | C5 | 523.251131 |
| 14 | 13 | 13 | 67 | 73 | 73 | C#5 | 554.365262 |
| 15 | 14 | 14 | 71 | 74 | 74 | D5 | 587.329536 |
| 16 | 15 | 15 | 75 | 75 | 75 | D#5 | 622.253967 |

表中“实体键”是目标编号，raw列是当前配置，不是GAO测量。全部实体位序仍待GAO确认，KEY_MAPPING_CONFIRMED=0。先记录实体1～16的one-hot raw状态，再配置 RAW_INDEX_TABLE；音符表保持逻辑0～15连续。

三次独立实际顶层展开测试：默认base60、非恒等raw置换base60、默认raw的base48，均16个唯一音符，37 On/37 Off，包含高四位组合、独立松键及全16键。输出 `D:\gaoyun\piano_v2_audio_fix\tests\scale_decay_20261017/mapping_*.csv`、VCD、日志。HDMI的status_note直接使用同一NOTE_TABLE，测试核对其与最低被按逻辑键一致；联合测试另外验证真实CDC和TMDS输出。MIDI对应的基础DDS满足十二平均律（仅有32位量化）；AMY测量的Partial1仍有原有约3～10音分偏差，测得基频和实际相邻频率比见NOTE_METRICS，不冒充严格相等。

证据：`D:\gaoyun\piano_v2_audio_fix\tests\scale_decay_20261017\MAPPING_PROVENANCE.json`、`D:\gaoyun\piano_v2_audio_fix\tests\scale_decay_20261017\KEY_MAPPING_COMPARISON.csv`。本轮开始前可用FS已备份：`D:\gaoyun\piano_v2_audio_fix\audit\scale_decay_20261017\backup\impl\pnr\ao_0.fs`，SHA256 `accb0d9b529278de59717c678e50b787b297aa367da85794ff0efce467870a96`。

最新构建状态PASS，FS哈希 `d5558ec0ec34cd610896238ddf9f3d9283f8dbb3b5c497520071bb017e66b5db`；完整启用源码/约束/GAO/GUI过程配置哈希与实际默认参数组合保存在 `D:\gaoyun\piano_v2_audio_fix\audit\scale_decay_20261017\BUILD.json`。该记录与本轮默认展开仿真和当前文件逐项匹配，不能把当前代码与另一个目录的旧FS混用。
