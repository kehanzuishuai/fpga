"""Join immutable verification jobs, run implementation, then publish local results."""
from pathlib import Path
import json,time,sys,importlib
import results
A,O=results.A,results.O

def wait_pass(name):
    p=A/(name+'.json')
    while not p.exists():time.sleep(10)
    assert json.loads(p.read_text())['status']=='PASS',str(p)

if __name__=='__main__':
    if sys.argv[1:]==['final-only']:
        # Join already completed implementation without rerunning or editing it.
        wait_pass('SUITE');importlib.reload(results).finalize();sys.exit(0)
    wait_pass('STREAMS');wait_pass('GAIN_CAPTURE');results.analyze()
    wait_pass('INTEGRATED')
    # Register only after these benches have been materialized by the suite.
    while not all((O/f).exists() for f in ['tb_direct_midi.sv','tb_scale_mapping.sv','tb_voice_peak.sv','tb_audio_stress_default.sv']):time.sleep(5)
    results.register_review();results.build()
    wait_pass('SUITE');importlib.reload(results).finalize()
