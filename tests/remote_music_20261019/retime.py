"""Reroute unchanged RTL/netlist, preserving the full synthesis provenance."""
from pathlib import Path
import hashlib,json,shutil,time,datetime,subprocess,re,argparse
R=Path(__file__).resolve().parents[2];A=R/'audit/remote_music_20261019';O=R/'tests/remote_music_20261019/out'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def now():return datetime.datetime.now(datetime.timezone.utc).isoformat()
args=argparse.ArgumentParser()
args.add_argument('--archive',required=True)
args.add_argument('--place',type=int,choices=range(5),required=True)
args.add_argument('--route',type=int,choices=range(3),required=True)
opts=args.parse_args()
assert re.fullmatch(r'[a-z0-9_]+',opts.archive)
b=json.loads((A/'BUILD.json').read_text());assert b['inputs_unchanged']
assert all(sha(R/q)==h for q,h in b['input_sha256'].items())
assert b['outputs']['impl/gwsynthesis/yinyue_fashengqi.vg']['sha256']==sha(R/'impl/gwsynthesis/yinyue_fashengqi.vg')
dest=A/opts.archive;dest.mkdir(exist_ok=False)
shutil.copy2(A/'BUILD.json',dest/'BUILD.json')
for q in b['outputs']:shutil.copy2(R/q,dest/Path(q).name)
shutil.copy2(O/'gowin.log',dest/'gowin.log')
if (O/'retime.log').exists():shutil.copy2(O/'retime.log',dest/'previous_retime.log')
shutil.copy2(R/'tools/remote_retime.tcl',dest/'remote_retime.tcl')
shutil.copy2(A/'BUILD_OPTIONS.json',dest/'BUILD_OPTIONS.json')
config=R/'impl/yinyue_fashengqi_process_config.json'
previous_config=json.loads(config.read_text())
shutil.copy2(config,dest/config.name)
# Change only implementation algorithms after verifying and archiving every
# previous input. The already tested RTL, constraints and netlist stay intact.
tcl=(R/'tools/remote_retime.tcl').read_text()
for name,value in [('place_option',opts.place),('route_option',opts.route)]:
 tcl,count=re.subn(r'(?m)^set_option -'+name+r' \d+$',f'set_option -{name} {value}',tcl)
 assert count==1,name
(R/'tools/remote_retime.tcl').write_text(tcl)
b['synthesis_provenance']={'receipt':str(dest/'BUILD.json'),'netlist_sha256':b['outputs']['impl/gwsynthesis/yinyue_fashengqi.vg']['sha256'],'synthesis_inputs_unchanged':True}
b['flow']='Unchanged synthesis followed by PnR-only timing repair'
b['pnr_options']={'place_option':opts.place,'route_option':opts.route,'timing_driven':1,'correct_hold_violation':1}
b['input_sha256']['tools/remote_retime.tcl']=sha(R/'tools/remote_retime.tcl')
for key in ['returncode','finished','reroute_elapsed_s','stop_reason','stopped_utc']:
 b.pop(key,None)
for q,m in b['outputs'].items():
 if q.startswith('impl/pnr/'):m['fresh']=False
b['worst_slack_ns']={k:None for k in b['worst_slack_ns']}
b['violated_endpoints']={'Setup':None,'Hold':None}
b.update(status='RUNNING',reroute_started=now(),automatic_jobs_running=True,
 implementation_status='PnR-only run in progress; no fresh accepted FS or timing report',
 all_timing_checks_pass=False)
(A/'BUILD.json').write_text(json.dumps(b,indent=2))
print(f'PnR-only started: placement {opts.place}, route {opts.route}; no programming',flush=True)
began=time.time()
with (O/'retime.log').open('w') as f:
 p=subprocess.run(['C:/Gowin2/Gowin_V1.9.12_x64/IDE/bin/gw_sh.exe','tools/remote_retime.tcl'],cwd=R,stdout=f,stderr=subprocess.STDOUT)
b.update(returncode=p.returncode,finished=now(),reroute_elapsed_s=time.time()-began,automatic_jobs_running=False)
options=json.loads((A/'BUILD_OPTIONS.json').read_text())
options.update(sha256=sha(config),options=json.loads(config.read_text()))
options['changes_from_previous_attempt']={k:{'before':previous_config.get(k),'after':options['options'].get(k)}
 for k in ['Place_Option','Route_Option'] if previous_config.get(k)!=options['options'].get(k)}
options['reason']='Explicit user request to resume completion; reuse verified synthesis, change only PnR algorithms after prior router failures/stalls. RTL, clocks, SDC and UI unchanged.'
(A/'BUILD_OPTIONS.json').write_text(json.dumps(options,indent=2))
shutil.copy2(O/'retime.log',dest/'reroute.log')
(O/'gowin.log').write_text((dest/'gowin.log').read_text(errors='replace')+'\n--- PnR-only timing repair ---\n'+(O/'retime.log').read_text(errors='replace'))
pnr_paths=[q for q in b['outputs'] if q.startswith('impl/pnr/')]
for q in pnr_paths:b['outputs'][q]={'sha256':sha(R/q),'bytes':(R/q).stat().st_size,'fresh':(R/q).stat().st_mtime>=began-2}
b['inputs_unchanged']=all(sha(R/q)==h for q,h in b['input_sha256'].items())
assert sha(R/'impl/gwsynthesis/yinyue_fashengqi.vg')==b['synthesis_provenance']['netlist_sha256']
t=(R/'impl/pnr/yinyue_fashengqi.tr').read_text(errors='replace')
names={'setup':'3.1.1 Setup Paths Table','hold':'3.1.2 Hold Paths Table','recovery':'3.1.3 Recovery Paths Table','removal':'3.1.4 Removal Paths Table','min_pulse_width':'3.2 Minimum Pulse Width Table'}
fresh=all(b['outputs'][q]['fresh'] for q in pnr_paths)
b['worst_slack_ns']={k:float(m[1]) if fresh and (m:=re.search('^'+re.escape(v)+r'.*?\n\s*1\s+([\d.-]+)',t,re.M|re.S)) else None for k,v in names.items()}
b['violated_endpoints']={k:int(m[1]) if fresh and (m:=re.search(r'<Numbers of '+k+r' Violated Endpoints>:(\d+)',t)) else None for k in ['Setup','Hold']}
b['all_timing_checks_pass']=fresh and all(v is not None and v>=0 for v in b['worst_slack_ns'].values()) and b['violated_endpoints']=={'Setup':0,'Hold':0}
b['status']='PASS' if p.returncode==0 and b['inputs_unchanged'] and b['all_timing_checks_pass'] else 'FAIL'
b['implementation_status']='Fresh routed implementation and all five timing checks passed' if b['status']=='PASS' else 'Implementation or timing failed; do not use FS as an accepted build'
(A/'BUILD.json').write_text(json.dumps(b,indent=2));print(json.dumps({k:b[k] for k in ['status','worst_slack_ns','violated_endpoints']},indent=2))
if b['status']!='PASS':raise SystemExit(1)
