from pathlib import Path
import sys
from continue_audio_audit import R,O,A,PY,run
code="from pathlib import Path; p=Path('tools/audio_chain_audit.py'); s=p.read_text().replace(\"O=R/'tests/audio_diagnosis'\",\"O=R/'tests/continuation_20261017/mapping_final'\"); exec(compile(s,str(p),'exec'),{'__file__':str(p.resolve()),'__name__':'__main__'})"
assert run('chain_audit',[PY,'-X','utf8','-B','-c',code])
assert run('key_metrics',[PY,'-X','utf8','-B','tools/continuation_analyze.py','key_metrics'])
