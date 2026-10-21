"""Confirm selected natural tail exits in unchanged Voice RTL, without early NoteOff."""
import concurrent.futures as cf
import json
from range44_run import R,A,O,VV,PY,FS,run,dump,now,sha
from range44_analyze import read,table

def one(n):
    p=O/f'held_natural_{n}.txt'
    run(f'held_natural_{n}',[VV,O/'voice.vvp',f'+note={n}','+vel=100','+on=4','+off=288000','+ticks=288020',f'+log={p}'])
    run(f'held_natural_equivalence_{n}',[PY,'-X','utf8','-B','tools/compare_pcm.py',p,'--hammer','1'])
    loads=[];samples=[]
    for line in p.read_text().splitlines():
        x=line.split()
        if x[0]=='L':loads.append(list(map(int,x[1:])))
        elif x[0]=='S':samples.append(list(map(int,x[1:])))
    assert len(loads)==1 and loads[0][1:]==[n,100] and all(s[2:]==[0,0] for s in samples)
    assert all(b[0]==a[0]+1 for a,b in zip(samples,samples[1:]))
    nz=[s for s in samples if s[1]];last=nz[-1][0];start=loads[0][0]+1
    actual=(last-start+1)/FS
    q=next(x for x in read('QUANTIZATION.csv') if int(x['midi'])==n)
    assert abs(actual-float(q['natural_held_zero_s_model']))<=1/FS
    assert samples[-1][1]==0 and samples[-1][0]<288000
    return {'midi':n,'velocity':100,'scheduled_note_off_s':6,'run_ticks':288020,'loader_done_tick':loads[0][0],'last_nonzero_tick':last,'last_sample_tick':samples[-1][0],'natural_zero_s_from_loader_complete_rtl':actual,'model_natural_zero_s':float(q['natural_held_zero_s_model']),'all_samples_bit_exact':True,'release_before_stop':False,'log_sha256':sha(p)}

if __name__=='__main__':
    with cf.ThreadPoolExecutor(max_workers=3) as ex:rows=list(ex.map(one,[87,88,89]))
    table('NATURAL_TAIL_RTL.csv',rows)
    dump(A/'NATURAL_TAIL_RTL.json',{'status':'PASS','time':now(),'scope':'3 additional fresh 6s Voice RTL simulations, velocity100, no NoteOff before natural exit; selected from diagnostic tail-revival probe','results':rows})
