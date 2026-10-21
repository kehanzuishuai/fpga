"""Counterfactual model only: can later breakpoints revive a naturally stopped voice?

The production model and RTL are never edited. The only experimental difference
is disabling the all-partials-gated transition to IDLE; first-stop times are taken
from the separately rendered unmodified model. This is not a proposed fix.
"""
import inspect, textwrap
import numpy as np
import fpga_piano_model as fm
import piano_tables as pt
from range44_run import A,O,NOTES,FS,sha,R,now,dump
from range44_analyze import read,table,rms,db

def main():
    code=textwrap.dedent(inspect.getsource(fm.Voice.render))
    assert code.count('if may_stop:')==1
    code=code.replace('if may_stop:', 'if False and may_stop:')
    ns={'np':np,'pt':pt,'MASK28':fm.MASK28};exec(compile(code,'counterfactual_no_early_idle','exec'),ns)
    class KeepRunning(fm.Voice):
        render=ns['render']
    T=pt.build();q={int(x['midi']):x for x in read('QUANTIZATION.csv')};rows=[]
    for n in NOTES:
        stop=round(float(q[n]['natural_held_zero_s_model'])*FS)
        normal=fm.Voice(T);normal.note_on(n,100);hyp=KeepRunning(T);hyp.note_on(n,100)
        offset=0;revival_count=0;first=None;last=None;max_rms=0.;max_peak=0;delta=0
        while offset<20*FS:
            y=hyp.render(4800);actual=normal.render(4800)
            if offset<stop:
                count=min(len(y),stop-offset);delta+=int(np.count_nonzero(y[:count]!=actual[:count]))
            ids=np.flatnonzero((np.arange(len(y))+offset>=stop)&(y!=0))
            if len(ids):
                first=offset+int(ids[0]) if first is None else first;last=offset+int(ids[-1]);revival_count+=len(ids)
            for i in range(0,len(y),480):
                if offset+i>=stop:
                    max_rms=max(max_rms,rms(y[i:i+480]));max_peak=max(max_peak,int(abs(y[i:i+480]).max()))
            offset+=len(y)
        assert delta==0
        rows.append({'midi':n,'actual_model_stop_s':stop/FS,'model_exact_until_stop':True,'counterfactual_nonzero_after_stop':revival_count,'counterfactual_first_after_stop_s':None if first is None else first/FS,'counterfactual_last_after_stop_s':None if last is None else (last+1)/FS,'counterfactual_max_10ms_rms_dbfs_after_stop':db(max_rms),'counterfactual_peak_after_stop':max_peak,'evidence':'diagnostic modified model only; no actual RTL or production change'})
        print('TAIL PROBE',n,'revival samples',revival_count,'max RMS',round(db(max_rms),2),flush=True)
    table('TAIL_REVIVAL_COUNTERFACTUAL.csv',rows)
    dump(A/'TAIL_PROBE.json',{'status':'PASS','time':now(),'scope':'Diagnostic model with only early all-gated IDLE disabled, 20s hold; no production change; not audible output of current RTL. Primary unmodified-model stop is independently recorded.','source_sha256':sha(R/'tools/fpga_piano_model.py'),'exact_until_stop':True,'notes_with_later_nonzero':[x['midi'] for x in rows if x['counterfactual_nonzero_after_stop']],'results':rows})

if __name__=='__main__':main()
