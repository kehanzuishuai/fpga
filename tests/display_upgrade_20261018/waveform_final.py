"""Preserve the PLL's non-50% reset clock duty through its DCS constraint.

Run only after a completed timing-clean full build. Synthesis is reused
only with identical RTL/project/options and exact original netlist hashes.
The physical implementation and timing reports are regenerated.
"""
from pathlib import Path
import json,subprocess,time,re,sys,shutil
R=Path(__file__).resolve().parents[2];O=Path(__file__).resolve().parent;A=R/'audit/display_upgrade_20261018'
sys.path.insert(0,str(R/'tools'))
from project_rebuild_20261018 import design_inputs,sha,now,enabled
parent=json.loads((A/'BUILD_pixel_global_final.json').read_text());assert parent['status']=='PASS'
assert parent['input_sha256']==design_inputs()
assert all(sha(R/q)==v['sha256'] for q,v in parent['outputs'].items())
sdc=R/'src/integrated.sdc';old=sdc.read_text()
line='create_generated_clock -name video_serial_reset_global -source [get_pins {u_video_clock/video_pll/PLL_inst/CLKOUT2}] -divide_by 1 [get_pins {u_video_io/reset_buffer/CLKOUT}]'
assert old.count(line)==1
backup=A/'before_waveform_constraint';backup.mkdir(exist_ok=True)
shutil.copy2(sdc,backup/'integrated.sdc')
sdc.write_text(old.replace(line,line.replace('-divide_by 1','-edges {1 2 3}')))
before=design_inputs();assert {q for q,h in before.items() if parent['input_sha256'][q]!=h}=={'src/integrated.sdc'}
place=R/'impl/pnr/yinyue_fashengqi.p';assert place.exists()
shutil.copy2(place,backup/place.name)
tcl=O/'waveform_final.tcl'
tcl.write_text('cd {'+R.as_posix()+'}\nopen_project {'+(R/'yinyue_fashengqi.gprj').as_posix()+'}\nset_option -inc_pnr {'+(backup/place.name).as_posix()+'}\nset_option -gen_text_timing_rpt 1\nrun pnr\n')
start=time.time();record={'status':'RUNNING','started':now(),'input_sha256':before,'enabled_files':enabled(),'no_auto_programming':True,'flow':'Full synthesis+P&R in BUILD_pixel_global_final, then exact-RTL matched synthesis reuse and incremental physical reimplementation for corrected DCS duty waveform','synthesis_parent':'BUILD_pixel_global_final.json','placement_seed_sha256':sha(backup/place.name)}
dest=A/'BUILD_waveform_final.json';dest.write_text(json.dumps(record,indent=2))
with (O/'gowin_waveform_final.log').open('w') as f:p=subprocess.run([r'C:/Gowin2/Gowin_V1.9.12_x64/IDE/bin/gw_sh.exe',str(tcl)],cwd=R,stdout=f,stderr=subprocess.STDOUT)
record.update(returncode=p.returncode,finished=now(),elapsed_s=time.time()-start,inputs_unchanged=before==design_inputs())
record['outputs']={}
for q in parent['outputs']:
 meta={'sha256':sha(R/q),'bytes':(R/q).stat().st_size,'fresh':(R/q).stat().st_mtime>=start}
 if q.startswith('impl/gwsynthesis/'):
  meta['authenticated_synthesis_reuse']=meta['sha256']==parent['outputs'][q]['sha256']
 record['outputs'][q]=meta
tr=(R/'impl/pnr/yinyue_fashengqi.tr').read_text()
names={'setup':'3.1.1 Setup Paths Table','hold':'3.1.2 Hold Paths Table','recovery':'3.1.3 Recovery Paths Table','removal':'3.1.4 Removal Paths Table','min_pulse_width':'3.2 Minimum Pulse Width Table'}
record['worst_slack_ns']={k:float(m[1]) if (m:=re.search('^'+re.escape(v)+r'.*?\n\s*1\s+([\d.-]+)',tr,re.M|re.S)) else None for k,v in names.items()}
record['violated_endpoints']={k:int(re.search(r'<Numbers of '+k+r' Violated Endpoints>:(\d+)',tr)[1]) for k in ['Setup','Hold']}
record['all_timing_checks_pass']=all(v is not None and v>=0 for v in record['worst_slack_ns'].values()) and record['violated_endpoints']=={'Setup':0,'Hold':0}
record['status']='PASS' if p.returncode==0 and record['inputs_unchanged'] and record['all_timing_checks_pass'] and all(v['fresh'] or v.get('authenticated_synthesis_reuse',False) for v in record['outputs'].values()) else 'FAIL'
dest.write_text(json.dumps(record,indent=2));print(json.dumps({k:record[k] for k in ['status','returncode','worst_slack_ns','violated_endpoints']},indent=2),flush=True)
sys.exit(record['status']!='PASS')
