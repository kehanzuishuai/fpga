
from pathlib import Path
import json,re,csv,hashlib,datetime
R=Path(__file__).resolve().parents[1];B=Path(r'D:\gaoyun\piano_v2_integrated')
D=R/'docs';O=R/'tests/results/keyboard';A=R/'audit/keyboard_v2'
def text(p):return p.read_text(encoding='utf-8-sig',errors='replace') if p.exists() else ''
def obj(p):return json.loads(text(p)) if p.exists() else {}
def write(name,body):
 stamp=datetime.datetime.now(datetime.timezone(datetime.timedelta(hours=8))).isoformat(timespec='seconds')
 header=f'# {name[:-3]}\n\n工作工程：{R}\n\n只读基线：{B}\n\n工程入口：{R}/yinyue_fashengqi.gprj\n\n更新：{stamp}\n\n'
 (D/name).write_text(header+body.replace('ROOT',str(R)).replace('BASE',str(B)).replace('FENCE',chr(96)*3),encoding='utf-8')
build=obj(A/'BUILD_INPUT_HASHES.json');system=obj(O/'keyboard_system_results.json')
unit=obj(O/'keyboard_unit_results.json');hud=obj(O/'keyboard_status_results.json')
m=re.search(r'(\d+) tests, (\d+) failed',text(O/'piano_regression.log'));piano=m[0] if m else 'PENDING'
write('KEYBOARD_PROTOCOL_AUDIT.md',r'''## 结论：新BIT-TREE实物协议未确认
官方页面：https://www.bit-tree.com/cn/product/product-64-542.html
当前标题Plus A075，参数表仍写A025；Demo1使用Wire、地址0x50，其它示例直接产生16次SCL脉冲读电平。ReadKeys16只有调用，没有其TTP229库实现。用户再次给相同链接不能解释成已经确认芯片协议。
已搜索E盘三个参考目录、两个原工程及Codex附件，没有找到“粘贴的文本 (1)(20261016-120252).txt”、TTP229.h/.cpp。没有用网上同名库冒充商家版本。

|问题|可核对证据/当前结论|
|---|---|
|真实芯片型号|未获得新板芯片丝印/确切模式，待确认|
|TTP两线还是I2C|商家示例矛盾，暂停新物理驱动定稿|
|16位完整返回|RTL和串行BFM能够处理；新模块实物未测|
|同时有效数|商家称多键，BFM假设16；不能据此称实物支持16并发|
|模式|若确为所参考BSF，16键、全多键和极性配置须匹配；不擅自要求焊接|
|数据顺序|候选假定D0先收到bit0；实体键对应待GAO|
|极性|候选低有效；输出按下规范化为1|
|3.3V电气|FPGA现有LVCMOS33；模块针序、上拉、输出电压仍待实物资料|
|复用C21/B20|保留分配；确认直接串行和3.3V电气后才可条件复用|
|ReadKeys16实现|未取得确切库源码，不能声称读过|

本地芯片依据：ROOT/ref/ttp229/TTP229-BSF_spec_v1.1.txt、TTP229_appendixA_package_list_v1.3.txt。包型/选件可能区分两线串行与I2C，不能只看TTP229名称。
商家单音示例返回第一个键，不能移植成复音系统；现有FPGA桥处理完整位图。
商家声明、商家代码、芯片系列资料、RTL仿真和实物证据分别记录，最后一项仍未执行。
KEYBOARD_PROFILE=0是保留旧时序/音符表的安全默认，启用原Reader已有STRICT_IDLE=1，不是新BIT-TREE完成版。
KEYBOARD_PROFILE=1是未确认的TTP16诊断候选：MIRROR_GUARD=0、临时MIDI60..75，通过功能仿真；实际Gowin Bitstream使用profile0。
若实物是标准I2C，需要地址/ACK和双向开漏SDA；当前SDO输入端口不满足，不擅自改方向或总线。
''')
write('KEYBOARD_MODULE_MAP.md',r'''## 实际数据链
FENCEmermaid
flowchart LR
 I["B20 SDO"] --> R["原ttp229_reader"]
 R -->|"C21 SCL"| K["触摸模块"]
 R -->|"确认16bit + valid/error"| M["新keyboard_state_mapper"]
 M -->|"同一映射快照"| E["原ttp229_event_bridge"]
 E -->|"valid/ready"| F["原16条FIFO"]
 F -->|"loader_ready"| C["原core / bank / allocator"]
 C --> V["原32Voice / Mixer / FX"]
 V --> DAC["原双DAC"]
 V --> FFT["原FFT/波形"]
 M --> HUD["状态HUD RAWS MAP=0"]
 HUD --> DVI["原DVI"]
 FFT --> DVI
 E --> MON["实际FIFO接受观测"]
 MON --> GAO["4096点GAO"]
FENCE
输入/事件/核心在约12.288MHz；原50MHz输入、25MHz像素、125MHz串行、显示CDC均保留。

|完整文件路径|功能/主要I/O|上下游与使用|
|---|---|---|
|ROOT/src/ttp229_reader.v|SDO/SCL→原始/确认位图、帧有效/错误|原样复用；顶层改STRICT_IDLE及候选镜像参数|
|ROOT/src/keyboard/keyboard_state_mapper.sv|valid无error时接纳、raw→key排列、拒绝重复raw/MIDI配置|新实际例化，输出同时供事件和显示|
|ROOT/src/ttp229_event_bridge.v|状态差分→独立On/Off及ready/valid|原样复用，Off优先|
|ROOT/src/note_event_fifo.v|16条事件队列|原样，满时背压|
|ROOT/src/synth_event_frontend.v|FIFO→core就绪握手|原样，loader忙时不出队|
|ROOT/src/voice_bank.v|分配/共享加载器/32Voice|原样，不降到16|
|ROOT/src/tang_mega_138k_pro_top.v.v|参数映射、快照、接受监视|新mapper实际调用，显示同源|
|ROOT/src/display/audio_visualizer.sv|仅透传映射确认参数|FFT算法不改|
|ROOT/src/display/piano_status_overlay.sv|RAWS/KEYS、MAP=0/1|防止未确认位序冒充实体|
|ROOT/src/keyboard_debug.rao|扫描/帧/接受/FIFO/Voice观测|新Bitstream包含|

key_reported_state代表原桥已放进输出寄存器的状态，不等于FIFO接受或Voice已分配。
key_fifo_accepted_state仅在event_valid&&event_ready更新。测试另核对core实际接受、allocation_valid/index和各Voice的MIDI/held状态。
新增输入快照延迟一个音频时钟。旧默认现有对照场景PCM和双DAC仍逐时钟一致，不据此声称任意输入相位绝无延迟差异。
无效帧保持上一次有效状态；没有声称能检测所有串行位错误。持续错误不能推断真实键是否已松开，需诊断/人工复位。
有限FIFO不能保存无限背压下的全部快速瞬态；桥保持已发布事件及待收敛状态，未被扫描或在堵塞中合并的历史不伪称都能保留。

## 未来双16键边界
mapper的KEYS/INDEX_W已测试32/5；当前硬件仍一块16键，原事件桥仍16位。
未来两个独立Reader/快照可形成{keys_B,keys_A}，用两个成熟桥和保持valid的公平仲裁合入FIFO；键索引扩5位，MIDI仍7位、Voice仍32。
各模块需独立valid/error和新鲜度；不必等两块同一瞬间扫描。
32次On/Off可分批背压处理，FIFO16不等于全部突发必须一次装下；若要求保留所有边沿，另需有界边沿队列/溢出策略。
两路SDO不可短接；未确认真正可寻址I2C及不同地址前，不承诺共用总线。先预留独立SCL/SDO逻辑边界，本轮不分配第二组管脚。
未来显示还需扩展当前16bit键位图/58bit状态包；本轮没有完成32实体键显示。
''')
legacy=[60,64,68,72,61,65,69,73,62,66,70,74,63,67,71,75]
mapping=r'''## 参数和真实确认状态
KEYBOARD_PROFILE=0：当前Gowin安全默认，原音符表、原TTP时序、保留8键镜像保护。
KEYBOARD_PROFILE=1：未确认TTP16候选，禁用镜像保护，临时线性音域；没有作为本轮Gowin默认实现。
KEY_RAW_MAP_ENABLE=0为identity；1时KEY_RAW_INDEX_TABLE[key*4+:4]指定该键取哪个raw bit。
KEY_NOTE_TABLE[key*7+:7]指定MIDI。raw位/MIDI重复时mapping_error置位且不接纳快照。
KEY_MAPPING_CONFIRMED=0显示RAWS/MAP=0；只有实物确认后设1，显示KEYS/MAP=1。

|raw bit（临时假定）|候选实体键|候选MIDI|安全默认MIDI|实物确认|
|---|---:|---:|---:|---|
'''
for i in range(16):mapping+=f'|{i}|{i+1}|{60+i}|{legacy[i]}|未确认|\n'
mapping+='\n## 用户给出的旧键盘GAO结果，不能代入新键盘\n|旧实体键|旧raw bit|目标MIDI|\n|---|---:|---:|\n'
for i,bit in enumerate([5,6,7,8,9,10,11,0,1,2,3,4]):mapping+=f'|{i+1}|{bit}|{60+i}|\n'
mapping+='\n旧第11键0008/0808不是新键盘应屏蔽bit11的依据。本次没有加入破坏合法和弦的双bit过滤。单元测试中余四位仅补齐合法测试排列，不是实物确认。\n'
write('KEYBOARD_MAPPING.md',mapping)
write('KEYBOARD_WIRING.md',r'''CST：ROOT/src/integrated.cst
SDC：ROOT/src/integrated.sdc
两者逐字节保留，不新增/改变管脚。

|功能|FPGA管脚|条件|
|---|---|---|
|原SCL/SDO|C21/B20|只在确认新模块为相应直接串行且3.3V电气后复用|
|PT8211 BCLK/WS/DIN|E22/F24/G24|原样|
|PCM5102 BCK/LCK/DIN|C24/B24/H15|原样|
|视频D0 +/-|AB24/AC24|原样|
|视频D1 +/-|V24/W24|原样|
|视频D2 +/-|AA22/AA23|原样|
|视频时钟 +/-|Y22/Y23|原样|

连接新模块前确认VCC/GND针序、芯片/协议、极性、多键模式和数据输出/上拉电压。FPGA不能因为商品支持5V供电就接5V信号。
确认直接串行后才条件连接C21→SCL、B20←SDO、共地和经确认的3.3V VCC。
若为标准I2C，当前input SDO不能发送ACK，必须先确认双向开漏驱动、地址和上拉；暂停TTP接线方案。
不擅改供电、焊接或第二组管脚，不短接两个SDO。视频保持原Pro Dock J11；显示器和板卡实际兼容性仍需人工验收。
本轮不处理PCM5102实物无声/音箱底噪，也不称其已修复。没有自动下载。
''')
write('KEYBOARD_GAO_GUIDE.md',r'''## 实际配置
ROOT/src/keyboard_debug.rao：clk_12m288采样，4096点，trigger_pos=64。约333.33us，触发前约5.21us。
16位扫描约3936clk/320.3us，默认M0匹配key_reader_busy=1，可看一轮；两帧确认、3ms扫描间隔和多Voice参数加载不能一次完整覆盖。

## 探针
SCL、SDO；key_raw_frame；key_reader_state/key_reader_frame_valid；key_state/key_frame_valid；frame_error；event_valid/event_ready/event_note_on/event_note/event_key_index；key_event_accepted；key_reported_state；key_fifo_accepted_state；fifo_level；active_voice_count；原PCM和DAC。
key_raw_frame已经按极性转为按下=1，不是未翻转线电平。错误计数只捕获key_rejected_frames[7:0]，会回绕。
去掉重复accepted_raw和缩窄错误计数是GAO资源优化；深度、视频RTL、PLL、CST/SDC未改。

## 人工六阶段验收
前提：实物协议、电气先确认；当前safe默认FS不是BIT-TREE正式兼容版。
1. 原始bit：确认TTP后选候选profile1，用户手动构建/下载；逐键重复至少10次，记录raw_frame，检查双bit异常；不凭听音猜位序。
2. MIDI：填16行raw→physical→MIDI，设置参数；触发key_frame_valid，核对key_state。没确认就保持MAP=0。
3. 两/三键：触发key_event_accepted，确认valid&&ready接受多个On；单独松一键生成Off，其余保持。
4. 五/八/十六键：观察FIFO满时ready=0、payload保持；等待加载完成后检查Voice，不要求按下瞬间数量齐全。
5. 屏幕：映射确认后KEYS/MAP=1，真实位图/音名正确。Voice是发布快照，含尾音且有跨域延迟，不等于当前按住键数。
6. 完整声音：声音和FFT始终保留；前几阶段可外部静音监听设备，不需改核心。随后听单音/和弦/独立松键/重触发。

GUI中由用户人工切换已捕获的key_frame_valid、key_event_accepted、frame_error等触发，分扫描、事件接受、最终Voice状态多次保存。一个333us窗口不能证明多毫秒链路，结合完整仿真VCD/CSV。
如以后需要更深窗口或资格采样，另评估资源和构建；本轮不假装已经用GAO实测，也不自动改变板卡状态。
''')
def resources(p):
 out={}
 for k in ['Logic','Register','BSRAM','DSP','PLL']:
  m=re.search(r'^\s*'+k+r'\s*\|\s*([\d.]+)/(\d+)\s*\|\s*(\d+)%',text(p),re.M)
  if m:out[k]=float(m[1])
 return out
old,new=resources(B/'impl/pnr/yinyue_fashengqi.rpt.txt'),resources(R/'impl/pnr/yinyue_fashengqi.rpt.txt')
tab='|资源|上一轮整合|本轮安全默认|增量|\n|---|---:|---:|---:|\n'
for k in ['Logic','Register','BSRAM','DSP','PLL']:
 if k in old and k in new:tab+=f'|{k}|{old[k]:g}|{new[k]:g}|{new[k]-old[k]:+g}|\n'
body=f'''## 本轮真实执行
|项目|状态|绝对证据路径|
|---|---|---|
|16键映射/事件/FIFO|{unit.get('status')}|{O}/keyboard_unit_results.json|
|HUD映射标识及58位CDC|{hud.get('status')}|{O}/keyboard_status_results.json|
|旧安全默认新旧顶层对照|{obj(O/'integration/results.json').get('status')}|{O}/integration/results.json|
|候选16键到32Voice/双DAC/FFT/视频|{system.get('status')}|{O}/keyboard_system_results.json|
|原钢琴全回归|{piano}|{O}/piano_regression.log|
|显示回归|{'PASS' if 'ALL DISPLAY-ONLY CHECKS PASS' in text(O/'display_regression.log') else 'PENDING'}|{O}/display_regression.log|
|Gowin安全默认|{build.get('status')}|{A}/BUILD_INPUT_HASHES.json|
|BIT-TREE实物、芯片位序|未执行|没有烧录|

{unit.get('results',[])}
{hud.get('results',[])}
端到端输出：
{system.get('result',system.get('error','PENDING'))}

## 失败证据与重跑
首次Gowin生成FS但复位恢复-0.051ns，门禁FAILED；{A}/build_attempt1保留报告、FS和输入哈希。仅精简GAO探针重新实现，没有改视频RTL/PLL/管脚/SDC。
首次联合仿真19场景到Voice、max_active=32，末尾把瞬时计数与显示快照直接比较失败；修测试为按真实发布时刻逐帧核对58位状态，不改RTL。{A}/system_attempt1保留首轮日志、VCD、CSV；完整复测{O}/system_attempt2.log。
本轮原钢琴结果是新执行的{piano}，不是把上一轮补测汇总当新结果。

## 当前实现
{tab}
工具Gowin V1.9.12，GW5AST-LV138FPG676AC1/I0 Device C。
开始：{build.get('started_at_Asia_Shanghai')}
FS：{build.get('bitstream')}
SHA256：{build.get('bitstream_sha256')}
时序：{R}/impl/pnr/yinyue_fashengqi.tr
只在BUILD_INPUT_HASHES为PASS并与当前输入匹配时认定对应。串行125MHz为专用原语边界，不把无普通Fmax路径解释成眼图测试。
原TCK自动20MHz、50MHz通用路由、PLL/Hammer截断告警及外部I/O实测边界仍保留。
'''
body+=r'''
## 复现
在ROOT执行，Python为本机已有运行时；先把已有Icarus加入PATH或设置FPGA_IVERILOG/FPGA_VVP。
本机Icarus位于D:/gaoyun/piano_v2/codex_test/tools/iverilog/bin；新旧对照还只读访问BASE，不能称完全脱离原目录。
FENCEpowershell
python -X utf8 -B tools/run_keyboard_unit.py
python -X utf8 -B tools/run_keyboard_status.py
python -X utf8 -B tools/run_keyboard_system.py
python -X utf8 -B tools/run_keyboard_integration.py
python -X utf8 -B sim/run_tests.py all
python -X utf8 -B tests/display/scripts/verify_display.py
python -X utf8 -B tools/run_keyboard_build.py
FENCE
VCD：ROOT/tests/results/keyboard/keyboard_events.vcd、keyboard_serial.vcd、keyboard_system.vcd。
事件CSV：ROOT/tests/results/keyboard/keyboard_system_events.csv。
整机使用已验证等价数组ROM和名义PLL/串行边界桩；实际ROM/厂商原语另经语法展开及Gowin实现。仿真不是真实锁定、电气、模拟声音、底噪或显示器实测。
'''
timing=text(R/'impl/pnr/yinyue_fashengqi.tr');oldtiming=text(B/'impl/pnr/yinyue_fashengqi.tr')
body+='\n## 实际时序/Fmax对照\n|时钟|上一轮MHz|本轮MHz|\n|---|---:|---:|\n'
for clock in ['clk_50m','audio_clk','video_pixel']:
 pattern=r'^\s*\d+\s+'+clock+r'\s+[\d.]+\(MHz\)\s+([\d.]+)\(MHz\)'
 om=re.search(pattern,oldtiming,re.M);nm=re.search(pattern,timing,re.M)
 body+=f'|{clock}|{om[1] if om else "未列出"}|{nm[1] if nm else "未列出"}|\n'
body+='\n最终Setup/Hold违例端点均为0；Recovery/Removal按报告逐项检查，保留首轮负值证据。226块BSRAM相对194增加32，主要用于扩大GAO观测窗口，而非新增钢琴算法。\n'
summary=obj(A/'FINAL_VALIDATION.json')
body+='\n## 原目录完整性边界\n'
if summary:
 body+=f"原整合基线逐文件检查{summary['integrated_baseline_files_checked']}项无内容差异；受保护src {summary['protected_baseline_src_files']}项无变化；原四目录工程输入无变化。\n"
 for ex in summary.get('original_metadata_exceptions',[]):
  body+=f"明确例外：{ex['path']}与旧清单不同，文件时间{ex['modified_at_Asia_Shanghai']}，早于工作副本创建={ex['mtime_precedes_work_copy_creation']}。内容为GUI FlowState/ResultFileList/UI元数据；没有恢复/覆盖，也不推断改动来源。不能声称原四目录所有字节完全未变。详见FINAL_VALIDATION.json及ORIGINAL_USER_CONFIG_OBSERVED.xml。\n"
else:body+='最终复核结果待FINAL_VALIDATION.json；不能预先宣称全部原目录字节不变。\n'
write('KEYBOARD_TEST_RESULTS.md',body)
base=obj(A/'BASELINE_MANIFEST.json')['files'];changes=[]
for folder in ['src','sim','tools','tests/keyboard']:
 for p in sorted((R/folder).rglob('*')):
  if not p.is_file() or p.suffix not in ['.v','.sv','.py','.tcl','.cst','.sdc','.rao']:continue
  rel=p.relative_to(R).as_posix();h=hashlib.sha256(p.read_bytes()).hexdigest()
  if base.get(rel)!=h:changes.append({'destination':str(p),'source':str(B/rel) if rel in base else '本轮新增','change':'修改副本' if rel in base else '新增','sha256':h})
p=R/'yinyue_fashengqi.gprj';changes.append({'destination':str(p),'source':str(B/p.name),'change':'加入mapper；原依赖保留','sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
with open(A/'FILE_CHANGES.csv','w',encoding='utf-8-sig',newline='')as f:
 w=csv.DictWriter(f,fieldnames=list(changes[0]));w.writeheader();w.writerows(changes)
reasons={
'src/display/audio_visualizer.sv':'仅透传映射确认参数，不改FFT/视频链',
'src/display/piano_status_overlay.sv':'增加RAWS/KEYS及MAP确认标志，避免未确认映射误导',
'src/keyboard/keyboard_state_mapper.sv':'新增有效帧接纳、raw位排列、MIDI唯一性检查、错误计数',
'src/keyboard_debug.rao':'保留旧探针并增加扫描/握手/FIFO/Voice探针，4096深度；精简重复数据',
'src/tang_mega_138k_pro_top.v.v':'新增键盘profile/映射参数、mapper实际例化、严格空闲及实际FIFO接受监视',
'sim/run_more.py':'已有音频顶层回归补mapper依赖，不改变声学模型',
'tools/finalize_keyboard.py':'核对测试/构建/管脚/保护文件，分别记录GUI元数据例外与工程输入',
'tools/generate_keyboard_docs.py':'生成八份键盘文档和逐文件变更表',
'tools/run_keyboard_build.py':'新目录构建及输入/输出/FS哈希记录',
'tools/run_keyboard_integration.py':'以只读整合基线作新旧顶层对照',
'tools/run_keyboard_status.py':'执行映射标签及原状态CDC回归',
'tools/run_keyboard_system.py':'执行候选16键到真实32Voice/双DAC/FFT/TMDS联合验证',
'tools/run_keyboard_unit.py':'执行事件/FIFO/位序及假设串行协议单元测试',
'tests/keyboard/tb_keyboard_events.sv':'16位排列/和弦/独立松键/无效帧/FIFO满背压/复位/32位边界',
'tests/keyboard/tb_keyboard_hud.sv':'验证RAWS/MAP0和KEYS/MAP1及键位/音名',
'tests/keyboard/tb_keyboard_serial.sv':'真实Reader在TTP-BSF模型下逐键、FFFF首帧、异常及复位',
'tests/keyboard/tb_keyboard_system.sv':'实际接受/分配/Voice音高/双DAC/显示校验，按发布时刻对齐CDC',
'yinyue_fashengqi.gprj':'加入新mapper，保留原音频/显示/约束/GAO依赖'}
for row in changes:
 row['change']=reasons.get(Path(row['destination']).relative_to(R).as_posix(),row['change'])
with open(A/'FILE_CHANGES.csv','w',encoding='utf-8-sig',newline='')as f:
 w=csv.DictWriter(f,fieldnames=list(changes[0]));w.writeheader();w.writerows(changes)
table='|当前完整路径|来源|变化|SHA256|\n|---|---|---|---|\n'
for row in changes:table+='|'+'|'.join(row.values())+'|\n'
write('KEYBOARD_CHANGELOG.md',r'''全部修改仅在ROOT，BASE及D:/gaoyun/piano_v2/E盘资料不改。
复制时基线比旧清单多两个impl/temp/rtl_parser文件；其余交付哈希一致，不当作源码变化。
旧构建归档ROOT/audit/previous_integrated_build；旧八份文档归档ROOT/audit/previous_integration_docs。
新mapper、顶层参数/严格空闲/实际接受监视、HUD标识和GAO为本轮主要硬件变化；sim/run_more补依赖。
Reader/桥/FIFO/frontend/core/bank/allocator、钢琴/ROM/Mixer/FX/DAC、FFT/视频PLL/TMDS及CST/SDC原样保留。
回退时打开BASE/yinyue_fashengqi.gprj；硬件回退仅由用户手动选择旧已确认FS，没有自动回写/下载。
逐文件：
'''+table)
write('KEYBOARD_NEXT_STEPS.md',r'''## 已完成
见ROOT/docs/KEYBOARD_TEST_RESULTS.md和ROOT/audit/keyboard_v2/FINAL_VALIDATION.json。
当前默认KEYBOARD_PROFILE=0、DISPLAY_ENABLE=1、32Voice；Gowin安全默认不等于新BIT-TREE正式兼容版。

## 未完成/需要用户确认
- 提供确切商家TTP229.h/.cpp和指定文本，或芯片丝印/板号/模式资料；网页矛盾尚未消除。
- 确认直接串行/低有效/16键全多键/3.3V电气，再选择候选profile1，不能先改供电/焊接/引脚。
- 用GAO填写新16键物理位序，确认MIDI表，再设KEY_MAPPING_CONFIRMED=1。
- 按逐键、两/三键、五/八/十六键、显示、完整声音进行人工验收。
- 双16模块只预留逻辑边界，第二组管脚、仲裁和32键显示尚未实施。
本轮不处理PCM实物无声或音箱底噪。

## 打开和使用
ROOT/yinyue_fashengqi.gprj，顶层tang_mega_138k_pro_top，Device C，SystemVerilog2017。
确认src/keyboard/keyboard_state_mapper.sv实际在工程；有效CST/SDC保留，piano_fx仍经compat包含。
ROOT/impl/pnr/ao_0.fs是本轮安全默认FS，核对最终哈希；未经协议确认不能称新键盘已完成。
使用tools/run_keyboard_*.py。复制的旧汇总/构建脚本带旧路径/旧结果，不用于覆盖本轮资料。
没有自动烧录；原工程、上一轮整合及其FS保持。
''')
(R/'README.md').write_text(f'# Keyboard v2\n\n工程：{R}/yinyue_fashengqi.gprj\n\n只读基线：{B}\n\n安全默认KEYBOARD_PROFILE=0；BIT-TREE实物协议/位序待确认，不是正式兼容完成版。\n\n先读docs/KEYBOARD_PROTOCOL_AUDIT.md、KEYBOARD_TEST_RESULTS.md、KEYBOARD_NEXT_STEPS.md。使用tools/run_keyboard_*.py；旧报告在audit/previous_integrated_build和audit/previous_integration_docs。未自动烧录。\n',encoding='utf-8')
print(json.dumps({'docs':8,'file_changes':len(changes),'piano':piano,'build':build.get('status'),'candidate_system':system.get('status')},ensure_ascii=False))
