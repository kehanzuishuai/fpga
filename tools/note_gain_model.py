"""Per-note gain after the unchanged raw partial voice, before tree_mixer."""
from pathlib import Path
import re
import numpy as np
_rtl=(Path(__file__).resolve().parents[1]/'src/piano_note_gain.v').read_text()
GAINS={int(n):int(q) for n,q in re.findall(r"7'd(\d+): gain_for_note = 16'd(\d+)",_rtl)}
assert sorted(GAINS)==list(range(48,92))
def gain_for_note(note):return GAINS.get(int(note),8192)
def apply_gain(samples,note):return np.clip((np.asarray(samples,dtype=np.int64)*gain_for_note(note))>>13,-8388608,8388607)
