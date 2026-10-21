from pathlib import Path
p=Path(__file__).resolve().parents[1]/'src/synth_core.v'
s=p.read_text(encoding='utf-8');a=s.index('generate if(REMOTE_ENABLE!=0)');b=s.index('end endgenerate',a)+len('end endgenerate')
block=s[a:b];s=s[:a]+s[b:];point=s.index('assign test_disable_pulse')
s=s[:point]+block+'\n\n'+s[point:];p.write_text(s,encoding='utf-8')
