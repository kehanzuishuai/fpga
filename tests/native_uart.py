from pathlib import Path
import subprocess,os
b=Path(__file__).resolve().parents[1];o=b/'tests/native';os.environ['TEMP']=str(o);os.environ['TMP']=str(o)
cc=Path(r'C:\Xilinx\Model_Composer\2020.2\tps\mingw\6.2.0\win64.o\nt\bin\g++.exe')
iv=Path(r'D:\gaoyun\piano_v2\codex_test\tools\iverilog\bin\iverilog.exe')
h=b/'firmware/remote_music_ble/esp32/ESP32_FPGA_Music_Controller'
src=[b/'src/remote/wifi_core.sv',b/'src/remote/control/wifi_control.sv',*sorted((b/'src/remote/uart').glob('*.sv'))]
steps=[('native_compile',[cc,'-std=c++11','-O2','-static','-I'+str(h),o/'stream_probe.cpp','-o',o/'probe.exe']),('generate',[o/'probe.exe','generate','requests.hex']),('uart_compile',[iv,'-g2012','-s','tb_uart_probe','-o','probe.vvp',o/'tb_uart_probe.sv',*src]),('uart',[iv.with_name('vvp.exe'),'probe.vvp']),('replay',[o/'probe.exe','validate','requests.hex','replies.hex'])]
for name,args in steps:
 p=subprocess.run(list(map(str,args)),cwd=o,capture_output=True,text=True,timeout=180);(o/(name+'.log')).write_text(p.stdout+p.stderr);print(name,p.returncode,(p.stdout+p.stderr)[-1800:],flush=True);assert p.returncode==0
