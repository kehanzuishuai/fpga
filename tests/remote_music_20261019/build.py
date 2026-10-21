"""Full Gowin synthesis, place/route and five timing checks; never flashes."""
from pathlib import Path
import subprocess,hashlib,json,time,datetime,re,shutil
R=Path(__file__).resolve().parents[2];A=R/'audit/remote_music_20261019';O=R/'tests/remote_music_20261019/out'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def inputs():
 return {p.relative_to(R).as_posix():sha(p) for p in [*sorted((R/'src').rglob('*')),R/'yinyue_fashengqi.gprj',R/'tools/build_gowin.tcl'] if p.is_file()}
def now():return datetime.datetime.now(datetime.timezone.utc).isoformat()
A.mkdir(exist_ok=True);O.mkdir(exist_ok=True)
dest=A/'BUILD.json';attempt=1
while (A/f'BUILD_attempt{attempt}.json').exists():attempt+=1
if dest.exists():
 shutil.copy2(dest,A/f'BUILD_attempt{attempt}.json')
 if (O/'gowin.log').exists():shutil.copy2(O/'gowin.log',O/f'gowin_attempt{attempt}.log')
start=time.time();before=inputs()
record={'status':'RUNNING','started':now(),'input_sha256':before,'no_auto_programming':True,'project':str(R/'yinyue_fashengqi.gprj')}
dest.write_text(json.dumps(record,indent=2))
print('Full Gowin build started',flush=True)
with (O/'gowin.log').open('w',encoding='utf-8') as f:
 p=subprocess.run(['C:/Gowin2/Gowin_V1.9.12_x64/IDE/bin/gw_sh.exe','tools/build_gowin.tcl'],cwd=R,stdout=f,stderr=subprocess.STDOUT)
record.update(returncode=p.returncode,finished=now(),elapsed_s=time.time()-start,inputs_unchanged=before==inputs())
paths=['impl/pnr/ao_0.fs','impl/gwsynthesis/yinyue_fashengqi.vg','impl/gwsynthesis/yinyue_fashengqi_syn.rpt.html','impl/pnr/yinyue_fashengqi.tr','impl/pnr/yinyue_fashengqi.rpt.txt','impl/pnr/yinyue_fashengqi.pin.html']
record['outputs']={q:{'sha256':sha(R/q),'bytes':(R/q).stat().st_size,'fresh':(R/q).stat().st_mtime>=start-2} for q in paths if (R/q).exists()}
text=(R/'impl/pnr/yinyue_fashengqi.tr').read_text(errors='replace')
names={'setup':'3.1.1 Setup Paths Table','hold':'3.1.2 Hold Paths Table','recovery':'3.1.3 Recovery Paths Table','removal':'3.1.4 Removal Paths Table','min_pulse_width':'3.2 Minimum Pulse Width Table'}
record['worst_slack_ns']={k:float(m[1]) if (m:=re.search('^'+re.escape(v)+r'.*?\n\s*1\s+([\d.-]+)',text,re.M|re.S)) else None for k,v in names.items()}
record['violated_endpoints']={k:int(m[1]) if (m:=re.search(r'<Numbers of '+k+r' Violated Endpoints>:(\d+)',text)) else None for k in ['Setup','Hold']}
timing_fresh=record['outputs'].get('impl/pnr/yinyue_fashengqi.tr',{}).get('fresh',False)
if not timing_fresh:
 record['stale_previous_timing_values']={'slacks':record['worst_slack_ns'],'violated_endpoints':record['violated_endpoints']}
 record['worst_slack_ns']={k:None for k in names};record['violated_endpoints']={'Setup':None,'Hold':None}
record['all_timing_checks_pass']=timing_fresh and all(v is not None and v>=0 for v in record['worst_slack_ns'].values()) and record['violated_endpoints']=={'Setup':0,'Hold':0}
record['status']='PASS' if p.returncode==0 and record['inputs_unchanged'] and len(record['outputs'])==len(paths) and all(m['fresh'] for m in record['outputs'].values()) and record['all_timing_checks_pass'] else 'FAIL'
dest.write_text(json.dumps(record,indent=2))
print(json.dumps({k:record[k] for k in ['status','returncode','worst_slack_ns','violated_endpoints']},indent=2),flush=True)
if record['status']!='PASS':raise SystemExit(1)
