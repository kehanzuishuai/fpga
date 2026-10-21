"""Read-only analysis of this recording; never rewrite historical audio audits."""
from pathlib import Path
import sys, os, wave, json, csv
import numpy as np

R = Path(__file__).resolve().parents[2]
O = Path(__file__).resolve().parent
sys.path.insert(0, str(R/'tools'))
sys.path.insert(0, str(R/'tools/audio_vendor'))
os.environ['MPLCONFIGDIR'] = str(O/'mpl_cache')
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import piano_tables as pt
from fpga_piano_model import Loader

with wave.open(str(O/'recording.wav')) as w:
    fs = w.getframerate()
    x = np.frombuffer(w.readframes(w.getnframes()), '<i2').astype(float)/32768
hop, win = 480, 8192
starts = np.arange(0, len(x)-win, hop)
frames = np.stack([x[k:k+win]*np.hanning(win) for k in starts])
spec = abs(np.fft.rfft(frames, axis=1))
freq = np.fft.rfftfreq(win, 1/fs)
time = (starts+win/2)/fs
power = spec**2
db = lambda z: 20*np.log10(np.maximum(z, 1e-15))
rms = np.array([np.sqrt(np.mean(x[k:k+hop]**2)) for k in range(0, len(x)-hop, hop)])
fig, ax = plt.subplots(3, 1, figsize=(16, 10), sharex=True)
ax[0].plot(np.arange(len(rms))*.01, db(rms)); ax[0].set_ylabel('RMS / dBFS')
ax[0].set_ylim(-90, 0)
ax[1].imshow(db(spec.T/(win/2)), origin='lower', aspect='auto',
    extent=[time[0], time[-1], 0, fs/2], vmin=-85, vmax=-25, cmap='magma')
ax[1].set_ylim(100, 6500); ax[1].set_ylabel('Hz'); ax[1].set_yscale('log')
tables = pt.build(); loader = Loader(tables)
rows=[]
for n in range(60,76):
    p = loader.params(n,100)
    f0 = 440*2**((n-69)/12)
    # This hypothesis is derived from the saved synthesis netlist: the DSP
    # pre-adder's D input is extended with ones instead of zeros. This adds
    # 2^20 to the ratio difference and 2^12 to the level difference.
    ap = (n-24)%4
    f = p['inc'][:15]*fs/2**28 + ap*8*f0
    track=[]
    for f1 in f[:6]:
        ix=np.where(abs(freq-f1)<12)[0]
        track.append(power[:,ix].max(axis=1) if len(ix) else np.zeros(len(time)))
    track=np.sqrt(np.sum(track, axis=0))/(win/2)
    ax[2].plot(time, db(track), label=str(n))
    rows.append({'midi_hypothesis':n,'pitch_quarter':ap,'predicted_first_partial_hz':float(f[0]),'track_max_dbfs':float(db(track.max()))})
ax[2].set_ylim(-90,0); ax[2].set_ylabel('Hypothesis line energy / dBFS')
ax[2].set_xlabel('Recording time / s');ax[2].legend(ncol=8, fontsize=8)
ax[0].grid();ax[2].grid();fig.tight_layout();fig.savefig(O/'recording_overview.png',dpi=150)
with (O/'HYPOTHESIS_TRACKS.csv').open('w',newline='') as h:
    c=csv.DictWriter(h,fieldnames=rows[0]);c.writeheader();c.writerows(rows)
np.savez_compressed(O/'spectra.npz',time=time,freq=freq,spec=spec)
print(json.dumps({'duration_s':len(x)/fs,'peak':float(abs(x).max()),'rail_samples':int(np.sum(abs(x)>=32767/32768)),'hypotheses':rows},indent=2))
