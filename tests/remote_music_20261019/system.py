from pathlib import Path
import sys
sys.path.insert(0,str(Path(__file__).resolve().parent))
from run import ROOT,OUT,run,sources,IVER,VVP
tb=(ROOT/'tests/keyboard32_20261019/tb_system32.sv').read_text()
tb=tb.replace('module tb_system32','module tb_system_remote')
tb=tb.replace('.ttp229_scl(scl0),',".esp_uart_rx(1'b1),.esp_spi_sck(1'b0),.esp_spi_cs_n(1'b1),.esp_spi_mosi(1'b0),.ttp229_scl(scl0),")
tb=tb.replace('tests/keyboard32_20261019/','tests/remote_music_20261019/out/')
(OUT/'tb_system.sv').write_text(tb)
files=[*sources(),OUT/'tb_system.sv','sim/models/ttp229_bfm.v','sim/models/i2s_rx_model.v','sim/tb/tb_pcm5102_i2s.v','tests/display/sim/tmds_stream_checker.sv']
run('system_compile',[IVER,'-g2012','-s','tb_system_remote','-o',OUT/'system.vvp',*files])
run('system',[VVP,OUT/'system.vvp'],3600)
