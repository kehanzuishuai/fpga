"""Bit-exact, per-sample comparison of RTL DDS, ADSR, Morph and Mixer."""
from pathlib import Path
import csv


def trunc_div(value: int, divisor: int) -> int:
    """SystemVerilog signed division truncates toward zero."""
    return value // divisor if value >= 0 else -((-value) // divisor)


def sat(value: int, bits: int) -> int:
    return max(-(1 << (bits - 1)), min((1 << (bits - 1)) - 1, value))


path = Path("sim_out/golden_vectors.csv")
with path.open(newline="", encoding="utf-8") as handle:
    rows = list(csv.DictReader(handle))
if len(rows) != 48:
    raise SystemExit(f"FAIL: expected 48 golden rows, found {len(rows)}")

phase = 0
level = 0
active = 0
stage = 0
checks = 0
for row in rows:
    r = {key: int(value) for key, value in row.items()}
    if r["phase_reset"]:
        phase = 0
    else:
        phase = (phase + 0x12345678) & 0xFFFFFFFF

    if r["gate_on"]:
        level, stage, active = 0, 1, 1
    elif r["gate_off"] and active:
        stage = 0
    else:
        if stage == 1:
            if level >= 255 - 40:
                level, stage = 255, 2
            else:
                level += 40
        elif stage == 2:
            if level <= 120 + 10:
                level, stage = 120, 3
            else:
                level -= 10
        elif stage == 3:
            level = 120
        elif active:
            if level <= 30:
                level, active = 0, 0
            else:
                level -= 30

    morph = r["morph"]
    if morph == 0:
        morph_expected = r["sine"]
    elif morph == 1023:
        morph_expected = r["triangle"]
    else:
        if morph < 341:
            a, b, frac = r["sine"], r["square"], morph * 3
        elif morph < 682:
            a, b, frac = r["square"], r["saw"], (morph - 341) * 3
        else:
            a, b, frac = r["saw"], r["triangle"], (morph - 682) * 3
        morph_expected = sat(a + (((b - a) * frac) >> 10), 24)

    mixed_expected = r["m0"] + r["m1"] + r["m2"] + r["m3"]
    expected = {
        "phase": phase,
        "level": level,
        "active": active,
        "stage": stage,
        "morph_sample": morph_expected,
        "mixed": mixed_expected,
        "mixed_sat": sat(mixed_expected, 24),
    }
    for signal, value in expected.items():
        if r[signal] != value:
            raise SystemExit(
                f"FAIL: row {r['k']} {signal}: RTL={r[signal]} golden={value}"
            )
        checks += 1

print(f"GOLDEN PASS: {checks} bit-exact per-sample DDS/ADSR/Morph/Mixer comparisons")
