"""Measured spectra/decay and integer precision evidence, isolated from hardware claims."""
from pathlib import Path
import csv, json, math, re, shutil, sys
import numpy as np
from scale_decay_run import R,A,O,PY,run,sha,now
import piano_tables as pt, fpga_piano_model as fm
FS=48000
def dump(name,obj): (O/name).write_text(json.dumps(obj,ensure_ascii=False,indent=2),encoding='utf8')
def table(name,rows):
    with (O/name).open('w',encoding='utf8',newline='') as f:
        w=csv.DictWriter(f,fieldnames=list(rows[0]));w.writeheader();w.writerows(rows)
def rms(y):return float(np.sqrt(np.mean(np.asarray(y,dtype=float)**2))) if len(y) else 0.0
def db(v):return 20*math.log10(max(float(v),1e-15)/(1<<23))
def provenance():
    before=json.loads((A/'BEFORE.json').read_text()); previous=json.loads((A/'backup/audit/continuation_20261017/BUILD.json').read_text())
    old=Path(r'D:\gaoyun\piano_v2_keyboard_v2\src\tang_mega_138k_pro_top.v.v')
    text=old.read_text();part=text.split('parameter [111:0] KEY_NOTE_TABLE =',1)[1].split(')(',1)[0]
    oldmap=list(reversed(list(map(int,re.findall(r"7'd(\d+)",part)[:16]))))
    pre=(A/'backup/src/tang_mega_138k_pro_top.v.v').read_text();prepart=pre.split('parameter [111:0] KEY_NOTE_TABLE =',1)[1].split(')(',1)[0]
    premap=list(reversed(list(map(int,re.findall(r"7'd(\d+)",prepart)))))
    actual=list(csv.DictReader((O/'mapping_r0_b60.csv').open(encoding='utf8')))
    assert premap==list(range(60,76)) and [int(x['midi']) for x in actual]==premap
    rows=[{'target_physical_key':i+1,'configured_raw_bit':i,'logical_key':i,'old_profile0_midi':oldmap[i],'before_this_round_midi':premap[i],'current_simulated_midi':int(actual[i]['midi']),'target_hz':440*2**((60+i-69)/12),'physical_status':'待GAO确认'} for i in range(16)]
    table('KEY_MAPPING_COMPARISON.csv',rows)
    configs=['yinyue_fashengqi.gprj','tools/build_gowin.tcl','impl/yinyue_fashengqi_process_config.json']
    assert all(not re.search(r'KEY_NOTE_TABLE|KEY_BASE_NOTE|KEY_RAW_MAP_ENABLE|KEYBOARD_PROFILE|defparam', (R/p).read_text()) for p in configs)
    saved={Path(p).as_posix():h for p,h in before['files'].items()}
    assert previous['sha256']==before['previous_fs_sha256'] and all(saved.get(Path(p).relative_to(R).as_posix())==h for p,h in previous['input_sha256'].items())
    dump('MAPPING_PROVENANCE.json',{'status':'PASS','time':now(),'old_reference':str(old),'old_sha256':sha(old),'old_profile0_midi':oldmap,'before_round_midi':premap,'actual_default_simulation_midi':[int(x['midi']) for x in actual],'override_files_checked':{p:sha(R/p) for p in configs},'override_found':False,'KEYBOARD_PROFILE':0,'KEY_RAW_MAP_ENABLE':0,'KEY_RAW_INDEX_TABLE':'fedcba9876543210 (inactive unless enabled)','KEY_BASE_NOTE':60,'USE_NOTE_TABLE':1,'KEY_MAPPING_CONFIRMED':0,'previous_fs_sha256':previous['sha256'],'previous_fs_inputs_match_snapshot':True,'reason_for_different_reports':'Source versions differ. keyboard_v2 profile0 selects a legacy permutation; audio_fix already had a profile-independent continuous table at the start of this round. This round adds an explicit logical scale base and tests, and does not claim to have newly changed an already-correct default mapping.','physical_order_confirmed':False})
    print('PASS version discrepancy resolved by actual old/new tables and previous FS input hashes')
def audio():
    old=R/'tests/continuation_20261017'; T=pt.build()
    # Reuse only unchanged algorithms/tables and recompare the saved real RTL samples.
    rels=['src/piano_partial_voice.v','src/piano_note_loader.v','src/note_freq_table.v','sim/models/piano_roms_fast.v','tools/fpga_piano_model.py','tools/piano_tables.py','tools/pianolib.py','src/piano_fx.v','tools/fx_model.py']
    metadata=json.loads((old/'note_baseline_midi_060_sim.json').read_text())
    same={p:sha(R/p)==metadata['input_sha256'][p.replace('/',chr(92))] for p in rels}
    assert all(same.values()),same
    # Load the analysis functions only (no old output/recording-generation side effects).
    p=R/'tools/audio_analyze.py'; code=p.read_text().split('rows=[];details={};seq={};')[0].replace("O=R/'tests/audio_diagnosis'","O=R/'tests/scale_decay_20261017'")
    ns={'__file__':str(p)};exec(compile(code,str(p),'exec'),ns)
    metrics=[];curve=[];detail={};sample_rows=[];proof=[]
    for n in range(60,76):
        d=O/'notes'/f'midi_{n:03d}';d.mkdir(parents=True,exist_ok=True);src=old/'notes/baseline'/f'midi_{n:03d}'
        for name in ['voice.npy','gain.npy','fx.npy','rtl_voice.txt','rtl_fx.txt','result.json']:
            shutil.copy2(src/name,d/name)
        for wav in src.glob('*.wav'):shutil.copy2(wav,d/wav.name)
        assert json.loads((d/'result.json').read_text())['status']=='PASS'
        assert run(f'recheck_voice_{n}',[PY,'-X','utf8','-B','tools/compare_pcm.py',d/'rtl_voice.txt','--hammer','1'])
        voice=np.load(d/'voice.npy');gain=np.load(d/'gain.npy');fx=np.load(d/'fx.npy')
        assert len(voice)==len(gain)==len(fx)==144000
        assert np.array_equal((voice*32767)>>15,gain)
        assert np.array_equal(np.loadtxt(d/'rtl_fx.txt',dtype=np.int64),fx)
        proof.append({'midi':n,'source':str(src),'voice_rtl_log_sha256':sha(d/'rtl_voice.txt'),'fx_rtl_log_sha256':sha(d/'rtl_fx.txt'),'voice_model_rechecked_now':True,'fx_144000_samples_equal_saved_rtl':True})
        for chain,y in [('fx_off',gain),('fx_on',fx)]:
            row,parts=ns['features'](n,y,chain);nz=np.flatnonzero(y)
            row.update(first_nonzero_sample=int(nz[0]),first_nonzero_ms=int(nz[0])*1000/FS,first_nonzero_value=int(y[nz[0]]),permanent_zero_from_sample=int(nz[-1])+1,permanent_zero_from_ms=(int(nz[-1])+1)*1000/FS,note_off_ms=2000,attack_peak_0_100ms=int(abs(y[:4800]).max()),sustain_rms_last_100ms=rms(y[91200:96000]),held_nonzero_samples=int(np.count_nonzero(y[:96000])))
            metrics.append(row);detail[f'{n}_{chain}']=parts
            for i in range(0,len(y),480):curve.append({'midi':n,'chain':chain,'start_s':i/FS,'rms':rms(y[i:i+480]),'rms_dbfs':db(rms(y[i:i+480])),'peak':int(abs(y[i:i+480]).max()),'nonzero':int(np.count_nonzero(y[i:i+480]))})
        for i in sorted(set([17,int(np.argmax(abs(voice))),95999,int(np.flatnonzero(voice)[-1]),int(np.flatnonzero(voice)[-1])+1])):
            sample_rows.append({'midi':n,'sample':i,'voice':int(voice[i]),'mixer_single_voice':int(voice[i]),'gain_product_s46':int(voice[i])*32767,'gain_shift15':int(gain[i]),'post_fx':int(fx[i])})
    table('NOTE_METRICS.csv',metrics);table('DECAY_CURVES.csv',curve);table('STAGE_EXAMPLES.csv',sample_rows);dump('HARMONIC_PEAKS.json',detail)
    dump('AUDIO_PROVENANCE.json',{'status':'PASS','time':now(),'scope':'Previously generated real RTL streams, current voice/model equivalence rechecked for every MIDI; algorithm/ROM/FX sources unchanged. Not a new 3-second RTL run. New direct-event simulation is separately recorded.','unchanged_relevant_inputs':same,'notes':proof})
    plt=ns['plt']; fig,axes=plt.subplots(2,2,figsize=(12,8),constrained_layout=True)
    for n in [60,64,68,72,73,74,75]:
        for chain,axis in [('fx_off',axes[0,0]),('fx_on',axes[0,1])]:
            x=[v for v in curve if v['midi']==n and v['chain']==chain];axis.plot([v['start_s'] for v in x],[v['rms_dbfs'] for v in x],label=str(n));axis.set(xlabel='Time (s)',ylabel='10ms RMS dBFS',title=chain,ylim=(-110,-5));axis.axvline(2,color='gray',ls='--');axis.legend(ncol=2);axis.grid(alpha=.2)
    for chain in ['fx_off','fx_on']:
        x=[v for v in metrics if v['chain']==chain];axes[1,0].plot([v['note'] for v in x],[v['estimated_f0_hz'] for v in x],'.-',label=chain);axes[1,1].plot([v['note'] for v in x],[v['rms_dbfs_0p1_0p5'] for v in x],'.-',label=chain)
    axes[1,0].set(xlabel='MIDI',ylabel='Fundamental Hz');axes[1,1].set(xlabel='MIDI',ylabel='0.1-0.5s RMS dBFS')
    for axis in axes[1,:]:axis.grid(alpha=.2);axis.legend()
    fig.savefig(O/'decay_and_pitch.png');fig.savefig(O/'decay_and_pitch.svg');plt.close(fig)
    shutil.copy2(old/'representative_spectra.png',O/'representative_spectra.png')
    assert all(r['f0_reliable'] and r['rail_samples']==0 and r['sustain_rms_last_100ms']>0 for r in metrics)
    print('PASS 16 notes, 32 WAVs, exact saved RTL streams, all 2s held intervals remain audible')
class AuditVoice(fm.Voice):
    def _amp(self,level):
        a=super()._amp(level);self.batches.append({'level':level.copy(),'amp':a});return a
    def _sine(self,phase):
        w=super()._sine(phase);self.batches[-1]['wave']=w;return w
def direct_chain():
    import fx_model
    rows=list(csv.DictReader((O/'DIRECT_STAGES.csv').open()));trace=list(csv.DictReader((O/'PARTIAL_FIXED_TRACE.csv').open()))
    assert len(trace)>30000
    for row in trace:
        d={k:int(v) for k,v in row.items()};raw=(d['exp_q18']<<6)>>(d['level_q22']>>22);off=raw-1049;gate=0 if off<=1153 else off
        assert (raw,off,gate)==(d['amp_raw'],d['amp_off'],d['amp_gated']),d
        assert d['product_s45']==d['amp_gated']*d['wave_q17'],d
    results=[]
    for n in range(60,76):
        assert run(f'direct_equivalence_{n}',[PY,'-X','utf8','-B','tools/compare_pcm.py',O/f'direct_voice_{n}.txt','--hammer','1'])
        a=[x for x in rows if int(x['midi'])==n];g=np.array([int(x['gain']) for x in a]);post=np.array([int(x['post_fx']) for x in a]);v=np.array([int(x['voice']) for x in a]);s=np.array([int(x['mixer']) for x in a]);f=fx_model.Fx().process(g)
        assert np.array_equal(v,s) and np.array_equal(g,(s*32767)>>15)
        # At the actual DAC capture phase the FX pipeline exposes the previous
        # sample's result. This latency is explicit, not hidden in the data.
        assert np.array_equal(post[1:],f[:-1]),n
        results.append({'midi':n,'stage_samples':len(a),'voice_equals_single_voice_mix':True,'gain_exact':True,'fx_exact_at_one_sample_capture_latency':True})
    dump('DIRECT_CHAIN_AUDIT.json',{'status':'PASS','partial_products_compared':len(trace),'source':'Real production 32Voice synth_top; clock12.288MHz,48kHz,velocity100; no keyboard events used','fixed_point_formula_mismatches':0,'direct_voice_model_comparisons':'Rechecked against actual new L/S logs for all16 notes','per_note':results,'limitations':'Direct injection is 512 held +512 release ticks per note, sufficient for onset/chain, not a full decay test; use separate 3s RTL streams and long hold model.'})
    print('PASS actual Partial level/exp/gate/signed multiply, Voice/Mixer/Gain/FX and all16 fresh direct voice streams')
def data_integrity():
    result=[]
    for n in range(60,76):
        d=O/'notes'/f'midi_{n:03d}';expected=np.zeros(144000,dtype=np.int64)
        for line in (d/'rtl_voice.txt').read_text().splitlines():
            a=line.split()
            if a[0]=='S' and int(a[1])<len(expected):expected[int(a[1])]=int(a[2])
        assert np.array_equal(expected,np.load(d/'voice.npy')),n
        result.append({'midi':n,'samples':len(expected),'data_equals_saved_real_RTL':True})
    dump('PCM_DATA_INTEGRITY.json',{'status':'PASS','notes':result})
    print('PASS all16 PCM arrays reconstructed from their exact real RTL logs')
def onset():
    values={};previous={};time=0;reset_time=None;events={};ids={};rows=[]
    def flush():
        nonlocal reset_time,previous
        if values.get('!')=='1' and previous.get('!')!='1':reset_time=time
        if values.get('#')=='1' and previous.get('#')!='1' and values.get('$')=='1' and values.get('%')=='1':
            note=int(values['"'],2);events[note]={'midi':note,'fifo_accept_cycle':int(round((time-reset_time)/81380))+1,'reset_release_ps':reset_time,'fifo_accept_ps':time+40690}
        previous=values.copy()
    for s in (O/'direct_midi.vcd').read_text().splitlines():
        if s.startswith('#'):flush();time=int(s[1:])
        elif s.startswith('b'):
            v,k=s[1:].split();values[k]=v
        elif s and s[0] in '01xz' and not s.startswith('$'):values[s[1:]]=s[0]
    flush()
    for d in csv.DictReader((O/'DIRECT_MIDI.csv').open()):
        n=int(d['midi']);e=events[n];first=int(d['first_pcm_cycle']);cycles=first-e['fifo_accept_cycle']
        rows.append({'midi':n,'fifo_accept_cycle':e['fifo_accept_cycle'],'first_dac_pcm_cycle':first,'latency_audio_clocks':cycles,'latency_ms_nominal_12p288MHz':cycles/12288,'first_pcm_value':int(d['first_pcm_value']),'origin':'FIFO handshake recovered from actual VCD; cycle counter from new RTL test'})
    assert len(rows)==16 and all(x['latency_audio_clocks']>0 for x in rows)
    table('ONSET_EVENT_TIMING.csv',rows);print('PASS first-PCM latency relative to actual FIFO NoteOn handshake',rows[-1])
def sequences():
    import wave
    old=[60,64,68,72,61,65,69,73,62,66,70,74,63,67,71,75];proof=[]
    for chain,kind in [('fx_off','gain'),('fx_on','fx')]:
        for name,order in [('logical_midi60_75',list(range(60,76))),('old_raw_order',old)]:
            arrays=[np.load(O/'notes'/f'midi_{n:03d}'/(kind+'.npy')) for n in order];y=np.concatenate(arrays).astype(np.int32).astype(np.uint32)
            b=np.column_stack([y&255,(y>>8)&255,(y>>16)&255]).astype(np.uint8)
            path=O/f'sequence_{name}_{chain}.wav'
            with wave.open(str(path),'wb') as f:f.setparams((1,3,FS,len(y),'NONE','not compressed'));f.writeframes(b.tobytes())
            proof.append({'path':str(path),'midi_order':order,'sha256':sha(path),'source':'Concatenation of revalidated real RTL streams; old order is raw-bit order, physical order unconfirmed'})
    dump('SEQUENCE_PROVENANCE.json',{'status':'PASS','files':proof});print('PASS 4 real-RTL chromatic/old-raw-order comparison sequences')
def long_decay():
    T=pt.build();rows=[];quant=[];pars=[];examples=[]
    for note in range(60,76):
        v=AuditVoice(T);v.note_on(note,100);v.batches=[];offset=0;last_nonzero=-1;stop_sample=None;counts={'products_nonzero_to_sub_lsb':0,'positive_acc_to_zero':0,'negative_small_acc_to_minus_one':0,'voice_rail_samples':0,'amplitude_gate_samples':0,'max_abs_product':0,'max_abs_acc':0};example_types=set()
        p=fm.Loader(T).params(note,100)
        for s in range(16):pars.append({'midi':note,'slot':s,'phase_inc_28':int(p['inc'][s]),'hz':int(p['inc'][s])*FS/(1<<28),'breakpoints_q8':';'.join(map(str,p['bp'][s])),'release_slope_q22':p['rel_slope']})
        while offset<60*FS and v.active:
            v.batches=[];y=v.render(4800);nz=np.flatnonzero(y)
            if len(nz):last_nonzero=offset+int(nz[-1])
            rows.append({'midi':note,'start_s':offset/FS,'rms':rms(y),'rms_dbfs':db(rms(y)),'peak':int(abs(y).max()),'active_after_chunk':v.active})
            pos=0
            for b in v.batches:
                amp,wave=b['amp'],b['wave'];product=amp*wave;acc=product.sum(axis=0);out=np.clip(acc>>18,-8388608,8388607)
                counts['products_nonzero_to_sub_lsb']+=int(np.count_nonzero((product!=0)&(abs(product)<(1<<18))))
                counts['positive_acc_to_zero']+=int(np.count_nonzero((acc>0)&(acc<(1<<18))))
                counts['negative_small_acc_to_minus_one']+=int(np.count_nonzero((acc<0)&(acc>-(1<<18))))
                counts['voice_rail_samples']+=int(np.count_nonzero((out==-8388608)|(out==8388607)))
                counts['amplitude_gate_samples']+=int(np.count_nonzero(amp==0))
                counts['max_abs_product']=max(counts['max_abs_product'],int(abs(product).max()))
                counts['max_abs_acc']=max(counts['max_abs_acc'],int(abs(acc).max()))
                for kind,mask in [('positive_acc_to_zero',(acc>0)&(acc<(1<<18))),('negative_floor',(acc<0)&(acc>-(1<<18))),('normal_nonzero',(abs(acc)>=(1<<18))&(out!=0)),('all_partials_gated',np.all(amp==0,axis=0))]:
                    ids=np.flatnonzero(mask)
                    if kind not in example_types and len(ids):
                        i=int(ids[0]);examples.append({'midi':note,'kind':kind,'sample_from_load_complete':offset+pos+i,'acc_s48':int(acc[i]),'voice_acc_shift18':int(out[i]),'nonzero_partials':int(np.count_nonzero(amp[:,i]))});example_types.add(kind)
                pos+=out.size
            if not v.active:stop_sample=last_nonzero+1
            offset+=len(y)
        quant.append({'midi':note,'natural_held_zero_sample_model':stop_sample,'natural_held_zero_s_model':None if stop_sample is None else stop_sample/FS,'active_at_limit':v.active,**counts})
        print('MODEL held MIDI',note,'zero_s',quant[-1]['natural_held_zero_s_model'],flush=True)
    table('HELD_DECAY_MODEL.csv',rows);table('QUANTIZATION_COUNTS.csv',quant);table('QUANTIZATION_EXAMPLES.csv',examples);table('LOADED_PARAMETERS.csv',pars)
    dump('LONG_DECAY.json',{'status':'PASS','scope':'Current bit-exact fixed-point model, continuous hold without NoteOff, max 60s; per-note 3s real RTL equivalence and long regression are separate evidence. These are model times, not hardware measurements.','results':quant,'no_overflow':all(x['max_abs_acc']<(1<<47) and x['max_abs_product']<(1<<44) and x['voice_rail_samples']==0 for x in quant)})
    assert all(not x['active_at_limit'] and x['natural_held_zero_s_model']>2 and x['voice_rail_samples']==0 for x in quant)
if __name__=='__main__':globals()[sys.argv[1]]()
