"""Accept only matching RTL simulation, fresh Gowin output and explicit IO audit."""
from pathlib import Path
import json,re,shutil,difflib,xml.etree.ElementTree as ET
from html.parser import HTMLParser
from run import R,O,A,sha,inputs,now
before=json.loads((A/'BEFORE.json').read_text())['sha256']
current=inputs();build=json.loads((A/'BUILD.json').read_text())
assert build['status']=='PASS' and build['input_sha256']==current
assert build['all_timing_checks_pass'] and build['inputs_unchanged']
for q,m in build['outputs'].items():assert m['fresh'] and sha(R/q)==m['sha256']

tests={}
for name in ['UNIT','SERIAL','SYSTEM','PRESERVE16','LOADROUTE32']:
    result=json.loads((O/(name+'.json')).read_text());assert result['status']=='PASS'
    diff=[q for q,h in result['input_sha256'].items() if current.get(q)!=h]
    # Initial unit and preservation runs preceded removal of one stale GAO net.
    # That XML is never compiled by Icarus. Every RTL file AND GPRJ must match.
    assert set(diff)<= {'src/keyboard_debug.rao'},(name,diff)
    tests[name]={'status':'PASS','all_RTL_and_GPRJ_hashes_match':True,
      'non_simulation_configuration_changed_after_test':diff,'record':str(O/(name+'.json'))}
assert tests['SYSTEM']['non_simulation_configuration_changed_after_test']==[]
assert json.loads((R/'impl/yinyue_fashengqi_process_config.json').read_text())==json.loads((A/'backup/impl/yinyue_fashengqi_process_config.json').read_text())
route=json.loads((O/'LOADROUTE32.json').read_text())
assert route['actual_RAM_writes_and_readbacks']==12800 and route['model_mismatches']==0

allowed={'src/tang_mega_138k_pro_top.v.v','src/ttp229_event_bridge.v',
 'src/keyboard/ttp229_keyboard_pair.sv','src/keyboard_debug.rao','src/integrated.cst','yinyue_fashengqi.gprj'}
changed=[q for q,h in current.items() if before.get(q)!=h]
assert set(changed)==allowed,changed
protected={q:h for q,h in before.items() if q.startswith('src/') and q not in allowed}
assert all(sha(R/q)==h for q,h in protected.items())
old_enabled=[dict(e.attrib) for e in ET.parse(A/'backup/yinyue_fashengqi.gprj').findall('./FileList/File') if e.get('enable')=='1']
enabled=[dict(e.attrib) for e in ET.parse(R/'yinyue_fashengqi.gprj').findall('./FileList/File') if e.get('enable')=='1']
assert enabled==old_enabled+[{'path':'src/keyboard/ttp229_keyboard_pair.sv','type':'file.verilog','enable':'1'}]
assert len(enabled)==68
assert all((R/e['path']).is_file() for e in enabled)

class Pins(HTMLParser):
 def __init__(self):super().__init__();self.rows=[];self.cells=None;self.cell=None
 def handle_starttag(self,tag,attrs):
  if tag=='tr':self.cells=[]
  if tag in ['td','th'] and self.cells is not None:self.cell=[]
 def handle_data(self,data):
  if self.cell is not None:self.cell.append(data)
 def handle_endtag(self,tag):
  if tag in ['td','th'] and self.cell is not None:
   self.cells.append(' '.join(''.join(self.cell).split()));self.cell=None
  if tag=='tr' and self.cells is not None:self.rows.append(self.cells);self.cells=None
def pin_rows(path):
 s=path.read_text(errors='replace');p=Pins();p.feed(s.split('<h1><a name="Pin_Details">',1)[1])
 i=next(i for i,row in enumerate(p.rows) if row and row[0]=='Loc./Bank')
 return p.rows[i+1:]
def port_rows(path):
 s=path.read_text(errors='replace');p=Pins();p.feed(s.split('<h1><a name="Pin_Details">',1)[1])
 i=next(i for i,row in enumerate(p.rows) if row and row[0]=='Loc./Bank')
 assert p.rows[0][0]=='Port Name'
 return {row[0]:row for row in p.rows[1:i]}
oldrows=pin_rows(A/'backup/impl/pnr/yinyue_fashengqi.pin.html')
rows=pin_rows(R/'impl/pnr/yinyue_fashengqi.pin.html')
assert len(rows)==len(oldrows)
pin_differences=[{'before':a,'after':b} for a,b in zip(oldrows,rows) if a!=b]
assert {d['after'][0] for d in pin_differences}=={'B19/5','A17/5'},pin_differences
for d in pin_differences:
 b=d['after'];assert d['before'][1]=='-' and b[5]=='LVCMOS33' and b[14]=='3.3'
 assert b[1:3]==(['ttp229_2_scl','out'] if b[0]=='B19/5' else ['ttp229_2_sdo','in'])
oldports=port_rows(A/'backup/impl/pnr/yinyue_fashengqi.pin.html')
ports=port_rows(R/'impl/pnr/yinyue_fashengqi.pin.html')
assert ports.keys()==oldports.keys()|{'ttp229_2_sdo','ttp229_2_scl'}
assert all(ports[k]==v for k,v in oldports.items())

netlist=(R/'impl/gwsynthesis/yinyue_fashengqi.vg').read_text(errors='replace')
gate=json.loads((O/'gate_loader32/RESULT.json').read_text())
assert gate['status']=='PASS' and gate['notes']==32 and gate['words']==12800 and gate['mismatches']==0
assert gate['netlist_sha256']==sha(R/'impl/gwsynthesis/yinyue_fashengqi.vg')
voices=sorted(set(map(int,re.findall(r'G_PARTIAL[.]G_VOICE\[(\d+)\]',netlist))))
assert voices==list(range(32))
assert not re.search(r'Compiling module .tb_', (O/'gowin.log').read_text(errors='replace'))
assert 'ttp229_2_scl' in netlist and 'ttp229_2_sdo' in netlist
rpt=(R/'impl/pnr/yinyue_fashengqi.rpt.txt').read_text(errors='replace')
resources={m[1]:{'used':float(m[2]),'available':float(m[3])} for m in re.finditer(r'^\s*(Logic|Register|BSRAM|DSP|PLL)\s*\|\s*([\d.]+)/([\d.]+)',rpt,re.M)}
assert set(resources)=={'Logic','Register','BSRAM','DSP','PLL'}
assert all(v['used']<=v['available'] for v in resources.values())
assert re.search(r'--Logic Register as Latch\s*\|\s*0/',rpt)

dest=O/'final_build';dest.mkdir(exist_ok=True)
for q in ['impl/pnr/ao_0.fs','impl/pnr/yinyue_fashengqi.tr','impl/pnr/yinyue_fashengqi.rpt.txt','impl/pnr/yinyue_fashengqi.pin.html']:
 shutil.copy2(R/q,dest/Path(q).name)
assert sha(dest/'ao_0.fs')==build['outputs']['impl/pnr/ao_0.fs']['sha256']
patch=[]
for q in sorted(changed):
 old=(A/'backup'/q).read_text().splitlines(True) if (A/'backup'/q).exists() else []
 patch.extend(difflib.unified_diff(old,(R/q).read_text().splitlines(True),fromfile='before/'+q,tofile='after/'+q))
(A/'CHANGES.patch').write_text(''.join(patch),encoding='utf8')
record={'status':'PASS','finished':now(),'project':str(R/'yinyue_fashengqi.gprj'),
 'input_sha256':current,'changed_files':changed,'protected_source_count':len(protected),
 'unchanged_piano_FX_FFT_video_DAC_SDC':True,'enabled_files':enabled,'simulations':tests,
 'Gowin_process_options_identical_to_backup':True,
 'actual_synthesized_voice_indices':voices,'pin_table_rows':len(rows),'pin_differences':pin_differences,
 'existing_port_attributes_unchanged':len(oldports),'added_port_attributes':{k:ports[k] for k in ['ttp229_2_scl','ttp229_2_sdo']},
 'post_synthesis_loader32':gate,
 'resource_usage':resources,'worst_slack_ns':build['worst_slack_ns'],
 'violated_endpoints':build['violated_endpoints'],'bitstream':str(R/'impl/pnr/ao_0.fs'),
 'archived_bitstream':str(dest/'ao_0.fs'),'fs_sha256':sha(dest/'ao_0.fs'),
 'midi_ranges':{'module1':[60,75],'module2':[76,91]},'display_keys':16,
 'board_wiring_verified':False,'audio_quality_acceptance':'Not established by this keyboard/32-voice functional acceptance',
 'no_auto_programming':True}
(A/'FINAL_ACCEPTANCE.json').write_text(json.dumps(record,ensure_ascii=False,indent=2),encoding='utf8')
summary='''本轮仿真、Gowin综合、布局布线及五类时序全部通过。未自动烧录，上板接线/协议/真实32键演奏与音质仍待确认。

'''
summary+='- FS：`impl/pnr/ao_0.fs`，同哈希归档 `tests/keyboard32_20261019/final_build/ao_0.fs`。\n'
summary+='- SHA256：`'+record['fs_sha256']+'`。\n'
summary+='- 实际综合网表包含32个钢琴Voice；68个有效工程输入；没有把测试平台参与综合。\n'
summary+=f'- 全部{len(rows)}行管脚表核对：仅原先空闲的B19、A17两行变为新增键盘接口；其余管脚字段全部不变。\n'
summary+=f'- {len(protected)}个受保护源文件哈希不变，包含钢琴/FX/FFT/HDMI/双DAC及完整SDC。\n'
summary+='\n| 时序检查 | 最差裕量/ns |\n|---|---:|\n'
summary+='\n'.join(f'|{k}|{v:.3f}|' for k,v in build['worst_slack_ns'].items())+'\n\n'
summary+='Setup/Hold违规端点均为0；Recovery、Removal和最小脉宽的最差裕量均非负。\n\n'
summary+='工具仍报告既有TA1132（GAO的tck_pad_i未显式建钟）及PR1014（clk_50m_d使用常规布线）警告，完整保留在日志中。本轮没有通过移除约束或放宽SDC消除警告，不能把“时序通过”理解为“没有任何工具警告”。\n\n'
summary+='| 资源 | 使用/总量 |\n|---|---:|\n'
summary+='\n'.join(f'|{k}|{v["used"]:g}/{v["available"]:g}|' for k,v in resources.items())+'\n\n'
summary+='- 实际本轮综合网表Loader与ROM的GW5A原语仿真：MIDI60～91共32音、12800个参数字，数学模型核对0处差异。只强制已捕获的请求音高/基准增量，不强制插值计算信号；该局部门级检查不覆盖键盘/Allocator，完整键盘通路由SYSTEM验证。\n'
summary+='- 两块串行键盘经过真实FIFO、Loader后，对32个实际Voice RAM端口的12800次写入逐次读回，全部成功；每一路RAM参数与该路MIDI音符的数学模型一致，0处差异。\n'
for label in ['events32','serial_pair','legacy16','preserve','system']:
 log=(O/(label+'.log')).read_text(errors='replace')
 lines=[s for s in log.splitlines() if s.startswith('PASS')]
 assert lines,(label,log[-1000:]);summary+='- '+lines[-1]+'\n'
summary+='\n首次综合因GAO引用已移除的旧 `key_reader_frame_valid` 名称而停止，未产生新实现，日志/失败门禁保存在 `gowin_attempt1.log` 和 `BUILD_attempt1.json`。移除该单个旧探针后重新完整实现；两模块的完整帧接纳脉冲由 `key_bank_frame_valid[1:0]` 捕获。时序门禁没有采用首次失败时仍在磁盘上的旧报告。初次系统仿真因缺少中途进度输出被主动终止，加入仅观测用时间输出后完整重跑，最终SYSTEM.json源哈希与当前工程一致。\n\n'
summary+='UNIT及原16键对照在GAO单个XML探针移除前完成，所有RTL及GPRJ哈希与最终构建一致；独立SERIAL及完整SYSTEM在最终配置下通过。此配置差异不参与Icarus编译，最终审计逐文件检查，未忽略任何RTL差异。\n'
p=R/'docs/KEYBOARD32_20261019.md';s=p.read_text();s=s.replace('待本轮综合、布局布线、时序及全部仿真完成后填入。',summary);p.write_text(s,encoding='utf8')
(R/'README.md').write_text('# 当前工程\n\n打开 `D:\\gaoyun\\piano_v2_audio_fix\\yinyue_fashengqi.gprj`。\n\n已扩展为两块独立16键模块，默认MIDI60～91。保留屏幕原16键对应、32 Voice、FFT、HDMI、双DAC和已验证音源/显示修复。\n\n'+summary.split('| 时序检查')[0]+'\n- [本轮接线与验证报告](docs/KEYBOARD32_20261019.md)\n- [此前显示升级](docs/DISPLAY_UPGRADE_16KEY_20261018.md)\n- [此前音源修复](docs/RECORDING_SYNTHESIS_FIX_20261018.md)\n',encoding='utf8')
(R/'docs/PROJECT_STATUS.md').write_text('# 当前状态（2026-10-19）\n\n主工程 `D:\\gaoyun\\piano_v2_audio_fix\\yinyue_fashengqi.gprj` 已完成双16键输入扩展及32键复音功能仿真、综合、布局布线与五类时序检查。\n\n默认原模块MIDI60～75，新增模块76～91。屏幕继续只绘制原模块16键，音频分析包含两模块总输出。\n\n'+summary+'\n[完整接线与验证说明](KEYBOARD32_20261019.md)\n',encoding='utf8')
print(json.dumps({k:record[k] for k in ['status','fs_sha256','changed_files','protected_source_count','resource_usage','worst_slack_ns']},ensure_ascii=False,indent=2))
