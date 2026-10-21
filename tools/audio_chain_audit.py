from pathlib import Path
import csv,json,numpy as np
R=Path(__file__).resolve().parents[1];O=R/'tests/audio_diagnosis'
inputs={};fx={};sums={};partial={};bad=[];groups={}
for a in csv.reader((O/'chain_stage_samples.csv').open()):
 key=int(a[0]);tick=int(a[2]);x=int(a[3]);y=int(a[4])
 if a[1]=='INPUT':
  inputs[key,tick]=x
  if y!=(x*32767)>>15:bad.append(['gain',key,tick,x,y])
  sums.setdefault(key,[]).append([x,y])
 else:fx.setdefault(key,[]).append(x)
for a in csv.reader((O/'partial_products.csv').open()):
 key,tick,slot,product=map(int,a);groups.setdefault((key,tick),[]).append(product)
 partial.setdefault((key,slot),[]).append(product/2**18)
for (key,tick),v in groups.items():
 if len(v)==16 and (key,tick+1) in inputs:
  expected=max(-8388608,min(8388607,sum(v)>>18))
  if expected!=inputs[key,tick+1]:bad.append(['partial_to_voice_to_mix',key,tick,expected,inputs[key,tick+1]])
rows=[]
for key in range(16):
 p=[np.sqrt(np.mean(np.array(partial.get((key,s),[0]),dtype=float)**2)) for s in range(16)]
 s=np.array(sums[key],dtype=float);f=np.array(fx[key],dtype=float)
 rows.append({'raw_bit':key,'midi':60+key,'partial_rms_lsb24':p,'mixer_rms_lsb24':float(np.sqrt(np.mean(s[:,0]**2))),'post_gain_rms_lsb24':float(np.sqrt(np.mean(s[:,1]**2))),'fx_rms_lsb24':float(np.sqrt(np.mean(f**2))),'scope':'same per-key 2048-sample attack window plus scan/load/short release; stage pipeline delay retained, not long-note metrics'})
result={'status':'PASS' if not bad else 'FAILED','input_samples_checked':len(inputs),'complete_partial_groups_checked':sum(len(v)==16 and (key,tick+1) in inputs for (key,tick),v in groups.items()),'mismatches':bad[:20],'rows':rows}
(O/'CHAIN_AUDIT.json').write_text(json.dumps(result,indent=2),encoding='utf8');print(result['status'],'stage comparisons',len(inputs),'samples, failures',len(bad));assert not bad
