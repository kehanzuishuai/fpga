from pathlib import Path
import re,json
from continue_audio_audit import R,O,sha,now
rp=R/'src/piano_ratio_rom.v';fp=R/'src/note_freq_table.v'
rat={int(a):int(v,16) for a,v in re.findall(r"9'd(\d+):\s*q\s*<=\s*20'h([0-9A-Fa-f]+)",rp.read_text())}
freq={int(n):int(v) for n,v in re.findall(r"7'd(\d+):\s+phase_inc_48k\s*=\s*32'd(\d+)",fp.read_text())}
# The seven-bit table spells 0..126 explicitly; MIDI127 is the default case.
assert set(freq)==set(range(127))
freq[127]=int(re.search(r"default:\s*phase_inc_48k\s*=\s*32'd(\d+)",fp.read_text())[1])
assert len(rat)==336 and len(freq)==128, (len(rat),len(freq))
bad=[];rows=[]
for n in range(24,105):
 j=min((n-24)//4,19);a=n-24-4*j
 for s in range(15):
  lo,hi=rat[j*16+s],rat[(j+1)*16+s]
  ratio=lo+(hi-lo)*a//4 if lo and hi else 0
  inc_unmasked=(freq[n]*ratio)>>19
  hz_unmasked=inc_unmasked*48000/(1<<28)
  row={'midi':n,'partial':s+1,'ratio':ratio,'phase_increment_before_28bit_slice':inc_unmasked,'frequency_before_wrap_hz':hz_unmasked}
  rows.append(row)
  if hz_unmasked>=24000 or inc_unmasked>=(1<<28):bad.append(row)
result={'status':'PASS' if not bad else 'FAIL','time':now(),'source_sha256':{str(p):sha(p) for p in [rp,fp]},'scope':'Actual production ROM and phase table; all MIDI24..104; tonal slots0..14; checks full product BEFORE 28-bit truncation, so modulo wrap cannot hide aliasing','max_unwrapped_tonal_hz':max(r['frequency_before_wrap_hz'] for r in rows),'violations':bad,'points_checked':len(rows)}
(O/'NYQUIST_AUDIT.json').write_text(json.dumps(result,indent=2),encoding='utf8')
print(json.dumps(result,indent=2));assert not bad
