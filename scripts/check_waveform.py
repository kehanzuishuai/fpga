"""Validate the quarter-wave RTL LUT against an ideal full-scale sine."""
from pathlib import Path
import csv
import math
import numpy as np

path = Path("sim_out/waveform_lut.csv")
with path.open(newline="", encoding="utf-8") as handle:
    rows = list(csv.DictReader(handle))
if len(rows) != 256:
    raise SystemExit(f"FAIL: expected 256 waveform samples, found {len(rows)}")

actual = np.array([int(row["sine"]) for row in rows], dtype=np.int64)
ideal = np.array(
    [round(math.sin(2.0 * math.pi * k / 256.0) * 32767.0) * 256 for k in range(256)],
    dtype=np.int64,
)
max_error = int(np.max(np.abs(actual - ideal)))
if max_error != 0:
    raise SystemExit(f"FAIL: sine LUT differs from regenerated reference by {max_error} LSB")
if actual[0] != 0 or actual[64] != 32767 * 256 or actual[128] != 0 or actual[192] != -32767 * 256:
    raise SystemExit("FAIL: sine LUT quadrant endpoints are incorrect")

spec = np.fft.rfft(actual.astype(np.float64))
fundamental = abs(spec[1])
harmonic_rms = math.sqrt(float(np.sum(np.abs(spec[2:]) ** 2)))
thd = harmonic_rms / fundamental
if thd > 1.0e-4:
    raise SystemExit(f"FAIL: LUT THD {thd:.8f} exceeds 0.01%")
print(f"WAVEFORM PASS: 65-entry quarter-sine LUT exact, peak={actual[64]}, THD={thd*100:.6f}%")
