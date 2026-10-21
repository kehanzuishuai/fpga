"""Shared code for the piano tools.

- loading the AMY partial table (tools/amy_data/amy_piano_params.json)
- amy_note_params():  the note-on interpolation of AMY's interp_partials.c
- amy_render():       numpy port of the AMY kernel signal path for the piano
                      (interp_partials.c + envelope.c + render_lut_256)
- WAV helpers and a few measurement helpers

The port follows AMY commit 69a1469 (v1.2.192).  It is a re-implementation in
floating point, not AMY's own binary: use it as "what the AMY algorithm
produces", not as a bit-exact AMY recording.
"""
import json
import os
import struct
import wave

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
PARAMS_JSON = os.path.join(HERE, "amy_data", "amy_piano_params.json")

FS = 48000

_cache = {}


def load_params():
    if "p" not in _cache:
        with open(PARAMS_JSON, encoding="utf-8") as f:
            p = json.load(f)
        p["num_harmonics"] = np.array(p["num_harmonics"], dtype=int)
        p["start"] = np.concatenate([[0], np.cumsum(p["num_harmonics"])])
        p["freq"] = np.array(p["harmonics_freq_cents"], dtype=float)
        p["mags"] = np.array(p["harmonics_mags_db"], dtype=float)
        p["times"] = np.array(p["sample_times_ms"], dtype=float)
        p["use"] = np.array(p["use_this_partial_map"], dtype=bool)
        _cache["p"] = p
    return _cache["p"]


def note_vel_rows(pitch_index, vel_index):
    """(cents[h], mags_db[h, 20]) of one stored note/velocity."""
    p = load_params()
    n = len(p["velocities"]) * pitch_index + vel_index
    s, e = p["start"][n], p["start"][n + 1]
    return p["freq"][s:e], p["mags"][s:e]


def cents_to_hz(cents):
    return 440.0 * 2.0 ** ((np.asarray(cents, dtype=float) - 6900.0) / 1200.0)


def env_lin_of_db(db):
    """AMY _env_lin_of_db: 100 dB -> 1.0, clipped at +20 dB, offset by -0.001."""
    lin = 10.0 ** (np.minimum(20.0, np.asarray(db, dtype=float) - 100.0) / 20.0) - 0.001
    return np.maximum(lin, 0.0)


def amy_note_params(note, vel, max_harmonics=40, use_map=True):
    """Port of interp_partials_note_on(): returns (harmonic_numbers, cents, mags_db).

    cents[k], mags_db[k, 20] are the bilinearly interpolated (pitch x velocity)
    log-domain parameters of the partials AMY would play.  harmonic_numbers[k]
    is the 1-based index in the stored harmonic list.
    """
    p = load_params()
    pitches = p["notes"]
    vels = p["velocities"]
    midi_vel = float(np.clip(round(vel), vels[0], vels[-1]))

    pi = 0
    while pi < len(pitches) - 2 and pitches[pi + 1] < note:
        pi += 1
    vi = 0
    while vi < len(vels) - 1 and vels[vi + 1] < midi_vel:
        vi += 1
    vi = min(vi, len(vels) - 2)

    pa = (note - pitches[pi]) / float(pitches[pi + 1] - pitches[pi])
    va = (midi_vel - vels[vi]) / float(vels[vi + 1] - vels[vi])

    rows = [note_vel_rows(pi, vi), note_vel_rows(pi, vi + 1),
            note_vel_rows(pi + 1, vi), note_vel_rows(pi + 1, vi + 1)]
    w = [(1 - pa) * (1 - va), (1 - pa) * va, pa * (1 - va), pa * va]
    nh = min(max_harmonics, min(len(r[0]) for r in rows))

    hn, cents, mags = [], [], []
    for h in range(nh):
        if use_map and not p["use"][h]:
            continue
        hn.append(h + 1)
        cents.append(sum(wi * r[0][h] for wi, r in zip(w, rows)))
        mags.append(sum(wi * r[1][h] for wi, r in zip(w, rows)))
    return np.array(hn), np.array(cents), np.array(mags)


def _amy_eg_normal(v0, v1, ratio):
    """ENVELOPE_NORMAL ("false exponential") segment of AMY envelope.c."""
    k = 1.0 / (1.0 - 2.0 ** -4.328085)
    return np.maximum(v0 + (v1 - v0) * k * (1.0 - 2.0 ** (-4.328085 * ratio)), 0.0)


def amy_render(note, vel, dur_s, release_s=None, fs=FS, block=256,
               max_harmonics=40, use_map=True, partial_select=None):
    """Numpy port of the AMY piano signal path.  Returns float samples
    (AMY amplitude units: one partial at 100 dB has amplitude 1.0).

    release_s: time of the note-off, None = key held for the whole duration.
    partial_select: optional list of harmonic numbers to keep.
    """
    p = load_params()
    hn, cents, mags_db = amy_note_params(note, vel, max_harmonics, use_map)
    if partial_select is not None:
        keep = np.isin(hn, partial_select)
        hn, cents, mags_db = hn[keep], cents[keep], mags_db[keep]

    n = int(round(dur_s * fs))
    nblocks = (n + block - 1) // block
    t_end = np.round(p["times"] * fs / 1000.0).astype(int)      # breakpoint end times, samples
    rel_len = int(200 * fs / 1000)
    rel_block = None if release_s is None else int(round(release_s * fs)) // block

    sine_lut = np.sin(2 * np.pi * np.arange(257) / 256.0)
    out = np.zeros(nblocks * block)
    idx = np.arange(block)

    for k in range(len(hn)):
        f_hz = cents_to_hz(cents[k])
        if f_hz >= fs / 2:
            continue
        vals = np.concatenate([[0.0], env_lin_of_db(mags_db[k])])
        times = np.concatenate([[0], t_end])
        step = f_hz / fs
        phase = 0.0
        last_amp = 0.0
        last_scale = 0.0
        for b in range(nblocks):
            if rel_block is not None and b >= rel_block:
                el = (b - rel_block) * block
                scale = 0.0 if el > rel_len else _amy_eg_normal(last_scale, 0.0, el / rel_len) if el > 0 else last_scale
            else:
                el = b * block + 1
                seg = np.searchsorted(times[1:], el, side="right")
                if seg >= len(t_end):
                    scale = vals[-1]                       # sustain at the last breakpoint
                else:
                    t0, t1 = times[seg], times[seg + 1]
                    v0, v1 = vals[seg], vals[seg + 1]
                    scale = v1 if (el == t1 or v0 == v1) else _amy_eg_normal(v0, v1, (el - t0) / float(t1 - t0))
                last_scale = scale
            amp = scale if scale > 0.0011 else 0.0
            if amp > 0 or last_amp > 0:
                ph = phase + step * idx
                pos = (ph % 1.0) * 256.0
                i0 = pos.astype(int)
                fr = pos - i0
                s = sine_lut[i0] + (sine_lut[i0 + 1] - sine_lut[i0]) * fr
                a = last_amp + (amp - last_amp) * idx / block
                out[b * block:(b + 1) * block] += s * a
            phase = (phase + step * block) % 1.0
            last_amp = amp
    return out[:n]


# ----------------------------------------------------------------------------
# WAV helpers
# ----------------------------------------------------------------------------

def write_wav(path, x, fs=FS, bits=24, scale=1.0):
    """Write mono PCM.  x is float in [-1, 1) after multiplying by scale."""
    y = np.asarray(x, dtype=float) * scale
    full = float(1 << (bits - 1))
    q = np.clip(np.round(y * full), -full, full - 1).astype(np.int64)
    os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(bits // 8)
        w.setframerate(fs)
        if bits == 16:
            w.writeframes(q.astype("<i2").tobytes())
        else:
            b = bytearray()
            for v in q:
                b += struct.pack("<i", int(v))[:3]
            w.writeframes(bytes(b))


def write_wav_int(path, q, fs=FS, bits=24):
    """Write mono PCM from integer samples (already in the range of `bits`)."""
    q = np.asarray(q, dtype=np.int64)
    os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(bits // 8)
        w.setframerate(fs)
        if bits == 16:
            w.writeframes(q.astype("<i2").tobytes())
        else:
            raw = (q & 0xFFFFFF).astype("<u4").tobytes()
            w.writeframes(bytes(np.frombuffer(raw, dtype=np.uint8).reshape(-1, 4)[:, :3].tobytes()))


def read_wav(path):
    """Returns (float samples in [-1, 1), fs).  Mono or first channel."""
    with wave.open(path, "rb") as w:
        fs = w.getframerate()
        nch = w.getnchannels()
        sw = w.getsampwidth()
        raw = w.readframes(w.getnframes())
    a = np.frombuffer(raw, dtype=np.uint8).reshape(-1, sw * nch)[:, :sw]
    if sw == 2:
        v = a.copy().view("<i2").astype(float).reshape(-1) / 32768.0
    elif sw == 3:
        pad = np.zeros((a.shape[0], 4), dtype=np.uint8)
        pad[:, :3] = a
        v = pad.view("<i4").reshape(-1).astype(np.int64)
        v = np.where(v >= 1 << 23, v - (1 << 24), v).astype(float) / float(1 << 23)
    else:
        raise ValueError("unsupported sample width %d" % sw)
    return v, fs


def read_pcm_txt(path):
    """Read one signed decimal sample per line (written by the test benches)."""
    with open(path) as f:
        return np.array([int(s) for s in f.read().split()], dtype=np.int64)


# ----------------------------------------------------------------------------
# Measurements
# ----------------------------------------------------------------------------

def partial_track(x, f_hz, fs=FS, win_s=0.020, hop_s=0.004):
    """Amplitude of the component at f_hz over time (heterodyne + Hann window).

    Returns (times_s, amplitude) where amplitude is the peak amplitude of the
    sinusoid in the units of x."""
    n = len(x)
    t = np.arange(n) / fs
    z = x * np.exp(-2j * np.pi * f_hz * t)
    w = np.hanning(int(win_s * fs))
    w /= w.sum()
    hop = int(hop_s * fs)
    base = np.convolve(z, w, mode="same")[::hop]
    return t[::hop], 2.0 * np.abs(base)


def refine_freq(x, f_guess, fs=FS, t0=0.05, t1=0.6, span_cents=40):
    """Frequency of the strongest component near f_guess (zero-padded FFT)."""
    a, b = int(t0 * fs), min(len(x), int(t1 * fs))
    seg = x[a:b] * np.hanning(b - a)
    nfft = 1 << 20
    spec = np.abs(np.fft.rfft(seg, nfft))
    lo = f_guess * 2 ** (-span_cents / 1200.0)
    hi = f_guess * 2 ** (span_cents / 1200.0)
    i0, i1 = int(lo * nfft / fs), int(hi * nfft / fs) + 1
    k = i0 + int(np.argmax(spec[i0:i1]))
    if 0 < k < len(spec) - 1:
        y0, y1, y2 = np.log(spec[k - 1] + 1e-30), np.log(spec[k] + 1e-30), np.log(spec[k + 1] + 1e-30)
        d = 0.5 * (y0 - y2) / (y0 - 2 * y1 + y2)
    else:
        d = 0.0
    return (k + d) * fs / nfft


def db(x, floor=1e-12):
    return 20.0 * np.log10(np.maximum(np.abs(x), floor))


def rms_envelope(x, fs=FS, win_s=0.010):
    n = int(win_s * fs)
    m = len(x) // n
    return (np.arange(m) + 0.5) * win_s, np.sqrt(np.mean(x[:m * n].reshape(m, n) ** 2, axis=1))


def spectral_centroid_track(x, fs=FS, win_s=0.030, hop_s=0.010):
    n = int(win_s * fs)
    hop = int(hop_s * fs)
    w = np.hanning(n)
    f = np.fft.rfftfreq(n, 1.0 / fs)
    ts, cs = [], []
    for s in range(0, len(x) - n, hop):
        mag = np.abs(np.fft.rfft(x[s:s + n] * w))
        tot = mag.sum()
        ts.append((s + n / 2) / fs)
        cs.append((f * mag).sum() / tot if tot > 1e-9 else 0.0)
    return np.array(ts), np.array(cs)


def spectral_flux(x, fs=FS, win_s=0.010, hop_s=0.0025):
    n = int(win_s * fs)
    hop = int(hop_s * fs)
    w = np.hanning(n)
    prev = None
    ts, fl = [], []
    for s in range(0, len(x) - n, hop):
        mag = np.abs(np.fft.rfft(x[s:s + n] * w))
        if prev is not None:
            ts.append((s + n / 2) / fs)
            fl.append(np.sum(np.maximum(mag - prev, 0.0)))
        prev = mag
    return np.array(ts), np.array(fl)
