"""32-key implementation evidence; all outputs remain in this project."""
from pathlib import Path
import sys, os, json, shutil, hashlib, subprocess, time, re, xml.etree.ElementTree as ET
from datetime import datetime, timezone, timedelta
R=Path(__file__).resolve().parents[2]
O=Path(__file__).resolve().parent
A=R/'audit/keyboard32_20261019'
IV=Path(r'D:/gaoyun/piano_v2/codex_test/tools/iverilog/bin/iverilog.exe')
VV=IV.with_name('vvp.exe')
sys.path.insert(0,str(R/'tools'))
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def now(): return datetime.now(timezone(timedelta(hours=8))).isoformat()
def inputs():
    return {str(p.relative_to(R)).replace('\\','/'):sha(p) for p in (R/'src').rglob('*') if p.is_file()} | {'yinyue_fashengqi.gprj':sha(R/'yinyue_fashengqi.gprj')}
def snapshot():
    A.mkdir(parents=True,exist_ok=True)
    assert not (A/'BEFORE.json').exists(),'Preserve existing backup'
    files=list((R/'src').rglob('*'))+list((R/'docs').glob('*.md'))+[R/'yinyue_fashengqi.gprj',R/'README.md']
    files += [R/q for q in ['impl/pnr/ao_0.fs','impl/pnr/yinyue_fashengqi.tr','impl/pnr/yinyue_fashengqi.pin.html','impl/pnr/yinyue_fashengqi.rpt.txt','impl/gwsynthesis/yinyue_fashengqi.vg','impl/yinyue_fashengqi_process_config.json']]
    record={}
    for p in files:
        if not p.is_file(): continue
        q=p.relative_to(R); target=A/'backup'/q;target.parent.mkdir(parents=True,exist_ok=True)
        shutil.copy2(p,target);record[q.as_posix()]=sha(p)
    (A/'BEFORE.json').write_text(json.dumps({'time':now(),'sha256':record},indent=2))
    print('Backed up',len(record),'files',flush=True)
def run(label,args):
    before=inputs(); t=time.time()
    with (O/(label+'.log')).open('w',encoding='utf8') as f:
        p=subprocess.run(list(map(str,args)),cwd=R,stdout=f,stderr=subprocess.STDOUT)
    assert before==inputs(),'Production changed during test'
    print(label,p.returncode,'elapsed',round(time.time()-t,1),flush=True)
    assert p.returncode==0,(label,(O/(label+'.log')).read_text(errors='replace')[-3500:])
def unit():
    from concurrent.futures import ThreadPoolExecutor
    jobs={
      'events32': ['src/ttp229_event_bridge.v','src/note_event_fifo.v',O/'tb_events32.sv'],
      'serial_pair':['src/ttp229_reader.v','src/keyboard/keyboard_state_mapper.sv','src/keyboard/ttp229_keyboard_pair.sv','sim/models/ttp229_bfm.v',O/'tb_pair_serial.sv'],
      'legacy16':['src/ttp229_event_bridge.v','src/note_event_fifo.v','src/keyboard/keyboard_state_mapper.sv','tests/keyboard/tb_keyboard_events.sv']}
    tops={'events32':'tb_events32','serial_pair':'tb_pair_serial','legacy16':'tb_keyboard_events'}
    def execute(name):
        run(name+'_compile',[IV,'-g2012','-s',tops[name],'-o',O/(name+'.vvp'),*jobs[name]])
        run(name,[VV,O/(name+'.vvp')])
        assert 'PASS' in (O/(name+'.log')).read_text()
    with ThreadPoolExecutor(max_workers=3) as ex:list(ex.map(execute,jobs))
    (O/'UNIT.json').write_text(json.dumps({'status':'PASS','input_sha256':inputs(),'groups':list(jobs)},indent=2))
def serial():
    files=['src/ttp229_reader.v','src/keyboard/keyboard_state_mapper.sv','src/keyboard/ttp229_keyboard_pair.sv','sim/models/ttp229_bfm.v',O/'tb_pair_serial.sv']
    run('serial_pair_compile',[IV,'-g2012','-s','tb_pair_serial','-o',O/'serial_pair.vvp',*files])
    run('serial_pair',[VV,O/'serial_pair.vvp'])
    assert 'PASS serial pair' in (O/'serial_pair.log').read_text()
    (O/'SERIAL.json').write_text(json.dumps({'status':'PASS','input_sha256':inputs(),'additional_coverage':'independent reversed/rotated raw-bit maps on the two modules'},indent=2))
def system():
    from continue_audio_audit import sources
    files=[*sources(),O/'tb_system32.sv','sim/models/piano_roms_fast.v','sim/models/gowin_pll_stub.v','sim/models/ttp229_bfm.v','sim/models/i2s_rx_model.v','sim/tb/tb_pcm5102_i2s.v','tests/display_upgrade_20261018/video_boundary_stub.v','tests/display/sim/tmds_stream_checker.sv']
    # visual_ref_pll_mod is an unused physical wrapper in this functional run.
    run('system_compile',[IV,'-g2012','-s','tb_system32','-o',O/'system.vvp',*files])
    run('system',[VV,O/'system.vvp'])
    assert 'PASS physical32 system' in (O/'system.log').read_text()
    (O/'SYSTEM.json').write_text(json.dumps({'status':'PASS','input_sha256':inputs(),'scope':'Production two-module reader timing, bridge, FIFO,32 real piano voices, FX, both decoded DAC outputs, FFT/TMDS/status. PLL/physical serializer functional stubs; not a hardware or audio-quality acceptance.'},indent=2))
def preserve():
    from continue_audio_audit import sources
    s=(A/'backup/src/tang_mega_138k_pro_top.v.v').read_text().replace('module tang_mega_138k_pro_top','module baseline_board').replace('ttp229_event_bridge #(','baseline_event_bridge #(')
    (O/'baseline_board.v').write_text(s)
    (O/'baseline_event_bridge.v').write_text((A/'backup/src/ttp229_event_bridge.v').read_text().replace('module ttp229_event_bridge','module baseline_event_bridge'))
    files=[*sources(),O/'baseline_board.v',O/'baseline_event_bridge.v',O/'tb_preserve16.sv','sim/models/piano_roms_fast.v','sim/models/gowin_pll_stub.v','sim/models/ttp229_bfm.v','tests/display_upgrade_20261018/video_boundary_stub.v']
    run('preserve_compile',[IV,'-g2012','-s','tb_preserve16','-o',O/'preserve.vvp',*files])
    run('preserve',[VV,O/'preserve.vvp'])
    assert 'PASS preserve16' in (O/'preserve.log').read_text()
    (O/'PRESERVE16.json').write_text(json.dumps({'status':'PASS','input_sha256':inputs(),'scope':'Original board+original bridge from before backup vs new board, real piano/FX, first-bank keys, idle second bank; disabled displays and functional clock/serializer boundaries. PCM and both DAC pins compared each audio clock.'},indent=2))
def progress():
    subprocess.run([r'C:/Users/Yan Guyao/.cache/codex-runtimes/codex-primary-runtime/dependencies/native/powershell/pwsh.exe','-NoProfile','-Command',
      'Get-Process vvp,gw_sh,gw_syn,pnr -ErrorAction SilentlyContinue | Select-Object ProcessName,Id,CPU,StartTime,WorkingSet64'],check=False)
def restart_system():
    # Only the exact VVP process previously observed for this task is eligible.
    cmd="& { $p=Get-CimInstance Win32_Process -Filter 'ProcessId=28180'; if ($p -and $p.Name -eq 'vvp.exe' -and $p.CommandLine -like '*keyboard32_20261019*system.vvp*') { Stop-Process -Id 28180 } elseif ($p) { throw 'Unexpected process; refusing to stop' } }"
    z=subprocess.run([r'C:/Users/Yan Guyao/.cache/codex-runtimes/codex-primary-runtime/dependencies/native/powershell/pwsh.exe','-NoProfile','-Command',cmd])
    assert z.returncode==0
    time.sleep(1)
    if (O/'system.log').exists():shutil.copy2(O/'system.log',O/'system_before_progress.log')
    system()
def gate():
    run('gate_loader_driver',[sys.executable,'-X','utf8','-B','-u',O/'gate_loader32.py'])
def loadroute():
    from continue_audio_audit import sources
    from fpga_piano_model import Loader
    import piano_tables as pt
    files=[*sources(),O/'tb_loadroute32.sv','sim/models/piano_roms_fast.v','sim/models/gowin_pll_stub.v','sim/models/ttp229_bfm.v','tests/display_upgrade_20261018/video_boundary_stub.v']
    run('loadroute_compile',[IV,'-g2012','-s','tb_loadroute32','-o',O/'loadroute.vvp',*files])
    run('loadroute',[VV,O/'loadroute.vvp'])
    loader=Loader(pt.build());expected={};seen=set();by_voice={};errors=[]
    for n in range(60,92):
        p=loader.params(n,100)
        for slot in range(16):
            for offset,val in enumerate([p['inc'][slot],0,pt.L_INIT,0,*p['bp'][slot]]):expected[n,slot*32+offset]=int(val)
    for line in (O/'voice_ram_words.csv').read_text().splitlines():
        voice,n,addr,data=map(int,line.split(','));key=(voice,addr)
        assert key not in seen;seen.add(key)
        if voice in by_voice: assert by_voice[voice]==n
        by_voice[voice]=n
        if data!=expected[n,addr]:errors.append({'voice':voice,'midi':n,'addr':addr,'actual':data,'expected':expected[n,addr]})
    assert len(seen)==12800 and sorted(by_voice)==list(range(32)) and sorted(by_voice.values())==list(range(60,92))
    result={'status':'PASS' if not errors else 'FAIL','voices':by_voice,'actual_RAM_writes_and_readbacks':12800,'model_mismatches':len(errors),'examples':errors[:20],'input_sha256':inputs(),'scope':'Production-timing two serial modules and real32-voice synth, every load word observed at actual Voice RAM port and read back after write; display disabled only for this focused run.'}
    (O/'LOADROUTE32.json').write_text(json.dumps(result,indent=2));assert not errors,errors[:10]
    print('PASS32 complete RAM images match per-note model at each actual destination Voice',flush=True)
def build():
    A.mkdir(parents=True,exist_ok=True)
    if (A/'BUILD.json').exists():
        n=1
        while (A/f'BUILD_attempt{n}.json').exists(): n+=1
        shutil.copy2(A/'BUILD.json',A/f'BUILD_attempt{n}.json')
        if (O/'gowin.log').exists():shutil.copy2(O/'gowin.log',O/f'gowin_attempt{n}.log')
    start=time.time();before=inputs()
    record={'status':'RUNNING','started':now(),'input_sha256':before,'no_auto_programming':True}
    dest=A/'BUILD.json';dest.write_text(json.dumps(record,indent=2))
    with (O/'gowin.log').open('w') as f:
        p=subprocess.run([r'C:/Gowin2/Gowin_V1.9.12_x64/IDE/bin/gw_sh.exe','tools/build_gowin.tcl'],cwd=R,stdout=f,stderr=subprocess.STDOUT)
    record.update(returncode=p.returncode,finished=now(),elapsed_s=time.time()-start,inputs_unchanged=before==inputs())
    paths=['impl/pnr/ao_0.fs','impl/gwsynthesis/yinyue_fashengqi.vg','impl/gwsynthesis/yinyue_fashengqi_syn.rpt.html','impl/pnr/yinyue_fashengqi.tr','impl/pnr/yinyue_fashengqi.rpt.txt','impl/pnr/yinyue_fashengqi.pin.html']
    record['outputs']={q:{'sha256':sha(R/q),'bytes':(R/q).stat().st_size,'fresh':(R/q).stat().st_mtime>=start-2} for q in paths if (R/q).exists()}
    text=(R/'impl/pnr/yinyue_fashengqi.tr').read_text(errors='replace')
    names={'setup':'3.1.1 Setup Paths Table','hold':'3.1.2 Hold Paths Table','recovery':'3.1.3 Recovery Paths Table','removal':'3.1.4 Removal Paths Table','min_pulse_width':'3.2 Minimum Pulse Width Table'}
    record['worst_slack_ns']={k:float(m[1]) if (m:=re.search('^'+re.escape(v)+r'.*?\n\s*1\s+([\d.-]+)',text,re.M|re.S)) else None for k,v in names.items()}
    record['violated_endpoints']={k:int(m[1]) if (m:=re.search(r'<Numbers of '+k+r' Violated Endpoints>:(\d+)',text)) else None for k in ['Setup','Hold']}
    record['all_timing_checks_pass']=all(v is not None and v>=0 for v in record['worst_slack_ns'].values()) and record['violated_endpoints']=={'Setup':0,'Hold':0}
    record['status']='PASS' if p.returncode==0 and record['inputs_unchanged'] and len(record['outputs'])==len(paths) and all(m['fresh'] for m in record['outputs'].values()) and record['all_timing_checks_pass'] else 'FAIL'
    dest.write_text(json.dumps(record,indent=2));print(json.dumps({k:record[k] for k in ['status','returncode','worst_slack_ns','violated_endpoints']},indent=2),flush=True)
    assert record['status']=='PASS'
if __name__=='__main__': globals()[sys.argv[1]]()
