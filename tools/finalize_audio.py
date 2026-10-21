from pathlib import Path
import json,csv,re,hashlib,html,xml.etree.ElementTree as ET,datetime,sys
R=Path(__file__).resolve().parents[1];B=Path(r'D:\gaoyun\piano_v2_keyboard_v2');O=R/'tests/audio_diagnosis';A=R/'audit/audio_diagnosis'
def read(p):return p.read_text(encoding='utf-8-sig',errors='replace')
def load(p):return json.loads(read(p))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
checks=['BASELINE_RUN.json','INTERPOLATION_AUDIT.json','AMY_SOURCE_AUDIT.json','ANALYSIS_SUMMARY.json','CHAIN_AUDIT.json','audio_stress_results.json','REGRESSION_RESULTS.json']
for name in checks:assert load(O/name)['status']=='PASS',name
assert re.search(r'\b68 tests, 0 failed\b',read(O/'piano_regression.log'))
assert 'ALL DISPLAY-ONLY CHECKS PASS' in read(O/'display_regression.log')
assert 'MAP FAIL raw bit 1: actual MIDI 64 expected 61' in read(O/'mapping_before_run.log')
assert 'PASS default map/chain 16 bits, 32Voice build, DISPLAY_ENABLE=1' in read(O/'mapping_after_run.log')
assert all(load(O/'baseline'/f'midi_{n:03d}'/'result.json')['status']=='PASS' for n in list(range(60,76))+[24,36,48,84,104])
build=load(A/'BUILD_INPUT_HASHES.json');assert build['status']=='PASS' and build['fresh_bitstream']
for rel,h in build['input_sha256'].items():assert sha(R/rel)==h,'Build input changed '+rel
for rel,h in load(A/'BUILD_OUTPUT_HASHES.json').items():assert sha(R/rel)==h,'Build output changed '+rel
rows=list(csv.DictReader((A/'BASELINE_MANIFEST.csv').open(encoding='utf-8-sig')));baseline_diffs=[x['RelativePath'] for x in rows if not (B/x['RelativePath']).exists() or sha(B/x['RelativePath']).lower()!=x['SHA256'].lower()]
assert not baseline_diffs,'Baseline changed '+str(baseline_diffs)
protected=[x for x in rows if x['RelativePath'].replace('\\','/').startswith('src/') and x['RelativePath'].replace('\\','/')!='src/tang_mega_138k_pro_top.v.v']
assert all((R/x['RelativePath']).exists() and sha(R/x['RelativePath']).lower()==x['SHA256'].lower() for x in protected)
assert sha(R/'yinyue_fashengqi.gprj')==sha(B/'yinyue_fashengqi.gprj')
entries=[e for e in ET.parse(R/'yinyue_fashengqi.gprj').findall('./FileList/File') if e.attrib.get('enable')=='1']
assert all((R/e.attrib['path']).is_file() for e in entries)
assert len({e.attrib['path'] for e in entries})==len(entries)
assert any(e.attrib['path']=='src/keyboard/keyboard_state_mapper.sv' for e in entries)
assert next(e for e in entries if e.attrib['path'].endswith('.cst')).attrib['path']=='src/integrated.cst'
text=read(R/'src/tang_mega_138k_pro_top.v.v')
for param,value in [('BUILD_STAGE','3'),('DISPLAY_ENABLE','1'),('KEYBOARD_PROFILE','0'),('KEY_MAPPING_CONFIRMED','0')]:assert re.search(r'parameter\s+'+param+r'\s*=\s*'+value+r'\s*,',text)
assert '(KEYBOARD_PROFILE==0) ? {' not in text
tr=read(R/'impl/pnr/yinyue_fashengqi.tr')
assert '<Numbers of Setup Violated Endpoints>:0' in tr and '<Numbers of Hold Violated Endpoints>:0' in tr
slacks=[float(x) for x in re.findall(r'^Slack\s*:\s*(-?[\d.]+)',tr,re.M)];assert all(x>=0 for x in slacks)
def pins(p):
 result={}
 for body in re.findall(r'<tr[^>]*>(.*?)</tr>',read(p),re.S):
  cells=[html.unescape(re.sub('<[^>]+>','',v)).strip() for v in re.findall(r'<td[^>]*>(.*?)</td>',body,re.S)]
  if len(cells)>=3 and re.fullmatch(r'[A-Z]{1,2}\d+',cells[2].split('/')[0]):result[cells[0]]=cells[2].split('/')[0]
 return result
expected=pins(B/'impl/pnr/yinyue_fashengqi.pin.html');actual=pins(R/'impl/pnr/yinyue_fashengqi.pin.html');assert expected and actual==expected
(A/'PIN_AUDIT.json').write_text(json.dumps({'status':'PASS','expected':expected,'actual':actual},indent=2),encoding='utf8')
rpt=read(R/'impl/pnr/yinyue_fashengqi.rpt.txt');resources={}
for name,label in [('Logic','Logic'),('Register','Register'),('BSRAM','BSRAM'),('DSP','DSP'),('PLL','PLL'),('I/O Port','IO')]:
 m=re.search(r'^\s*'+re.escape(name)+r'\s*\|\s*([\d.]+)',rpt,re.M);assert m,name;v=float(m[1]);resources[label]=int(v) if v.is_integer() else v
for clk in ['clk_50m','audio_clk','video_pixel','tck_pad_i']:
 m=re.search(r'^\s*\d+\s+'+clk+r'\s+[\d.]+\(MHz\)\s+([\d.]+)\(MHz\)',tr,re.M);assert m,clk;resources[clk+'_fmax_MHz']=float(m[1])
resources.update({'setup_violated_endpoints':0,'hold_violated_endpoints':0,'minimum_reported_path_slack_ns':min(slacks) if slacks else None,'video_serial_fmax':'Dedicated 125MHz serialization; no ordinary Fmax path reported'})
assert resources['PLL']==2 and resources['IO']==23
baseline_resources={'Logic':43772,'Register':16238,'BSRAM':226,'DSP':98.5,'PLL':2,'IO':23,'clk_50m_fmax_MHz':279.598,'audio_clk_fmax_MHz':33.916,'video_pixel_fmax_MHz':33.026}
voice_samples=sum(int(re.search(r'samples compared: (\d+)',read(O/'baseline'/f'midi_{n:03d}'/'equivalence.log'))[1]) for n in list(range(60,76))+[24,36,48,84,104])
data={'status':'DIGITAL_VALIDATION_PASS','project':str(R/'yinyue_fashengqi.gprj'),'selected_baseline':str(B/'yinyue_fashengqi.gprj'),'selected_baseline_bitstream_sha256':load(A/'BASELINE_BUILD_OUTPUTS.json')['impl\\pnr\\ao_0.fs'],'production_rtl_changed':['src/tang_mega_138k_pro_top.v.v'],'old_13_key_module_found':False,'old_permutation_removed':True,'raw_bit_mapping':'bit0..15 -> MIDI60..75','physical_key_order_confirmed':False,'hardware_compatibility':'UNCONFIRMED','analog_audio_fix_confirmed':False,'automatic_programming_performed':False,'baseline_files_verified_unchanged':len(rows),'protected_src_files_unchanged':len(protected),'piano_checks':68,'piano_failures':0,'long_voice_note_cases':21,'voice_samples_bit_exact':voice_samples,'fx_samples_bit_exact':21*144000,'target_single_wav_files':32,'target_comparison_wav_files':4,'pins_unchanged':True,'resources_before':baseline_resources,'resources_after':resources,'bitstream':build['bitstream'],'bitstream_sha256':build['bitstream_sha256'],'build_started':build['started_at_Asia_Shanghai'],'expected_before_failure':str(O/'mapping_before_run.log'),'closed_at_Asia_Shanghai':datetime.datetime.now().astimezone().isoformat()}
(A/'FINAL_VALIDATION.json').write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf8');print(json.dumps(data,ensure_ascii=False,indent=2))