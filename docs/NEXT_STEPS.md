# NEXT_STEPS

工作工程：`D:\gaoyun\piano_v2_audio_fix`

工程入口：`D:\gaoyun\piano_v2_audio_fix\yinyue_fashengqi.gprj`

更新：2026-10-17T19:15:59.244408+08:00；本轮记录目录：`D:\gaoyun\piano_v2_audio_fix\audit\continuation_20261017`、`D:\gaoyun\piano_v2_audio_fix\tests\continuation_20261017`。

验证层次：源码审查及依赖哈希已留证（PATH_VERSION_AUDIT.json）；本轮仿真/数据核对=PASS；Gowin实现=PASS；真实上板=未执行，协议、实体键位及模拟音频仍待验证。

数字验证：**PASS**。实物功能验收：**PENDING**。

本轮修复测试平台跨复位半帧残留，增加真实事件链GAO诊断，对齐GUI/CLI过程选项，并针对已复现的视频串行器复位恢复负裕量增加逐通道局部复位。未修改AMY参数、ROM、Loader算法、Partial算法、Allocator调度、增益或FX算法。raw bit0..15→MIDI60..75是上一轮已存在的映射，本轮保留；实体键位与实物协议仍未确认。

最后四个实体键无声：当前协议模型下未复现，不能报告实物故障已修复。原照片只证明mapper状态和组合MIDI曾显示，不能确定Note On已被FIFO接受或声音已启动；照片中的旧表MIDI为67/71/75，不能混作当前73/74/75。

本轮记录 `D:\gaoyun\piano_v2_audio_fix\audit\continuation_20261017\VALIDATION.json` 为唯一当前汇总；`audit/audio_diagnosis`、`tests/audio_diagnosis` 内既有记录是历史基线，不能替代本轮结果。原docs已备份到 `D:\gaoyun\piano_v2_audio_fix\audit\continuation_20261017\backup\docs`。

待真实板上确认：实体1..16到raw位序；BIT-TREE芯片/选件及SDO整帧；正常键与异常键GAO握手差值；板载模拟输出与同MIDI数字PCM的对照。若计数链全部前进而模拟仍无声，再测板载DAC串行/耳放/负载。只有硬件证据定位后才针对相关级修改；音色算法变更须先局部A/B与资源评估。

数字检查若仍有NOT_RUN/RUNNING/FAIL，继续对应日志中的实际命令，不把历史PASS当作当前结果。硬件验收未完成前保持MAP=0，不发布“实物全修复”结论，不自动下载。

## 最小人工测量

1. 先确认本轮数字验证和时序门禁已PASS，再自行选择是否加载诊断镜像；本任务未连接下载器、未自动烧录。打开 `D:\gaoyun\piano_v2_audio_fix\yinyue_fashengqi.gprj`，芯片GW5AST-LV138FPG676AC1/I0、Device C；GUI选项应为SystemVerilog2017、顶层tang_mega_138k_pro_top、开启文本时序报告。
2. 当前FS候选：`D:\gaoyun\piano_v2_audio_fix\impl\pnr\ao_0.fs`；本轮构建状态 `PASS`；SHA256：`accb0d9b529278de59717c678e50b787b297aa367da85794ff0efce467870a96`。它是诊断候选，实物功能尚未验收，不能当作最终声音已修复的交付版。
3. 如人工进行上板诊断，复位后先空手等待RAWS稳定为0000，再单独短按一个已知正常键，记录实体编号、RAWS、显示MIDI；再分别对实体13、14、15、16做按下0.5秒、松开0.5秒。为比较计数可每键复位，或取前后差值。不要默认实体编号等于raw bit+1。
4. 在当前GAO中默认用key_event_accepted触发，保持clk_12m288/4096点。记录key_raw_frame、key_state、frame_valid/error、key_note_on_count/off_count、key_last_accepted_midi、diagnostic_chain、active_voice_count。先比较正常键与异常键各一组；无需先测全部引脚。HDMI另记录VOICE/PEAK。若始终不触发，可按下后手动强制捕获，查看保留的计数与raw；不要把未触发当作没有raw。
5. 单键预期：FIFO写On+1、读On+1、分配/start脉冲+1、Loader完成+1、就绪完成+1，FX前后峰值非零；松开时FIFO写/读Off各+1。当前raw bit12/13/14/15应发MIDI72/73/74/75；照片中的旧bit13/14/15为67/71/75，两版不能混记。
6. raw有变化但mapper无变化：查帧错误/镜像/确认；mapper变化而写On不增：查Bridge/背压；写增读不增：查FIFO/Loader busy；读增分配不增：查分配；分配增Loader不增：查加载等待；Loader增就绪完成不增：查Voice状态；完成增且FX前零：查参数/Voice/同拍重启；FX前非零FX后零：查FX；两者非零且耳机无声：再查板载串行输出/模拟DAC/耳放/负载。
7. 最小回传数据是一个正常键和一个异常键的上述计数前后值及原始捕获；另附实体编号与raw十六进制。可用 `D:\gaoyun\piano_v2_audio_fix\tests\continuation_20261017\BOARD_KEY_RECORD.csv` 记录全16键。若需确认协议，再测SCL/SDO一整帧的16个脉冲、极性及键盘型号/选件；不要先改I²C或Bank电压。

## 回退

本轮修改前源码、配置与旧FS位于 `D:\gaoyun\piano_v2_audio_fix\audit\continuation_20261017\backup`；前哈希在 `D:\gaoyun\piano_v2_audio_fix\audit\continuation_20261017\before.json`。要回退时，先在当前工程内另存当前状态，再只将变更表中有旧版本的文件从backup复制回同一相对路径。新建过程配置原来不存在，可在当前工程内移入回退归档以恢复原默认行为。旧FS只在用户明确选择时人工加载；不回写任何只读旧工程。

