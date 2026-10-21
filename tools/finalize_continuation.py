"""Produce evidence-based current documents; hardware acceptance always stays open."""
from pathlib import Path
import json,csv,re,html,sys
from continue_audio_audit import R,A,O,sha,now,IV,VV,PY

def read(p,default=None):return json.loads(p.read_text(encoding='utf8')) if p.exists() else default
def report(name):return read(O/(name+'.json'),{'status':'NOT_RUN','name':name})
def resources(p):
    t=p.read_text(errors='replace') if p.exists() else ''
    result={k:float(m[1]) for k in ['Logic','Register','BSRAM','DSP','PLL'] if (m:=re.search(r'^\s*'+k+r'\s*\|\s*([\d.]+)/',t,re.M))}
    syn=p.parent.parent/'gwsynthesis/yinyue_fashengqi_syn.rpt.html'
    if syn.exists() and (m:=re.search(r'\bPLL</td>\s*<td>(\d+)</td>',syn.read_text(errors='replace'))):result['PLL']=float(m[1])
    return result
def timing(p):
    t=p.read_text(errors='replace') if p.exists() else ''
    f={n:float(v) for n,v in re.findall(r'^\s*\d+\s+(\w+)\s+[\d.]+\(MHz\)\s+([\d.]+)\(MHz\)',t,re.M)}
    setup=re.search(r'^3\.1\.1 Setup Paths Table.*?\n\s*1\s+([\d.-]+)',t,re.S|re.M)
    hold=re.search(r'^3\.1\.2 Hold Paths Table.*?\n\s*1\s+([\d.-]+)',t,re.S|re.M)
    recovery=re.search(r'^3\.1\.3 Recovery Paths Table.*?\n\s*1\s+([\d.-]+)',t,re.S|re.M)
    removal=re.search(r'^3\.1\.4 Removal Paths Table.*?\n\s*1\s+([\d.-]+)',t,re.S|re.M)
    pulse=re.search(r'^3\.2 Minimum Pulse Width Table.*?\n\s*1\s+([\d.-]+)',t,re.S|re.M)
    return {'fmax_MHz':f,'worst_listed_setup_ns':float(setup[1]) if setup else None,'worst_listed_hold_ns':float(hold[1]) if hold else None,'worst_listed_recovery_ns':float(recovery[1]) if recovery else None,'worst_listed_removal_ns':float(removal[1]) if removal else None,'worst_listed_pulse_width_slack_ns':float(pulse[1]) if pulse else None,'zero_setup_hold_violations':all(f'<Numbers of {k} Violated Endpoints>:0' in t for k in ['Setup','Hold']),'all_listed_timing_nonnegative':all(m is not None and float(m[1])>=0 for m in [setup,hold,recovery,removal,pulse]),'video_serial_fmax':'No internal timing paths; do not invent Fmax'}
def ports(p):
    t=p.read_text(errors='replace');t=t[t.index('name="Pinout_by_Port_Name"'):t.index('name="All_Package_Pins"')]
    rows=[]
    for row in re.findall(r'<tr>(.*?)</tr>',t,re.S):
        cells=[html.unescape(re.sub('<[^>]+>','',x)).strip() for x in re.findall(r'<td[^>]*>(.*?)</td>',row,re.S)]
        if len(cells)>10 and '<b>' not in row:rows.append(cells)
    return {row[0]:row for row in rows}

names=['baseline_checker','mapping_final','keyboard_unit','keyboard_status','display','hardware_syntax','dvi_local_reset','dvi_vendor','mirror_policy','high_chord','stress','full_regression','loader','audio_static_audit','audio_source_audit','nyquist_audit','chain_audit']
results={n:report(n) for n in names}
notes=read(O/'notes/RESULTS.json',{'status':'NOT_RUN'});build=read(A/'BUILD.json',{'status':'NOT_RUN'})
build_run=report('gowin')
if build_run.get('status')=='RUNNING':build=dict(build,status='RUNNING')
if build.get('status')=='PASS' and not all(Path(p).exists() and sha(Path(p))==h for p,h in build.get('input_sha256',{}).items()):build=dict(build,status='STALE_INPUTS')
analysis=read(O/'ANALYSIS_SUMMARY.json',{'status':'NOT_RUN'});keys=read(O/'KEY_DIAGNOSTIC_TABLE.json',{'status':'NOT_RUN','rows':[]})
baseline=read(A/'before.json')['files'];expected=report('original_reset_repro')
expected_text=(O/'original_reset_repro.log').read_text() if (O/'original_reset_repro.log').exists() else ''
expected_ok=expected['status']=='FAIL' and 'data=0 pad=0 length=1 delay=0' in expected_text and 'FATAL:' in expected_text
current={}
for folder in ['src','tools','sim','tests/keyboard','tests/integration','tests/audio_diagnosis','tests/continuation_20261017']:
    for p in (R/folder).rglob('*'):
        if p.is_file() and 'audio_vendor' not in p.parts and p.suffix in ['.v','.sv','.py','.tcl','.cst','.sdc','.rao']:
            current[str(p.relative_to(R))]=sha(p)
for p in [R/'yinyue_fashengqi.gprj',R/'impl/yinyue_fashengqi_process_config.json']:
    if p.exists():current[str(p.relative_to(R))]=sha(p)
stable={}
for n,m in results.items():
    # Functional Icarus runs consume RTL and include files; GAO/CST/SDC are
    # implementation-only inputs, checked against the final Gowin build below.
    src={rel:h for rel,h in m.get('input_sha256',{}).items() if (rel.replace('\\','/').startswith('src/') and Path(rel).suffix in ['.v','.sv']) or rel=='yinyue_fashengqi.gprj'}
    # Audio/default-top simulations explicitly replace physical visual_dvi_io
    # with tests/integration/video_boundary_stub.v; portable display tests also
    # exclude this primitive boundary. Check its new RTL in the dedicated test
    # and real-vendor hardware elaboration instead.
    if n not in ['hardware_syntax','dvi_local_reset','dvi_vendor']:
        src={rel:h for rel,h in src.items() if rel.replace('\\','/')!='src/display/visual_dvi_io.v'}
    stable[n]=bool(src) and all(current.get(rel)==h for rel,h in src.items())
pincheck={'status':'NOT_RUN'}
if build['status']=='PASS':
    old=ports(A/'backup/impl/pnr/yinyue_fashengqi.pin.html');new=ports(R/'impl/pnr/yinyue_fashengqi.pin.html')
    pincheck={'status':'PASS' if old==new and len(new)>0 else 'FAIL','ports':new,'baseline_ports':old,'note':'Compares all per-port report fields including bank voltage, locations, IO type and pulls'}
    (A/'PIN_AUDIT.json').write_text(json.dumps(pincheck,indent=2),encoding='utf8')
resource_before=resources(A/'backup/impl/pnr/yinyue_fashengqi.rpt.txt');resource_after=resources(R/'impl/pnr/yinyue_fashengqi.rpt.txt') if build['status']=='PASS' else {}
timing_before=timing(A/'backup/impl/pnr/yinyue_fashengqi.tr');timing_after=timing(R/'impl/pnr/yinyue_fashengqi.tr') if build['status']=='PASS' else {}
digital=(all(m['status']=='PASS' for m in results.values()) and all(stable.values()) and notes['status']=='PASS' and build['status']=='PASS' and pincheck['status']=='PASS' and keys['status']=='PASS' and analysis['status']=='PASS' and expected_ok and timing_after.get('all_listed_timing_nonnegative',False))
summary={'time':now(),'project':str(R),'gprj':str(R/'yinyue_fashengqi.gprj'),'digital_validation':'PASS' if digital else 'INCOMPLETE_OR_FAILED','hardware_acceptance':'PENDING','overall_status':'HARDWARE_PENDING' if digital else 'DIGITAL_INCOMPLETE','tests':{n:m['status'] for n,m in results.items()},'current_functional_RTL_and_gprj_match_tested':stable,'final_implementation_inputs_match_current':build.get('status')=='PASS' and all(Path(p).exists() and sha(Path(p))==h for p,h in build.get('input_sha256',{}).items()),'expected_negative_reproduction':'EXPECTED_FAIL_REPRODUCED' if expected_ok else 'INCOMPLETE','notes':notes['status'],'analysis':analysis['status'],'key_table':keys['status'],'build':build,'pin_check':pincheck['status'],'resources_before':resource_before,'resources_after':resource_after,'timing_before':timing_before,'timing_after':timing_after,'hardware_keys_confirmed':False,'hardware_protocol_confirmed':False,'no_auto_programming':True,'no_sound_algorithm_change':True}
(A/'VALIDATION.json').write_text(json.dumps(summary,indent=2),encoding='utf8')
(A/'TOOLCHAIN.json').write_text(json.dumps({str(p):sha(p) for p in [IV,VV,PY,Path(r'C:\Gowin2\Gowin_V1.9.12_x64\IDE\bin\gw_sh.exe')]},indent=2),encoding='utf8')

def loc(rel):return str(R/rel)
def doc(name,text):
    if name in ['BOARD_TEST_GUIDE.md','BOARD_AUDIO_TEST_GUIDE.md','KEYBOARD_GAO_GUIDE.md']:
        text+=f'\nGowin确认方法：打开当前工程后检查u_synth_top/u_synth/u_core/u_bank的G_PARTIAL与32个G_VOICE，以及G_FX、G_DISPLAY；在 `{R / "impl/gwsynthesis/RTL_GAO/gw_gao_top.v"}` 搜索key_note_on_count、key_last_accepted_midi和diagnostic_chain对应捕获位，在综合网表搜索三条独立local_rst_n。最终资源/时序/管脚报告均位于 `{R / "impl/pnr"}`，SHA256在BUILD.json与OUTPUT_HASHES.json。HDMI应为STAGE=3、MAP=0，当前raw2000应显示MIDI73；不能把旧照片MIDI67当成当前镜像的证据。\n'
        text+=f'\n最终最小移除裕量为 {timing_after.get("worst_listed_removal_ns","待完成")} ns；须在上板时检查逻辑复位、反复启动和HDMI恢复。当前报告通过只表示本次实现的已约束数字时序通过，不代表所有未来重新布局或物理板状态均已验证。\n'
    if name in ['MODULE_MAP.md','KEYBOARD_MODULE_MAP.md']:
        text+=f'\n物理DVI边界 `{R / "src/display/visual_dvi_io.v"}`：新增三条通道各自的局部复位寄存器（u_video_io/channels[i].local_rst_n），异步断言、同一像素边沿释放，RGB位序及差分输出连接不变。专门复位测试、真实Gowin行为模型对照与原语展开均有独立日志，最终时序以当前BUILD.json为准。\n'
    if name in ['TEST_RESULTS.md','AUDIO_TEST_RESULTS.md','KEYBOARD_TEST_RESULTS.md']:
        text+=f'\n历史第三次Gowin也为FAIL：最差视频复位恢复-0.020ns，完整记录 `{A / "build_attempt3"}`。随后修改真实DVI边界的复位扇出，新增复位测试及3000个真实OSER10/ELVDS模型DDR边沿对照均PASS；当前第四次实现状态为 {build["status"]}。此前便携音频联合测试实际替换物理DVI边界，新边界另行核对，不冒充已上板验证。\n'
    header=f'# {name[:-3]}\n\n工作工程：`{R}`\n\n工程入口：`{R / "yinyue_fashengqi.gprj"}`\n\n更新：{now()}；本轮记录目录：`{A}`、`{O}`。\n\n'
    sim_state='PASS' if all(m['status']=='PASS' for m in results.values()) and notes['status']=='PASS' and keys['status']=='PASS' and analysis['status']=='PASS' else '未全部完成或存在失败，按TEST_RESULTS逐项读取'
    header+=f'验证层次：源码审查及依赖哈希已留证（PATH_VERSION_AUDIT.json）；本轮仿真/数据核对={sim_state}；Gowin实现={build["status"]}；真实上板=未执行，协议、实体键位及模拟音频仍待验证。\n\n'
    (R/'docs'/name).write_text(header+text+'\n',encoding='utf8')

testtable='|本轮项目|状态|日志 / 完整命令、cwd、时间、退出码、哈希记录|\n|---|---|---|\n'
for n,m in results.items():testtable+=f'|{n}|{m["status"]}|`{O/(n+".log")}`；`{O/(n+".json")}`|\n'
testtable+=f'|21音符各3秒 Voice/FX 逐样本|{notes["status"]}|`{O / "notes/RESULTS.json"}`，每音每阶段命令见 `note_*.json`|\n|16键逐级与PCM表|{keys["status"]}|`{O / "KEY_DIAGNOSTIC_TABLE.csv"}`|\n|Gowin综合/布局布线/FS|{build["status"]}|`{O / "gowin.log"}`；`{A / "BUILD.json"}`|\n|管脚及Bank配置与基线|{pincheck["status"]}|`{A / "PIN_AUDIT.json"}`|\n|原PCM失败定向复现|{"EXPECTED_FAIL_REPRODUCED" if expected_ok else "INCOMPLETE"}|`{O / "original_reset_repro.log"}`，保留FAIL，不计成DUT通过|\n|实物协议、16实体键、模拟输出|NOT_RUN / 待用户上板|不自动下载或改变开发板状态|\n'
testtable+=f'|首次新增PCM导出边界检查|FAIL（已定位并修正后全16键重跑）|`{O / "capture_window_attempt1_check.log"}`；首次观察少1点，实际4095点，不缩小分析窗口。源码和数据保存在 `{A / "capture_window_attempt1"}`|\n'
testtable+=f'|Gowin尝试1|实现PASS，FIFO写计数探针未齐|`{A / "build_attempt1"}`，不是最终镜像|\n|Gowin尝试2|FAIL，3条视频复位恢复负裕量，最差-0.469ns|`{A / "build_attempt2"}`，不推荐加载其FS|\n|奈奎斯特审计首次解析|FAIL，解析器漏取MIDI127的default分支|`{A / "nyquist_parser_attempt1"}`；补全解析后全1215项通过，生产ROM未改|\n|初次Icarus沙箱启动|工具异常，未运行RTL|`{A / "SANDBOX_TOOL_FAILURE.json"}`；原始开始时刻未留存，不伪造；正常审批后重跑通过|\n'
status=f'''数字验证：**{summary['digital_validation']}**。实物功能验收：**PENDING**。

本轮修复测试平台跨复位半帧残留，增加真实事件链GAO诊断，对齐GUI/CLI过程选项，并针对已复现的视频串行器复位恢复负裕量增加逐通道局部复位。未修改AMY参数、ROM、Loader算法、Partial算法、Allocator调度、增益或FX算法。raw bit0..15→MIDI60..75是上一轮已存在的映射，本轮保留；实体键位与实物协议仍未确认。

最后四个实体键无声：当前协议模型下未复现，不能报告实物故障已修复。原照片只证明mapper状态和组合MIDI曾显示，不能确定Note On已被FIFO接受或声音已启动；照片中的旧表MIDI为67/71/75，不能混作当前73/74/75。

本轮记录 `{A/'VALIDATION.json'}` 为唯一当前汇总；`audit/audio_diagnosis`、`tests/audio_diagnosis` 内既有记录是历史基线，不能替代本轮结果。原docs已备份到 `{A/'backup/docs'}`。
'''
signal='''```mermaid
flowchart LR
 A[SDO/SCL] --> B[TTP229 Reader 16 bits]
 B --> C[mapper valid and no error]
 C --> D[state difference / registered event]
 D --> E[16-entry Note FIFO]
 E --> F[32 Voice allocator / shared Loader]
 F --> G[32 partial voices]
 G --> H[tree mixer / constant gain]
 H --> I[Stage3 piano FX]
 I --> J[PT8211 / PCM5102A]
 I --> K[telemetry / FFT / HDMI CDC]
```

实际默认参数：BUILD_STAGE=3、DISPLAY_ENABLE=1、KEYBOARD_PROFILE=0、KEY_RAW_MAP_ENABLE=0、KEY_MAPPING_CONFIRMED=0；固定velocity100；32 Voice、FIFO16、48kHz、音频每256拍取样。50MHz板级时钟、PLL 29/118生成约12.288MHz，SDC未改。
'''
event='''## 源码审查

- Reader使用5位bit_index，0..15共16次；每一完整帧在bit15完成时发布。高4位没有12键边界。CONFIRM=1逐位要求两帧一致；默认SAMPLE_LOW=0，在SCL高相末端采样同步后的SDO。
- 默认STRICT_IDLE=1拒绝SDO持续有效电平。MIRROR_GUARD=1在未见上下字节不同的确认帧时屏蔽上字节；F000单独按下可证明16位并解除保护。首次FFFF或0101等对称和弦可能被屏蔽上字节；这是模型已复现的保守策略限制，不是照片所示单个高位被接纳后无声的证实根因。未未经实物确认关闭保护或切换I²C。
- mapper只在frame_valid && !frame_error && !mapping_error时更新key_state和accepted_raw；输出valid由非阻塞赋值产生，下游在下一拍读取稳定的整帧；16位保持完整。
- Bridge的reported_state表示已排入其输出寄存器的状态。真正接受点是event_valid && event_ready；背压时负载保持，Off优先，再发On。短于两帧确认窗口的触摸可能不被接纳，不承诺捕获每个模拟短脉冲。
- FIFO只有in_valid&&in_ready才写，out_valid&&core_ready才读；满时停写，保持事件次序，没有越过满状态静默覆盖。满且同拍读时会留一拍写入空隙，属于吞吐限制。
- core_ready=!ld_busy，Loader忙时On和Off均不出队；Allocator选择空闲、释放中、再抢占Voice。Loader锁存MIDI、velocity及基础相位增量，写400字/音后对所选Voice发ld_done。
- Voice在V_LOAD接收ld_done后进入V_PLAY；active包含LOAD/FADE/PLAY，故active非零不等于已经输出PCM。stop可以在加载/播放期间设置释放；新start优先。32条独立Voice RAM和调度均保留。
- MIDI60..75在有效区间；Loader将超出24..104的音色索引钳位，频率表仍按实际MIDI。MIDI参数不依赖实体键号。原旧表也是16个唯一有效音，不能单凭其排列解释四键全部零Voice。

## 仿真覆盖层级

直接注入事件：原钢琴Voice/Loader、系统、抢占/重触发、短按/加载中释放、长音与FX回归。mapper输入注入：keyboard_events，覆盖16键、和弦2/3/5/8/16、独立松键、快速切换、无效帧、FIFO满背压及复位。模拟串行SDO：逐键mapping、默认stress、high_chord和mirror_policy，真实Reader/mapper/FIFO/32Voice/FX连接。仿真BFM假定TTP229-BSF式低有效16键串行；不等于BIT-TREE实物协议已确认。
'''
diag='''## 无声定位与诊断语义

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
'''
board=f'''## 最小人工测量

1. 先确认本轮数字验证和时序门禁已PASS，再自行选择是否加载诊断镜像；本任务未连接下载器、未自动烧录。打开 `{R/'yinyue_fashengqi.gprj'}`，芯片GW5AST-LV138FPG676AC1/I0、Device C；GUI选项应为SystemVerilog2017、顶层tang_mega_138k_pro_top、开启文本时序报告。
2. 当前FS候选：`{R/'impl/pnr/ao_0.fs'}`；本轮构建状态 `{build['status']}`；SHA256：`{build.get('sha256','尚未生成本轮结果')}`。它是诊断候选，实物功能尚未验收，不能当作最终声音已修复的交付版。
3. 如人工进行上板诊断，复位后先空手等待RAWS稳定为0000，再单独短按一个已知正常键，记录实体编号、RAWS、显示MIDI；再分别对实体13、14、15、16做按下0.5秒、松开0.5秒。为比较计数可每键复位，或取前后差值。不要默认实体编号等于raw bit+1。
4. 在当前GAO中默认用key_event_accepted触发，保持clk_12m288/4096点。记录key_raw_frame、key_state、frame_valid/error、key_note_on_count/off_count、key_last_accepted_midi、diagnostic_chain、active_voice_count。先比较正常键与异常键各一组；无需先测全部引脚。HDMI另记录VOICE/PEAK。若始终不触发，可按下后手动强制捕获，查看保留的计数与raw；不要把未触发当作没有raw。
5. 单键预期：FIFO写On+1、读On+1、分配/start脉冲+1、Loader完成+1、就绪完成+1，FX前后峰值非零；松开时FIFO写/读Off各+1。当前raw bit12/13/14/15应发MIDI72/73/74/75；照片中的旧bit13/14/15为67/71/75，两版不能混记。
6. raw有变化但mapper无变化：查帧错误/镜像/确认；mapper变化而写On不增：查Bridge/背压；写增读不增：查FIFO/Loader busy；读增分配不增：查分配；分配增Loader不增：查加载等待；Loader增就绪完成不增：查Voice状态；完成增且FX前零：查参数/Voice/同拍重启；FX前非零FX后零：查FX；两者非零且耳机无声：再查板载串行输出/模拟DAC/耳放/负载。
7. 最小回传数据是一个正常键和一个异常键的上述计数前后值及原始捕获；另附实体编号与raw十六进制。可用 `{O/'BOARD_KEY_RECORD.csv'}` 记录全16键。若需确认协议，再测SCL/SDO一整帧的16个脉冲、极性及键盘型号/选件；不要先改I²C或Bank电压。

## 回退

本轮修改前源码、配置与旧FS位于 `{A/'backup'}`；前哈希在 `{A/'before.json'}`。要回退时，先在当前工程内另存当前状态，再只将变更表中有旧版本的文件从backup复制回同一相对路径。新建过程配置原来不存在，可在当前工程内移入回退归档以恢复原默认行为。旧FS只在用户明确选择时人工加载；不回写任何只读旧工程。
'''
wiring=f'''有效管脚文件：`{R/'src/integrated.cst'}`；时钟文件：`{R/'src/integrated.sdc'}`。二者本轮内容未修改。管脚报告对比：{pincheck['status']}。

|信号|FPGA位置 / 已有接口|
|---|---|
|clk_50m / rst_n|P16 / K16|
|TTP229 SCL / SDO|C21 / B20，原PMOD2/J26连接|
|板载BCLK / LRCK / DATA|E22 / F24 / G24|
|板载耳放使能|H17|
|PCM5102A BCLK / LRCK / DATA|C24 / B24 / H15，原PMOD1连接|
|DVI三数据对 / 时钟对|AB24/AC24，V24/W24，AA22/AA23，Y22/Y23|

上述为当前CST声明及实现报告检查，不是本轮重新测量的电路连接。没有新增外部端口、分配新管脚或调整Bank电压。保留现有板载与外接DAC。外接DAC注释中的“未激活”属于历史注释；实际顶层EXT_PCM5102已定义且有效CST已有三管脚，应以实际工程/报告为准。实物BIT-TREE协议、键盘选件、电平与物理顺序仍待确认。
'''
mapping='''## 映射与实物证据

当前连续表：raw bit i -> MIDI60+i，i=0..15；RAW_MAP_ENABLE=0，未添加实体位序置换。KEY_MAPPING_CONFIRMED=0继续显示MAP=0。

旧keyboard_v2表按raw bit0..15为60,64,68,72,61,65,69,73,62,66,70,74,63,67,71,75。若实体序等于raw位序，第四到第五键将由72跳到61，下降11半音，能造成音区和音色突变；这是条件推论，未测实体顺序，不能称为唯一实物根因。上一轮已经去掉这个排列，本轮未再改音高表。

本轮再次读取四张原图：2000/067、2000/067、4000/071、8000/075，VOICE/PEAK均0。前两张是同一raw，照片未覆盖bit12或全16实体键；它们与旧表相符。当前同raw13/14/15应为73/74/75。原图路径和SHA256见PATH_VERSION_AUDIT.json。
'''
modmap=signal+'\n|模块 / 当前源码|职责 / 本轮变化|\n|---|---|\n'
for path,desc in [('src/tang_mega_138k_pro_top.v.v','Reader、mapper、Bridge、板级复位、显示连接；新增真实接受MIDI/帧/背压诊断'),('src/ttp229_reader.v','16位串行读帧、两帧确认、镜像保护；未改'),('src/keyboard/keyboard_state_mapper.sv','整帧接纳和位序映射；未改'),('src/ttp229_event_bridge.v','状态差分、保持背压负载；未改'),('src/note_event_fifo.v','16项事件FIFO；未改'),('src/synth_event_frontend.v','FIFO就绪到Core；新增实际出队计数'),('src/voice_allocator.v','固定32 Voice分配/抢占；未改'),('src/voice_bank.v','共享Loader与32Voice；新增分配、加载、播放计数'),('src/piano_note_loader.v','AMY参数插值及400字RAM加载；算法未改'),('src/piano_partial_voice.v','每音15泛音+Hammer、包络/相位/乘累加；未改'),('src/synth_core.v','Mixer/增益/FX/遥测；新增真实前后累计峰值'),('src/synth_top.v','音频链、双DAC；透传诊断'),('src/piano_fx_compat.v','包含当前src/piano_fx.v，后者在gprj中禁独立编译以免重复'),('src/i2s_tx.v','PT8211 16位双声道、sample_tick源；未改'),('src/pcm5102_i2s_tx.v','24位标准I²S、每通道32位；未改'),('src/display/piano_status_cdc.v','真实状态request/ack邮箱；未改'),('src/keyboard_debug.rao','保留旧探针并增加128位链诊断、MIDI、帧、拒绝/背压计数')]:modmap+=f'|`{R/path}`|{desc}|\n'
modmap+=f'\n自动源图、63个有效条目+1个include、65个唯一模块：`{A/"PATH_VERSION_AUDIT.json"}`。源图保守包含generate的备用分支，实际默认分支由完整顶层层级断言及Gowin检查。所有生产ROM在当前src初始化，不从旧目录读取ROM。audio_pll.mod中的旧生成路径未列入工程依赖，未运行IP重生成。\n'
res_table='|资源|历史audio_fix基线|本轮|差值|\n|---|---:|---:|---:|\n'
for k,v in resource_before.items():res_table+=f'|{k}|{v:g}|{resource_after.get(k,"待完成")}|{resource_after[k]-v if k in resource_after else "待完成"}|\n'
timing_text=f'\n基线时序：`{json.dumps(timing_before,ensure_ascii=False)}`\n\n本轮时序：`{json.dumps(timing_after,ensure_ascii=False)}`。SDC声明的异步邮箱路径属于显式时钟分组，不能把这些跨域路径未做同步时序分析解释为物理CDC已上板验证。video_serial没有普通内部路径的Fmax数值，不虚构125MHz逻辑裕量。\n'
tests=status+'\n'+testtable+'\n'+res_table+timing_text+f'''\n## 参数、命令与范围

每组实际命令、cwd、开始/结束时间、returncode、运行时源码/约束哈希和完整日志均在同名JSON。原全回归由原sim/run_tests.py all执行，保留原长音时长和检查；组内细节由已哈希运行器和docs/test_manifest_all.txt追溯。测试元数据中的inputs_unchanged包含工具脚本与实现配置，期间新增审计脚本或GAO探针可能使其为false；本轮额外逐项核对仿真实际使用的.v/.sv及gprj是否仍与已测输入一致；CST/SDC/GAO及过程配置由最终Gowin构建的完整输入哈希另行核对。仿真不加载GAO电路，不能宣称仿真验证了GAO硬件，不能将脚本变动伪装成RTL已重测。

16键mapping在实际默认顶层模拟串行Reader输入，每键完整按/持/松，4096 PCM样本；trace包含扫描/mapper/FIFO写/分配，control表包含FIFO读/Loader/播放/active时长/串行输出/HDMI。独立音色测试velocity100、48kHz、NoteOff=96000tick、每音144000样本（3秒），输出21个音符；MIDI60..75统一0.1..0.5s频谱/RMS窗口，两条FX链，另测32Voice混合压力。Loader用实际生产case ROM跑810请求、324000字，再和独立整数插值核对；原回归还穷举所有地址验证array-ROM等价。

便携长仿真使用同接口、同延迟且逐地址验证过的array-ROM，PLL和物理串行器边界使用名义模型；真实ROM/原语另做hardware_syntax及Gowin实现。数字串行解码通过不等于板载模拟输出、PLL锁定实测或HDMI线缆眼图通过。没有安装软件。

保留历史mapping_after_run.log的FATAL，不把其中16条子检查PASS说成整体PASS。当前负向复现也是FAIL证据。沙箱内第一次Icarus编译曾以0xC0000005退出，之后经正常权限审批使用同一现有工具执行；不是RTL功能失败。未完成或失败项不会生成最终全功能PASS。
'''
audio=status+'\n'+diag+f'''\n## 音高、音色与响度

本轮没有修改这些算法/参数；相同MIDI对应的新旧Voice/Gain/FX数组必须逐样本一致，才允许分析通过。报告 `{O/'NOTE_METRICS.csv'}` 列出目标频率、AMY实际partial1频率、谐波/自相关支持、音分差、RMS、谱质心、泛音/基频比、衰减、直流及削波。`{O/'wav'}` 内含逐音24位WAV与新/旧排列的序列，属于仿真音频。

音高：MIDI频率表及Loader地址/插值对照；AMY测量泛音并非严格整数谐波，允许其原有轻微失谐，应区分音名错误和AMY源频率偏移。音色：原参数的每4半音存储点与缺失泛音策略会造成自然差别；所有非零保留partial必须低于24kHz。响度：固定混音增益、FX与PT8211量化逐样本验证，不用高音补偿掩盖事件问题。

历史基线中MIDI64与68的0.1..0.5秒FX前RMS相差约13.18dB；当前应由本轮NOTE_METRICS复核。AMY源表、提取JSON、生成ROM和Loader独立对照只能证明差异来源与实现一致，不代表主观听感理想，更不能当作最后四个实体键无声的已证实根因。

录音源与副本SHA256均为18fdc4889cd3c85ecf7ac9c13ec7b19259446d1ed7240884a8520d728adcdfb1。当前分析重新从副本解码；无逐键事件标签、手机AGC/房间/负载未知，后段弱信号不能证明RTL未发声。原文件读取与照片复核在PATH_VERSION_AUDIT.json留证。

## 现象到证据

|现象|源码/复现/PCM证据|结论与动作|
|---|---|---|
|原逐键测试末尾PCM FATAL|tests/audio_diagnosis/tb_audio_note_map.sv；original_reset_repro与baseline_checker；非零PCM且只多1次长度错|测试复位管理根因证实；调用既有restart并保留完整检查|
|实体最后四键VOICE/PEAK=0|旧照片、当前完整链路与high_chord/stress、KEY_DIAGNOSTIC_TABLE|模型下不能复现实物故障；加真实计数，待正常/异常键最小GAO测量|
|第5键附近音色突变|旧顶层KEY_NOTE_TABLE与固定MIDI PCM|旧表可能造成72→61跳转，取决实体位序；本轮不重复修改已有连续表|
|响度与金属感|AMY源/ROM/810 Loader校验、同窗口PCM/WAV及指标|不盲调源参数；区分原音色特征、映射和模拟硬件，待带键号实测|
'''

doc('PROJECT_STATUS.md',status+'\n'+res_table)
doc('MODULE_MAP.md',modmap)
doc('AUDIO_SIGNAL_CHAIN.md',signal+'\n'+event+'\n'+diag)
doc('KEYBOARD_EVENT_AUDIT.md',event+'\n'+testtable)
doc('VOICE_ZERO_DIAGNOSIS.md',status+'\n'+diag+'\n'+board)
doc('BOARD_TEST_GUIDE.md',board+'\n'+wiring)
doc('HARDWARE_WIRING.md',wiring)
doc('AUDIO_DIAGNOSIS.md',audio)
doc('TEST_RESULTS.md',tests)
doc('AUDIO_TEST_RESULTS.md',tests)
doc('MIDI_MAPPING_AUDIT.md',mapping+'\n'+testtable)
nextsteps='''待真实板上确认：实体1..16到raw位序；BIT-TREE芯片/选件及SDO整帧；正常键与异常键GAO握手差值；板载模拟输出与同MIDI数字PCM的对照。若计数链全部前进而模拟仍无声，再测板载DAC串行/耳放/负载。只有硬件证据定位后才针对相关级修改；音色算法变更须先局部A/B与资源评估。

数字检查若仍有NOT_RUN/RUNNING/FAIL，继续对应日志中的实际命令，不把历史PASS当作当前结果。硬件验收未完成前保持MAP=0，不发布“实物全修复”结论，不自动下载。
'''
doc('NEXT_STEPS.md',status+'\n'+nextsteps+'\n'+board)
plan='''本轮执行顺序：只读路径/哈希与实物证据确认 → 当前工程内备份 → 原PCM FATAL分类与A/B → 保留原检查并补齐逐键观测 → 真实GAO计数接入 → 键盘/背压/双DAC/显示/完整钢琴/固定力度音色回归 → 相关仿真通过后单次Gowin实现 → 哈希、时序与管脚门禁 → 用户最小上板测量。

GUI原打开值与CLI的差异为语言标准、显式顶层和文本时序报告。本轮新建当前impl下最小process_config，仅设置这些必要值及CST警告升级；再由Gowin saveto -all_options分别导出GUI_ON_OPEN.tcl和CLI_EFFECTIVE.tcl，验证选项相同。没有复制旧工程整份生成配置，不更改Bank电压/下载配置。生产gprj仍使用原相对文件路径，新增RTL诊断在已入工程模块中直接实现，未并列加入冲突版本。

第一次实现通过后，复核发现FIFO写入On/Off计数尚未加入GAO捕获清单，因此补探针和实际接受点默认触发，作必要的第二次实现；该次报告三条OSER10复位恢复负裕量，最差-0.469ns，判FAIL。随后压缩新增计数探针到低8位，第三次仍有一条恢复-0.020ns。详细路径显示共享像素复位源到三个串行器的布线延迟达3.57..4.00ns，挤占4ns恢复关系；因此增加三个受保留的局部复位寄存器，缩小每个复位源扇出到一个串行器，相关专门仿真通过后进行第四次实现。声音RTL、管脚、时钟和SDC不变。前三次产物分别保存在audit/continuation_20261017/build_attempt1、build_attempt2、build_attempt3；最终以BUILD.json和当前Gowin日志为准。基线与本轮均出现tck_pad_i自动时钟及clk_50m_d普通布线警告，完整保留，不通过删除约束掩盖；以最终实际时序及最小脉宽报告判断数字实现门禁，物理接口仍需硬件验证。
'''
doc('INTEGRATION_PLAN.md',status+'\n'+plan+'\n'+nextsteps)
change=f'''本轮五个音频/顶层RTL仅新增诊断：voice_bank新增分配/start、加载/就绪完成计数；synth_core新增真实FX前后累计峰值；frontend新增FIFO真正出队计数；synth_top透传；板级顶层新增接受MIDI/帧/背压统计。第六个RTL是src/display/visual_dvi_io.v，增加三个逐通道局部复位寄存器，处理实际报告的共享复位长路由恢复问题，数据连线不变。GAO增加对应探针并以低8位计数保留4096点深度；impl过程配置新建以匹配CLI。音色、频率、事件/Loader调度协议及管脚保持原值。

测试修复：每键复位前重启无reset端口的接收模型，累计错误断言保留；增加逐键真实握手、PCM、两声道板载解码、HDMI与诊断计数断言；统一4096样本保持窗口。增加冷启动镜像策略、低高键和弦与原失败定向复现，保留原负向结果。

逐文件完整路径、来源、原因、前后SHA256及验证映射见 `{A/'FILE_CHANGES.csv'}`；生产不变项及前哈希见 `{A/'before.json'}`。新增审计/运行/分析脚本均写在当前tools；测试源码、日志、PCM、WAV、结果及构建产物均在当前工程。旧目录只读。
'''
doc('CHANGELOG.md',change)
doc('AUDIO_FIX_CHANGELOG.md',change)
doc('PIANO_INTERPOLATION_AUDIT.md',f'当前实际ROM、AMY源与Loader验证：`{O/"INTERPOLATION_AUDIT.json"}`、`{O/"AMY_SOURCE_AUDIT.json"}`。状态 {report("audio_static_audit")["status"]}/{report("audio_source_audit")["status"]}；Loader全810请求日志 `{O/"loader.log"}`。此为数据/整数实现一致性，不冒充主观音色验收。\n\n'+testtable)
doc('AUDIO_BEFORE_AFTER.md',status+'\n相同MIDI的新旧Voice/Gain/FX逐样本比较由continuation_analyze.py执行；不同raw排列的声音顺序可能不同。前后声学图和WAV只在本轮分析完成时有效。\n\n'+audio)
for name,text in [('BOARD_AUDIO_TEST_GUIDE.md',board),('KEYBOARD_GAO_GUIDE.md',diag+'\n'+board),('KEYBOARD_MAPPING.md',mapping),('KEYBOARD_MODULE_MAP.md',modmap),('KEYBOARD_NEXT_STEPS.md',nextsteps+'\n'+board),('KEYBOARD_PROTOCOL_AUDIT.md',event),('KEYBOARD_TEST_RESULTS.md',tests),('KEYBOARD_WIRING.md',wiring),('KEYBOARD_CHANGELOG.md',change)]:doc(name,text)
(R/'README.md').write_text(f'# 当前电子钢琴诊断工程\n\n唯一开发工程：`{R}`\n\n打开：`{R/"yinyue_fashengqi.gprj"}`\n\n{status}\n\n先读 docs/PROJECT_STATUS.md、AUDIO_DIAGNOSIS.md、AUDIO_TEST_RESULTS.md、BOARD_TEST_GUIDE.md。当前复现入口为 tools/continue_audio_audit.py、continue_audio_tasks.py、continuation_parameter_audit.py；测试命令和工作目录见 tests/continuation_20261017/*.json。正式构建入口仍是 tools/build_gowin.tcl；GUI已补齐当前最小过程配置。不要运行继承的旧目录专用finalize/run_keyboard_build脚本覆盖当前报告。\n',encoding='utf8')
if not (O/'BOARD_KEY_RECORD.csv').exists():
    with (O/'BOARD_KEY_RECORD.csv').open('w',newline='',encoding='utf8') as f:
        w=csv.writer(f);w.writerow(['physical_key','raw_hex','display_midi','accepted_midi','write_on_delta','read_on_delta','alloc_delta','load_delta','play_delta','pre_peak','post_peak','hdmi_voice','hdmi_peak','heard_sound','capture_file']);w.writerows([[i]+['']*14 for i in range(1,17)])

# Files that existed at the real start plus this turn's new source artifacts.
candidate={rel for rel in baseline if not rel.startswith('impl'+str(Path('/')))}
candidate.update(current)
candidate.update(str(p.relative_to(R)) for p in (R/'docs').glob('*') if p.is_file())
candidate.add('README.md')
changed=[]
for rel in sorted(candidate):
    p=R/rel
    if not p.exists() or rel.startswith('audit') or rel.startswith('impl\\pnr') or rel.startswith('impl\\gwsynthesis'):continue
    old=baseline.get(rel);new=sha(p)
    if rel=='tools\\continue_audio_audit.py':old=None # bootstrap created in this turn before production snapshot
    if old==new:continue
    origin=str(A/'backup'/rel) if old else '本轮新增（含生成的定向测试源码）'
    why='当前源码诊断与真实握手/PCM观测' if rel.startswith('src') else '本轮可复现测试、审计或报告'
    if 'process_config' in rel:why='GUI/CLI三项必要选项对齐，已用Gowin再次导出比对'
    if rel.replace('\\','/')=='src/display/visual_dvi_io.v':why='OSER10共享复位长路由导致恢复负裕量，改为三个逐通道局部复位寄存器；不改时钟/引脚/数据'
    validation=f'Gowin={build["status"]}; mapping_final={results["mapping_final"]["status"]}; stress={results["stress"]["status"]}; full_regression={results["full_regression"]["status"]}' if rel.startswith('src') else '见VALIDATION.json及同名测试JSON；报告由真实结果生成'
    if rel.replace('\\','/')=='src/display/visual_dvi_io.v':validation=f'dvi_local_reset={results["dvi_local_reset"]["status"]}; dvi_vendor={results["dvi_vendor"]["status"]}; hardware_syntax={results["hardware_syntax"]["status"]}; Gowin={build["status"]}'
    changed.append({'full_path':str(p),'source':origin,'reason':why,'before_sha256':old or 'NEW','after_sha256':new,'validation':validation})
with (A/'FILE_CHANGES.csv').open('w',newline='',encoding='utf8') as f:
    w=csv.DictWriter(f,fieldnames=list(changed[0]));w.writeheader();w.writerows(changed)
(A/'FILE_CHANGES.json').write_text(json.dumps(changed,indent=2),encoding='utf8')
print(json.dumps({k:summary[k] for k in ['digital_validation','hardware_acceptance','overall_status','tests','notes','analysis','key_table','pin_check']},indent=2),flush=True)
if '--require-complete' in sys.argv and not digital:sys.exit(1)
