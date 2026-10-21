"""Bit-exact integer model of the FPGA piano voice.

Mirrors piano_note_loader.v (note-on interpolation) and piano_partial_voice.v
(per-sample synthesis) operation for operation, so that the PCM written by the
RTL test bench can be compared sample by sample (tools/compare_pcm.py).

All arithmetic is integer; ">>" on negative numbers is an arithmetic shift
(floor), exactly like ">>>" on signed values in the RTL.
"""
import numpy as np

import piano_tables as pt

MASK28 = (1 << 28) - 1


def note_phase_inc(note, fs=48000):
    """32 bit DDS increment of an equal-tempered MIDI note, as note_freq_table.v
    stores it (round(f / fs * 2^32))."""
    f = 440.0 * 2.0 ** ((note - 69) / 12.0)
    return int(round(f / fs * (1 << 32)))


class Loader:
    """piano_note_loader.v: what is written into the voice RAM at note-on."""

    def __init__(self, tables):
        self.t = tables

    def params(self, note, vel, inc0=None):
        t = self.t
        note_c = min(104, max(24, note))
        j = min((note_c - 24) >> 2, 19)
        ap = note_c - 24 - 4 * j                      # 0..4 quarters of the way to grid note j+1
        vel_c = min(120, max(40, vel))
        if vel_c < 80:
            vl, d = 0, vel_c - 40
        else:
            vl, d = 1, vel_c - 80
        av = (d * 205) >> 5                           # 0..256
        extra = (40 - vel) * pt.EXTRA_ATT_PER_VEL if vel < 40 else 0
        if inc0 is None:
            inc0 = note_phase_inc(note)

        lev = t["level"]
        bp = np.zeros((pt.SLOTS, pt.NUM_BP), dtype=np.int64)
        inc = np.zeros(pt.SLOTS, dtype=np.int64)
        for s in range(pt.SLOTS):
            r0, r1 = int(t["ratio"][j, s]), int(t["ratio"][j + 1, s])
            if r0 == 0 or r1 == 0:
                r = 0
            else:
                r = r0 + (((r1 - r0) * ap) >> 2)
            inc[s] = ((inc0 * r) >> (pt.RATIO_FRAC + 4)) & MASK28
            for b in range(pt.NUM_BP):
                a = int(lev[j, vl, s, b])
                bb = int(lev[j, vl + 1, s, b])
                c = int(lev[j + 1, vl, s, b])
                dd = int(lev[j + 1, vl + 1, s, b])
                if pt.L_MISSING in (a, bb, c, dd):
                    x = pt.L_MISSING
                else:
                    lo = a + (((c - a) * ap) >> 2)
                    hi = bb + (((dd - bb) * ap) >> 2)
                    x = lo + (((hi - lo) * av) >> 8)
                    x = min(x + extra, pt.L_MAX_ROM)
                bp[s, b] = x
        return {"inc": inc, "bp": bp, "rel_slope": int(t["rel_slope"][note])}


class Voice:
    """piano_partial_voice.v"""

    def __init__(self, tables, voice_index=0, hammer_enable=True):
        self.t = tables
        self.loader = Loader(tables)
        self.hammer_enable = hammer_enable
        self.lfsr = 0xACE1 ^ (voice_index * 0x0101)
        self.y1 = 0
        self.y2 = 0
        self.active = False
        self.releasing = False
        self.fading = False
        self.seg = 0
        self.seg_cnt = 0
        self.inc = np.zeros(pt.SLOTS, dtype=np.int64)
        self.phase = np.zeros(pt.SLOTS, dtype=np.int64)
        self.level = np.full(pt.SLOTS, pt.L_INIT, dtype=np.int64)
        self.slope = np.zeros(pt.SLOTS, dtype=np.int64)
        self.bp = np.full((pt.SLOTS, pt.NUM_BP), pt.L_MISSING, dtype=np.int64)
        self.rel_slope = 0
        self.future_audible = np.zeros(pt.NUM_BP, dtype=bool)

    # -- events -------------------------------------------------------------
    def note_on(self, note, vel, inc0=None):
        """State right after the loader has finished (voice plays from the next sample)."""
        p = self.loader.params(note, vel, inc0)
        self.inc = p["inc"].copy()
        self.bp = p["bp"].copy()
        self.rel_slope = p["rel_slope"]
        # Exact ROM-domain threshold used by piano_partial_voice. Retiring
        # completed segments is represented by the slice at self.seg below.
        self.future_audible = np.any(self.bp <= 3301, axis=0)
        self.phase[:] = 0
        self.level[:] = pt.L_INIT
        self.slope[:] = 0
        self.seg = 0
        self.seg_cnt = 0
        self.active = True
        self.releasing = False
        self.fading = False

    def note_off(self):
        if self.active:
            self.releasing = True

    def steal(self):
        if self.active:
            self.fading = True

    # -- noise source: runs on every sample, also while the voice is idle ----
    def _noise(self, n):
        out = np.zeros(n, dtype=np.int64)
        lfsr, y1, y2 = self.lfsr, self.y1, self.y2
        for i in range(n):
            fb = ((lfsr >> 15) ^ (lfsr >> 13) ^ (lfsr >> 12) ^ (lfsr >> 10)) & 1
            lfsr = ((lfsr << 1) & 0xFFFF) | fb
            x = lfsr - 0x10000 if lfsr & 0x8000 else lfsr
            y1 += ((x << 4) - y1) >> 3
            y2 += (y1 - y2) >> 3
            v = y2 >> 1
            out[i] = max(-131071, min(131071, v))
        self.lfsr, self.y1, self.y2 = lfsr, y1, y2
        return out

    # -- synthesis ------------------------------------------------------------
    def _amp(self, level):
        t = self.t
        li = level >> pt.L_FRAC
        lf = (level >> 12) & 0x3FF
        amp = (t["exp_mant"][lf] << 6) >> li
        amp = amp - pt.AMP_OFFSET
        return np.where(amp <= pt.AMP_GATE, 0, amp)

    def _sine(self, phase):
        t = self.t
        q = phase >> 26
        idx = (phase >> 17) & 0x1FF
        fr = (phase >> 7) & 0x3FF
        mirror = (q & 1) == 1
        idx = np.where(mirror, 511 - idx, idx)
        fr = np.where(mirror, 1023 - fr, fr)
        v = t["sine_val"][idx] + ((t["sine_delta"][idx] * fr) >> 10)
        return np.where((q & 2) == 2, -v, v)

    def render(self, n):
        """Next n output samples (24 bit signed integers)."""
        out = np.zeros(n, dtype=np.int64)
        noise = self._noise(n)
        pos = 0
        while pos < n and self.active:
            hold = self.releasing or self.fading
            if (not hold) and self.seg <= 20 and self.seg_cnt == 0:
                # segment boundary: new slope towards the next breakpoint
                target = self.bp[:, self.seg] << 14
                x = target - self.level
                self.slope = (x * pt.K3) >> (18 + 6 + pt.SEG_SHIFT[self.seg])
            if hold or self.seg > 20:
                chunk = n - pos
            else:
                chunk = min(n - pos, (pt.SEG_BASE_LEN << pt.SEG_SHIFT[self.seg]) - self.seg_cnt)
            if self.fading:
                sl = np.full(pt.SLOTS, pt.FADE_SLOPE, dtype=np.int64)
            elif self.releasing:
                sl = np.full(pt.SLOTS, self.rel_slope, dtype=np.int64)
            else:
                sl = self.slope
            k = np.arange(chunk, dtype=np.int64)
            level = np.clip(self.level[:, None] + sl[:, None] * k[None, :], 0, pt.L_TOP)
            phase = (self.phase[:, None] + self.inc[:, None] * k[None, :]) & MASK28
            amp = self._amp(level)
            wave = self._sine(phase)
            wave[pt.HAMMER_SLOT, :] = noise[pos:pos + chunk] if self.hammer_enable else 0
            acc = np.sum(amp * wave, axis=0)
            y = np.clip(acc >> 18, -(1 << 23), (1 << 23) - 1)
            audible = np.any(amp != 0, axis=0)

            # A held-note gap is not terminal while a future target can sound.
            may_stop = hold or (self.seg >= 2 and not np.any(self.future_audible[self.seg:]))
            used = chunk
            if may_stop:
                silent = np.nonzero(~audible)[0]
                if len(silent):
                    used = int(silent[0]) + 1
                    self.active = False
            out[pos:pos + used] = y[:used]
            self.level = np.clip(self.level + sl * used, 0, pt.L_TOP)
            self.phase = (self.phase + self.inc * used) & MASK28
            if not hold and self.seg <= 20:
                self.seg_cnt += used
                if self.seg_cnt == (pt.SEG_BASE_LEN << pt.SEG_SHIFT[self.seg]):
                    self.seg += 1
                    self.seg_cnt = 0
            pos += used
            if not self.active:
                self.releasing = False
                self.fading = False
        return out


def render_note(tables, note, vel, n_samples, off_sample=None, hammer=True, voice_index=0):
    """One note from an idle voice: note-on completes before sample 0."""
    v = Voice(tables, voice_index, hammer)
    v.note_on(note, vel)
    if off_sample is None or off_sample >= n_samples:
        return v.render(n_samples)
    a = v.render(off_sample)
    v.note_off()
    return np.concatenate([a, v.render(n_samples - off_sample)])


if __name__ == "__main__":
    import sys
    import pianolib as pl
    tables = pt.build()
    note = int(sys.argv[1]) if len(sys.argv) > 1 else 60
    vel = int(sys.argv[2]) if len(sys.argv) > 2 else 80
    y = render_note(tables, note, vel, 3 * 48000, off_sample=2 * 48000)
    print("note %d vel %d: peak %d (%.1f dBFS)" % (note, vel, np.abs(y).max(),
                                                  20 * np.log10(np.abs(y).max() / 2.0 ** 23)))
    pl.write_wav_int("../build/model_n%d_v%d.wav" % (note, vel), y)
