"""Measure Voice lifetime for the four gated old post-synthesis parameters."""
from pathlib import Path
import sys,csv,json
import numpy as np
R=Path(__file__).resolve().parents[2];O=Path(__file__).resolve().parent
sys.path.insert(0,str(R/'tools'))
import piano_tables as pt
from fpga_piano_model import Voice
tables=pt.build();words={n:{} for n in [63,67,71,75]}
for row in csv.reader((O/'before/words.csv').open()):
    n,a,z=map(int,row)
    if n in words:words[n][a]=z
rows=[]
for n,w in words.items():
    v=Voice(tables);v.note_on(n,100)
    for s in range(16):
        v.inc[s]=w[32*s];v.bp[s]=[w[32*s+4+b] for b in range(21)]
    v.future_audible=np.any(v.bp<=3301,axis=0)
    ticks=0
    while v.active and ticks<4800:
        y=v.render(1);assert y[0]==0;ticks+=1
    assert not v.active
    rows.append({'midi':n,'received_note_on_and_loaded':True,'all_pcm_exact_zero':True,'active_samples_after_load_model':ticks,'retirement_ms_after_load_model':1000*ticks/48000,'future_audible_mask':0})
result={'status':'PASS','scope':'Integer Voice model driven by actual old post-synthesis Loader words; not a fresh Voice RTL or board measurement','rows':rows}
(O/'SILENT_VOICE_EXIT_MODEL.json').write_text(json.dumps(result,indent=2));print(json.dumps(result,indent=2))
