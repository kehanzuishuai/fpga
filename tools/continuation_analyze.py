"""Analyze only this run's completed files; never turn an incomplete run into PASS."""
from pathlib import Path
import sys,json,csv,math,wave,shutil
import numpy as np
from continue_audio_audit import R,O,A,run,PY,sha,now

def key_metrics():
    m=json.loads((O/'mapping_final.json').read_text());assert m['status']=='PASS','final mapping must complete first'
    K=O/'mapping_final'
    control=list(csv.DictReader((K/'key_chain.csv').open()))
    assert len(control)==16
    assert json.loads((O/'loader.json').read_text())['status']=='PASS','complete Loader run required'
    traces={k:[] for k in range(16)}
    for t in csv.reader((K/'key_trace.csv').open()):traces[int(t[0])].append(t)
    samples={k:[] for k in range(16)}
    for row in csv.reader((K/'key_pcm.csv').open()):samples[int(row[0])].append(list(map(int,row[2:4])))
    increments={n:[None]*16 for n in range(60,76)}
    for row in csv.reader((O/'loader_words.csv').open()):
        n,v,a,d=map(int,row)
        if 60<=n<=75 and v==100 and a%32==0:increments[n][a//32]=d
    freq={int(n):int(x) for n,x in __import__('re').findall(r"7'd(\d+):\s+phase_inc_48k\s*=\s*32'd(\d+)",(R/'src/note_freq_table.v').read_text())}
    rows=[]
    for ctrl in control:
        k=int(ctrl['raw_bit']);n=60+k;y=np.array(samples[k],dtype=np.int64)
        assert y.shape==(4096,2),y.shape
        assert all(v is not None for v in increments[n]),'missing actual Loader increment'
        row={name:int(value) for name,value in ctrl.items()}
        scan_mask=confirmed_mask=mapped_mask=0
        writes=[t for t in traces[k] if t[2]=='WRITE'];alloc=[t for t in traces[k] if t[2]=='ALLOC']
        for t in traces[k]:
            if t[2]=='SCAN':scan_mask|=int(t[3],16);confirmed_mask|=int(t[4],16)
            if t[2]=='MAP':mapped_mask|=int(t[4],16)
        assert scan_mask==confirmed_mask==mapped_mask==(1<<k)
        assert len(writes)==2 and [int(t[3]) for t in writes]==[1,0] and all(int(t[4])==n for t in writes)
        assert len(alloc)==1 and int(alloc[0][4])==n
        row.update(scan_observed_hex=f'{scan_mask:04x}',confirmed_observed_hex=f'{confirmed_mask:04x}',mapper_observed_hex=f'{mapped_mask:04x}',actual_midi=int(alloc[0][4]),fifo_write_on=1,fifo_write_off=1,allocated_voice=int(alloc[0][3]),loader_requests=1)
        row.update(expected_raw_hex=f'{1<<k:04x}',expected_midi=n,expected_base_phase_inc=freq[n],loader_partial1_inc=increments[n][0],loaded_nonzero_tonal_partials=sum(x!=0 for x in increments[n][:15]),pcm_samples=len(y),active_ms=row['active_cycles']/12288)
        for j,stage in enumerate(['pre_fx','post_fx']):
            x=y[:,j];row.update({stage+'_peak':int(abs(x).max()),stage+'_rms':float(np.sqrt(np.mean(x.astype(float)**2))),stage+'_nonzero':int(np.count_nonzero(x))})
        row['pt8211_nonzero_samples']=int(np.count_nonzero(y[:,1]>>8))
        assert row['pre_fx_nonzero']>0 and row['post_fx_nonzero']>0 and row['loaded_nonzero_tonal_partials']>0
        rows.append(row)
    with (O/'KEY_DIAGNOSTIC_TABLE.csv').open('w',newline='',encoding='utf8') as f:
        w=csv.DictWriter(f,fieldnames=list(rows[0]));w.writeheader();w.writerows(rows)
    (O/'KEY_DIAGNOSTIC_TABLE.json').write_text(json.dumps({'status':'PASS','time':now(),'scope':'Actual default top, assumed serial BFM, velocity100, same 4096-sample held window; frame traces in mapping_final/key_trace.csv; PT8211 both channels and I2S frames compared exactly in TB','rows':rows},indent=2),encoding='utf8')
    print('PASS full 16-key diagnostic table, 4096 samples per key')

def notes_analysis():
    result=json.loads((O/'notes/RESULTS.json').read_text());assert result['status']=='PASS' and len(result['results'])==21
    # The first invocation logged through the central ledger; materialize exact
    # copies at the per-note paths referenced by result.json as well.
    for n in [r['note'] for r in result['results']]:
        for stage in ['sim','equivalence','fx_sim']:
            src=O/f'note_baseline_midi_{n:03d}_{stage}.log'
            dst=O/f'notes/baseline/midi_{n:03d}/{stage}.log'
            if src.exists():shutil.copyfile(src,dst)
    assert all(np.array_equal(np.load(O/f'notes/baseline/midi_{n:03d}/{kind}.npy'),np.load(R/f'tests/audio_diagnosis/baseline/midi_{n:03d}/{kind}.npy')) for n in range(60,76) for kind in ['voice','gain','fx'])
    # Decode the verified original m4a anew, with an existing local executable.
    ff=R/'tools/audio_vendor/imageio_ffmpeg/binaries/ffmpeg-win-x86_64-v7.1.exe'
    assert run('recording_decode',[ff,'-nostdin','-y','-i',R/'tests/audio_diagnosis/user_recording.m4a','-ac','1','-ar','48000','-c:a','pcm_s16le',O/'user_recording_decoded.wav'])
    p=R/'tools/audio_analyze.py'
    s=p.read_text().replace("O=R/'tests/audio_diagnosis'","O=R/'tests/continuation_20261017'").replace("d=O/'baseline'/","d=O/'notes'/'baseline'/")
    s=s.replace("'scope':'Only note mapping changes; synthesis PCM for identical MIDI is unchanged, audio is RTL verified, not hardware recording.'","'scope':'This run changes diagnostics only; current MIDI60..75 voice/gain/FX arrays independently compared equal to backed historical baseline; physical output and key order remain unverified.'")
    exec(compile(s,str(p),'exec'),{'__file__':str(p),'__name__':'__main__'})
    summary=json.loads((O/'ANALYSIS_SUMMARY.json').read_text());assert summary['f0_reliable_count']==32 and summary['rail_samples']==0

if __name__=='__main__':globals()[sys.argv[1]]()
