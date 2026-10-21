"""Hash completed deliverables after final report generation, without self-reference."""
from pathlib import Path
import csv,json,sys,shutil
from datetime import datetime
from scale_decay_run import R,A,O,sha,now
v=json.loads((A/'VALIDATION.json').read_text());assert v['digital_validation']=='PASS'
started=datetime.fromisoformat(json.loads((O/'full_regression.json').read_text())['started']).timestamp()
streams={}
for p in (R/'build').iterdir():
    if p.is_file() and p.suffix in ['.txt','.csv','.log'] and p.stat().st_mtime>=started:
        target=O/'regression_streams'/p.name;target.parent.mkdir(exist_ok=True);shutil.copy2(p,target);streams[str(target)]={'source':str(p),'sha256':sha(p)}
manifest=R/'docs/test_manifest_all.txt'
shutil.copy2(manifest,A/'TEST_MANIFEST_ALL.txt')
(O/'REGRESSION_STREAMS.json').write_text(json.dumps({'scope':'Current full regression data preserved before a future run can replace build outputs','files':streams},indent=2),encoding='utf8')
other={}
for folder in [R/'tests/results/keyboard',R/'tests/display/sim_out_visual']:
    for p in folder.rglob('*'):
        if p.is_file() and p.suffix not in ['.vvp','.pyc'] and p.stat().st_mtime>=started:
            target=O/'other_test_outputs'/p.relative_to(R/'tests');target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,target);other[str(target)]={'source':str(p),'sha256':sha(p)}
(O/'OTHER_TEST_OUTPUTS.json').write_text(json.dumps({'files':other},indent=2),encoding='utf8')
files=[p for p in O.rglob('*') if p.is_file() and p.suffix not in ['.vvp','.pyc'] and 'mplconfig' not in p.parts]
files += [p for p in A.glob('*') if p.is_file() and p.name!='OUTPUT_HASHES.json']
files += [R/'docs'/n for n in ['KEY_MAPPING_FIX.md','HIGH_NOTE_DECAY_ANALYSIS.md','VOICE_PEAK_ZERO_ANALYSIS.md','AUDIO_FIX_CHANGELOG.md','AUDIO_TEST_RESULTS.md','BOARD_VALIDATION_GUIDE.md','PROJECT_STATUS.md']]
files += [R/'README.md',R/'docs/test_manifest_all.txt',R/'impl/pnr/ao_0.fs',R/'impl/pnr/yinyue_fashengqi.tr',R/'impl/pnr/yinyue_fashengqi.rpt.txt',R/'impl/pnr/yinyue_fashengqi.pin.html',R/'impl/gwsynthesis/yinyue_fashengqi_syn.rpt.html']
files += list((R/'tools').glob('scale_decay_*.py'))+[R/'src/tang_mega_138k_pro_top.v.v']
index={str(p):{'sha256':sha(p),'bytes':p.stat().st_size} for p in sorted(set(files))}
(A/'OUTPUT_HASHES.json').write_text(json.dumps({'time':now(),'status':'PASS','files':index},indent=2),encoding='utf8')
changes=json.loads((A/'FILE_CHANGES.json').read_text());assert all(sha(x['path'])==x['after_sha256'] for x in changes)
build=v['build'];assert sha(build['fs'])==build['sha256'] and all(sha(p)==h for p,h in build['input_sha256'].items())
print('PASS indexed',len(index),'deliverables; all change/build hashes current; FS',build['sha256'])
