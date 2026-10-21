"""Isolated internal 50-MHz timing experiment. Its automatic IO mapping is NOT a board image."""
from pathlib import Path
import sys,subprocess,xml.etree.ElementTree as ET
R=Path(__file__).resolve().parents[2];variant='variant' in sys.argv;spi='spi' in sys.argv
name='spi_timing' if spi else ('wav_variant_timing' if variant else 'wav_timing')
candidate='candidate' in sys.argv
if candidate:name='spi_candidate_timing' if spi else 'wav_candidate_timing'
top='wav_spi_stream' if spi else 'wav_pcm_player'
O=R/'tests/remote_music_20261019/resource'/name;O.mkdir(parents=True,exist_ok=True)
source=R/'tests/remote_music_20261019/resource/wav_variant/wav_pcm_player.sv' if variant else R/f'src/remote/{top}.sv'
if candidate:source=R/f'tests/remote_music_20261019/out/wav_timing_candidate/{top}.sv'
(O/'clock.sdc').write_text('create_clock -name clk -period 20.000 [get_ports {clk}]\n')
p=ET.Element('Project');ET.SubElement(p,'Template').text='FPGA';ET.SubElement(p,'Version').text='5'
ET.SubElement(p,'Device',name='GW5AST-138C',pn='GW5AST-LV138FPG676AC1/I0').text='gw5ast138c-003'
files=ET.SubElement(p,'FileList')
ET.SubElement(files,'File',path=source.as_posix(),type='file.verilog',enable='1')
ET.SubElement(files,'File',path=(O/'clock.sdc').as_posix(),type='file.sdc',enable='1')
(O/'probe.gprj').write_bytes(ET.tostring(p,encoding='utf-8',xml_declaration=True))
(O/'build.tcl').write_text(f'cd {{{O.as_posix()}}}\nopen_project probe.gprj\nset_option -verilog_std sysv2017\nset_option -top_module {top}\nset_option -gen_text_timing_rpt 1\nrun all\nexit\n')
with (O/'timing.log').open('w') as f:
 result=subprocess.run(['C:/Gowin2/Gowin_V1.9.12_x64/IDE/bin/gw_sh.exe',str(O/'build.tcl')],cwd=O,stdout=f,stderr=subprocess.STDOUT)
print((O/'timing.log').read_text(errors='replace')[-5000:]);sys.exit(result.returncode)
