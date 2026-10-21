"""Validate this integration's actual mapped piano Loader/ROM, not the old FS."""
from pathlib import Path
import re
R=Path(__file__).resolve().parents[2]
net=(R/'impl/gwsynthesis/yinyue_fashengqi.vg').read_text()
body=re.search(r'^module piano_note_loader \([\s\S]*?^endmodule',net,re.M)[0]
inputs={x.strip() for x in re.findall(r'^input\s+(?:\[[^\]]+\]\s+)?([^;]+);',body,re.M)}
resets={x for x in re.findall(r'\.CLEAR\(([^)]+)\)',body) if x in inputs}
assert len(resets)==1,resets
reset_name=resets.pop()
capture_ce=re.search(r'DFFCE\s+note_r_0_s0\s*\([\s\S]*?\.CE\((\w+)\)',body)[1]
start_name=capture_ce if capture_ce in inputs else 'grant'
assert start_name in inputs,start_name
state_port=re.search(r'^output\s+(\[[^\]]+\])\s+state;',body,re.M)
s=(R/'tests/recording_20261018_150135/verify_loader.py').read_text()
s=s.replace("elif name=='n290_6':", "elif name=='"+reset_name+"':")
s=s.replace("elif name=='n135_6':val=\"(state[3:0]==0)\"", "elif name=='"+start_name+"':val='req'")
s=s.replace("elif name=='out_velocity_Z':val=\"1'b1\"", "elif name=='out_note_Z':val='note'\n        elif name=='out_velocity_Z':val=\"7'd100\"\n        elif name.startswith('rel_s_7'):val=\"1'b1\"")
if state_port:
    s=s.replace("'state':'state'", "'state':'state"+state_port[1]+"'")
else:
    # This synthesis split the externally observed state bits into scalar ports.
    # Reproduce the parent's grant_8 idle decode; grant itself remains stimulus.
    assert all(x in body for x in ('output state_0;', 'output state_1;', 'output state_4;'))
    state_outputs="'state_0':'state[0]','state_1':'state[1]','state_4':'state[4]'"
    if 'grant_8' in inputs:
        assert 'output n1428_11;' in body
        state_outputs+=",'n1428_11':'idle_hi'"
        s=s.replace("elif name=='grant':val='req'", "elif name=='grant':val='req'\n        elif name=='grant_8':val='(idle_hi && !(state[4] | state[1] | state[0]))'")
    s=s.replace("'state':'state'", state_outputs)
    s=s.replace('wire[4:0]state;', 'wire[4:0]state;wire idle_hi;\nassign state[3:2]=d.state_2[3:2];')
s=s.replace('n<=75','n<=91').replace('range(60,76)','range(60,92)').replace('6400','12800')
s=s.replace("'notes':16","'notes':32").replace('16 notes','32 notes')
s=s.replace("elif name.startswith('eng'):", "elif name=='chosen':val=\"5'd0\"\n        elif name.startswith('eng'):")
ns={'__file__':str(__file__),'__name__':'gate32_helpers'}
exec(compile(s,str(__file__),'exec'),ns)
result=ns['run']('out/gate_loader32',R/'impl/gwsynthesis/yinyue_fashengqi.vg')
assert result['status']=='PASS' and result['notes']==32 and result['words']==12800
print('PASS32 actual current integrated mapped Loader/ROMs, 12800 model-matched parameter words')
