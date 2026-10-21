"""Final six requested documents and strict digital evidence gate."""
from pathlib import Path
import csv,html,json,re,sys
from scale_decay_run import R,A,O,sha,now,PY
def read(p,default=None):return json.loads(p.read_text(encoding='utf8')) if p.exists() else default
def report(n):return read(O/(n+'.json'),{'status':'NOT_RUN'})
def save(p,data):p.write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf8')
def md_table(headers,rows):return '| '+' | '.join(headers)+' |\n|'+'|'.join(['---']*len(headers))+'|\n'+'\n'.join('| '+' | '.join(map(str,row))+' |' for row in rows)+'\n'
def loc(p):return str(R/p)
def line(p,needle):return next(i for i,s in enumerate((R/p).read_text(encoding='utf8').splitlines(),1) if needle in s)
def ports(p):
    s=p.read_text(errors='replace');s=s[s.index('name="Pinout_by_Port_Name"'):s.index('name="All_Package_Pins"')];rows=[]
    for row in re.findall(r'<tr>(.*?)</tr>',s,re.S):
        v=[html.unescape(re.sub('<[^>]+>','',x)).strip() for x in re.findall(r'<td[^>]*>(.*?)</td>',row,re.S)]
        if len(v)>10 and '<b>' not in row:rows.append(v)
    return {row[0]:row for row in rows}
def resources(p):
    s=p.read_text(errors='replace');d={k:float(m[1]) for k in ['Logic','Register','BSRAM','DSP','PLL'] if (m:=re.search(r'^\s*'+k+r'\s*\|\s*([\d.]+)/',s,re.M))}
    q=p.parent.parent/'gwsynthesis/yinyue_fashengqi_syn.rpt.html'
    if q.exists() and (m:=re.search(r'\bPLL</td>\s*<td>(\d+)</td>',q.read_text(errors='replace'))):d['PLL']=float(m[1])
    return d
required=['mapping_default','mapping_permuted','mapping_transposed','direct_midi','voice_peak','keyboard_unit','keyboard_status','display','stress','hardware_syntax','full_regression','loader','audio_static_audit','audio_source_audit','nyquist_audit']+[f'direct_equivalence_{n}' for n in range(60,76)]+[f'recheck_voice_{n}' for n in range(60,76)]
tests={n:report(n) for n in required}
artnames=['MAPPING_PROVENANCE','AUDIO_PROVENANCE','DIRECT_CHAIN_AUDIT','LONG_DECAY','PCM_DATA_INTEGRITY']
art={n:read(O/(n+'.json'),{'status':'NOT_RUN'}) for n in artnames}
build=read(A/'BUILD.json',{'status':'NOT_RUN'})
same={n:all(sha(R/p)==h for p,h in m.get('input_sha256',{}).items() if p.replace('\\','/').startswith('src/') and Path(p).suffix in ['.v','.sv']) for n,m in tests.items() if m['status']=='PASS'}
if build.get('status')=='PASS' and not all(sha(p)==h for p,h in build['input_sha256'].items()):build=dict(build,status='STALE_INPUTS')
pin='NOT_RUN';after={};fmax={}
if build['status']=='PASS':
    pin='PASS' if ports(A/'backup/impl/pnr/yinyue_fashengqi.pin.html')==ports(R/'impl/pnr/yinyue_fashengqi.pin.html') else 'FAIL'
    after=resources(R/'impl/pnr/yinyue_fashengqi.rpt.txt');s=(R/'impl/pnr/yinyue_fashengqi.tr').read_text(errors='replace');fmax={n:float(v) for n,v in re.findall(r'^\s*\d+\s+(\w+)\s+[\d.]+\(MHz\)\s+([\d.]+)\(MHz\)',s,re.M)}
before=read(A/'BEFORE.json');saved={Path(p).as_posix():h for p,h in before['files'].items()}
protected=['src/integrated.cst','src/integrated.sdc','src/keyboard_debug.rao','src/display/visual_dvi_io.v','src/piano_partial_voice.v','src/piano_note_loader.v','src/voice_bank.v','src/voice_allocator.v','src/synth_core.v','src/piano_fx.v','yinyue_fashengqi.gprj']
unchanged={p:sha(R/p)==saved[p] for p in protected}
metrics=list(csv.DictReader((O/'NOTE_METRICS.csv').open())) if (O/'NOTE_METRICS.csv').exists() else []
numeric_ok=len(metrics)==32 and all(x['f0_reliable']=='True' and int(x['rail_samples'])==0 and float(x['sustain_rms_last_100ms'])>0 for x in metrics)
direct_rows=list(csv.DictReader((O/'DIRECT_MIDI.csv').open())) if (O/'DIRECT_MIDI.csv').exists() else []
chain_ok=len(direct_rows)==16 and [int(x['midi']) for x in direct_rows]==list(range(60,76)) and all(all(int(x[k])==1 for k in ['write_on','write_off','allocations','loader_done','held_voice_count','read_on','read_off']) and int(x['first_pcm_value'])!=0 for x in direct_rows)
numerical_proof=art['DIRECT_CHAIN_AUDIT'].get('partial_products_compared',0)>30000 and art['DIRECT_CHAIN_AUDIT'].get('fixed_point_formula_mismatches')==0 and art['LONG_DECAY'].get('no_overflow') is True and len(art['PCM_DATA_INTEGRITY'].get('notes',[]))==16
digital=all(x['status']=='PASS' for x in tests.values()) and all(x['status']=='PASS' for x in art.values()) and all(same.values()) and all(unchanged.values()) and numeric_ok and chain_ok and numerical_proof and build['status']=='PASS' and pin=='PASS'
validation={'time':now(),'project':str(R),'gprj':loc('yinyue_fashengqi.gprj'),'digital_validation':'PASS' if digital else 'INCOMPLETE','hardware_acceptance':'PENDING','no_auto_programming':True,'physical_order_confirmed':False,'tests':{n:m['status'] for n,m in tests.items()},'analysis_artifacts':{n:m['status'] for n,m in art.items()},'current_RTL_matches_tested':same,'preserved_components_unchanged':unchanged,'pin_check':pin,'build':build,'resources_before':resources(A/'backup/impl/pnr/yinyue_fashengqi.rpt.txt'),'resources_after':after,'fmax_MHz':fmax,'numerical_metrics_gate':numeric_ok,'all16_direct_chain_rows_verified':chain_ok,'numerical_proof_gate':numerical_proof,'known_limitations':['Physical BIT-TREE protocol/order and original last-four-key failure remain unverified','3s per-note RTL/FX streams are reused only after current source hashes and fresh per-note equivalence/data checks; new direct-injection runs are separate','Long natural decay to zero is measured in the verified fixed-point model; no hardware audio measurements','Base DDS is equal-tempered; original AMY partial1 measured frequency ratios introduce small cents offsets']}
save(A/'VALIDATION.json',validation)
stamp=f'工程：`{R}`\n\n入口：`{R/"yinyue_fashengqi.gprj"}`\n\n更新时间：{now()}。数字验证：**{validation["digital_validation"]}**；真实上板：**PENDING**。禁止自动烧录。\n\n'
source='src/tang_mega_138k_pro_top.v.v';base_line=line(source,'parameter [6:0] KEY_BASE_NOTE');table_line=line(source,'parameter [111:0] KEY_NOTE_TABLE');bridge_line=line(source,'.BASE_NOTE(KEY_BASE_NOTE)')
mapping=list(csv.DictReader((O/'KEY_MAPPING_COMPARISON.csv').open())) if (O/'KEY_MAPPING_COMPARISON.csv').exists() else []
old_new=md_table(['目标实体键（未实测）','配置raw bit','逻辑键','旧profile0 MIDI','本轮开始前 MIDI','当前RTL仿真 MIDI','目标音符','目标Hz'],[[x['target_physical_key'],x['configured_raw_bit'],x['logical_key'],x['old_profile0_midi'],x['before_this_round_midi'],x['current_simulated_midi'],['C','C#','D','D#','E','F','F#','G','G#','A','A#','B'][int(x['current_simulated_midi'])%12]+str(int(x['current_simulated_midi'])//12-1),f"{float(x['target_hz']):.6f}"] for x in mapping])
def doc(name,body):(R/'docs'/name).write_text('# '+name.removesuffix('.md')+'\n\n'+stamp+body,encoding='utf8')
doc('KEY_MAPPING_FIX.md',f'''旧 `keyboard_v2` 顶层在 KEYBOARD_PROFILE=0 时选择 60,64,68,72,61,65,69,73,62,66,70,74,63,67,71,75。当前 audio_fix 本轮开始前已是60～75，上一版 FS 的全部启用输入哈希与本轮快照一致。因此此前两个结论来自不同源码版本；未发现 gprj、构建 Tcl 或 GUI 配置覆盖这些参数。旧照片 raw2000→MIDI67 与旧表一致，当前配置为73。不能从旧照片推断已加载当前FS。

实际代码变更位于 `{loc(source)}`：第{base_line}行新增7位 KEY_BASE_NOTE=60；第{table_line}行把默认表明确写为16个 KEY_BASE_NOTE+i；第{bridge_line}行把桥的BASE_NOTE连接到同一参数。默认输出本轮前后均为60～75，不能把本轮配置改进宣称为再次修复默认跳跃音阶。

KEYBOARD_PROFILE=0仅选择Reader镜像保护；KEY_RAW_MAP_ENABLE=0；默认 RAW_INDEX_TABLE=fedcba9876543210，关闭重排时不参与计算。开启时，表的第 i 个低位4bit字段选择逻辑键 i 对应的 raw bit。KEY_NOTE_TABLE可显式覆盖默认音阶；使用连续默认表时 KEY_BASE_NOTE可用范围0～112。Event Bridge始终USE_NOTE_TABLE=1，直接接收16位mapper状态；本轮未修改桥、Reader或Mapper算法。

{old_new}
表中“实体键”是目标编号，raw列是当前配置，不是GAO测量。全部实体位序仍待GAO确认，KEY_MAPPING_CONFIRMED=0。先记录实体1～16的one-hot raw状态，再配置 RAW_INDEX_TABLE；音符表保持逻辑0～15连续。

三次独立实际顶层展开测试：默认base60、非恒等raw置换base60、默认raw的base48，均16个唯一音符，37 On/37 Off，包含高四位组合、独立松键及全16键。输出 `{O}/mapping_*.csv`、VCD、日志。HDMI的status_note直接使用同一NOTE_TABLE，测试核对其与最低被按逻辑键一致；联合测试另外验证真实CDC和TMDS输出。MIDI对应的基础DDS满足十二平均律（仅有32位量化）；AMY测量的Partial1仍有原有约3～10音分偏差，测得基频和实际相邻频率比见NOTE_METRICS，不冒充严格相等。

证据：`{O/'MAPPING_PROVENANCE.json'}`、`{O/'KEY_MAPPING_COMPARISON.csv'}`。本轮开始前可用FS已备份：`{A/'backup/impl/pnr/ao_0.fs'}`，SHA256 `{before['previous_fs_sha256']}`。

最新构建状态{build['status']}，FS哈希 `{build.get('sha256','待构建')}`；完整启用源码/约束/GAO/GUI过程配置哈希与实际默认参数组合保存在 `{A/'BUILD.json'}`。该记录与本轮默认展开仿真和当前文件逐项匹配，不能把当前代码与另一个目录的旧FS混用。
''')
high=[x for x in metrics if x['chain']=='fx_off' and int(x['note'])>=72]
high_table=md_table(['MIDI','测得f0 Hz','起音Peak整数（0～100ms）','起音RMS dBFS','按住最后100ms RMS','干声归零ms（松键2000ms）'],[[x['note'],f"{float(x['estimated_f0_hz']):.6f}",x['attack_peak_0_100ms'],f"{float(x['rms_dbfs_attack_0_0p1']):.3f}",f"{float(x['sustain_rms_last_100ms']):.3f}",f"{float(x['permanent_zero_from_ms']):.3f}"] for x in high])
doc('HIGH_NOTE_DECAY_ANALYSIS.md',f'''结论：MIDI60～75全部产生非零PCM；72～75在相同两秒按住期间没有提前归零。没有证实高音因位宽不足而整段静音，本轮不修改AMY参数、包络、增益或FX。

证据分层：本轮向真实32Voice synth_top直接注入每个MIDI，velocity100，每次复位清空其他Voice，512个held采样+512个release采样，观察FIFO/分配/Loader/active/非零PCM/松键；这是起音和事件链测试，不是完整长衰减测试。三秒音频为此前真实RTL流（相同velocity100、NoteOff=96000、144000个24位48k采样）；本轮重新核对算法及ROM哈希，逐音重新比较当前定点模型，并从RTL日志重建PCM数组、核对144000个FX样本。完整的长时间回归另行本轮重跑。长按自然归零扩展使用这些逐样本验证过的定点模型，明确不是板上测量。

{high_table}
FX前后32份WAV、精确首次非零样本和值、2秒松键后最终零点、基频、起音/持续/释放RMS、泛音相对功率均位于 `{O/'notes'}`、NOTE_METRICS.csv、HARMONIC_PEAKS.json、DECAY_CURVES.csv。自然长按模型的72/73/74/75零点分别11.510042、11.048229、10.717146、10.315896秒（自加载完成起）；60为9.255833秒、64为7.875896秒。支持正常频谱/包络差异，不支持高音一开始即归零。图：`{O/'decay_and_pitch.png'}`。

ROM检查：每4半音一组，vel40/80/120三层；Loader对相邻音高和力度进行两级有符号插值，缺失Partial保留FFF标记。16个键全部有15个非零有调性Partial，另有hammer槽。段长度192×2^n样本对所有音高相同；音高改变的是各槽21个电平断点和释放斜率。实际数据在LOADED_PARAMETERS.csv，覆盖60～64、64～68、68～72、72～75。MIDI64在0.1～0.5秒干声RMS约-36.373dBFS，68约-23.189dBFS，相差13.184dB；这一差异已存在于源AMY数据，不是插值突然越界，也没有证据应强行拉平。若实体位序等于raw序，旧表第四→第五键72→61可导致明显跳音；真实物理关系尚未确认，不能据此确定实物第五键的全部音色问题。

定点路径（AMY采用对数电平曲线，并没有独立普通ADSR幅度乘法）：

| 级 | 真实格式和运算 |
|---|---|
| ROM/插值 | level无符号12位Q4.8；音高差13位signed，乘积17位，算术右移2；力度差15位，乘积25位，算术右移8；末端限幅0～4094，FFF表示缺失 |
| 包络状态 | level无符号26位Q4.22，slope signed22位，更新signed28位饱和；边界差signed27×K3 signed18→signed45，算术右移24+n |
| 指数到幅度 | exp unsigned18位，拼6零得24位后按整数level右移；减1049在signed25位完成；结果≤1153门控为0，其他保留24位 |
| Partial乘法 | 幅度零扩展到signed27位×波形signed18位（Q17）→signed45位；16槽符号扩展累加到signed48位 |
| Voice | signed48累加算术右移18，随后饱和到signed24位 |
| Mixer/Gain | 32×signed24→signed29；正Q15增益32767扩展signed17，signed46乘积算术右移15；当前不按Voice数自动衰减 |
| FX | 输入signed29保留4小数位转signed32；各反馈乘法signed64并向零截断，状态饱和signed32；Limiter扩展signed36，增益×2、曲线、去4小数位，输出signed24 |
| DAC | PCM5102传signed24；PT8211取[23:8]，低8位量化与声音总线静音分开统计 |

真实RTL 32738条Partial记录逐条验证指数/门控/符号乘积，零不匹配；逐音Voice=Mixer，Gain公式精确，FX在实际DAC捕获相位具有明确1采样延迟，所有样本与模型相等。证据DIRECT_CHAIN_AUDIT.json、PARTIAL_FIXED_TRACE.csv、DIRECT_STAGES.csv、direct_midi.vcd。初始level=54525952，exp=262143，raw=2047，减1049得998，小于门限，因此起音最初为零是设计。MIDI64 tick55槽10 raw2203→1154，乘波形22175得25589950，证明门限刚上方未丢失；MIDI75 tick430槽8同样1154×90667=104629718。

量化确实存在：模型中MIDI75累加35887经过>>18得0；-237042经过算术>>18为-1，符号正确。这是个别零交叉/低幅采样，不等于整段静音。QUANTIZATION_COUNTS/EXAMPLES记录小于1LSB的乘积、正数归零、负数floor、最大乘积与累加；全部幅度/累加在位宽内，Voice无rail样本，最终自然门控关闭，未出现持续底噪。MIDI64某RTL样本Voice=-673265→Gain乘积-22060874255→>>15=-673245；相应样本索引FX=-1544793，见STAGE_EXAMPLES（FX按离线已验证流的样本索引对齐，实时延迟另列）。

新直接注入的首次DAC PCM时间也从VCD恢复的真实FIFO握手计算：MIDI72～75均为接受后3958个音频时钟，约0.322103ms，首次值依次309、326、343、362；详见ONSET_EVENT_TIMING.csv。不要与旧三秒流自仿真起始的第17采样混用时间原点。

特别区分显式门限与位宽丢失：amp_raw=2202时，减1049得到1153，按源代码门限直接置0；amp_raw=2203得到1154则保留。因此最终干声可能从数百PCM LSB变成0，例如MIDI64末尾574→0；这是原有AMY门控结束Voice，不能归咎于最终>>18只剩不足1LSB。NOTE_METRICS中的first_nonzero_ms是精确非零采样时间；旧特征字段onset_ms是10ms包络阈值所在窗口，不能混用。

全部24～104范围的1215个有调性频率在28位切片前检查，最高17694.0097Hz，小于24kHz；不把最大FFT峰当基音，基频估计同时使用Partial1频率、谐波支持与自相关。源表测量/插值造成的微小调音偏差和响度起伏保留；模拟输出及主观音色仍待板上试听。
''')
doc('VOICE_PEAK_ZERO_ANALYSIS.md',f'''VOICE直接对voice_active位图计数：`{loc('src/audio_telemetry.v')}` 的组合循环；`{loc('src/piano_partial_voice.v')}` 的active=(vstate!=V_IDLE)，包含加载、播放和偷音淡出，不取决于音频阈值，普通衰减时可在所有Partial门控后进入IDLE。env_level在Partial引擎中为0不等于active=0。

PEAK对最终FX后audio取绝对值，累计2400个48k采样（50ms）后发布整窗最大值，再清内部peak_work。公开audio_peak保留上次已完成窗口，直到下次发布；短按后可晚出现，再随后续全零窗口清零。HDMI的58位mailbox在音频pcm_valid时尝试快照，像素vblank时更新；不是每拍直播，短于刷新周期的Active事件可能遗漏。持续0.5秒的正常高音不能仅用这种采样遗漏解释。

本轮定向RTL证明：active=80000000且audio=0时VOICE=1、PEAK=0；active=0且audio=-6789时整窗后VOICE=0、PEAK=6789；所有32位active为1时VOICE=32。第2399采样尚未发布，第2400采样发布12345。见VOICE_PEAK_DEFINITION.csv和voice_peak.log。

顶层键盘高亮与桥共用mapper的16位key_state。HDMI MIDI是最低置位逻辑键的组合音符，不等于已被FIFO接受的最后MIDI。bridge的key_reported_state可能在输出事件挂起时已前进；确认接收应看event_valid&&event_ready、key_fifo_accepted_state、key_last_accepted_midi、key_note_on_count。实际FIFO读出计数与分配/加载计数继续区分下游边界。

本轮逻辑键11(MIDI71，实体目标12)与逻辑键12(MIDI72，实体目标13)，以及逻辑12～15(MIDI72～75)均通过On/Off、分配和非零PCM。DIRECT_MIDI.csv每音write On/Off=1/1、allocation=1、load=1、read On/Off=1/1、held VOICE=1。短注入只有约10.7ms按住，50msPEAK窗口尚未完成，不能把其PEAK=0当失败；较长的既有逐键4096采样测试和本轮联合压力测试验证非零窗口及实际显示快照。

Reader保留默认镜像保护：未确认16键时，上下字节相同的镜像帧可能屏蔽高8位；冷启动直接出现FFFF也受此策略影响。单独raw1000/2000/4000/8000会证明16模式并保留高位。这不是0FFF或12位截取。逻辑层的全16键无丢事件验证不能冒充冷启动镜像帧已无条件放行。实物BIT-TREE协议/位序未知，BFM通过不等于芯片模式已证实；实测确认16键协议后可评估KEYBOARD_PROFILE=1并重跑Reader和联合测试。本轮没有无依据更改该策略。

当前不能报告已找到真实最后四个实体键的零VOICE/PEAK根因，也不能断言它们就是MIDI72～75或某一确定事件链缺陷。需要同一新FS下逐键记录raw、mapped、真实FIFO写/读、last accepted MIDI、allocation、Loader、Active、前后PCM峰值、按住/松开时序，定位第一个不增长的边界。数据表见BOARD_KEY_RECORD.csv。数字测试排除了“这些MIDI本身必然静音”，没有排除板载版本、真实输入、事件传递或显示时序差异。
''')
testrows=[[n,m['status'],str(O/(n+'.log'))] for n,m in tests.items()]
commands='\n'.join(f'- `{n}`：`'+ ' '.join(map(str,m.get('command',[])))+'`；日志 `'+str(O/(n+'.log'))+'`。' for n,m in tests.items())
doc('AUDIO_TEST_RESULTS.md',f'''工作目录全部为 `{R}`；当前汇总 `{A/'VALIDATION.json'}`。命令的真实参数、起止时间、返回码和输入SHA256在每个同名JSON中。下列状态来自实际运行，不把历史PASS替代本轮要求的回归。

{md_table(['测试','状态','实际日志'],testrows)}
{commands}

新增分析入口：`{PY} -X utf8 -B tools/scale_decay_analyze.py provenance|audio|long_decay|direct_chain|data_integrity|onset`（每次选择一个动作）。audio_analysis.log、long_decay.log、direct_chain_analysis.log保留分析输出；逐音模型复核命令在recheck_voice_*及direct_equivalence_*的JSON。调度入口 `{PY} -X utf8 -B -u tools/scale_decay_run.py snapshot|mapping|direct|telemetry|keyboard|display|stress|parameters|syntax|regression|build`，每次选择一个动作，最终报告命令为 `{PY} -X utf8 -B tools/scale_decay_report.py --require-complete`。新直接注入16音都是当前真实32Voice RTL；3秒逐音文件按源哈希复用此前真实RTL，并本轮重新比较模型、重建PCM和检查FX，不冒充本轮重新跑满3秒。

量化数值、逐音频率/Peak/RMS/首次非零/最终零点：NOTE_METRICS.csv、STAGE_EXAMPLES.csv、QUANTIZATION_COUNTS.csv、PARTIAL_FIXED_TRACE.csv。短直接注入PCM5102共16832帧，零错误；联合压力21场景69On/53Off、69次分配、用到全部32Voice，12618 PCM5102帧和12618 PT8211字精确，6帧FFT、4826162 TMDS像素和15次源发布对齐状态快照通过。独立显示验证N1024/2048/4096；原有68项全回归的实际最终总数以full_regression.log末尾为准。

并发范围：稳定按住的16键和独立释放在映射/键盘/联合测试中验证完整接收。原有13ms快速重复触发压力场景保留桥的状态合并策略：若按下又松开均发生在未发出的NoteOn等待期间，可以不生成该短按事件；其测试期望加载64～132次，不是保证所有128次手势都各产生NoteOn。本轮没有重写事件系统；不要把该压力PASS解释成任意短按/任意背压下无条件保存全部历史手势。

显示边界：便携联合/显示仿真使用硬件PLL和物理OSER输出边界的stub，验证到真实TMDS编码数据；不能把这些日志称为板上HDMI电气验证。本轮hardware_syntax另用真实Gowin原语展开整个工程，新的P&R/STA检查物理实现。DVI局部复位RTL未变，上一轮真实Gowin行为原语对照记录保留在audit/continuation_20261017和tests/continuation_20261017，本轮不冒称重新运行该旧对照测试。

失败与补测：首次版本追溯分析因为快照字典混用正/反斜杠键而断言失败，FS与源码内容并未变化；修正路径规范化后逐项匹配，记录provenance_attempt1.json。映射三用例补跑一次，使默认用例连未启用的raw索引表也与正式默认参数完全一致，早期PASS保留在mapping_before_exact_default_parameter；生产RTL输出未变。其余本轮失败若有在对应JSON如实列出；硬件、实物位序、BIT-TREE芯片协议、模拟音频未执行。长按至最终零点为已验证模型扩展，不伪称16音都跑满60秒RTL。原有长音TB的fork/join会等待较晚的NoteOff，实际日志长度可超过名义ticks；本轮未缩短/修改这个既有测试。

Gowin状态：{build['status']}；FS `{loc('impl/pnr/ao_0.fs')}`；SHA256 `{build.get('sha256','待构建')}`。前后资源 `{validation['resources_before']}` → `{after}`；Fmax MHz `{fmax}`；时序 `{build.get('worst_slacks_ns',{})}`；引脚/IO/Bank对照 {pin}。video_serial没有常规内部Fmax路径，不能据此声称125MHz逻辑Fmax。关键既有Warning与完整日志保留在gowin.log，本轮没有修改SDC来隐藏违规。
''')
guide=f'''工程 `{loc('yinyue_fashengqi.gprj')}`；最新候选FS `{loc('impl/pnr/ao_0.fs')}`；SHA256 `{build.get('sha256','待构建')}`；本轮实现状态 **{build['status']}**。只在数字门禁PASS后由用户手动决定加载。本工具链没有自动烧录步骤。

1. 手离键盘复位，确认RAWS=0000、STAGE=3、MAP=0，检查工程与FS路径和哈希。每个实体键按住0.5～1秒、放开0.5秒，先正常键再异常键，每键重置计数或用模256差值。
2. 按实体1～16顺序填写 `{O/'BOARD_KEY_RECORD.csv'}`；记录one-hot raw与mapped，不能预设实体键1=raw0。目标MIDI为60+(实体编号-1)；当前raw顺序只是一份待验证配置。记录目标12/13键的边界，再核对最后四键。
3. GAO当前采样clk_12m288、深度4096（约333us），默认key_event_accepted触发。观察key_raw_frame、key_state、key_reported_state、key_fifo_accepted_state、event_valid/ready/on/note、key_last_accepted_midi、key_note_on/off_count、active_voice_count、audio_peak及diagnostic_chain。如果异常键不触发，触摸后手动force capture看保持计数和raw。
   该短窗口用于事件和约0.2ms加载过程；含预触发时未必覆盖首次PCM，更不覆盖50ms PEAK窗口。持续按住0.5秒后再force capture读sticky前后峰值和audio_peak，避免把采集窗口不覆盖误判为数字静音。
4. 每次正常按下writeOn、readOn、allocation/start、ld_done、ld_done&ld_ready应各+1；保持后pre/post峰值非零，松开writeOff/readOff各+1。GAO计数器捕获低8位，原RTL是16位；比较差值 `(after-before)&255`。diagnostic_chain [7:0]分配、[23:16]done、[39:32]done且ready、[71:48]pre峰、[95:72]post峰、[103:96]读On、[119:112]读Off。done且ready是完成时的资格计数，实际播放还需Active/PCM证据。
5. 沿第一个断点定位：raw存在但mapped无→Reader/Mapper；mapped存在但writeOn不增→Bridge/背压；write增read不增→FIFO/Core-ready；read增分配不增→Allocator；分配增done不增→Loader；正常Active但pre为0→Partial数值；pre非零post为0→Gain/FX；PCM非零而显示0→状态窗口/CDC；数字输出非零但听不见→DAC/模拟路径。不要仅凭琴键高亮判断已接收NoteOn。
6. 保存16键实测位序后，只配置KEY_RAW_MAP_ENABLE=1及KEY_RAW_INDEX_TABLE（每个逻辑键对应的raw索引从低位4bit起）；再跑三组mapping/keyboard/stress并重建。确认后才把KEY_MAPPING_CONFIRMED设为1；不要用旧profile0跳跃音符表补偿未知排列。
7. 对MIDI72～75按住两秒，比较FX关/开的WAV和板上输出，记录从NoteOn至Active/首次声响、松键时间；自然长衰减不能改成永不停止。分别听PT8211和PCM5102；进行反复复位和HDMI恢复测试，保留三通道local_rst_n修复。当前无法代替这些实物步骤。

回退：本轮前完整快照 `{A/'backup'}`、清单 `{A/'BEFORE.json'}`。只把备份中的顶层恢复到当前副本对应路径即可回退本轮生产代码；其他本轮新测试/文档可保留或移入当前副本内的归档目录。恢复FS只从该备份取，不覆盖旧正式工程。不要调用历史finalize脚本覆盖本轮报告。
'''
doc('BOARD_VALIDATION_GUIDE.md',guide)
changes=[]
scan=[R/'src/tang_mega_138k_pro_top.v.v',*list((R/'tools').glob('scale_decay_*.py')),*list(O.glob('*.sv')),*[R/'docs'/n for n in ['KEY_MAPPING_FIX.md','HIGH_NOTE_DECAY_ANALYSIS.md','VOICE_PEAK_ZERO_ANALYSIS.md','AUDIO_FIX_CHANGELOG.md','AUDIO_TEST_RESULTS.md','BOARD_VALIDATION_GUIDE.md','PROJECT_STATUS.md','test_manifest_all.txt']],R/'README.md']
for p in scan:
    if not p.exists():continue
    rel=p.relative_to(R).as_posix();old=saved.get(rel)
    if old==sha(p):continue
    changes.append({'path':str(p),'before_sha256':old,'after_sha256':sha(p),'reason':'Logical scale base/default-table/bridge parameter' if rel==source else 'New validation/evidence/reporting for scale and decay'})
doc('AUDIO_FIX_CHANGELOG.md',f'''本轮生产RTL只改 `{loc(source)}`：{base_line}行新增KEY_BASE_NOTE，{table_line}行生成连续逻辑音阶默认表，{bridge_line}行桥BASE_NOTE复用。默认音阶在本轮开始前已修正为连续，因此本轮改变的是配置表达与可测试性，默认输出未变。KEYBOARD_PROFILE、raw配置和物理未确认标记保留。

新增独立映射、32Voice直接MIDI、VOICE/PEAK窗口测试与数值分析脚本，完整路径和SHA见 `{A/'FILE_CHANGES.json'}`。没有修改AMY/ROM/Loader/Partial/Allocator/Gain/FX/双DAC/FFT/HDMI算法、引脚、电压或时钟；DVI局部复位修复保留。报告中的自然衰减及门限不作为错误进行主观调音。

开始前备份204个文件，最近可用FS哈希 `{before['previous_fs_sha256']}`，新FS哈希 `{build.get('sha256','待完成')}`。回退到 `{A/'backup'}` 中对应顶层及已保存FS，仍只写当前副本。每份测试meta保留命令、起止、返回值和输入哈希；唯一当前汇总 `{A/'VALIDATION.json'}`；历史continuation目录保留，不运行其finalize覆盖当前结论。
''')
doc('PROJECT_STATUS.md',f'''当前开发副本和所有输出均在本工程。最新逻辑音阶/衰减工作汇总 `{A/'VALIDATION.json'}`；此前continuation_20261017记录为历史基线。请先读KEY_MAPPING_FIX.md、HIGH_NOTE_DECAY_ANALYSIS.md、VOICE_PEAK_ZERO_ANALYSIS.md、AUDIO_TEST_RESULTS.md和BOARD_VALIDATION_GUIDE.md。

32Voice、AMY、混音音效、PT8211/PCM5102、FFT、HDMI、真实GAO计数和三通道DVI复位均保留。连续映射与直接MIDI非零PCM验证完成；实物最后四键零VOICE/PEAK根因未确认。当前FS `{loc('impl/pnr/ao_0.fs')}`，哈希 `{build.get('sha256','待构建')}`，实现状态{build['status']}。
''')
(R/'README.md').write_text('# 当前电子钢琴音阶与衰减验证工程\n\n'+stamp+f'当前记录：`{A/"VALIDATION.json"}`。先读docs/KEY_MAPPING_FIX.md、HIGH_NOTE_DECAY_ANALYSIS.md、VOICE_PEAK_ZERO_ANALYSIS.md、AUDIO_TEST_RESULTS.md、BOARD_VALIDATION_GUIDE.md。历史continuation_20261017保持原记录，不替代本轮结果。\n\n默认逻辑0～15连续MIDI60～75，本轮增加KEY_BASE_NOTE并验证配置。真实位序仍待GAO，最后四实体键问题尚未板上定位。32Voice、双DAC、FFT、HDMI和DVI复位修复保留。\n',encoding='utf8')
# Recompute document hashes after writing them.
changes=[]
for p in scan:
    if p.exists() and saved.get(p.relative_to(R).as_posix())!=sha(p):changes.append({'path':str(p),'before_sha256':saved.get(p.relative_to(R).as_posix()),'after_sha256':sha(p),'reason':'Logical-scale base/table/bridge parameters' if p.relative_to(R).as_posix()==source else 'Validation, scripts, requested documentation and current entry point'})
save(A/'FILE_CHANGES.json',changes)
with (A/'FILE_CHANGES.csv').open('w',encoding='utf8',newline='') as f:w=csv.DictWriter(f,fieldnames=list(changes[0]));w.writeheader();w.writerows(changes)
if not (O/'BOARD_KEY_RECORD.csv').exists():
    with (O/'BOARD_KEY_RECORD.csv').open('w',encoding='utf8',newline='') as f:
        headers=['physical_key','target_midi','measured_raw_hex','logical_key','last_accepted_midi','write_on_delta','read_on_delta','allocation_delta','loader_delta','VOICE_held','PEAK_held','pre_peak','post_peak','write_off_delta','read_off_delta','physical_status'];w=csv.DictWriter(f,fieldnames=headers);w.writeheader();w.writerows({'physical_key':i+1,'target_midi':60+i,'physical_status':'待GAO确认'} for i in range(16))
print('DIGITAL',validation['digital_validation'],'BUILD',build['status'],'hardware PENDING',flush=True)
if '--require-complete' in sys.argv and not digital:raise SystemExit(1)
