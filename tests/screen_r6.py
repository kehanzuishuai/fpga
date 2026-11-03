from pathlib import Path
import sys,json
sys.path.insert(0,str(Path(__file__).resolve().parent))
from run_checks import sim,full_sources,sha
B=Path(__file__).resolve().parents[1];C=B/'audit/timing_candidate_r6';O=B/'tests/out'
s=(B/'tests/tb_adsr_screen.sv').read_text().replace('module tb_adsr_screen;','module tb_adsr_screen_r6;').replace('adsr_screen.ppm','adsr_screen_r6.ppm')
p=O/'tb_adsr_screen_r6.sv';p.write_text(s)
files=[C/f.relative_to(B) if f.is_relative_to(B) else f for f in full_sources()]
sim('tb_adsr_screen_r6',[p,*files],timeout=3600)
print('PASS candidate raster; native production RTL with no Icarus transformation')
