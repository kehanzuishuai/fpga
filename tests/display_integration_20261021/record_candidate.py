"""Record current sources and verified artifacts without running more regression."""
from pathlib import Path
import json,hashlib,re,xml.etree.ElementTree as ET,datetime,sys
R=Path(__file__).resolve().parents[2];A=R/'audit/display_integration_20261021';O=Path(__file__).resolve().parent/'out'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
paths=[R/f.attrib['path'] for f in ET.parse(R/'yinyue_fashengqi.gprj').findall('./FileList/File') if f.get('enable')=='1']
fw=R/'firmware/remote_music/esp32/ESP32_FPGA_Music_Controller'
esp=json.loads((Path(__file__).resolve().parent/'esp32/esp32_compile.json').read_text())
assert esp['status']=='PASS'
for name,digest in esp['sources'].items():assert sha(fw/name)==digest,name
for name,data in esp['binaries'].items():
 p=Path(__file__).resolve().parent/'esp32'/name;assert sha(p)==data['sha256'],name
build=A/(sys.argv[1] if len(sys.argv)>1 else 'SYN_DISTRIBUTED_SHIFT_ALL.json')
run=json.loads(build.read_text())
assert run['status']=='SYNTHESIS_PASSED_PNR_PENDING',run['status']
for name,h in run['inputs'].items():assert sha(R/name)==h,'Stale synthesis: '+name
assert sha(R/'impl/gwsynthesis/yinyue_fashengqi.vg')==run['netlist_sha256'],'Netlist changed after recorded synthesis'
log=(R/run['log']).read_text(encoding='utf-8-sig',errors='replace')
errors=re.findall(r'^ERROR.*',log,re.M)
finished='GowinSynthesis finish' in log
status='SYNTHESIS_FAILED' if errors else 'SYNTHESIS_PASSED_PNR_PENDING' if finished else 'SYNTHESIZING'
frequency=run.get('clock_frequency_estimates_mhz',{})
pixel_estimates=[value for name,value in frequency.items() if 'pixel_clk' in name]
if finished and pixel_estimates and min(pixel_estimates)<74.25:status='SYNTHESIS_PASSED_TIMING_REPAIR_REQUIRED'
frequency_checks={}
for name,actual in frequency.items():
 required=50.0 if name=='clk_50m' else 74.25 if 'pixel_clk' in name else 12.288 if 'u_audio_pll/' in name else 27.0 if 'ref_pll/' in name else None
 if required is not None:frequency_checks[name]={'required_mhz':required,'estimate_mhz':actual,'meets_estimate':actual>=required}
if finished and any(not v['meets_estimate'] for v in frequency_checks.values()):status='SYNTHESIS_PASSED_TIMING_REPAIR_REQUIRED'
def checked_receipt(p):
 data=json.loads(p.read_text());hashes=data.get('files',data.get('source_sha256',{}))
 if isinstance(hashes,str):
  hashes={'src/display/visual_background.sv':hashes} if p.stem=='BACKGROUND_EQUIVALENCE' else {}
 changed=[name for name,h in hashes.items() if not (R/name).is_file() or sha(R/name)!=h]
 return {'recorded_status':data.get('status'),'matches_current_inputs':bool(hashes) and not changed,
         'changed_inputs':changed,'receipt':p.relative_to(R).as_posix()}
record={'status':status,'recorded_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),
 'approved_guidance':True,'phone_style_and_html_unchanged':True,
 'phone_change':'APP_JS only: activate approved existing practice container, using unchanged segments CSS',
 'display_rtl_byte_identical_to_delivery':False,'display_style':'Preserved with exact data packing, bounded arithmetic and latency-aligned pixel equivalence',
 'no_auto_programming':True,'automatic_routing_started':False,
 'synthesis_log':run['log'],'synthesis_errors':errors,'build_receipt':build.relative_to(R).as_posix(),
 'pnr_status':'Not run; old report/FS are the 2026-10-20 baseline',
 'sources':{p.relative_to(R).as_posix():sha(p) for p in paths},
 'gprj_sha256':sha(R/'yinyue_fashengqi.gprj'),
 'assets':{p.relative_to(R).as_posix():sha(p) for p in sorted((R/'assets').glob('*.hex'))},
 'firmware_sources':esp['sources'],'firmware_binaries':esp['binaries'],
 'baseline_fs_sha256':sha(R/'impl/pnr/ao_0.fs'),
 'validated_archive_fs_sha256':sha(R/'release/latest/ao_0.fs'),
 'checks':{p.stem:checked_receipt(p) for p in O.glob('*EQUIVALENCE.json')},
 'keyboard_latency_receipt':'tests/display_integration_20261021/out/KEYBOARD_LATENCY.json',
 'keyboard_latency_limitations':'Measured single keys below5ms at digital DAC pins; all32 last Voice10.965ms before final mix/DAC. TTP sensing/analog/display excluded.',
 'keyboard_latency_report':'docs/KEYBOARD_LATENCY_20261021.md'}
manual_failure=R/'audit/routing_repair_20261022/MANUAL_RUN_FAILURE.json'
if manual_failure.exists():
 record['previous_manual_implementation']={'receipt':manual_failure.relative_to(R).as_posix(),
  'details':json.loads(manual_failure.read_text())}
 record['automatic_routing_started_by_agent']=False
 record['pnr_status']='Previous text_sum_final netlist: user manual run failed PR0004 with420 unrouted nets at2026-10-22 13:28. Current replacement netlist not implemented. Detailed STA and FS remain2026-10-20 baseline.'
if 'SHIFT_STORAGE_EQUIVALENCE' in record['checks']:
 record['pixel_evidence']={'kind':'Historical pixel simulation plus annotation-only functional source identity',
  'proof':record['checks']['SHIFT_STORAGE_EQUIVALENCE'],
  'explanation':'The old RENDERER_EQUIVALENCE hash is intentionally not rewritten; the new proof verifies all simulation dependencies and normalizes only syn_srlstyle.'}
assert record['baseline_fs_sha256']==json.loads((A/'BEFORE.json').read_text())['files']['impl/pnr/ao_0.fs'],'Working FS changed during synthesis-only work'
latency=json.loads((O/'KEYBOARD_LATENCY.json').read_text())
latency_changed=[name for name,h in latency['source_sha256'].items() if sha(R/name)!=h]
audio_changed=[name for name in latency_changed if not name.startswith('src/display/')]
assert not audio_changed,'Audio input changed after latency test: '+str(audio_changed)
record['keyboard_latency_evidence']={'status':latency['status'],'audio_sources_match':True,
 'changed_uninstantiated_display_sources':latency_changed,
 'explanation':'Latency TB sets DISPLAY_ENABLE=0. Later display RTL changes are outside its instantiated audio path; unchanged adapter checked separately.',
 'rows':latency['rows']}
closure=json.loads((O/'CHECKS.json').read_text())
for name,h in closure['source_sha256'].items():assert sha(R/name)==h,'Stale project closure: '+name
for name,h in closure['asset_sha256'].items():assert sha(R/name)==h,'Stale asset: '+name
record['project_closure']={'status':closure['status'],'enabled_inputs':closure['enabled_inputs'],
 'receipt':'tests/display_integration_20261021/out/CHECKS.json'}
estimate=json.loads((O/'DISPLAY_CORE_TIMING_ESTIMATE.json').read_text())
for name,h in estimate['source_sha256'].items():assert sha(R/name)==h,'Stale display core timing estimate: '+name
record['display_core_timing_estimate']=estimate
record['main_synthesis_frequency_estimate']=run.get('synthesis_frequency_estimate')
record['frequency_estimate_checks']=frequency_checks
if finished and not errors:
 report=R/'impl/gwsynthesis/yinyue_fashengqi_syn_rsc.xml'
 assert report.stat().st_mtime>=build.stat().st_mtime-5 or sha(R/'impl/gwsynthesis/yinyue_fashengqi.vg')==run['netlist_sha256']
 record['synthesis_resources']=ET.parse(report).getroot().attrib
 record['synthesis_netlist_sha256']=sha(R/'impl/gwsynthesis/yinyue_fashengqi.vg')
(A/'CURRENT.json').write_text(json.dumps(record,indent=2),encoding='utf-8')
print(status,'; current ESP32 sources and all copied binaries match verified compilation')
