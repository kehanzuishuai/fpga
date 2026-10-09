"""Offline Hall calibration/action tests, integer oracle, strict lint and Yosys.

Generated vectors/logs stay ignored. No audio, GPIO or vendor IP modifications.
"""
from pathlib import Path
import hashlib,json,random,subprocess,sys
from datetime import datetime,timezone
from toolchain import ROOT,discover,environment

OUT=ROOT/'sim_out_keys'
OUT.mkdir(exist_ok=True)
SOURCES=[ROOT/'src'/n for n in ('hall_position_filter.sv','hall_key_events.sv')]
TB=ROOT/'sim/tb_hall_keys.sv'
FILES=SOURCES+[TB,Path(__file__)]
report={'status':'RUNNING','physical_validation':False,'started_utc':datetime.now(timezone.utc).isoformat(),
        'results':[],'configurations':[],'source_sha256':{str(p.relative_to(ROOT)).replace('\\','/'):hashlib.sha256(p.read_bytes()).hexdigest() for p in FILES}}

class Golden:
    def __init__(self,keys,shift,confirm):
        self.keys,self.shift,self.confirm=keys,shift,confirm
        self.reset()
    def reset(self):
        self.state=[dict(rest=0,down=0,cal=False,filt=None,armed=False,pressed=False,travel=False,slow=False,start=0,count=0,velocity=0) for _ in range(self.keys)]
    @staticmethod
    def velocity(ticks):
        for bound,value in zip((100,200,400,800,1600,3200,6400,12800),(127,112,96,80,64,48,32,16)):
            if ticks<=bound:return value
        return 1
    def command(self,cmd):
        kind,k,raw,t,good,rest,down=cmd
        if kind==2:
            self.reset();return ['R'],[]
        if k>=self.keys:return [],[]
        s=self.state[k]
        if kind==1:
            s.update(rest=rest,down=down,cal=abs(down-rest)>=64,filt=None)
            pos,valid=0,False
        elif not good or not s['cal']:
            s['filt']=None;pos,valid=0,False
        else:
            target=raw*16
            if s['filt'] is None or not self.shift:s['filt']=target
            else:s['filt']+=(target-s['filt'])//(2**self.shift)
            value=s['filt']//16
            # Independent signed affine mapping and clamp, not RTL divider steps.
            distance=(value-s['rest'])*(1 if s['down']>s['rest'] else -1)
            pos=max(0,min(4095,(distance*4095)//abs(s['down']-s['rest'])))
            valid=True
        out=[f'P {k} {pos} {int(valid)} {t}'];ev=[]
        def emit(on,vel):ev.append(f'E {k} {on} {vel} {t}')
        if not valid:
            if s['pressed']:emit(0,0)
            s.update(armed=False,travel=False,slow=False,count=0,pressed=False)
        elif not s['armed']:
            if pos<=512:s['armed']=True
        elif s['pressed']:
            s['count']=s['count']+1 if pos<=512 else 0
            if s['count']==self.confirm:
                s.update(pressed=False,count=0,travel=False);emit(0,0)
        else:
            elapsed=(t-s['start'])&0xffffffff
            was_travel=s['travel'];was_slow=s['slow']
            if pos<=256:s.update(travel=False,slow=False)
            elif not was_travel:s.update(travel=True,slow=False,start=t)
            elif elapsed>12800:s['slow']=True
            if pos>=2048:
                v=(1 if was_slow else self.velocity(elapsed)) if was_travel else 127
                if not s['count']:s['velocity']=v
                s['count']+=1
                if s['count']==self.confirm:
                    s.update(pressed=True,count=0);emit(1,s['velocity'])
            else:s['count']=0
        return out,ev

def vectors(keys,shift,confirm):
    cmds=[];stamp=100
    def add(kind,k=0,raw=0,good=1,rest=0,down=4095,dt=100):
        nonlocal stamp
        stamp=(stamp+dt)&0xffffffff
        cmds.append((kind,k,raw,stamp,good,rest,down))
    def sample(k,raw,repeat=1,**kw):
        for _ in range(repeat):add(0,k,raw,**kw)
    # All keys independently configured, alternating rising/falling orientation.
    for k in range(keys):add(1,k,rest=400 if k%2==0 else 3600,down=3600 if k%2==0 else 400)
    # Held at startup: may not arm or trigger; then rail release/re-press all keys.
    for pressed in (True,False,True,False):
        for _ in range(100):
            for k in range(keys):sample(k,(4095 if k%2==0 else 0) if pressed else (0 if k%2==0 else 4095))
    # Invalid sample while held, stale indication, recovery requires release.
    sample(0,4095,100);sample(0,4095,good=0);sample(0,4095,100);sample(0,0,100)
    # Reconfiguration while held must emit release once, then require re-arm.
    sample(0,4095,100);add(1,0,rest=400,down=3600);sample(0,4095,100);sample(0,0,100)
    # Equal, tiny, minimum allowed, reversed and full rail calibration spans.
    for rest,down in ((2000,2000),(1000,1063),(1000,1064),(1064,1000),(0,4095),(4095,0)):
        add(1,0,rest=rest,down=down)
        for raw in (0,999,1000,1032,1064,2000,4095,0):sample(0,raw,35)
    # Hysteresis and confirmation/bounce: exact normalized boundary sequence.
    add(1,0);sample(0,0,100)
    for raw in (256,257,511,512,513,2047,2048,2047,2048,2049,2048,2048,2048,1024,513,512,513,512,511,512,0):sample(0,raw)
    sample(0,0,100)
    # Exact timestamp-wrap and all velocity-band endpoints (shift0 direct mapping).
    for duration in (0,1,99,100,101,200,201,400,401,800,801,1600,1601,3200,3201,6400,6401,12800,12801,1000000):
        add(1,0);sample(0,0)
        stamp=0xfffffff0;sample(0,300,dt=0)
        sample(0,2048,dt=duration);sample(0,2048,repeat=confirm,dt=0)
        sample(0,0,repeat=confirm)
    # Slow travel latch cannot turn into high velocity after later timer wrap.
    add(1,0);sample(0,0);sample(0,300);sample(0,300,dt=20000)
    sample(0,2048,repeat=confirm,dt=0xffffffff-19999);sample(0,0,repeat=confirm)
    # Out-of-range channel encodings (for non-power-of-two KEYS) are ignored.
    width=max(1,(keys-1).bit_length())
    if keys<2**width:
        add(1,2**width-1);sample(2**width-1,4095)
    # Reset while keys held, calibrations invalidated, then restore independently.
    sample(0,4095,100);add(2)
    for k in range(keys):sample(k,4095);add(1,k);sample(k,0)
    rng=random.Random(9242+keys+shift*43+confirm*97)
    for _ in range(5000):
        k=rng.randrange(keys)
        if rng.randrange(80)==0:
            rest=rng.randrange(4096);down=rng.randrange(4096);add(1,k,rest=rest,down=down)
        else:sample(k,rng.choice((0,4095,256,512,2048,rng.randrange(4096))),good=int(rng.randrange(31)!=0),dt=rng.choice((0,1,100,10000,20000)))
    return cmds

def run(name,args,timeout=180):
    p=subprocess.run([str(x) for x in args],cwd=ROOT,env=environment(),capture_output=True,text=True,errors='replace',timeout=timeout)
    output=p.stdout+p.stderr;(OUT/(name+'.log')).write_text(output,encoding='utf-8')
    if p.returncode or 'FATAL' in output or 'WARNING:' in output:raise RuntimeError(name+': '+output[-4000:])
    return output

def main():
    tc=discover()
    for keys,shift,confirm in ((1,0,1),(3,0,2),(16,0,1),(16,1,2),(16,2,2),(16,4,3),(32,2,2)):
        model=Golden(keys,shift,confirm);cmds=vectors(keys,shift,confirm);expected_p=[];expected_e=[]
        for cmd in cmds:
            p,e=model.command(cmd);expected_p+=p;expected_e+=e
        mask=sum(int(s['pressed'])<<k for k,s in enumerate(model.state))
        (OUT/'vectors.txt').write_text(''.join(' '.join(map(str,c))+'\n' for c in cmds),encoding='ascii')
        label=f'keys{keys}_filter{shift}_confirm{confirm}';image=OUT/(label+'.vvp')
        output=run(label+'_compile',[tc['iverilog'],'-g2012','-s','tb_hall_keys',f'-Ptb_hall_keys.KEYS={keys}',f'-Ptb_hall_keys.FILTER_SHIFT={shift}',f'-Ptb_hall_keys.CONFIRM_SAMPLES={confirm}','-o',image,*SOURCES,TB])
        if 'warning' in output.lower():raise RuntimeError(output)
        output=run(label,[tc['vvp'],image]);assert 'PASS' in output,output
        lines=(OUT/'results.txt').read_text().splitlines()
        actual_p=[s for s in lines if s.startswith(('P ','R'))];actual_e=[s for s in lines if s.startswith('E ')]
        for title,a,b in (('positions',actual_p,expected_p),('events',actual_e,expected_e)):
            if a!=b:
                first=next((i for i,(x,y) in enumerate(zip(a,b)) if x!=y),min(len(a),len(b)))
                raise AssertionError(f'{label} {title} first mismatch{first}: actual{a[first:first+3]}, expected{b[first:first+3]}, counts{len(a)}/{len(b)}')
        assert lines[-1]==f'D {mask}',lines[-1]
        assert lines[-2]=='L 1 25',lines[-2]
        assert any(' 1 ' in e for e in expected_e) and any(e.split()[2]=='0' for e in expected_e)
        if keys==16 and shift==0 and confirm==1:
            assert set(int(e.split()[3]) for e in expected_e if e.split()[2]=='1')=={1,16,32,48,64,80,96,112,127}
        (OUT/(label+'_results.txt')).write_text('\n'.join(lines)+'\n',encoding='ascii')
        report['configurations'].append({'keys':keys,'filter_shift':shift,'confirm_samples':confirm,'commands':len(cmds),'positions':len(actual_p)-1,'events':len(actual_e),'normalizer_latency_cycles':[1,25],'status':'PASS'})
        report['results'].append(label+': integer golden positions/events/final state bit-exact PASS')
        print(label,output.strip(),flush=True)
        for top in ('hall_position_filter','hall_key_events'):
            parameters={'KEYS':keys,**({'FILTER_SHIFT':shift} if top.endswith('filter') else {'CONFIRM_SAMPLES':confirm})}
            out=run(label+'_lint_'+top,[tc['verilator'],'--lint-only','--Wall','--top-module',top,*[f'-G{k}={v}' for k,v in parameters.items()],*SOURCES])
            if '%Warning' in out or '%Error' in out:raise RuntimeError(out)
    report['results'].append('14 strict Verilator configurations:0 warnings PASS')
    for top,param,value in (('hall_position_filter','FILTER_SHIFT',5),('hall_position_filter','MIN_SPAN',0),('hall_key_events','ON_POSITION',512),('hall_key_events','CONFIRM_SAMPLES',17)):
        label=f'reject_{top}_{param}';image=OUT/(label+'.vvp')
        run(label+'_compile',[tc['iverilog'],'-g2012','-s',top,f'-P{top}.{param}={value}','-o',image,*SOURCES])
        p=subprocess.run([str(tc['vvp']),str(image)],cwd=ROOT,env=environment(),capture_output=True,text=True,timeout=10)
        text=p.stdout+p.stderr
        (OUT/(label+'.log')).write_text(text,encoding='utf-8')
        if 'FATAL:' not in text or top+' invalid parameters' not in text or 'Time: 0' not in text or 'PASS' in text:raise RuntimeError(label+': missing time0 rejection')
    report['results'].append('4 invalid parameter guards reject at time0 PASS')
    for top in ('hall_position_filter','hall_key_events'):
        command='read_verilog -sv -DSYNTHESIS '+' '.join(str(p.relative_to(ROOT)).replace('\\','/') for p in SOURCES)+f'; hierarchy -check -top {top}; proc; opt; check -assert; stat; log HALL_KEYS_CHECK_COMPLETE'
        out=run('yosys_'+top,[tc['yosys'],'-Q','-T','-p',command])
        if 'Found and reported 0 problems' not in out or 'HALL_KEYS_CHECK_COMPLETE\n' not in out:raise RuntimeError(out)
        if 'Warning:' in out or any(x in out for x in ('$div','$mod','$mul','$dlatch')):raise RuntimeError('Unexpected divider/multiplier/latch or warning: '+out[-4000:])
    report['results'].append('Yosys both modules:0 problems,no runtime div/mod/mul/latches PASS')
    for name,h in report['source_sha256'].items():assert hashlib.sha256((ROOT/name).read_bytes()).hexdigest()==h,name
    report['status']='PASS'
    report['scope']='Standalone calibrated positions and key actions only; no audio FIFO/board wiring or automatic calibration; velocity bands need physical tuning. Input timestamps are acquisition times, not processing times.'

(OUT/'verification.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
try:main()
except Exception as exc:report['status']='FAIL';report['error']=str(exc);print('FAIL',exc,flush=True)
report['finished_utc']=datetime.now(timezone.utc).isoformat()
(OUT/'verification.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print('ALL HALL KEY CHECKS '+report['status'],flush=True)
sys.exit(0 if report['status']=='PASS' else 1)
