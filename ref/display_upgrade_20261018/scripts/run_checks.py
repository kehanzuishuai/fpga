"""Display-only upgrade regression. All writes stay in this package."""
from pathlib import Path
import sys,os,json,subprocess,math,re,hashlib,xml.etree.ElementTree as ET,shutil
import numpy as np
from PIL import Image,ImageDraw
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'sim_out_visual';OUT.mkdir(exist_ok=True)
ENV=dict(os.environ,LANG='C',LC_ALL='C',PYTHONIOENCODING='utf-8',PYTHONDONTWRITEBYTECODE='1')
ENV['PATH']='C:/Strawberry/perl/bin;'+ENV.get('PATH','')
BIN=Path('D:/fpga26/bin');TOOLS=Path(os.environ['APPDATA'])/'Python/Python313/Scripts'
PORTABLE=[ROOT/'src'/p for p in ['visual_xy_source.sv','visual_xy_plot.sv','visual_frame_store.v','visual_twiddle_rom.v',
 'visual_fft.sv','visual_raster.v','visual_labels.sv','visual_renderer.sv','visual_tmds.sv','audio_visualizer.sv']]
ALL=[ROOT/p for p in (ROOT/'rtl_sources.f').read_text().splitlines()]
results={};errors={}
def run(name,args,timeout=300):
 p=subprocess.run(list(map(str,args)),cwd=ROOT,env=ENV,capture_output=True,text=True,errors='replace',timeout=timeout)
 text=p.stdout+p.stderr;(OUT/(name+'.log')).write_text(text,encoding='utf-8')
 if p.returncode:raise RuntimeError(text[-6500:])
 return text
def check(name,fn):
 try:fn();results[name]='PASS';print(name,'PASS',flush=True)
 except Exception as e:results[name]='FAIL';errors[name]=str(e);print(name,'FAIL',str(e)[-3000:],flush=True)
def sim(name,params=()):
 image=OUT/(name+'.vvp')
 run(name+'_compile',[BIN/'iverilog.exe','-g2012','-s',name,*params,'-o',image,*PORTABLE,ROOT/'sim'/(name+'.sv')])
 text=run(name,[BIN/'vvp.exe',image],timeout=360)
 if 'PASS' not in text or 'FATAL' in text:raise RuntimeError(text)
 return text
def stimuli():
 source=[]
 for block,(freq,amp) in enumerate([(261.63,12000),(1000,12000),(8000,12000),(16000,40),(20000,80),(22000,12000),(0,1000),(1000,100)]):
  for j in range(1024):
   n=block*1024+j
   wave=1000 if block==6 else round(amp*math.sin(2*math.pi*freq*n/48000))
   xx=round(100*math.sin(2*math.pi*freq*n/48000));yy=round(50*math.cos(2*math.pi*freq*n/48000))
   source.append((int(block==7),wave,xx,yy))
 np.save(OUT/'source_reference.npy',np.array(source))
 (OUT/'xy_source.hex').write_text(''.join(f'{(m<<48)|((w&65535)<<32)|((x&65535)<<16)|(y&65535):013x}\n' for m,w,x,y in source))
 frames=[]
 for k in range(10):
  a=[]
  for i in range(512):
   t=2*math.pi*3*i/512
   x=round(10000*math.sin(t));y=round(10000*math.cos(t));mode=1
   if k==1:x=round(40*math.sin(2*math.pi*16000*i/48000));y=round(40*math.cos(2*math.pi*16000*i/48000))
   elif k==2:x=round(12000*math.sin(t));y=round(3000*math.cos(t))
   elif k==3:x=y=0
   elif k==4:x=1200;y=-2300
   elif k==5:y=x
   elif k==6:x=32767 if i%2 else -32768;y=-32768 if i%2 else 32767
   elif k==7:x=round(100*math.sin(2*math.pi*20000*i/48000));y=round(100*math.cos(2*math.pi*20000*i/48000))
   elif k==8:mode=int(i<256)
   elif k==9:x+=1200;y-=2300
   a.append((mode,x,y))
  frames.append(a)
 (OUT/'xy_plot.hex').write_text(''.join(f'{(m<<32)|((x&65535)<<16)|(y&65535):013x}\n' for a in frames for m,x,y in a))
 # Real renderer input: weak high-pitch X/Y to demonstrate the former 8-bit collapse.
 wave=[]
 for i in range(512):
  p=round(14000*math.sin(2*math.pi*261.63*i/48000)+4000*math.sin(2*math.pi*523.26*i/48000))
  x=round(100*math.sin(2*math.pi*1000*i/48000));y=round(100*math.cos(2*math.pi*1000*i/48000))
  wave.append(((p&65535)<<33)|(1<<32)|((x&65535)<<16)|(y&65535))
 (OUT/'render_wave.hex').write_text(''.join(f'{v:013x}\n' for v in wave))
 p=np.zeros(1024,dtype=np.int64)
 for i in range(1,1024):p[i]=int(20+sum(20000000/(k+1)**2*math.exp(-.5*((i-(k+1)*11)/1.3)**2) for k in range(12)))
 (OUT/'render_spec.hex').write_text(''.join(f'{int(v):010x}\n' for v in p))
def source_test():
 sim('tb_xy_source');a=np.load(OUT/'source_reference.npy');co=json.loads((ROOT/'reference/hilbert_coefficients.json').read_text())
 rows=np.loadtxt(OUT/'xy_source.txt',dtype=np.int64)
 for i,mode,w,x,y in rows:
  if i>=8192:continue
  m,p,xx,yy=a[i];hy=sum(int(a[i-2*k,1])*co[k] for k in range(32))>>15;hy=max(-32768,min(32767,hy))
  expected=(xx,yy) if m else (a[i-31,1],hy)
  assert (mode,w,x,y)==(m,p,*expected),(i,(mode,w,x,y),(m,p,*expected))
 # In audio passband, quadrature must be a real transform of input, not fake oscillation.
 metrics={}
 for block in [1,2,3,4,5]:
  r=rows[(rows[:,0]>=block*1024+128)&(rows[:,0]<(block+1)*1024)]
  x=r[:,3].astype(float);y=r[:,4].astype(float)
  corr=float(np.corrcoef(x,y)[0,1]);ratio=float(np.std(y)/np.std(x))
  assert abs(corr)<.04 and .85<ratio<1.15,(block,corr,ratio)
  metrics[str(block)]={'correlation':corr,'rms_ratio':ratio}
 (OUT/'quadrature_metrics.json').write_text(json.dumps(metrics,indent=2))
def map_test():
 sim('tb_xy_plot');lines=(OUT/'xy_maps.txt').read_text().splitlines();maps=[];stats=[]
 for i in range(0,len(lines),2):
  info=lines[i].split();bits=np.array(list(lines[i+1]),dtype=np.uint8).reshape(128,128)
  yy,xx=np.where(bits);n=int(bits.sum());spanx=int(xx.max()-xx.min()) if n else 0;spany=int(yy.max()-yy.min()) if n else 0
  k=int(info[1]);valid=int(info[2]);cycles=int(info[-1]);assert cycles<99000
  if k in [3,4,8]:assert n==0
  else:assert spanx>=30 and spany>=10 and n>30,(k,spanx,spany,n)
  if k==0:assert abs(spanx-spany)<=2
  if k==2:assert .20<spany/spanx<.30,'independent AGC would falsify this ellipse'
  if k==9:assert abs(spanx-spany)<=2
  maps.append(bits);stats.append({'case':k,'pixels':n,'span_x':spanx,'span_y':spany,'cycles':cycles,'valid':valid})
 (OUT/'xy_metrics.json').write_text(json.dumps(stats,indent=2))
 canvas=Image.new('RGB',(5*256,2*288),(3,8,16));draw=ImageDraw.Draw(canvas)
 for k,bits in enumerate(maps):
  rgb=np.zeros((128,128,3),dtype=np.uint8);rgb[:]=[3,8,16];rgb[bits!=0]=[32,210,255]
  tile=Image.fromarray(rgb).resize((256,256),Image.Resampling.NEAREST);ox=k%5*256;oy=k//5*288
  canvas.paste(tile,(ox,oy));draw.text((ox+5,oy+260),f'case {k}: {stats[k]["span_x"]} x {stats[k]["span_y"]}',fill=(180,210,224))
 canvas.save(OUT/'xy_regression.png')
def fixed_fft(x,window,logn):
 n=len(x);c=[math.floor(32767*math.cos(2*math.pi*k/4096)+.5) for k in range(4096)];s=[math.floor(-32767*math.sin(2*math.pi*k/4096)+.5) for k in range(4096)]
 r=[0]*n;im=[0]*n
 for k,v in enumerate(x):
  rev=int(f'{k:0{logn}b}'[::-1],2);r[rev]=(int(v)*((32767-c[k<<(12-logn)])>>1))>>15 if window else int(v)
 h=1
 for stage in range(1,logn+1):
  for base in range(0,n,2*h):
   for j in range(h):
    a=base+j;b=a+h;t=j<<(12-stage);tr=r[b]*c[t]-im[b]*s[t];ti=r[b]*s[t]+im[b]*c[t]
    ar=r[a]*32768;ai=im[a]*32768;r[a]=(ar+tr)>>16;im[a]=(ai+ti)>>16;r[b]=(ar-tr)>>16;im[b]=(ai-ti)>>16
  h*=2
 return [(r[k],im[k],r[k]**2+im[k]**2) for k in range(n//2)]
def fft_test():
 for logn,window in [(10,0),(11,1),(12,1)]:
  n=1<<logn;t=np.arange(n);bins=list(range(8,8+32*6,6));rng=np.random.default_rng(26)
  vectors=[np.zeros(n,dtype=int),np.rint(26000*np.sin(2*np.pi*37*t/n)).astype(int),
   np.rint(sum(700*np.sin(2*np.pi*k*t/n) for k in bins)).astype(int),rng.choice([-32768,-20000,-1,0,1,20000,32767],n)]
  (OUT/'fft_input.hex').write_text(''.join(f'{int(v)&65535:04x}\n' for a in vectors for v in a))
  sim('tb_visual_fft',[f'-Ptb_visual_fft.LOGN={logn}',f'-Ptb_visual_fft.WINDOW={window}'])
  rows=np.loadtxt(OUT/'fft_rtl.txt',dtype=np.int64);assert len(rows)==4*n//2
  for f,a in enumerate(vectors):
   expected=fixed_fft(a,window,logn);assert np.array_equal(rows[f*n//2:(f+1)*n//2,2:],expected)
  shutil.copyfile(OUT/'fft_rtl.txt',OUT/f'fft_rtl_{n}.txt')
def renderer_test():
 sim('tb_renderer_1080')
 rows=(OUT/'frame_logical.hex').read_text().splitlines();assert len(rows)==640*360
 b=bytes.fromhex(''.join(rows));Image.frombytes('RGB',(640,360),b).resize((1920,1080),Image.Resampling.NEAREST).save(OUT/'display_1080p30.png')
def lint():
 run('strict_lint',[TOOLS/'verilator-cli.exe','--lint-only','--Wall','--top-module','audio_visualizer','--Mdir','sim_out_visual/obj_lint',*[p.relative_to(ROOT).as_posix() for p in PORTABLE]])
def structure():
 script='read_verilog -sv '+' '.join(p.relative_to(ROOT).as_posix() for p in PORTABLE)
 script+='; hierarchy -check -top audio_visualizer; proc; opt; memory_dff; memory_collect; opt_clean; check -assert; log VIS_COMPLETE'
 text=run('structure',[TOOLS/'yowasp-yosys.exe','-Q','-T','-p',script])
 if 'Warning:' in text or 'VIS_COMPLETE\n' not in text:raise RuntimeError(text[-6000:])
def board():
 for node in ET.parse(ROOT/'visual_demo.gprj').findall('.//File'):assert (ROOT/node.attrib['path']).exists()
 run('board_elaboration',[BIN/'iverilog.exe','-g2012','-s','visual_test_top','-o',OUT/'board.vvp',*ALL,ROOT/'sim/visual_primitive_stubs.v'])
 def params(name):
  text=(ROOT/'src/gowin_pll'/name).read_text();return {k:float(v) for k,v in re.findall(r'PLL_inst\.(\w+)\s*=\s*"?([\d.]+)"?;',text)}
 ref=params('visual_ref_pll_mod.v');vid=params('visual_pll_mod.v')
 def freq(p):
  pfd=p['FCLKIN']/p['IDIV_SEL'];vco=pfd*p['FBDIV_SEL']*(p['MDIV_SEL']+p['MDIV_FRAC_SEL']/8)
  assert 19<=pfd<=81.25 and 650<=vco<=1300,(pfd,vco)
  return vco/p['ODIV0_SEL'],vco/p['ODIV1_SEL']
 assert freq(ref)[0]==27;assert freq(vid)==(371.25,74.25)
 assert 74250000/(2200*1125)==30
 (OUT/'clock_math.json').write_text(json.dumps({'ref_MHz':27,'pixel_MHz':74.25,'serial_MHz':371.25,'fps':30,'vendor_verified':False},indent=2))
def outside():
 baseline=json.loads((ROOT/'reference/outside_before.json').read_text())
 changed=[p for p,h in baseline.items() if not Path(p).exists() or hashlib.sha256(Path(p).read_bytes()).hexdigest()!=h]
 if changed:raise RuntimeError(changed)
stimuli()
check('xy_source_bit_exact_quadrature',source_test)
check('xy_bitmap_geometry_low_high_level',map_test)
check('raster_1080p30_tmds',lambda:sim('tb_video_1080'))
check('snapshot_cdc',lambda:sim('tb_visual_cdc'))
check('audio_pixel_reset',lambda:sim('tb_visual_reset'))
check('audio_capture_cdc_pairing',lambda:sim('tb_capture_cdc'))
check('fft_1024_2048_4096',fft_test)
check('renderer_1080_frame',renderer_test)
check('strict_lint',lint);check('structure_check',structure);check('board_elaboration_clock_math',board);check('outside_scope_hashes',outside)
report={'status':'FAIL' if errors else 'PASS','results':results,'errors':errors,
 'scope':'Display package standalone tests only. Original live-board source unavailable; no actual piano integration, vendor P&R or monitor test.',
 'source_sha256':{p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in ALL}}
(OUT/'verification.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
(OUT/'verification_report.md').write_text('# 升级显示独立验证\n\n'+'\n'.join(f'- {k}: {v}' for k,v in results.items())+'\n\n'+report['scope']+'\n',encoding='utf-8')
print('ALL DISPLAY CHECKS PASS' if not errors else 'FAILED',flush=True);sys.exit(bool(errors))
