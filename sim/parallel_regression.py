"""Run the unchanged complete regression groups concurrently with separate outputs.

The system and stress functions originally compile to the same VVP filename.
Load two copies with only that output filename changed; their benches, stimuli,
durations, comparisons, and verdicts remain the originals.
"""
from pathlib import Path
import concurrent.futures as cf
import hashlib,json,time

def run_all(core):
    root=Path(core['ROOT']);path=root/'sim/run_more.py';text=path.read_text()
    assert text.count('out = "build/tb_system.vvp"')==2
    def load(tag):
        body=text.replace('out = "build/tb_system.vvp"',f'out = "build/tb_system_{tag}.vvp"')
        scope={'__file__':str(path),'__name__':'regression_'+tag}
        exec(compile(body,str(path),'exec'),scope)
        return scope
    more=load('system');stress=load('stress');report=core['report'];compile_tb=core['compile_tb'];sh=core['sh']
    groups=[('keys',core['run_keys']),('rom',core['run_rom']),
            ('voice',lambda:core['run_voice'](core['VOICE_SHORT']+core['VOICE_LONG'],'voice')),
            ('dac_unit',lambda:more['run_dac_unit'](report,compile_tb,sh)),
            ('dac_top',lambda:more['run_dac_top'](report,compile_tb,sh)),
            ('fx',lambda:more['run_fx'](report,compile_tb,sh)),
            ('legacy',lambda:more['run_legacy'](report,compile_tb,sh)),
            ('system',lambda:more['run_system'](report,compile_tb,sh)),
            ('stress',lambda:stress['run_stress'](report,compile_tb,sh))]
    failures={};started=time.monotonic()
    with cf.ThreadPoolExecutor(max_workers=len(groups)) as ex:
        jobs={ex.submit(fn):name for name,fn in groups}
        for f in cf.as_completed(jobs):
            name=jobs[f]
            try:f.result()
            except BaseException as e:failures[name]=repr(e);report('group '+name,False,repr(e))
    record={'groups':[n for n,f in groups],'group_failures':failures,'result_count':len(core['results']),'elapsed_s':time.monotonic()-started,'original_run_more_sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'test_scenarios_shortened':False,'system_vvp':'build/tb_system_system.vvp','stress_vvp':'build/tb_system_stress.vvp','only_in_memory_run_more_change':'Separate compiled VVP filename; no changes to tests or assertions'}
    (root/'build/parallel_regression.json').write_text(json.dumps(record,indent=2),encoding='utf8')
    assert not failures,failures
    assert len(core['results'])==68,'Original complete suite must still execute exactly 68 verdicts'
