"""All artifacts, logs and audio go under yinse/sim/out. Never modifies src."""
from pathlib import Path
import os,sys,subprocess,json,hashlib,shutil,time,math,wave
import numpy as np
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'sim/out';OUT.mkdir(exist_ok=True)
SOURCES=sorted(ROOT.rglob('*.sv'))
SOURCES=[p for p in SOURCES if 'sim' not in p.relative_to(ROOT).parts]
RESULTS=[]
(OUT/'report.md').write_text('# RUNNING / INCOMPLETE\n',encoding='utf-8')
(OUT/'report.json').write_text(json.dumps({'status':'RUNNING'}),encoding='utf-8')
def tool(name,extra=()):
    override=os.environ.get('FPGA_'+name.upper())
    names=[override] if override else [name,*extra]
    folders=[ROOT.parent/'bin',Path(sys.executable).parent/'Scripts']
    folders+=list((Path(os.environ.get('APPDATA','__absent__'))/'Python').glob('*/Scripts'))
    for n in names:
        if not n:continue
        found=shutil.which(n)
        if found:return found
        if Path(n).is_file():return n
        for folder in folders:
            for suffix in ('','.exe'):
                p=folder/(n+suffix)
                if p.is_file():return str(p)
    raise RuntimeError('Missing tool '+name)
IV,VVP=tool('iverilog'),tool('vvp')
def run(name,args,timeout=240):
    env=dict(os.environ);env['LANG']=env['LC_ALL']='C'
    perl=Path('C:/Strawberry/perl/bin')
    if perl.exists():env['PATH']=str(perl)+os.pathsep+env.get('PATH','')
    p=subprocess.run(list(map(str,args)),cwd=ROOT,capture_output=True,text=True,errors='replace',timeout=timeout,env=env)
    output=p.stdout+p.stderr;(OUT/(name+'.log')).write_text(output,encoding='utf-8')
    if p.returncode:raise RuntimeError(name+': '+output[-4500:])
    return output
def sim(top,name,params=(),args=()):
    run(name+'_compile',[IV,'-g2012','-s',top,*params,'-o',OUT/(name+'.vvp'),*SOURCES,ROOT/'sim'/(top+'.sv')])
    result=run(name,[VVP,OUT/(name+'.vvp'),*args])
    if 'PASS' not in result or 'WARNING:' in result or 'FATAL' in result:raise RuntimeError(name+': '+result)
    RESULTS.append(name+': PASS');print(result.strip(),flush=True)
def peak_near(x,target,rate=48000):
    power=np.abs(np.fft.rfft(x*np.hanning(len(x))))**2
    k0=int(round(target*len(x)/rate));k=int(np.argmax(power[max(1,k0-3):k0+4]))+max(1,k0-3)
    y=np.log(np.maximum(power[k-1:k+2],1e-30));delta=.5*(y[0]-y[2])/(y[0]-2*y[1]+y[2])
    return (k+delta)*rate/len(x),power,k
def audio_check(path,instrument,note,voices):
    x=np.loadtxt(path,dtype=np.int64);steady=x[-16384:].astype(float)
    if len(x)!=24576 or max(abs(x))>=8388607:raise RuntimeError('audio missing or clipped')
    rms=float(np.sqrt(np.mean(steady**2)))
    if rms<100:raise RuntimeError('silent instrument')
    if voices==1:
        target=440*2**((note-69)/12)
        if instrument==4:
            # FM ratio produces inharmonic sidebands; carrier remains a target component.
            actual,power,k=peak_near(steady,target)
            if power[k]<max(power)*.002:raise RuntimeError('FM carrier missing')
            cents=1200*math.log2(actual/target)
            if abs(cents)>20:raise RuntimeError('FM carrier pitch '+str(cents))
        else:
            actual,power,k=peak_near(steady,target);cents=1200*math.log2(actual/target)
            if abs(cents)>12:raise RuntimeError('pitch '+str(cents))
        summary=f'instrument {instrument}, MIDI {note}: RMS {rms:.1f}, carrier/fundamental {actual:.3f} Hz, error {cents:.3f} cents'
    else:
        expected=[440*2**((n-69)/12) for n in range(60,60+voices)]
        hits=[]
        for f in expected:
            actual,power,k=peak_near(steady,f)
            if abs(1200*math.log2(actual/f))>15 or power[k]<max(power)*.00005:raise RuntimeError('polyphonic peak missing '+str(f))
            hits.append(k)
        if len(set(hits))!=voices:raise RuntimeError('polyphonic peaks not independent')
        summary=f'{voices} voices: {voices}/{voices} distinct fundamental components, RMS {rms:.1f}'
    RESULTS.append(summary+' PASS');print(summary,flush=True)
    with wave.open(str(path.with_suffix('.wav')),'wb') as w:
        w.setnchannels(1);w.setsampwidth(2);w.setframerate(48000)
        w.writeframes(np.clip(x>>8,-32768,32767).astype('<i2').tobytes())
try:
    sim('tb_yinse_controls','controls');sim('tb_yinse_tables','tables')
    sim('tb_yinse_switch_edges','switch_edges')
    sim('tb_yinse_range','range')
    sim('tb_yinse_events','events')
    for instrument,note in [(1,69),(1,60),(2,69),(2,60),(3,69),(3,60),(4,69),(4,60)]:
        name=f'audio_{instrument}_{note}';path=OUT/(name+'.txt')
        sim('tb_yinse_audio',name,args=[f'+instrument={instrument}',f'+note={note}',f'+output={path.as_posix()}'])
        audio_check(path,instrument,note,1)
    for voices,instrument in [(4,3),(16,1),(16,2),(16,3),(16,4)]:
        name=f'poly_{voices}_{instrument}';path=OUT/(name+'.txt')
        sim('tb_yinse_audio',name,params=[f'-Ptb_yinse_audio.VOICES={voices}'],args=[f'+instrument={instrument}',f'+output={path.as_posix()}'])
        if instrument!=4:audio_check(path,instrument,69,voices)
        else:
            x=np.loadtxt(path);assert np.sqrt(np.mean(x*x))>100
            RESULTS.append(f'FM {voices} independently active voices nonzero PCM PASS')
    # Explicit 256-clock frame budget, separate from accelerated numeric renders.
    for instrument in [1,2,3,4]:
        name=f'budget_16_{instrument}';path=OUT/(name+'.txt')
        sim('tb_yinse_audio',name,params=['-Ptb_yinse_audio.VOICES=16','-Ptb_yinse_audio.FRAME_CYCLES=256','-Ptb_yinse_audio.TOTAL_FRAMES=512'],
            args=[f'+instrument={instrument}',f'+output={path.as_posix()}'])
    RESULTS.append('16-voice four instruments, 512 frames each at 256 clocks/frame: no overrun, clipping or silent voice PASS')
    verilator=tool('verilator',('verilator-cli',))
    for top in ['yinse_controls','yinse_aux_bank','yinse_audio_mux','yinse_display_info']:
        result=run('lint_'+top,[verilator,'--lint-only','--Wall','--top-module',top,'--Mdir',OUT/('obj_'+top),*SOURCES])
        if '%Warning' in result or '%Error' in result:raise RuntimeError('lint diagnostics '+top)
        RESULTS.append(top+' strict lint: PASS')
    run('generic_structure',[sys.executable,'-B',ROOT/'sim/run_structure.py'])
    RESULTS.append('Yosys controls + auxiliary bank: no latches/warnings/structural errors PASS (not Gowin mapping)')
    baseline=json.loads((ROOT/'sim/outside_before.json').read_text())
    for name,digest in baseline.items():
        p=ROOT.parent/name
        if not p.exists() or hashlib.sha256(p.read_bytes()).hexdigest()!=digest:raise RuntimeError('outside yinse changed: '+name)
    RESULTS.append(f'{len(baseline)} existing tracked files unchanged PASS')
    report={'status':'PASS','scope':'Standalone yinse simulation, lint and generic RTL/memory check only; not Gowin mapping, original piano integration or hardware validation','results':RESULTS,
            'rtl_sha256':{p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in SOURCES}}
    (OUT/'report.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
    (OUT/'report.md').write_text('# 多音色独立验证\n\n'+'\n'.join('- '+r for r in RESULTS)+'\n\n'+report['scope']+'\n',encoding='utf-8')
    print('ALL YINSE CHECKS PASS',flush=True)
except Exception as e:
    (OUT/'report.md').write_text('# FAILED / INCOMPLETE\n\n'+'\n'.join(RESULTS)+'\n\n'+str(e),encoding='utf-8')
    (OUT/'report.json').write_text(json.dumps({'status':'FAILED','error':str(e),'results':RESULTS},indent=2),encoding='utf-8')
    print('FAIL',e,flush=True);sys.exit(1)
