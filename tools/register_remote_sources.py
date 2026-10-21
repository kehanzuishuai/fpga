from pathlib import Path
import xml.etree.ElementTree as ET
root=Path(__file__).resolve().parents[1]
p=root/'yinyue_fashengqi.gprj';s=p.read_text(encoding='utf-8-sig')
paths=[*sorted((root/'src/remote/uart').glob('*.sv')),
       root/'src/remote/control/wifi_control.sv',root/'src/remote/control/wifi_score_player.sv',
       *sorted((root/'src/remote').glob('*.sv'))]
paths += [root/'src/instruments'/name for name in [
 'gongyong/yinse_aux_bank.sv','gongyong/yinse_aux_voice.sv','gongyong/yinse_envelope.sv',
 'gongyong/yinse_note_table.sv','gongyong/yinse_sine_rom.sv','yushe/yinse_preset.sv',
 'guanfengqin/yinse_organ_profile.sv','jianhuachangdi/yinse_flute_profile.sv',
 'zhongqin/yinse_bell_profile.sv','jita/yinse_ks_loop.sv','jita/yinse_ks_tuning.sv']]
for f in paths:
 path=f.relative_to(root).as_posix()
 if f'path="{path}"' not in s:s=s.replace('    </FileList>',f'        <File path="{path}" type="file.verilog" enable="1"/>\n    </FileList>')
p.write_text(s,encoding='utf-8')
p=root/'src/keyboard_debug.rao';s=p.read_text(encoding='utf-8-sig')
s=s.replace('storage_depth="4096"','storage_depth="1024"').replace('capture_amount="4096"','capture_amount="1024"')
p.write_text(s,encoding='utf-8')
p=root/'src/integrated.cst';s=p.read_text(encoding='utf-8-sig')
if 'IO_LOC "esp_uart_rx"' not in s:
 s+='\n// ESP32-S3, 3.3 V, independent of the two TTP229 buses.\n'
 for name,pin,extra in [('esp_uart_rx','B21',' PULL_MODE=UP'),('esp_uart_tx','A20',''),
 ('esp_spi_sck','L17',' PULL_MODE=DOWN'),('esp_spi_cs_n','H14',' PULL_MODE=UP'),
 ('esp_spi_mosi','E25',' PULL_MODE=DOWN'),('esp_spi_miso','D25','')]:
  s+=f'IO_LOC "{name}" {pin};\nIO_PORT "{name}" IO_TYPE=LVCMOS33{extra};\n'
 p.write_text(s,encoding='utf-8')
print(len(paths),'remote/instrument sources registered; GAO depth 1024; six explicit pins.')
