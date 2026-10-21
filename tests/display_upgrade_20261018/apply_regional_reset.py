from pathlib import Path
import shutil,json
R=Path(__file__).resolve().parents[2];O=Path(__file__).resolve().parent;P=O/'clock_probes/regional_3_phase7'
assert json.loads((P/'RESULT.json').read_text())['status']=='PASS'
shutil.copy2(P/'visual_pll_mod.v',R/'src/display/gowin_pll/visual_pll_mod.v')
p=R/'src/display/visual_dvi_io.v';s=p.read_text().replace('reset_global','reset_regional')
s=s.replace(' // Three release stages on the dedicated185.625MHz PLL output. Its phase',' // The reset DCS uses PTR3[0] regional routing near the serializer IOs.\n // Three release stages on the dedicated185.625MHz PLL output. Its phase')
p.write_text(s)
p=R/'src/integrated.sdc';s=p.read_text();replacement={line.split()[2]:line for line in (P/'probe.sdc').read_text().splitlines() if line.startswith('create_generated_clock -name video_serial_reset')}
assert len(replacement)==2
s='\n'.join(replacement.get(line.split()[2],line) if line.startswith('create_generated_clock -name video_serial_reset') else line for line in s.splitlines())+'\n'
s=s.replace('video_serial_reset_global','video_serial_reset_regional');p.write_text(s)
p=R/'src/integrated.cst';s=p.read_text();assert 'INS_LOC "u_video_io/reset_buffer"' not in s
p.write_text(s+'// Keep the five reset flops on the peripheral regional clock near IOR33..47.\nINS_LOC "u_video_io/reset_buffer" PTR3[0];\n')
print('Applied verified regional reset clock; fine7, rising trim100ps; exact non-50% duty retained in SDC.')
