from pathlib import Path
import wave
p=Path('sim_out/test32_s24le.pcm'); raw=p.read_bytes()
with wave.open('sim_out/test32_s24le.wav','wb') as w:
    w.setnchannels(1); w.setsampwidth(3); w.setframerate(48000); w.writeframes(raw)
print('WAV PASS: sim_out/test32_s24le.wav')
