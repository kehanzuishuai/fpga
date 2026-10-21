"""Only check the changed XY peak pipeline against the existing ten bitmaps."""
from pathlib import Path
import json,hashlib
from run import ROOT,OUT,IVER,VVP,run
old=ROOT/'tests/display_upgrade_20261018/sim_out_visual'
tb=(ROOT/'tests/display_upgrade_20261018/sim/tb_xy_plot.sv').read_text()
tb=tb.replace('sim_out_visual/xy_plot.hex',(old/'xy_plot.hex').as_posix())
tb=tb.replace('sim_out_visual/xy_maps.txt',(OUT/'xy_timing_maps.txt').as_posix())
(OUT/'tb_xy_timing.sv').write_text(tb)
run('xy_timing_compile',[IVER,'-g2012','-s','tb_xy_plot','-o',OUT/'xy_timing.vvp',OUT/'tb_xy_timing.sv','src/display/visual_xy_plot.sv'])
run('xy_timing',[VVP,OUT/'xy_timing.vvp'],60)
a=(old/'xy_maps.txt').read_text().splitlines();b=(OUT/'xy_timing_maps.txt').read_text().splitlines()
assert len(a)==len(b)==20
cases=[]
for i in range(0,20,2):
 aa=a[i].split();bb=b[i].split()
 assert aa[:-1]==bb[:-1] and a[i+1]==b[i+1],i//2
 assert int(bb[-1])-int(aa[-1])==512,(aa,bb)
 cases.append({'case':i//2,'bitmap_exact':True,'additional_clocks':512,'clocks':int(bb[-1])})
p=ROOT/'src/display/visual_xy_plot.sv'
r={'status':'PASS','source_sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'scope':'Only changed peak pipeline. Ten previous reference bitmaps and mode/scale flags exact; 512 additional pixel clocks per snapshot. No complete HDMI-frame rerun.','cases':cases}
(OUT/'XY_TIMING_CHECK.json').write_text(json.dumps(r,indent=2));print('PASS ten XY bitmaps exact, 512 extra clocks, within blanking budget')
