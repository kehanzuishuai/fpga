"""Run synthesis only, recording exact inputs and refusing stale results."""
from pathlib import Path
import hashlib,json,datetime,subprocess,re,sys,xml.etree.ElementTree as ET
R=Path(__file__).resolve().parents[2];A=R/'audit/display_integration_20261021';O=Path(__file__).resolve().parent/'out'
tag=sys.argv[1] if len(sys.argv)>1 else 'pipeline'
assert re.fullmatch('[a-z0-9_]+',tag)
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
paths=[R/f.get('path') for f in ET.parse(R/'yinyue_fashengqi.gprj').findall('./FileList/File') if f.get('enable')=='1']
paths+=list((R/'assets').glob('*.hex'))+[R/'yinyue_fashengqi.gprj',R/'impl/yinyue_fashengqi_process_config.json',R/'tools/build_display_integration_syn.tcl']
inputs={p.relative_to(R).as_posix():sha(p) for p in sorted(set(paths))}
now=lambda:datetime.datetime.now(datetime.timezone.utc).isoformat()
log=O/f'gowin_syn_{tag}.log';receipt=A/f'SYN_{tag.upper()}.json'
record={'status':'SYNTHESIZING','started_utc':now(),'inputs':inputs,'log':log.relative_to(R).as_posix(),'programming':False,'automatic_routing':False}
receipt.write_text(json.dumps(record,indent=2));started=receipt.stat().st_mtime
with log.open('w',encoding='utf-8') as f:
 p=subprocess.run(['C:/Gowin2/Gowin_V1.9.12_x64/IDE/bin/gw_sh.exe',str(R/'tools/build_display_integration_syn.tcl')],cwd=R,stdout=f,stderr=subprocess.STDOUT)
s=log.read_text(errors='replace');errors=re.findall(r'^ERROR.*',s,re.M)
changed=[name for name,h in inputs.items() if not (R/name).is_file() or sha(R/name)!=h]
passed=p.returncode==0 and not errors and 'GowinSynthesis finish' in s and not changed
record.update(status='SYNTHESIS_PASSED_PNR_PENDING' if passed else 'SOURCE_CHANGED' if changed else 'SYNTHESIS_FAILED',finished_utc=now(),returncode=p.returncode,errors=errors,changed_inputs=changed)
if passed:
 net=R/'impl/gwsynthesis/yinyue_fashengqi.vg';resource=net.with_name('yinyue_fashengqi_syn_rsc.xml')
 assert net.stat().st_mtime>=started and resource.stat().st_mtime>=started
 record.update(netlist_sha256=sha(net),resources=ET.parse(resource).getroot().attrib)
report=R/'impl/gwsynthesis/yinyue_fashengqi_syn.rpt.html'
if report.exists() and report.stat().st_mtime>=started:
 text=report.read_text(errors='replace');a=text.find('<a name="performance">');b=text.find('<h3>Path&nbsp1',a)
 record['synthesis_frequency_estimate']=re.sub('<[^>]+>',' ',text[a:b]).split()
 summary=' '.join(record['synthesis_frequency_estimate'])
 record['clock_frequency_estimates_mhz']={clock:float(actual) for clock,constraint,actual in re.findall(r'(\S+)\s+(\d+\.\d+)\(MHz\)\s+(\d+\.\d+)\(MHz\)',summary)}
receipt.write_text(json.dumps(record,indent=2))
print(record['status'],flush=True);print('\n'.join(errors),flush=True)
sys.exit(0 if passed else 1)
