"""Bit-exact integer model of src/piano_fx.v.

The coefficient values are read from the Verilog parameters, so the RTL file
is the only place where they are defined.

    from fx_model import Fx
    fx = Fx(soundboard=True, reverb=True, eq_preset=0, limiter_soft=True, gain_shift=1)
    y = fx.process(x)      # x: integer samples of the mix (any range), y: 24 bit

Also usable from the command line to put the effects on a WAV file:
    python tools/fx_model.py in.wav out.wav [--no-soundboard] [--no-reverb] [--eq N]
"""
import os
import re
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
RTL = os.path.join(HERE, "..", "src", "piano_fx.v")

S32_MAX = (1 << 31) - 1
S32_MIN = -(1 << 31)
S36_MAX = (1 << 35) - 1
S36_MIN = -(1 << 35)


def rtl_params(path=RTL):
    text = open(path, encoding="utf-8").read()
    out = {}
    for m in re.finditer(r"parameter\s+(?:signed\s+)?(?:\[[^\]]+\]\s+)?(\w+)\s*=\s*(-?)\s*(?:\d+'s?d)?(\d+)", text):
        out[m.group(1)] = int(m.group(3)) * (-1 if m.group(2) else 1)
    return out


def sat32(v):
    return S32_MAX if v > S32_MAX else S32_MIN if v < S32_MIN else v


def sat36(v):
    return S36_MAX if v > S36_MAX else S36_MIN if v < S36_MIN else v


def div16(v):
    """v / 16 truncated towards zero."""
    return -((-v) >> 4) if v < 0 else v >> 4


def mulq(a, c):
    """(a * c) / 65536 truncated towards zero, as in the RTL."""
    p = a * c
    return -((-p) >> 16) if p < 0 else p >> 16


class Fx:
    def __init__(self, soundboard=True, reverb=True, eq_preset=0, limiter_soft=True, gain_shift=1,
                 clear_samples=0):
        p = rtl_params()
        self.p = p
        self.soundboard = soundboard
        self.reverb = reverb
        self.eq_preset = eq_preset
        self.limiter_soft = limiter_soft
        self.gain_shift = gain_shift
        # soundboard
        self.sb_f = [p["SB_F%d" % i] for i in range(4)]
        self.sb_q = [p["SB_Q%d" % i] for i in range(4)]
        self.sb_g = [p["SB_G%d" % i] for i in range(4)]
        self.bp = [0] * 4
        self.lp = [0] * 4
        # reverb
        self.rv_len = [p["RV_LEN%d" % i] for i in range(1, 5)]
        self.mem = [[0] * 2048 for _ in range(4)]
        self.wp = 0
        self.s = [0] * 4
        # The RTL clears its delay memory during the first 2048 clk after
        # reset and passes the dry signal meanwhile.  clear_samples = number
        # of samples that arrive in that time (0 when the input starts later).
        self.clear_left = clear_samples
        # eq
        self.lo = 0
        self.hi = 0

    def _soundboard(self, x):
        # resonator states: 36 bit, 4 more fraction bits than the chain format
        xs = x * 2                                   # x * 16 / 8
        wet = 0
        for i in range(4):
            hp = sat36(xs - self.lp[i] - mulq(self.bp[i], self.sb_q[i]))
            self.bp[i] = sat36(self.bp[i] + mulq(hp, self.sb_f[i]))
            self.lp[i] = sat36(self.lp[i] + mulq(self.bp[i], self.sb_f[i]))
            wet += sat36(mulq(self.bp[i], self.sb_g[i]))
        return sat32(x + div16(wet)) if self.soundboard else x

    @staticmethod
    def _to_mem(v):
        t = min(abs(v) >> 10, 131071)          # truncate towards zero, saturate
        return -t if v < 0 else t

    def _reverb(self, x):
        p = self.p
        clearing = self.clear_left > 0
        e = []
        for i in range(4):
            d = 0 if clearing else self.mem[i][(self.wp - self.rv_len[i]) & 2047] << 10
            self.s[i] = sat32(self.s[i] + mulq(sat32(d - self.s[i]), p["RV_LPCOEF"]))
            u = sat32(self.s[i] + mulq(sat32(d - self.s[i]), p["RV_LPGAIN"]))
            v = mulq(u, p["RV_LIVE_HALF"])
            if i < 2:
                v += x >> 4
            e.append(sat32(v))
        wet = sat32(e[0] + e[1])
        if clearing:
            self.clear_left -= 1
            return x
        self.mem[0][self.wp] = self._to_mem(e[0] + e[1] + e[2] + e[3])
        self.mem[1][self.wp] = self._to_mem(e[0] - e[1] + e[2] - e[3])
        self.mem[2][self.wp] = self._to_mem(e[0] + e[1] - e[2] - e[3])
        self.mem[3][self.wp] = self._to_mem(e[0] - e[1] - e[2] + e[3])
        self.wp = (self.wp + 1) & 2047
        return sat32(x + mulq(wet, p["RV_LEVEL"])) if self.reverb else x

    def _eq(self, x):
        p = self.p
        gl, gh = {1: (p["EQ_WARM_GL"], p["EQ_WARM_GH"]), 2: (p["EQ_BRIGHT_GL"], p["EQ_BRIGHT_GH"])}.get(
            self.eq_preset, (0, 0))
        xw = x << 4                                  # 36 bit filter states
        self.lo = sat36(self.lo + mulq(sat36(xw - self.lo), p["EQ_KL"]))
        self.hi = sat36(self.hi + mulq(sat36(xw - self.hi), p["EQ_KH"]))
        return sat32(x + div16(mulq(self.lo, gl) + mulq(sat36(xw - self.hi), gh)))

    def _limiter(self, x):
        fs = 1 << 27
        v = x << self.gain_shift
        neg = v < 0
        a = -v if neg else v
        if not self.limiter_soft:
            y = fs - 16 if a >= fs else a
        elif a <= fs // 2:
            y = a
        elif a <= fs * 3 // 4:
            d = a - fs // 2
            y = fs // 2 + (d >> 1) + (d >> 2)
        elif a <= fs:
            y = 92274688 + ((a - fs * 3 // 4) >> 1)
        elif a <= 2 * fs:
            y = 109051904 + ((a - fs) >> 3)
        elif a <= 4 * fs:
            y = 125829120 + ((a - 2 * fs) >> 5)
        else:
            y = fs - 16
        mag = 0x7FFFFF if y >= fs else (y >> 4)
        return -mag if neg else mag

    def step(self, sample):
        """One sample of the mix (integer, 24 bit scale) -> 24 bit output."""
        lim = (1 << 26)
        v = lim - 1 if sample > lim - 1 else -lim if sample < -lim else sample
        x = v << 4
        x = self._soundboard(x)
        x = self._reverb(x)
        x = self._eq(x)
        return self._limiter(x)

    def process(self, samples):
        return np.array([self.step(int(v)) for v in samples], dtype=np.int64)


if __name__ == "__main__":
    import pianolib as pl
    args = sys.argv[1:]
    if len(args) < 2:
        print(__doc__)
        sys.exit(0)
    x, fs = pl.read_wav(args[0])
    eq = int(args[args.index("--eq") + 1]) if "--eq" in args else 0
    fx = Fx(soundboard="--no-soundboard" not in args, reverb="--no-reverb" not in args, eq_preset=eq)
    y = fx.process(np.round(x * (1 << 23)).astype(np.int64))
    pl.write_wav_int(args[1], y, fs)
    print("wrote", args[1], "peak %.1f dBFS" % (20 * np.log10(max(1, np.abs(y).max()) / 2.0 ** 23)))
