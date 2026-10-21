"""Extract the AMY piano partial table from an AMY checkout.

Reads  <amy>/src/interp_partials.h  (the table the AMY kernel plays as the
"dpwe piano", patch 256) and writes it as JSON, together with the commit it
came from, to tools/amy_data/amy_piano_params.json.

    python tools/amy_extract.py C:/path/to/amy

AMY: https://github.com/shorepine/amy  (MIT licence, see amy_data/LICENSE.amy)
"""
import json
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "amy_data", "amy_piano_params.json")


def c_array(text, name):
    m = re.search(r"\b%s\s*\[[^\]]*\]\s*(?:PROGMEM\s*)?=\s*\{(.*?)\};" % re.escape(name), text, re.S)
    if not m:
        raise SystemExit("array %s not found" % name)
    return [int(x) for x in re.findall(r"-?\d+", m.group(1))]


def main():
    amy = sys.argv[1] if len(sys.argv) > 1 else "."
    header = os.path.join(amy, "src", "interp_partials.h")
    text = open(header, encoding="utf-8").read()
    kernel = open(os.path.join(amy, "src", "interp_partials.c"), encoding="utf-8").read()

    times = c_array(text, "piano_sample_times_ms")
    vels = c_array(text, "piano_velocities")
    notes = c_array(text, "piano_notes")
    num_h = c_array(text, "piano_num_harmonics")
    freq = c_array(text, "piano_harmonics_freq")
    mags = c_array(text, "piano_harmonics_mags")

    assert len(num_h) == len(notes) * len(vels)
    assert len(freq) == sum(num_h)
    assert len(mags) == sum(num_h) * len(times)

    m = re.search(r"use_this_partial_map\[[^\]]*\]\s*=\s*\{(.*?)\};", kernel, re.S)
    use_map = [int(x) for x in re.findall(r"\b[01]\b", re.sub(r"//.*", "", m.group(1)))]

    try:
        commit = subprocess.check_output(["git", "-C", amy, "log", "-1", "--format=%H %cI"], text=True).strip()
    except Exception:
        commit = "unknown"

    data = {
        "source": "shorepine/amy src/interp_partials.h + use_this_partial_map from src/interp_partials.c",
        "amy_commit": commit,
        "sample_times_ms": times,
        "velocities": vels,
        "notes": notes,
        "num_harmonics": num_h,
        "harmonics_freq_cents": freq,
        "harmonics_mags_db": [mags[i * len(times):(i + 1) * len(times)] for i in range(sum(num_h))],
        "use_this_partial_map": use_map,
    }
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as f:
        json.dump(data, f, separators=(",", ":"))
    print("wrote", OUT)
    print("commit", commit)
    print("notes", notes)
    print("velocities", vels, "times_ms", times)
    print("harmonics total", sum(num_h), "per note/vel", num_h)
    print("use_this_partial_map ones:", sum(use_map), "of", len(use_map))


if __name__ == "__main__":
    main()
