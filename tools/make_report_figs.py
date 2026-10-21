"""Figures and tables from the audio made by make_report_audio.py.

    python tools/make_report_figs.py        (run from piano_v2)

Reads build/metrics.json and audio/*.wav, writes docs/img/*.png and
docs/metrics.md.
"""
import json
import os

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

import pianolib as pl
from fx_model import Fx

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
os.chdir(ROOT)
os.makedirs("docs/img", exist_ok=True)
FS = 48000

OLD, AMY, NEW = "#8a8a8a", "#d1495b", "#00798c"
plt.rcParams.update({"font.size": 9, "axes.grid": True, "grid.alpha": 0.3, "figure.dpi": 110})


def wav(kind, tag):
    path = "audio/%s_%s.wav" % (kind, tag)
    if not os.path.exists(path):
        return None
    x, _ = pl.read_wav(path)
    return x * 16.0            # AMY amplitude units for all three


def spectrogram(ax, x, title, fmax=6000):
    n, hop = 2048, 256
    w = np.hanning(n)
    frames = np.array([x[i:i + n] * w for i in range(0, len(x) - n, hop)])
    s = 20 * np.log10(np.abs(np.fft.rfft(frames, axis=1)) / (n / 4) + 1e-9)
    f = np.fft.rfftfreq(n, 1.0 / FS)
    k = f <= fmax
    ax.imshow(s[:, k].T, origin="lower", aspect="auto", cmap="magma", vmin=-90, vmax=-10,
              extent=[0, len(x) / FS, 0, fmax])
    ax.set_title(title)
    ax.set_xlabel("time [s]")
    ax.grid(False)


def fig_spectrograms(tag="C4_v100"):
    kinds = [("old", "previous voice (RTL simulation)"), ("amy", "AMY algorithm (numpy port)"),
             ("new", "new engine (bit-exact model of the RTL)")]
    fig, axes = plt.subplots(1, 3, figsize=(13, 3.6), sharey=True)
    for ax, (kind, title) in zip(axes, kinds):
        x = wav(kind, tag)
        if x is not None:
            spectrogram(ax, x, title)
    axes[0].set_ylabel("frequency [Hz]")
    fig.suptitle("C4, velocity 100, key released at 2.0 s", y=1.02)
    fig.savefig("docs/img/spectrogram_C4_v100.png", bbox_inches="tight")
    plt.close(fig)


def fig_partials(metrics, tag="C4_v80"):
    m = metrics[tag]
    t = np.array(m["amy"]["track_t"])
    fig, axes = plt.subplots(2, 3, figsize=(13, 5.6), sharex=True, sharey=True)
    for i, ax in enumerate(axes.flat):
        for kind, col, lab in (("old", OLD, "previous"), ("amy", AMY, "AMY algorithm"), ("new", NEW, "new engine")):
            if kind in m and i < len(m[kind]["partials"]):
                ax.plot(t, np.maximum(m[kind]["partials"][i]["db"], -100), color=col, label=lab, lw=1.3)
        ax.set_title("partial %d" % (i + 1))
        ax.set_ylim(-100, 5)
        ax.set_xlim(0, 2.6)
    axes[0, 0].legend(loc="lower left")
    for ax in axes[1]:
        ax.set_xlabel("time [s]")
    for ax in axes[:, 0]:
        ax.set_ylabel("amplitude [dB re 1.0]")
    fig.suptitle("C4, velocity 80: amplitude of each partial over time (key released at 2.0 s)")
    fig.savefig("docs/img/partials_C4_v80.png", bbox_inches="tight")
    plt.close(fig)


def fig_velocity(note="C4"):
    fig, axes = plt.subplots(1, 3, figsize=(13, 3.4), sharey=True)
    for ax, (kind, title) in zip(axes, (("old", "previous voice"), ("amy", "AMY algorithm"), ("new", "new engine"))):
        for vel, ls in ((40, ":"), (80, "--"), (120, "-")):
            x = wav(kind, "%s_v%d" % (note, vel))
            if x is None:
                continue
            t, c = pl.spectral_centroid_track(x[:int(1.9 * FS)], FS)
            ax.plot(t, c, ls, color="k", label="velocity %d" % vel)
        ax.set_title(title)
        ax.set_xlabel("time [s]")
        ax.set_yscale("log")
    axes[0].set_ylabel("spectral centroid [Hz]")
    axes[0].legend()
    fig.suptitle("%s: brightness over time at three velocities" % note, y=1.02)
    fig.savefig("docs/img/velocity_brightness_%s.png" % note, bbox_inches="tight")
    plt.close(fig)


def fig_attack_release(tag="C4_v100"):
    fig, axes = plt.subplots(2, 3, figsize=(13, 5), sharey="row")
    for j, (kind, title, col) in enumerate((("old", "previous voice", OLD), ("amy", "AMY algorithm", AMY),
                                            ("new", "new engine", NEW))):
        x = wav(kind, tag)
        if x is None:
            continue
        n = int(0.05 * FS)
        axes[0, j].plot(np.arange(n) / FS * 1000, x[:n], color=col, lw=0.8)
        axes[0, j].set_title(title + ": first 50 ms")
        axes[0, j].set_xlabel("time [ms]")
        t, e = pl.rms_envelope(x, FS, 0.005)
        axes[1, j].plot(t, pl.db(e), color=col)
        axes[1, j].axvline(2.0, color="k", lw=0.6, ls=":")
        axes[1, j].set_ylim(-90, 10)
        axes[1, j].set_title("RMS level (key released at 2.0 s)")
        axes[1, j].set_xlabel("time [s]")
    axes[0, 0].set_ylabel("amplitude")
    axes[1, 0].set_ylabel("level [dB]")
    fig.tight_layout()
    fig.savefig("docs/img/attack_release_C4_v100.png", bbox_inches="tight")
    plt.close(fig)


def fig_fx():
    n = 1 << 15
    imp = np.zeros(n, dtype=np.int64)
    imp[0] = 1 << 20
    fig, axes = plt.subplots(1, 2, figsize=(11, 3.6))
    f = np.fft.rfftfreq(n, 1.0 / FS)
    for label, kw, col in (("soundboard", dict(reverb=False), NEW),
                           ("EQ warm", dict(soundboard=False, reverb=False, eq_preset=1), AMY),
                           ("EQ bright", dict(soundboard=False, reverb=False, eq_preset=2), "#edae49")):
        h = Fx(gain_shift=0, limiter_soft=False, **kw).process(imp).astype(float) / (1 << 20)
        axes[0].semilogx(f[1:], 20 * np.log10(np.abs(np.fft.rfft(h))[1:] + 1e-9), color=col, label=label)
    axes[0].set_xlim(30, 20000)
    axes[0].set_ylim(-6, 8)
    axes[0].set_xlabel("frequency [Hz]")
    axes[0].set_ylabel("gain [dB]")
    axes[0].set_title("frequency response of the soundboard and the EQ presets")
    axes[0].legend()

    rng = np.random.RandomState(3)
    x = np.concatenate([rng.randint(-4000000, 4000000, 4800), np.zeros(2 * FS)]).astype(np.int64)
    y = Fx(soundboard=False, gain_shift=0, limiter_soft=False).process(x).astype(float)[4800:]
    e = np.cumsum(y[::-1] ** 2)[::-1]
    ed = 10 * np.log10(e / e[0] + 1e-30)
    axes[1].plot(np.arange(len(ed)) / FS, ed, color=NEW)
    i5, i35 = int(np.argmax(ed < -5)), int(np.argmax(ed < -35))
    rt60 = 2.0 * (i35 - i5) / FS
    axes[1].set_ylim(-80, 3)
    axes[1].set_xlim(0, 1.6)
    axes[1].set_xlabel("time after the end of a noise burst [s]")
    axes[1].set_ylabel("remaining energy [dB]")
    axes[1].set_title("reverb decay: RT60 = %.2f s" % rt60)
    fig.tight_layout()
    fig.savefig("docs/img/fx_response.png", bbox_inches="tight")
    plt.close(fig)
    return rt60


def env_error(m, kind, kmax=6):
    """Mean |dB difference| to the AMY partial tracks, 30 ms .. 1.9 s, while the AMY partial is above -60 dB."""
    t = np.array(m["amy"]["track_t"])
    sel = (t > 0.03) & (t < 1.9)
    errs = []
    for i in range(min(kmax, len(m["amy"]["partials"]), len(m[kind]["partials"]))):
        a = np.array(m["amy"]["partials"][i]["db"])[sel]
        b = np.array(m[kind]["partials"][i]["db"])[sel]
        ok = a > -60
        if ok.sum() > 10:
            errs.append(np.mean(np.abs(np.maximum(b[ok], -100) - a[ok])))
    return float(np.mean(errs)) if errs else float("nan")


def tables(metrics, rt60):
    lines = ["# Measurements", "",
             "Made by `tools/make_report_audio.py` and `tools/make_report_figs.py`.",
             "All numbers are digital-domain: one voice, no effects, no DAC, no loudspeaker.", "",
             "- **previous**: the unchanged `voice.v` chain, RTL simulation",
             "- **AMY**: numpy port of the AMY piano algorithm (not AMY's own binary)",
             "- **new**: integer model that is bit-exact with `piano_partial_voice.v` (hammer muted for the partial measurements)",
             "", "## Level, decay, release, brightness", "",
             "| note | vel | version | peak RMS [dB] | level after 1 s [dB re peak] | release to -30 dB [ms] | centroid 50 ms [Hz] | centroid 1.5 s [Hz] |",
             "|---|---|---|---|---|---|---|---|"]
    for tag, m in metrics.items():
        note, vel = tag.split("_v")
        for kind, name in (("old", "previous"), ("amy", "AMY"), ("new", "new")):
            if kind in m:
                r = m[kind]
                lines.append("| %s | %s | %s | %.1f | %.1f | %.0f | %.0f | %.0f |" % (
                    note, vel, name, r["peak_rms_db"], r["decay_db_at_1s"], r["release_ms_to_-30db"],
                    r["centroid_hz_50ms"], r["centroid_hz_1500ms"]))
    lines += ["", "## Partial frequencies: deviation from the AMY analysis [cent]", "",
              "A real piano string is slightly inharmonic: partial k lies above k times the fundamental.",
              "The previous voice reads one fixed wave cycle, so its partials are exact multiples.", "",
              "| note | vel | version | k=1 | k=2 | k=3 | k=4 | k=5 | k=6 |", "|---|---|---|---|---|---|---|---|---|"]
    for tag, m in metrics.items():
        note, vel = tag.split("_v")
        if vel != "80":
            continue
        for kind, name in (("old", "previous"), ("new", "new")):
            if kind in m:
                c = ["%.1f" % p["cents_vs_ref"] for p in m[kind]["partials"][:6]]
                c += [""] * (6 - len(c))
                lines.append("| %s | %s | %s | %s |" % (note, vel, name, " | ".join(c)))
    lines += ["", "## Partial envelopes: mean distance to the AMY envelopes [dB]", "",
              "Mean absolute difference of the amplitude of partials 1..6, 30 ms to 1.9 s,",
              "wherever the AMY partial is above -60 dB.  Smaller is closer.", "",
              "| note | vel | previous | new |", "|---|---|---|---|"]
    olds, news = [], []
    for tag, m in metrics.items():
        note, vel = tag.split("_v")
        eo = env_error(m, "old") if "old" in m else float("nan")
        en = env_error(m, "new")
        olds.append(eo)
        news.append(en)
        lines.append("| %s | %s | %.1f | %.1f |" % (note, vel, eo, en))
    lines.append("| **mean** | | **%.1f** | **%.1f** |" % (np.nanmean(olds), np.nanmean(news)))
    lines += ["", "## Brightness and velocity", "",
              "Spectral centroid 50 ms after the strike, velocity 120 divided by velocity 40.",
              "1.0 means the timbre does not change with velocity (only the volume does).", "",
              "| note | previous | AMY | new |", "|---|---|---|---|"]
    for note in ("C3", "C4", "C5", "Eb5"):
        row = []
        for kind in ("old", "amy", "new"):
            try:
                row.append("%.2f" % (metrics["%s_v120" % note][kind]["centroid_hz_50ms"] /
                                     metrics["%s_v40" % note][kind]["centroid_hz_50ms"]))
            except KeyError:
                row.append("-")
        lines.append("| %s | %s |" % (note, " | ".join(row)))
    lines += ["", "## Effects", "", "Reverb RT60 measured on the model: **%.2f s**." % rt60, ""]
    with open("docs/metrics.md", "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")
    print("\n".join(lines[-28:]))


def main():
    with open("build/metrics.json") as f:
        metrics = json.load(f)
    fig_spectrograms()
    fig_partials(metrics)
    fig_velocity()
    fig_attack_release()
    rt60 = fig_fx()
    tables(metrics, rt60)
    print("figures in docs/img:", sorted(os.listdir("docs/img")))


if __name__ == "__main__":
    main()
