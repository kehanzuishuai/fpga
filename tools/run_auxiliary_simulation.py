from pathlib import Path
import sys,json,os
R=Path(__file__).resolve().parents[1]
path=R/'tests/yinse/sim/run_tests.py'
# Reuse reviewed test functions, but do not execute unavailable lint/Yosys stages.
ns={'__file__':str(path),'__name__':'yinse_independent_helpers'}
code=path.read_text(encoding='utf-8').split('\ntry:\n',1)[0]
exec(compile(code,str(path),'exec'),ns)
sim=ns['sim'];out=ns['OUT'];results=ns['RESULTS']
try:
 for top,name in [('tb_yinse_controls','controls'),('tb_yinse_tables','tables'),('tb_yinse_switch_edges','switch_edges'),('tb_yinse_range','range'),('tb_yinse_events','events')]:sim(top,name)
 for instrument,note in [(1,60),(1,69),(2,60),(2,69),(3,60),(3,69),(4,60),(4,69)]:
  name=f'audio_{instrument}_{note}';p=out/(name+'.txt')
  sim('tb_yinse_audio',name,args=[f'+instrument={instrument}',f'+note={note}',f'+output={p.as_posix()}'])
  ns['audio_check'](p,instrument,note,1)
 for instrument in [1,2,3,4]:
  name=f'budget_16_{instrument}';p=out/(name+'.txt')
  sim('tb_yinse_audio',name,params=['-Ptb_yinse_audio.VOICES=16','-Ptb_yinse_audio.FRAME_CYCLES=256','-Ptb_yinse_audio.TOTAL_FRAMES=512'],
      args=[f'+instrument={instrument}',f'+output={p.as_posix()}'])
 report={'status':'PASS','scope':'Independent candidate Icarus simulation only; no auxiliary audio-path integration, strict lint, Yosys or Gowin auxiliary mapping claim','results':results}
 (out/'current_results.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
 print('ALL CURRENT AUXILIARY SIMULATION CHECKS PASS',flush=True)
except Exception as e:
 (out/'current_results.json').write_text(json.dumps({'status':'FAILED','results':results,'error':str(e)},indent=2),encoding='utf-8')
 print('FAIL',e,flush=True);sys.exit(1)

