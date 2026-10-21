from pathlib import Path
import json,sys,numpy as np,re
R=Path(__file__).resolve().parents[1];O=R/'tests/audio_diagnosis';sys.path.insert(0,str(R/'tools'))
import amy_extract,pianolib as pl
j=json.loads((R/'tools/amy_data/amy_piano_params.json').read_text());h=(R/'ref/amy_excerpt/src/interp_partials.h').read_text();checks=[]
for array,key in [('piano_sample_times_ms','sample_times_ms'),('piano_velocities','velocities'),('piano_notes','notes'),('piano_num_harmonics','num_harmonics'),('piano_harmonics_freq','harmonics_freq_cents'),('piano_harmonics_mags','harmonics_mags_db')]:
 actual=amy_extract.c_array(h,array);expected=np.array(j[key]).ravel().tolist();assert actual==expected,array;checks.append({'array':array,'words':len(actual),'exact':True})
notes=[]
for n in [60,64,68,72]:
 i=j['notes'].index(n);c,m=pl.note_vel_rows(i,1);c2,m2=pl.note_vel_rows(i,2);db=(m[0]+m2[0])*.5
 notes.append({'midi':n,'fundamental_db_amy_at_4_8_12_16_24ms':db[:5].tolist(),'fundamental_db_amy_at_96_128_192_256_384_512ms':db[8:14].tolist(),'frequency_cents_v80_v120':[float(c[0]),float(c2[0])]})
result={'status':'PASS','source_header':str(R/'ref/amy_excerpt/src/interp_partials.h'),'source_json':str(R/'tools/amy_data/amy_piano_params.json'),'checks':checks,'examples':notes,'conclusion':'E4 fundamental weaker values are already in original AMY source data; no extraction shift between notes detected. AMY dB scale is not digital dBFS.'}
(O/'AMY_SOURCE_AUDIT.json').write_text(json.dumps(result,indent=2),encoding='utf8');print(json.dumps(result,indent=2))