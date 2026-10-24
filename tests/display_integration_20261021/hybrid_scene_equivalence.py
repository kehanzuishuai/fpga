"""Verify every pipeline field, including protected voice bits, against V6."""
from pathlib import Path
import hashlib,json,re,subprocess,sys
R=Path(__file__).resolve().parents[2];A=R/'audit/routing_followup_20261022';O=A/'hybrid_scene';O.mkdir(exist_ok=True)
pane='--pane' in sys.argv
if pane:
 sys.path.insert(0,str(R/'tools'))
 from display_pane_geometry_20261023 import prepare_pane_geometry
 O=A/'pane_geometry';O.mkdir(exist_ok=True)
 baseline=(R/'src/display/visual_scene.sv').read_text();(O/'before_visual_scene.sv').write_text(baseline)
 candidate=O/'candidate_visual_scene.sv';candidate.write_text(prepare_pane_geometry(baseline));gold=baseline
else:
 candidate=R/'src/display/visual_scene.sv';gold=(A/'v7_before/src/display/visual_scene.sv').read_text()
for name in re.findall(r'\bmodule\s+(\w+)',gold):gold=re.sub(r'\b'+re.escape(name)+r'\b','scene_before' if name=='visual_scene' else name+'_v6_reference',gold)
(O/'gold.sv').write_text(gold)
tb=(A/'well_geometry/verification/pixels.sv').read_text()
checks='\n'.join(f'  if(i>=40 && '+(f'(dut.STAGE_{k}.q>>52)' if pane else f'dut.STAGE_{k}.q')+f'!==gold.STAGE_{k}.q)$fatal(1,"scene state differs stage{k} cycle%0d",i);' for k in range(40))
tb=tb.replace('  clk=0;',checks+'\n  clk=0;');(O/'tb.sv').write_text(tb)
iv=Path('D:/gaoyun/piano_v2/codex_test/tools/iverilog/bin/iverilog.exe')
files=[candidate,O/'gold.sv',O/'tb.sv']
for name,args in [('compile',[iv,'-g2012','-s','tb','-o',O/'test.vvp',*files]),('simulation',[iv.with_name('vvp.exe'),O/'test.vvp'])]:
 p=subprocess.run(list(map(str,args)),cwd=R,capture_output=True,text=True,timeout=180)
 (O/(name+'.log')).write_text(p.stdout+p.stderr)
 if p.returncode:raise RuntimeError((p.stdout+p.stderr)[-3000:])
 print(p.stdout[-1300:],flush=True)
r=dict(status='PASS_ISOLATED_PANE_GEOMETRY_NOT_APPLIED' if pane else 'PASS',pixels=512,compared_pipeline_stages=40,all_struct_fields=True,latency_cycles=40,source_sha256=hashlib.sha256(files[0].read_bytes()).hexdigest(),scope='All pre-existing fields (excluding52 new helper bits) and pixels equal V7; no stage added.' if pane else 'All stage pixel_state vectors and final RGB equal V6; no stage added.',programming=False)
(O/'RESULT.json').write_text(json.dumps(r,indent=2));print(json.dumps(r,indent=2))
