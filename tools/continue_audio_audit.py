"""Evidence ledger for the 2026-10-17 continuation. Never writes outside R."""
from pathlib import Path
from datetime import datetime, timezone, timedelta
import hashlib, json, shutil, subprocess, sys, os, xml.etree.ElementTree as ET
R=Path(__file__).resolve().parents[1]
assert R == Path(r'D:\gaoyun\piano_v2_audio_fix')
A=R/'audit/continuation_20261017'; O=R/'tests/continuation_20261017'
PY=Path(sys.executable); IV=Path(r'D:\gaoyun\piano_v2\codex_test\tools\iverilog\bin\iverilog.exe'); VV=IV.with_name('vvp.exe')
def now(): return datetime.now(timezone(timedelta(hours=8))).isoformat()
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def inputs():
    return {str(p.relative_to(R)):sha(p) for folder in ['src','sim','tools','tests/keyboard','tests/integration','tests/display','tests/audio_diagnosis','tests/continuation_20261017']
            for p in (R/folder).rglob('*') if p.is_file() and 'audio_vendor' not in p.parts and (p.suffix in ['.v','.sv','.py','.tcl','.cst','.sdc','.rao','.hex','.mem'] or p.name=='amy_piano_params.json') and 'sim_out' not in str(p)} | {str(p.relative_to(R)):sha(p) for p in [R/'yinyue_fashengqi.gprj', R/'impl/yinyue_fashengqi_process_config.json'] if p.exists()}
def snapshot():
    A.mkdir(parents=True,exist_ok=True); O.mkdir(parents=True,exist_ok=True)
    if (A/'before.json').exists(): raise RuntimeError('Snapshot already exists; refusing overwrite')
    files=inputs()
    files.update({str(p.relative_to(R)):sha(p) for p in (R/'docs').glob('*') if p.is_file()})
    for rel in ['impl/pnr/ao_0.fs','impl/pnr/yinyue_fashengqi.tr','impl/pnr/yinyue_fashengqi.rpt.txt','impl/pnr/yinyue_fashengqi.pin.html','impl/gwsynthesis/yinyue_fashengqi_syn.rpt.html']:
        if (R/rel).exists(): files[rel]=sha(R/rel)
    for rel in files:
        dst=A/'backup'/rel; dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(R/rel,dst)
    (A/'before.json').write_text(json.dumps({'time':now(),'root':str(R),'files':files},indent=2),encoding='utf8')
    print('Backup:',len(files),'files',A,flush=True)
def run(name,args,timeout=21600):
    O.mkdir(parents=True,exist_ok=True); A.mkdir(parents=True,exist_ok=True)
    args=list(map(str,args)); start=now(); before=inputs(); log=O/(name+'.log')
    meta={'name':name,'command':args,'cwd':str(R),'started':start,'input_sha256':before,'log':str(log),'status':'RUNNING'}
    dest=O/(name+'.json');dest.write_text(json.dumps(meta,indent=2),encoding='utf8')
    env=os.environ.copy();env['PATH']=str(IV.parent)+os.pathsep+env['PATH'];env['FPGA_IVERILOG']=str(IV);env['FPGA_VVP']=str(VV);env['PYTHONDONTWRITEBYTECODE']='1'
    try:
        with log.open('w',encoding='utf8') as out:
            p=subprocess.run(args,cwd=R,env=env,stdout=out,stderr=subprocess.STDOUT,timeout=timeout)
        meta.update(returncode=p.returncode,status='PASS' if p.returncode==0 else 'FAIL')
    except subprocess.TimeoutExpired:
        meta.update(returncode=None,status='TIMEOUT')
    meta.update(finished=now(),inputs_unchanged=before==inputs())
    dest.write_text(json.dumps(meta,indent=2),encoding='utf8'); print(name,meta['status'],str(log),flush=True)
    return meta['status']=='PASS'
def sources():
    excluded={'audio_pll.v','audio_pll_mod.v','visual_video_clock.v','visual_dvi_io.v','visual_pll_mod.v','pll_init.v','piano_level_rom.v','piano_ratio_rom.v','piano_note_rom.v','piano_sine_rom.v','piano_exp_rom.v'}
    return [R/e.attrib['path'] for e in ET.parse(R/'yinyue_fashengqi.gprj').findall('./FileList/File') if e.attrib.get('enable')=='1' and Path(e.attrib['path']).suffix in ['.v','.sv'] and Path(e.attrib['path']).name not in excluded]
def sim(name,tb,top,extra=(),defines=(),plus=()):
    out=O/(name+'.vvp')
    files=[*sources(),tb,'sim/models/piano_roms_fast.v','sim/models/gowin_pll_stub.v','sim/models/ttp229_bfm.v','sim/models/i2s_rx_model.v','sim/tb/tb_pcm5102_i2s.v','tests/integration/video_boundary_stub.v',*extra]
    if not run(name+'_compile',[IV,'-g2012','-s',top,*['-D'+d for d in defines],'-o',out,*files]):return False
    return run(name,[VV,out,*plus])
if __name__=='__main__':
    action=sys.argv[1]
    if action=='snapshot':snapshot()
    elif action=='mapping':sys.exit(not sim('mapping','tests/audio_diagnosis/tb_audio_note_map.sv','tb_audio_note_map'))
    elif action=='baseline_checker':sys.exit(not sim('baseline_checker','tests/continuation_20261017/tb_checker_reset.sv','tb_checker_reset',defines=()))
    elif action=='stress':sys.exit(not sim('stress','tests/audio_diagnosis/tb_audio_stress_default.sv','tb_audio_stress_default',extra=['tests/display/sim/tmds_stream_checker.sv']))
    elif action=='regression':sys.exit(not run('full_regression',[PY,'-X','utf8','-B','-u','-c',"import os,runpy,sys;os.cpu_count=lambda:6;sys.argv=['sim/run_tests.py','all'];runpy.run_path('sim/run_tests.py',run_name='__main__')"]))
    elif action=='display':sys.exit(not run('display',[PY,'-X','utf8','-B','-u','tests/display/scripts/verify_display.py']))
    elif action=='keyboard':
        a=run('keyboard_unit',[PY,'-X','utf8','-B','-u','tools/run_keyboard_unit.py']);b=run('keyboard_status',[PY,'-X','utf8','-B','-u','tools/run_keyboard_status.py']);sys.exit(not(a and b))
