"""Whole-chain check of the system simulation (sim/tb/tb_system.v).

    python tools/compare_system.py [tag]        tag: file name prefix, default "sys"

Takes the per-voice samples the RTL logged (build/sys_voice_<n>.txt, each
already compared with the voice model by compare_pcm.py), adds them up the way
tree_mixer + polyphony_gain (constant gain) do, sends the sum through the
effects model and compares the result with the samples the RTL put on the
audio bus (build/sys_pcm.txt).  A constant delay of whole samples is allowed;
everything else has to be identical.
"""
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fx_model import Fx  # noqa: E402
from note_gain_model import apply_gain

TAG = sys.argv[1] if len(sys.argv) > 1 else "sys"

pcm = np.array([int(v) for v in open("build/%s_pcm.txt" % TAG).read().split()], dtype=np.int64)
n = len(pcm)
mix = np.zeros(n + 8, dtype=np.int64)
used = 0
for g in range(32):
    path = "build/%s_voice_%d.txt" % (TAG, g)
    if not os.path.exists(path) or os.path.getsize(path) == 0:
        continue
    used += 1
    current_note = 0
    for ln in open(path):
        f = ln.split()
        if len(f) == 4 and f[0] == "L":
            current_note = int(f[2])
        if len(f) == 5 and f[0] == "S":
            t = int(f[1])
            if 0 <= t < len(mix):
                mix[t] += int(apply_gain(int(f[2]), current_note))

# polyphony_gain with NORMALIZE = 0: gain 32767/32768, arithmetic shift
mixq = (mix * 32767) >> 15
y = Fx(soundboard=True, reverb=True, eq_preset=0, limiter_soft=True, gain_shift=1).process(mixq)

best = None
for lag in range(0, 6):
    a = pcm[lag:n]
    b = y[:n - lag]
    diff = int(np.count_nonzero(a != b))
    if best is None or diff < best[1]:
        best = (lag, diff)
    if diff == 0:
        break
lag, diff = best
print("voices used %d, samples %d, mix peak %.1f dBFS, output peak %.1f dBFS" % (
    used, n, 20 * np.log10(max(1, np.abs(mixq).max()) / 2.0 ** 23), 20 * np.log10(max(1, np.abs(pcm).max()) / 2.0 ** 23)))
if diff == 0:
    print("PASS: audio bus = effects model(sum of the 32 voices), delayed by %d samples" % lag)
else:
    print("FAIL: best delay %d samples still has %d different samples" % (lag, diff))
    sys.exit(1)
