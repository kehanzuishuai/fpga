"""Register verification files in Gowin, then run and audit a fresh implementation.

No programming. Test benches, Python and reports are excluded from synthesis.
"""
from pathlib import Path
from datetime import datetime, timezone, timedelta
from collections import Counter
import hashlib, json, re, shutil, subprocess, sys, time
import xml.etree.ElementTree as ET

R=Path(__file__).resolve().parents[1]
assert R==Path(r'D:\gaoyun\piano_v2_audio_fix')
A=R/'audit/project_rebuild_20261018';O=R/'tests/project_rebuild_20261018'
PROJECT=R/'yinyue_fashengqi.gprj'
GW=Path(r'C:\Gowin2\Gowin_V1.9.12_x64\IDE\bin\gw_sh.exe')
DOC=R/'docs/GOWIN_PROJECT_REBUILD_20261018.md'
NEW=[
 ('tests/range44_20261018/tb_direct_midi.sv','file.verilog'),
 ('tests/range44_20261018/tb_audio_fx.v','file.verilog'),
 *[(p,'file.other') for p in [
  'tools/range44_run.py','tools/range44_analyze.py','tools/range44_report.py',
  'tools/range44_tail_probe.py','tools/range44_tail_rtl.py',
  'tools/build_gowin.tcl','tools/project_rebuild_20261018.py',
  'docs/SOUND_SOURCE_44_NOTE_RESULTS.md','docs/SOUND_SOURCE_32KEY_ACCEPTANCE.md',
  'docs/KEY_MAPPING_FIX.md','docs/HIGH_NOTE_DECAY_ANALYSIS.md','docs/VOICE_PEAK_ZERO_ANALYSIS.md',
  'docs/AUDIO_FIX_CHANGELOG.md','docs/AUDIO_TEST_RESULTS.md','docs/BOARD_VALIDATION_GUIDE.md',
  'docs/GOWIN_PROJECT_REBUILD_20261018.md','docs/PROJECT_STATUS.md','README.md',
  'tests/range44_20261018/NOTE_METRICS_44.csv','tests/range44_20261018/LISTENING_ROOM.html']]]

def now():return datetime.now(timezone(timedelta(hours=8))).isoformat()
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def dump(p,obj):p.parent.mkdir(parents=True,exist_ok=True);p.write_text(json.dumps(obj,ensure_ascii=False,indent=2),encoding='utf8')
def entries():return [dict(e.attrib) for e in ET.parse(PROJECT).findall('./FileList/File')]
def enabled():return [x for x in entries() if x.get('enable')=='1']
def design_inputs():
    paths=[p for p in (R/'src').rglob('*') if p.is_file()]
    paths += [PROJECT,R/'tools/build_gowin.tcl',R/'impl/yinyue_fashengqi_process_config.json']
    return {p.relative_to(R).as_posix():sha(p) for p in paths}

def prepare():
    if (A/'BEFORE.json').exists():raise RuntimeError('Backup exists; refusing overwrite')
    A.mkdir(parents=True,exist_ok=True);O.mkdir(parents=True,exist_ok=True)
    paths=[*(R/'src').rglob('*'),PROJECT,R/'impl/yinyue_fashengqi_process_config.json',
     R/'tools/build_gowin.tcl',R/'docs/PROJECT_STATUS.md',R/'README.md',
     R/'impl/pnr/ao_0.fs',R/'impl/pnr/yinyue_fashengqi.tr',
     R/'impl/pnr/yinyue_fashengqi.rpt.txt',R/'impl/pnr/yinyue_fashengqi.pin.html',
     R/'impl/gwsynthesis/yinyue_fashengqi_syn.rpt.html']
    files={p.relative_to(R).as_posix():sha(p) for p in paths if p.is_file()}
    for rel in files:
        dest=A/'backup'/rel;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(R/rel,dest)
    old=entries()
    dump(A/'BEFORE.json',{'time':now(),'files':files,'project_entries':old,'enabled_files':enabled(),'no_auto_programming':True})
    DOC.write_text('# Gowin工程文件登记与重新实现\n\n构建状态：待运行。验证文件加入工程但不参与综合；生产RTL未改；禁止自动烧录。\n',encoding='utf8')
    existing={x['path'] for x in old};lines=[]
    for path,kind in NEW:
        assert (R/path).exists(),path
        if path not in existing:lines.append(f'        <File path="{path}" type="{kind}" enable="0"/>')
    text=PROJECT.read_text(encoding='utf8');assert text.count('    </FileList>')==1
    block='        <!-- Verification and review artifacts: excluded from synthesis. -->\n'+'\n'.join(lines)+'\n'
    PROJECT.write_text(text.replace('    </FileList>',block+'    </FileList>'),encoding='utf8')
    assert enabled()==[x for x in old if x.get('enable')=='1']
    assert all((R/x['path']).exists() and (R/x['path']).resolve().is_relative_to(R) for x in entries())
    assert all(next(e for e in entries() if e['path']==p)['enable']=='0' for p,k in NEW)
    dump(A/'PROJECT_UPDATE.json',{'time':now(),'status':'PASS','added_files':[{'path':p,'type':k,'enable':'0'} for p,k in NEW if p not in existing],'added_count':len(lines),'enabled_entries_unchanged':True,'enabled_count':len(enabled()),'total_project_files':len(entries()),'gprj_sha256':sha(PROJECT),'production_rtl_changed':False,'type_reference':'Installed Gowin example data/examples/vga_text_generator/vga_text_generator.gprj uses file.other; existing project uses enable=0 for excluded HDL.'})
    print('PROJECT UPDATED:',len(lines),'excluded verification/review files;',len(enabled()),'active inputs unchanged',flush=True)

def warnings(text):
    values=[]
    for s in text.splitlines():
        if re.search(r'\bWARN(?:ING)?\b',s,re.I):
            s=re.sub(r'\(\d+(?:,\s*\d+)?\)', '(LINE)',s)
            values.append(s.strip())
    return Counter(values)

def build():
    assert (A/'PROJECT_UPDATE.json').exists()
    inp=design_inputs();start=time.time()
    cmd=[str(GW),str(R/'tools/build_gowin.tcl')]
    record={'status':'RUNNING','started':now(),'command':cmd,'cwd':str(R),'input_sha256':inp,'enabled_files':enabled(),'project_entries':entries(),'log':str(O/'gowin.log'),'no_auto_programming':True}
    dump(A/'BUILD.json',record)
    try:
        with (O/'gowin.log').open('w',encoding='utf8') as f:
            p=subprocess.run(cmd,cwd=R,stdout=f,stderr=subprocess.STDOUT,timeout=10800)
        rc=p.returncode
    except Exception as exc:
        record.update(status='ERROR',finished=now(),error=repr(exc));dump(A/'BUILD.json',record);raise
    paths=['impl/pnr/ao_0.fs','impl/pnr/yinyue_fashengqi.tr','impl/pnr/yinyue_fashengqi.rpt.txt','impl/pnr/yinyue_fashengqi.pin.html','impl/gwsynthesis/yinyue_fashengqi_syn.rpt.html']
    outputs={p:{'exists':(R/p).exists(),'fresh':(R/p).exists() and (R/p).stat().st_mtime>=start,'sha256':sha(R/p) if (R/p).exists() else None} for p in paths}
    text=(R/'impl/pnr/yinyue_fashengqi.tr').read_text(errors='replace')
    names={'setup':'3.1.1 Setup Paths Table','hold':'3.1.2 Hold Paths Table','recovery':'3.1.3 Recovery Paths Table','removal':'3.1.4 Removal Paths Table','min_pulse_width':'3.2 Minimum Pulse Width Table'}
    slacks={k:float(m[1]) if (m:=re.search('^'+re.escape(v)+r'.*?\n\s*1\s+([\d.-]+)',text,re.M|re.S)) else None for k,v in names.items()}
    endpoints={kind:int(m[1]) if (m:=re.search(r'<Numbers of '+kind+r' Violated Endpoints>:(\d+)',text)) else None for kind in ['Setup','Hold']}
    fmax={m[1]:{'constraint_MHz':float(m[2]),'actual_Fmax_MHz':float(m[3])} for m in re.finditer(r'^\s*\d+\s+(\S+)\s+([\d.]+)\(MHz\)\s+([\d.]+)\(MHz\)',text,re.M)}
    stable=inp==design_inputs()
    same_pins=sha(R/'impl/pnr/yinyue_fashengqi.pin.html')==sha(A/'backup/impl/pnr/yinyue_fashengqi.pin.html')
    # Compare pin table contents if generation timestamps/header differ.
    def pin_data(p):
        html=p.read_text(errors='replace')
        assert '<h1><a name="Pin_Details">' in html
        return re.sub(r'\s+',' ',html.split('<h1><a name="Pin_Details">',1)[1])
    pin_match=same_pins or pin_data(R/'impl/pnr/yinyue_fashengqi.pin.html')==pin_data(A/'backup/impl/pnr/yinyue_fashengqi.pin.html')
    fresh=all(x['fresh'] for x in outputs.values())
    timing=all(x is not None and x>=0 for x in slacks.values()) and endpoints=={'Setup':0,'Hold':0}
    baseline=(R/'tests/scale_decay_20261017/gowin.log').read_text(errors='replace')
    oldw,neww=warnings(baseline),warnings((O/'gowin.log').read_text(errors='replace'))
    dump(A/'WARNING_COMPARISON.json',{'baseline':'tests/scale_decay_20261017/gowin.log','baseline_count':sum(oldw.values()),'new_count':sum(neww.values()),'new_or_more':list((neww-oldw).elements()),'removed_or_less':list((oldw-neww).elements())})
    ok=rc==0 and fresh and stable and timing and pin_match
    record.update(status='PASS' if ok else 'FAIL',finished=now(),elapsed_seconds=time.time()-start,returncode=rc,outputs=outputs,fresh_outputs=fresh,inputs_unchanged=stable,all_timing_checks_nonnegative=timing,worst_slack_ns=slacks,violated_endpoints=endpoints,fmax=fmax,pin_assignments_unchanged=pin_match,sha256=sha(R/'impl/pnr/ao_0.fs'),fs=str(R/'impl/pnr/ao_0.fs'),hardware_acceptance='PENDING',audio_quality_acceptance='NOT_ACCEPTED',production_rtl_changed=False)
    dump(A/'BUILD.json',record)
    print(json.dumps({k:record[k] for k in ['status','returncode','fresh_outputs','inputs_unchanged','worst_slack_ns','violated_endpoints','pin_assignments_unchanged','sha256']},indent=2),flush=True)
    if not ok:raise RuntimeError('Build or strict checks failed; inspect BUILD.json and current reports')

def recheck():
    """Audit the completed run without rerunning Gowin; ignore pin-report date headers."""
    b=json.loads((A/'BUILD.json').read_text())
    assert b['status']!='RUNNING' and b['returncode']==0 and b['fresh_outputs'] and b['inputs_unchanged'] and b['all_timing_checks_nonnegative']
    assert b['input_sha256']==design_inputs()
    for rel,m in b['outputs'].items():assert sha(R/rel)==m['sha256']
    netlist=R/'impl/gwsynthesis/yinyue_fashengqi.vg'
    voice_indices=sorted(set(map(int,re.findall(r'G_PARTIAL[.]G_VOICE\[(\d+)\]',netlist.read_text(errors='replace')))))
    test_modules=re.findall(r'Compiling module .tb_[A-Za-z_0-9]*',(O/'gowin.log').read_text(errors='replace'))
    assert voice_indices==list(range(32)) and not test_modules
    dump(A/'SYNTHESIS_SCOPE.json',{'status':'PASS','time':now(),'actual_partial_voice_indices_in_netlist':voice_indices,'voice_count':32,'testbench_modules_compiled':test_modules,'netlist_sha256':sha(netlist),'project_sha256':sha(PROJECT),'enabled_entries':enabled()})
    def pin_rows(p):
        from html.parser import HTMLParser
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
        text=p.read_text(errors='replace');assert '<h1><a name="Pin_Details">' in text
        parser=Pins();parser.feed(text.split('<h1><a name="Pin_Details">',1)[1]);return parser.rows
    old=pin_rows(A/'backup/impl/pnr/yinyue_fashengqi.pin.html');new=pin_rows(R/'impl/pnr/yinyue_fashengqi.pin.html')
    assert old==new,'Actual pin assignment fields changed'
    dump(A/'PIN_COMPARISON.json',{'status':'PASS','time':now(),'rows_compared':len(new),'all_pin_fields_identical':True,'excluded':'Report metadata including Created Time; all Pin Details table cells compared','before_report_sha256':sha(A/'backup/impl/pnr/yinyue_fashengqi.pin.html'),'current_report_sha256':sha(R/'impl/pnr/yinyue_fashengqi.pin.html')})
    if b['status']!='PASS':
        dump(A/'BUILD_FIRST_PIN_HEADER_CHECK.json',b)
        b.update(status='PASS',pin_assignments_unchanged=True,pin_check_revalidated_at=now(),pin_check_correction='First wrapper compared Created Time in the HTML report; all Pin Details table cells now independently compared, with no source/Gowin/output changes.')
    rpt=(R/'impl/pnr/yinyue_fashengqi.rpt.txt').read_text(errors='replace')
    b['resource_usage']={m[1]:{'used':float(m[2]),'available':float(m[3])} for m in re.finditer(r'^\s*(Logic|Register|BSRAM|DSP|PLL)\s*\|\s*([\d.]+)/([\d.]+)',rpt,re.M)}
    assert all(k in b['resource_usage'] for k in ['Logic','Register','BSRAM','DSP','PLL'])
    dump(A/'BUILD.json',b)
    print('PASS: fresh completed implementation, all timing, all',len(new),'pin table rows verified; no Gowin rerun',flush=True)

def report():
    b=json.loads((A/'BUILD.json').read_text());p=json.loads((A/'PROJECT_UPDATE.json').read_text())
    assert b['status']=='PASS' and b['input_sha256']==design_inputs()
    before=json.loads((A/'BEFORE.json').read_text())
    assert all(sha(R/q)==h for q,h in before['files'].items() if q.startswith('src/'))
    for rel,m in b['outputs'].items():assert sha(R/rel)==m['sha256']
    notes=['# Gowin工程文件登记与重新实现','',f'完成时间：{now()}。工程：`{PROJECT}`。','', '**本轮实际重新运行：综合 PASS、布局布线 PASS、五类时序检查 PASS、生成新FS。没有自动烧录。**','',f'`.gprj`新增{p["added_count"]}个验证/分析/文档条目，全部enable=0；原{p["enabled_count"]}个启用条目及生产RTL保持不变。已有RTL改动继续参与综合；测试台为file.verilog，Python/Tcl/报告为file.other，均可在项目中管理但不参与综合。', '', '本次构建的音源算法仍是当前版本：44音测量发现的响度低谷和87～89极弱尾段退出风险没有被修复；32个优质音色的音质验收仍NOT_ACCEPTED。实体最后四键无声、两块16键接入及同时32Voice仍需独立实物验收。','', '32 Voice、AMY、FFT、HDMI、PT8211、PCM5102A和GAO保留；顶层BUILD_STAGE=3、DISPLAY_ENABLE=1，仍为16键逻辑MIDI60～75。CST/SDC、引脚、时钟/电压配置和音源参数未改。','', '## 本轮时序','', '|检查|最差Slack(ns)|','|---|---:|']
    notes.extend(f'|{k}|{v:.3f}|' for k,v in b['worst_slack_ns'].items())
    notes+=['',f'Setup/Hold违反端点：{b["violated_endpoints"]}。引脚表与构建前一致：{b["pin_assignments_unchanged"]}。Removal裕量很小，数字STA通过不代替板上复位/重启和HDMI恢复验收。','', '|时钟|约束MHz|报告Fmax MHz|','|---|---:|---:|']
    notes.extend(f'|{k}|{v["constraint_MHz"]:.3f}|{v["actual_Fmax_MHz"]:.3f}|' for k,v in b['fmax'].items())
    notes+=['','video_serial不具有普通内部逻辑Fmax报告，不能把其目标频率当成测得Fmax。','', '|资源|用量/可用|','|---|---:|']
    notes.extend(f'|{k}|{v["used"]:g}/{v["available"]:g}|' for k,v in b['resource_usage'].items())
    w=json.loads((A/'WARNING_COMPARISON.json').read_text())
    notes+=['',f'警告基线{w["baseline_count"]}条，本轮{w["new_count"]}条；新增/增多{len(w["new_or_more"])}条。继承TA1132（tck_pad_i未显式创建时钟）和PR1014（clk_50m_d通用布线）仍在，时序PASS表示当前约束下所报告的检查通过，不代表零警告或板上验收。','', '综合网表确认G_PARTIAL.G_VOICE[0]～[31]全部存在，32个Voice保留；没有编译tb_测试台。详见SYNTHESIS_SCOPE.json。引脚逐项403行比较结果见PIN_COMPARISON.json。','', '## 产物','',f'- 工程：`{PROJECT}`',f'- 综合：`{R/"impl/gwsynthesis/yinyue_fashengqi_syn.rpt.html"}`',f'- 时序：`{R/"impl/pnr/yinyue_fashengqi.tr"}`',f'- 布局布线：`{R/"impl/pnr/yinyue_fashengqi.rpt.txt"}`',f'- 新FS：`{b["fs"]}`',f'- SHA256：`{b["sha256"]}`',f'- 本轮完整日志：`{O/"gowin.log"}`',f'- 命令、输入/输出哈希、工具返回值、时序门限：`{A/"BUILD.json"}`',f'- 工程新增条目：`{A/"PROJECT_UPDATE.json"}`',f'- 警告逐项比较：`{A/"WARNING_COMPARISON.json"}`。',f'- 构建前备份：`{A/"backup"}`。','', '上一轮range44及更早BUILD/VALIDATION记录保持历史内容，不把本轮新FS覆盖成旧测试的产物。当前新FS由本轮BUILD.json关联到准确输入。']
    if 'pin_check_correction' in b:notes+=['','包装脚本首次引脚检查把报告生成时间也纳入比较，造成误报；原结果保留在BUILD_FIRST_PIN_HEADER_CHECK.json。已独立逐项比较全部Pin Details单元格，仅排除报告元数据，PIN_COMPARISON.json为PASS。Gowin本体返回0，综合/时序/FS均是同一次新运行的产物，未修改或重跑设计以消除该报告时间戳差异。']
    DOC.write_text('\n'.join(notes)+'\n',encoding='utf8')
    status=f'''# PROJECT_STATUS

工程：`{PROJECT}`。更新时间：{now()}。禁止自动烧录。

最新工程登记与实现：docs/GOWIN_PROJECT_REBUILD_20261018.md；`{A/'BUILD.json'}`。
`.gprj`新增{p['added_count']}个非综合验证/分析/文档条目；生产RTL与原启用源码集合未改。综合、布局布线、setup/hold/recovery/removal/min-pulse时序检查全部PASS；新FS `{b['fs']}`，SHA256 `{b['sha256']}`。引脚与约束保留，未烧录，上板验收PENDING。

44音源功能验证PASS；32音音质验收NOT_ACCEPTED。MIDI64/84响度低谷及87～89极弱尾段退出风险尚未修复，不把实现PASS当音质修复。详见docs/SOUND_SOURCE_44_NOTE_RESULTS.md、docs/SOUND_SOURCE_32KEY_ACCEPTANCE.md。历史44音WAV/测量与RTL哈希仍对应当前未变的音源代码。

32 Voice、FFT、HDMI、PT8211和PCM5102A保留。当前仍是16键逻辑MIDI60～75；两块16键的硬件接入和同时32Voice独立验收，实体最后四键零VOICE/PEAK问题仍待GAO。
'''
    (R/'docs/PROJECT_STATUS.md').write_text(status,encoding='utf8')
    (R/'README.md').write_text(status.replace('# PROJECT_STATUS','# 当前电子钢琴工程',1),encoding='utf8')
    changes=[{'path':q,'before':h,'after':sha(R/q)} for q,h in before['files'].items() if (R/q).exists() and sha(R/q)!=h]
    dump(A/'FILE_CHANGES.json',{'time':now(),'changes':changes,'new_project_references':p['added_files'],'production_rtl_changed':False,'no_auto_programming':True})
    paths=[PROJECT,DOC,R/'docs/PROJECT_STATUS.md',R/'README.md',Path(__file__),*A.glob('*.json'),*O.glob('*.log'),*[R/q for q in b['outputs']]]
    dump(A/'OUTPUT_HASHES.json',{'time':now(),'files':{q.relative_to(R).as_posix():{'sha256':sha(q),'bytes':q.stat().st_size} for q in paths if q.name!='OUTPUT_HASHES.json'}})
    print('Fresh implementation PASS; project entries and all production inputs verified. No programming.',flush=True)

if __name__=='__main__':globals()[sys.argv[1]]()
