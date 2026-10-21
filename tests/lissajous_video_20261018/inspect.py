from pathlib import Path
import sys,json,re,subprocess,wave
R=Path(__file__).resolve().parents[2];O=Path(__file__).resolve().parent
import numpy as np
from PIL import Image,ImageDraw
files=sorted(O.glob('frame_*.png'));sheet=Image.new('RGB',(1050,4*430),'#20242a');draw=ImageDraw.Draw(sheet)
for i,p in enumerate(files):
 im=Image.open(p).crop((170,250,540,680)).resize((350,407));xx=(i%3)*350;yy=(i//3)*430;sheet.paste(im,(xx,yy+23));draw.text((xx+8,yy+4),f'{(i+0.5)/2:.2f}s',fill='white')
sheet.save(O/'trajectory_contact_sheet.png')
coeff=np.array([int(v) for v in re.findall(r'coefficient=(-?)(?:16\x27sd)(\d+)',(R/'src/display/visual_xy_source.sv').read_text()) for v in []]) if False else np.array(json.loads((R/'tests/display_upgrade_20261018/reference/hilbert_coefficients.json').read_text()))
freqs=[130.8128,261.6256,440,523.2511,1046.5023,1567.9817]
response=[]
for f in freqs:
 h=np.sum(coeff*np.exp(-2j*np.pi*f/48000*np.arange(32)*2))/32768
 response.append({'Hz':f,'Y_over_X':float(abs(h)),'Y_gain_dB':float(20*np.log10(abs(h))),'relative_phase_deg':float(np.angle(h*np.exp(2j*np.pi*f*31/48000),deg=True))})
(O/'hilbert_response_before.json').write_text(json.dumps(response,indent=2));print(json.dumps(response,indent=2))
ff=R/'tools/audio_vendor/imageio_ffmpeg/binaries/ffmpeg-win-x86_64-v7.1.exe'
p=subprocess.run([str(ff),'-hide_banner','-loglevel','error','-y','-i',r'C:/Users/Yan Guyao/Documents/xwechat_files/wxid_jzxtufy9t9g622_b3bc/msg/video/2026-10/67d390becf9b1005fe8610f6b62cd805.mp4','-vn','-ar','48000','-ac','1',str(O/'recording.wav')],capture_output=True);assert p.returncode==0,p.stderr
with wave.open(str(O/'recording.wav'),'rb') as f:a=np.frombuffer(f.readframes(f.getnframes()),dtype='<i2').astype(float)
for t in [0,1,2,3,4]:
 q=a[t*48000:(t+1)*48000];amp=abs(np.fft.rfft(q*np.hanning(len(q))));peaks=np.argsort(amp[50:4000])[-5:]+50;print('Audio',t,'s dominant Hz:',peaks[::-1].tolist())
