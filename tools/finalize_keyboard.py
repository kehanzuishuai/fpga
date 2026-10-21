
from pathlib import Path
import json,csv,re,hashlib,html,xml.etree.ElementTree as E,datetime
R=Path(__file__).resolve().parents[1];B=Path(r'D:\gaoyun\piano_v2_integrated');A=R/'audit/keyboard_v2';O=R/'tests/results/keyboard'
def read(p):return p.read_text(encoding='utf-8-sig',errors='replace')
def load(p):return json.loads(read(p))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
build=load(A/'BUILD_INPUT_HASHES.json');assert build['status']=='PASS'
for rel,h in build['input_sha256'].items():assert sha(R/rel)==h,'Current build input differs: '+rel
for rel,h in load(A/'BUILD_OUTPUT_HASHES.json').items():assert sha(R/rel)==h,'Current build output differs: '+rel
assert re.search(r'\b68 tests, 0 failed\b',read(O/'piano_regression.log')),'full regression not PASS'
for rel in ['keyboard_unit_results.json','keyboard_status_results.json','keyboard_system_results.json','integration/results.json']:
 assert load(O/rel)['status']=='PASS',rel
assert 'ALL DISPLAY-ONLY CHECKS PASS' in read(O/'display_regression.log')
text=read(R/'impl/pnr/yinyue_fashengqi.tr')
assert '<Numbers of Setup Violated Endpoints>:0' in text and '<Numbers of Hold Violated Endpoints>:0' in text
# Core timing count also covers the recovery failure seen in attempt1. Reject any negative recovery/removal slack.
for slack in re.findall(r'^Slack\s*:\s*(-?[\d.]+)',text,re.M):assert float(slack)>=0,'negative timing slack '+slack
baseline=load(A/'BASELINE_MANIFEST.json')['files']
baseline_diffs=[rel for rel,h in baseline.items() if not (B/rel).is_file() or sha(B/rel)!=h]
assert not baseline_diffs,'Read-only integrated baseline changed: '+str(baseline_diffs)
allowed={'src/tang_mega_138k_pro_top.v.v','src/display/audio_visualizer.sv','src/display/piano_status_overlay.sv','src/keyboard_debug.rao'}
protected=[rel for rel in baseline if rel.startswith('src/') and rel not in allowed]
protected_diffs=[rel for rel in protected if sha(R/rel)!=baseline[rel]]
assert not protected_diffs,protected_diffs
inventory=list(csv.DictReader((R/'audit/SOURCE_INVENTORY.csv').open(encoding='utf-8-sig')))
original_diffs=[row['SourcePath'] for row in inventory if not Path(row['SourcePath']).is_file() or sha(Path(row['SourcePath'])).lower()!=row['SHA256'].lower()]
# Do not hide a user-config change as an unchanged original engineering tree.
# Only this inspected Gowin UserConfig metadata file may be classified separately.
metadata_exceptions=[];critical_original_diffs=[]
for name in original_diffs:
 q=Path(name)
 try:
  node=E.fromstring(read(q))
  is_ui=(str(q)==r'D:\gaoyun\piano_v2\yinyue_fashengqi.gprj.user' and node.tag=='UserConfig'
   and {x.tag for x in node}<={'Version','FlowState','ResultFileList','Ui','FpUi'})
 except Exception:is_ui=False
 if is_ui:
  oldhash=next(x['SHA256'] for x in inventory if x['SourcePath']==name)
  created=datetime.datetime.fromisoformat(load(A/'BASELINE_MANIFEST.json')['created_Asia_Shanghai']).timestamp()
  metadata_exceptions.append({'path':name,'previous_inventory_sha256':oldhash,'observed_sha256':sha(q),
   'modified_at_Asia_Shanghai':datetime.datetime.fromtimestamp(q.stat().st_mtime,datetime.timezone(datetime.timedelta(hours=8))).isoformat(),
   'mtime_precedes_work_copy_creation':q.stat().st_mtime<created,
   'scope':'Gowin FlowState/ResultFileList/UI metadata; no origin restored or overwritten; cause not inferred'})
  (A/'ORIGINAL_USER_CONFIG_OBSERVED.xml').write_bytes(q.read_bytes())
 else:critical_original_diffs.append(name)
assert not critical_original_diffs,critical_original_diffs
known={row['SourcePath'].casefold() for row in inventory};added=[]
for root in {row['SourceRoot'] for row in inventory}:
 added.extend(str(p) for p in Path(root).rglob('*') if p.is_file() and str(p).casefold() not in known)
assert not added,'original reference folder files added '+str(added)
assert (R/'src/integrated.cst').read_bytes()==(B/'src/integrated.cst').read_bytes()
assert (R/'src/integrated.sdc').read_bytes()==(B/'src/integrated.sdc').read_bytes()
expected=load(B/'tests/results/PIN_AUDIT.json')['expected'];actual={}
for body in re.findall(r'<tr[^>]*>(.*?)</tr>',read(R/'impl/pnr/yinyue_fashengqi.pin.html'),re.S):
 cells=[html.unescape(re.sub('<[^>]+>','',v)).strip() for v in re.findall(r'<td[^>]*>(.*?)</td>',body,re.S)]
 if cells and cells[0] in expected:actual[cells[0]]=cells[2].split('/')[0]
assert actual==expected,'pin assignment differs'
(A/'PIN_AUDIT.json').write_text(json.dumps({'pass':True,'expected':expected,'actual':actual},indent=2),encoding='utf-8')
required=['KEYBOARD_PROTOCOL_AUDIT.md','KEYBOARD_MODULE_MAP.md','KEYBOARD_MAPPING.md','KEYBOARD_CHANGELOG.md','KEYBOARD_TEST_RESULTS.md','KEYBOARD_WIRING.md','KEYBOARD_GAO_GUIDE.md','KEYBOARD_NEXT_STEPS.md']
for name in required:assert str(R) in read(R/'docs'/name),name
data={'status':'DIGITAL_VALIDATION_PASS','hardware_compatibility':'UNCONFIRMED','project':str(R/'yinyue_fashengqi.gprj'),'implemented_profile':0,'candidate_simulated_profile':1,
'physical_mapping_confirmed':False,'hardware_tested':False,'automatic_programming_performed':False,
'piano_checks':68,'piano_failures':0,'candidate_end_to_end':load(O/'keyboard_system_results.json'),
'original_inventory_files_checked':len(inventory),'integrated_baseline_files_checked':len(baseline),'protected_baseline_src_files':len(protected),
'baseline_differences':baseline_diffs,'protected_differences':protected_diffs,'original_differences':original_diffs,'original_metadata_exceptions':metadata_exceptions,'original_engineering_inputs_unchanged':not critical_original_diffs,'pins_pass':True,
'bitstream':build['bitstream'],'bitstream_sha256':build['bitstream_sha256'],'build_started':build['started_at_Asia_Shanghai'],
'initial_failure_evidence':[str(A/'build_attempt1'),str(A/'system_attempt1')],
'closed_at_Asia_Shanghai':datetime.datetime.now(datetime.timezone(datetime.timedelta(hours=8))).isoformat()}
(A/'FINAL_VALIDATION.json').write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf-8')
rows=[]
for p in sorted(R.rglob('*')):
 if p.is_file() and p!=A/'DELIVERY_MANIFEST.csv':
  rows.append({'path':str(p),'relative':p.relative_to(R).as_posix(),'bytes':p.stat().st_size,'sha256':sha(p)})
with open(A/'DELIVERY_MANIFEST.csv','w',encoding='utf-8-sig',newline='')as f:
 w=csv.DictWriter(f,fieldnames=list(rows[0]));w.writeheader();w.writerows(rows)
print(json.dumps({k:data[k] for k in ['status','hardware_compatibility','piano_checks','piano_failures','original_inventory_files_checked','integrated_baseline_files_checked','protected_baseline_src_files','pins_pass','original_metadata_exceptions','bitstream_sha256']},ensure_ascii=False,indent=2))
print('delivery_files',len(rows))
