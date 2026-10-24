"""Restore verified V13 build outputs to its GUI project's default paths.

Never invokes the programmer or changes source files. Existing outputs/settings
are archived before replacement. The frozen successful run remains untouched.
"""
from pathlib import Path
import datetime,hashlib,json,shutil,xml.etree.ElementTree as ET

R=Path(__file__).resolve().parents[1]
B=(R/'branches/v13_20261024').resolve()
D=B/'audit/autonomous_timing_20261022_154006/runs/v13_p3_r0'
r=json.loads((D/'RESULT.json').read_text(encoding='utf-8-sig'))
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
assert r['status']=='PASS' and r['complete_implementation'] and r['inputs_unchanged']
assert r['returncode']==0 and not r['errors']
assert r['violated_endpoints']=={'Setup':0,'Hold':0}
assert len(r['worst_slack_ns'])==5 and all(v is not None and v>=0 for v in r['worst_slack_ns'].values())
source_names=[n for n in r['inputs'] if n.startswith(('src/','assets/')) or n=='yinyue_fashengqi.gprj']
for n in source_names:assert sha(B/n)==sha(D/n)==r['inputs'][n],('Input mismatch',n)
assert sha(D/'impl/gwsynthesis/yinyue_fashengqi.vg')==r['final_netlist_sha256']
for n,record in r['artifacts'].items():
 assert record['fresh'] and sha(D/'impl/pnr'/n)==record['sha256'],('Artifact mismatch',n)
assert r['artifacts']['ao_0.fs']['sha256']=='bec2b041c230e20e19b0252a7d61dce7b9a9eed0a92b03fee85701e476be1377'

stamp=datetime.datetime.now().strftime('%Y%m%d_%H%M%S')
backup=(B/'audit'/('gui_outputs_before_sync_'+stamp)).resolve()
assert B.is_relative_to(R.resolve()) and backup.is_relative_to(B)
backup.mkdir()
for n in ['yinyue_fashengqi.gprj.user','impl/yinyue_fashengqi_process_config.json']:
 p=B/n
 if p.exists():q=backup/n;q.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,q)

moved=[]
try:
 for n in ['impl/gwsynthesis','impl/pnr']:
  p=(B/n).resolve();q=(backup/n).resolve()
  assert p.is_relative_to(B) and q.is_relative_to(backup) and p!=B
  if p.exists():q.parent.mkdir(parents=True,exist_ok=True);shutil.move(str(p),str(q))
  moved.append(n);shutil.copytree(D/n,p)
 for n in ['impl/gwsynthesis','impl/pnr']:
  for p in (D/n).rglob('*'):
   if p.is_file():assert sha(p)==sha(B/p.relative_to(D)),('Copy mismatch',p)
 # Preserve the currently open GUI's layout, while importing the actual
 # completed flow states and relative result paths from the successful run.
 user=B/'yinyue_fashengqi.gprj.user'
 current=ET.parse(user).getroot();root=ET.parse(D/'yinyue_fashengqi.gprj.user').getroot()
 # Keep the vendor's canonical child order as well as the completed states.
 for name in ['Ui','FpUi']:
  old=current.find(name);target=root.find(name)
  if old is not None and target is not None:target.text=old.text
 for e in root.findall('./ResultFileList/ResultFile'):
  assert (B/e.get('ResultFilePath')).is_file(),e.attrib
 user.write_bytes(b'<?xml version="1.0" encoding="UTF-8"?>\n<!DOCTYPE ProjectUserData>\n'+ET.tostring(root,encoding='utf-8'))
 shutil.copy2(D/'impl/yinyue_fashengqi_process_config.json',B/'impl/yinyue_fashengqi_process_config.json')
 for n in source_names:assert sha(B/n)==r['inputs'][n],('Source changed during sync',n)
except Exception:
 for n in reversed(moved):
  p=(B/n).resolve();q=(backup/n).resolve();failed=(backup/'partial_copy'/n).resolve()
  assert p.is_relative_to(B) and q.is_relative_to(backup) and failed.is_relative_to(backup)
  if p.exists():failed.parent.mkdir(parents=True,exist_ok=True);shutil.move(str(p),str(failed))
  if q.exists():shutil.move(str(q),str(p))
 for n in ['yinyue_fashengqi.gprj.user','impl/yinyue_fashengqi_process_config.json']:
  if (backup/n).exists():shutil.copy2(backup/n,B/n)
 raise

result=dict(status='VERIFIED_V13_OUTPUTS_SYNCHRONIZED_FOR_GUI',branch=str(B),source_run=str(D),backup=str(backup),
 source_inputs_checked=len(source_names),source_unchanged=True,project_xml_unchanged=True,
 bitstream=str(B/'impl/pnr/ao_0.fs'),bitstream_sha256=sha(B/'impl/pnr/ao_0.fs'),
 worst_slack_ns=r['worst_slack_ns'],violated_endpoints=r['violated_endpoints'],programming=False,
 note='Reload the project in Gowin to refresh its cached flow state. No synthesis, PnR or FPGA programming was run.')
(B/'audit/GUI_OUTPUT_SYNC_20261024.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
with (B/'README.md').open('a',encoding='utf-8') as f:
 f.write('\n\nGUI输出同步（'+stamp+'）：已核对当前源码/资源/工程文件与v13_p3_r0的141项输入一致，将该次通过构建的完整gwsynthesis、pnr及设置同步到本分支impl。烧录文件现在也位于impl/pnr/ao_0.fs，SHA256前缀BEC2B041C230E20E。旧输出和GUI设置保存在audit/gui_outputs_before_sync_*；源码和GPRJ清单未改，未重新构建、未烧录。高云若仍缓存旧状态，请关闭并重新打开本分支工程。\n')
print(json.dumps(result,indent=2))
