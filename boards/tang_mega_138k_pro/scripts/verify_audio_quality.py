"""Current board audio equations/quality only; no physical DAC claims."""
from pathlib import Path
import sys,subprocess,json,math,re,wave,xml.etree.ElementTree as ET
import numpy as np
from toolchain import ROOT,discover,environment
from pcm_to_wav import write_wav

OUT=ROOT/'sim_out_visual';OUT.mkdir(exist_ok=True)
(OUT/'audio_quality_report.md').write_text('# RUNNING / INCOMPLETE\n',encoding='utf-8')
TC=discover();results=[]
def run(name,args):
    p=subprocess.run([str(a) for a in args],cwd=ROOT,env=environment(),capture_output=True,text=True,errors='replace',timeout=900)
    output=p.stdout+p.stderr;(OUT/(name+'.log')).write_text(output,encoding='utf-8')
    if p.returncode:raise RuntimeError(name+': '+output[-2500:])
    return output
def sim(name,sources,params=(),label=None):
    label=label or name;image=OUT/(label+'.vvp')
    run(label+'_compile',[TC['iverilog'],'-g2012','-I',ROOT/'src','-s',name,*params,'-o',image,*sources,ROOT/'sim'/(name+'.sv')])
    output=run(label,[TC['vvp'],image])
    if 'PASS' not in output or 'WARNING:' in output or 'FATAL' in output:raise RuntimeError(output)
    print(output,flush=True)
def main():
    for depth in (1,3,16):
        sim('tb_note_fifo',[ROOT/'src/note_event_fifo.v'],[f'-Ptb_note_fifo.DEPTH={depth}'],f'note_fifo_{depth}')
    results.append('Current note FIFO depths1/3/16 continuous/random backpressure,full,wrap and reset scoreboard PASS')
    gain_rows=0
    for n in (4,8,16,32):
      for w in (16,24):
        for master,atten in ((29491,0),(32767,2),(0,0)):
          sim('tb_mix_gain',[ROOT/'src'/p for p in ('tree_mixer.v','polyphony_gain.v','saturator.v')],
              [f'-Ptb_mix_gain.{k}={v}' for k,v in [('N',n),('W',w),('MASTER',master),('ATTEN',atten)]],f'gain_{n}_{w}_{master}_{atten}')
          rows=np.loadtxt(OUT/'gain_trace.txt',dtype=np.int64)
          for i,count,total,gain,actual in rows:
            cap=master//int(count) if count else master
            expected=(int(total)*min(int(gain),cap))>>(15+atten)
            if actual!=expected:raise RuntimeError('Python gain bit-exact mismatch')
          gain_rows+=len(rows)
    results.append(f'4/8/16/32 Voice,16/24bit,master mute/default/unity,attenuation,reset and random/extreme gain: {gain_rows} samples bit-exact PASS')
    tree=ET.parse(ROOT/'yinyue_fashengqi.gprj')
    core=[ROOT/f.attrib['path'] for f in tree.findall('.//File') if f.attrib.get('type')=='file.verilog'
          and 'gowin_pll' not in f.attrib['path'] and 'tang_mega_138k_pro_top' not in f.attrib['path']]
    sim('tb_waveform_quality',core)
    rows=np.loadtxt(OUT/'waveform_quality.txt',dtype=np.int64)
    max_lut_error=0
    for phase,sine,square,saw,triangle in rows:
        phase=int(phase);index=phase>>24
        ideal=math.floor(32767*math.sin(2*math.pi*index/256)+.5)*256
        max_lut_error=max(max_lut_error,abs(int(sine)-ideal))
        if abs(int(sine)-ideal)>256:raise RuntimeError('Quarter sine amplitude/angle mismatch')
        expected_square=-8388607 if phase>>31 else 8388607
        top=phase>>8;signed_top=top if top<8388608 else top-16777216
        expected_saw=signed_top+(1 if phase&255 and top!=8388607 else 0)
        magnitude=(phase>>8)&0x7fffff
        if phase>>31:magnitude=(~magnitude)&0x7fffff
        expected_triangle=2*magnitude-8388607
        if (square,saw,triangle)!=(expected_square,expected_saw,expected_triangle):raise RuntimeError('Waveform arithmetic boundary')
    sine=rows[:4096,1].astype(float);spectrum=np.abs(np.fft.rfft(sine))**2
    harmonic_thd=math.sqrt(float(sum(spectrum[2:21]))/spectrum[1])
    nonfundamental=math.sqrt(float(sum(spectrum[2:]))/spectrum[1])
    if nonfundamental>.008:raise RuntimeError('Sine unexpected distortion/phase-table images')
    scales=np.loadtxt(OUT/'voice_scaling.txt',dtype=np.int64)
    max_scale_error=0
    for raw,env,vel,actual in scales:
        raw,env,vel=map(int,(raw,env,vel));vq=128 if vel>=127 else vel
        expected=(((raw*env)>>21)*vq)>>10
        ideal=(raw*env*vq)>>31
        max_scale_error=max(max_scale_error,abs(int(actual)-ideal))
        if actual!=expected or abs(int(actual)-ideal)>1:raise RuntimeError('Voice scaling bit-exact/Q-format error')
    results.append(f'{len(rows)} waveform phases and{len(scales)} voice scaling/velocity boundaries PASS; LUT maxerror{max_lut_error} 24bitLSB,scale quantization<=1LSB')
    sim('tb_audio_quality',core)
    audio=np.loadtxt(OUT/'audio_quality.txt',dtype=np.int64)
    scenarios={}
    for scenario in sorted(set(audio[:,0])):
        data=audio[audio[:,0]==scenario];pcm=data[:,-1]
        endpoint=int(np.count_nonzero((pcm==8388607)|(pcm==-8388608)))
        if endpoint:raise RuntimeError('Core audio clipped')
        scenarios[int(scenario)]={'samples':len(pcm),'endpoint_clips':endpoint,'peak':int(np.max(np.abs(pcm))),
            'max_adjacent_step':int(np.max(np.abs(np.diff(pcm)))),'max_active_voices':int(max(data[:,2]))}
        write_wav(OUT/f'audio_scenario_{scenario}.wav',pcm)
    if scenarios[9]['peak']!=0:raise RuntimeError('Zero velocity silence')
    # Simultaneously started equal-phase equal-velocity voices should retain
    # mono loudness (reciprocal floor error only), not suffer fixed /32.
    mono=audio[audio[:,0]==1][:1024,-1]
    for scenario,n in ((2,4),(3,8),(4,16),(5,32)):
        poly=audio[audio[:,0]==scenario][:1024,-1]
        ratio=float(np.sqrt(np.mean(poly[512:].astype(float)**2))/np.sqrt(np.mean(mono[512:].astype(float)**2)))
        if not .995<ratio<1.005:raise RuntimeError('Single/poly normalization loudness')
        scenarios[scenario]['rms_ratio_to_single']=ratio
    startup=audio[audio[:,0]==0]
    current=(np.minimum(startup[:,4],startup[:,5])*startup[:,3])>>15
    if not np.array_equal(current,startup[:,6]):raise RuntimeError('Actual core gain/sample alignment')
    mono_window=audio[audio[:,0]==1][1024:8192,-1].astype(float)
    power=np.abs(np.fft.rfft(mono_window*np.hanning(len(mono_window))))**2
    peak=int(np.argmax(power[1:]))+1;measured=peak*48000/len(mono_window)
    if abs(measured-440)>48000/len(mono_window):raise RuntimeError('Mono DDS frequency')
    # Check exact24bit export, signed endpoints and file metadata independently.
    vector=[-8388608,-1,0,1,8388607];testwav=OUT/'pcm_roundtrip.wav';write_wav(testwav,vector)
    with wave.open(str(testwav),'rb') as f:
        if (f.getnchannels(),f.getsampwidth(),f.getframerate(),f.getnframes())!=(1,3,48000,5):raise RuntimeError('WAV metadata')
        raw=f.readframes(5)
    recovered=[int.from_bytes(raw[i:i+3],'little',signed=True) for i in range(0,len(raw),3)]
    if recovered!=vector:raise RuntimeError('24bit WAV endian/sign error')
    results.append(f'Real current core{len(scenarios)} startup/polyphony/waveform/velocity/morph/retrigger/release/reset scenarios: {len(audio)} samples,0 clipped endpoints PASS')
    results.append('Mono gain retained; equal-phase4/8/16/32 Voice RMS within0.5% ofmono;24bit WAV signed endpoint roundtrip PASS')
    for l in (2,3,4,5):
        lint=run(f'lint_gain_{l}',[TC['verilator'],'--lint-only','--Wall','--top-module','polyphony_gain',f'-GLOG2_VOICES={l}',ROOT/'src/polyphony_gain.v'])
        if '%Warning' in lint or '%Error' in lint:raise RuntimeError('Gain Verilator warning')
    results.append('polyphony_gain Verilator strict--Wall,4/8/16/32 configurations:0warnings PASS')
    command='read_verilog -sv -DSYNTHESIS src/polyphony_gain.v; hierarchy -check -top polyphony_gain; proc; opt; check -assert; stat; log AUDIO_GAIN_CHECK_COMPLETE'
    ys=run('yosys_gain',[TC['yosys'],'-Q','-T','-p',command])
    if 'Found and reported 0 problems' not in ys or 'AUDIO_GAIN_CHECK_COMPLETE\n' not in ys or 'Warning:' in ys:
        raise RuntimeError('Gain Yosys check')
    if re.search(r'\n\s+\d+\s+\$div',ys):raise RuntimeError('Runtime division was inferred')
    results.append('Gain Yosys check0problems,no runtime divider PASS')
    baseline_file=ROOT/'sim/fixtures/audio_gain_before.txt'
    baseline=None
    if baseline_file.exists():
        old=np.loadtxt(baseline_file,dtype=np.int64)
        if not np.array_equal(old[:,:4],startup[:,:4]):
            raise RuntimeError('Voice/phase/envelope raw samples changed from pre-gain fixture')
        idx=np.flatnonzero((old[:,-1]==8388607)|(old[:,-1]==-8388608)).tolist()
        baseline={'trace_samples':len(old),'clip_indices':idx,'clips':len(idx),'raw_mix_unchanged':True,
            'scope':'pre-fix accelerated post-edge sample-enable fixture, not analog measurement'}
    report={'status':'PASS','results':results,'scenarios':scenarios,'gain_samples_compared':gain_rows,
        'waveform_phases':len(rows),'scaling_vectors':len(scales),'sine_thd_first20_harmonics':harmonic_thd,
        'sine_all_nonfundamental_ratio':nonfundamental,'max_lut_error_24bit_lsb':max_lut_error,
        'max_scale_quantization_error_lsb':max_scale_error,'mono_fft_grid_frequency_hz':measured,
        'master_gain_q15':29491,'nominal_single_gain_db':20*math.log10(29491/32768),
        'baseline':baseline,'physical_validation':False}
    (OUT/'audio_quality.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
    (OUT/'audio_quality_report.md').write_text('# Audio quality offline verification\n\n'+'\n'.join('- '+r for r in results)+
        f'\n\nSine20-harmonic THD{harmonic_thd:.8%}; all nonfundamental energy ratio{nonfundamental:.6%} includes8bit phase-table hold images. Square/saw/piano harmonics are intentional; no bandlimiting or analog THD claim.\n'
        'Sample enables are accelerated in core quality tests; actual DAC clocks are checked separately. Max adjacent steps are measured, not a promise of click-free voice stealing.\n',encoding='utf-8')
    for result in results:print(result,flush=True)
    print('ALL AUDIO QUALITY CHECKS PASS',flush=True)
if __name__=='__main__':
    try:main()
    except Exception as error:
        (OUT/'audio_quality_report.md').write_text('# FAILED / INCOMPLETE\n\n'+'\n'.join(results)+'\n\n'+str(error),encoding='utf-8')
        print('FAIL',error,flush=True);sys.exit(1)
