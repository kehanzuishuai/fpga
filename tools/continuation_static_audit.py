from pathlib import Path
import json,re,xml.etree.ElementTree as ET,hashlib,shutil
from continue_audio_audit import R,A,O,sha,now

def strip(s):return re.sub(r'/\*.*?\*/|//[^\n]*','',s,flags=re.S)
g=R/'yinyue_fashengqi.gprj'; entries=ET.parse(g).findall('./FileList/File')
files=[R/e.attrib['path'] for e in entries if e.attrib.get('enable')=='1']
assert len(files)==len(set(files)) and all(p.is_file() for p in files)
includes=[]
for p in list(files):
    if p.suffix in ['.v','.sv']:
        for inc in re.findall(r'`include\s+"([^"]+)"',p.read_text(encoding='utf8')):
            q=R/inc
            assert q.is_file();includes.append({'from':str(p),'resolved':str(q)})
            if q not in files:files.append(q)
modules={};bodies={}
for p in files:
    if p.suffix in ['.v','.sv']:
        s=strip(p.read_text(encoding='utf-8-sig'))
        for m in re.finditer(r'\bmodule\s+(\w+)\b(.*?)\bendmodule\b',s,re.S):
            assert m[1] not in modules,'duplicate module '+m[1]
            modules[m[1]]=str(p);bodies[m[1]]=m[2]
deps={n:[d for d in modules if d!=n and re.search(r'\b'+re.escape(d)+r'\s*(?:#\s*\([^;]*?\)\s*)?\w+\s*\(',bodies[n],re.S)] for n in modules}
seen=set()
def visit(n):
    if n in seen:return
    seen.add(n)
    for d in deps[n]:visit(d)
visit('tang_mega_138k_pro_top')
historical=json.loads((R/'audit/audio_diagnosis/BUILD_INPUT_HASHES.json').read_text())
backup=json.loads((A/'before.json').read_text())['files']
historical_mismatch=[rel for rel,h in historical['input_sha256'].items() if backup.get(rel)!=h]
oldrefs=[]
for p in (R/'src').rglob('*'):
    if p.is_file() and p.suffix in ['.v','.sv','.mod','.ipc','.cst','.sdc','.rao']:
        for line,t in enumerate(p.read_text(encoding='utf8',errors='replace').splitlines(),1):
            if re.search(r'[D-Zd-z]:[\\/]',t):oldrefs.append({'file':str(p),'line':line,'text':t,'enabled_dependency':p in files})
photo_dir=Path(r'C:\Users\Yan Guyao\Documents\xwechat_files\wxid_jzxtufy9t9g622_b3bc\temp\RWTemp\2026-10\229a925f915d645d4934e296b36e36a7')
photos=[]
for name,raw,midi in [('f6375392e18a78a2413987ed9e2de6e7.jpg','2000',67),('7535964547f28218ede237bb2f0048d1.jpg','2000',67),('2eec55cbede60b850ae10c997ddf9bda.jpg','4000',71),('8135b8330168fd58e69df74793fbd8f1.jpg','8000',75)]:
    p=photo_dir/name;photos.append({'path':str(p),'sha256':sha(p),'visually_rechecked':True,'RAWS':raw,'MIDI':midi,'VOICE':0,'PEAK':0})
recording=Path(r'C:\Users\Yan Guyao\Documents\xwechat_files\wxid_jzxtufy9t9g622_b3bc\msg\file\2026-10\20261017_140503(1).m4a')
result={'time':now(),'cwd':str(R),'only_write_root':str(R),'gprj':str(g),'top':'tang_mega_138k_pro_top','enabled_entries':len(entries)-sum(e.attrib.get('enable')!='1' for e in entries),'enabled_files':{str(p):sha(p) for p in files},'includes':includes,'modules':modules,'source_graph':deps,'top_source_closure':sorted(seen),'source_graph_scope':'Conservative source graph includes both generate branches; actual default engine/display branch checked by hierarchy assertions and elaboration','old_absolute_refs':oldrefs,'initial_historical_build_hash_mismatches':historical_mismatch,'historical_build_finished':historical.get('started_at_Asia_Shanghai'),'recording':{'original':str(recording),'copy':str(R/'tests/audio_diagnosis/user_recording.m4a'),'original_sha256':sha(recording),'copy_sha256':sha(R/'tests/audio_diagnosis/user_recording.m4a')},'photos':photos,'physical_key_order_confirmed':False,'physical_protocol_confirmed':False}
assert not historical_mismatch
(A/'PATH_VERSION_AUDIT.json').write_text(json.dumps(result,indent=2),encoding='utf8')
print('PASS static audit:',len(files),'enabled+include files,',len(modules),'unique modules; no historical input mismatch at snapshot')
