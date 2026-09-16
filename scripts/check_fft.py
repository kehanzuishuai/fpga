"""Verify the RTL test-mode PCM contains 32 independently generated notes."""
from pathlib import Path
import numpy as np

path = Path("sim_out/test32_s24le.pcm")
raw = path.read_bytes()
if len(raw) % 3:
    raise SystemExit("FAIL: PCM length is not a whole number of signed-24 samples")
b = np.frombuffer(raw, dtype=np.uint8).reshape(-1, 3)
x = (b[:, 0].astype(np.int32) | (b[:, 1].astype(np.int32) << 8) | (b[:, 2].astype(np.int32) << 16))
x = np.where(x & 0x800000, x - 0x1000000, x).astype(np.float64)
rate = 48000
n = len(x)
spec = np.abs(np.fft.rfft(x * np.hanning(n)))
freq = np.fft.rfftfreq(n, 1 / rate)
found = []
for midi in range(36, 100, 2):
    expected = 440.0 * 2.0 ** ((midi - 69) / 12.0)
    width = max(6.0, rate / n * 2.0)
    region = np.where(np.abs(freq - expected) <= width)[0]
    peak = region[np.argmax(spec[region])]
    measured = freq[peak]
    if abs(measured - expected) > width or spec[peak] < spec.max() * 0.025:
        raise SystemExit(f"FAIL: MIDI {midi} expected {expected:.2f} Hz; peak {measured:.2f} Hz too weak/misaligned")
    found.append((midi, expected, measured))
print(f"FFT PASS: {len(found)} independent expected frequency peaks in {n} PCM samples")
