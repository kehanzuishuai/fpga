from pathlib import Path
import sys,re,json,csv,subprocess,numpy as np,hashlib
R=Path(__file__).resolve().parents[1];O=R/'tests/audio_diagnosis';sys.path.insert(0,str(R/'tools'))
import piano_tables as pt,fpga_piano_model as fm
T=pt.build()
def rom(name,count,bank=False):
 text=(R/'src'/f'{name}.v').read_text();v=np.full(count,-1,dtype=np.int64)
 for m in re.finditer(r"(\d+)'d(\d+):\s+(q\d*)\s*<=\s*(\d+)'h([0-9a-fA-F_]+)",text):
  i=int(m[2]);i+=int(m[3][1:] or '0')*1024 if bank else 0
  if i<count:v[i]=int(m[5].replace('_',''),16)
 assert np.all(v>=0),(name,np.flatnonzero(v<0)[:5])
 return v
roms={'level':rom('piano_level_rom',21168,True).reshape(21,3,16,21),'ratio':rom('piano_ratio_rom',336).reshape(21,16),'rel_slope':rom('piano_note_rom',128),'sine':rom('piano_sine_rom',512),'exp_mant':rom('piano_exp_rom',1024)}
for k in ['level','ratio','rel_slope','exp_mant']:assert np.array_equal(T[k],roms[k]),k
assert np.array_equal((T['sine_val']<<9)+T['sine_delta'],roms['sine'])
# Independent interpolation arithmetic from the actual generated ROM words.
W={};ratios=[];missing=0
for n in range(24,105):
 j=min((n-24)//4,19);a=n-24-4*j
 for vel in [1,39,40,60,79,80,100,119,120,127]:
  vc=min(120,max(40,vel));vl=int(vc>=80);av=((vc-(80 if vl else 40))*205)//32;extra=max(0,40-vel)*26
  for s in range(16):
   ra,rb=map(int,roms['ratio'][j:j+2,s]);rat=ra+((rb-ra)*a//4) if ra and rb else 0
   inc=(fm.note_phase_inc(n)*rat>>19)&((1<<28)-1)
   W[n,vel,s*32]=inc;W[n,vel,s*32+1]=0;W[n,vel,s*32+2]=13<<22;W[n,vel,s*32+3]=0
   if vel==100 and s<15 and rat:ratios.append({'note':n,'partial':s+1,'ratio_q15':rat,'frequency_hz':inc*48000/2**28,'target_hz':440*2**((n-69)/12)})
   for b in range(21):
    x0,x1,x2,x3=map(int,[roms['level'][j,vl,s,b],roms['level'][j,vl+1,s,b],roms['level'][j+1,vl,s,b],roms['level'][j+1,vl+1,s,b]])
    if 4095 in [x0,x1,x2,x3]:val=4095;missing+=1
    else:
     low=x0+(x2-x0)*a//4;high=x1+(x3-x1)*a//4;val=min(4094,max(0,low+(high-low)*av//256+extra))
    W[n,vel,s*32+4+b]=val
actual={}
for row in csv.reader((O/'loader_words.csv').open()):
 n,v,a,d=map(int,row);key=n,v,a;assert key not in actual,key;actual[key]=d
bad=[(k,W[k],actual.get(k)) for k in W if W[k]!=actual.get(k)]
with (O/'partial_frequencies.csv').open('w',newline='') as f:
 w=csv.DictWriter(f,fieldnames=list(ratios[0]));w.writeheader();w.writerows(ratios)
assert max(x['frequency_hz'] for x in ratios)<24000
out={'status':'PASS' if not bad and len(actual)==len(W) else 'FAILED','rom_words_equal_generated_reference':sum(v.size for v in roms.values()),'loader_requests':810,'loader_words_checked':len(W),'mismatches':bad[:20],'max_retained_partial_hz':max(x['frequency_hz'] for x in ratios),'missing_breakpoint_results':missing,'scope':'MIDI24..104, velocities1/39/40/60/79/80/100/119/120/127; exact actual ROM and independent floor integer arithmetic'}
(O/'INTERPOLATION_AUDIT.json').write_text(json.dumps(out,indent=2),encoding='utf8');print(json.dumps(out,indent=2));assert out['status']=='PASS'
