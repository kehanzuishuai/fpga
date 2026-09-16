"""Compare every RTL MIDI phase-ROM entry with the equal-tempered reference."""
from pathlib import Path
import csv
import math

with Path("sim_out/note_table.csv").open(newline="", encoding="utf-8") as handle:
    rows = list(csv.DictReader(handle))
if len(rows) != 128:
    raise SystemExit(f"FAIL: expected 128 note ROM rows, found {len(rows)}")
max_error_hz = 0.0
for expected_note, row in enumerate(rows):
    note = int(row["note"])
    actual = int(row["phase_inc"])
    expected = round(440.0 * 2.0 ** ((note - 69) / 12.0) * 2.0 ** 32 / 48000.0)
    if note != expected_note or actual != expected:
        raise SystemExit(f"FAIL: MIDI {expected_note} RTL={actual} expected={expected}")
    actual_hz = actual * 48000.0 / 2.0 ** 32
    ideal_hz = 440.0 * 2.0 ** ((note - 69) / 12.0)
    max_error_hz = max(max_error_hz, abs(actual_hz - ideal_hz))
print(f"NOTE ROM PASS: 128/128 exact increments, max quantization error={max_error_hz:.6f} Hz")
