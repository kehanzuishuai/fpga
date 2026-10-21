"""Copy the supplied source into this project; never modify E:\\lanya."""
from pathlib import Path
import hashlib,json,shutil
from datetime import datetime,timezone,timedelta
R=Path(__file__).resolve().parents[1]
S=Path(r'E:/lanya');D=R/'ref/lanya_20261019';A=R/'audit/remote_music_20261019'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
A.mkdir(parents=True,exist_ok=True)
assert not (A/'BEFORE.json').exists(),'Preserve existing backup'
files=[p for p in (R/'src').rglob('*') if p.is_file()]
files += list((R/'docs').glob('*.md'))+[R/'README.md',R/'yinyue_fashengqi.gprj',R/'tools/build_gowin.tcl',R/'impl/yinyue_fashengqi_process_config.json']
files += [R/q for q in ['impl/pnr/ao_0.fs','impl/pnr/yinyue_fashengqi.tr','impl/pnr/yinyue_fashengqi.pin.html','impl/pnr/yinyue_fashengqi.rpt.txt','impl/gwsynthesis/yinyue_fashengqi.vg']]
backup={}
for p in files:
 if not p.is_file():continue
 rel=p.relative_to(R);out=A/'backup'/rel;out.parent.mkdir(parents=True,exist_ok=True)
 shutil.copy2(p,out);backup[rel.as_posix()]=sha(p)
(A/'BEFORE.json').write_text(json.dumps({'time':datetime.now(timezone(timedelta(hours=8))).isoformat(),'sha256':backup},indent=2))
manifest={}
for p in S.rglob('*'):
 rel=p.relative_to(S)
 if not p.is_file() or any(n in {'out','node_modules','build','.git','__pycache__'} for n in rel.parts):continue
 if p.suffix.lower() not in {'.sv','.v','.cst','.js','.html','.css','.h','.ino','.py','.md','.yaml','.f','.json'}:continue
 out=D/rel;out.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,out)
 manifest[rel.as_posix()]=sha(p);assert sha(out)==manifest[rel.as_posix()]
(A/'SUPPLIED_SOURCE.json').write_text(json.dumps({'source':str(S),'reference':str(D),'files':manifest,'original_files_modified':False},indent=2))
print('Backed up',len(backup),'current project files; imported',len(manifest),'supplied source files')
