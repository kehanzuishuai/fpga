"""Short demo phrases rendered with the bit-exact models (run from piano_v2).

    python tools/make_demo.py

    audio/demo_keys_v100.wav       what the 16 touch keys can play: fixed velocity 100
    audio/demo_keys_v100_dry.wav   the same without soundboard / reverb
    audio/demo_dynamics.wav        the same notes with changing velocity (needs a
                                   velocity-sensitive keyboard, not the TTP229)

Every note is one Voice model; the sum goes through the effects model, exactly
as in the FPGA (constant mix gain, output gain x2, soft limiter).
"""
import numpy as np

import fpga_piano_model as fm
import piano_tables as pt
import pianolib as pl
from fx_model import Fx

FS = 48000


def render(events, total_s, fx=True):
    """events: (start_s, note, velocity, length_s)"""
    tables = pt.build()
    n = int(total_s * FS)
    mix = np.zeros(n, dtype=np.int64)
    for i, (t0, note, vel, dur) in enumerate(events):
        a = int(t0 * FS)
        m = n - a
        y = fm.render_note(tables, note, vel, m, off_sample=int(dur * FS), voice_index=i % 32)
        mix[a:] += y
    mixq = (mix * 32767) >> 15
    return Fx(soundboard=fx, reverb=fx).process(mixq), mix


def phrase(vel_of):
    ev = []
    t = 0.2
    # rising arpeggio C E G C' E'b... inside the 16 keys (MIDI 60..75)
    for i, note in enumerate((60, 64, 67, 72, 67, 64)):
        ev.append((t, note, vel_of(len(ev)), 0.45))
        t += 0.30
    # melody over held chords
    for chord, mel in (((60, 64, 67), (72, 74, 72)), ((62, 65, 69), (74, 72, 69)), ((60, 64, 67), (72, 67, 64))):
        for c in chord:
            ev.append((t, c, vel_of(len(ev)), 1.30))
        for k, m in enumerate(mel):
            ev.append((t + 0.02 + 0.43 * k, m, vel_of(len(ev)), 0.40))
        t += 1.35
    ev.append((t, 60, vel_of(len(ev)), 2.2))
    ev.append((t, 67, vel_of(len(ev)), 2.2))
    ev.append((t, 72, vel_of(len(ev)), 2.2))
    return ev, t + 3.4


def main():
    ev, total = phrase(lambda i: 100)
    y, mix = render(ev, total, fx=True)
    pl.write_wav_int("audio/demo_keys_v100.wav", y)
    yd, _ = render(ev, total, fx=False)
    pl.write_wav_int("audio/demo_keys_v100_dry.wav", yd)
    vels = [52, 60, 70, 84, 96, 108, 70, 64, 60, 92, 100, 96, 80, 76, 72, 104, 112, 100, 64, 60, 56, 90, 78, 66, 58, 62, 70]
    ev2, total2 = phrase(lambda i: vels[i % len(vels)])
    y2, _ = render(ev2, total2, fx=True)
    pl.write_wav_int("audio/demo_dynamics.wav", y2)
    for name, v in (("demo_keys_v100", y), ("demo_keys_v100_dry", yd), ("demo_dynamics", y2)):
        print("audio/%s.wav  %.1f s  peak %.1f dBFS  rms %.1f dBFS" % (
            name, len(v) / FS, 20 * np.log10(np.abs(v).max() / 2.0 ** 23),
            10 * np.log10(np.mean((v / 2.0 ** 23) ** 2))))
    over = np.count_nonzero(np.abs((mix * 32767) >> 15) * 2 > (1 << 22))
    print("samples above the limiter knee (0.5 full scale): %.1f %%" % (100.0 * over / len(mix)))


if __name__ == "__main__":
    main()
