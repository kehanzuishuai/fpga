"""Exercise exact early indicator selection with changing32-voice bitmaps."""
from pathlib import Path
import hashlib,json,re,subprocess,sys
R=Path(__file__).resolve().parents[2];sys.path.insert(0,str(R/'tools'))
from display_voice_pixel_20261023 import select_voice_pixel
from display_pane_geometry_20261023 import prepare_pane_geometry
A=R/'audit/routing_followup_20261022';O=A/'voice_pixel';O.mkdir(exist_ok=True)
s=(R/'src/display/visual_scene.sv').read_text();(O/'before_visual_scene.sv').write_text(s)
c=prepare_pane_geometry(select_voice_pixel(s));(O/'candidate_visual_scene.sv').write_text(c)
gold=s
for name in re.findall(r'\bmodule\s+(\w+)',s):gold=re.sub(r'\b'+name+r'\b','scene_before' if name=='visual_scene' else name+'_voice_reference',gold)
(O/'gold.sv').write_text(gold)
tb=(A/'well_geometry/verification/pixels.sv').read_text()
tb=tb.replace('i<512','i<8704')
marker='  #3;clk=1;#3;';assert tb.count(marker)==1
tb=tb.replace(marker,'''  //256 cycles per voice exercise rectangle edges, every row, changing
  //one-hot/all-on/all-off/complement masks and status validity.
  if(i>=512 && i<8704-40)begin
   k=(i-512)/256;
   x=12'(1192+(k%8)*27+((i-512)%32)-5);
   y=12'(226+(k/8)*41+(((i-512)%256)/8)-2);
   case(i%4)
    0:status[50+:32]=32'd1<<k;
    1:status[50+:32]=~(32'd1<<k);
    2:status[50+:32]=32'hffffffff;
    3:status[50+:32]=0;
   endcase
   live=i%11!=0;status[4]=i%13!=0;
  end
'''+marker)
tb=tb.replace('512 scene pixel comparisons','8704 scene pixel comparisons')
(O/'tb.sv').write_text(tb)
iv=Path('D:/gaoyun/piano_v2/codex_test/tools/iverilog/bin/iverilog.exe')
for name,args in [('compile',[iv,'-g2012','-s','tb','-o',O/'test.vvp',O/'candidate_visual_scene.sv',O/'gold.sv',O/'tb.sv']),('simulation',[iv.with_name('vvp.exe'),O/'test.vvp'])]:
 p=subprocess.run(list(map(str,args)),cwd=R,capture_output=True,text=True,timeout=300)
 (O/(name+'.log')).write_text(p.stdout+p.stderr)
 if p.returncode:raise RuntimeError((p.stdout+p.stderr)[-3500:])
 print(p.stdout[-1300:],flush=True)
assert (R/'src/display/visual_scene.sv').read_text()==s
r=dict(status='PASS_ISOLATED_VOICE_PIXEL_AND_PANE_NOT_APPLIED',cycles=8704,voice_indicators=32,latency_cycles=40,
 before_sha256=hashlib.sha256((O/'before_visual_scene.sv').read_bytes()).hexdigest(),candidate_sha256=hashlib.sha256((O/'candidate_visual_scene.sv').read_bytes()).hexdigest(),
 scope='Final scene RGB equals V7 with all32 indicator regions and cycle-varying metadata; existing40 clocks and pane appearance preserved. Physical audio untouched.',programming=False)
(O/'RESULT.json').write_text(json.dumps(r,indent=2));print(json.dumps(r,indent=2))
