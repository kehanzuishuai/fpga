"""Publish after fresh full timing and targeted checks; retain prior test provenance."""
from pathlib import Path
import json,re,hashlib,shutil,datetime,xml.etree.ElementTree as ET,difflib
from html.parser import HTMLParser
R=Path(__file__).resolve().parents[2];A=R/'audit/remote_music_20261019';O=R/'tests/remote_music_20261019/out'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def read(p):return json.loads(p.read_text(encoding='utf-8'))
b=read(A/'BUILD.json');assert b['status']=='PASS' and b['inputs_unchanged'] and b['all_timing_checks_pass']
assert all(sha(R/q)==h for q,h in b['input_sha256'].items())
assert all(m['fresh'] and sha(R/q)==m['sha256'] for q,m in b['outputs'].items())
options=read(A/'BUILD_OPTIONS.json')
assert sha(R/options['path'])==options['sha256']
assert options['options']['TopModule']=='tang_mega_138k_pro_top'
assert options['options']['Verilog_Standard']=='Vlg_Std_Sysv2017'
assert options['options']['Run_Timing_Driven'] and options['options']['Correct_Hold_Violation']
assert options['options']['BACKGROUND_PROGRAMMING']=='off'
fwroot=R/'firmware/remote_music/esp32/ESP32_FPGA_Music_Controller'
fwdir=R/'tests/remote_music_20261019/esp32';fw=read(fwdir/'esp32_compile.json');assert fw['status']=='PASS'
assert all(sha(fwroot/q)==h for q,h in fw['sources'].items())
assert all(sha(fwdir/'esp32_build'/q)==m['sha256'] for q,m in fw['binaries'].items())
# User explicitly requested restoring the phone UI. This is the exact bundle
# hash from before the temporary title/notice edits, including all embedded assets.
assert sha(fwroot/'web_page.h')=='5428444eaa7aad9c41b0537b720fe516ef80e1186605d6154d6dbf38bfe253cf'
test_names=['phone','share_equiv','wav_formats','wav_errors','wav_dac','native_wav','native_replay','native_http','control','aux','preserve','gate_aux','audio_top','score_top','xy_timing','spi_timing']

# The user requested fewer repeated simulations. These are the only two RTL
# changes after the completed targeted suite, each backed by a fresh local check.
repair_backup=A/'routed_setup_negative_0554'
xy=read(O/'XY_TIMING_CHECK.json');assert xy['status']=='PASS'
assert xy['source_sha256']==sha(R/'src/display/visual_xy_plot.sv')
assert len(xy['cases'])==10 and all(c['bitmap_exact'] and c['additional_clocks']==512 for c in xy['cases'])
spi_current=read(O/'spi_timing.json')
assert spi_current['status']=='PASS' and spi_current['inputs_unchanged']
assert all(sha(R/q)==h for q,h in spi_current['input_sha256'].items())
checked_changes={q:{'before_sha256':sha(repair_backup/Path(q).name),'after_sha256':sha(R/q),'targeted_check':check}
 for q,check in [('src/display/visual_xy_plot.sv','XY_TIMING_CHECK.json'),('src/remote/wav_spi_stream.sv','spi_timing.json')]}
def validate_receipt(receipt):
 assert receipt['status']=='PASS' and receipt['inputs_unchanged']
 changed={q:h for q,h in receipt['input_sha256'].items() if sha(R/q)!=h}
 assert all(q in checked_changes and h==checked_changes[q]['before_sha256'] for q,h in changed.items()),changed
 return {'all_recorded_source_hashes_match':not changed,
  'reused_prior_result':bool(changed),'later_changes_covered_by_targeted_checks':{q:checked_changes[q] for q in changed}}
tests={}
for name in test_names:
 p=O/(name+'.log');text=p.read_text(errors='replace');assert 'PASS' in text and not re.search(r'FATAL:|^FAIL',text,re.M),name
 tests[name]={'log':str(p),'sha256':sha(p),'pass_messages':[x for x in text.splitlines() if x.startswith('PASS')]}
 if name!='phone':
  receipt=read(O/(name+'.json'));tests[name].update(validate_receipt(receipt))
  tests[name]['receipt_sha256']=sha(O/(name+'.json'))

# The last full display run was intentionally stopped. Never relabel its stale
# PASS receipt or partial current log as a successful current full-system run.
old_system_path=A/'prior_completed_system_receipt.json'
old_system=read(old_system_path)
assert read(O/'system.json')['status']=='STOPPED_PER_USER'
display_deps={q:h for q,h in old_system['input_sha256'].items() if q.startswith('src/display/')}
assert old_system['status']=='PASS' and len(display_deps)>=16
assert all(sha(R/q)==h or (q in checked_changes and h==checked_changes[q]['before_sha256']) for q,h in display_deps.items())
full_system={'status':'STOPPED_PER_USER','current_full_system_pass':False,
 'partial_log':str(O/'system.log'),'partial_log_sha256':sha(O/'system.log'),
 'prior_receipt':str(old_system_path),'prior_receipt_sha256':sha(old_system_path),
 'reuse_scope':'Prior display evidence only. Display source hashes unchanged except XY peak pipeline, checked separately with ten exact bitmaps. Other changed integration dependencies are covered by targeted audio/control checks, not a new complete HDMI-frame simulation.',
 'display_dependency_sha256':display_deps,'XY_pipeline_check':xy}
gate=read(O/'gate_loader32/RESULT.json')
assert gate['status']=='PASS' and gate['words']==12800 and gate['mismatches']==0
gate_reuse=None
if gate['netlist_sha256']!=sha(R/'impl/gwsynthesis/yinyue_fashengqi.vg'):
 oldnet=repair_backup/'yinyue_fashengqi.vg'
 assert sha(oldnet)==gate['netlist_sha256']
 def loader_modules(path):
  mods={m[1]:m[0] for m in re.finditer(r'^module\s+(\w+)\s*\([\s\S]*?^endmodule',path.read_text(),re.M)}
  wanted={'piano_note_loader'}
  while True:
   found={t for n in wanted for t in re.findall(r'^\s+(\w+)\s+[\\\w]+\s*\(',mods[n],re.M) if t in mods}
   if found<=wanted:break
   wanted|=found
  return {n:mods[n] for n in wanted}
 oldmods=loader_modules(oldnet);newmods=loader_modules(R/'impl/gwsynthesis/yinyue_fashengqi.vg')
 assert oldmods==newmods,'Loader mapping changed: a new short mapped check is required'
 gate_reuse={'current_full_netlist_sha256':sha(R/'impl/gwsynthesis/yinyue_fashengqi.vg'),
  'tested_full_netlist_sha256':gate['netlist_sha256'],'modules_byte_identical':{n:hashlib.sha256(s.encode()).hexdigest() for n,s in newmods.items()}}
tests['gate_loader32']={'log':str(O/'gate_loader32/run.log'),'sha256':sha(O/'gate_loader32/run.log'),'result':gate,'pass_messages':['Actual current integrated piano Loader/ROM: 32 notes, 12800 words, zero model mismatches; captured request pitch/inc forced, keyboard/allocator outside this isolated scope']}
tests['gate_loader32']['unchanged_mapped_modules_reuse']=gate_reuse
aux_gate=read(O/'GATE_AUX_NETLIST.json')
assert aux_gate['status']=='PASS' and aux_gate['netlist_sha256']==sha(R/'tests/remote_music_20261019/resource/lane/impl/gwsynthesis/probe.vg')
assert aux_gate['testbench_sha256']==sha(O/'tb_gate_aux.sv') and aux_gate['executable_sha256']==sha(O/'gate_aux.vvp')
assert set(aux_gate['parts'])=={f'gate_aux_{i}' for i in range(1,5)}
for i in range(1,5):
 part=f'gate_aux_{i}'
 assert aux_gate['parts'][part]==sha(O/(part+'.log'))
 part_record=read(O/(part+'.json'))
 validate_receipt(part_record)
 assert f'PASS actual Gowin shared lane instrument {i}: 8 voices, one arithmetic engine, 512 PCM frames bit exact' in (O/(part+'.log')).read_text()
tests['gate_aux']['mapped_netlist_check']=aux_gate
netview=read(O/'BANK_SIM_VIEW.json');assert sha(R/netview['original'])==netview['original_sha256']
assert sha(R/netview['generated'])==netview['generated_sha256']
equivalent=(R/netview['original']).read_text()
for old,new in netview['replacements']:
 assert equivalent.count(old)==1;equivalent=equivalent.replace(old,new)
assert equivalent==(R/netview['generated']).read_text()
assert '(EX3638)' not in (O/'gowin.log').read_text(errors='replace')
before=read(A/'BEFORE.json')['sha256']
changed=[q for q,h in before.items() if (q.startswith('src/') or q=='yinyue_fashengqi.gprj') and (R/q).is_file() and sha(R/q)!=h]
expected={'src/integrated.cst','src/integrated.sdc','src/keyboard_debug.rao','src/synth_core.v','src/synth_event_frontend.v','src/synth_top.v','src/tang_mega_138k_pro_top.v.v','src/display/audio_visualizer.sv','src/display/piano_status_overlay.sv','src/display/visual_xy_plot.sv','yinyue_fashengqi.gprj'}
assert set(changed)==expected,changed
protected={q:h for q,h in before.items() if q.startswith('src/') and q not in expected}
assert all(sha(R/q)==h for q,h in protected.items())
def enabled(p):return [e.attrib for e in ET.parse(p).findall('.//File') if e.get('enable')=='1']
old_files=enabled(A/'backup/yinyue_fashengqi.gprj');files=enabled(R/'yinyue_fashengqi.gprj')
assert len(files)==91 and files[:len(old_files)]==old_files and all((R/e['path']).is_file() for e in files)
assert all(not e['path'].startswith(('tests/','sim/','ref/','firmware/')) for e in files)
class Pins(HTMLParser):
 def __init__(self):super().__init__();self.rows=[];self.cells=None;self.cell=None
 def handle_starttag(self,tag,attrs):
  if tag=='tr':self.cells=[]
  if tag in ('td','th') and self.cells is not None:self.cell=[]
 def handle_data(self,data):
  if self.cell is not None:self.cell.append(data)
 def handle_endtag(self,tag):
  if tag in ('td','th') and self.cell is not None:self.cells.append(' '.join(''.join(self.cell).split()));self.cell=None
  if tag=='tr' and self.cells is not None:self.rows.append(self.cells);self.cells=None
def tables(p):
 h=Pins();h.feed(p.read_text(errors='replace').split('<h1><a name="Pin_Details">',1)[1]);i=next(i for i,r in enumerate(h.rows) if r and r[0]=='Loc./Bank')
 return {r[0]:r for r in h.rows[1:i]},h.rows[i+1:]
oldports,oldpins=tables(A/'backup/impl/pnr/yinyue_fashengqi.pin.html');ports,pins=tables(R/'impl/pnr/yinyue_fashengqi.pin.html')
new={'esp_uart_rx':'B21/5','esp_uart_tx':'A20/5','esp_spi_sck':'L17/4','esp_spi_mosi':'E25/4','esp_spi_cs_n':'H14/5','esp_spi_miso':'D25/4'}
assert ports.keys()==oldports.keys()|new.keys()
assert all(ports[k]==v for k,v in oldports.items())
assert len(pins)==len(oldpins)==378
diff=[{'before':a,'after':z} for a,z in zip(oldpins,pins) if a!=z]
assert {d['after'][0] for d in diff}==set(new.values()),diff
for d in diff:
 row=d['after'];assert d['before'][1]=='-' and row[5]=='LVCMOS33' and row[14]=='3.3'
 assert new[row[1]]==row[0]
net=(R/'impl/gwsynthesis/yinyue_fashengqi.vg').read_text(errors='replace')
piano=sorted(set(map(int,re.findall(r'G_PARTIAL[.]G_VOICE\[(\d+)\]',net))))
aux=sorted(set(map(int,re.findall(r'G\[(\d+)\][.]voice',net))))
assert piano==aux==list(range(32)),(piano,aux)
resource_tree=ET.parse(R/'impl/gwsynthesis/yinyue_fashengqi_syn_rsc.xml')
aux_resources=next(e for e in resource_tree.iter('SubModule') if e.get('name')=='G_AUX.bank')
shared_engines=sorted(e.get('name') for e in aux_resources if re.fullmatch(r'L\[[0-3]\][.]math',e.get('name','')))
assert shared_engines==[f'L[{i}].math' for i in range(4)]
assert aux_resources.get('T_Bsram')=='64(0)'
report=(R/'impl/pnr/yinyue_fashengqi.rpt.txt').read_text(errors='replace')
resources={m[1]:{'used':float(m[2]),'available':float(m[3])} for m in re.finditer(r'^\s*(Logic|Register|BSRAM|DSP|PLL)\s*\|\s*([\d.]+)/([\d.]+)',report,re.M)}
assert len(resources)==5 and all(v['used']<=v['available'] for v in resources.values())
assert re.search(r'--Logic Register as Latch\s*\|\s*0/',report)
dest=R/'tests/remote_music_20261019/final_build';dest.mkdir(exist_ok=True)
for q in b['outputs']:shutil.copy2(R/q,dest/Path(q).name)
for q in fw['binaries']:shutil.copy2(fwdir/'esp32_build'/q,dest/q)
shutil.copy2(fwdir/'esp32_compile.json',dest/'esp32_compile.json')
patch=[]
for q in sorted(changed):patch.extend(difflib.unified_diff((A/'backup'/q).read_text(errors='replace').splitlines(True),(R/q).read_text(errors='replace').splitlines(True),fromfile='before/'+q,tofile='after/'+q))
(A/'CHANGES.patch').write_text(''.join(patch),encoding='utf-8')
record={'status':'PASS','finished_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'project':str(R/'yinyue_fashengqi.gprj'),'FPGA_build':b,'firmware_build':fw,'simulations':tests,'changed_existing_files':changed,'unchanged_existing_source_count':len(protected),'new_files':[q for q in b['input_sha256'] if q not in before],'enabled_GPRJ_files':files,'piano_voice_indices':piano,'aux_voice_indices':aux,'pin_rows_checked':len(pins),'existing_port_attributes_unchanged':len(oldports),'new_ports':new,'pin_differences':diff,'resource_usage':resources,'fs_sha256':sha(dest/'ao_0.fs'),'final_build':str(dest),'display_physical_keys':16,'physical_keyboard_MIDI_ranges':[[60,75],[76,91]],'hardware_and_subjective_sound_quality_tested':False,'no_auto_programming':True}
record['GUI_process_configuration']=options
record['Icarus_connectivity_view']=netview
record['auxiliary_shared_engines']=shared_engines
record['auxiliary_independent_KS_RAM_blocks']=64
record['physical_keyboard_instrument']='Original piano only, 32 voices; no auxiliary instruments layered'
record['phone_timbre_scope']='MIDI/JSON scores only; WAV retains its recorded sound'
record['phone_UI_restored_bundle_sha256']=sha(fwroot/'web_page.h')
record['validation_policy']='Reduced regression per user: fresh checks only for changed paths; prior completed results retain original receipts and dependency hashes.'
record['timing_repair_targeted_checks']=checked_changes
record['full_system_regression']=full_system
record['implicit_forward_declaration_warnings']=0
warning_log=(O/'gowin.log').read_text(errors='replace')
record['synthesis_warning_counts']={k:len(re.findall(r'^WARN\s+\('+re.escape(k)+r'\)',warning_log,re.M)) for k in sorted(set(re.findall(r'^WARN\s+\((EX\d+|NL\d+)\)',warning_log,re.M)))}
warnings=[x.strip() for x in (O/'gowin.log').read_text(errors='replace').splitlines() if re.search(r'WARN\s+\((TA|PR)\d+\)',x)]
record['tool_timing_implementation_warnings']=sorted(set(warnings))
(A/'FINAL_ACCEPTANCE.json').write_text(json.dumps(record,ensure_ascii=False,indent=2),encoding='utf-8')
summary='# 本轮最终验证结果\n\n完整工程综合、布局布线、五类时序和ESP32固件编译通过。本轮针对性验证通过；按用户要求停止重复的完整显示回归，未改动部分复用已有验证，改动的XY峰值及SPI CRC流水线补做短验证。未自动烧录；真实接线、Wi-Fi长时间连续播放和主观音质仍待上板确认。\n\n'
summary+='实体32键固定为原来的32 Voice钢琴，不叠加其他乐器。手机五音色仅作用于MIDI/JSON曲谱，WAV保留录音原声。网页包已恢复修改前的原样，SHA256为`'+record['phone_UI_restored_bundle_sha256']+'`。\n\n'
summary+='- 工程：`D:\\gaoyun\\piano_v2_audio_fix\\yinyue_fashengqi.gprj`\n- FS：`impl/pnr/ao_0.fs`\n- FS SHA256：`'+record['fs_sha256']+'`\n- 固件和FS归档：`tests/remote_music_20261019/final_build`\n\n'
summary+='| 时序 | 最差裕量/ns |\n|---|---:|\n'+'\n'.join(f'|{k}|{v:.3f}|' for k,v in b['worst_slack_ns'].items())+'\n\nSetup/Hold违规端点均为0。\n\n'
if b.get('synthesis_provenance'):
 summary+='最终实现复用了本轮完整综合的同一综合网表，仅重新布局布线；源文件、时钟频率和SDC未改变。最终PnR选项为'+json.dumps(b['pnr_options'],ensure_ascii=False)+'。原始综合及前次实现结果收据保存在`'+str(Path(b['synthesis_provenance']['receipt']).relative_to(R))+'`，最终收据保存复用关系及网表哈希。\n\n'
summary+='| 资源 | 使用/总量 |\n|---|---:|\n'+'\n'.join(f'|{k}|{v["used"]:g}/{v["available"]:g}|' for k,v in resources.items())+'\n\n'
summary+=f'有效GPRJ输入{len(files)}个，原有{len(oldports)}个端口属性不变；全部378行物理管脚表核对，仅6个空闲管脚新增ESP32接口。实际综合网表保留32个钢琴Voice及32个辅助Voice；每次选择一个音色，共32个逻辑演奏Voice。\n\n'
for name,t in tests.items():summary+='- '+name+('（复用先前结果；后续两处流水改动单独验证）' if t.get('reused_prior_result') else '')+'：'+'；'.join(t['pass_messages'])+'\n'
summary+='\n完整system仿真本轮已按用户要求停止，当前没有新的整帧HDMI通过结论。旧完整显示结果仅按显示模块依赖哈希复用；XY新增流水级的10张位图与此前完全一致，每帧增加512个像素时钟，仍在消隐预算内。\n'
summary+='\n`audit/remote_music_20261019/FINAL_ACCEPTANCE.json`保存源文件/产物哈希、资源、管脚及完整结果。原始输入与修改前备份均保留。完整工具警告见`tests/remote_music_20261019/out/gowin.log`；通过不等同于零警告。\n'
summary+='\n键索引和FIFO计数已提前显式声明，本轮EX3638前向隐式声明警告为0。综合仍保留EX3791原有位宽截取和NL0002层级/未用逻辑优化；EX3791所涉及的PLL、钢琴参数/分音及显示标签源码与修改前一致。\n'
summary+='\n时序/实现工具提示：\n\n'+'\n'.join('- '+x for x in sorted(set(warnings)))+'\n\n其中GAO的`tck_pad_i`是未显式建钟的调试接口；本次五类时序通过指当前SDC覆盖的设计时钟检查，不包含外部JTAG时序验收。新SPI接口采用50MHz过采样同步器，上板线长、IO延迟及真实传输连续性仍需实测。\n'
(R/'docs/REMOTE_MUSIC_RESULTS_20261019.md').write_text(summary,encoding='utf-8')
(R/'README.md').write_text('# 当前工程\n\n打开 `D:\\gaoyun\\piano_v2_audio_fix\\yinyue_fashengqi.gprj`。\n\n手机ESP32 Wi-Fi控制、五音色、WAV在FPGA解码播放已集成；保留两块16键、32 Voice、原16键屏幕对应、FFT、HDMI和双DAC。\n\n[接线与使用说明](docs/REMOTE_MUSIC_20261019.md) · [最终验证结果](docs/REMOTE_MUSIC_RESULTS_20261019.md)\n\n'+summary[summary.index('完整工程'):summary.index('| 时序')],encoding='utf-8')
print(json.dumps({'status':'PASS','resources':resources,'slacks':b['worst_slack_ns'],'fs_sha256':record['fs_sha256']},indent=2))
