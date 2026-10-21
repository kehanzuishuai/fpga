"""Synthesize isolated additions to identify resource growth without changing main project."""
from pathlib import Path
import subprocess,sys,xml.etree.ElementTree as ET
R=Path(__file__).resolve().parents[2]
name=sys.argv[1]
tops={'aux':'yinse_aux_voice','bank':'probe_aux_bank','lane':'probe_aux_bank','sine':'yinse_sine_rom','organ':'yinse_organ_profile','ks':'yinse_ks_loop','control':'wifi_control','wav':'wav_pcm_player','wav_variant':'wav_pcm_player','spi':'wav_spi_stream'}
top=tops[name]
O=R/'tests/remote_music_20261019/resource'/name;O.mkdir(parents=True,exist_ok=True)
sources=list((R/'src/instruments').rglob('*.sv')) if name in ('aux','bank','lane','sine','organ','ks') else [R/f'src/remote/{top}.sv']
if name=='wav_variant':sources=[O/'wav_pcm_player.sv']
if name=='control':sources=[R/'src/remote/control/wifi_control.sv']
if name in ('bank','lane'):
 wrapper=O/'bank32.sv'
 wrapper.write_text((R/'src/instruments/gongyong/yinse_aux_bank.sv').read_text().replace('module yinse_aux_bank','module probe_aux_bank').replace('VOICES=16','VOICES='+('32' if name=='bank' else '8')).replace('MIX_SHIFT=$clog2(VOICES)','MIX_SHIFT=3'))
 sources.append(wrapper)
project=ET.Element('Project');ET.SubElement(project,'Template').text='FPGA';ET.SubElement(project,'Version').text='5'
ET.SubElement(project,'Device',name='GW5AST-138C',pn='GW5AST-LV138FPG676AC1/I0').text='gw5ast138c-003'
files=ET.SubElement(project,'FileList')
for p in sources:ET.SubElement(files,'File',path=p.as_posix(),type='file.verilog',enable='1')
(O/'probe.gprj').write_bytes(ET.tostring(project,encoding='utf-8',xml_declaration=True))
(O/'probe.tcl').write_text(f'cd {{{O.as_posix()}}}\nopen_project probe.gprj\nset_option -verilog_std sysv2017\nset_option -top_module {top}\nrun syn\nexit\n')
with (O/'probe.log').open('w') as f:
 p=subprocess.run(['C:/Gowin2/Gowin_V1.9.12_x64/IDE/bin/gw_sh.exe',str(O/'probe.tcl')],cwd=O,stdout=f,stderr=subprocess.STDOUT)
print((O/'probe.log').read_text(errors='replace')[-5000:]);sys.exit(p.returncode)
