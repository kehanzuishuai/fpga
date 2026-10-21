"""Targeted post-fix RTL regression in isolated output paths; no programming."""
from pathlib import Path
import concurrent.futures as cf
import sys,os,json,subprocess,csv,hashlib,time
import numpy as np
R=Path(__file__).resolve().parents[2];O=Path(__file__).resolve().parent
sys.path.insert(0,str(R/'tools'))
IV=Path(r'D:/gaoyun/piano_v2/codex_test/tools/iverilog/bin/iverilog.exe');VV=IV.with_name('vvp.exe')
os.environ['PATH']=str(IV.parent)+os.pathsep+os.environ['PATH']
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def run(label,args):
    with (O/(label+'.log')).open('w') as f:p=subprocess.run(list(map(str,args)),cwd=R,stdout=f,stderr=subprocess.STDOUT)
    print(label,p.returncode,flush=True);assert p.returncode==0,(label,(O/(label+'.log')).read_text(errors='replace')[-1500:])

def voice():
    # Same 21 short regression cases and assertions. Only output filenames
    # change in memory; no edits or shortened scenarios in the original suite.
    out=O/'rtl_voice';out.mkdir(exist_ok=True)
    p=R/'sim/run_tests.py';text=p.read_text().replace('"build/','"tests/recording_20261018_150135/rtl_voice/')
    scope={'__file__':str(p),'__name__':'targeted_regression'}
    exec(compile(text,str(p),'exec'),scope)
    os.cpu_count=lambda:6
    scope['run_voice'](scope['VOICE_SHORT'],'voice')
    result={'status':'PASS' if all(ok for name,ok in scope['results']) else 'FAIL','count':len(scope['results']),'results':scope['results'],'original_script_sha256':sha(p),'only_in_memory_change':'isolated output filenames; same21 original short cases and assertions','long_and_other_groups_rerun':False}
    (O/'VOICE_REGRESSION.json').write_text(json.dumps(result,indent=2));assert result['status']=='PASS' and result['count']==21

def direct():
    from continue_audio_audit import sources
    from note_gain_model import GAINS
    from fx_model import Fx
    text=(R/'tests/calibration_20261018/tb_direct_midi.sv').read_text().replace('tests/calibration_20261018','tests/recording_20261018_150135')
    tb=O/'tb_direct_midi.sv';tb.write_text(text)
    files=[*sources(),tb,'sim/models/piano_roms_fast.v','sim/models/gowin_pll_stub.v','sim/models/ttp229_bfm.v','sim/models/i2s_rx_model.v','sim/tb/tb_pcm5102_i2s.v','tests/integration/video_boundary_stub.v']
    run('direct_compile',[IV,'-g2012','-s','tb_direct_midi','-o',O/'direct.vvp',*files]);run('direct',[VV,O/'direct.vvp'])
    stages=list(csv.DictReader((O/'DIRECT_STAGES.csv').open()));result=[]
    for n in range(48,92):
        run(f'direct_equivalence_{n}',[sys.executable,'-X','utf8','-B','tools/compare_pcm.py',O/f'direct_voice_{n}.txt','--hammer','1'])
        rows=[r for r in stages if int(r['midi'])==n]
        v=np.array([int(r['voice']) for r in rows]);s=np.array([int(r['mixer']) for r in rows]);g=np.array([int(r['gain']) for r in rows]);y=np.array([int(r['post_fx']) for r in rows])
        assert np.array_equal(s,np.clip((v*GAINS[n])>>13,-8388608,8388607)),('calibration',n)
        assert np.array_equal(g,(s*32767)>>15),('master',n)
        expected=Fx().process(g);assert np.array_equal(y[1:],expected[:-1]),('FX',n)
        result.append({'midi':n,'samples':len(rows),'raw_model_bit_exact':True,'gain_mixer_fx_bit_exact':True})
    (O/'DIRECT_CHAIN.json').write_text(json.dumps({'status':'PASS','notes':44,'real_voices':32,'scope':'Current RTL full synth_top, each note512held+512released samples, real PCM5102 checks; keyboard bypassed. Not a gate-level whole synth simulation.','results':result},indent=2))

def suite():
    before={str(p.relative_to(R)):sha(p) for p in (R/'src').rglob('*') if p.is_file()}
    before['yinyue_fashengqi.gprj']=sha(R/'yinyue_fashengqi.gprj')
    (O/'RTL_INPUTS.json').write_text(json.dumps(before,indent=2))
    with cf.ThreadPoolExecutor(max_workers=2) as ex:
        for f in cf.as_completed([ex.submit(run,'voice_driver',[sys.executable,'-X','utf8','-B','-u',__file__,'voice']),ex.submit(direct)]):f.result()
    assert all(sha(R/p)==h for p,h in before.items())
    (O/'RTL_SUITE.json').write_text(json.dumps({'status':'PASS','sources_unchanged':True,'groups':['21 original voice short cases','44 full synth direct MIDI cases'],'same_core_model_unchanged':True},indent=2))

if __name__=='__main__':globals()[sys.argv[1]]()
