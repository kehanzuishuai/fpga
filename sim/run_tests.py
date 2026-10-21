"""Regression runner for piano_v2 (run from the piano_v2 folder).

    python sim/run_tests.py            everything except the long voice runs
    python sim/run_tests.py all        everything
    python sim/run_tests.py keys|rom|voice|voice_long|fx|legacy|system|stress|dac   one group
    python sim/run_tests.py dac_before   the PT8211 pins against the sources from before the
                                         PCM5102A transmitter (needs the backup folder)

"all" adds the long voice runs (about 15 minutes), the system run (about 10),
the voice stealing stress run (about 15) and the board top with both DAC
outputs in the three build stages (about 10).

Needs iverilog/vvp (OSS CAD Suite) on PATH, or set OSS_CAD=<folder with bin>.
"""
import concurrent.futures as cf
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.chdir(ROOT)
os.makedirs("build", exist_ok=True)

oss = os.environ.get("OSS_CAD", r"C:\fpga\tools\oss-cad-suite")
if os.path.isdir(oss):
    os.environ["PATH"] = os.path.join(oss, "bin") + os.pathsep + os.path.join(oss, "lib") + os.pathsep + os.environ["PATH"]

ROMS_FAST = ["sim/models/piano_roms_fast.v"]
ROMS_SYN = ["src/piano_level_rom.v", "src/piano_ratio_rom.v", "src/piano_note_rom.v",
            "src/piano_sine_rom.v", "src/piano_exp_rom.v"]
VOICE = ["src/piano_partial_voice.v", "src/piano_note_loader.v", "src/note_freq_table.v"]

results = []


def sh(cmd, quiet=False):
    r = subprocess.run(cmd, capture_output=True, text=True)
    return r.returncode, (r.stdout + r.stderr)


def compile_tb(out, files, defines=()):
    cmd = ["iverilog", "-g2012", "-o", out] + ["-D" + d for d in defines] + files
    rc, txt = sh(cmd)
    if rc != 0:
        print(txt)
        raise SystemExit("compile failed: " + " ".join(cmd))


def report(name, ok, detail=""):
    results.append((name, ok))
    print("%-58s %s %s" % (name, "PASS" if ok else "FAIL", detail))


def run_keys():
    files = ["sim/tb/tb_ttp229_keys.v", "sim/models/ttp229_bfm.v", "src/ttp229_reader.v",
             "src/ttp229_event_bridge.v", "src/note_event_fifo.v"]
    for name, defs in (("keys: 16 key multi mode", ()), ("keys: chip left in 8 key mode", ("MODE8",)),
                       ("keys: 16 key single-key mode", ("SINGLE",)),
                       ("keys: SDO stuck, STRICT_IDLE=1 (frames dropped)", ("STUCK",)),
                       ("keys: SDO stuck, STRICT_IDLE=0 (default, read anyway)", ("STUCK_READ",))):
        out = "build/tb_keys_%s.vvp" % (defs[0] if defs else "MULTI")
        compile_tb(out, files, defs)
        rc, txt = sh(["vvp", "-n", out])
        line = [l for l in txt.splitlines() if l.startswith(("PASS", "FAIL"))]
        report(name, bool(line) and line[-1].startswith("PASS"), line[-1] if line else txt[-200:])


def run_rom():
    compile_tb("build/tb_rom_equiv.vvp", ["sim/tb/tb_rom_equiv.v"] + ROMS_FAST + ROMS_SYN, ("ROM_EQUIV",))
    rc, txt = sh(["vvp", "-n", "build/tb_rom_equiv.vvp"])
    report("rom: case form == array form (all addresses)", "PASS: ROM forms identical" in txt)


def voice_case(args):
    """A scenario is (name, plus arguments, hammer, expectation).

    expectation: "rel"   the log must contain released samples and sound
                 "steal" two notes, fade samples, released samples
                 "mute"  loaded but never audible (released while loading)
                 "held"  sound, no release
    """
    name, plus, hammer, expect = args
    log = "build/voice_%s.txt" % name
    rc, txt = sh(["vvp", "-n", "build/tb_voice.vvp", "+log=" + log, "+hammer=%d" % hammer] + ["+" + p for p in plus])
    sim_ok = "SIM DONE" in txt
    rc2, txt2 = sh([sys.executable, "tools/compare_pcm.py", log, "--hammer", str(hammer)])
    out = txt2.strip().splitlines()
    last = out[-1] if out else "no output"
    ok = sim_ok and rc2 == 0
    import re
    m = re.search(r"notes loaded: (\d+), samples compared: (\d+), released samples: (\d+), fade samples: (\d+), RTL peak (\d+)", txt2)
    if not m:
        return name, False, last
    notes, _, n_rel, n_fade, peak = [int(g) for g in m.groups()]
    want = {
        "rel":   notes == 1 and n_rel > 0 and peak > 0,
        "steal": notes == 2 and n_fade > 0 and n_rel > 0 and peak > 0,
        "mute":  notes == 1 and peak == 0,
        "held":  notes == 1 and n_rel == 0 and peak > 0,
    }[expect]
    if not want:
        ok = False
        last = "scenario did not happen as written (notes %d, released %d, fade %d, peak %d)" % (notes, n_rel, n_fade, peak)
    eng = [l for l in txt.splitlines() if l.startswith("engine:")]
    return name, ok, last + (" | " + eng[0] if eng else "")


VOICE_SHORT = [
    ("c4_mf",        ["note=60", "vel=80", "on=4", "off=9000", "ticks=16000"], 1, "rel"),
    ("c4_pp",        ["note=60", "vel=40", "on=4", "off=9000", "ticks=16000"], 1, "rel"),
    ("c4_ff",        ["note=60", "vel=120", "on=4", "off=9000", "ticks=16000"], 1, "rel"),
    ("c4_v100",      ["note=60", "vel=100", "on=4", "off=9000", "ticks=16000"], 1, "rel"),
    ("c3_v100",      ["note=48", "vel=100", "on=4", "off=9000", "ticks=20000"], 1, "rel"),
    ("c5_v100",      ["note=72", "vel=100", "on=4", "off=9000", "ticks=16000"], 1, "rel"),
    ("eb5_v100",     ["note=75", "vel=100", "on=7", "off=9000", "ticks=16000"], 1, "rel"),
    ("d4_v93",       ["note=62", "vel=93", "on=4", "off=9000", "ticks=16000"], 1, "rel"),
    ("f4_v61",       ["note=65", "vel=61", "on=4", "off=9000", "ticks=16000"], 1, "rel"),
    ("c4_no_hammer", ["note=60", "vel=100", "on=4", "off=9000", "ticks=16000"], 0, "rel"),
    ("vel_1",        ["note=60", "vel=1", "on=4", "off=9000", "ticks=16000"], 1, "rel"),
    ("vel_127",      ["note=67", "vel=127", "on=4", "off=9000", "ticks=16000"], 1, "rel"),
    ("note_0",       ["note=0", "vel=100", "on=4", "off=9000", "ticks=24000"], 1, "rel"),
    ("note_24",      ["note=24", "vel=100", "on=4", "off=9000", "ticks=24000"], 1, "rel"),
    ("note_104",     ["note=104", "vel=100", "on=4", "off=9000", "ticks=16000"], 1, "rel"),
    ("note_127",     ["note=127", "vel=100", "on=4", "off=9000", "ticks=16000"], 1, "rel"),
    ("tap_2ms",      ["note=60", "vel=100", "on=4", "off=100", "ticks=16000"], 1, "rel"),
    ("off_in_load",  ["note=60", "vel=100", "on=4", "off=6", "ticks=3000"], 1, "mute"),
    ("steal_loud",   ["note=60", "vel=100", "on=4", "note2=67", "vel2=110", "on2=3000", "off=12000", "ticks=20000"], 1, "steal"),
    ("steal_release",["note=60", "vel=100", "on=4", "off=2000", "note2=62", "vel2=90", "on2=2400", "ticks=16000"], 1, "steal"),
    ("retrigger",    ["note=64", "vel=100", "on=4", "note2=64", "vel2=100", "on2=1000", "off=9000", "ticks=16000"], 1, "steal"),
]

VOICE_LONG = [
    ("long_c4_held", ["note=60", "vel=100", "on=4", "off=900000", "ticks=420000"], 1, "held"),
    ("long_c3_held", ["note=48", "vel=80", "on=4", "off=900000", "ticks=420000"], 1, "held"),
    ("long_eb5_rel", ["note=75", "vel=120", "on=4", "off=250000", "ticks=280000"], 1, "rel"),
]




def run_voice(cases, label):
    compile_tb("build/tb_voice.vvp", ["sim/tb/tb_piano_voice.v"] + VOICE + ROMS_FAST)
    with cf.ThreadPoolExecutor(max_workers=max(2, (os.cpu_count() or 4) - 2)) as ex:
        for name, ok, detail in ex.map(voice_case, cases):
            report("%s: %s bit-exact vs model" % (label, name), ok, detail)


def write_manifest(what, bad):
    """Record which files this run tested: SHA-256 of every source, test bench,
    model and tool, next to the results.  docs/test_manifest_<group>.txt can be
    compared with the files on disk (python sim/check_manifest.py)."""
    import datetime
    import hashlib
    lines = ["# piano_v2 regression manifest",
             "# group: %s    finished: %s" % (what, datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")),
             "# result: %d tests, %d failed" % (len(results), len(bad)), "", "[results]"]
    lines += ["%s  %s" % ("PASS" if ok else "FAIL", name) for name, ok in results]
    lines += ["", "[files]"]
    for folder in ("src", "sim/tb", "sim/models", "sim", "tools"):
        for f in sorted(os.listdir(folder)):
            path = folder + "/" + f
            if os.path.isfile(path) and f.endswith((".v", ".py", ".cst", ".sdc")):
                h = hashlib.sha256(open(path, "rb").read()).hexdigest()
                lines.append("%s  %s" % (h, path))
    with open("docs/test_manifest_%s.txt" % what, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines) + "\n")
    print("wrote docs/test_manifest_%s.txt" % what)


def main():
    what = sys.argv[1] if len(sys.argv) > 1 else "default"
    if what == "all":
        import importlib.util
        spec = importlib.util.spec_from_file_location("parallel_regression", os.path.join(ROOT, "sim", "parallel_regression.py"))
        scheduler = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(scheduler)
        scheduler.run_all(globals())
        bad = [n for n, ok in results if not ok]
        print("\n%d tests, %d failed" % (len(results), len(bad)))
        write_manifest(what, bad)
        sys.exit(1 if bad else 0)
    if what in ("default", "all", "keys"):
        run_keys()
    if what in ("default", "all", "rom"):
        run_rom()
    if what in ("default", "all", "voice"):
        run_voice(VOICE_SHORT, "voice")
    if what in ("all", "voice_long"):
        run_voice(VOICE_LONG, "voice")
    extra = os.path.join(ROOT, "sim", "run_more.py")
    if os.path.exists(extra):
        import importlib.util
        spec = importlib.util.spec_from_file_location("run_more", extra)
        mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)
        mod.run(what, report, compile_tb, sh)
    bad = [n for n, ok in results if not ok]
    print("\n%d tests, %d failed" % (len(results), len(bad)))
    write_manifest(what, bad)
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()
