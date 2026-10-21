"""Integration and evidence for measured 44-note gain. Never programs hardware."""
from pathlib import Path
import concurrent.futures as cf
import csv,json,os,re,shutil,subprocess,sys,time
import numpy as np
R=Path(__file__).resolve().parents[2];sys.path.insert(0,str(R/'tools'))
from tail_fix_run import sha,now,dump,IV,VV,PY,evidence_inputs
O=Path(__file__).resolve().parent;A=R/'audit/calibration_20261018'

def inputs():
    return evidence_inputs() | {p.relative_to(R).as_posix():sha(p) for p in O.iterdir() if p.suffix in ['.py','.v','.sv'] or p.name=='GAIN_COEFFICIENTS_44.csv'}

def run(name,args,timeout=14400):
    args=list(map(str,args));before=inputs();start=time.monotonic()
    meta={'command':args,'cwd':str(R),'started':now(),'input_sha256':before,'status':'RUNNING'};dump(O/(name+'.json'),meta)
    env=os.environ.copy();env['PATH']=str(IV.parent)+os.pathsep+env['PATH'];env['PYTHONDONTWRITEBYTECODE']='1';env['FPGA_IVERILOG']=str(IV);env['FPGA_VVP']=str(VV)
    with (O/(name+'.log')).open('w',encoding='utf8') as f:p=subprocess.run(args,cwd=R,env=env,stdout=f,stderr=subprocess.STDOUT,timeout=timeout)
    text=(O/(name+'.log')).read_text(errors='replace');ok=p.returncode==0 and 'FATAL' not in text and '\nFAIL' not in text
    meta.update(status='PASS' if ok else 'FAIL',finished=now(),elapsed_s=time.monotonic()-start,returncode=p.returncode,inputs_unchanged=before==inputs());dump(O/(name+'.json'),meta)
    print(name,meta['status'],round(meta['elapsed_s'],1),'s',flush=True)
    assert ok,(name,text[-2000:]);return meta

def coeff():return {int(r['midi']):int(r['q13']) for r in csv.DictReader((O/'GAIN_COEFFICIENTS_44.csv').open(encoding='utf-8-sig'))}

def directed():
    q=coeff();rng=np.random.default_rng(1048);rows=[]
    for n in range(128):
        for x in [0,1,-1,255,-255,8191,-8191,8388607,-8388608,*rng.integers(-8388608,8388608,80).tolist()]:
            y=max(-8388608,min(8388607,(x*q.get(n,8192))>>13));rows.append(f'{n} {x} {y}')
    (O/'gain_vectors.txt').write_text('\n'.join(rows)+'\n')
    tb='''`timescale 1ns/1ps
module tb_gain;
reg clk=0,rst_n=0,start=0,done=0;always #5 clk=~clk;
reg[6:0] note=0;reg signed[23:0] raw=0;wire signed[23:0] y;
piano_note_gain u(clk,rst_n,start,note,done,raw,y);
integer fi,rc,n,x,expected,count=0;reg[15:0] old_gain;
initial begin
 repeat(4)@(negedge clk);rst_n=1;raw=100000;@(negedge clk);
 if(y!==24'sd100000)$fatal(1,"reset unity");
 fi=$fopen("tests/calibration_20261018/gain_vectors.txt","r");
 while(!$feof(fi))begin
  rc=$fscanf(fi,"%d %d %d",n,x,expected);
  if(rc==3)begin
   old_gain=u.active_gain;note=n;start=1;@(negedge clk);start=0;
   if(u.active_gain!==old_gain)$fatal(1,"steal changed old gain before load");
   repeat(3)@(negedge clk);
   if(u.active_gain!==old_gain)$fatal(1,"pending gain leaked");
   raw=0;done=1;@(negedge clk);done=0;raw=x;#1;
   if(y!==expected)$fatal(1,"gain mismatch note%0d raw%0d expected%0d got%0d",n,x,expected,y);
   count=count+1;
  end
 end
 rst_n=0;@(negedge clk);rst_n=1;raw=-999;#1;
 if(y!==-24'sd999)$fatal(1,"reset lost unity");
 $display("PASS gain signed rounding/saturation/unity/retarget commit/reset: %0d vectors",count);$finish;
end
endmodule
'''
    (O/'tb_gain.v').write_text(tb,encoding='utf8')
    run('gain_compile',[IV,'-g2012','-s','tb_gain','-o',O/'gain.vvp',O/'tb_gain.v',O/'piano_note_gain.v'])
    run('gain_directed',[VV,O/'gain.vvp'])
    dump(A/'GAIN_DIRECTED.json',{'status':'PASS','time':now(),'signed_vectors':len(rows),'notes':128,'edge_cases':['rounding negative','positive and negative saturation','unity outside48..91','keep old gain before load','commit new gain only at load','reset unity'],'rtl_sha256':sha(O/'piano_note_gain.v')})

def stream_one(arg):
    import fx_model
    n,vel=arg;q=coeff()[n]
    d=O/'streams'/f'midi_{n:03d}'/('primary' if vel==0 else f'vel_{vel:03d}');d.mkdir(parents=True,exist_ok=True)
    if vel==0:
        src=R/'tests/tail_fix_20261018/notes'/f'midi_{n:03d}'/'voice.npy';source_kind='fresh 3s raw Voice RTL;2s held/1s release'
    else:
        src=O/'velocity_raw'/f'midi_{n:03d}'/f'vel_{vel:03d}.npy';source_kind='1s integer source model; no NoteOff'
    raw=np.load(src);unbounded=(raw*q)>>13;cal=np.clip(unbounded,-8388608,8388607);g=(cal*32767)>>15
    inp=d/'raw_input.txt';out=d/'fx_rtl.txt';np.savetxt(inp,raw,fmt='%d')
    run(f'stream_{n}_{vel}',[VV,O/'calibrated_stream.vvp',f'+input={inp}',f'+output={out}',f'+samples={len(raw)}',f'+note={n}'])
    actual=np.loadtxt(out,dtype=np.int64);model=fx_model.Fx().process(g)
    assert np.array_equal(actual,model) and not np.any(cal!=unbounded),(n,vel)
    for name,x in [('voice',cal),('gain',g),('fx',actual)]:np.save(d/(name+'.npy'),x)
    result={'status':'PASS','midi':n,'velocity':100 if vel==0 else vel,'samples':len(raw),'source_kind':source_kind,'source_sha256':sha(src),'q13':q,'calibration_rtl':True,'fx_rtl':True,'bit_exact_samples':len(raw),'rail_samples':int(np.count_nonzero(abs(actual)>=8388607)),'calibration_saturated_samples':int(np.count_nonzero(cal!=unbounded)),'rtl_module_sha256':sha(O/'piano_note_gain.v')}
    dump(d/'RESULT.json',result);return result

def streams():
    run('calibrated_stream_compile',[IV,'-g2005','-s','tb_calibrated_stream','-o',O/'calibrated_stream.vvp',O/'tb_calibrated_stream.v',O/'piano_note_gain.v','src/piano_fx.v'])
    jobs=[(n,v) for v in [0,40,80,120] for n in range(48,92)];results=[]
    # Primary velocity100 plus40/80/120 for every pitch; all127 are additionally model screened.
    with cf.ThreadPoolExecutor(max_workers=6) as ex:
        for r in ex.map(stream_one,jobs):results.append(r);dump(A/'STREAM_PROGRESS.json',{'time':now(),'completed':len(results),'total':len(jobs)})
    assert not any(r['rail_samples'] or r['calibration_saturated_samples'] for r in results)
    dump(A/'STREAMS.json',{'status':'PASS','time':now(),'results':results,'primary_full_duration_real_voice_rtl_notes':44,'secondary_velocities_source_model_gain_fx_rtl':[40,80,120],'tested_gain_sha256':sha(O/'piano_note_gain.v'),'production_integration_validated_separately':True})

def integrate():
    import xml.etree.ElementTree as ET
    assert json.loads((R/'audit/tail_fix_20261018/TAIL_FIX_VALIDATED_PENDING_CALIBRATION.json').read_text())['status']=='PASS'
    assert json.loads((A/'VELOCITY_SCREEN.json').read_text())['status']=='PASS'
    assert json.loads((A/'GAIN_DIRECTED.json').read_text())['status']=='PASS'
    assert not (A/'BEFORE.json').exists(),'Refusing overwrite integration snapshot'
    paths=[*(R/'src').rglob('*'),R/'yinyue_fashengqi.gprj',R/'impl/yinyue_fashengqi_process_config.json',R/'tools/build_gowin.tcl',R/'tools/compare_system.py',R/'tools/fpga_piano_model.py',R/'README.md',R/'docs/PROJECT_STATUS.md',R/'impl/pnr/ao_0.fs',R/'impl/pnr/yinyue_fashengqi.tr',R/'impl/pnr/yinyue_fashengqi.rpt.txt',R/'impl/pnr/yinyue_fashengqi.pin.html',R/'impl/gwsynthesis/yinyue_fashengqi_syn.rpt.html']
    files={p.relative_to(R).as_posix():sha(p) for p in paths if p.is_file()}
    for rel in files:
        dest=A/'backup'/rel;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(R/rel,dest)
    dump(A/'BEFORE.json',{'time':now(),'files':files,'note':'Snapshot immediately before calibration integration; already contains validated natural-tail fix. Original pre-tail source/FS remain in audit/tail_fix_20261018/backup.','enabled_files':[dict(e.attrib) for e in ET.parse(R/'yinyue_fashengqi.gprj').findall('./FileList/File') if e.attrib.get('enable')=='1'],'no_auto_programming':True})
    shutil.copy2(O/'piano_note_gain.v',R/'src/piano_note_gain.v')
    p=R/'src/voice_bank.v';text=p.read_text();partial,legacy=text.split('else begin : G_LEGACY',1)
    marker='        piano_partial_voice #('
    assert partial.count(marker)==1
    block='''        // Fixed measured gain follows each raw voice; keep the old note's
        // coefficient during fade and commit only after the new loader finishes.
        wire signed [SAMPLE_W-1:0] raw_sample;
        piano_note_gain #(.SAMPLE_W(SAMPLE_W)) u_note_gain (
            .clk(clk), .rst_n(rst_n), .start(starts[g]),
            .note_in(midi_note), .load_done(ld_done[g]),
            .sample_in(raw_sample),
            .sample_out(voice_samples[g*SAMPLE_W +: SAMPLE_W])
        );

'''
    partial=partial.replace(marker,block+marker)
    old='''                    voice_samples[
                        g*SAMPLE_W
                        +: SAMPLE_W
                    ]'''
    assert partial.count(old)==1
    partial=partial.replace(old,'                    raw_sample')
    p.write_text(partial+'else begin : G_LEGACY'+legacy,encoding='utf8')
    model='''"""Per-note gain after the unchanged raw partial voice, before tree_mixer."""
from pathlib import Path
import re
import numpy as np
_rtl=(Path(__file__).resolve().parents[1]/'src/piano_note_gain.v').read_text()
GAINS={int(n):int(q) for n,q in re.findall(r"7'd(\\d+): gain_for_note = 16'd(\\d+)",_rtl)}
assert sorted(GAINS)==list(range(48,92))
def gain_for_note(note):return GAINS.get(int(note),8192)
def apply_gain(samples,note):return np.clip((np.asarray(samples,dtype=np.int64)*gain_for_note(note))>>13,-8388608,8388607)
'''
    (R/'tools/note_gain_model.py').write_text(model,encoding='utf8')
    p=R/'tools/compare_system.py';text=p.read_text();text=text.replace('from fx_model import Fx  # noqa: E402','from fx_model import Fx  # noqa: E402\nfrom note_gain_model import apply_gain')
    text=text.replace('    for ln in open(path):','    current_note = 0\n    for ln in open(path):')
    text=text.replace('        if len(f) == 5 and f[0] == "S":','        if len(f) == 4 and f[0] == "L":\n            current_note = int(f[2])\n        if len(f) == 5 and f[0] == "S":')
    text=text.replace('mix[t] += int(f[2])','mix[t] += int(apply_gain(int(f[2]), current_note))')
    p.write_text(text,encoding='utf8')
    doc=R/'docs/NOTE_GAIN_CALIBRATION_20261018.md';doc.write_text('# 44音实测响度校准\n\n生产RTL已加入补偿，综合与组合回归进行中。详见tests/calibration_20261018和audit/calibration_20261018。禁止自动烧录。\n',encoding='utf8')
    gprj=R/'yinyue_fashengqi.gprj';old=[dict(e.attrib) for e in ET.parse(gprj).findall('./FileList/File')];existing={e['path'] for e in old}
    add=[('src/piano_note_gain.v','file.verilog','1'),('tools/note_gain_model.py','file.other','0'),('docs/NOTE_GAIN_CALIBRATION_20261018.md','file.other','0'),*[(p.relative_to(R).as_posix(),'file.verilog' if p.suffix=='.v' else 'file.other','0') for p in O.iterdir() if p.suffix in ['.py','.v'] or p.name=='GAIN_COEFFICIENTS_44.csv']]
    add=[(p,k,e) for p,k,e in add if p not in existing];lines=[f'        <File path="{p}" type="{k}" enable="{e}"/>' for p,k,e in add]
    text=gprj.read_text();gprj.write_text(text.replace('    </FileList>','        <!-- Measured note gain and excluded verification artifacts. -->\n'+'\n'.join(lines)+'\n    </FileList>'),encoding='utf8')
    new=[dict(e.attrib) for e in ET.parse(gprj).findall('./FileList/File')]
    assert [e for e in new if e['enable']=='1']==[e for e in old if e['enable']=='1']+[{'path':'src/piano_note_gain.v','type':'file.verilog','enable':'1'}]
    dump(A/'PROJECT_UPDATE.json',{'status':'PASS','time':now(),'added_files':[{'path':p,'type':k,'enable':e} for p,k,e in add],'added_count':len(add),'enabled_count':sum(e['enable']=='1' for e in new),'production_rtl_changed':['src/piano_partial_voice.v','src/voice_bank.v'],'production_rtl_added':['src/piano_note_gain.v'],'no_auto_programming':True})
    status='# PROJECT_STATUS\n\n实际尾音退出修复和44音响度补偿已写入生产RTL及GPRJ。组合回归、综合/时序尚在进行；当前FS仍为修复前版本，禁止自动烧录。详见docs/NOTE_GAIN_CALIBRATION_20261018.md。\n'
    (R/'README.md').write_text(status,encoding='utf8');(R/'docs/PROJECT_STATUS.md').write_text(status,encoding='utf8')
    dump(A/'INTEGRATED.json',{'status':'PASS','time':now(),'source_sha256':{p:sha(R/p) for p in ['src/piano_partial_voice.v','src/voice_bank.v','src/piano_note_gain.v','tools/note_gain_model.py','tools/compare_system.py']}})
    print('CALIBRATION INTEGRATED INTO PRODUCTION RTL AND GPRJ',flush=True)

def gain_capture_one(n):
    d=O/'gain_capture'/f'midi_{n:03d}';d.mkdir(parents=True,exist_ok=True)
    src=R/'tests/tail_fix_20261018/notes'/f'midi_{n:03d}'/'voice.npy';raw=np.load(src)
    np.savetxt(d/'raw.txt',raw,fmt='%d')
    run(f'gain_capture_{n}',[VV,O/'gain_stream.vvp',f'+input={d/"raw.txt"}',f'+output={d/"gain_rtl.txt"}',f'+samples={len(raw)}',f'+note={n}'])
    actual=np.loadtxt(d/'gain_rtl.txt',dtype=np.int64);expected=np.clip((raw*coeff()[n])>>13,-8388608,8388607)
    assert np.array_equal(actual,expected)
    np.save(d/'calibrated_rtl.npy',actual)
    return {'midi':n,'samples':len(raw),'source_sha256':sha(src),'calibrated_rtl_sha256':sha(d/'calibrated_rtl.npy'),'bit_exact':True}

def gain_capture():
    run('gain_stream_compile',[IV,'-g2012','-s','tb_gain_stream','-o',O/'gain_stream.vvp',O/'tb_gain_stream.v',O/'piano_note_gain.v'])
    with cf.ThreadPoolExecutor(max_workers=4) as ex:results=list(ex.map(gain_capture_one,range(48,92)))
    dump(A/'GAIN_CAPTURE.json',{'status':'PASS','time':now(),'notes':44,'results':results,'rtl_sha256':sha(O/'piano_note_gain.v')})

def direct():
    from continue_audio_audit import sources
    tb=O/'tb_direct_midi.sv';tb.write_text((R/'tests/tail_fix_20261018/tb_direct_midi.sv').read_text().replace('tests/tail_fix_20261018','tests/calibration_20261018'),encoding='utf8')
    files=[*sources(),tb,'sim/models/piano_roms_fast.v','sim/models/gowin_pll_stub.v','sim/models/ttp229_bfm.v','sim/models/i2s_rx_model.v','sim/tb/tb_pcm5102_i2s.v','tests/integration/video_boundary_stub.v']
    run('direct_compile',[IV,'-g2012','-s','tb_direct_midi','-o',O/'direct.vvp',*files]);run('direct',[VV,O/'direct.vvp'])
    import fx_model
    q=coeff();stages=list(csv.DictReader((O/'DIRECT_STAGES.csv').open(encoding='utf-8-sig')));results=[]
    for n in range(48,92):
        run(f'direct_equivalence_{n}',[PY,'-X','utf8','-B','tools/compare_pcm.py',O/f'direct_voice_{n}.txt','--hammer','1'])
        z=[r for r in stages if int(r['midi'])==n]
        v=np.array([int(r['voice']) for r in z]);s=np.array([int(r['mixer']) for r in z]);g=np.array([int(r['gain']) for r in z]);y=np.array([int(r['post_fx']) for r in z])
        assert np.array_equal(s,np.clip((v*q[n])>>13,-8388608,8388607)),('calibration wiring',n)
        assert np.array_equal(g,(s*32767)>>15)
        expected=fx_model.Fx().process(g);assert np.array_equal(y[1:],expected[:-1]),('FX',n)
        results.append({'midi':n,'raw_voice_model_bit_exact':True,'calibration_mixer_master_fx_bit_exact':True,'samples':len(z)})
    dump(A/'DIRECT_CHAIN.json',{'status':'PASS','time':now(),'notes':44,'real_voices':32,'results':results,'no_auto_programming':True})

def regression():
    run('full_regression',[PY,'-X','utf8','-B','-u','-c',"import os,runpy,sys;os.cpu_count=lambda:6;sys.argv=['sim/run_tests.py','all'];runpy.run_path('sim/run_tests.py',run_name='__main__')"])
    assert '68 tests, 0 failed' in (O/'full_regression.log').read_text()

def integration():
    import scale_decay_run as old
    old.A=A;old.O=O
    for file in ['tb_scale_mapping.sv','tb_voice_peak.sv']:
        (O/file).write_text((R/'tests/scale_decay_20261017'/file).read_text().replace('tests/scale_decay_20261017','tests/calibration_20261018'),encoding='utf8')
    def mapping():
        return all(old.top_sim(name,O/'tb_scale_mapping.sv','tb_scale_mapping',parameters=['-Ptb_scale_mapping.REMAPPED='+str(remap),'-Ptb_scale_mapping.BASE='+str(base)]) for name,remap,base in [('mapping_default',0,60),('mapping_permuted',1,60),('mapping_transposed',0,48)])
    def stress():
        dst=O/'tb_audio_stress_default.sv';dst.write_text((R/'tests/audio_diagnosis/tb_audio_stress_default.sv').read_text().replace('tests/continuation_20261017','tests/calibration_20261018'),encoding='utf8')
        return old.top_sim('stress',dst,'tb_audio_stress_default',extra=['tests/display/sim/tmds_stream_checker.sv'])
    for name,fn in [('mapping',mapping),('keyboard',old.keyboard),('display',old.display),('stress',stress),('syntax',old.syntax)]:assert fn(),name
    dump(A/'INTEGRATION.json',{'status':'PASS','time':now(),'groups':['3 mappings','keyboard/status','FFT/HDMI','32Voice+dualDAC stress','Gowin primitives'],'no_auto_programming':True})

def suite():
    pending=R/'audit/tail_fix_20261018/TAIL_FIX_VALIDATED_PENDING_CALIBRATION.json'
    print('Waiting for immutable tail-fix suite to complete before changing production.',flush=True)
    while not pending.exists():time.sleep(10)
    integrate();results={};failures={}
    with cf.ThreadPoolExecutor(max_workers=3) as ex:
        jobs={ex.submit(fn):name for name,fn in [('regression',regression),('direct',direct),('integration',integration)]}
        for f in cf.as_completed(jobs):
            name=jobs[f]
            try:f.result();results[name]='PASS'
            except Exception as e:results[name]='FAIL';failures[name]=repr(e)
            dump(A/'SUITE_PROGRESS.json',{'time':now(),'groups':results,'failures':failures});print('GROUP',name,results[name],flush=True)
    assert not failures,failures
    dump(A/'SUITE.json',{'status':'PASS','time':now(),'groups':results})
    print('COMBINED CALIBRATION SUITE PASS',flush=True)

if __name__=='__main__':globals()[sys.argv[1]]()
