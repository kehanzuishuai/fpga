from pathlib import Path
import json,hashlib,sys,re,csv
R=Path(__file__).resolve().parents[1]
def read(p):return p.read_text(encoding='utf-8-sig')
p=R/'docs/test_manifest_all.txt'
if not p.exists() or not re.search(r'\d+ tests, \d+ failed',read(R/'tests/results/piano_final_regression.log')):
 print('PENDING: full piano regression has not finished');sys.exit(2)
section=None;results={}
for line in read(p).splitlines():
 if line.startswith('['):section=line;continue
 if section=='[results]' and line.startswith(('PASS ','FAIL ')):
  status,name=line.split(' ',1);name=name.strip();results[name]={'pass':status=='PASS','evidence':str(R/'tests/results/piano_final_regression.log')}
initial_failures=[n for n,x in results.items() if not x['pass']]
retry=json.loads(read(R/'tests/results/initialization_retest.json'))
assert retry['status']=='PASS','affected retests did not pass'
for check in retry['results']:
 assert check['pass']
 assert check['name'] in results,'unmatched retest '+check['name']
 results[check['name']]={'pass':True,'evidence':str(R/'tests/results/piano_initialization_retest.log')}
remaining=[n for n,x in results.items() if not x['pass']]
assert not remaining,remaining
build=json.loads(read(R/'audit/BUILD_INPUT_HASHES.json'));assert build['status']=='PASS'
for rel,expected in build['input_sha256'].items():
 assert hashlib.sha256((R/rel).read_bytes()).hexdigest()==expected,'build source changed '+rel
for rel,expected in json.loads(read(R/'audit/BUILD_OUTPUT_HASHES.json')).items():
 assert hashlib.sha256((R/rel).read_bytes()).hexdigest()==expected,'build output changed '+rel
integration=json.loads(read(R/'tests/results/integration/results.json'));assert integration['status']=='PASS'
assert json.loads(read(R/'tests/yinse/sim/out/current_results.json'))['status']=='PASS'
assert json.loads(read(R/'tests/results/ORIGINALS_UNCHANGED.json'))['Pass']
assert json.loads(read(R/'tests/results/PIN_AUDIT.json'))['pass']
assert 'ALL DISPLAY-ONLY CHECKS PASS' in read(R/'tests/results/display_final_source.log')
assert 'PASS status HUD' in read(R/'tests/results/status_interfaces.log')
out={'status':'PASS','project':str(R/'yinyue_fashengqi.gprj'),'total_unique_piano_checks':len(results),
'initial_full_run_failures':initial_failures,'affected_retest_count':len(retry['results']),
'remaining_failures':remaining,'note':'Full run and targeted retests are separate actual executions. Initial failing logs are retained, never rewritten as a clean single all-run.',
'checks':results,'hardware_build':build['bitstream'],'bitstream_sha256':build['bitstream_sha256'],
'integration_scope':integration['scope'],'physical_board_tested':False,'automatic_programming_performed':False}
(R/'docs/VALIDATION_SUMMARY.json').write_text(json.dumps(out,ensure_ascii=False,indent=2),encoding='utf-8')
files=[]
for p in sorted(R.rglob('*')):
 if p.is_file() and p.name!='DELIVERY_FILE_MANIFEST.csv':
  rel=p.relative_to(R).as_posix()
  if rel.startswith(('impl/','build/','tests/')):role='构建或验证证据/测试源'
  elif rel.startswith('src/') or p.suffix=='.gprj':role='工程输入/RTL/资源/约束'
  elif rel.startswith('docs/'):role='交付文档'
  elif rel.startswith('audit/'):role='审计/来源/回退证据'
  else:role='开发工具/参考资料'
  files.append({'absolute_path':str(p),'relative_path':rel,'role':role,'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
with open(R/'audit/DELIVERY_FILE_MANIFEST.csv','w',encoding='utf-8-sig',newline='') as f:
 writer=csv.DictWriter(f,fieldnames=list(files[0]));writer.writeheader();writer.writerows(files)
print(json.dumps({k:out[k] for k in ['status','total_unique_piano_checks','affected_retest_count','initial_full_run_failures','bitstream_sha256']},ensure_ascii=False,indent=2))

