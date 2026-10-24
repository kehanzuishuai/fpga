"""Measure actual mapped BSRAM count for the paired memory primitive."""
from pathlib import Path
import shutil,subprocess,json,xml.etree.ElementTree as ET,hashlib
R=Path(__file__).resolve().parents[1];D=R/'audit/routing_followup_20261022/packed_ks/resource_pair';D.mkdir(exist_ok=False)
shutil.copy2(R/'src/instruments/gongyong/yinse_aux_bank.sv',D/'bank.sv')
(D/'probe.gprj').write_text('''<?xml version="1.0"?><Project><Template>FPGA</Template><Version>5</Version><Device name="GW5AST-138C" pn="GW5AST-LV138FPG676AC1/I0">gw5ast138c-003</Device><FileList><File path="bank.sv" type="file.verilog" enable="1"/></FileList></Project>''')
(D/'run.tcl').write_text(f'cd {{{D.as_posix()}}}\nopen_project probe.gprj\nset_option -verilog_std sysv2017\nset_option -top_module yinse_ks_ram_pair\nrun syn\nexit\n')
with (D/'console.log').open('w') as f:p=subprocess.run(['C:/Gowin2/Gowin_V1.9.12_x64/IDE/bin/gw_sh.exe',str(D/'run.tcl')],cwd=D,stdout=f,stderr=subprocess.STDOUT)
assert p.returncode==0,(D/'console.log').read_text(errors='replace')[-3000:]
resources=ET.parse(D/'impl/gwsynthesis/probe_syn_rsc.xml').getroot().attrib
assert resources.get('T_Bsram','').split('(')[0]=='3',resources
rec=dict(status='PASS_THREE_BSRAM_PER_TWO_VOICES',resources=resources,source_sha256=hashlib.sha256((D/'bank.sv').read_bytes()).hexdigest(),programming=False)
(D/'RESULT.json').write_text(json.dumps(rec,indent=2));print(json.dumps(rec,indent=2),flush=True)
