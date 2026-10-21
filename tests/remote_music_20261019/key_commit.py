"""Early focused UART commit check before launching a long full implementation."""
from run import ROOT,OUT,run,IVER,VVP
files=[*list((ROOT/'src/remote/uart').glob('*.sv')),'src/remote/wifi_core.sv','src/remote/control/wifi_control.sv','src/remote/control/wifi_score_player.sv','src/remote/remote_control.sv','src/ttp229_event_bridge.v']
run('key_commit_compile',[IVER,'-g2012','-s','tb_control','-o',OUT/'key_commit.vvp','tests/remote_music_20261019/tb_control.sv',*files])
run('key_commit',[VVP,OUT/'key_commit.vvp'])
