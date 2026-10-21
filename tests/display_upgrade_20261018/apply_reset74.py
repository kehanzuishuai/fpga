from pathlib import Path
import json,shutil
R=Path(__file__).resolve().parents[2];O=Path(__file__).resolve().parent;P=O/'clock_probes/regional_reset74c1'
assert json.loads((P/'RESULT.json').read_text())['status']=='PASS'
rejected={'status':'REJECTED','build':'BUILD_regional_final.json','reason':'185.625MHz/pixel74.25MHz5:2 phase classes caused serializer bit rotation after restart despite passing STA. Improved aligned-PLL test with variable reset holds observed offsets[-10,-2]. Never accepted for delivery.','replacement':'Pixel-frequency74.25MHz regional reset clock, fixed phase and3release stages; same test offsets[-10] only'}
(R/'audit/display_upgrade_20261018/REJECTED_REGIONAL_185.json').write_text(json.dumps(rejected,indent=2))
shutil.copy2(P/'visual_pll_mod.v',R/'src/display/gowin_pll/visual_pll_mod.v')
p=R/'src/integrated.sdc';replacement={l.split()[2]:l for l in (P/'probe.sdc').read_text().splitlines() if l.startswith('create_generated_clock -name video_serial_reset')}
assert len(replacement)==2
s='\n'.join(replacement.get(l.split()[2],l) if l.startswith('create_generated_clock -name video_serial_reset') else l for l in p.read_text().splitlines())+'\n';p.write_text(s)
p=R/'src/display/visual_dvi_io.v';s=p.read_text().replace('185.625MHz','74.25MHz')
s=s.replace(' // Three release stages on the dedicated74.25MHz PLL output. Its phase',' // Each release stage adds one pixel period; reset word phase is fixed.\n // Three release stages on the dedicated74.25MHz PLL output. Its phase')
p.write_text(s)
print('Applied74.25MHz reset at pixel frequency, coarse1/fine7,100ps rising trim, regionalPTR3[0].')
