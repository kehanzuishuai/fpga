"""Final regressions against frozen current sources; sequential dependencies stay ordered."""
from pathlib import Path
import subprocess,sys
import json,hashlib
from concurrent.futures import ThreadPoolExecutor
R=Path(__file__).resolve().parents[2];D=R/'tests/remote_music_20261019'
commands=[['run.py','elaborate'],['share_equiv.py'],['run.py','wav'],['wav_formats.py'],['error_tests.py'],['wav_dac.py'],['native.py'],['native_replay.py'],['native_http.py'],['run.py','control'],['run.py','aux'],['audio_top.py'],['score_top.py'],['preserve.py'],['system.py']]
def execute(group):
 for command in group:
  print('Final regression:',*command,flush=True)
  subprocess.run([sys.executable,'-X','utf8','-B','-u',str(D/command[0]),*command[1:]],cwd=R,check=True)
if '--parallel' in sys.argv:
 # Each group has distinct testbench/executable/log files. Fixture/native
 # producer-consumer dependencies remain ordered inside the first group.
 groups=[commands[0:1]+commands[2:10], [['run.py','aux']],
  [['audio_top.py'],['score_top.py']], [['preserve.py'],['system.py']],
  [['share_equiv.py'],['gate_bank.py']]]
 if '--after-control' in sys.argv:groups[0]=[q for q in groups[0] if q!=['run.py','control']]
 if '--after-top' in sys.argv:groups[2]=[]
 with ThreadPoolExecutor(max_workers=5) as pool:list(pool.map(execute,groups))
 external=(['control'] if '--after-control' in sys.argv else [])+(['audio_top','score_top'] if '--after-top' in sys.argv else [])
 for name in external:
  receipt=json.loads((D/'out'/(name+'.json')).read_text())
  assert receipt['status']=='PASS' and receipt['inputs_unchanged'],name
  assert all(hashlib.sha256((R/q).read_bytes()).hexdigest()==h for q,h in receipt['input_sha256'].items()),name
 print('PASS final production-source regression suite',flush=True)
 sys.exit(0)
for command in commands:
 if '--after-equiv' in sys.argv and command[0]=='share_equiv.py':continue
 print('Final regression:',*command,flush=True)
 subprocess.run([sys.executable,'-X','utf8','-B','-u',str(D/command[0]),*command[1:]],cwd=R,check=True)
print('PASS final production-source regression suite',flush=True)
