"""Reuse the prior gate Loader/model check with current synthesized port names.

No netlist cell or defparam is edited. Only the testbench adapter changes;
captured note/inc forcing has the same limited scope as the earlier audit.
"""
from pathlib import Path
import re,json
R=Path(__file__).resolve().parents[2];O=Path(__file__).resolve().parent
s=(R/'tests/recording_20261018_150135/verify_loader.py').read_text()
s=s.replace("elif name=='n290_6':", "elif name=='n541_6':")
s=s.replace("elif name=='n135_6':", "elif name=='n135_7':")
s=s.replace("elif name=='out_velocity_Z':", "elif name=='out_note_Z':val='note'\n        elif name=='out_velocity_Z':")
s=s.replace('n<=75','n<=91').replace('range(60,76)','range(60,92)').replace('6400','12800')
s=s.replace("'notes':16","'notes':32").replace('16 notes','32 notes')
ns={'__file__':str(__file__),'__name__':'gate32_helpers'}
exec(compile(s,str(__file__),'exec'),ns)
result=ns['run']('gate_loader32',R/'impl/gwsynthesis/yinyue_fashengqi.vg')
assert result['status']=='PASS' and result['notes']==32 and result['words']==12800
print('PASS32 actual integrated synthesized Loader/ROMs, 12800 model-matched parameter words')
