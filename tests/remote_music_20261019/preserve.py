"""Compare the pre-integration production piano with the new unity path."""
from pathlib import Path
import sys
sys.path.insert(0,str(Path(__file__).resolve().parent))
from run import ROOT,OUT,run,sources,IVER,VVP
OUT.mkdir(exist_ok=True)
backup=ROOT/'audit/remote_music_20261019/backup/src'
old=(backup/'tang_mega_138k_pro_top.v.v').read_text(encoding='utf-8-sig')
for a,b in [('tang_mega_138k_pro_top','baseline_board'),('synth_top','baseline_synth_top')]:old=old.replace(a,b)
(OUT/'baseline_board.v').write_text(old,encoding='utf-8')
for file,module in [('synth_top.v','synth_top'),('synth_event_frontend.v','synth_event_frontend'),('synth_core.v','synth_core')]:
 s=(backup/file).read_text(encoding='utf-8-sig')
 for name in ['synth_event_frontend','synth_core','synth_top']:s=s.replace(name,'baseline_'+name)
 (OUT/('baseline_'+file)).write_text(s,encoding='utf-8')
tb=(ROOT/'tests/keyboard32_20261019/tb_preserve16.sv').read_text()
tb=tb.replace('.ttp229_sdo(a_sdo),',".ttp229_sdo(a_sdo),.ttp229_2_sdo(1'b1),")
tb=tb.replace('.ttp229_2_scl(scl2),',".esp_uart_rx(1'b1),.esp_spi_sck(1'b0),.esp_spi_cs_n(1'b1),.esp_spi_mosi(1'b0),.ttp229_2_scl(scl2),")
tb=tb.replace('oldboard.u_synth_top','oldboard.u_baseline_synth_top')
tb=tb.replace('original16','original piano').replace('unconnected bank2 silent','unconnected bank2 and ESP32 silent')
(OUT/'tb_preserve.sv').write_text(tb,encoding='utf-8')
files=[*sources(),*[OUT/n for n in ['baseline_board.v','baseline_synth_top.v','baseline_synth_event_frontend.v','baseline_synth_core.v','tb_preserve.sv']],'sim/models/ttp229_bfm.v']
run('preserve_compile',[IVER,'-g2012','-s','tb_preserve16','-o',OUT/'preserve.vvp',*files])
run('preserve',[VVP,OUT/'preserve.vvp'])
