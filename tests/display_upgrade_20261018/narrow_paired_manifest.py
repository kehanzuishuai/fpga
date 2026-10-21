"""Retain the completed test; explicitly hash only sources actually compiled.

Physical clock wrappers are replaced by the documented simulation stub.
They are validated separately with primitive simulation and full P&R.
"""
from pathlib import Path
import json,hashlib,sys
R=Path(__file__).resolve().parents[2];O=Path(__file__).resolve().parent
sys.path.insert(0,str(R/'tools'))
from continue_audio_audit import sources
p=O/'PAIRED.json';v=json.loads(p.read_text());assert v['status']=='PASS'
assert all(hashlib.sha256((R/q).read_bytes()).hexdigest()==h for q,h in v['input_sha256'].items())
backup=O/'PAIRED_before_pixel_global.json';assert not backup.exists();backup.write_bytes(p.read_bytes())
compiled={q.relative_to(R).as_posix() for q in sources()}
old={Path(q).as_posix():h for q,h in v['input_sha256'].items()}
v['input_sha256']={q:old[q] for q in sorted(compiled)}
v['replaced_physical_sources_not_compiled']=['visual_video_clock.v','visual_dvi_io.v','visual_pll_mod.v','pll_init.v','audio_pll.v','audio_pll_mod.v']
aux=['baseline_board.v','video_boundary_stub.v','tb_integrated_system_120ms.sv']
v['test_fixture_sha256']={str((O/q).relative_to(R)):hashlib.sha256((O/q).read_bytes()).hexdigest() for q in aux}
v['manifest_note']='Completed120ms simulation retained. Original full-source manifest preserved; compiled source set refined before physical-clock-only edits. All compiled RTL unchanged, physical boundary replaced by stub and verified separately.'
p.write_text(json.dumps(v,indent=2));print('PASS completed paired test,',len(compiled),'actual production compile inputs hashed.')
