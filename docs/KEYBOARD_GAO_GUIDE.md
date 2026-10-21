# KEYBOARD_GAO_GUIDE

工作工程：`D:\gaoyun\piano_v2_audio_fix`

工程入口：`D:\gaoyun\piano_v2_audio_fix\yinyue_fashengqi.gprj`

更新：2026-10-17T19:15:59.254686+08:00；本轮记录目录：`D:\gaoyun\piano_v2_audio_fix\audit\continuation_20261017`、`D:\gaoyun\piano_v2_audio_fix\tests\continuation_20261017`。

验证层次：源码审查及依赖哈希已留证（PATH_VERSION_AUDIT.json）；本轮仿真/数据核对=PASS；Gowin实现=PASS；真实上板=未执行，协议、实体键位及模拟音频仍待验证。

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

Gowin确认方法：打开当前工程后检查u_synth_top/u_synth/u_core/u_bank的G_PARTIAL与32个G_VOICE，以及G_FX、G_DISPLAY；在 `D:\gaoyun\piano_v2_audio_fix\impl\gwsynthesis\RTL_GAO\gw_gao_top.v` 搜索key_note_on_count、key_last_accepted_midi和diagnostic_chain对应捕获位，在综合网表搜索三条独立local_rst_n。最终资源/时序/管脚报告均位于 `D:\gaoyun\piano_v2_audio_fix\impl\pnr`，SHA256在BUILD.json与OUTPUT_HASHES.json。HDMI应为STAGE=3、MAP=0，当前raw2000应显示MIDI73；不能把旧照片MIDI67当成当前镜像的证据。

最终最小移除裕量为 0.023 ns；须在上板时检查逻辑复位、反复启动和HDMI恢复。当前报告通过只表示本次实现的已约束数字时序通过，不代表所有未来重新布局或物理板状态均已验证。

