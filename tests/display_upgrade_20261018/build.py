"""Fresh production Gowin build with source/output ledger; never programs."""
from pathlib import Path
import sys,subprocess,time,json,re,hashlib
R=Path(__file__).resolve().parents[2];O=Path(__file__).resolve().parent;A=R/'audit/display_upgrade_20261018'
sys.path.insert(0,str(R/'tools'))
from project_rebuild_20261018 import design_inputs,sha,now,enabled
tag=sys.argv[1];before=design_inputs();start=time.time()
record={'status':'RUNNING','started':now(),'input_sha256':before,'enabled_files':enabled(),'no_auto_programming':True}
dest=A/f'BUILD_{tag}.json';dest.write_text(json.dumps(record,indent=2))
with (O/f'gowin_{tag}.log').open('w') as f:
    p=subprocess.run([r'C:/Gowin2/Gowin_V1.9.12_x64/IDE/bin/gw_sh.exe','tools/build_gowin.tcl'],cwd=R,stdout=f,stderr=subprocess.STDOUT)
record.update(returncode=p.returncode,finished=now(),elapsed_s=time.time()-start,inputs_unchanged=before==design_inputs())
paths=['impl/pnr/ao_0.fs','impl/gwsynthesis/yinyue_fashengqi.vg','impl/gwsynthesis/yinyue_fashengqi_syn.rpt.html','impl/pnr/yinyue_fashengqi.tr','impl/pnr/yinyue_fashengqi.rpt.txt','impl/pnr/yinyue_fashengqi.pin.html']
record['outputs']={q:{'sha256':sha(R/q),'bytes':(R/q).stat().st_size,'fresh':(R/q).stat().st_mtime>=start} for q in paths if (R/q).exists()}
text=(R/'impl/pnr/yinyue_fashengqi.tr').read_text(errors='replace')
names={'setup':'3.1.1 Setup Paths Table','hold':'3.1.2 Hold Paths Table','recovery':'3.1.3 Recovery Paths Table','removal':'3.1.4 Removal Paths Table','min_pulse_width':'3.2 Minimum Pulse Width Table'}
record['worst_slack_ns']={k:float(m[1]) if (m:=re.search('^'+re.escape(v)+r'.*?\n\s*1\s+([\d.-]+)',text,re.M|re.S)) else None for k,v in names.items()}
record['violated_endpoints']={k:int(m[1]) if (m:=re.search(r'<Numbers of '+k+r' Violated Endpoints>:(\d+)',text)) else None for k in ['Setup','Hold']}
record['all_timing_checks_pass']=all(v is not None and v>=0 for v in record['worst_slack_ns'].values()) and record['violated_endpoints']=={'Setup':0,'Hold':0}
record['status']='PASS' if p.returncode==0 and record['inputs_unchanged'] and all(m['fresh'] for m in record['outputs'].values()) and record['all_timing_checks_pass'] else 'FAIL'
dest.write_text(json.dumps(record,indent=2));print(json.dumps({k:record[k] for k in ['status','returncode','worst_slack_ns','violated_endpoints']},indent=2),flush=True)
sys.exit(record['status']!='PASS')
