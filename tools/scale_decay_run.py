"""Isolated ledger for logical scale and numerical decay validation. No programming."""
from pathlib import Path
from datetime import datetime, timezone, timedelta
import hashlib, json, os, shutil, subprocess, sys, xml.etree.ElementTree as ET

R=Path(__file__).resolve().parents[1]
assert R == Path(r'D:\gaoyun\piano_v2_audio_fix')
A=R/'audit/scale_decay_20261017'; O=R/'tests/scale_decay_20261017'
PY=Path(sys.executable)
IV=Path(r'D:\gaoyun\piano_v2\codex_test\tools\iverilog\bin\iverilog.exe'); VV=IV.with_name('vvp.exe')
def now(): return datetime.now(timezone(timedelta(hours=8))).isoformat()
def sha(p): return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def inputs():
    paths=[p for folder in ['src','sim','tools','tests/keyboard','tests/integration','tests/display','tests/scale_decay_20261017'] for p in (R/folder).rglob('*')
           if p.is_file() and p.suffix in ['.v','.sv','.vh','.py','.tcl','.hex','.mem','.json'] and 'audio_vendor' not in p.parts and 'sim_out' not in p.parts]
    paths += [R/'yinyue_fashengqi.gprj',R/'impl/yinyue_fashengqi_process_config.json']
    return {str(p.relative_to(R)):sha(p) for p in paths if p.exists()}
def snapshot():
    A.mkdir(parents=True,exist_ok=True); O.mkdir(parents=True,exist_ok=True)
    dest=A/'BEFORE.json'
    if dest.exists(): raise RuntimeError('Refusing to replace existing rollback snapshot')
    files=inputs()
    for folder in ['docs','tests/audio_diagnosis','tests/continuation_20261017']:
        for p in (R/folder).rglob('*'):
            if p.is_file() and (folder=='docs' or p.suffix in ['.v','.sv','.py']): files[str(p.relative_to(R))]=sha(p)
    for p in R.glob('*.md'): files[str(p.relative_to(R))]=sha(p)
    for rel in ['src/integrated.cst','src/integrated.sdc','src/keyboard_debug.rao','impl/pnr/ao_0.fs','impl/pnr/yinyue_fashengqi.tr','impl/pnr/yinyue_fashengqi.rpt.txt','impl/pnr/yinyue_fashengqi.pin.html','impl/gwsynthesis/yinyue_fashengqi_syn.rpt.html','audit/continuation_20261017/BUILD.json']:
        p=R/rel
        if p.exists():files[rel]=sha(p)
    for rel in files:
        p=A/'backup'/rel;p.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(R/rel,p)
    dest.write_text(json.dumps({'time':now(),'root':str(R),'files':files,'previous_fs_sha256':sha(R/'impl/pnr/ao_0.fs')},indent=2),encoding='utf8')
    print('SNAPSHOT',len(files),'files;',dest,flush=True)
def run(name,args,timeout=21600):
    O.mkdir(parents=True,exist_ok=True); A.mkdir(parents=True,exist_ok=True)
    args=list(map(str,args)); before=inputs(); m={'name':name,'command':args,'cwd':str(R),'started':now(),'input_sha256':before,'status':'RUNNING','log':str(O/(name+'.log'))}
    meta=O/(name+'.json');meta.write_text(json.dumps(m,indent=2),encoding='utf8')
    env=os.environ.copy();env.update(FPGA_IVERILOG=str(IV),FPGA_VVP=str(VV),PYTHONDONTWRITEBYTECODE='1');env['PATH']=str(IV.parent)+os.pathsep+env['PATH']
    try:
        with (O/(name+'.log')).open('w',encoding='utf8') as f:p=subprocess.run(args,cwd=R,env=env,stdout=f,stderr=subprocess.STDOUT,timeout=timeout)
        m.update(status='PASS' if p.returncode==0 else 'FAIL',returncode=p.returncode)
    except subprocess.TimeoutExpired:m.update(status='TIMEOUT',returncode=None)
    m.update(finished=now(),source_hashes_after=inputs());meta.write_text(json.dumps(m,indent=2),encoding='utf8');print(name,m['status'],flush=True)
    return m['status']=='PASS'
def sources():
    from continue_audio_audit import sources as old_sources
    return old_sources()
def top_sim(name,tb,top,parameters=(),extra=()):
    out=O/(name+'.vvp')
    files=[*sources(),tb,'sim/models/piano_roms_fast.v','sim/models/gowin_pll_stub.v','sim/models/ttp229_bfm.v','sim/models/i2s_rx_model.v','sim/tb/tb_pcm5102_i2s.v','tests/integration/video_boundary_stub.v',*extra]
    return run(name+'_compile',[IV,'-g2012','-s',top,*parameters,'-o',out,*files]) and run(name,[VV,out])
def regression():return run('full_regression',[PY,'-X','utf8','-B','-u','-c',"import os,runpy,sys;os.cpu_count=lambda:6;sys.argv=['sim/run_tests.py','all'];runpy.run_path('sim/run_tests.py',run_name='__main__')"])
def keyboard():return run('keyboard_unit',[PY,'-X','utf8','-B','-u','tools/run_keyboard_unit.py']) and run('keyboard_status',[PY,'-X','utf8','-B','-u','tools/run_keyboard_status.py'])
def display():return run('display',[PY,'-X','utf8','-B','-u','tests/display/scripts/verify_display.py'])
def mapping():
    return all(top_sim(name,'tests/scale_decay_20261017/tb_scale_mapping.sv','tb_scale_mapping',parameters=['-Ptb_scale_mapping.REMAPPED='+str(remap),'-Ptb_scale_mapping.BASE='+str(base)]) for name,remap,base in [('mapping_default',0,60),('mapping_permuted',1,60),('mapping_transposed',0,48)])
def direct():return top_sim('direct_midi','tests/scale_decay_20261017/tb_direct_midi.sv','tb_direct_midi')
def telemetry():
    out=O/'voice_peak.vvp'
    return run('voice_peak_compile',[IV,'-g2012','-s','tb_voice_peak','-o',out,'tests/scale_decay_20261017/tb_voice_peak.sv','src/audio_telemetry.v']) and run('voice_peak',[VV,out])
def parameters():
    dst=O/'tb_loader.v';dst.write_text((R/'tests/audio_diagnosis/tb_audio_loader.v').read_text().replace('tests/audio_diagnosis/loader_words.csv','tests/scale_decay_20261017/loader_words.csv'),encoding='utf8')
    if not run('loader_compile',[IV,'-g2012','-s','tb_audio_loader','-o',O/'loader.vvp',dst,'src/piano_note_loader.v','src/note_freq_table.v','src/piano_level_rom.v','src/piano_ratio_rom.v','src/piano_note_rom.v']):return False
    if not run('loader',[VV,O/'loader.vvp']):return False
    for script in ['audio_static_audit.py','audio_source_audit.py']:
        code="from pathlib import Path;p=Path('tools/"+script+"');s=p.read_text().replace(\"O=R/'tests/audio_diagnosis'\",\"O=R/'tests/scale_decay_20261017'\");exec(compile(s,str(p),'exec'),{'__file__':str(p.resolve()),'__name__':'__main__'})"
        if not run(script[:-3],[PY,'-X','utf8','-B','-c',code]):return False
    code="import sys,runpy;sys.path.insert(0,'tools');import continue_audio_audit as m;from pathlib import Path;m.O=Path('tests/scale_decay_20261017').resolve();runpy.run_path('tools/continuation_nyquist_audit.py',run_name='__main__')"
    return run('nyquist_audit',[PY,'-X','utf8','-B','-c',code])
def stress():
    dst=O/'tb_audio_stress_default.sv';dst.write_text((R/'tests/audio_diagnosis/tb_audio_stress_default.sv').read_text().replace('tests/continuation_20261017','tests/scale_decay_20261017'),encoding='utf8')
    return top_sim('stress',dst,'tb_audio_stress_default',extra=['tests/display/sim/tmds_stream_checker.sv'])
def syntax():
    src=[R/e.attrib['path'] for e in ET.parse(R/'yinyue_fashengqi.gprj').findall('./FileList/File') if e.attrib.get('enable')=='1' and Path(e.attrib['path']).suffix in ['.v','.sv']]
    return run('hardware_syntax',[IV,'-g2012','-tnull','-s','tb_hardware_elaboration','tests/integration/tb_hardware_elaboration.sv',*src,r'C:\Gowin2\Gowin_V1.9.12_x64\IDE\simlib\gw5a\prim_sim.v'])
def build():
    import time,re
    src={str(R/e.attrib['path']):sha(R/e.attrib['path']) for e in ET.parse(R/'yinyue_fashengqi.gprj').findall('./FileList/File') if e.attrib.get('enable')=='1'}
    for rel in ['src/piano_fx.v','yinyue_fashengqi.gprj','tools/build_gowin.tcl','impl/yinyue_fashengqi_process_config.json']:src[str(R/rel)]=sha(R/rel)
    started=time.time();meta={'status':'RUNNING','started':now(),'input_sha256':src}
    dest=A/'BUILD.json';dest.write_text(json.dumps(meta,indent=2),encoding='utf8')
    good=run('gowin',[r'C:\Gowin2\Gowin_V1.9.12_x64\IDE\bin\gw_sh.exe',R/'tools/build_gowin.tcl'])
    fs=R/'impl/pnr/ao_0.fs';tr=R/'impl/pnr/yinyue_fashengqi.tr';text=tr.read_text(errors='replace') if tr.exists() else ''
    headers=['3.1.1 Setup Paths Table','3.1.2 Hold Paths Table','3.1.3 Recovery Paths Table','3.1.4 Removal Paths Table','3.2 Minimum Pulse Width Table']
    slacks={h:float(m[1]) if (m:=re.search('^'+re.escape(h)+r'.*?\n\s*1\s+([\d.-]+)',text,re.M|re.S)) else None for h in headers}
    timing=all(v is not None and v>=0 for v in slacks.values()) and all(f'<Numbers of {t} Violated Endpoints>:0' in text for t in ['Setup','Hold'])
    fresh=fs.exists() and fs.stat().st_mtime>=started;stable=all(sha(p)==h for p,h in src.items())
    meta.update(status='PASS' if good and timing and fresh and stable else 'FAIL',finished=now(),fresh_bitstream=fresh,inputs_unchanged=stable,all_listed_timing_nonnegative=timing,worst_slacks_ns=slacks,fs=str(fs),sha256=sha(fs) if fs.exists() else None,no_auto_programming=True,
      effective_parameters={'BUILD_STAGE':3,'DISPLAY_ENABLE':1,'KEYBOARD_PROFILE':0,'KEY_RAW_MAP_ENABLE':0,'KEY_RAW_INDEX_TABLE':'fedcba9876543210','KEY_MAPPING_CONFIRMED':0,'KEY_BASE_NOTE':60,'logical_midi':list(range(60,76)),'KEY_NOTE_TABLE_packed_hex':f'{sum((60+i)<<(7*i) for i in range(16)):028x}','bridge_USE_NOTE_TABLE':1,'note':'Derived from hashed default top and independent default elaboration CSV; no parameter overrides in hashed build configuration'})
    dest.write_text(json.dumps(meta,indent=2),encoding='utf8');print('BUILD',meta['status'],slacks,flush=True);return meta['status']=='PASS'
def build_after_regression():
    import time,re
    print('Waiting for the current complete regression before implementation',flush=True)
    while True:
        m=json.loads((O/'full_regression.json').read_text())
        if m['status']!='RUNNING':break
        time.sleep(10)
    if m['status']!='PASS' or not re.search(r'68 tests, 0 failed',(O/'full_regression.log').read_text()):
        raise RuntimeError('Full 68-test regression did not pass; refusing implementation')
    print('68 tests passed; starting Gowin implementation, no programming',flush=True)
    return build()
if __name__=='__main__':
    action=sys.argv[1]
    if action=='snapshot':snapshot()
    else:sys.exit(not globals()[action]())
