"""Reference audio, measurements and figures for docs/ (run from piano_v2).

    python tools/make_report_audio.py            everything
    python tools/make_report_audio.py --no-sim   skip the RTL simulation of the old voice

Writes
    audio/old_*.wav     the previous voice.v, RTL simulation (digital output of one voice)
    audio/amy_*.wav     numpy port of the AMY piano algorithm (tools/pianolib.amy_render)
    audio/new_*.wav     the new engine: integer model that is bit-exact with the RTL
    audio/new_fx_*.wav  the same through the effects model (soundboard, reverb, limiter)
    audio/demo_*.wav    a short phrase, old / new / new with effects
    docs/img/*.png      figures
    docs/metrics.md     tables

Scale of the WAV files: old/new are the 24 bit voice output as it is;
amy_* is scaled so that amplitude 16.0 (the full scale of the new engine)
is digital full scale, i.e. new_* and amy_* are directly comparable.
"""
import concurrent.futures as cf
import json
import os
import subprocess
import sys

import numpy as np

import fpga_piano_model as fm
import piano_tables as pt
import pianolib as pl
from fx_model import Fx

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
os.chdir(ROOT)
os.makedirs("audio", exist_ok=True)
os.makedirs("docs/img", exist_ok=True)
os.makedirs("build", exist_ok=True)

FS = 48000
DUR = 3.0
OFF = 2.0
NOTES = [(48, "C3"), (60, "C4"), (72, "C5"), (75, "Eb5")]
VELS = [40, 80, 120]
N = int(DUR * FS)
N_OFF = int(OFF * FS)

oss = os.environ.get("OSS_CAD", r"C:\fpga\tools\oss-cad-suite")
if os.path.isdir(oss):
    os.environ["PATH"] = os.path.join(oss, "bin") + os.pathsep + os.path.join(oss, "lib") + os.pathsep + os.environ["PATH"]


def legacy_render(args):
    note, vel = args
    out = "build/legacy_n%d_v%d.txt" % (note, vel)
    if not os.path.exists(out) or os.path.getsize(out) < 100000:
        subprocess.run(["vvp", "-n", "build/tb_legacy.vvp", "+note=%d" % note, "+vel=%d" % vel,
                        "+off=%d" % (N_OFF + 4), "+ticks=%d" % (N + 8), "+out=" + out],
                       capture_output=True, text=True)
    x = pl.read_pcm_txt(out)
    return note, vel, x[5:5 + N]


def build_legacy():
    files = ["sim/tb/tb_legacy_voice.v", "sim/models/piano_dual_wavetable_fast.v", "src/voice.v",
             "src/piano_string_model.v", "src/piano_envelope.v", "src/dds_phase_accum.v", "src/note_freq_table.v"]
    r = subprocess.run(["iverilog", "-g2005", "-o", "build/tb_legacy.vvp"] + files, capture_output=True, text=True)
    if r.returncode != 0:
        raise SystemExit(r.stdout + r.stderr)


def to_units(x_int):
    """24 bit integer -> AMY amplitude units (full scale = 16.0)."""
    return np.asarray(x_int, dtype=float) / 2.0 ** 23 * 16.0


def note_metrics(x, note, vel, ref_partials):
    """x in AMY amplitude units.  ref_partials: list of (harmonic number, Hz)."""
    out = {}
    t, env = pl.rms_envelope(x, FS, 0.010)
    peak_i = int(np.argmax(env))
    out["peak_rms_db"] = float(pl.db(env.max()))
    out["attack_ms_to_peak"] = float(t[peak_i] * 1000)
    # level 1 s after the strike, relative to the peak: a piano decays, an organ does not
    out["decay_db_at_1s"] = float(pl.db(env[int(1.0 / 0.010)]) - pl.db(env.max()))
    # release: time from note-off until 30 dB below the level at note-off
    i_off = int(OFF / 0.010)
    lvl = env[i_off - 1]
    below = np.nonzero(env[i_off:] < lvl * 10 ** (-30 / 20.0))[0]
    out["release_ms_to_-30db"] = float(below[0] * 10) if len(below) else float("nan")
    # brightness
    tc, c = pl.spectral_centroid_track(x, FS)
    out["centroid_hz_50ms"] = float(np.interp(0.05, tc, c))
    out["centroid_hz_500ms"] = float(np.interp(0.5, tc, c))
    out["centroid_hz_1500ms"] = float(np.interp(1.5, tc, c))
    tf, fl = pl.spectral_flux(x[:int(0.06 * FS)], FS)
    out["attack_flux_peak_ms"] = float(tf[int(np.argmax(fl))] * 1000) if len(fl) else float("nan")
    # partials
    part = []
    for k, f_ref in ref_partials:
        f = pl.refine_freq(x, f_ref, FS, 0.05, 0.8, span_cents=60)
        tt, a = pl.partial_track(x, f, FS)
        part.append({"k": int(k), "hz": float(f), "cents_vs_ref": float(1200 * np.log2(f / f_ref)),
                     "db": pl.db(a).tolist()})
    out["partials"] = part
    out["track_t"] = tt.tolist()
    return out


def main():
    do_sim = "--no-sim" not in sys.argv
    tables = pt.build()
    jobs = [(n, v) for n, _ in NOTES for v in VELS + [100]]

    legacy = {}
    if do_sim:
        build_legacy()
        with cf.ThreadPoolExecutor(max_workers=6) as ex:
            for note, vel, x in ex.map(legacy_render, jobs):
                legacy[(note, vel)] = x
    metrics = {}
    for note, name in NOTES:
        for vel in VELS + [100]:
            tag = "%s_v%d" % (name, vel)
            new = fm.render_note(tables, note, vel, N, off_sample=N_OFF)
            new_nh = fm.render_note(tables, note, vel, N, off_sample=N_OFF, hammer=False)
            amy = pl.amy_render(note, vel, DUR, release_s=OFF)
            pl.write_wav_int("audio/new_%s.wav" % tag, new)
            pl.write_wav("audio/amy_%s.wav" % tag, amy, scale=1.0 / 16.0)
            if vel == 100:
                pl.write_wav_int("audio/new_nohammer_%s.wav" % tag, new_nh)
                pl.write_wav_int("audio/new_fx_%s.wav" % tag, Fx().process(new))
            hn, cents, _ = pl.amy_note_params(note, vel)
            ref = [(int(k), float(pl.cents_to_hz(c))) for k, c in zip(hn, cents) if k <= 8 and pl.cents_to_hz(c) < 20000]
            m = {"new": note_metrics(to_units(new_nh), note, vel, ref),
                 "amy": note_metrics(amy, note, vel, ref)}
            if (note, vel) in legacy:
                old = legacy[(note, vel)]
                pl.write_wav_int("audio/old_%s.wav" % tag, old)
                m["old"] = note_metrics(to_units(old), note, vel, ref)
            metrics[tag] = m
            print("rendered", tag)

    with open("build/metrics.json", "w") as f:
        json.dump(metrics, f)
    print("wrote build/metrics.json")


if __name__ == "__main__":
    main()
