# 44音响度校准与尾音修复：组合版本验证结果

完成时间：2026-10-18T14:40:16.556198+08:00。唯一修改工程：`D:\gaoyun\piano_v2_audio_fix`。工程入口：`D:\gaoyun\piano_v2_audio_fix\yinyue_fashengqi.gprj`。**没有自动烧录。**

**实际生产RTL已修改，新增补偿模块已以enable=1加入GPRJ，并完成最终组合版本的68项回归、直接MIDI、联合仿真、综合、布局布线及所报告时序检查。**

## 生产改动

- `src/piano_partial_voice.v`：修复持键期间所有partial短暂门控为0时直接IDLE、丢弃后续包络的问题。加载时记录21段未来可发声断点，完成一段清一位；未来仍可发声时保留Voice，NoteOff和偷音仍正常退出。每Voice增加21bit状态，没有改变16partial/32Voice或每采样210clk的计算期限。
- `src/piano_note_gain.v`：新增固定按音高的Q13补偿表，覆盖48～91，区间外单位增益。用真实力度100、100～500ms RMS拟合-30dBFS；增益最多4倍（12.04dB），同时约束全力度扫描峰值保留至少7dB原始Voice余量。不是运行时AGC，不随尾音增加增益。
- `src/voice_bank.v`：在每个原始Voice之后、混音之前接入补偿。新系数在Loader完成时生效，旧音偷音淡出期间保留旧系数，避免切换幅度。
- `tools/fpga_piano_model.py`同步尾音退出条件；`tools/note_gain_model.py`和`tools/compare_system.py`同步补偿及真实混音的参照计算。原始Voice逐样本模型仍单独验证。
- `.gprj`原63个启用条目全部保留，新增`src/piano_note_gain.v`启用；测试台/脚本/表格和文档均禁用综合。最终综合网表确认32个Voice全部存在，未编译测试台。

未修改ROM参数、泛音频率、FX算法、键盘默认映射、CST/SDC、引脚、电压、PLL、FFT/HDMI或双DAC接口。顶层仍BUILD_STAGE=3、显示开启、实体16键逻辑MIDI60～75；推荐音域不自动改变当前硬件键盘。

## A/B响度改善

力度100；早期RMS为100～500ms，未经额外WAV归一化。RMS是PCM能量指标，不是感知响度单位。

|方案|链路|修改前RMS跨度dB|修改后RMS跨度dB|修改后标准差dB|最大相邻RMS差dB|
|---|---|---:|---:|---:|---:|
|A 48～79|fx_off|13.184|0.140|0.024|0.140|
|A 48～79|fx_on|12.352|2.062|0.562|1.576|
|B 60～91|fx_off|23.708|4.856|1.393|2.628|
|B 60～91|fx_on|24.235|6.958|1.685|3.102|

**推荐方案A：MIDI48～79（C3～G5）**，作为真实32键演奏的优先音源候选。它在统一力度下更均匀、弱力度离散较小。方案B的高音仍受峰值余量约束，无法安全地全部拉平；84～91原始频谱仍以基音为主，补偿没有填造泛音。不能据此宣布32个音色已经“优秀”。

以下仍需统一播放音量试听和板上确认：音色偏薄是否可接受、低音至高音的自然衰减差异、强力度软限幅听感。两块16键接入和同时32音的硬件/复音验收保持独立；当前仿真压力通过不等于完成该实物验收。

## 全44音测量与试听

- 试听页：`D:\gaoyun\piano_v2_audio_fix\tests\calibration_20261018\LISTENING_ROOM.html`。
- 44音逐音88行测量：`D:\gaoyun\piano_v2_audio_fix\tests\calibration_20261018\NOTE_METRICS_44.csv`，含基频、起音RMS、Peak、衰减、基音/泛音、FX前后幅度、PT8211量化及零样本。
- 对照：`D:\gaoyun\piano_v2_audio_fix\tests\calibration_20261018\BEFORE_AFTER_88.csv`、`D:\gaoyun\piano_v2_audio_fix\tests\calibration_20261018\AB_BEFORE_AFTER.csv`、`D:\gaoyun\piano_v2_audio_fix\tests\calibration_20261018\GAIN_COEFFICIENTS_44.csv`。
- 可携带试听包：`D:\gaoyun\piano_v2_audio_fix\tests\calibration_20261018\calibration44_listening_pack.zip`。
- 图：`D:\gaoyun\piano_v2_audio_fix\tests\calibration_20261018\calibration_before_after.png`。

主试听为力度100、48kHz/24bit，每音2秒持键+1秒释放，44音均有FX前后WAV。原始Voice为本轮新3秒RTL，之后通过真实补偿RTL和真实FX RTL；补偿输出另完整导出并逐样本比对。masterQ15中间算术与真实32Voice直接通路独立核对。分段组合证据不冒充44次完整板级3秒仿真，也不是模拟DAC录音。每个主音频样本具有源文件/RTL哈希记录；序列无额外逐音归一化或试听淡出。

44音在两链路基频均可靠、严格递增；无无声音和主测试硬削波。保留原AMY频率的调音偏差，最大约14.47cent，不把ROM原有调音误差当作补偿修复。补偿前后干声基音/泛音比变化最多0.00006dB，说明没有用改变谱包络掩盖响度问题。

## 力度曲线、削波与量化

- 44音×力度1～127，共5588次1秒整数模型扫描；没有大于0.1dB的相邻力度早期RMS倒退。固定系数保留每个音原有力度曲线；原Loader在120～127钳位为同层，仍为平台，不宣称127个互异响度。
- 每音力度1/20/40/60/80/100/120/127，共352次FX模型屏查，无补偿饱和、FX输入饱和、输出硬削波或硬平台。力度40/80/120的全部44音又逐样本运行真实补偿+FX RTL；这些次要测试的输入Voice来自整数模型，主力度100来自真实Voice RTL。
- 44音×力度40/100/120，共132次最长30秒的自然长按模型，均有限退出，无补偿饱和；强力度完整自然包络峰值也保持约7dB或更多原始Voice余量。不能把1秒扫描说成全部127力度的30秒实际RTL。
- FX保留现有软限幅。代表力度模型测试中最多有4.858%采样进入软拐点；强力度可能受到轻微压缩，不能把“无硬削波”说成完全线性。复音压力另按原测试检查，仍不等于任何32音强力度组合都不触发限幅。
- 加在原Voice之后的补偿不能恢复原AMP_GATE已经置零的样本。方案B高音极弱力度仍明显偏弱/较早接近量化底噪；MIDI91的极弱力度100～500ms原始Voice可完全为0，FX残响的非零不能当成持续发声。没有靠增益掩盖这一限制。方案A更适合当前源的32键候选。
补充44音×32个Voice噪声种子、力度120的1秒模型检查，共1408次；最小干声峰值余量6.891dB，无单音硬削波。每音另取干声峰值最大的种子送FX模型，也无输出硬削波。7dB是拟合时参考Voice0的目标，各种子有微小差异；本检查不是所有力度、种子和32音组合的穷举。

自然长按FX衰减另外用44音完整整数模型核对，在源结束后继续输入4秒零，所有FX末尾1秒均为精确零；表NATURAL_DECAY_SOURCE_AND_FX.csv列出FX前后T20/T40/T60和最终非零时间。NOTE_METRICS_44.csv的自然衰减字段按FX前/后分别填写，字段带model标记；这不是额外44次长时RTL。

实际6336000个补偿RTL样本的误差均在−1至0 LSB之间，44个Voice最后100ms精确为零，具体产品/移位/正小数归零/负数向下取整示例见GAIN_FIXED_POINT_44.csv及GAIN_FIXED_POINT_EXAMPLES.csv。有限长度音符的均值不等于永久直流；固定增益会放大已有hammer/noise，不声称降低其原始底噪。


## 尾音缺陷的实证修复

|MIDI|修复前自然归零s|修复后自然归零s|恢复非零样本|
|---:|---:|---:|---:|
|87|3.059167|5.013104|90208|
|88|2.995542|5.377146|97488|
|89|2.890938|4.290000|17303|

同一人工断点用例在旧RTL重现临时静音提前结束，新RTL通过9项定向检查。4096个exp ROM代码核对最后可发声门限3301。87/88/89均额外新跑6秒持键RTL，直到旧退出点输出完全相同，之后恢复原ROM规定的极弱尾音并有限退出；真实FX RTL也核对通过。全部44音的2秒持键/1秒释放原始Voice在此退出修复前后完全相同。尾音原幅度与仅尾段+48dB诊断对照保存在tests/tail_fix_20261018，不把诊断放大当作FPGA音量。

## 最终组合版本验证

- 原68项完整回归：68 tests, 0 failed。包括键盘/ROM、短长Voice、FX、Stage1/2/3、DAC变异测试、全系统及偷音压力。
- 实际32Voice synth_top的全部44音直接FIFO注入：每音512 held+512 release ticks，验证原Voice、补偿后Mixer、Q15主增益、FX、Loader/On/Off和PCM5102帧。
- 默认/重排/转调三套映射、键盘/状态、FFT/HDMI、32Voice与双DAC联合压力、真实Gowin原语展开通过。
- src与约束哈希在构建前后稳定；所有Pin Details字段与构建前逐项相同。未减少Voice、FFT、HDMI、GAO或DAC。

|时序检查|最差Slack ns|
|---|---:|
|setup|13.439|
|hold|0.138|
|recovery|2.775|
|removal|0.025|
|min_pulse_width|7.128|

Setup/Hold违反端点：{'Setup': 0, 'Hold': 0}。上述是当前约束下报告的STA检查，不代替板上时钟、复位和HDMI恢复验收。

|资源|使用/可用|
|---|---:|
|Logic|47084/138240|
|Register|17741/139140|
|BSRAM|258/340|
|DSP|130.5/298|
|PLL|2/12|

音频时钟约束仍为12.288MHz，报告Fmax 23.440MHz；像素约束25.000MHz，报告Fmax 37.650MHz。未降低时钟来通过检查。没有普通内部路径Fmax的串行视频域不冒称其目标频率就是实测Fmax。

回归调度修改仅在sim/run_tests.py与sim/parallel_regression.py：并发原测试组，system/stress使用不同VVP输出名；原始场景时长和断言保留。REGRESSION_COVERAGE.json逐项比较原版与最终版68个唯一测试名称，均通过。TESTED_SOURCES.json核对每次仿真的实际RTL/ROM、原测试台和参照工具哈希；广义输入快照也包含FS输出和禁用审阅文件，并行构建可能改变这些非仿真输入，原始标志保留而不伪改为不变。

警告基线77条，本轮77条；新增/增多0条，详见WARNING_COMPARISON.json。继承的TA1132（tck_pad_i未显式创建时钟）和PR1014（clk_50m_d通用布线）如仍存在，应按日志保留解释；没有用删除功能或放宽约束获得通过。

工程：`D:\gaoyun\piano_v2_audio_fix\yinyue_fashengqi.gprj`。新FS：`D:\gaoyun\piano_v2_audio_fix\impl\pnr\ao_0.fs`。
FS SHA256：`9689bf3b0085a3830a0cea5592a8c21831679e4a345711bb31d4fb3d2853aecd`。
综合报告：`D:\gaoyun\piano_v2_audio_fix\impl\gwsynthesis\yinyue_fashengqi_syn.rpt.html`。
时序报告：`D:\gaoyun\piano_v2_audio_fix\impl\pnr\yinyue_fashengqi.tr`。
布局布线：`D:\gaoyun\piano_v2_audio_fix\impl\pnr\yinyue_fashengqi.rpt.txt`。
完整构建日志：`D:\gaoyun\piano_v2_audio_fix\tests\calibration_20261018\gowin.log`；准确命令/输入输出哈希：`D:\gaoyun\piano_v2_audio_fix\audit\calibration_20261018\BUILD.json`。

## 仍待实物确认

实体最后四键VOICE/PEAK为零的根因仍无板上事件链证据。直接MIDI和映射仿真说明16个逻辑输入均可到达Note On，不能推断实际Reader/raw bit/硬件顺序已经正常。需按既有GAO流程在板上抓Reader→Mapper→Event Bridge→FIFO→Allocator→Loader→Voice链路。本轮没有把尾音/增益修复冒充该物理问题的修复。

回退快照：audit/tail_fix_20261018/backup是本轮声音修改前的源码、GPRJ和FS（7829d74b…）；模型精确恢复记录见MODEL_BACKUP_RECOVERY.json。audit/calibration_20261018/backup是校准接入前、已含尾音源码修复的快照，其FS仍是修改前版本，不能混称已构建尾音版。所有更早44音报告保持历史基线，本报告对应最新组合源码和新FS。

**验收结论：数字功能与本轮客观均衡/数值检查通过；优先推荐A。主观“32个优质音色”及真实硬件接入/复音验收仍待统一音量听评和上板确认，不能仅凭非零PCM或ROM参数宣布优秀。**
