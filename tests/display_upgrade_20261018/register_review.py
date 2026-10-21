from pathlib import Path
import xml.etree.ElementTree as ET,json
R=Path(__file__).resolve().parents[2];p=R/'yinyue_fashengqi.gprj';s=p.read_text(encoding='utf8')
old=ET.fromstring(s[s.index('<Project'):]);existing={e.attrib['path'] for e in old.findall('./FileList/File')}
paths=['docs/DISPLAY_UPGRADE_16KEY_20261018.md','docs/LISSAJOUS_VIDEO_FIX_20261018.md']+[f'tests/display_upgrade_20261018/{n}.py' for n in ['run_checks','integration_checks','timing_checks','label_equivalence','preview','build','boundary_checks','audit_current']]+[f'tests/lissajous_video_20261018/{n}' for n in ['generate_hilbert.py','verify_hilbert.py','response_44.csv']]
added=[q for q in paths if q not in existing]
assert all((R/q).is_file() for q in paths)
s=s.replace('    </FileList>','        <!-- Display upgrade review and verification; excluded from synthesis. -->\n'+''.join(f'        <File path="{q}" type="file.other" enable="0"/>\n' for q in added)+'    </FileList>')
p.write_text(s,encoding='utf8')
(R/'audit/display_upgrade_20261018/REVIEW_REGISTRATION.json').write_text(json.dumps({'added':added,'enabled':False,'project':str(p)},indent=2))
print('Registered',len(added),'review/test files; active HDL unchanged.')
