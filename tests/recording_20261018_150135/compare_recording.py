"""Connect the saved hardware defect to measured recording lines and audition.

WAV reconstructions use actual post-synthesis Loader words and the previously
bit-exact verified integer Voice/gain/FX models. They are NOT board recordings
or a gate-level simulation of the whole synth audio path.
"""
from pathlib import Path
import sys,json,csv,os,wave
import numpy as np
R=Path(__file__).resolve().parents[2];O=Path(__file__).resolve().parent
sys.path.insert(0,str(R/'tools'));sys.path.insert(0,str(R/'tools/audio_vendor'))
os.environ['MPLCONFIGDIR']=str(O/'mpl_cache')
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import piano_tables as pt
from fpga_piano_model import Voice
from note_gain_model import apply_gain
from fx_model import Fx
from pianolib import write_wav_int
FS=48000
t=pt.build()

def params(tag):
    d={n:{} for n in range(60,76)}
    for r in csv.reader((O/tag/'words.csv').open()):
        n,a,v=map(int,r);d[n][a]=v
    return d

def render(n,words):
    v=Voice(t);v.note_on(n,100)
    for s in range(16):
        v.inc[s]=words[s*32]
        v.bp[s]=[words[s*32+4+b] for b in range(21)]
    v.future_audible=np.any(v.bp<=3301,axis=0)
    held=v.render(96000);v.note_off();tail=v.render(48000)
    raw=np.concatenate([held,tail]);cal=apply_gain(raw,n);dry=(cal*32767)>>15
    return dry,Fx().process(dry)

def peak(x,guess):
    nf=262144;f=np.fft.rfftfreq(nf,1/FS)
    s=abs(np.fft.rfft(x*np.hanning(len(x)),nf));ix=np.where(abs(f-guess)<12)[0]
    k=ix[np.argmax(s[ix])];a,b,c=np.log(s[k-1:k+2]+1e-30)
    kk=k+.5*(a-c)/(a-2*b+c)
    return kk*FS/nf,float(s[k]),s,f

def main():
    before,after=params('before'),params('after')
    wav=O/'wav';wav.mkdir(exist_ok=True)
    stats=[];seq={tag:[] for tag in ['before','after']}
    for n in range(60,76):
        for tag,words in [('before',before[n]),('after',after[n])]:
            dry,fx=render(n,words)
            write_wav_int(str(wav/f'{tag}_midi_{n:03d}.wav'),fx)
            seq[tag]+=[fx,np.zeros(12000,dtype=np.int64)]
            rms=np.sqrt(np.mean(dry[4800:24000].astype(float)**2))
            stats.append({'midi':n,'variant':tag,'first_partial_hz':words[0]*FS/2**28,'min_tonal_bp':min(words[s*32+4+b] for s in range(15) for b in range(21)),
                'dry_rms_100_500ms_dbfs':float(20*np.log10(rms/2**23)) if rms else None,
                'dry_peak_dbfs':float(20*np.log10(abs(dry).max()/2**23)) if np.any(dry) else None,
                'entire_dry_zero':bool(not np.any(dry)), 'fx_hard_rail_samples':int(np.count_nonzero(abs(fx)>=8388607))})
        print('rendered',n,flush=True)
    for tag in seq:write_wav_int(str(wav/f'sequence16_{tag}_post_synth_params_model.wav'),np.concatenate(seq[tag]))
    with wave.open(str(O/'recording.wav')) as w:x=np.frombuffer(w.readframes(w.getnframes()),'<i2').astype(float)/32768
    # Eight unambiguous sounding attacks. Other key presses may be gated to
    # silence; recording alone cannot timestamp those or infer their raw bits.
    windows=[(60,1.02,1.47),(61,3.98,4.40),(64,10.12,10.55),(65,13.05,13.47),
             (68,19.42,19.85),(69,22.61,23.03),(72,28.55,28.96),(73,31.02,31.44)]
    matches=[]
    fig,ax=plt.subplots(4,2,figsize=(13,11))
    for (n,a,b),axis in zip(windows,ax.flat):
        old=before[n][0]*FS/2**28;new=after[n][0]*FS/2**28
        clip=x[int(a*FS):int(b*FS)]
        measured,amp,s,f=peak(clip,old)
        # Strength at the correct first partial vs the erroneous first partial.
        lo=s[abs(f-new)<5].max();hi=s[abs(f-old)<5].max()
        row={'midi_hypothesis':n,'window_start_s':a,'window_end_s':b,'recorded_line_hz':float(measured),
             'old_netlist_first_partial_hz':old,'correct_first_partial_hz':new,
             'measured_minus_old_hz':float(measured-old),
             'correct_to_erroneous_line_db':float(20*np.log10(max(lo,1e-15)/max(hi,1e-15))),
             'recording_midi_assignment_scope':'Spectral match to actual defective Loader; audible attacks only, not GAO raw-bit confirmation'}
        matches.append(row)
        axis.plot(f,20*np.log10(np.maximum(s/s.max(),1e-8)),linewidth=.7)
        axis.axvline(new,color='green',label=f'Correct first partial {new:.1f} Hz')
        axis.axvline(old,color='red',linestyle='--',label=f'Old netlist {old:.1f} Hz')
        axis.set_xlim(100, min(6500,max(1800,old+1000)));axis.set_ylim(-90,5)
        axis.set_title(f'Recording {a:.2f}..{b:.2f}s / MIDI {n} hypothesis');axis.legend(fontsize=7);axis.grid(alpha=.3)
    fig.supxlabel('Hz');fig.supylabel('dB relative to maximum in each recording window')
    fig.tight_layout();fig.savefig(O/'recording_vs_netlist.png',dpi=140)
    for name,rows in [('SYNTHESIS_AUDIO_COMPARISON_16',stats),('RECORDING_NETLIST_MATCHES',matches)]:
        with (O/(name+'.csv')).open('w',newline='',encoding='utf8') as h:
            c=csv.DictWriter(h,fieldnames=rows[0]);c.writeheader();c.writerows(rows)
    summary={'recording_confirmed_latest_fs_by_user':True,'recording_user_order':'left to right independently',
        'strong_attacks_spectrally_matched':len(matches),'max_line_error_hz':max(abs(r['measured_minus_old_hz']) for r in matches),
        'wrong_note_first_partial_examples':matches,'audio_stats':stats,
        'wav_scope':__doc__,'physical_silent_key_timing_and_raw_bit_identity':'not established by audio alone',
        'recording_absolute_rms_comparison':'Phone gain/room/AGC unknown; no claim of calibrated acoustic loudness'}
    (O/'AUDIO_DIAGNOSIS.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2))
    print('EIGHT RECORDING MATCHES max error',summary['max_line_error_hz'],'Hz',flush=True)

if __name__=='__main__':main()
