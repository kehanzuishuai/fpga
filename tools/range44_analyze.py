"""44-note fixed-point audit, measured comparison and listening artifacts."""
from pathlib import Path
import csv, json, math, os, sys, wave
import numpy as np
from range44_run import R,A,O,FS,NOTES,sha,now,dump,protected
import piano_tables as pt
import fpga_piano_model as fm

def table(name, rows):
    with (O/name).open('w',encoding='utf-8-sig',newline='') as f:
        w=csv.DictWriter(f,fieldnames=list(rows[0]));w.writeheader();w.writerows(rows)
def read(name): return list(csv.DictReader((O/name).open(encoding='utf-8-sig')))
def rms(y): return float(np.sqrt(np.mean(np.asarray(y,dtype=float)**2))) if len(y) else 0.
def db(v): return 20*math.log10(max(float(v),1e-15)/(1<<23))
def ratio(a,b): return 20*math.log10(max(float(a),1e-15)/max(float(b),1e-15))
def label(n): return ['C','Cs','D','Ds','E','F','Fs','G','Gs','A','As','B'][n%12]+str(n//12-1)
def wav(path,y):
    y=np.asarray(y,dtype=np.int64);assert np.all(y>=-8388608) and np.all(y<=8388607)
    u=y.astype(np.int32).astype(np.uint32);b=np.column_stack([u&255,(u>>8)&255,(u>>16)&255]).astype(np.uint8)
    path.parent.mkdir(parents=True,exist_ok=True)
    with wave.open(str(path),'wb') as f:
        f.setparams((1,3,FS,len(y),'NONE','not compressed'));f.writeframes(b.tobytes())

class AuditVoice(fm.Voice):
    def _amp(self,level):
        a=super()._amp(level);self.batches.append({'level':level.copy(),'amp':a});return a
    def _sine(self,phase):
        w=super()._sine(phase);self.batches[-1]['wave']=w;return w

def model():
    """Natural hold, no NoteOff; zero/gating and arithmetic are model evidence."""
    T=pt.build();quant=[];curves=[];examples=[];dynamic=[]
    for note in NOTES:
        v=AuditVoice(T);v.batches=[];v.note_on(note,100);offset=0;last=-1
        pieces=[];counts={'nonzero_products_below_output_lsb':0,'positive_sum_quantized_to_zero':0,'negative_sub_lsb_sum_to_minus_one':0,'gated_partial_samples':0,'played_samples_all_gated':0,'rail_samples':0,'max_abs_product':0,'max_abs_sum':0}
        example_kinds=set()
        while offset<30*FS and v.active:
            v.batches=[];y=v.render(4800);pieces.append(y);nz=np.flatnonzero(y)
            if len(nz):last=offset+int(nz[-1])
            for i in range(0,len(y),480):
                curves.append({'midi':note,'start_s':(offset+i)/FS,'rms_dbfs':db(rms(y[i:i+480])),'peak':int(abs(y[i:i+480]).max())})
            pos=0
            for bi,b in enumerate(v.batches):
                amp=b['amp'];ww=b['wave'];size=amp.shape[1]
                if bi==len(v.batches)-1 and not v.active:
                    z=np.flatnonzero(np.all(amp==0,axis=0))
                    if len(z):size=int(z[0])+1
                amp=amp[:,:size];ww=ww[:,:size];product=amp*ww;acc=product.sum(axis=0)
                out=np.clip(acc>>18,-8388608,8388607)
                counts['nonzero_products_below_output_lsb']+=int(np.count_nonzero((product!=0)&(abs(product)<(1<<18))))
                counts['positive_sum_quantized_to_zero']+=int(np.count_nonzero((acc>0)&(acc<(1<<18))))
                counts['negative_sub_lsb_sum_to_minus_one']+=int(np.count_nonzero((acc<0)&(acc>-(1<<18))))
                counts['gated_partial_samples']+=int(np.count_nonzero(amp==0))
                counts['played_samples_all_gated']+=int(np.count_nonzero(np.all(amp==0,axis=0)))
                counts['rail_samples']+=int(np.count_nonzero(abs(out)>=8388607))
                counts['max_abs_product']=max(counts['max_abs_product'],int(abs(product).max()))
                counts['max_abs_sum']=max(counts['max_abs_sum'],int(abs(acc).max()))
                for kind,mask in [('positive_sum_to_zero',(acc>0)&(acc<(1<<18))),('all_partials_gated',np.all(amp==0,axis=0)),('nonzero_sum',(abs(acc)>=(1<<18)))]:
                    ids=np.flatnonzero(mask)
                    if kind not in example_kinds and len(ids):
                        i=int(ids[0]);examples.append({'midi':note,'kind':kind,'sample_from_loader_complete':offset+pos+i,'sum_s48':int(acc[i]),'voice_shift18':int(out[i]),'nonzero_partials':int(np.count_nonzero(amp[:,i]))});example_kinds.add(kind)
                pos+=size
            offset+=len(y)
        held=np.concatenate(pieces);dry=(held*32767)>>15
        # RMS envelope duration measured from its peak; robust to beating: last above threshold.
        env=np.array([rms(dry[i:i+480]) for i in range(0,len(dry)-479,480)])
        ip=int(np.argmax(env));peak=float(env[ip]);t={}
        for d in [20,40,60]:
            z=np.flatnonzero(env[ip:]>=peak*10**(-d/20))
            t[f'held_last_above_minus{d}db_s_model']=(ip+int(z[-1])+1)*.01 if len(z) else None
        nz16=np.flatnonzero((dry>>8)!=0)
        quant.append({'midi':note,'natural_held_zero_s_model':(last+1)/FS,'pt8211_last_nonzero_s_model':(int(nz16[-1])+1)/FS if len(nz16) else 0.,'active_at_30s':v.active,'rms_peak_time_s_model':ip*.01,**t,**counts})
        # Secondary dynamics screen is explicitly model-only; primary velocity 100 is all-RTL.
        for velocity in [40,80,100,120]:
            y=fm.render_note(T,note,velocity,FS,off_sample=None,hammer=True);g=(y*32767)>>15
            dynamic.append({'midi':note,'velocity':velocity,'rms_attack_dbfs':db(rms(g[:4800])),'rms_0p1_0p5_dbfs':db(rms(g[4800:24000])),'peak_dbfs':db(abs(g).max()),'nonzero_samples':int(np.count_nonzero(g)),'evidence':'current integer model; not additional full RTL runs'})
        print('MODEL',note,'natural zero',quant[-1]['natural_held_zero_s_model'],flush=True)
    table('HELD_DECAY_MODEL.csv',curves);table('QUANTIZATION.csv',quant);table('QUANTIZATION_EXAMPLES.csv',examples);table('VELOCITY_SCREEN_MODEL.csv',dynamic)
    dump(A/'MODEL_RUN.json',{'status':'PASS' if all(not x['active_at_30s'] and x['max_abs_sum']<(1<<47) and x['max_abs_product']<(1<<44) and not x['rail_samples'] for x in quant) else 'FAIL','time':now(),'scope':'44 fresh model renders: natural hold up to 30s, no NoteOff; durations are model times, not long RTL or physical measurements','results':quant,'input_sha256':{p:sha(R/p) for p in ['tools/fpga_piano_model.py','tools/piano_tables.py','tools/pianolib.py','src/piano_partial_voice.v','src/piano_note_loader.v','src/piano_fx.v']}})

def spectrum(y):
    y=np.asarray(y,dtype=float);w=np.hanning(len(y));s=abs(np.fft.rfft((y-y.mean())*w,131072))**2
    return np.fft.rfftfreq(131072,1/FS),s
def spectral_peak(f,s,target,tolerance=.012):
    ids=np.flatnonzero((f>target*(1-tolerance))&(f<target*(1+tolerance)))
    i=int(ids[np.argmax(s[ids])]);z=np.log(np.maximum(s[i-1:i+2],1e-30));den=z[0]-2*z[1]+z[2]
    delta=.5*(z[0]-z[2])/den if den else 0.
    return float(f[i]+np.clip(delta,-1,1)*(f[1]-f[0])),float(s[i])

def measure(note,y,chain,L):
    target=440*2**((note-69)/12);par=L.params(note,100);expected=par['inc'][0]*FS/2**28
    early=y[4800:24000];f,s=spectrum(early);f0,p1=spectral_peak(f,s,expected)
    partial=[];bands=[]
    for i,inc in enumerate(par['inc'][:15]):
        if inc:
            hz=inc*FS/2**28;fq,p=spectral_peak(f,s,hz)
            mask=abs(f-hz)<5.;bands.append(mask)
            partial.append({'midi':note,'chain':chain,'partial':i+1,'expected_hz':hz,'measured_peak_hz':fq,'band_power':float(s[mask].sum()),'peak_power':p})
    ef=float(s[bands[0]].sum());eh=float(s[np.any(bands[1:],axis=0)].sum()) if len(bands)>1 else 0.
    support=sum(abs(1200*math.log2(p['measured_peak_hz']/p['expected_hz']))<4 and p['peak_power']>s.max()*1e-5 for p in partial)
    z=early.astype(float)-np.mean(early);n=1<<(2*len(z)-1).bit_length()
    ac=np.fft.irfft(abs(np.fft.rfft(z,n))**2,n)[:len(z)]/np.arange(len(z),0,-1)
    lo=max(1,int(FS/(expected*1.08)));hi=int(FS/(expected*.92));lag=lo+int(np.argmax(ac[lo:hi+1]));confidence=float(ac[lag]/max(ac[0],1))
    reliable=abs(1200*math.log2(f0/expected))<4 and support>=2 and confidence>.3 and ef/max(s.sum(),1)>1e-5
    env=np.array([rms(y[i:i+480]) for i in range(0,len(y)-479,480)])
    onset=np.flatnonzero(y);nz_held=np.flatnonzero(y[:96000]);lastnz=int(onset[-1]) if len(onset) else -1
    mask=(np.arange(len(env))*.01>=.2)&(np.arange(len(env))*.01<=1.8)&(env>1)
    slope=float(np.polyfit(np.arange(len(env))[mask]*.01,20*np.log10(env[mask]),1)[0]) if mask.sum()>2 else float('nan')
    rows={'midi':note,'note_name':label(note),'chain':chain,'target_hz':target,'dds_partial1_hz':expected,'measured_f0_hz':f0,'tuning_cents':1200*math.log2(f0/target),'measured_minus_dds_cents':1200*math.log2(f0/expected),'f0_reliable':bool(reliable),'harmonic_support':support,'acf_confidence':confidence,'attack_rms_dbfs_0_100ms':db(rms(y[:4800])),'early_rms_dbfs_100_500ms':db(rms(early)),'held_rms_dbfs_500_1500ms':db(rms(y[24000:72000])),'tail_rms_dbfs_1900_2000ms':db(rms(y[91200:96000])),'peak_dbfs':db(abs(y).max()),'peak_integer':int(abs(y).max()),'fundamental_to_overtones_db':10*math.log10(max(ef,1e-30)/max(eh,1e-30)),'fundamental_power_fraction':ef/max(s.sum(),1e-30),'centroid_hz':float((f*s).sum()/max(s.sum(),1)),'centroid_over_f0':float((f*s).sum()/max(s.sum(),1)/f0),'decay_db_per_s_0p2_1p8':slope,'rail_samples':int(np.count_nonzero(abs(y)>=8388607)),'first_nonzero_ms':int(onset[0])*1000/FS if len(onset) else None,'last_nonzero_ms':(lastnz+1)*1000/FS,'held_nonzero_count':len(nz_held),'release_tail_last_nonzero_ms':max(0,(lastnz+1-96000)*1000/FS),'zero_count_100_500ms':int(np.count_nonzero(early==0)),'pt8211_zero_count_100_500ms':int(np.count_nonzero((early>>8)==0)),'pt8211_quantization_rms_error_dbfs':db(rms(early-((early>>8)<<8))),'dc_fraction_full_scale':float(np.mean(y)/(1<<23))}
    return rows,partial,env

def analyze():
    assert json.loads((A/'AUDIO_RUN.json').read_text())['status']=='PASS'
    L=fm.Loader(pt.build());metrics=[];parts=[];curves=[];gainrows=[];waveproof=[];loaded=[]
    model_rows={int(r['midi']):r for r in read('QUANTIZATION.csv')}
    for note in NOTES:
        d=O/'notes'/f'midi_{note:03d}';result=json.loads((d/'RESULT.json').read_text());assert result['status']=='PASS'
        params=L.params(note,100)
        for slot in range(16):
            loaded.append({'midi':note,'slot':slot,'phase_inc_28':int(params['inc'][slot]),'frequency_hz':int(params['inc'][slot])*FS/(1<<28),'breakpoints_unsigned_q4p8':';'.join(map(str,params['bp'][slot])),'release_slope_q22':int(params['rel_slope'])})
        arrays={name:np.load(d/(name+'.npy')) for name in ['voice','gain','fx']}
        assert all(len(y)==144000 for y in arrays.values())
        assert np.array_equal((arrays['voice']*32767)>>15,arrays['gain'])
        assert np.array_equal(arrays['fx'],np.loadtxt(d/'rtl_fx.txt',dtype=np.int64))
        # Ensure no unverified synthesized bytes enter the exported WAV.
        rebuilt=np.zeros(144000,dtype=np.int64)
        for line in (d/'rtl_voice.txt').read_text().splitlines():
            a=line.split()
            if a[0]=='S':rebuilt[int(a[1])]=int(a[2])
        assert np.array_equal(rebuilt,arrays['voice'])
        for chain,kind in [('fx_off','gain'),('fx_on','fx')]:
            y=arrays[kind];row,pp,env=measure(note,y,chain,L)
            row.update({k:v for k,v in model_rows[note].items() if k!='midi' and k not in row})
            row['long_model_voice_rail_samples']=int(model_rows[note]['rail_samples'])
            for threshold in [20,40,60]:
                row[f'held_decay_{threshold}db_after_peak_s_model']=float(model_rows[note][f'held_last_above_minus{threshold}db_s_model'])-float(model_rows[note]['rms_peak_time_s_model'])
            row['release_tail_censored_at_3s']=bool(y[-1]!=0 or np.any(y[-480:]!=0))
            metrics.append(row);parts.extend(pp)
            for i,e in enumerate(env):curves.append({'midi':note,'chain':chain,'start_s':i*.01,'rms_dbfs':db(e)})
            path=O/'wav'/chain/f'midi_{note:03d}_{label(note)}.wav';wav(path,y)
            waveproof.append({'midi':note,'chain':chain,'path':path.relative_to(R).as_posix(),'sha256':sha(path),'samples':len(y),'gain':'unchanged integer PCM; common 24-bit full scale; no individual normalization'})
        dry,post=arrays['gain'],arrays['fx']
        gainrows.append({'midi':note,'attack_fx_delta_db':ratio(rms(post[:4800]),rms(dry[:4800])),'early_fx_delta_db':ratio(rms(post[4800:24000]),rms(dry[4800:24000])),'held_fx_delta_db':ratio(rms(post[24000:72000]),rms(dry[24000:72000])),'peak_fx_delta_db':ratio(abs(post).max(),abs(dry).max()),'gain_shift15_zeroed_nonzero_voice_samples':int(np.count_nonzero((arrays['voice']!=0)&(dry==0))),'post_fx_all_zero':not bool(np.any(post))})
    table('NOTE_METRICS_44.csv',metrics);table('PARTIAL_SPECTRA.csv',parts);table('ENVELOPES_10MS.csv',curves);table('FX_AMPLITUDE_COMPARISON.csv',gainrows);table('LOADED_PARAMETERS_44.csv',loaded)
    dump(O/'WAV_PROVENANCE.json',{'status':'PASS','time':now(),'sample_rate':FS,'bits':24,'velocity':100,'note_off_s':2,'duration_s':3,'fresh_rtl_each_note':True,'files':waveproof})
    comparisons(metrics)
    listening(metrics)
    plots(metrics,curves)
    print('44 fresh-RTL notes measured; 88 unnormalized WAV files exported',flush=True)

def comparisons(metrics):
    adjacent=[];summaries=[];four=[];valleys=[]
    keys=['attack_rms_dbfs_0_100ms','early_rms_dbfs_100_500ms','held_rms_dbfs_500_1500ms','fundamental_to_overtones_db','centroid_over_f0']
    for chain in ['fx_off','fx_on']:
        rows={r['midi']:r for r in metrics if r['chain']==chain}
        for n in range(49,92):
            a,b=rows[n-1],rows[n];d={key:b[key]-a[key] for key in keys}
            flags=[]
            if abs(d['attack_rms_dbfs_0_100ms'])>6:flags.append('attack_RMS_step_gt_6dB')
            if abs(d['early_rms_dbfs_100_500ms'])>6:flags.append('early_RMS_step_gt_6dB')
            if abs(d['held_rms_dbfs_500_1500ms'])>6:flags.append('held_RMS_step_gt_6dB')
            if abs(d['fundamental_to_overtones_db'])>10:flags.append('fundamental_overtones_step_gt_10dB')
            cr=b['centroid_over_f0']/a['centroid_over_f0']
            if max(cr,1/cr)>1.5:flags.append('relative_centroid_ratio_gt_1p5')
            td=float(b['natural_held_zero_s_model'])/float(a['natural_held_zero_s_model'])
            if max(td,1/td)>2:flags.append('natural_decay_ratio_gt_2')
            adjacent.append({'chain':chain,'from_midi':n-1,'to_midi':n,**{'delta_'+k:v for k,v in d.items()},'measured_frequency_ratio':b['measured_f0_hz']/a['measured_f0_hz'],'centroid_normalized_ratio':cr,'natural_decay_ratio_model':td,'flags':';'.join(flags)})
        for name,lo,hi in [('A',48,79),('B',60,91)]:
            z=[rows[n] for n in range(lo,hi+1)];adj=[r for r in adjacent if r['chain']==chain and lo<=r['from_midi'] and r['to_midi']<=hi]
            flags={str(n):[] for n in range(lo,hi+1)}
            for r in z:
                if not r['f0_reliable']:flags[str(r['midi'])].append('fundamental_not_reliably_verified')
                if abs(r['tuning_cents'])>15:flags[str(r['midi'])].append('tuning_gt_15_cents')
                if r['held_nonzero_count']==0:flags[str(r['midi'])].append('silent')
                if r['rail_samples']:flags[str(r['midi'])].append('clipping')
                if float(r['natural_held_zero_s_model'])<2:flags[str(r['midi'])].append('natural_zero_before_2s')
                if r['midi'] in [87,88,89]:flags[str(r['midi'])].append('early_idle_suppresses_later_very_weak_tail_diagnostic_model')
            span=max(r['early_rms_dbfs_100_500ms'] for r in z)-min(r['early_rms_dbfs_100_500ms'] for r in z)
            four_here=[];valley_here=[]
            for n in range(lo,hi-3):
                delta=rows[n+4]['early_rms_dbfs_100_500ms']-rows[n]['early_rms_dbfs_100_500ms']
                hdelta=rows[n+4]['fundamental_to_overtones_db']-rows[n]['fundamental_to_overtones_db']
                cratio=rows[n+4]['centroid_over_f0']/rows[n]['centroid_over_f0']
                rec={'scheme':name,'chain':chain,'from_midi':n,'to_midi':n+4,'early_rms_change_db':delta,'fundamental_overtones_change_db':hdelta,'normalized_centroid_ratio':cratio,'flag':abs(delta)>9}
                four.append(rec)
                if rec['flag']:four_here.append(rec)
            for n in range(lo+4,hi-3):
                center=rows[n]['early_rms_dbfs_100_500ms'];reference=(rows[n-4]['early_rms_dbfs_100_500ms']+rows[n+4]['early_rms_dbfs_100_500ms'])/2
                rec={'scheme':name,'chain':chain,'midi':n,'neighbors':f'{n-4};{n+4}','early_rms_residual_db':center-reference,'flag':abs(center-reference)>6}
                valleys.append(rec)
                if rec['flag']:valley_here.append(rec)
            range_flags=[]
            if span>12:range_flags.append('32_note_early_RMS_span_gt_12dB')
            if four_here:range_flags.append('four_semitone_RMS_change_gt_9dB')
            if valley_here:range_flags.append('local_RMS_valley_or_peak_gt_6dB')
            summary={'scheme':name,'low':lo,'high':hi,'chain':chain,'notes':32,'silent_notes':[r['midi'] for r in z if not r['held_nonzero_count']],'unverified_f0':[r['midi'] for r in z if not r['f0_reliable']],'max_abs_tuning_cents':max(abs(r['tuning_cents']) for r in z),'attack_rms_span_db':max(r['attack_rms_dbfs_0_100ms'] for r in z)-min(r['attack_rms_dbfs_0_100ms'] for r in z),'early_rms_span_db':span,'early_rms_std_db':float(np.std([r['early_rms_dbfs_100_500ms'] for r in z])),'largest_adjacent_early_rms_db':max(abs(r['delta_early_rms_dbfs_100_500ms']) for r in adj),'largest_adjacent_attack_rms_db':max(abs(r['delta_attack_rms_dbfs_0_100ms']) for r in adj),'flagged_seams':[r for r in adj if r['flags']],'flagged_four_semitone_intervals':four_here,'flagged_local_valleys':valley_here,'range_flags':range_flags,'per_note_flags':{n:f for n,f in flags.items() if f},'natural_held_zero_range_s_model':[min(float(r['natural_held_zero_s_model']) for r in z),max(float(r['natural_held_zero_s_model']) for r in z)],'quality_screen_pass':not any(flags.values()) and not any(r['flags'] for r in adj) and not range_flags,'human_listening_accepted':False}
            summaries.append(summary)
    table('ADJACENT_COMPARISON.csv',adjacent)
    table('FOUR_SEMITONE_COMPARISON.csv',four);table('LOCAL_LOUDNESS_VALLEYS.csv',valleys)
    dump(O/'RANGE_COMPARISON.json',{'time':now(),'screen_thresholds':'Engineering screening: adjacent attack/early/held RMS >6dB, fundamental:overtones >10dB, normalized centroid ratio >1.5, natural duration ratio >2, |tuning|>15cent; 32-note early RMS span >12dB, four-semitone early RMS change >9dB, center vs mean of +/-4-semitone neighbors >6dB. Diagnostic flags, not universal psychoacoustic standards. No per-note equalization.','human_listening_status':'PENDING: objective evidence and audition files supplied; no claim of having listened or of subjective excellent sound.','schemes':summaries})
    # All 13 possible continuous 32-note windows inside 48..91, to avoid a forced A/B choice.
    windows=[]
    for lo in range(48,61):
        per={}
        for chain in ['fx_off','fx_on']:
            z=[r for r in metrics if r['chain']==chain and lo<=r['midi']<lo+32]
            adj=[r for r in adjacent if r['chain']==chain and lo<=r['from_midi'] and r['to_midi']<lo+32]
            per[chain]={'early_rms_std_db':float(np.std([r['early_rms_dbfs_100_500ms'] for r in z])),'early_rms_span_db':max(r['early_rms_dbfs_100_500ms'] for r in z)-min(r['early_rms_dbfs_100_500ms'] for r in z),'flagged_seams':sum(bool(r['flags']) for r in adj),'max_adjacent_early_rms_db':max(abs(r['delta_early_rms_dbfs_100_500ms']) for r in adj)}
        windows.append({'low':lo,'high':lo+31,**{f'{chain}_{k}':v for chain,q in per.items() for k,v in q.items()}})
    table('ALL_32_NOTE_WINDOWS.csv',windows)

def listening(metrics):
    proof=[]
    for chain,kind in [('fx_off','gain'),('fx_on','fx')]:
        ys={n:np.load(O/'notes'/f'midi_{n:03d}'/(kind+'.npy')) for n in NOTES}
        for name,order in [('all44',NOTES),('A_48_79',list(range(48,80))),('B_60_91',list(range(60,92)))]:
            # Exact 3-second per-note stream, 250ms zero separation. No edits to note PCM.
            y=np.concatenate([np.concatenate([ys[n],np.zeros(FS//4,dtype=np.int64)]) for n in order])
            p=O/'wav'/f'sequence_{name}_{chain}.wav';wav(p,y)
            proof.append({'path':p.relative_to(R).as_posix(),'midi_order':order,'note_s':3,'gap_s':.25,'sha256':sha(p)})
    # Repeated adjacent pairs make loudness/timbre seams easy to locate without normalization.
    adj=read('ADJACENT_COMPARISON.csv');focus=sorted(set(int(x['from_midi']) for x in adj if x['flags'])|{63,64,67,79,83,84,87})
    for chain,kind in [('fx_off','gain'),('fx_on','fx')]:
        order=[n for a in focus for n in [a,a+1,a,a+1]]
        if order:
            y=np.concatenate([np.concatenate([np.load(O/'notes'/f'midi_{n:03d}'/(kind+'.npy')),np.zeros(FS//4,dtype=np.int64)]) for n in order])
            p=O/'wav'/f'flagged_seam_pairs_{chain}.wav';wav(p,y);proof.append({'path':p.relative_to(R).as_posix(),'midi_order':order,'note_s':3,'gap_s':.25,'sha256':sha(p)})
    dump(O/'SEQUENCE_PROVENANCE.json',{'status':'PASS','files':proof,'all_gain':'same unnormalized 24-bit scale for all notes and chains'})

def plots(metrics,curves):
    os.environ['MPLCONFIGDIR']=str(O/'mplconfig');sys.path.insert(0,str(R/'tools/audio_vendor'))
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    fig,axes=plt.subplots(3,2,figsize=(15,11),constrained_layout=True)
    items=[('early_rms_dbfs_100_500ms','100-500ms RMS (dBFS)'),('attack_rms_dbfs_0_100ms','0-100ms attack RMS (dBFS)'),('peak_dbfs','Peak (dBFS)'),('fundamental_to_overtones_db','Fundamental / overtones (dB)'),('centroid_over_f0','Spectral centroid / f0'),('tuning_cents','Tuning error (cents)')]
    for ax,(key,title) in zip(axes.flat,items):
        for chain in ['fx_off','fx_on']:
            rr=[r for r in metrics if r['chain']==chain];ax.plot([r['midi'] for r in rr],[r[key] for r in rr],'.-',label=chain)
        ax.axvspan(48,59,color='#4c9b57',alpha=.08,label='A only');ax.axvspan(80,91,color='#c56337',alpha=.08,label='B only');ax.set(title=title,xlabel='MIDI');ax.set_xticks(range(48,92,4));ax.grid(alpha=.2);ax.legend(fontsize=8)
    fig.suptitle('44 fresh RTL notes; velocity 100, fixed common gain, 48kHz / 24bit')
    fig.savefig(O/'range44_quality.png',dpi=150);fig.savefig(O/'range44_quality.svg');plt.close(fig)
    fig,axes=plt.subplots(2,1,figsize=(14,8),constrained_layout=True)
    q=read('QUANTIZATION.csv');axes[0].plot([int(r['midi']) for r in q],[float(r['natural_held_zero_s_model']) for r in q],'.-',label='Natural hold until digital zero (model)')
    for d in [20,40]:axes[0].plot([int(r['midi']) for r in q],[float(r[f'held_last_above_minus{d}db_s_model']) for r in q],'.-',label=f'Last 10ms RMS above peak-{d}dB (model)')
    axes[0].set(xlabel='MIDI',ylabel='Seconds',title='Continuous hold; no NoteOff, integer model');axes[0].legend();axes[0].grid(alpha=.2)
    for n in [48,60,63,64,65,72,79,84,88,91]:
        rr=[r for r in curves if r['midi']==n and r['chain']=='fx_off'];axes[1].plot([r['start_s'] for r in rr],[r['rms_dbfs'] for r in rr],label=str(n))
    axes[1].set(ylim=(-100,-5),xlabel='Seconds',ylabel='10ms RMS dBFS',title='Actual RTL: 2s held then release');axes[1].axvline(2,color='gray',ls='--');axes[1].legend(ncol=5);axes[1].grid(alpha=.2)
    fig.savefig(O/'range44_decay.png',dpi=150);fig.savefig(O/'range44_decay.svg');plt.close(fig)

if __name__=='__main__':globals()[sys.argv[1]]()
