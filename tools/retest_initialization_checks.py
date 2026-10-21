from pathlib import Path
import os,sys,importlib.util,json
r=Path(__file__).resolve().parents[1];os.chdir(r)
spec=importlib.util.spec_from_file_location('piano_regression',r/'sim/run_tests.py')
rt=importlib.util.module_from_spec(spec);spec.loader.exec_module(rt)
case=[x for x in rt.VOICE_SHORT if x[0]=='note_0']
rt.run_voice(case,'voice')
spec=importlib.util.spec_from_file_location('piano_more',r/'sim/run_more.py')
more=importlib.util.module_from_spec(spec);spec.loader.exec_module(more)
more.run_dac_top(rt.report,rt.compile_tb,rt.sh)
bad=[n for n,ok in rt.results if not ok]
rt.write_manifest('initialization_retest',bad)
(r/'tests/results/initialization_retest.json').write_text(json.dumps({'status':'PASS' if not bad else 'FAILED','scope':'Only affected MIDI0 and dual-DAC testbench initialization; no FPGA RTL changes','results':[{'name':n,'pass':ok} for n,ok in rt.results]},indent=2),encoding='utf-8')
print('%d retests, %d failed'%(len(rt.results),len(bad)),flush=True)
sys.exit(1 if bad else 0)
