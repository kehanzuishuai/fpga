"""Further test groups for sim/run_tests.py: effects chain, whole system, DAC outputs."""
import os
import sys

import numpy as np

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "tools"))

FX_FILES = ["sim/tb/tb_piano_fx.v", "src/piano_fx_compat.v"]


def _write_txt(path, x):
    with open(path, "w") as f:
        f.write("\n".join(str(int(v)) for v in x) + "\n")


def _read_txt(path):
    with open(path) as f:
        return np.array([int(s) for s in f.read().split()], dtype=np.int64)


def fx_inputs():
    """Test signals, in 24 bit sample units (the mix bus is wider)."""
    import fpga_piano_model as fm
    import piano_tables as pt
    rng = np.random.RandomState(1)
    fs = 48000
    t = np.arange(fs // 2) / fs
    tables = pt.build()
    chord = sum(fm.render_note(tables, n, 100, 12000, off_sample=7000, voice_index=i)
                for i, n in enumerate((60, 64, 67, 72)))
    sig = {}
    sig["piano_chord"] = chord
    sig["impulse"] = np.concatenate([[0] * 10, [6000000], [0] * 20000]).astype(np.int64)
    sig["sine_110_loud"] = np.round(7.5e6 * np.sin(2 * np.pi * 110 * t[:8000])).astype(np.int64)
    sig["noise_loud"] = rng.randint(-8000000, 8000000, 6000).astype(np.int64)
    # far beyond 24 bit: 16 voices at full scale, square wave
    sig["overload_square"] = (np.where((np.arange(4000) // 50) % 2 == 0, 1, -1) * 120000000).astype(np.int64)
    sig["burst_then_silence"] = np.concatenate([rng.randint(-6000000, 6000000, 2000), np.zeros(144000)]).astype(np.int64)
    return sig


def run_fx(report, compile_tb, sh):
    from fx_model import Fx
    sig = fx_inputs()
    builds = {}
    for gain in (0, 1):
        out = "build/tb_fx_g%d.vvp" % gain
        import subprocess
        r = subprocess.run(["iverilog", "-g2012", "-Ptb_piano_fx.GAIN=%d" % gain, "-o", out] + FX_FILES,
                           capture_output=True, text=True)
        if r.returncode != 0:
            print(r.stdout + r.stderr)
            raise SystemExit("compile failed")
        builds[gain] = out

    cases = [
        # name, signal, sb, rev, eq, soft, gain
        ("all on, natural",         "piano_chord",        1, 1, 0, 1, 1),
        ("all on, warm",            "piano_chord",        1, 1, 1, 1, 1),
        ("all on, bright",          "piano_chord",        1, 1, 2, 1, 1),
        ("soundboard only",         "piano_chord",        1, 0, 0, 1, 1),
        ("reverb only",             "piano_chord",        0, 1, 0, 1, 1),
        ("impulse",                 "impulse",            1, 1, 0, 1, 1),
        ("loud 110 Hz sine",        "sine_110_loud",      1, 1, 1, 1, 1),
        ("loud noise",              "noise_loud",         1, 1, 2, 1, 1),
        ("overload square",         "overload_square",    1, 1, 2, 1, 1),
        ("overload, hard clip",     "overload_square",    1, 1, 0, 0, 1),
        ("burst then silence",      "burst_then_silence", 1, 1, 0, 1, 1),
    ]
    for name, sname, sb, rev, eq, soft, gain in cases:
        x = sig[sname]
        fin = "build/fx_in_%s.txt" % sname
        fout = "build/fx_out.txt"
        _write_txt(fin, x)
        rc, txt = sh(["vvp", "-n", builds[gain], "+in=" + fin, "+out=" + fout,
                      "+sb=%d" % sb, "+rev=%d" % rev, "+eq=%d" % eq, "+soft=%d" % soft])
        y = _read_txt(fout)
        m = Fx(soundboard=bool(sb), reverb=bool(rev), eq_preset=eq, limiter_soft=bool(soft),
               gain_shift=gain).process(x)
        ok = "SIM DONE" in txt and len(y) == len(m) and np.array_equal(y, m)
        detail = "peak in %.1f dBFS, out %.1f dBFS" % (
            20 * np.log10(max(1, np.abs(x).max()) / 2.0 ** 23), 20 * np.log10(max(1, np.abs(y).max()) / 2.0 ** 23))
        if not ok and len(y) == len(m):
            bad = np.nonzero(y != m)[0]
            detail += " | %d differ, first at %d (rtl %d, model %d)" % (len(bad), bad[0], y[bad[0]], m[bad[0]])
        report("fx: %s bit-exact vs model" % name, ok, detail)

        if sname == "burst_then_silence":
            tail = np.abs(y[-12000:])
            report("fx: exact silence 2.75 s after a burst", tail.max() == 0, "max |out| = %d LSB" % tail.max())
            mid = np.abs(y[2000:2000 + 4800]).max()
            report("fx: reverb tail is there (first 0.1 s after the burst)", mid > 100, "max %d LSB" % mid)
        if sname == "overload_square":
            report("fx: overload stays inside 24 bit (%s)" % name, np.abs(y).max() <= 8388607,
                   "max %d" % np.abs(y).max())

    # bypass: everything off, gain 0, plain clipping -> output is the input
    x = sig["piano_chord"]
    fin = "build/fx_in_piano_chord.txt"
    rc, txt = sh(["vvp", "-n", builds[0], "+in=" + fin, "+out=build/fx_out.txt", "+sb=0", "+rev=0", "+eq=0", "+soft=0"])
    y = _read_txt("build/fx_out.txt")
    report("fx: all stages bypassed -> output equals input", np.array_equal(y, np.clip(x, -8388607, 8388607)),
           "%d samples" % len(y))
    # reverb bypass: same result as a chain that has no reverb contribution
    rc, txt = sh(["vvp", "-n", builds[0], "+in=" + fin, "+out=build/fx_out.txt", "+sb=0", "+rev=1", "+eq=0", "+soft=0"])
    y2 = _read_txt("build/fx_out.txt")
    report("fx: reverb on changes the signal, off does not", (not np.array_equal(y2, y)), "")


SKIP_RTL = ("piano_fx.v","piano_level_rom.v", "piano_ratio_rom.v", "piano_note_rom.v", "piano_sine_rom.v", "piano_exp_rom.v",
            "waveform_gen.v", "waveform_set.v", "timbre_morph.v", "adsr_env.v", "performance_mode_controller.v",
            "score_rom.v", "led_guide.v", "synth_pkg.v")


def run_system(report, compile_tb, sh):
    """Touch pad model -> complete top level -> DAC pins.  About 10 minutes."""
    rtl = sorted("src/" + f for f in os.listdir("src") if f.endswith(".v") and f not in SKIP_RTL) + ["tests/integration/video_boundary_stub.v"] + ["src/keyboard/keyboard_state_mapper.sv"]
    out = "build/tb_system.vvp"
    import subprocess
    r = subprocess.run(["iverilog", "-g2012", "-s", "tb_system", "-o", out, "sim/tb/tb_system.v",
                        "sim/models/ttp229_bfm.v", "sim/models/gowin_pll_stub.v",
                        "sim/models/i2s_rx_model.v",
                        "sim/models/piano_roms_fast.v"] + rtl, capture_output=True, text=True)
    if r.returncode != 0:
        print(r.stdout + r.stderr)
        raise SystemExit("compile failed")
    for g in range(32):
        if os.path.exists("build/sys_voice_%d.txt" % g):
            os.remove("build/sys_voice_%d.txt" % g)
    rc, txt = sh(["vvp", "-n", out])
    line = [l for l in txt.splitlines() if l.startswith(("PASS", "FAIL"))]
    stats = [l for l in txt.splitlines() if l.startswith("samples ")]
    report("system: keys -> 32 voices -> effects -> DAC pins", bool(line) and line[-1].startswith("PASS"),
           (line[-1] if line else "no verdict") + (" | " + stats[0] if stats else ""))
    i2s = [l for l in txt.splitlines() if l.startswith("PCM5102A frames checked")]
    report("system: PCM5102A wires carry the same audio_out, 24 bit", bool(i2s) and i2s[0].endswith("wrong 0") and
           bool(line) and line[-1].startswith("PASS"), i2s[0] if i2s else "no result")
    used, bad = 0, 0
    for g in range(32):
        path = "build/sys_voice_%d.txt" % g
        if os.path.exists(path) and os.path.getsize(path) > 0:
            used += 1
            rc, _ = sh([sys.executable, "tools/compare_pcm.py", path, "--voice", str(g)])
            bad += rc != 0
    report("system: every used voice bit-exact vs model", used > 0 and bad == 0, "%d voices used, %d differ" % (used, bad))
    rc, txt = sh([sys.executable, "tools/compare_system.py"])
    report("system: audio bus = effects model(sum of voices)", rc == 0, txt.strip().splitlines()[-1] if txt.strip() else "")


def run_stress(report, compile_tb, sh):
    """All sixteen keys tapped eight times in 0.2 s: every voice in use, voices reused while sounding."""
    rtl = sorted("src/" + f for f in os.listdir("src") if f.endswith(".v") and f not in SKIP_RTL) + ["tests/integration/video_boundary_stub.v"] + ["src/keyboard/keyboard_state_mapper.sv"]
    out = "build/tb_system.vvp"
    import subprocess
    r = subprocess.run(["iverilog", "-g2012", "-s", "tb_system", "-o", out, "sim/tb/tb_system.v",
                        "sim/models/ttp229_bfm.v", "sim/models/gowin_pll_stub.v",
                        "sim/models/i2s_rx_model.v",
                        "sim/models/piano_roms_fast.v"] + rtl, capture_output=True, text=True)
    if r.returncode != 0:
        print(r.stdout + r.stderr)
        raise SystemExit("compile failed")
    for g in range(32):
        if os.path.exists("build/stress_voice_%d.txt" % g):
            os.remove("build/stress_voice_%d.txt" % g)
    rc, txt = sh(["vvp", "-n", out, "+stress=1", "+tag=stress"])
    line = [l for l in txt.splitlines() if l.startswith(("PASS", "FAIL"))]
    info = [l.strip() for l in txt.splitlines() if "notes loaded" in l]
    report("stress: 16 keys tapped 8 times, voices reused while sounding", bool(line) and line[-1].startswith("PASS"),
           (line[-1] if line else "no verdict") + (" | " + info[0] if info else ""))
    i2s = [l for l in txt.splitlines() if l.startswith("PCM5102A frames checked")]
    report("stress: PCM5102A wires carry the same audio_out, 24 bit", bool(i2s) and i2s[0].endswith("wrong 0") and
           bool(line) and line[-1].startswith("PASS"), i2s[0] if i2s else "no result")
    used, bad = 0, 0
    for g in range(32):
        path = "build/stress_voice_%d.txt" % g
        if os.path.exists(path) and os.path.getsize(path) > 0:
            used += 1
            rc, _ = sh([sys.executable, "tools/compare_pcm.py", path, "--voice", str(g)])
            bad += rc != 0
    report("stress: all 32 voices used and bit-exact vs model", used == 32 and bad == 0,
           "%d voices used, %d differ" % (used, bad))
    rc, txt = sh([sys.executable, "tools/compare_system.py", "stress"])
    report("stress: audio bus = effects model(sum of voices)", rc == 0, txt.strip().splitlines()[-1] if txt.strip() else "")


def run_legacy(report, compile_tb, sh):
    """Bring-up stages 1 and 2 of the board top (BUILD_STAGE)."""
    skip = SKIP_RTL + ("piano_dual_wavetable.v",)
    rtl = sorted("src/" + f for f in os.listdir("src") if f.endswith(".v") and f not in skip) + ["tests/integration/video_boundary_stub.v"] + ["src/keyboard/keyboard_state_mapper.sv"]
    import subprocess
    for stage, what in ((1, "new key reader + previous sound"), (2, "new piano engine, effects off")):
        out = "build/tb_stage%d.vvp" % stage
        r = subprocess.run(["iverilog", "-g2012", "-s", "tb_stage_top", "-Ptb_stage_top.STAGE=%d" % stage,
                            "-o", out, "sim/tb/tb_stage_top.v", "sim/models/ttp229_bfm.v",
                            "sim/models/gowin_pll_stub.v", "sim/models/piano_roms_fast.v",
                            "sim/models/piano_dual_wavetable_fast.v"] + rtl, capture_output=True, text=True)
        if r.returncode != 0:
            print(r.stdout + r.stderr)
            raise SystemExit("compile failed")
        rc, txt = sh(["vvp", "-n", out])
        lines = [l for l in txt.splitlines() if l.startswith(("PASS", "FAIL", "stage", "ERROR"))]
        report("stage %d: %s" % (stage, what), "PASS" in lines, lines[0] if lines else "")


# ----------------------------------------------------------------------------
# External PCM5102A output (src/pcm5102_i2s_tx.v)
# ----------------------------------------------------------------------------

DAC_UNIT = ["sim/tb/tb_pcm5102_i2s.v", "sim/models/i2s_rx_model.v"]

# Deliberately broken transmitters: (what, text in src/pcm5102_i2s_tx.v, replacement).
# Several places are separated by " @@ ".  The unit test has to fail for every one.
DAC_MUTANTS = [
    ("no one bit delay (left-justified)",
     "            if (slot == 6'd0) begin\n\n                pcm5102_lrck <= 1'b0;",
     "            if (slot == 6'd63) begin\n\n                pcm5102_lrck <= 1'b0;"),
    ("left and right swapped",
     "shift_reg <= {left_word, right_word};", "shift_reg <= {right_word, left_word};"),
    ("sample right-justified in the slot",
     "assign left_word  = {left_sample,  {PAD_W{1'b0}}};",
     "assign left_word  = {{PAD_W{left_sample[SAMPLE_W-1]}}, left_sample};"),
    ("lowest sample bit dropped (23 bit)",
     "assign right_word = {right_sample, {PAD_W{1'b0}}};",
     "assign right_word = {right_sample[SAMPLE_W-1:1], 1'b0, {PAD_W{1'b0}}};"),
    ("sample taken one clk early", "(delay_cnt == 5'd1)", "(delay_cnt == 5'd2)"),
    ("frame is 63 slots", "frame_cnt <= pos + 8'd1;",
     "frame_cnt <= (pos == 8'd251) ? 8'd0 : pos + 8'd1;"),
    ("BCK rises one clk late", "else if (phase == 2'd2) begin", "else if (phase == 2'd3) begin"),
    ("frames stop when sample_valid stops", "else if (capture || running) begin",
     "else if (capture || (running && frame_cnt != 8'd0)) begin"),
    ("reset leaves LRCK low",
     "pcm5102_lrck <= 1'b1;\n        pcm5102_data <= 1'b0;\n\n    end",
     "pcm5102_lrck <= 1'b0;\n        pcm5102_data <= 1'b0;\n\n    end"),
    ("LRCK polarity inverted",
     "pcm5102_lrck <= 1'b0;\n\n                if (capture) @@                 if (slot == 6'd32)\n                    pcm5102_lrck <= 1'b1;",
     "pcm5102_lrck <= 1'b1;\n\n                if (capture) @@                 if (slot == 6'd32)\n                    pcm5102_lrck <= 1'b0;"),
    ("one bit sent twice, last bit lost",
     "shift_reg <= {shift_reg[62:0], 1'b0};",
     "shift_reg <= (slot == 6'd1) ? shift_reg : {shift_reg[62:0], 1'b0};"),
]


def run_dac_unit(report, compile_tb, sh):
    """The transmitter alone against the I2S receiver model (about 2 minutes)."""
    import subprocess
    out = "build/tb_pcm5102_i2s.vvp"
    compile_tb(out, DAC_UNIT + ["src/pcm5102_i2s_tx.v"])
    rc, txt = sh(["vvp", "-n", out])
    line = [l for l in txt.splitlines() if l.startswith(("PASS", "FAIL"))]
    report("dac: PCM5102A transmitter alone, every 24 bit word decoded by an I2S receiver",
           bool(line) and line[-1].startswith("PASS"), line[-1] if line else "no verdict")
    for l in txt.splitlines():
        if l.startswith("delay 7:"):
            print("      " + l)

    src = open("src/pcm5102_i2s_tx.v", encoding="utf-8").read().replace("\r\n", "\n")
    caught, missed = 0, []
    for name, a, b in DAC_MUTANTS:
        m = src
        for x, y in zip(a.split(" @@ "), b.split(" @@ ")):
            if m.count(x) != 1:
                raise SystemExit("mutant '%s' does not fit src/pcm5102_i2s_tx.v any more" % name)
            m = m.replace(x, y)
        with open("build/mut_tx.v", "w", newline="\n") as f:
            f.write(m)
        r = subprocess.run(["iverilog", "-g2012", "-o", "build/mut.vvp"] + DAC_UNIT + ["build/mut_tx.v"],
                           capture_output=True, text=True)
        if r.returncode != 0:
            raise SystemExit("mutant '%s' does not compile:\n%s" % (name, r.stdout + r.stderr))
        rc, t = sh(["vvp", "-n", "build/mut.vvp", "+frames=300"])
        verdict = [l for l in t.splitlines() if l.startswith(("PASS", "FAIL"))]
        if verdict and verdict[-1].startswith("FAIL"):
            caught += 1
        else:
            missed.append(name)
    for f in ("build/mut_tx.v", "build/mut.vvp"):
        if os.path.exists(f):
            os.remove(f)
    report("dac: the same test fails for every deliberately broken transmitter",
           caught == len(DAC_MUTANTS),
           "%d of %d caught%s" % (caught, len(DAC_MUTANTS), (", missed: " + "; ".join(missed)) if missed else ""))


DAC_SKIP = SKIP_RTL + ("piano_dual_wavetable.v",)
DAC_TOP = ["sim/tb/tb_dual_dac.v", "sim/models/i2s_rx_model.v", "sim/models/ttp229_bfm.v",
           "sim/models/gowin_pll_stub.v", "sim/models/piano_roms_fast.v",
           "sim/models/piano_dual_wavetable_fast.v"]
DAC_BEFORE = "backup/2026-10-13_before_pcm5102"


def _dac_top_run(job):
    """Compile and run tb_dual_dac once.  job = (tag, stage, defines, rtl files)."""
    import re
    import subprocess
    tag, stage, defines, rtl = job
    out = "build/dualdac_%s.vvp" % tag
    cmd = ["iverilog", "-g2012", "-s", "tb_dual_dac", "-Ptb_dual_dac.STAGE=%d" % stage, "-o", out]
    cmd += ["-D" + d for d in defines] + DAC_TOP + rtl
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0:
        return tag, None, r.stdout + r.stderr
    r = subprocess.run(["vvp", "-n", out, "+tag=" + tag], capture_output=True, text=True)
    txt = r.stdout + r.stderr
    with open("build/dualdac_%s.log" % tag, "w") as f:
        f.write(txt)
    m = re.search(r"PT8211 pin signature ([0-9a-f]{16})", txt)
    lines = txt.splitlines()
    ok = "PASS" in lines and "FAIL" not in lines
    return tag, (ok, m.group(1) if m else None), txt


def _dac_jobs(names):
    rtl = sorted("src/" + f for f in os.listdir("src") if f.endswith(".v") and f not in DAC_SKIP) + ["tests/integration/video_boundary_stub.v"] + ["src/keyboard/keyboard_state_mapper.sv"]
    jobs = []
    for stage in (1, 2, 3):
        if "inside" in names:
            jobs.append(("inside_s%d" % stage, stage, ["PCM5102_INSIDE"], rtl))
        if "pins" in names:
            jobs.append(("pins_s%d" % stage, stage, ["EXT_PCM5102"], rtl))
        if "before" in names:
            old = [f for f in rtl if os.path.basename(f) not in
                   ("synth_top.v", "tang_mega_138k_pro_top.v.v", "pcm5102_i2s_tx.v")]
            old += [DAC_BEFORE + "/src/synth_top.v", DAC_BEFORE + "/src/tang_mega_138k_pro_top.v.v"]
            jobs.append(("before_s%d" % stage, stage, [], old))
    return jobs


def _dac_run_all(jobs):
    import concurrent.futures as cf
    res = {}
    with cf.ThreadPoolExecutor(max_workers=min(len(jobs), max(2, (os.cpu_count() or 4) - 2))) as ex:
        for tag, r, txt in ex.map(_dac_top_run, jobs):
            if r is None:
                print(txt)
                raise SystemExit("compile failed: tb_dual_dac " + tag)
            res[tag] = (r[0], r[1], txt)
    return res


def _same_file(a, b):
    return os.path.exists(a) and os.path.exists(b) and open(a, "rb").read() == open(b, "rb").read()


def run_dac_top(report, compile_tb, sh):
    """Board top, BUILD_STAGE 1 to 3, the PCM5102A pins off (as delivered) and on.  About 10 minutes."""
    res = _dac_run_all(_dac_jobs(("inside", "pins")))
    what = {1: "previous sound", 2: "new engine, effects off", 3: "new engine + effects"}
    for stage in (1, 2, 3):
        for kind, label in (("inside", "pins off"), ("pins", "EXT_PCM5102 pins")):
            ok, sig, txt = res["%s_s%d" % (kind, stage)]
            info = [l for l in txt.splitlines() if "PCM5102A frames" in l]
            report("dac: stage %d (%s), %s: both DAC outputs = audio_out, frame by frame" % (stage, what[stage], label),
                   ok, info[0].split(": ", 1)[1] if info else "")
        a, b = res["inside_s%d" % stage], res["pins_s%d" % stage]
        report("dac: stage %d: PT8211 pins the same with the PCM5102A pins off and on" % stage,
               a[1] is not None and a[1] == b[1] and
               _same_file("build/dualdac_inside_s%d_pt8211.txt" % stage, "build/dualdac_pins_s%d_pt8211.txt" % stage),
               "pin signature %s / %s" % (a[1], b[1]))


def run_dac_before(report, compile_tb, sh):
    """PT8211 pins of this design against the sources from before the PCM5102A transmitter
    (backup/2026-10-13_before_pcm5102): same level at every clock edge, same decoded words.

    Only meaningful as long as nothing else that changes the sound or the key mapping has
    been changed since that backup; run it on request (python sim/run_tests.py dac_before)."""
    if not os.path.isdir(DAC_BEFORE):
        raise SystemExit("no " + DAC_BEFORE)
    res = _dac_run_all(_dac_jobs(("inside", "before")))
    for stage in (1, 2, 3):
        a, b = res["before_s%d" % stage], res["inside_s%d" % stage]
        edges = [l for l in a[2].splitlines() if "clock edges" in l]
        same = _same_file("build/dualdac_before_s%d_pt8211.txt" % stage, "build/dualdac_inside_s%d_pt8211.txt" % stage)
        report("dac_before: stage %d: PT8211 pins identical before / after adding the transmitter" % stage,
               a[0] and b[0] and a[1] is not None and a[1] == b[1] and same,
               "pin signature %s / %s, decoded words %s | %s" % (
                   a[1], b[1], "identical" if same else "DIFFER",
                   edges[0].split(": ", 1)[1].split(",")[0] if edges else ""))


def run(what, report, compile_tb, sh):
    if what in ("default", "all", "dac"):
        run_dac_unit(report, compile_tb, sh)
    if what in ("all", "dac"):
        run_dac_top(report, compile_tb, sh)
    if what == "dac_before":
        run_dac_before(report, compile_tb, sh)
    if what in ("default", "all", "fx"):
        run_fx(report, compile_tb, sh)
    if what in ("default", "all", "legacy"):
        run_legacy(report, compile_tb, sh)
    if what in ("all", "system"):
        run_system(report, compile_tb, sh)
    if what in ("all", "stress"):
        run_stress(report, compile_tb, sh)
