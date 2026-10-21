from pathlib import Path
import csv,re,json,hashlib,difflib,xml.etree.ElementTree as ET,html
R=Path(__file__).resolve().parents[1];O=Path(r'D:\gaoyun\piano_v2')
D=R/'docs';D.mkdir(exist_ok=True)
def read(p):return Path(p).read_text(encoding='utf-8-sig',errors='replace') if Path(p).is_file() else ''
def digest(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def md(name,text): (D/name).write_text(f'# {name[:-3]}\n\n整合工程：{R}\n\n原始基线：{O}\\yinyue_fashengqi.gprj\n\n更新时间：2026-10-16（本次本机审计/构建）。\n\n'+text.replace('FENCE',chr(96)*3),encoding='utf-8')
def jread(p):return json.loads(read(p)) if Path(p).is_file() else {}
inventory=list(csv.DictReader(open(R/'audit/SOURCE_INVENTORY.csv',encoding='utf-8-sig')))
entries=ET.parse(R/'yinyue_fashengqi.gprj').findall('./FileList/File')
enabled={e.attrib['path'] for e in entries if e.attrib.get('enable')=='1'}
effective=enabled|{'src/piano_fx.v'}
baseline=read(R/'audit/rebuilt_audio_baseline/pnr/yinyue_fashengqi.rpt.txt')
current=read(R/'impl/pnr/yinyue_fashengqi.rpt.txt')
def resources(text):
 out={}
 for k in ['Logic','Register','BSRAM','DSP','I/O Port','PLL']:
  m=re.search(r'^\s*'+re.escape(k)+r'\s*\|\s*([\d.]+)/(\d+)\s*\|\s*(\d+)%',text,re.M)
  if m:out[k]=(float(m[1]),int(m[2]),int(m[3]))
 return out
b,a=resources(baseline),resources(current)
timing=read(R/'impl/pnr/yinyue_fashengqi.tr')
pianolog=read(R/'tests/results/piano_final_regression.log')
pm=re.search(r'(\d+) tests, (\d+) failed',pianolog)
piano_state=(f'{pm[1]} 项，{pm[2]} 项失败' if pm else '运行中，不能宣称全量通过')
summary=jread(R/'docs/VALIDATION_SUMMARY.json')
if summary.get('status')=='PASS':
 piano_state=f"{summary['total_unique_piano_checks']}项汇总通过；首轮{len(summary['initial_full_run_failures'])}项测试初始化问题已通过{summary['affected_retest_count']}项补测闭合，原失败记录保留"
integ=jread(R/'tests/results/integration/results.json')
integ_state=integ.get('status','尚无结果')
# A stale failure JSON from an earlier compile must not be presented as final.
if not read(R/'tests/results/integration_equivalent_rom.log').strip():integ_state='运行中'
aux=jread(R/'tests/yinse/sim/out/current_results.json')
display_ok='ALL DISPLAY-ONLY CHECKS PASS' in read(R/'tests/results/display_final_source.log')
fs=R/'impl/pnr/ao_0.fs'
pinhtml=read(R/'impl/pnr/yinyue_fashengqi.pin.html')
rows=[]
for body in re.findall(r'<tr[^>]*>(.*?)</tr>',pinhtml,re.S):
 cells=[html.unescape(re.sub('<[^>]+>','',v)).strip() for v in re.findall(r'<td[^>]*>(.*?)</td>',body,re.S)]
 if cells and cells[0] in ['clk_50m','rst_n','ttp229_scl','ttp229_sdo','i2s_bclk','i2s_lrck','i2s_data','audio_pa_en','pcm5102_bclk','pcm5102_lrck','pcm5102_data','video_d_p[0]','video_d_p[1]','video_d_p[2]','video_d_n[0]','video_d_n[1]','video_d_n[2]','video_ck_p','video_ck_n']:rows.append(cells)
expect={'clk_50m':'P16','rst_n':'K16','ttp229_scl':'C21','ttp229_sdo':'B20','i2s_bclk':'E22','i2s_lrck':'F24','i2s_data':'G24','audio_pa_en':'H17','pcm5102_bclk':'C24','pcm5102_lrck':'B24','pcm5102_data':'H15','video_d_p[0]':'AB24','video_d_n[0]':'AC24','video_d_p[1]':'V24','video_d_n[1]':'W24','video_d_p[2]':'AA22','video_d_n[2]':'AA23','video_ck_p':'Y22','video_ck_n':'Y23'}
pin_result={}
for row in rows:
 # Gowin table: port, differential mate, package-pin/bank, constrained, direction...
 pin=row[2].split('/')[0];pin_result[row[0]]=pin
pin_ok=len(pin_result)==len(expect) and pin_result==expect
(R/'tests/results/PIN_AUDIT.json').write_text(json.dumps({'pass':pin_ok,'expected':expect,'actual':pin_result},indent=2),encoding='utf-8')
resource_table='|资源|本次重建音频基线|加入显示|增量|\n|---|---|---|---|\n'
for k in ['Logic','Register','BSRAM','DSP','I/O Port','PLL']:
 if k in b and k in a:
  resource_table+=f'|{k}|{b[k][0]:g} / {b[k][1]}（{b[k][2]}%）|{a[k][0]:g} / {a[k][1]}（{a[k][2]}%）|{a[k][0]-b[k][0]:+g}|\n'
protected=['synth_core.v','voice_bank.v','voice_allocator.v','piano_note_loader.v','piano_partial_voice.v','piano_fx.v','pcm5102_i2s_tx.v','ttp229_reader.v','ttp229_event_bridge.v']
protected_ok=all((R/'src'/n).read_bytes()==(O/'src'/n).read_bytes() for n in protected)
# Per-file provenance. Historical outputs are evidence, never new implementation.
mapping=[]
for x in inventory:
 root=x['SourceRoot'];rel=x['RelativePath'].replace('\\','/');target=None;role='未采用；保留原始来源'
 if root==str(O):
  if rel.startswith(('src/','sim/','tools/','ref/','backup/')) and (R/rel).is_file():target=R/rel;role='基线副本'
  elif rel=='yinyue_fashengqi.gprj':target=R/rel;role='主工程适配'
 elif root==r'E:\xiugai':
  if rel.startswith('srctianjia/'):target=R/'src/display'/rel[len('srctianjia/'):];role='显示实现'
  elif rel.startswith('sim/'):target=R/'tests/display/sim'/rel[4:];role='显示测试'
  elif rel.startswith('scripts/'):target=R/'tests/display/scripts'/rel[8:];role='显示测试脚本'
 elif root==r'E:\yinse':
  if rel=='xianshi/yinse_display_info.sv':target=R/'src/display/yinse_display_info.sv';role='真实当前音色名称（固定钢琴ID0）'
  elif rel in ['sim/audit/original/src/waveform_gen.v','sim/audit/original/src/waveform_set.v']:
   target=R/'src'/Path(rel).name;role='恢复与原回归清单哈希一致的缺失旧依赖'
  elif (R/'tests/yinse'/rel).is_file():target=R/'tests/yinse'/rel;role='候选独立测试；未接入演奏音频'
 if target and not target.is_file():target=None
 changed=bool(target and digest(target).lower()!=x['SHA256'].lower())
 mapping.append(dict(source=x['SourcePath'],destination=str(target) if target else '',role=role,
  modified=changed,source_sha256=x['SHA256'],destination_sha256=digest(target) if target else '',
  active_gprj=bool(target and target.relative_to(R).as_posix() in effective),
  verification=(
   'Gowin完整工程输入已实际接受：综合/P&R/Bitstream及0 Setup/Hold；未实例化备用分支不代表独立器件映射，功能证据见TEST_RESULTS.md' if target and target.relative_to(R).as_posix() in effective else
   '辅助音色/控制独立仿真PASS；未接演奏主链，未作Gowin资源映射' if target and 'tests/yinse/' in target.relative_to(R).as_posix() else
   '显示独立回归已执行PASS；FFT/CDC/TMDS具体覆盖见display_final_source.log' if target and 'tests/display/' in target.relative_to(R).as_posix() else
   '测试/工具副本；实际执行条目与日志见TEST_RESULTS.md；不按单文件推断功能通过' if target and target.relative_to(R).as_posix().startswith(('sim/','tools/')) else
   '保留参考或回退证据；不作为当前硬件输入' if target else
   '未作为新工程输入；未执行原二进制产物')))
with open(R/'audit/FILE_INTEGRATION_MAP.csv','w',encoding='utf-8-sig',newline='') as f:
 w=csv.DictWriter(f,fieldnames=list(mapping[0]));w.writeheader();w.writerows(mapping)
# Source-level comparisons, including old reference tops that must not be substituted.
diffdir=R/'audit/diffs';diffdir.mkdir(exist_ok=True)
comparisons=[]
pairs=[(O/'src/pll_init.v',R/'audit/reference_sources/xiugai/dependencies/pll_init.v')]
pairs += [(O/'src'/n,R/'audit/reference_sources/xiugai/reference'/(n+'.txt')) for n in ['synth_top.v','tang_mega_138k_pro_top.v.v','i2s_tx.v']]
pairs += [(O/'srctianjia'/p.name,p) for p in (R/'audit/reference_sources/xiugai/srctianjia').glob('*') if p.suffix in ['.v','.sv']]
for left,right in pairs:
 if not left.is_file() or not right.is_file():continue
 l,t=read(left),read(right)
 norm=lambda s:re.sub(r'\s+','',re.sub(r'/\*.*?\*/|//[^\n]*','',s,flags=re.S))
 diff=list(difflib.unified_diff(l.splitlines(),t.splitlines(),fromfile=str(left),tofile=str(right),lineterm=''))
 name=left.name+'.diff';(diffdir/name).write_text('\n'.join(diff)+'\n',encoding='utf-8')
 comparisons.append({'original':str(left),'candidate_snapshot':str(right),'byte_identical':left.read_bytes()==right.read_bytes(),'logic_text_identical_after_comments_whitespace':norm(l)==norm(t),'diff_lines':len(diff),'diff':str(diffdir/name)})
(R/'audit/SOURCE_COMPARISONS.json').write_text(json.dumps(comparisons,ensure_ascii=False,indent=2),encoding='utf-8')
# All important modules: full declarations + clocks + dependencies, not just a top file list.
rtl=list((R/'src').rglob('*.v'))+list((R/'src').rglob('*.sv'))
rtl+=list((R/'tests/yinse').rglob('*.sv'))
rtl=[p for p in rtl if not ('sim' in p.relative_to(R).parts and 'yinse' in p.relative_to(R).parts)]
blocks=[]
for p in sorted(rtl):
 text=read(p);clean=re.sub(r'/\*.*?\*/|//[^\n]*','',text,flags=re.S)
 for m in re.finditer(r'\bmodule\s+(\w+)\b(.*?)\bendmodule\b',clean,re.S):
  name=m[1];body=m[2]
  blocks.append({'module':name,'path':str(p),'relative':p.relative_to(R).as_posix(),'body':body,
  'declaration':body.split(';',1)[0].strip(),'clock_reset_edges':sorted(set(re.findall(r'\b(posedge|negedge)\s+(\w+)',body))),
  'active':p.relative_to(R).as_posix() in effective})
names={v['module'] for v in blocks}
for block in blocks:
 body=block.pop('body')
 block['dependencies']=sorted(n for n in names-{block['module']} if re.search(r'\b'+re.escape(n)+r'\s*(?:#\s*\(.*?\)\s*)?\w+\s*\(',body,re.S))
 block['upstream']=[];block['duplicate_definitions']=[b['path'] for b in blocks if b['module']==block['module'] and b['path']!=block['path']]
 for direction in ['input','output','inout']:
  block[direction+'_declarations']=re.findall(r'\b'+direction+r'\b[^;]+;',body)
 for row in mapping:
  if row['destination']==block['path']:block['source']=row['source'];break
 else:block['source']='本次新增适配'
for block in blocks:
 block['upstream']=sorted(set(b['module'] for b in blocks if block['module'] in b['dependencies']))
(R/'audit/MODULE_DETAILS.json').write_text(json.dumps(blocks,ensure_ascii=False,indent=2),encoding='utf-8')
functions={'tang_mega_138k_pro_top':'板级时钟、TTP229、32 Voice、双DAC和视频实际例化；默认 Stage3/显示开',
'synth_top':'保留音频调度；新增在 PT8211 实际锁存沿导出最终24位PCM',
'synth_core':'32 Voice、29位混音、增益、效果与遥测；原样保留',
'voice_bank':'共享加载器+32独立声部、ready/valid与抢占；实际写死32位匹配，不能直接降声部',
'voice_allocator':'空闲优先、释放声部优先、轮转抢占；原样保留',
'piano_note_loader':'相邻存储音高和力度插值；约2500clk加载16槽的频率与21点包络',
'piano_partial_voice':'15正弦泛音+hammer槽；非谐性、独立衰减、松键与64采样抢占淡出',
'piano_voice_ram':'每个Voice 512x32状态/参数RAM',
'piano_fx':'音板→混响→EQ→增益/软限幅；用2001兼容包装加载，算法原样',
'piano_soundboard':'4模态状态变量音板共振','piano_reverb':'4路延迟反馈网络与低通',
'piano_eq':'自然/暖/亮三档EQ','piano_limiter':'带饱和的分段软限幅','piano_delay_ram':'2048x18同步延迟RAM',
'pcm5102_i2s_tx':'24位标准I2S，32位时隙；3.072MHz BCK/48kHz LRCK，原样',
'i2s_tx':'板载PT8211 16位LSB对齐；仅增加只读frame_capture',
'ttp229_reader':'SDO两级同步、16位读取、确认和8键镜像保护',
'ttp229_event_bridge':'松键优先、事件保持/背压；实际物理键位映射保持',
'note_event_fifo':'16条事件同步FIFO','tree_mixer':'32路24位加至29位',
'polyphony_gain':'Stage3使用常量增益；归一化模式留给Stage1',
'audio_visualizer':'真实最终PCM波形/FFT；共享复位、快照与状态叠加',
'visual_fft':'单蝶形radix-2 FFT；18位数据、Q1.15系数、逐级除2；默认2048点Hann',
'visual_frame_store':'双缓冲稳定邮箱；忙时丢整帧并计数，不反压音频',
'visual_renderer':'消隐期间复制快照；波形/延迟相图/功率谱/最强非直流频率',
'visual_labels':'嵌入5x7字体及真实频率/时间刻度',
'visual_twiddle_rom':'4096对数学正余弦常量，同时用于FFT/Hann',
'visual_raster':'640x480有效区，800x525总时序',
'visual_tmds':'视频TMDS编码；always_comb修复初始求值',
'visual_video_clock':'独立25MHz像素/125MHz串行PLL；不改音频PLL',
'visual_PLL_MOD':'GW5AST C版视频PLL参数封装','visual_dvi_io':'3个OSER10+4个ELVDS_OBUF接J11',
'piano_status_cdc':'58位稳定总线握手邮箱，像素域仅在vblank更新',
'piano_status_overlay':'真实按键/音名/MIDI/Voice/峰值/Stage显示',
'yinse_display_info':'当前生效音色名称；此工程实际固定PIANO，组合初始求值适配',
'audio_telemetry':'活动声部计数、50ms峰值窗口与降采样遥测',
'telemetry_uart':'内部UART包封装，原样保留；外部未接UART端口',
'latency_monitor':'原延迟调试，实际可被优化；未删除','PLL_INIT':'复用原厂初始化，不重复引入同名候选定义',
'audio_PLL':'原50MHz→12.2881MHz时钟，保持原参数','audio_PLL_MOD':'原音频PLL器件C版封装',
'yinse_button':'双级同步与稳定按下/松开消抖','yinse_selector':'音色编号循环选择',
'yinse_switch':'等待真loader_busy/全键释放并淡出/提交/淡入；尚未接主链',
'yinse_controls':'两个按钮和切换控制封装；未分配按钮管脚',
'yinse_preset':'辅助包络及效果建议元数据','yinse_aux_bank':'独立4/16等声部辅助组，固定1/VOICES混音；非主钢琴替代',
'yinse_aux_voice':'管风琴/长笛/FM共享振荡调度+KS','yinse_note_table':'48kHz、MIDI36..96音高/KS调音表',
'yinse_sine_rom':'256点Q1.15数学正弦','yinse_envelope':'辅助ADSR包络',
'yinse_organ_profile':'九音栓加法管风琴','yinse_flute_profile':'三泛音简化长笛，非物理管道模型',
'yinse_bell_profile':'sqrt(2)频率比FM钟琴','yinse_ks_loop':'同步RAM拨弦环、损耗滤波及小数延迟全通校正',
'yinse_ks_tuning':'离线整数延迟与全通调音值传递','yinse_audio_mux':'满增益钢琴逐位透传候选；未接主链'}
functions.update({
'adsr_env':'旧引擎的攻击/衰减/保持/释放包络，Stage3不替代分泛音包络',
'performance_mode_controller':'旧演奏模式与内部事件控制，当前触摸顶层未启用',
'score_rom':'旧预置乐谱事件ROM，当前触摸顶层不播放内置乐谱',
'led_guide':'旧琴键/音高LED指示辅助；当前顶层无对应外部LED连接',
'morph_control':'按采样使能逐步平滑morph参数；当前顶层固定关闭',
'dds_phase_accum':'旧波形路径的相位累加',
'waveform_gen':'旧基本波形生成封装，已恢复与历史清单一致依赖',
'waveform_set':'旧正弦/方波/锯齿/三角波查表与选择，已恢复精确历史版本',
'voice':'Stage1旧钢琴声部：双层波表、弦模型、包络和力度流水线',
'piano_dual_wavetable':'Stage1低泛音体音/高泛音亮度两层同步波表',
'piano_envelope':'Stage1快速起音、快速/慢速衰减、尾音与松键制音',
'piano_string_model':'Stage1第二虚拟弦轻失谐与hammer/body生成',
'timbre_morph':'旧波形间的受控插值/形变通路',
'uart_tx':'ready/valid握手UART串行发送；当前遥测不接外部端口',
'saturator':'宽混音到24位的饱和转换，FX关闭时使用',
'test_mode':'内部多声部测试音符发生，当前顶层test_enable固定0',
'note_freq_table':'MIDI0..127到32位十二平均律相位增量；支持采样率常量缩放',
'piano_level_rom':'21音高x3力度x16槽x21时间点的12位包络数据',
'piano_ratio_rom':'包含非谐性的每泛音相对基频比值',
'piano_note_rom':'按音符查松键衰减斜率',
'piano_sine_rom':'512点四分之一正弦及插值增量同步ROM',
'piano_exp_rom':'分泛音dB包络转线性幅度的指数同步ROM'})
# Add explicit audit decisions without pretending pruned/unused definitions were separately mapped.
original_enabled={e.attrib['path'].replace('\\','/') for e in ET.parse(O/'yinyue_fashengqi.gprj').findall('./FileList/File') if e.attrib.get('enable')=='1'}
for block in blocks:
 block['function']=functions.get(block['module'],'原有备用或支持模块；接口及依赖详见源代码')
 block['included_in_original_gprj']=block['relative'] in original_enabled
 block['synthesis_assessment']=('已作为本次Gowin完整工程输入；默认参数裁剪的备用分支不等于独立器件映射通过' if block['active'] else '仅候选RTL/支持定义；未独立进行Gowin资源映射')
 block['integration_decision']=('已纳入工程；真实实例化关系见上游/综合层级，备用模块依参数裁剪' if block['active'] else '不直接接主链；安全切换/资源映射需另行适配验证')
(R/'audit/MODULE_DETAILS.json').write_text(json.dumps(blocks,ensure_ascii=False,indent=2),encoding='utf-8')
modulemd='完整机器可读端口声明、时钟/复位边沿、上游/下游及重复定义：'+str(R/'audit/MODULE_DETAILS.json')+'\n\n'
for bmod in blocks:
 classification='当前Gowin输入（实际例化见综合报告）' if bmod['active'] else ('独立候选测试' if '/tests/yinse/' in bmod['path'].replace('\\','/') else '保留备用/未入工程')
 modulemd+=f"## {bmod['module']}\n\n- 功能：{functions.get(bmod['module'],'原有备用或支持模块；接口及依赖详见 MODULE_DETAILS.json')}\n- 来源：{bmod['source']}\n- 整合/审查位置：{bmod['path']}\n- 分类：{classification}\n- 原主工程是否引用同路径：{bmod['included_in_original_gprj']}\n- 可综合性：{bmod['synthesis_assessment']}\n- 直接整合判断：{bmod['integration_decision']}\n- 时钟/复位边沿：{bmod['clock_reset_edges'] or '组合逻辑/见原厂原语'}\n- 依赖：{', '.join(bmod['dependencies']) or '无本地子模块'}\n- 上游：{', '.join(bmod['upstream']) or '顶层/未引用'}\n- 同名备选：{'；'.join(bmod['duplicate_definitions']) or '无'}；不在同一有效文件列表加载。\n- 端口/参数原声明：\n\nFENCEverilog\nmodule {bmod['module']} {bmod['declaration']};\nFENCE\n\n"
md('MODULE_MAP.md',modulemd)
diagram="""FENCEmermaid
flowchart LR
 subgraph A["12.2881 MHz 音频域；名义48 kHz采样使能"]
  K["原 TTP229 Reader"] --> E["原事件桥"]
  E --> Q["原16条Note FIFO"] --> L["原分配器+加载器"]
  L --> V["原32个 AMY partial Voice"] --> M["原29位树形混音/常量增益"]
  M --> FX["原音板/混响/EQ/限幅"]
  FX --> DAC["原PT8211 + PCM5102A"]
  DAC --> TAP["适配：实际DAC锁存沿只读PCM"]
  TAP --> FFT["xiugai: 2048点FFT/Hann"]
  TAP --> W["xiugai: 512点波形快照"]
  K --> STATUS["适配：真实按键/音名/声部数/峰值"]
 end
 C["50 MHz板级时钟"] --> AP["原音频PLL"] --> A
 C --> VP["xiugai 视频PLL"]
 VP --> PX["25 MHz像素域"]
 VP --> SER["125 MHz专用串行时钟"]
 FFT --> MB["xiugai 双缓冲CDC"]
 W --> MB
 STATUS --> SM["新增58位稳定握手CDC"]
 MB --> PX
 SM --> PX
 N["yinse: 实际PIANO名称"] --> HUD["新增状态叠加"]
 PX --> HUD --> T["xiugai TMDS/OSER10/差分输出"]
 SER --> T
 T --> HDMI["Pro Dock J11 DVI A(TX)"]
 GAO["原GAO：保留层级/探针"] -.-> A
FENCE
"""
md('INTEGRATION_PLAN.md',"""已按先审计→重建音频基线→候选独立验证→只读PCM接口→状态CDC→实际顶层接线→完整Gowin构建的顺序实施。

原钢琴、Voice调度、采样时钟和PCM5102A接口保持；没有复制另一套旧顶层替换新钢琴。显示不能影响 event_ready、sample_tick、voice loader 或音频复位。
视频掉锁只触发 analysis/display 两端共同异步断言、分别同步释放；音频继续运行。
DISPLAY_ENABLE=1 为真实显示，0 停止分析（视频边界/引脚保留，便于音频隔离测试）。仿真桩不加入.gprj。
状态总线采用请求/应答期间保持不变的58位快照，绝非多位逐位同步拼接。note显示最低编号的当前按下键；和弦其它键由16键位图显示。
当前音色ID0就是实际钢琴；其它四种音色只独立测试，未假装可以运行时切换。

"""+diagram)
md('INTEGRATION_AUDIT.md',"""## 文件与版本

四目录共2590个文件，全部路径/大小/SHA-256见 audit/SOURCE_INVENTORY.csv；逐文件来源、目标、是否改变、是否有效工程输入、验证范围见 audit/FILE_INTEGRATION_MAP.csv。
二进制、旧VVP、图片和旧构建文件只作清单/历史证据，不当作本次运行结果。
重要RTL、测试脚本、约束与说明已读取并建立依赖；ROM常量通过内容/哈希和仿真校验，不以修改日期选版本。

|目录|文件数|有效内容|选择|
|---|---:|---|---|
|D:/gaoyun/piano_v2|1701|AMY钢琴、32Voice、音效、TTP229、双DAC、GAO、已有构建/测试|正式基线，只读|
|E:/xianshi|10|VVP、FFT输入hex、历史报告；没有RTL|不能拿来直接加入Gowin|
|E:/yinse|818|17个独立辅助音色/控制RTL，测试，以及大量更早工程快照|采用名称模块；辅助音源只独立验证；恢复2个缺失旧依赖|
|E:/xiugai|61|11个显示RTL、显示测试、参考约束与旧顶层文本|采用显示链；复用原PLL_INIT，拒绝整份覆盖旧顶层|

根目录与 codex_test/project 的.gprj和40个引用文件完全一致。用户已明确选择根目录。
backup/2026-10-13_before_pcm5102 是局部回退包，并非所有依赖齐全的独立主工程。
xiugai 不含 yinse_ 辅助音色升级模块，它是显示迁移包；不存在“因为日期较新就整体覆盖yinse”的依据。
xiugai 的11个显示源文件与主目录 srctianjia 对应文件逐字节相同。PLL_INIT 与旧顶层差异见 audit/SOURCE_COMPARISONS.json 及完整统一diff。
xiugai/reference 中 synth_top/top/i2s 属于不同音源/接口架构，不能整份替代。

## 逐项技术决策

|修改项|原实现/候选区别|收益|代价/风险|验证|采用|
|---|---|---|---|---|---|
|基频/泛音/AMY/非谐性|原15泛音+hammer及21点曲线；yinse没有新钢琴|保护已验证音色|替换会丢失加载/衰减契约|原黄金模型、32Voice压力|保留原样|
|包络/自然衰减|钢琴分泛音dB轨迹；候选辅助ADSR不是等价替代|保持钢琴自然衰减|辅助ADSR不能替换AMY数据|单Voice长时与松键测试|保留原样|
|Hammer|原LFSR双低通；候选不是钢琴hammer补丁|维持一致|原有22→21位赋值告警仍记录；不未经证明修改|现有带/不带hammer逐样本测试|保留|
|混响/EQ/限幅|原4模态+FDN+三档EQ+软限幅；旧reference是另一架构|保留当前反馈数值稳定性|切音色需清理旧尾音，不能直接mux|FX定点模型、过载/静音回归|保留原样|
|混音增益/位宽|原32x24→29位、Stage3常量增益；辅助固定1/N|不引入按键数量泵音|辅助响度需单独校准|黄金PCM和双DAC逐bit|不新增音频mux|
|32Voice|原32并行；辅助组独立可参数化|避免声部退化|原bank/allocator有硬编码32位，不能直接降到16|32Voice占满与抢占压力|保留32|
|外接DAC|原24bit/32位时隙，sample_tick+7clk捕获|时序和接口不变|禁止把辅助pcm_valid代替DAC节拍|接收器解码、11种故障注入|原模块字节不变|
|PCM显示采样|旧visual_strobe是计算启动tick；新增真实锁存沿只读tap|屏幕与DAC取同一最终样本|增加少量扇出，无反压|同沿断言、原/新顶层逐时钟比较|采用|
|FFT/图形|候选真实radix2、双缓存、TMDS|真实频谱与波形|额外RAM/DSP/PLL；25MHz非标准25.175MHz|1024/2048/4096位精确、CDC、TMDS、Gowin|采用|
|状态界面|候选缺少当前钢琴键/声部状态界面|真按键/音名/Voice数/幅度/Stage|58位快照CDC、少量字符逻辑|状态来源断言与TMDS解码|适配新增|
|音色名称|yinse_display_info输出ASCII|真实显示当前PIANO|只固定ID0，不宣称辅助切换|HUD、独立控制测试|采用|
|辅助四音色|加法管风琴、简化长笛、KS吉他、FM钟琴|提供未来扩展|真loader_busy、FIFO flush、钢琴all_notes_off、FX尾音尚待适配；满载抢占可点击|独立音高/16Voice预算通过；无器件映射结论|暂不接主链|
|组合初始求值|原always @*在输入初始不变时Icarus出现X；always_comb首次求值|可复现的仿真可靠性修复|硬件组合函数不变|原TB失败复现、修后复跑|显示TMDS/名称采用；辅助修复仅测试副本|
|缺失回退依赖|原缺2个waveform文件；yinse历史快照哈希与原回归清单一致|恢复Stage1完整依赖|拒绝使用不同board版本同名文件|哈希与回退阶段测试|恢复并入.gprj|
|语言兼容|原piano_fx端口soft与SV关键字冲突|保留算法字节不变|需要2001关键字包装，避免重复定义|Gowin和Icarus完整工程|采用独立compat文件|

## 显示吞吐与资源

默认2048点，48kHz名义采样，观察窗42.667ms、频率栅格23.4375Hz，Hann窗。单蝶形5状态运算，加装载/输出少于65000音频时钟（约5.3ms），低于下一个42.667ms观察窗。
测试包含4096点、高幅随机数据、32个实际频谱峰、整帧过载丢弃统计。频谱最高非直流峰可能是泛音，绝不等于逐键音高识别。
像素25MHz、总800x525、有效640x480，约59.524Hz。45行vblank约36000像素时钟；清相图32768+波形512+默认频谱1024及少量控制，能放入消隐区。
字体/系数均嵌入RTL，没有外部字体文件、帧缓存芯片或运行时Python。显示路径保留双缓冲，不阻塞声音。XY是混音与延迟混音，不假称两个独立声部。

## 原工程风险保留

原 velocity-zero NoteOn 未在钢琴bank/frontend转换为NoteOff，这是静态审查项；TTP229固定力度100不触发。本次未擅改主核心，也不把候选旧报告中的失败复现算作本次测试。
原文档称PCM5102默认关闭，但源码已启用EXT_PCM5102、CST已生效。旧文档“无当前Gowin结果”同样过时，本次已实际重建。
原回归清单72文件匹配、2文件改动、2文件缺失，不能将历史68项PASS直接套到最初读取的目录。实际复测见TEST_RESULTS。
""")
hardware="""## 显示接线及证据

平台已由用户确认是138K Pro Dock；使用原工程既有4071f资料与本次下载的官方4071f Rev1.2（2024-10-10）图交叉核对。
官方来源：https://dl.sipeed.com/fileList/TANG/Mega_138K_Pro/02_Schematic/TANG_MEGA-138K_Pro-Dock-4071f_Schematics.pdf
本地："""+str(R/'ref/hardware/Pro_Dock_4071f_official.pdf')+"""
渲染页：ref/hardware/schematic_page_02.png、05.png、08.png、15.png。
第8页为J11 DVI A(TX)，第2页为Bank电压选择；默认Bank2/4/5为3.3V。没有修改任何供电选件。

|功能|FPGA管脚|连接|
|---|---|---|
|视频蓝D0 +/-|AB24 / AC24|J11 HDMI形状插座，DVI A(TX)|
|视频绿D1 +/-|V24 / W24|同上|
|视频红D2 +/-|AA22 / AA23|同上|
|视频时钟 +/-|Y22 / Y23|同上|
|50MHz|P16|原板级时钟|
|复位|K16|原连接|
|TTP229 SCL/SDO|C21 / B20|原PMOD2/J26|
|PT8211 BCLK/WS/DIN|E22 / F24 / G24|原板载DAC|
|耳放使能|H17|原连接|
|PCM5102 BCK/LCK/DIN|C24 / B24 / H15|保留原PMOD1/J24数字引脚|

新增仅8根视频差分物理管脚，均不与原11个音频/键盘/时钟/复位信号冲突。CST对正端指定一对，不对负端重复分配。
Ports&Pins实际报告核对："""+('PASS' if pin_ok else '尚未完成/需检查')+"""；详情 tests/results/PIN_AUDIT.json。
DVI视频无HDMI音频、EDID控制、CEC或HDCP。使用支持640x480约59.52Hz的显示器；显示器实际兼容性只能上板验证。

## 人工边界

本次没有连接板卡、自动烧录或改变硬件状态。首次上板前请核对实物为上述Pro Dock/J11且Bank电压选件未改；若丝印/版本/连接不一致，暂停下载并提供对应图纸。
PCM5102A模拟模块的VIN稳压、SCK/FMT/XSMT等原有待确认事项仍按 audit/baseline_docs/PINOUT_AND_WIRING.md 执行，本次不改变它们，不凭数字引脚分配推断供电。
TTP229要真实16键多键须模块本身配置支持；仿真通过不能代替TP选件和接线确认。
"""
md('HARDWARE_WIRING.md',hardware)
# Actual changes, including compatibility and test repairs, captured independently of an interrupted helper script.
changed=[]
for p in sorted((R/'src').rglob('*')):
 if not p.is_file():continue
 rel=p.relative_to(R).as_posix()
 origin=next((v['source'] for v in mapping if v['destination']==str(p)),None)
 old=Path(origin) if origin and origin.startswith(str(O)) else None
 if old and old.is_file() and old.read_bytes()==p.read_bytes():continue
 changed.append({'destination':str(p),'source':origin or '本次适配新增','sha256':digest(p),
 'rollback':str(R/'audit/preintegration'/rel) if (R/'audit/preintegration'/rel).is_file() else '删除该新增文件并恢复旧.gprj（仅在工作副本）'})
for p in [R/'yinyue_fashengqi.gprj',R/'impl/yinyue_fashengqi_process_config.json']:
 changed.append({'destination':str(p),'source':str(O/p.relative_to(R)),'sha256':digest(p),'rollback':str(R/'audit/preintegration'/p.relative_to(R))})
(R/'audit/CHANGE_PROVENANCE.json').write_text(json.dumps(changed,ensure_ascii=False,indent=2),encoding='utf-8')
changelog="""原始四目录只读；所有输出只在整合工程。受保护钢琴/键盘/DAC算法文件逐字节保持："""+str(protected_ok)+"""。
回退：本次重建的纯音频基线源文件与报告/GAO bitstream在 audit/rebuilt_audio_baseline；逐项修改前副本在 audit/preintegration，候选初始化修复前副本在 audit/pre_simulation_fix。
不要覆盖原工程。需要回退时，在整合目录另建副本并恢复上述基线的.gprj/src，不自动回写D:/gaoyun/piano_v2。

|实际源文件/工程修改|来源|SHA-256|
|---|---|---|
"""
for c in changed:changelog+=f"|{c['destination']}|{c['source']}|{c['sha256']}|\n"
changelog+="\n测试适配：sim/run_tests.py、sim/run_more.py采用SystemVerilog编译并排除重复FX定义；旧音频TB明确DISPLAY_ENABLE=0；tb_piano_fx仅改测试变量名以避开soft关键字。新增tests/integration与tools/run_integration_tests.py，采用原顶层/原synth_top/原i2s独立重命名作对照。\n\n首轮失败保留：显示TMDS初始X、候选音高表初始X、工具目录多嵌套、仿真桩端口语法、缺漏BFM/GSR、SV关键字冲突。修复及重跑结果分开保存，未删除失败日志。辅助6个左右组合模块只在tests/yinse修复，没有采用其音源进入主链。\n"
md('CHANGELOG.md',changelog)
tests="""## 本次实际执行

|项目|状态/证据|
|---|---|
|纯音频基线Gowin综合/P&R/Bitstream|完成；tests/results/gowin_baseline.log；audit/rebuilt_audio_baseline|
|完整集成Gowin综合/P&R/Bitstream|PASS；最终输入、输出和Bitstream哈希已复核，见audit/BUILD_INPUT_HASHES.json及BUILD_OUTPUT_HASHES.json|
|Setup/Hold|报告均为0违例；不能据此声称外部设备功能已通过|
|有效端口/管脚|"""+('PASS' if pin_ok else '未通过/待核对')+"""，tests/results/PIN_AUDIT.json|
|钢琴完整回归|"""+piano_state+"""；tests/results/piano_final_regression.log及docs/test_manifest_all.txt|
|完整新/原顶层对照|"""+integ_state+"""；tests/results/integration/results.json、integration_equivalent_rom.log|
|显示独立回归|"""+('PASS' if display_ok else '运行中/未通过')+"""；最终源复测tests/results/display_final_source.log及tests/display/sim_out_visual/verification_report.md|
|yinse独立仿真|"""+aux.get('status','尚无结果')+"""；tests/yinse/sim/out/current_results.json；不包含严格lint/Yosys/Gowin辅助音源映射|
|新增状态HUD/58位CDC|实际通过66组相干快照、vblank更新、字符/按键和复位恢复；tests/results/status_interfaces.log|\n|受保护核心源码哈希|"""+str(protected_ok)+"""；保护范围见INTEGRATION_AUDIT|
|原始四目录完整性复核|PASS，2590文件无增删改；tests/results/ORIGINALS_UNCHANGED.json|
|实际板上/显示器/示波器/音质|未执行；没有自动烧录|

"""+resource_table+"""
资源均来自本次本机Gowin V1.9.12，不采用旧报告估算。DSP为厂商归一资源计数，允许98.5等半单位。
音频基线Setup/Hold均0，音频域Fmax32.827MHz；本次完整显示工程的最终时钟明细见 impl/pnr/yinyue_fashengqi.tr。
video_serial由PLL产生125MHz，OSER10为器件专用串行原语；报告可能显示“No timing paths to get frequency”，这不等于已经测得串行输出眼图或外部显示器时序。
GAO的tck_pad_i有原工程同类自动时钟提示，工具按20MHz分析；没有为了清告警而猜测真实外部调试TCK频率。
PR1014板级50MHz走通用路由、原PLL和hammer截断告警仍需连同最终日志审阅。没有通过全局false path掩盖音频内部问题。\n新CST保留了原待定文件的历史注释；其“未启用”等旧说明不适用于本工程。当前唯一有效物理约束明确由.gprj中的src/integrated.cst决定，实际管脚检查已通过。

硬件语法检查实际使用Gowin GW5A prim_sim.v并加入GSR仿真实例。功能整机比较使用名义PLL/视频边界桩，以及原回归已逐地址验证等价的数组形式钢琴ROM；Gowin中的原case ROM未改。整机测试检查最终TMDS编码字，而非物理PLL锁定/OSER10串行眼图。未完成的大case-ROM功能仿真已因软件解释耗时中止，不算通过。
PCM5102独立接收验证及11/11故障注入检出均已通过；系统30718帧、压力38158帧数据校验无误，见piano_final_regression.log。
原完整回归与初始化补测的逐项合并结果见 docs/VALIDATION_SUMMARY.json；不是将失败日志改写成一次干净运行。原回归中的“PCM引脚off/on”旧条目名在当前EXT_PCM5102固定启用时实际比较内部信号观测与顶层端口观测，不能据此声称验证了宏关闭配置。\n先前失败记录不当作PASS；首轮piano_full_regression.log含工具路径错误及桩语法失败，不能作为最终全量通过报告。
完整all-run中的MIDI0初值和三组复位前引脚签名问题仅修测试台；原失败输出保存在tests/results/pre_retest及原日志。test_manifest_all在结束时记录文件哈希；这四项的实际重新运行证据以initialization_retest.json和test_manifest_initialization_retest.txt为准，汇总逐项记录在VALIDATION_SUMMARY.json。
"""
for line in timing.splitlines():
 if re.search(r'^\s*\d+\s+(audio_clk|video_pixel|clk_50m|tck_pad_i)\s+[\d.]+\(MHz\)',line):tests+='\n'+line.strip()+'\n'
if integ.get('status')=='PASS':tests+='\n完整顶层测试输出：\n\n'+'\n'.join(integ.get('results',[]))+'\n'
md('TEST_RESULTS.md',tests)
md('PROJECT_STATUS.md',f"""## 当前入口与能力

打开：{R/'yinyue_fashengqi.gprj'}
器件：GW5AST-LV138FPG676AC1/I0，Device C，顶层 tang_mega_138k_pro_top，SystemVerilog2017；原FX由2001兼容包装加载。
默认BUILD_STAGE=3、DISPLAY_ENABLE=1、外接PCM5102端口保持启用。新增RTL全部在.gprj中；五个钢琴ROM与FFT/字体资源均嵌入RTL并在有效依赖链中。
CST：{R/'src/integrated.cst'}
SDC：{R/'src/integrated.sdc'}
GAO：{R/'src/keyboard_debug.rao'}，探针/音频层级保留。
实际生成Bitstream（含GAO）：{fs}
当前该文件SHA-256：{digest(fs) if fs.is_file() else '尚无文件'}

原工程已有：TTP229确认/事件背压、32Voice AMY泛音钢琴、自然衰减/hammer、混音、音板/混响/EQ/限幅、板载PT8211与外接PCM5102、GAO。
本次接入：实际DAC最终样本旁路、真实波形/2048点FFT、J11 DVI视频、真实按键/音名/MIDI/活动Voice数/幅度/Stage状态，采用yinse的实际PIANO名称。
其它四音色独立验证，不在演奏链中；其切换、钢琴清理/FX尾音及用户按钮仍待专门适配。

当前钢琴完整回归：{piano_state}。
当前端到端对照：{integ_state}。
显示独立回归：{'PASS' if display_ok else '未完成'}。辅助候选独立仿真：{aux.get('status','未完成')}。
详细边界及失败重试记录以TEST_RESULTS.md为准，物理上板和试听未执行。

"""+resource_table)
md('NEXT_STEPS.md',f"""## 你可以直接打开的工程

1. Gowin FPGA Designer V1.9.12 → Open Project → {R/'yinyue_fashengqi.gprj'}。
2. 确认顶层 tang_mega_138k_pro_top、器件GW5AST-LV138FPG676AC1/I0 / Device C；Process Configuration的Verilog标准为SystemVerilog2017。
3. 工程树应出现src/display的14个模块，src/piano_fx.v为停用的被包含源文件，piano_fx_compat.v为有效入口；不能把两者同时独立编译。
4. 有效约束为src/integrated.cst、src/integrated.sdc，GAO为src/keyboard_debug.rao。其它备份CST/SDC不同时启用。
5. 运行Synthesize、Place & Route；检查综合层级有G_DISPLAY/u_visual/fft、wave_frames、spectrum_frames、G_STATUS/mailbox、u_video_io/channels，以及32个G_PARTIAL/G_VOICE。
6. 查impl/pnr/yinyue_fashengqi.rpt.txt中的3个OSER10、2个PLL、23个物理端口（含4个GAO JTAG），并用pin报告核对J11八个差分管脚与原音频11个管脚。
7. 查impl/pnr/yinyue_fashengqi.tr：audio_clk约12.288MHz、video_pixel25MHz、video_serial125MHz；Setup/Hold均0，且没有忽略的生成时钟约束。
8. 本次没有自动烧录。请在核对实物接线和Bank电压后，由你决定是否下载 {fs}，并保留旧正式工程和旧Bitstream作为回退。

## 复跑

PowerShell在 {R}：
FENCEpowershell
$env:PATH='D:\\gaoyun\\piano_v2\\codex_test\\tools\\iverilog\\bin;'+$env:PATH
$env:FPGA_IVERILOG='D:\\gaoyun\\piano_v2\\codex_test\\tools\\iverilog\\bin\\iverilog.exe'
$env:FPGA_VVP='D:\\gaoyun\\piano_v2\\codex_test\\tools\\iverilog\\bin\\vvp.exe'
& 'C:\\Users\\Yan Guyao\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe' -X utf8 -B sim/run_tests.py all
& 'C:\\Users\\Yan Guyao\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe' -X utf8 -B tools/run_integration_tests.py
& 'C:\\Users\\Yan Guyao\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe' -X utf8 -B tests/display/scripts/verify_display.py
& 'C:\\Users\\Yan Guyao\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe' -X utf8 -B tools/run_auxiliary_simulation.py
& 'C:\\Gowin2\\Gowin_V1.9.12_x64\\IDE\\bin\\gw_sh.exe' tools/build_gowin.tcl
FENCE
换电脑只需指定已有Python/Icarus/Gowin可执行程序；当前硬编码工具路径仅用于本机发现，不是RTL依赖。测试输出都在整合目录的build/tests；仿真模型和测试文件不加入下载工程。

## 最优先三个任务

1. 人工上板验收：先单键/和弦/32Voice压力，再接J11显示器；核对真实频谱、按键状态和两路DAC；保存截图、录音、板卡版本、Bitstream哈希。
2. 在此已验证钢琴/显示基线上设计真正的辅助音色切换：真loader_busy、FIFO安全清理、钢琴all_notes_off、淡入淡出和FX尾音处理，再核对可用用户按键后从4辅助Voice开始。
3. 依据实物结果优化显示兼容性和测量：必要时改为显示器支持的标准像素时钟；评估4096点分辨率/刷新折衷及串行输出时序。每次只改整合副本并回归。

不要覆盖正式原工程；等你确认新工程上板表现后再讨论替换。
""")
(R/'README.md').write_text(f'# Tang Mega 138K Pro 集成工程\n\n工程目录：{R}\n\n打开 {R/"yinyue_fashengqi.gprj"}。\n\n先读 docs/PROJECT_STATUS.md、docs/TEST_RESULTS.md、docs/NEXT_STEPS.md。\n原始工程和三个E盘来源保持只读；本目录是独立工作副本。没有自动烧录。\n',encoding='utf-8')
print(json.dumps({'module_definitions':len(blocks),'enabled_project_files':len(enabled),'file_mapping_rows':len(mapping),'pins_pass':pin_ok,'piano':piano_state,'integration':integ_state,'protected_core_unchanged':protected_ok},ensure_ascii=False))

