"""A bounded, standard PCM test file for manual phone -> FPGA stereo bring-up."""
from pathlib import Path
import math,wave,struct,json,hashlib
O=Path(__file__).resolve().parent/'hardware_test';O.mkdir(exist_ok=True)
rate=48000;frames=4*rate;peak=round(32767*.2);raw=bytearray()
for n in range(frames):
 second=n//rate;local=n%rate
 gain=min(1,local/240,(rate-1-local)/240) # five-ms endpoint fades
 left=round(peak*gain*math.sin(2*math.pi*440*n/rate)) if second in (0,2) else 0
 right=round(peak*gain*math.sin(2*math.pi*660*n/rate)) if second in (1,2) else 0
 raw.extend(struct.pack('<hh',left,right))
p=O/'stereo_channel_check_16bit_48k.wav'
with wave.open(str(p),'wb') as f:f.setnchannels(2);f.setsampwidth(2);f.setframerate(rate);f.writeframes(raw)
(O/'EXPECTED.json').write_text(json.dumps({'scope':'Generated transport/stereo wiring test tones; not synthesized instrument quality evidence','format':'PCM16 stereo 48000 Hz','seconds':4,'frames':frames,'peak_fraction_FS':.2,'timeline':[{'second':0,'left_Hz':440,'right_Hz':0},{'second':1,'left_Hz':0,'right_Hz':660},{'second':2,'left_Hz':440,'right_Hz':660},{'second':3,'left_Hz':0,'right_Hz':0}],'sha256':hashlib.sha256(p.read_bytes()).hexdigest()},indent=2),encoding='utf-8')
print('Created',p)
