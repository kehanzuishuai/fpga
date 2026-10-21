"""Fresh 44-note source-quality evidence. No production edits or programming."""
from pathlib import Path
from datetime import datetime, timezone, timedelta
import concurrent.futures as cf
import hashlib, json, os, shutil, subprocess, sys, time
import numpy as np

R = Path(__file__).resolve().parents[1]
assert R == Path(r'D:\gaoyun\piano_v2_audio_fix')
A = R/'audit/range44_20261018'
O = R/'tests/range44_20261018'
PY = Path(sys.executable)
IV = Path(r'D:\gaoyun\piano_v2\codex_test\tools\iverilog\bin\iverilog.exe')
VV = IV.with_name('vvp.exe')
FS, N, OFF = 48000, 144000, 96000
NOTES = list(range(48, 92))

def now(): return datetime.now(timezone(timedelta(hours=8))).isoformat()
def sha(p): return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def dump(p, obj):
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(json.dumps(obj, ensure_ascii=False, indent=2), encoding='utf8')

def protected():
    paths = [p for p in (R/'src').rglob('*') if p.is_file()]
    paths += [R/'yinyue_fashengqi.gprj', R/'impl/yinyue_fashengqi_process_config.json', R/'impl/pnr/ao_0.fs']
    return {p.relative_to(R).as_posix():sha(p) for p in paths if p.exists()}

def evidence_inputs():
    return protected() | {p.relative_to(R).as_posix():sha(p)
        for folder in ['sim', 'tools', 'tests/range44_20261018'] for p in (R/folder).rglob('*')
        if p.is_file() and p.suffix in ['.py', '.v', '.sv', '.hex', '.mem'] and 'audio_vendor' not in p.parts}

def prepare():
    A.mkdir(parents=True, exist_ok=True); O.mkdir(parents=True, exist_ok=True)
    if (A/'BEFORE.json').exists(): raise RuntimeError('Snapshot already exists')
    files = protected()
    for p in [*R.glob('*.md'), *(R/'docs').glob('*.md')]:
        files[p.relative_to(R).as_posix()] = sha(p)
    for rel in files:
        dst=A/'backup'/rel; dst.parent.mkdir(parents=True,exist_ok=True); shutil.copy2(R/rel,dst)
    dump(A/'BEFORE.json', {'started':now(),'root':str(R),'files':files,'protected':protected(),'scope':'44 individual pitches, not 32-key hardware or simultaneous polyphony acceptance','no_auto_programming':True})
    text=(R/'tests/scale_decay_20261017/tb_direct_midi.sv').read_text()
    text=text.replace('tests/scale_decay_20261017','tests/range44_20261018')
    text=text.replace('midi=60;midi<=75','midi=48;midi<=91').replace('MIDI60..75','MIDI48..91')
    text=text.replace('note==64 || note==75','note==48 || note==64 || note==79 || note==84 || note==91')
    text=text.replace('#3000000000;', '#6000000000;')
    (O/'tb_direct_midi.sv').write_text(text,encoding='utf8')
    shutil.copy2(R/'tests/audio_diagnosis/tb_audio_fx.v', O/'tb_audio_fx.v')
    print('BACKUP',len(files),'files; prepared 44-note direct test',flush=True)

def run(name,args,timeout=14400):
    args=list(map(str,args)); inp=evidence_inputs()
    meta={'command':args,'cwd':str(R),'started':now(),'input_sha256':inp,'status':'RUNNING'}
    log=O/(name+'.log'); dest=O/(name+'.json');dump(dest,meta)
    env=os.environ.copy();env['PATH']=str(IV.parent)+os.pathsep+env['PATH'];env['PYTHONDONTWRITEBYTECODE']='1'
    started=time.monotonic()
    try:
        with log.open('w',encoding='utf8') as f:
            p=subprocess.run(args,cwd=R,env=env,stdout=f,stderr=subprocess.STDOUT,timeout=timeout)
        text=log.read_text(errors='replace')
        ok=p.returncode==0 and 'FATAL' not in text and '\nFAIL' not in text
        meta.update(returncode=p.returncode,status='PASS' if ok else 'FAIL')
    except Exception as e:
        meta.update(status='ERROR',error=repr(e));ok=False
    meta.update(finished=now(),elapsed_s=time.monotonic()-started,inputs_unchanged=inp==evidence_inputs())
    dump(dest,meta);print(name,meta['status'],round(meta['elapsed_s'],1),'s',flush=True)
    if not ok:raise RuntimeError(name+' failed: '+str(log))
    return meta

def compile_audio():
    run('voice_compile',[IV,'-g2012','-s','tb_piano_voice','-o',O/'voice.vvp','sim/tb/tb_piano_voice.v','src/piano_partial_voice.v','src/piano_note_loader.v','src/note_freq_table.v','sim/models/piano_roms_fast.v'])
    run('fx_compile',[IV,'-g2005','-s','tb_audio_fx','-o',O/'fx.vvp',O/'tb_audio_fx.v','src/piano_fx.v'])

def voice(n):
    import fx_model
    d=O/'notes'/f'midi_{n:03d}';d.mkdir(parents=True,exist_ok=True)
    run(f'voice_{n}',[VV,O/'voice.vvp',f'+note={n}','+vel=100','+on=4',f'+off={OFF}',f'+ticks={N}',f'+log={d/"rtl_voice.txt"}'])
    run(f'equivalence_{n}',[PY,'-X','utf8','-B','tools/compare_pcm.py',d/'rtl_voice.txt','--hammer','1'])
    y=np.zeros(N,dtype=np.int64);seen=set();loads=[];nonzero_after_off=0
    for line in (d/'rtl_voice.txt').read_text().splitlines():
        x=line.split()
        if x[0]=='L':loads.append(list(map(int,x[1:])))
        elif x[0]=='S':
            tick,value,release,fade=map(int,x[1:]);assert 0<=tick<N and tick not in seen
            seen.add(tick);y[tick]=value
            if tick>OFF and value and release:nonzero_after_off+=1
    assert len(loads)==1 and loads[0][1:]==[n,100] and len(seen)>OFF and nonzero_after_off>0
    g=(y*32767)>>15;np.save(d/'voice.npy',y);np.save(d/'gain.npy',g)
    np.savetxt(d/'fx_input.txt',g,fmt='%d')
    run(f'fx_{n}',[VV,O/'fx.vvp',f'+input={d/"fx_input.txt"}',f'+output={d/"rtl_fx.txt"}',f'+samples={N}'])
    actual=np.loadtxt(d/'rtl_fx.txt',dtype=np.int64);model=fx_model.Fx().process(g)
    assert len(actual)==N and np.array_equal(actual,model),f'FX mismatch {n}'
    np.save(d/'fx.npy',actual)
    obj={'status':'PASS','midi':n,'velocity':100,'samples':N,'sample_rate':FS,'note_off_tick':OFF,'loads':loads,'computed_voice_samples':len(seen),'released_nonzero_samples':nonzero_after_off,'fresh_voice_rtl':True,'all_computed_voice_samples_bit_exact':True,'fresh_fx_rtl':True,'fx_bit_exact_samples':N,'sha256':{p.name:sha(p) for p in d.iterdir() if p.is_file()}}
    dump(d/'RESULT.json',obj);print('NOTE COMPLETE',n,flush=True);return obj

def audio():
    compile_audio(); results=[];failures=[];started=time.monotonic()
    with cf.ThreadPoolExecutor(max_workers=8) as ex:
        fs={ex.submit(voice,n):n for n in NOTES}
        for f in cf.as_completed(fs):
            try:results.append(f.result())
            except Exception as e:failures.append({'midi':fs[f],'error':repr(e)});print('FAILED',fs[f],e,flush=True)
            dump(A/'AUDIO_PROGRESS.json',{'status':'RUNNING','completed':len(results),'failures':failures,'elapsed_s':time.monotonic()-started})
    dump(A/'AUDIO_RUN.json',{'status':'PASS' if len(results)==44 and not failures else 'FAIL','finished':now(),'elapsed_s':time.monotonic()-started,'results':sorted(results,key=lambda x:x['midi']),'failures':failures})
    if failures:raise RuntimeError(failures)

def direct():
    from continue_audio_audit import sources
    files=[*sources(),O/'tb_direct_midi.sv','sim/models/piano_roms_fast.v','sim/models/gowin_pll_stub.v','sim/models/ttp229_bfm.v','sim/models/i2s_rx_model.v','sim/tb/tb_pcm5102_i2s.v','tests/integration/video_boundary_stub.v']
    run('direct_compile',[IV,'-g2012','-s','tb_direct_midi','-o',O/'direct.vvp',*files])
    run('direct',[VV,O/'direct.vvp'])

if __name__=='__main__':
    globals()[sys.argv[1]]()
