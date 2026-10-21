"""Long-held FX decay extension. Model evidence, separate from primary RTL WAVs."""
from pathlib import Path
import concurrent.futures as cf
import csv,json,sys,wave,zipfile
import numpy as np
R=Path(__file__).resolve().parents[2];sys.path.insert(0,str(R/'tools'))
from fx_model import Fx
from tail_fix_analyze import rms,db,wav
from tail_fix_run import sha,now,dump
O=Path(__file__).resolve().parent;A=R/'audit/calibration_20261018'

def one(n):
    src=O/'natural_hold_model'/f'midi_{n:03d}.wav'
    with wave.open(str(src)) as f:
        b=np.frombuffer(f.readframes(f.getnframes()),dtype=np.uint8).reshape(-1,3)
    x=b[:,0].astype(np.int64)+(b[:,1].astype(np.int64)<<8)+(b[:,2].astype(np.int64)<<16);x=np.where(x>=(1<<23),x-(1<<24),x)
    y=Fx().process(np.concatenate([x,np.zeros(192000,dtype=np.int64)]))
    assert not np.any(y[-48000:]) and not np.any(abs(y)>=8388607)
    nz=np.flatnonzero(y);env=np.array([rms(y[i:i+480]) for i in range(0,len(y)-479,480)]);p=int(np.argmax(env));peak=env[p]
    row={'midi':n,'fx_last_nonzero_s_model':(int(nz[-1])+1)/48000,'fx_peak_dbfs_model':db(abs(y).max()),'fx_rail_samples_model':int(np.count_nonzero(abs(y)>=8388607)),'final_1s_exact_zero':True,'source_wav_sha256':sha(src)}
    for d in [20,40,60]:
        ids=np.flatnonzero(env[p:]>=peak*10**(-d/20));row[f'fx_decay_{d}db_after_peak_s_model']=(int(ids[-1])+1)*.01 if len(ids) else 0
    wav(O/'natural_hold_fx_model'/f'midi_{n:03d}.wav',y)
    print('NATURAL FX MODEL',n,flush=True);return row

if __name__=='__main__':
    with cf.ProcessPoolExecutor(max_workers=4) as ex:rows=list(ex.map(one,range(48,92)))
    with (O/'NATURAL_FX_44_MODEL.csv').open('w',encoding='utf-8-sig',newline='') as f:
        w=csv.DictWriter(f,fieldnames=list(rows[0]));w.writeheader();w.writerows(rows)
    dump(A/'NATURAL_FX_MODEL.json',{'status':'PASS','time':now(),'notes':44,'velocity':100,'natural_hold_no_note_off':True,'extra_zero_input_s':4,'all_final_1s_exact_zero':True,'source':'integer model, not additional long RTL','results':rows})
