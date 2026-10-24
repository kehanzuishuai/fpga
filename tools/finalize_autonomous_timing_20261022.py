"""Promote one finished, source-verified attempt; preserve every prior root output."""
from pathlib import Path
import argparse,datetime,hashlib,json,re,shutil,xml.etree.ElementTree as ET

R=Path(__file__).resolve().parents[1];A=R/'audit/autonomous_timing_20261022_154006'
p=argparse.ArgumentParser();p.add_argument('tag');o=p.parse_args()
assert re.fullmatch('[a-z0-9_]+',o.tag)
D=A/'runs'/o.tag;r=json.loads((D/'RESULT.json').read_text())
assert r['status']!='RUNNING','Finish or explicitly stop the candidate first'
def sha(p):
 h=hashlib.sha256()
 with p.open('rb') as f:
  for block in iter(lambda:f.read(1024*1024),b''):h.update(block)
 return h.hexdigest()
for n,v in r['inputs'].items():
 if n!='impl/gwsynthesis/yinyue_fashengqi.vg':assert sha(D/n)==v,n
assert 'GowinSynthesis finish' in (D/'console.log').read_text(errors='replace') or r.get('synthesis_reuse')
net=D/'impl/gwsynthesis/yinyue_fashengqi.vg'
assert net.is_file() and (D/'impl/gwsynthesis/yinyue_fashengqi_syn.rpt.html').is_file()
if r['status']=='PASS':
 check=json.loads((D/'STA_INSPECTION.json').read_text())
 assert check['status']=='PASS_REPORT_PROVENANCE_AND_CLOCKS'
 assert check['report_sha256']==sha(D/'impl/pnr/yinyue_fashengqi.tr')
 assert all(v is not None and v>=0 for v in r['worst_slack_ns'].values())
 assert r['violated_endpoints']=={'Setup':0,'Hold':0}
# Root is allowed to contain only our latest frozen source, not unrelated edits.
latest=json.loads((A/'runs/pll_compact_p3_r0_inc/RESULT.json').read_text())
for n,v in latest['inputs'].items():
 if n.startswith(('src/','assets/')) or n=='yinyue_fashengqi.gprj':assert sha(R/n)==v,('Root edited externally',n)
B=A/('root_before_promote_'+o.tag);B.mkdir(exist_ok=False)
for n in ['src','assets']:shutil.copytree(R/n,B/n)
for n in ['yinyue_fashengqi.gprj','yinyue_fashengqi.gprj.user','README.md']:
 if (R/n).exists():shutil.copy2(R/n,B/n)
# Verify absolute move boundaries before moving directories on Windows.
if (R/'impl/yinyue_fashengqi_process_config.json').exists():
 shutil.copy2(R/'impl/yinyue_fashengqi_process_config.json',B/'process_config.before.json')
moved=[]
try:
 for n in ['impl/gwsynthesis','impl/pnr']:
  source=(R/n).resolve();dest=(B/n).resolve()
  assert source.is_relative_to(R.resolve()) and dest.is_relative_to(B.resolve())
  assert source==R/n and not dest.exists()
  dest.parent.mkdir(parents=True,exist_ok=True)
  if source.exists():shutil.move(str(source),str(dest))
  moved.append(n)
  shutil.copytree(D/n,R/n)
except Exception:
 # Restore original implementation trees without deleting partial new copies.
 for n in reversed(moved):
  source=(R/n).resolve();original=(B/n).resolve();partial=(B/'partial_copy'/n).resolve()
  assert source.is_relative_to(R.resolve()) and original.is_relative_to(B.resolve()) and partial.is_relative_to(B.resolve())
  if source.exists():
   partial.parent.mkdir(parents=True,exist_ok=True);shutil.move(str(source),str(partial))
  if original.exists():shutil.move(str(original),str(source))
 raise
for n in ['src','assets']:shutil.copytree(D/n,R/n,dirs_exist_ok=True)
shutil.copy2(D/'yinyue_fashengqi.gprj',R/'yinyue_fashengqi.gprj')
if (D/'yinyue_fashengqi.gprj.user').exists():
 shutil.copy2(D/'yinyue_fashengqi.gprj.user',R/'yinyue_fashengqi.gprj.user')
cfg=D/'impl/yinyue_fashengqi_process_config.json'
if cfg.exists():shutil.copy2(cfg,R/'impl/yinyue_fashengqi_process_config.json')
opts=r['options'];cp=R/'impl/yinyue_fashengqi_process_config.json';c=json.loads(cp.read_text())
c.update(Place_Option=str(opts['place']),Route_Option=str(opts['route']),Clock_Route_Order=opts['clock_order'],
 Run_Timing_Driven=bool(opts.get('timing_driven',1)),Correct_Hold_Violation=bool(opts.get('correct_hold',1)),
 Convert_SDP32_36_to_SDP16_18=False,Generate_Plain_Text_Timing_Report=True)
cp.write_text(json.dumps(c,indent=2))
enabled=[e.get('path') for e in ET.parse(R/'yinyue_fashengqi.gprj').findall('./FileList/File') if e.get('enable')=='1']
assert all(sha(R/n)==sha(D/n) for n in enabled)
assert sha(R/'impl/gwsynthesis/yinyue_fashengqi.vg')==sha(net)
pnr={}
for f in (R/'impl/pnr').iterdir():
 if f.is_file():
  assert sha(f)==sha(D/'impl/pnr'/f.name),f.name
  pnr[f.name]=sha(f)
now=datetime.datetime.now(datetime.timezone.utc)
session=json.loads((A/'SESSION.json').read_text());sleep=json.loads((A/'SYSTEM_SLEEP.json').read_text())
active=(now-datetime.datetime.fromisoformat(session['started_utc'])).total_seconds()-sleep['excluded_sleep_seconds']
status='TIMING_PASS_NOT_PROGRAMMED' if r['status']=='PASS' else 'NOT_TIMING_CLOSED_NOT_PROGRAMMED'
assert sha(R/'release/latest/ao_0.fs')=='e483552fc9993df6e9464790a9ca29d7e8253e02a51002507d05ee2234884e0b'
final=dict(status=status,selected=o.tag,finished_utc=now.isoformat(),active_minutes_excluding_system_sleep=active/60,
 scope='Root source, synthesis netlist and PnR outputs all copied from the same verified attempt. Historic FS/STA moved to backup, never reused as current proof. No programming.',
 source_sha256={n:sha(R/n) for n in enabled},netlist_sha256=sha(net),pnr_sha256=pnr,
 worst_slack_ns=r['worst_slack_ns'],violated_endpoints=r['violated_endpoints'],
 options=opts,attempt_status=r['status'],errors=r['errors'],backup=str(B),
 old_release_unchanged_sha256=sha(R/'release/latest/ao_0.fs'))
(A/'FINAL.json').write_text(json.dumps(final,indent=2))
current=R/'audit/display_integration_20261021/CURRENT.json'
if current.exists():shutil.copy2(current,B/'CURRENT.before.json')
current.write_text(json.dumps(dict(status=status,receipt='audit/autonomous_timing_20261022_154006/FINAL.json',
 note='This pointer supersedes the historical manual-implementation status; old receipt preserved in promotion backup.'),indent=2))
rows=[]
for f in sorted((A/'runs').glob('*/RESULT.json')):
 j=json.loads(f.read_text());rows.append('| '+f.parent.name+' | '+j['status']+' | '+('; '.join(j.get('errors',[])) or '—')+' |')
report=f'''# 2026-10-22自主时序迭代记录

当前结论：**{status}**。主工程仍为`D:\\gaoyun\\piano_v2_audio_fix\\yinyue_fashengqi.gprj`，本轮未烧录。

主目录采用候选：`{o.tag}`。源码、综合网表、实现报告已对应；原主目录的旧网表、旧FS和旧STA均保存在`{B.relative_to(R).as_posix()}`。`release/latest`仍为10月20日旧基线，不代表新显示工程。

本轮实际可运行时间约{active/60:.1f}分钟；系统多次现代待机累计{sleep['excluded_sleep_seconds']/60:.1f}分钟不计入计算窗口，见`audit/autonomous_timing_20261022_154006/SYSTEM_SLEEP.json`。

## 实际实现结果

| 候选 | 结果 | 工具错误 |
|---|---|---|
'''+ '\n'.join(rows)+f'''

最终候选五类STA裕量(ns)：`{json.dumps(r['worst_slack_ns'])}`；Setup/Hold违例端点：`{json.dumps(r['violated_endpoints'])}`。空表表示未取得本候选STA，绝不表示0违例。PR0004即使显示0条未布通也仍是实现失败。

完整输入、网表与产物SHA256见`audit/autonomous_timing_20261022_154006/FINAL.json`。原始日志、Tcl和报告保留在各候选`runs/`目录。诊断版若关闭自动时序优化/Hold修补，SDC及五类STA验收仍保持，不能把关闭修补当作通过。

## 功能与专项验证

- 保留32 Voice实体钢琴、FFT、HDMI、双DAC、ESP32接口和既有UI；未改音源、声部分配、ROM、按键事件与音色算法。
- PLL输入旁路真实原语1000周期及整板展开通过；只改旁路选择和内部端口，不改音频PLL输出0的分频、相位与VCO设置。
- 文字减负候选先选当前标签音高，仍为21拍；原90区域、2912动态像素/字符及全部65536个BCD输入等价检查通过。综合SSRAM445→390，逻辑减少330，寄存器增加224。但该候选实际仍有595条未布通，本轮未采用到最终主目录；完整源码及验证证据保留在`runs/pll_compact_p3_r0_inc/`。它只改显示数据，没有改32 Voice音频路径。
- PLL基础版键盘至双DAC专项通过，单键数字链路约4.7ms；32键齐按最后声部约10.97ms。触摸模块内部检测、模拟DAC及扬声器延迟不在该数字仿真内。
- 手机网页SHA256保持`3969c34b4d279eae7e16e1066441730b026b021e04ecf8e4ed52bece4bc719c1`。文字音高选择只影响当前像素的标签数据，不减少同时发声或显示的键数。

## 继续工作

先阅读本文件和FINAL.json，再核对本候选新的实现结果。只有布线完成、最新STA五类裕量非负且Setup/Hold端点为0，并核对所有时钟定义，才能称为新工程通过。若尚未闭合，应继续定位PR0004、时钟分配及高密度布局；本轮不以小工程通过替代整机结果。

最后的低占用诊断工程保留三组真实PLL、HDMI串行器、相同相关管脚及reset/DCS位置约束，完成了实现并生成自己的STA/FS；不包含完整音源、显示逻辑或GAO，不能作为整机通过证据。说明基本时钟拓扑在低负载时可以实现，但尚不能区分整机密度、GAO或其他资源交互的影响。另外，保持SDC、关闭自动Timing Driven/Hold修补的整机诊断版仍报PR0004且计数0，未定位出该错误的确定根因。
'''
(R/'docs/AUTONOMOUS_TIMING_20261022.md').write_text(report,encoding='utf-8')
readme=R/'README.md';text=readme.read_text(encoding='utf-8');a=text.index('> 2026-10-22本轮进行中：');z=text.index('\n\n',a)
message=('本轮新工程已完成布局布线及五类STA，未烧录。' if r['status']=='PASS' else '本轮新工程尚未通过完整实现与STA，未烧录。')
text=text[:a]+f'> 2026-10-22本轮结论：{message}当前采用`{o.tag}`，源码/网表/实现报告已对应；原主目录旧产物另行归档，release/latest仍为10月20日旧基线。详见[本轮实际结果](docs/AUTONOMOUS_TIMING_20261022.md)及`audit/autonomous_timing_20261022_154006/FINAL.json`。'+text[z:]
text=text.replace('> 2026-10-22 14:33用户重新手动实现','> 历史记录（已被上述本轮结论取代）：2026-10-22 14:33用户重新手动实现')
readme.write_text(text,encoding='utf-8')
print(json.dumps({k:final[k] for k in ['status','selected','active_minutes_excluding_system_sleep','worst_slack_ns','violated_endpoints','backup']},indent=2),flush=True)
