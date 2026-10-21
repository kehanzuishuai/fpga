"""Promote only the tested timing candidate, backing up current WAV sources."""
from pathlib import Path
import hashlib,json,shutil
R=Path(__file__).resolve().parents[2];O=R/'tests/remote_music_20261019/out'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
receipt=json.loads((O/'wav_candidate.json').read_text())
for name in ['wav_candidate','wav_candidate_formats','wav_candidate_errors','wav_candidate_dac']:
 assert json.loads((O/(name+'.json')).read_text())['status']=='PASS',name
dest=R/'audit/remote_music_20261019/before_wav_pipeline';dest.mkdir(exist_ok=False)
record={}
for name in ['wav_pcm_player.sv','wav_spi_stream.sv']:
 p=R/'src/remote'/name;candidate=O/'wav_timing_candidate'/name
 assert sha(p)==receipt['input_sha256'][p.relative_to(R).as_posix()]
 shutil.copy2(p,dest/name)
 record[name]={'before_sha256':sha(p),'after_sha256':sha(candidate)}
 shutil.copy2(candidate,p)
(dest/'PROMOTION.json').write_text(json.dumps(record,indent=2))
print('Promoted tested WAV bounds/count and status-CRC pipeline; originals backed up.')
