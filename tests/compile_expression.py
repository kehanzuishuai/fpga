from pathlib import Path
import sys,subprocess
sys.path.insert(0,str(Path(__file__).resolve().parent))
from run_checks import full_sources,IV,B,O
args=[str(IV),'-g2012','-s','tb_audio_readonly','-o',str(O/'expression_elaborate.vvp'),str(B/'tests/tb_audio_readonly.sv'),str(B.parents[1]/'sim/models/i2s_rx_model.v'),*map(str,full_sources())]
p=subprocess.run(args,cwd=B,capture_output=True,text=True)
(O/'expression_elaborate.log').write_text(p.stdout+p.stderr)
print(p.returncode,(p.stdout+p.stderr)[-5000:]);sys.exit(p.returncode)
