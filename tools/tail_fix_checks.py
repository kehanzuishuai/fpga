from pathlib import Path
import concurrent.futures as cf
import csv,json,os,subprocess,sys,time
import numpy as np
from tail_fix_run import R,A,O,PY,IV,VV,run,sha,now,dump

def directed():
    tb=O/'tb_tail_gap.sv'
    run('tail_gap_compile',[IV,'-g2012','-s','tb_tail_gap','-o',O/'tail_gap.vvp',tb,'src/piano_partial_voice.v','sim/models/piano_roms_fast.v'])
    # Before/after uses the exact pre-edit snapshot, same bench and ROM.
    run('tail_gap_before_compile',[IV,'-g2012','-DLEGACY_VOICE','-s','tb_tail_gap','-o',O/'tail_gap_before.vvp',tb,A/'backup/src/piano_partial_voice.v','sim/models/piano_roms_fast.v'])
    p=subprocess.run([str(VV),str(O/'tail_gap_before.vvp')],cwd=R,capture_output=True,text=True)
    (O/'tail_gap_before.log').write_text(p.stdout+p.stderr,encoding='utf8')
    expected=p.returncode!=0 and 'held Voice was retired in a temporary silent gap' in p.stdout
    dump(O/'tail_gap_before.json',{'time':now(),'status':'EXPECTED_FAILURE' if expected else 'UNEXPECTED_RESULT','returncode':p.returncode,'source':str(A/'backup/src/piano_partial_voice.v'),'sha256':sha(A/'backup/src/piano_partial_voice.v'),'same_bench':str(tb)})
    assert expected,p.stdout+p.stderr
    # The legacy run writes the same VCD name; retain it before the corrected run.
    (O/'tail_gap_before.vcd').write_bytes((O/'tail_gap.vcd').read_bytes())
    run('tail_gap',[VV,O/'tail_gap.vvp'])
    import piano_tables as pt,fpga_piano_model as fm
    v=fm.Voice(pt.build());codes=np.arange(4096,dtype=np.int64)
    assert np.array_equal(v._amp(codes<<14)>0,codes<=3301)
    dump(A/'DIRECTED.json',{'status':'PASS','time':now(),'before_reproduces_bug':True,'after_assertions_pass':True,'exp_threshold_codes_checked':4096,'source_sha256':sha(R/'src/piano_partial_voice.v')})

def regression():
    run('full_regression',[PY,'-X','utf8','-B','-u','-c',"import os,runpy,sys;os.cpu_count=lambda:6;sys.argv=['sim/run_tests.py','all'];runpy.run_path('sim/run_tests.py',run_name='__main__')"])
    assert '68 tests, 0 failed' in (O/'full_regression.log').read_text()

def integration():
    import scale_decay_run as old
    old.A=A;old.O=O
    # Clone benches with fixed artifact paths so previous evidence is preserved.
    for file in ['tb_scale_mapping.sv','tb_voice_peak.sv']:
        (O/file).write_text((R/'tests/scale_decay_20261017'/file).read_text().replace('tests/scale_decay_20261017','tests/tail_fix_20261018'),encoding='utf8')
    def mapping():
        return all(old.top_sim(name,O/'tb_scale_mapping.sv','tb_scale_mapping',parameters=['-Ptb_scale_mapping.REMAPPED='+str(remap),'-Ptb_scale_mapping.BASE='+str(base)]) for name,remap,base in [('mapping_default',0,60),('mapping_permuted',1,60),('mapping_transposed',0,48)])
    def telemetry():
        return bool(run('voice_peak_compile',[IV,'-g2012','-s','tb_voice_peak','-o',O/'voice_peak.vvp',O/'tb_voice_peak.sv','src/audio_telemetry.v'])) and bool(run('voice_peak',[VV,O/'voice_peak.vvp']))
    def stress():
        dst=O/'tb_audio_stress_default.sv'
        dst.write_text((R/'tests/audio_diagnosis/tb_audio_stress_default.sv').read_text().replace('tests/continuation_20261017','tests/tail_fix_20261018'),encoding='utf8')
        return old.top_sim('stress',dst,'tb_audio_stress_default',extra=['tests/display/sim/tmds_stream_checker.sv'])
    for name,func in [('mapping',mapping),('telemetry',telemetry),('keyboard',old.keyboard),('display',old.display),('stress',stress),('syntax',old.syntax)]:
        assert func(),name
    dump(A/'INTEGRATION.json',{'status':'PASS','time':now(),'groups':['mapping default/permuted/transposed','VOICE/PEAK','keyboard/serial/status','FFT/display','32Voice+HDMI+dualDAC stress','real Gowin primitive elaboration'],'no_programming':True})

def held_one(n):
    path=O/f'held_natural_{n}.txt'
    run(f'held_natural_{n}',[VV,O/'voice.vvp',f'+note={n}','+vel=100','+on=4','+off=288000','+ticks=288020',f'+log={path}'])
    run(f'held_equivalence_{n}',[PY,'-X','utf8','-B','tools/compare_pcm.py',path,'--hammer','1'])
    return n
def held():
    assert (O/'voice.vvp').exists()
    with cf.ThreadPoolExecutor(max_workers=3) as ex:notes=list(ex.map(held_one,[87,88,89]))
    dump(A/'HELD_RTL.json',{'status':'PASS','time':now(),'notes':notes,'seconds_per_note':6,'note_off_s':6,'source_sha256':sha(R/'src/piano_partial_voice.v')})

def register():
    import xml.etree.ElementTree as ET
    gprj=R/'yinyue_fashengqi.gprj';old=[dict(x.attrib) for x in ET.parse(gprj).findall('./FileList/File')]
    doc=R/'docs/NATURAL_TAIL_FIX_20261018.md'
    doc.write_text('# 钢琴包络间隙提前退出修复\n\n实际RTL补丁已完成；旧版定向复现失败、修复版9项通过。44音/68项/联合仿真和新Gowin构建进行中，尚无修复后的可用FS。禁止自动烧录。\n',encoding='utf8')
    files=['tools/tail_fix_run.py','tools/tail_fix_analyze.py','tools/tail_fix_checks.py','tools/tail_fix_report.py','docs/NATURAL_TAIL_FIX_20261018.md','tests/tail_fix_20261018/tb_tail_gap.sv','tests/tail_fix_20261018/tb_direct_midi.sv','tests/tail_fix_20261018/tb_audio_fx.v']
    existing={x['path'] for x in old};added=[];lines=[]
    for p in files:
        assert (R/p).exists(),p
        if p not in existing:
            kind='file.verilog' if Path(p).suffix in ['.v','.sv'] else 'file.other'
            added.append({'path':p,'type':kind,'enable':'0'});lines.append(f'        <File path="{p}" type="{kind}" enable="0"/>')
    text=gprj.read_text();gprj.write_text(text.replace('    </FileList>','        <!-- Tail-gap fix verification: excluded from synthesis. -->\n'+'\n'.join(lines)+'\n    </FileList>'),encoding='utf8')
    new=[dict(x.attrib) for x in ET.parse(gprj).findall('./FileList/File')]
    assert [x for x in old if x['enable']=='1']==[x for x in new if x['enable']=='1']
    dump(A/'PROJECT_UPDATE.json',{'status':'PASS','time':now(),'added_count':len(added),'added_files':added,'enabled_count':sum(x['enable']=='1' for x in new),'production_rtl_changed':['src/piano_partial_voice.v'],'model_changed':['tools/fpga_piano_model.py']})
    status='# PROJECT_STATUS\n\n正在实际修复音源RTL中的临时静音提前退出。旧版定向测试失败、修复版9项通过；完整回归/44音/新综合时序尚在进行，当前FS是修复前的7829d74b…版本。禁止自动烧录。详见docs/NATURAL_TAIL_FIX_20261018.md。\n'
    (R/'docs/PROJECT_STATUS.md').write_text(status,encoding='utf8');(R/'README.md').write_text(status,encoding='utf8')
    print('Registered tail fix and verification; production source was already enabled.',flush=True)

def suite():
    from tail_fix_run import audio,direct
    def audio_and_hold():audio();held()
    outcomes={};failures={}
    with cf.ThreadPoolExecutor(max_workers=4) as ex:
        jobs={ex.submit(fn):name for name,fn in [('audio_and_hold',audio_and_hold),('regression',regression),('integration',integration),('direct',direct)]}
        for f in cf.as_completed(jobs):
            name=jobs[f]
            try:f.result();outcomes[name]='PASS'
            except Exception as e:outcomes[name]='FAIL';failures[name]=repr(e)
            dump(A/'SUITE_PROGRESS.json',{'time':now(),'groups':outcomes,'failures':failures});print('GROUP',name,outcomes[name],flush=True)
    assert not failures,failures
    dump(A/'SUITE.json',{'status':'PASS','time':now(),'groups':outcomes})
    from tail_fix_report import analyze,build_and_report
    analyze();build_and_report()

if __name__=='__main__':globals()[sys.argv[1]]()
