"""Render a test scene through the real renderer and the real16-key HUD."""
from pathlib import Path
import sys,subprocess,re
R=Path(__file__).resolve().parents[2];O=Path(__file__).resolve().parent
sys.path.insert(0,str(R/'tools/audio_vendor'))
from PIL import Image
IV=Path(r'D:/gaoyun/piano_v2/codex_test/tools/iverilog/bin/iverilog.exe');VV=IV.with_name('vvp.exe')
import math,json
coeff=json.loads((R/'tests/lissajous_video_20261018/hilbert_coefficients_1023.json').read_text())
def pcm(n):return round(14000*math.sin(2*math.pi*261.63*n/48000)+4000*math.sin(2*math.pi*523.26*n/48000))
wave=[]
for n in range(1023,1535):
    xx=pcm(n-511);yy=max(-32768,min(32767,sum(pcm(n-2*k)*coeff[k] for k in range(512))>>15))
    wave.append(((pcm(n)&65535)<<33)|((xx&65535)<<16)|(yy&65535))
(O/'sim_out_visual/render_wave_preview.hex').write_text(''.join(f'{v:013x}\n' for v in wave))
s=(O/'sim/tb_renderer_1080.sv').read_text().replace('module tb_renderer_1080;','module tb_preview;').replace('render_wave.hex','render_wave_preview.hex')
s=s.replace(' wire [7:0] r,g,b;wire ode,ohs,ovs;', ''' wire [7:0] r,g,b;wire ode,ohs,ovs;
 wire ink,area,keyon;
 piano_status_overlay #(.MAPPING_CONFIRMED(0),.INFO_Y(164),.DETAIL_Y(176),.KEY_X(8),.KEY_Y(198),.KEY_PITCH(24),.KEY_WIDTH(20),.KEY_HEIGHT(10)) hud(
  10'(x/12'd3),10'(y/12'd3),{16'ha005,6'd4,24'h0abcde,7'd60,1'b1,4'd3},ink,area,keyon);
 wire[7:0]fr=ink?8'd240:(area?(keyon?8'd40:8'd16):r);
 wire[7:0]fg=ink?8'd240:(area?(keyon?8'd240:8'd32):g);
 wire[7:0]fb=ink?8'd200:(area?(keyon?8'd96:8'd48):b);
''')
s=s.replace('frame_logical.hex','frame_hud16.hex').replace('$fdisplay(f,"%02x%02x%02x",r,g,b)','$fdisplay(f,"%02x%02x%02x",fr,fg,fb)')
(O/'tb_preview.sv').write_text(s)
files=[p for p in (R/'src/display').glob('*') if p.suffix in ['.v','.sv'] and p.name not in ['visual_video_clock.v','visual_dvi_io.v']]
for label,args in [('compile',[IV,'-g2012','-s','tb_preview','-o',O/'preview.vvp',O/'tb_preview.sv',*files]),('run',[VV,O/'preview.vvp'])]:
    p=subprocess.run(list(map(str,args)),cwd=O,stdout=subprocess.PIPE,stderr=subprocess.STDOUT);(O/('preview_'+label+'.log')).write_bytes(p.stdout);assert p.returncode==0,p.stdout[-2000:]
rows=(O/'sim_out_visual/frame_hud16.hex').read_text().splitlines();assert len(rows)==640*360
img=Image.frombytes('RGB',(640,360),bytes.fromhex(''.join(rows))).resize((1920,1080),Image.Resampling.NEAREST)
img.save(O/'preview_1080p30_16keys.png');print('Rendered actual RTL plus16-key HUD at3x; synthetic test inputs, not board screenshot.')
