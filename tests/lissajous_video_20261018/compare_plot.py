"""Engineering comparison using actual integer FIR coefficients, common axes."""
from pathlib import Path
import re,json,math,wave
import numpy as np
from PIL import Image,ImageDraw,ImageFont
R=Path(__file__).resolve().parents[2];O=Path(__file__).resolve().parent
old=(R/'audit/lissajous_video_20261018/visual_xy_source_before.sv').read_text()
co_old=np.array([(-1 if sg=='-' else 1)*int(v) for sg,v in re.findall(r"coefficient=(-?)16'sd(\d+)",old)],dtype=np.int64)
co_new=np.array(json.loads((O/'hilbert_coefficients_1023.json').read_text()),dtype=np.int64)
assert len(co_old)==32 and len(co_new)==512
def fir(co,p):
 h=np.zeros(2*len(co)-1,dtype=np.int64);h[::2]=co
 return np.clip(np.convolve(p,h)>>15,-32768,32767)
with wave.open(str(R/'tests/range44_20261018/wav/fx_on/midi_060_C4.wav'),'rb') as w:
 raw=np.frombuffer(w.readframes(2048),dtype=np.uint8).reshape(-1,3).astype(np.int64)
 p=raw[:,0]|(raw[:,1]<<8)|(raw[:,2]<<16);p=((p^0x800000)-0x800000)>>8
tone=np.rint(12000*np.sin(2*np.pi*261.6255653*np.arange(2048)/48000)).astype(np.int64)
im=Image.new('RGB',(1200,800),'#101b2b');d=ImageDraw.Draw(im)
font=lambda n:ImageFont.truetype('C:/Windows/Fonts/arial.ttf',n)
d.text((32,18),'Hilbert X/Y correction: same input, same axis scale',font=font(30),fill='white')
for row,(name,a) in enumerate([('C4 sine, 261.626 Hz',tone),('C4 piano PCM, attack excerpt',p)]):
 t=np.arange(1024,1536);x=a[t].astype(float);x-=x.mean()
 ys=[fir(co_old,a)[t+31].astype(float),fir(co_new,a)[t+511].astype(float)]
 ys=[y-y.mean() for y in ys];peak=max(abs(x).max(),*(abs(y).max() for y in ys),1)
 for col,y in enumerate(ys):
  x0=36+col*590;y0=95+row*330;cx=x0+270;cy=y0+150;radius=122
  d.rounded_rectangle((x0,y0-22,x0+552,y0+282),radius=10,fill='#182b40')
  for g in [-1,-.5,0,.5,1]:
   q=round(g*radius);d.line((cx-radius,cy+q,cx+radius,cy+q),fill='#33465b');d.line((cx+q,cy-radius,cx+q,cy+radius),fill='#33465b')
  xy=[(cx+round(v/peak*radius),cy-round(w/peak*radius)) for v,w in zip(x,y)]
  d.line(xy,fill='#40e7e4',width=2)
  title=('Before: 63 taps' if col==0 else 'After: 1023 taps')+' | '+name
  d.text((x0+12,y0-12),title,font=font(20),fill='white')
  if row==0:d.text((cx-126,y0+265),('Y/X=0.356 (-8.98dB)' if col==0 else 'Y/X=0.999 (-0.006dB)'),font=font(18),fill='#e6deaa')
d.text((35,764),'Computed from integer coefficients; not a board capture. Piano harmonics retain complex shapes.',font=font(19),fill='#b6c8da')
im.save(O/'hilbert_before_after.png');print('Saved hilbert_before_after.png')
