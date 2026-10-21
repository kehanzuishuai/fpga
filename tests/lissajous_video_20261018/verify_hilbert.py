from pathlib import Path
import sys,json,subprocess,math,hashlib
import numpy as np
R=Path(__file__).resolve().parents[2];O=Path(__file__).resolve().parent
IV=Path(r'D:/gaoyun/piano_v2/codex_test/tools/iverilog/bin/iverilog.exe');VV=IV.with_name('vvp.exe')
co=np.array(json.loads((O/'hilbert_coefficients_1023.json').read_text()),dtype=np.int64)
freqs=[130.81278265,261.6255653,440.0,1567.9817439,20000.0]
a=[]
for block,f in enumerate(freqs):
 for k in range(2048):
  n=block*2048+k;p=round(12000*math.sin(2*math.pi*f*n/48000));x=round(100*math.sin(2*math.pi*1000*n/48000));y=round(50*math.cos(2*math.pi*1000*n/48000));a.append((int(block==4),p,x,y))
a=np.array(a,dtype=np.int64)
(O/'stimulus.hex').write_text(''.join(f'{(int(m)<<48)|((int(p)&65535)<<32)|((int(x)&65535)<<16)|(int(y)&65535):013x}\n' for m,p,x,y in a))
tb=(R/'ref/display_upgrade_20261018/sim/tb_xy_source.sv').read_text()
tb=tb.replace('sim_out_visual/xy_source.hex','tests/lissajous_video_20261018/stimulus.hex').replace('sim_out_visual/xy_source.txt','tests/lissajous_video_20261018/output.txt').replace('8191','10239').replace('8192','10240').replace('-63','-1023').replace('repeat(40)','repeat(140)')
(O/'tb_xy_source.sv').write_text(tb)
for label,args in [('compile',[IV,'-g2012','-s','tb_xy_source','-o',O/'source.vvp',O/'tb_xy_source.sv',R/'src/display/visual_xy_source.sv']),('run',[VV,O/'source.vvp'])]:
 p=subprocess.run(list(map(str,args)),cwd=R,stdout=subprocess.PIPE,stderr=subprocess.STDOUT);(O/(label+'.log')).write_bytes(p.stdout);print(label,p.returncode,flush=True);assert p.returncode==0,p.stdout[-2000:]
rows=np.loadtxt(O/'output.txt',dtype=np.int64);seen=rows[rows[:,0]<len(a)];assert len(seen)==len(a)-1023
for i,m,p,x,y in seen:
 ref=a[i];hy=int(np.dot(a[i-2*np.arange(512),1],co))>>15;hy=max(-32768,min(32767,hy))
 ex=(int(ref[2]),int(ref[3])) if ref[0] else (int(a[i-511,1]),hy)
 assert (m,p,x,y)==(int(ref[0]),int(ref[1]),*ex),(i,(m,p,x,y),(ref,*ex))
metrics=[]
for block,f in enumerate(freqs[:4]):
 q=seen[(seen[:,0]>=block*2048+1024)&(seen[:,0]<(block+1)*2048)]
 n=q[:,0];basis=np.stack([np.sin(2*np.pi*f*n/48000),np.cos(2*np.pi*f*n/48000),np.ones(len(n))],axis=1)
 bx=np.linalg.lstsq(basis,q[:,3],rcond=None)[0];by=np.linalg.lstsq(basis,q[:,4],rcond=None)[0]
 ratio=float(np.hypot(*by[:2])/np.hypot(*bx[:2]));phase=float((np.angle(by[0]+1j*by[1])-np.angle(bx[0]+1j*bx[1]))*180/np.pi);phase=(phase+180)%360-180
 assert .985<ratio<1.015 and abs(phase+90)<.2,(f,ratio,phase)
 metrics.append({'Hz':f,'fitted_Y_over_X':ratio,'relative_phase_deg':phase})
response=[]
for note in range(48,92):
 f=440*2**((note-69)/12);h=np.sum(co*np.exp(-2j*np.pi*f/48000*np.arange(512)*2))/32768
 ratio=abs(h);phase=float(np.angle(h*np.exp(2j*np.pi*f*511/48000),deg=True));assert .985<ratio<1.015 and abs(phase+90)<.001
 response.append({'MIDI':note,'Hz':f,'Y_over_X':float(ratio),'Y_gain_dB':float(20*np.log10(ratio)),'phase_deg':phase})
(O/'response_44.json').write_text(json.dumps(response,indent=2))
(O/'response_44.csv').write_text('MIDI,Hz,Y_over_X,Y_gain_dB,phase_deg\n'+''.join(','.join(str(v) for v in r.values())+'\n' for r in response))
result={'status':'PASS','actual_RTL_sample_pairs':len(seen),'warmup_samples':1024,'sample_interval_audio_clocks':256,'overruns_normal':0,'forced_overload_reports_drops':True,'sample_bit_exact_against_independent_convolution':True,'pure_tone_fitted_metrics':metrics,'response_notes':44,'source_sha256':hashlib.sha256((R/'src/display/visual_xy_source.sv').read_bytes()).hexdigest()}
(O/'HILBERT_VALIDATION.json').write_text(json.dumps(result,indent=2));print(json.dumps(result,indent=2),flush=True)
