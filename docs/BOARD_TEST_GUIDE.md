# BOARD_TEST_GUIDE

工作工程：`D:\gaoyun\piano_v2_audio_fix`

工程入口：`D:\gaoyun\piano_v2_audio_fix\yinyue_fashengqi.gprj`

更新：2026-10-17T19:15:59.244408+08:00；本轮记录目录：`D:\gaoyun\piano_v2_audio_fix\audit\continuation_20261017`、`D:\gaoyun\piano_v2_audio_fix\tests\continuation_20261017`。

验证层次：源码审查及依赖哈希已留证（PATH_VERSION_AUDIT.json）；本轮仿真/数据核对=PASS；Gowin实现=PASS；真实上板=未执行，协议、实体键位及模拟音频仍待验证。

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

有效管脚文件：`D:\gaoyun\piano_v2_audio_fix\src\integrated.cst`；时钟文件：`D:\gaoyun\piano_v2_audio_fix\src\integrated.sdc`。二者本轮内容未修改。管脚报告对比：PASS。

|信号|FPGA位置 / 已有接口|
|---|---|
|clk_50m / rst_n|P16 / K16|
|TTP229 SCL / SDO|C21 / B20，原PMOD2/J26连接|
|板载BCLK / LRCK / DATA|E22 / F24 / G24|
|板载耳放使能|H17|
|PCM5102A BCLK / LRCK / DATA|C24 / B24 / H15，原PMOD1连接|
|DVI三数据对 / 时钟对|AB24/AC24，V24/W24，AA22/AA23，Y22/Y23|

上述为当前CST声明及实现报告检查，不是本轮重新测量的电路连接。没有新增外部端口、分配新管脚或调整Bank电压。保留现有板载与外接DAC。外接DAC注释中的“未激活”属于历史注释；实际顶层EXT_PCM5102已定义且有效CST已有三管脚，应以实际工程/报告为准。实物BIT-TREE协议、键盘选件、电平与物理顺序仍待确认。

Gowin确认方法：打开当前工程后检查u_synth_top/u_synth/u_core/u_bank的G_PARTIAL与32个G_VOICE，以及G_FX、G_DISPLAY；在 `D:\gaoyun\piano_v2_audio_fix\impl\gwsynthesis\RTL_GAO\gw_gao_top.v` 搜索key_note_on_count、key_last_accepted_midi和diagnostic_chain对应捕获位，在综合网表搜索三条独立local_rst_n。最终资源/时序/管脚报告均位于 `D:\gaoyun\piano_v2_audio_fix\impl\pnr`，SHA256在BUILD.json与OUTPUT_HASHES.json。HDMI应为STAGE=3、MAP=0，当前raw2000应显示MIDI73；不能把旧照片MIDI67当成当前镜像的证据。

最终最小移除裕量为 0.023 ns；须在上板时检查逻辑复位、反复启动和HDMI恢复。当前报告通过只表示本次实现的已约束数字时序通过，不代表所有未来重新布局或物理板状态均已验证。

