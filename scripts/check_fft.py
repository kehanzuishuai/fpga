"""Verify 32 test-mode peaks and emit machine-readable frequency metrics."""
from pathlib import Path
import csv
import json
import numpy as np

RATE = 48_000
with Path("sim_out/note_table.csv").open(newline="", encoding="utf-8") as handle:
    NOTE_ROM = {int(row["note"]): int(row["phase_inc"]) for row in csv.DictReader(handle)}


path = Path("sim_out/test32_s24le.pcm")
raw = path.read_bytes()
if len(raw) % 3:
    raise SystemExit("FAIL: PCM length is not a whole number of signed-24 samples")
b = np.frombuffer(raw, dtype=np.uint8).reshape(-1, 3)
x = b[:, 0].astype(np.int32) | (b[:, 1].astype(np.int32) << 8) | (b[:, 2].astype(np.int32) << 16)
x = np.where(x & 0x800000, x - 0x1000000, x).astype(np.float64)
n = len(x)
if n < 16_384:
    raise SystemExit(f"FAIL: FFT capture too short ({n}); need at least 16384 samples")
spec = np.abs(np.fft.rfft(x * np.hanning(n)))
freq = np.fft.rfftfreq(n, 1 / RATE)
bin_hz = RATE / n
found = []
peak_bins = set()
for midi in range(36, 100, 2):
    ideal = 440.0 * 2.0 ** ((midi - 69) / 12.0)
    dds = NOTE_ROM[midi] * RATE / (2.0 ** 32)
    width = max(4.0, bin_hz * 1.5)
    region = np.where(np.abs(freq - dds) <= width)[0]
    peak_bin = int(region[np.argmax(spec[region])])
    measured = float(freq[peak_bin])
    if abs(measured - dds) > width or spec[peak_bin] < spec.max() * 0.02:
        raise SystemExit(f"FAIL: MIDI {midi} expected {dds:.3f} Hz; peak {measured:.3f} Hz weak/misaligned")
    if peak_bin in peak_bins:
        raise SystemExit(f"FAIL: MIDI {midi} reused FFT bin {peak_bin}; peaks are not independent")
    peak_bins.add(peak_bin)
    found.append({"midi": midi, "ideal_hz": ideal, "dds_hz": dds,
                  "dds_error_hz": dds - ideal, "fft_hz": measured,
                  "fft_error_hz": measured - dds})

with Path("sim_out/rtl_metrics.csv").open(newline="", encoding="utf-8") as handle:
    rtl_metrics = next(csv.DictReader(handle))
samples = int(rtl_metrics["samples"])
clips = int(rtl_metrics["clip_count"])
latency_valid = bool(int(rtl_metrics["latency_valid"]))
latency_samples = int(rtl_metrics["latency_samples"])
if clips:
    raise SystemExit(f"FAIL: normalized 32-Voice mix clipped {clips}/{samples} samples")
if not latency_valid:
    raise SystemExit("FAIL: latency monitor did not report a digital latency")

metrics = {
    "result": "PASS", "sample_count": n, "fft_bin_hz": bin_hz,
    "peak_count": len(found), "clip_count": clips, "clip_ratio": clips / samples,
    "latency_samples": latency_samples,
    "max_abs_dds_error_hz": max(abs(v["dds_error_hz"]) for v in found),
    "max_abs_fft_error_hz": max(abs(v["fft_error_hz"]) for v in found),
    "peaks": found,
}
Path("sim_out/fft_metrics.json").write_text(json.dumps(metrics, ensure_ascii=False, indent=2), encoding="utf-8")
print(f"FFT PASS: {len(found)}/32 independent peaks, {n} samples, "
      f"DDS max error={metrics['max_abs_dds_error_hz']:.6f} Hz, "
      f"clip={metrics['clip_ratio']:.6%}, latency={latency_samples} samples")
