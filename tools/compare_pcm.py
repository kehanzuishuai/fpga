"""Compare the RTL voice with the integer model, sample by sample.

    python tools/compare_pcm.py [build/voice_log.txt] [--hammer 0|1] [--voice N] [--wav out.wav]

--voice N: number of the voice inside voice_bank (selects its noise seed).

The log is written by sim/tb/tb_piano_voice.v:
    L <tick> <note> <velocity>      loader finished after this tick
    S <tick> <sample> <rel> <fade>  one computed sample
Exit code 0 only if every sample is identical.
"""
import sys

import numpy as np

import fpga_piano_model as fm
import piano_tables as pt
import pianolib as pl


def main():
    args = sys.argv[1:]
    path = "build/voice_log.txt"
    hammer = True
    wav = None
    voice_index = 0
    i = 0
    while i < len(args):
        if args[i] == "--hammer":
            hammer = args[i + 1] != "0"
            i += 2
        elif args[i] == "--voice":
            voice_index = int(args[i + 1])
            i += 2
        elif args[i] == "--wav":
            wav = args[i + 1]
            i += 2
        else:
            path = args[i]
            i += 1

    tables = pt.build()
    v = fm.Voice(tables, voice_index, hammer)
    tick = 0                      # next tick the model will render
    rtl, mod = [], []
    mismatches = 0
    first_bad = None
    notes = 0

    def advance_idle(to_tick):
        """Ticks without an RTL sample: the voice is idle or loading."""
        nonlocal tick, mismatches, first_bad
        n = to_tick - tick
        if n <= 0:
            return
        was_active = v.active
        fading = v.fading
        y = v.render(n) if not (was_active and not fading and False) else None
        if np.any(y != 0):
            mismatches += int(np.count_nonzero(y))
            if first_bad is None:
                first_bad = (tick + int(np.nonzero(y)[0][0]), "model plays, RTL silent")
        rtl.extend([0] * n)
        mod.extend(y.tolist())
        tick = to_tick

    with open(path) as f:
        lines = [ln.split() for ln in f if ln.strip()]
    # a log cut off in the middle of its last line
    if lines and len(lines[-1]) != (4 if lines[-1][0] == "L" else 5):
        lines.pop()

    k = 0
    while k < len(lines):
        ln = lines[k]
        if ln[0] == "L":
            t, note, vel = int(ln[1]), int(ln[2]), int(ln[3])
            advance_idle(t + 1)
            v.note_on(note, vel)
            notes += 1
            k += 1
            continue
        # run of consecutive samples with the same flags
        t0, rel, fade = int(ln[1]), ln[3], ln[4]
        run = []
        while (k < len(lines) and lines[k][0] == "S" and lines[k][3] == rel and lines[k][4] == fade
               and int(lines[k][1]) == t0 + len(run)):
            run.append(int(lines[k][2]))
            k += 1
        advance_idle(t0)
        if rel == "1" and not v.releasing:
            v.note_off()
        if fade == "1" and not v.fading:
            v.steal()
        if not v.active:
            y = np.zeros(len(run), dtype=np.int64)
            v.render(len(run))
        else:
            y = v.render(len(run))
        r = np.array(run, dtype=np.int64)
        bad = np.nonzero(r != y)[0]
        if len(bad):
            mismatches += len(bad)
            if first_bad is None:
                first_bad = (t0 + int(bad[0]), "rtl %d model %d" % (r[bad[0]], y[bad[0]]))
        rtl.extend(run)
        mod.extend(y.tolist())
        tick = t0 + len(run)

    rtl = np.array(rtl, dtype=np.int64)
    peak = int(np.abs(rtl).max()) if len(rtl) else 0
    n_rel = sum(1 for ln in lines if ln[0] == "S" and ln[3] == "1")
    n_fade = sum(1 for ln in lines if ln[0] == "S" and ln[4] == "1")
    print("notes loaded: %d, samples compared: %d, released samples: %d, fade samples: %d, "
          "RTL peak %d (%.1f dBFS)" % (notes, len(rtl), n_rel, n_fade, peak,
                                       20 * np.log10(max(peak, 1) / 2.0 ** 23)))
    if wav:
        pl.write_wav_int(wav, rtl)
        print("wrote", wav)
    if mismatches:
        print("FAIL: %d samples differ, first at tick %d (%s)" % (mismatches, first_bad[0], first_bad[1]))
        sys.exit(1)
    if notes == 0:
        print("FAIL: no note was loaded")
        sys.exit(1)
    print("PASS: RTL and model are bit-exact")


if __name__ == "__main__":
    main()
