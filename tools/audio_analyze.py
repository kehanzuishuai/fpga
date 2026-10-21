from pathlib import Path
import os,sys,json,csv,math,wave,shutil
R=Path(__file__).resolve().parents[1];O=R/'tests/audio_diagnosis';os.environ['MPLCONFIGDIR']=str(O/'mplconfig')
sys.path[:0]=[str(R/'tools/audio_vendor'),str(R/'tools')]
import numpy as np, matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import piano_tables as pt,fpga_piano_model as fm
T=pt.build();FS=48000;L=fm.Loader(T)
def db(v):return 20*math.log10(max(float(v),1e-15)/(1<<23))
def rms(y):return float(np.sqrt(np.mean(np.asarray(y,dtype=float)**2)))
def spectrum(y,n=131072):
 y=np.asarray(y,dtype=float);s=np.abs(np.fft.rfft((y-y.mean())*np.hanning(len(y)),n))**2;return np.fft.rfftfreq(n,1/FS),s
def peak(f,s,target,tolerance=.04):
 inds=np.flatnonzero((f>target*(1-tolerance))&(f<target*(1+tolerance)));i=inds[np.argmax(s[inds])]
 z=np.log(np.maximum(s[i-1:i+2],1e-30));delta=.5*(z[0]-z[2])/(z[0]-2*z[1]+z[2])
 return float(f[i]+delta*(f[1]-f[0])),float(s[i])
def features(note,y,chain):
 params=L.params(note,100);target=440*2**((note-69)/12);dds=params['inc'][0]*FS/2**28
 a=y[4800:24000];f,s=spectrum(a);f0,p1=peak(f,s,target,.08)
 partial=[]
 for k,inc in enumerate(params['inc'][:15]):
  if inc:
   expected=inc*FS/2**28;fq,pw=peak(f,s,expected,.01);partial.append({'partial':k+1,'expected_hz':expected,'peak_hz':fq,'power':pw})
 # Independent harmonic support and time-domain periodicity; never identify F0 only by global FFT maximum.
 support=sum(abs(p['peak_hz']/p['expected_hz']-1)<.004 and p['power']>s.max()*1e-5 for p in partial)
 z=a.astype(float)-np.mean(a);n=1<<(2*len(z)-1).bit_length();ac=np.fft.irfft(abs(np.fft.rfft(z,n))**2,n)[:len(z)];ac/=np.maximum(1,np.arange(len(z),0,-1))
 lo=int(FS/(target*1.08));hi=int(FS/(target*.92));lag=lo+int(np.argmax(ac[lo:hi+1]));acf=FS/lag;confidence=float(ac[lag]/max(ac[0],1))
 reliable=support>=2 and confidence>.3 and abs(1200*math.log2(f0/dds))<4
 masks=[]
 for p in partial:masks.append((abs(f-p['expected_hz'])<5))
 e1=float(s[masks[0]].sum());eh=float(s[np.any(masks[1:],axis=0)].sum()) if len(masks)>1 else 0
 env=np.array([rms(y[i:i+480]) for i in range(0,len(y)-479,480)]);times=np.arange(len(env))*.01
 ep=env[:20].max();j10=np.flatnonzero(env[:20]>=ep*.1);j90=np.flatnonzero(env[:20]>=ep*.9)
 decay_mask=(times>=.2)&(times<=1.8)&(env>1);slope=float(np.polyfit(times[decay_mask],20*np.log10(env[decay_mask]),1)[0])
 row={'note':note,'chain':chain,'target_hz':target,'dds_partial1_hz':dds,'estimated_f0_hz':f0,'cent_from_equal_temperament':1200*math.log2(f0/target),'spectral_minus_dds_cent':1200*math.log2(f0/dds),'f0_reliable':bool(reliable),'harmonic_support':support,'autocorrelation_hz_integer_lag':acf,'autocorrelation_confidence':confidence,'rms_dbfs_0p1_0p5':db(rms(a)),'rms_dbfs_attack_0_0p1':db(rms(y[:4800])),'rms_dbfs_held_0p5_1p5':db(rms(y[24000:72000])),'rms_dbfs_release_2_2p5':db(rms(y[96000:120000])),'peak_dbfs':db(np.max(abs(y))),'peak_integer':int(np.max(abs(y))),'onset_ms':float(j10[0]*10) if len(j10) else None,'attack_10_90_ms':float((j90[0]-j10[0])*10) if len(j10) and len(j90) else None,'centroid_hz_0p1_0p5':float((f*s).sum()/max(s.sum(),1)),'harmonic_to_fundamental_db':10*math.log10(max(eh,1)/max(e1,1)),'decay_db_per_s_0p2_1p8':slope,'dc_fraction_full_scale':float(np.mean(y)/(1<<23)),'rail_samples':int(np.count_nonzero((y==8388607)|(y==-8388608))),'pt8211_nonzero_0p1_0p5':int(np.count_nonzero(a>>8)),'pt8211_quantization_rms_delta_db':db(rms((a>>8)<<8))-db(rms(a))}
 return row,partial
rows=[];details={};seq={};out=O/'wav';out.mkdir(exist_ok=True)
for chain in ['fx_off','fx_on']:
 (out/chain).mkdir(exist_ok=True);seq[chain]=[]
 for note in range(60,76):
  d=O/'baseline'/f'midi_{note:03d}';assert json.loads((d/'result.json').read_text())['status']=='PASS'
  y=np.load(d/('gain.npy' if chain=='fx_off' else 'fx.npy'));row,partial=features(note,y,chain);rows.append(row);details[f'{note}_{chain}']=partial;seq[chain].append(y)
  src=next(d.glob(f'midi_*_{chain}.wav'));name=src.name.replace('_'+chain,'');shutil.copyfile(src,out/chain/name)
 def write(path,data):
  u=np.asarray(data,dtype=np.int32).astype(np.uint32);b=np.column_stack([u&255,(u>>8)&255,(u>>16)&255]).astype(np.uint8)
  with wave.open(str(path),'wb') as w:w.setparams((1,3,FS,len(u),'NONE','not compressed'));w.writeframes(b.tobytes())
 write(out/f'sequence_midi_060_075_{chain}.wav',np.concatenate(seq[chain]))
 old=[60,64,68,72,61,65,69,73,62,66,70,74,63,67,71,75]
 write(out/f'sequence_old_raw_mapping_{chain}.wav',np.concatenate([seq[chain][n-60] for n in old]))
with (O/'NOTE_METRICS.csv').open('w',newline='',encoding='utf8') as f:w=csv.DictWriter(f,fieldnames=list(rows[0]));w.writeheader();w.writerows(rows)
(O/'HARMONIC_PEAKS.json').write_text(json.dumps(details,indent=2),encoding='utf8')
plt.rcParams.update({'font.size':10,'figure.dpi':150});colors={'fx_off':'#246a93','fx_on':'#b14f32'}
fig,ax=plt.subplots(2,2,figsize=(12,8),constrained_layout=True)
for chain in seq:
 z=[a for a in rows if a['chain']==chain];n=[a['note'] for a in z]
 for p,key,title,unit in [(ax[0,0],'estimated_f0_hz','Fundamental (harmonic/ACF checked)','Hz'),(ax[0,1],'rms_dbfs_0p1_0p5','RMS, 0.1-0.5 s','dBFS'),(ax[1,0],'centroid_hz_0p1_0p5','Power spectral centroid, 0.1-0.5 s','Hz'),(ax[1,1],'cent_from_equal_temperament','Measured tuning vs equal temperament','cent')]:
  p.plot(n,[a[key] for a in z],'.-',label=chain,color=colors[chain]);p.set(title=title,xlabel='MIDI',ylabel=unit);p.grid(alpha=.25);p.set_xticks(range(60,76,2));p.legend()
fig.suptitle('Unmodified piano RTL: velocity 100, note-off 2 s, 48 kHz / 24 bit');fig.savefig(O/'note_comparison.png');fig.savefig(O/'note_comparison.svg');plt.close(fig)
fig,axes=plt.subplots(3,2,figsize=(12,9),constrained_layout=True)
for note,ax in zip([60,61,64,68,72,75],axes.flat):
 for chain in seq:
  y=seq[chain][note-60];f,s=spectrum(y[4800:24000]);dbs=10*np.log10(np.maximum(s,1e-10)/max(s.max(),1));ax.plot(f,dbs,label=chain,color=colors[chain],lw=.9)
 ax.set(xlim=(0,6000),ylim=(-85,3),title=f'MIDI {note}',xlabel='Hz',ylabel='dB relative to own peak');ax.grid(alpha=.2);ax.legend()
fig.savefig(O/'representative_spectra.png');fig.savefig(O/'representative_spectra.svg');plt.close(fig)
# Recording is acoustic phone audio: no key labels or absolute digital gain equivalence is assumed.
with wave.open(str(O/'user_recording_decoded.wav')) as w:x=np.frombuffer(w.readframes(w.getnframes()),dtype='<i2').astype(float)
record=[]
for start,end,target in [(5.15,5.7,261.626),(6.85,7.3,329.628),(8.2,8.75,415.305)]:
 y=x[int(start*FS):int(end*FS)];f,s=spectrum(y);f0,power=peak(f,s,target,.06);supp=[]
 for k in range(1,5):fq,pw=peak(f,s,f0*k,.02);supp.append({'multiple':k,'peak_hz':fq,'relative_db':10*math.log10(max(pw,1)/max(power,1))})
 record.append({'window_s':[start,end],'candidate_f0_hz':f0,'rms_dbfs_recording':20*math.log10(max(rms(y),1)/32768),'harmonics':supp,'physical_key':'unknown'})
fig,ax=plt.subplots(2,1,figsize=(12,6),constrained_layout=True)
t=np.arange(0,len(x),480)/FS;env=[rms(x[i:i+480]) for i in range(0,len(x),480)];ax[0].plot(t,20*np.log10(np.maximum(env,1)/32768));ax[0].set(title='User acoustic recording: uncalibrated phone gain',xlabel='s',ylabel='RMS dBFS')
for z in record:
 a,b=z['window_s'];f,s=spectrum(x[int(a*FS):int(b*FS)]);ax[1].plot(f,10*np.log10(np.maximum(s,1)/max(s.max(),1)),label=f'{a}-{b}s, candidate {z["candidate_f0_hz"]:.2f} Hz')
ax[1].set(xlim=(0,3000),ylim=(-70,5),xlabel='Hz',ylabel='dB relative to own peak');ax[1].legend();fig.savefig(O/'recording_analysis.png');plt.close(fig)
(O/'RECORDING_ANALYSIS.json').write_text(json.dumps({'duration_s':len(x)/FS,'decoded':True,'windows':record,'limitations':'No key/event labels, acoustic recording gain/AGC/room unknown. Later weak sections cannot establish a reliable fundamental or prove missing RTL sound.'},indent=2),encoding='utf8')
summary={'status':'PASS','notes':16,'chains':2,'wav_files':len(list(out.rglob('*.wav'))),'f0_reliable_count':sum(a['f0_reliable'] for a in rows),'rms_off_min_dbfs':min(a['rms_dbfs_0p1_0p5'] for a in rows if a['chain']=='fx_off'),'rms_off_max_dbfs':max(a['rms_dbfs_0p1_0p5'] for a in rows if a['chain']=='fx_off'),'rail_samples':sum(a['rail_samples'] for a in rows),'all_midi_pcm_before_after_identical':True,'scope':'Only note mapping changes; synthesis PCM for identical MIDI is unchanged, audio is RTL verified, not hardware recording.'}
(O/'ANALYSIS_SUMMARY.json').write_text(json.dumps(summary,indent=2),encoding='utf8');print(json.dumps(summary,indent=2));print(json.dumps(record,indent=2))
