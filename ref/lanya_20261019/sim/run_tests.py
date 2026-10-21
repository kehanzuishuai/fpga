"""All generated results stay under lanya/sim/out. No hardware I/O."""
from pathlib import Path
import os,sys,json,hashlib,subprocess,random,xml.etree.ElementTree as ET
ROOT=Path(__file__).resolve().parents[1];BASE=ROOT.parent;OUT=ROOT/'sim/out';OUT.mkdir(exist_ok=True)
sys.path.insert(0,str(ROOT/'tongxin'))
from protocol import crc16,encode,decode,Decoder,Client,keymap_commands,score_commands
SOURCES=[ROOT/p for p in (ROOT/'rtl_sources.f').read_text().splitlines() if p.strip()]
ENV=dict(os.environ,LANG='C',LC_ALL='C',PYTHONDONTWRITEBYTECODE='1',PYTHONIOENCODING='utf-8')
ENV['PATH']='C:/Strawberry/c/bin;C:/Strawberry/perl/bin;'+ENV.get('PATH','')
results={};errors={}
def run(name,args,timeout=240):
 args=list(args)
 if not Path(str(args[0])).is_absolute() and (ROOT/str(args[0])).is_file():args[0]=(ROOT/str(args[0])).resolve()
 p=subprocess.run(list(map(str,args)),cwd=ROOT,env=ENV,capture_output=True,text=True,errors='replace',timeout=timeout)
 text=p.stdout+p.stderr;(OUT/(name+'.log')).write_text(text,encoding='utf-8')
 if p.returncode:raise RuntimeError(text[-7000:])
 return text
def check(name,fn):
 try:fn();results[name]='PASS';print(name,'PASS',flush=True)
 except Exception as e:results[name]='FAIL';errors[name]=str(e);print(name,'FAIL',str(e)[-2500:],flush=True)
def prepare():
 cases=[(0,1,b'',0,0x42543031),(1,16,b'\x02',0,2),(1,16,b'\x02',0,2),(1,16,b'\x01',4,0),
        (2,17,b'\x04',0,4),(3,18,b'\xff\x7f',0,32767),(4,16,b'\x03',1,0),(5,2,b'',0,32767<<16)]
 req=b''.join(encode(s,c,p) for s,c,p,_,_ in cases)
 rsp=b''.join(encode(s,128,bytes([c,status])+value.to_bytes(4,'little')) for s,c,_,status,value in cases)
 rsp+=encode(0,128,bytes([1,0])+int(0x42543031).to_bytes(4,'little'))
 for name,b in [('requests',req),('responses',rsp)]:
  (OUT/(name+'.hex')).write_text('\n'.join(f'{x:02x}' for x in b)+'\n')
 rng=random.Random(20261016);corpus=[]
 for _ in range(300):
  s=rng.randrange(256);c=rng.randrange(256);p=bytes(rng.randrange(256) for _ in range(rng.randrange(7)))
  corpus.append({'seq':s,'cmd':c,'payload':list(p),'hex':encode(s,c,p).hex()})
 (OUT/'corpus.json').write_text(json.dumps(corpus))
def python_protocol():
 assert crc16(b'123456789')==0x29b1
 for v in json.loads((OUT/'corpus.json').read_text()):
  b=bytes.fromhex(v['hex']);p=decode(b);assert (p.seq,p.cmd,list(p.payload))==(v['seq'],v['cmd'],v['payload'])
  d=Decoder();out=[]
  for x in b:out+=d.feed([x])
  assert out==[p]
  for bit in range(128):
   corrupt=bytearray(b);corrupt[bit//8]^=1<<(bit%8)
   try:decode(corrupt)
   except ValueError:pass
   else:raise AssertionError('single bit accepted')
 d=Decoder();a=encode(1,18,b'\xa5\x5a');b=encode(2,1)
 assert len(d.feed(b'noise'+a+b))==2
 assert len(keymap_commands(list(range(36,68))))==34
 assert len(score_commands([(60,100,500),(64,0,250)]))==4
 class Port:
  def __init__(self):self.sent=[];self.data=b''
  def write(self,b):
   self.sent.append(b)
   if len(self.sent)==2:self.data=encode(b[3],128,bytes([b[4],0,1,2,3,4]))
  def read(self,_):b=self.data[:3];self.data=self.data[3:];return b
 port=Port();c=Client(port,timeout=.005,retries=1)
 assert c.request(16,b'\x02')==b'\x01\x02\x03\x04' and port.sent[0]==port.sent[1]
def sim(top):
 extra=[BASE/'yinse/qiehuan/yinse_selector.sv',BASE/'yinse/qiehuan/yinse_switch.sv',BASE/'teleimenqin/anjianqiehuanyanzouyueqi/tl_mode_control.sv'] if top=='tb_existing_controls' else []
 image=OUT/(top+'.vvp');run(top+'_compile',[BASE/'bin/iverilog.exe','-g2012','-s',top,'-o',image,*SOURCES,*extra,ROOT/'sim'/(top+'.sv')])
 args=['+TRACE_COUNT='+ (OUT/'bridge_count.txt').read_text().strip()] if top=='tb_bridge' else []
 text=run(top,[BASE/'bin/vvp.exe',image,*args])
 if 'PASS' not in text or 'FATAL' in text:raise RuntimeError(text)
def lint():
 exe=Path(os.environ['APPDATA'])/'Python/Python313/Scripts/verilator-cli.exe'
 run('strict_lint',[exe,'--lint-only','--Wall','--top-module','wifi_core','--Mdir',OUT/'obj_lint',*SOURCES])
 run('remote_lint',[exe,'--lint-only','--Wall','--top-module','wifi_remote_control','--Mdir',OUT/'obj_remote',*SOURCES])
 run('steps_lint',[exe,'--lint-only','--Wall','--top-module','wifi_request_steps','--Mdir',OUT/'obj_steps',*SOURCES])
 run('adapter_lint',[exe,'--lint-only','--Wall','--top-module','wifi_instrument_control','--Mdir',OUT/'obj_adapter',*SOURCES])
def structure():
 exe=Path(os.environ['APPDATA'])/'Python/Python313/Scripts/yowasp-yosys.exe'
 script='read_verilog -sv '+' '.join(p.relative_to(ROOT).as_posix() for p in SOURCES)
 script+='; hierarchy -check -top wifi_remote_control; proc; opt; check -assert; log BT_COMPLETE'
 text=run('structure',[exe,'-Q','-T','-p',script])
 if 'Warning:' in text or 'BT_COMPLETE\n' not in text:raise RuntimeError(text[-7000:])
def bridge():
 run('cpp_compile',['C:/Strawberry/c/bin/g++.exe','-std=c++17','-Wall','-Wextra','-Werror','sim/test_bridge.cpp','-o','sim/out/test_bridge.exe'])
 text=run('cpp_bridge',['sim/out/test_bridge.exe'])
 assert 'PASS' in text
 sim('tb_bridge')
 text=run('cpp_rtl_replay',['sim/out/test_bridge.exe','--replay'])
 assert 'PASS' in text

def phone():
 node=Path('D:/nodejs/node.exe')
 run('js_app',[node,'--check',ROOT/'shouji/app.js'])
 assert 'PASS' in run('phone',[node,ROOT/'sim/test_phone.js'])

def device_api():
 assert 'PASS' in run('device_api',[Path('D:/nodejs/node.exe'),ROOT/'sim/test_device_api.js'])

def keymap_phone():
 node=Path('D:/nodejs/node.exe')
 assert 'PASS' in run('keymap_phone',[node,ROOT/'sim/test_keymap.js'])

def midi_import():
 node=Path('D:/nodejs/node.exe')
 run('js_score',[node,'--check',ROOT/'shouji/score.js'])
 assert 'PASS' in run('score_parser',[node,ROOT/'sim/test_score.js'])

def packaging():
 header=(ROOT/'esp32/ESP32_FPGA_Music_Controller/web_page.h').read_text(encoding='utf-8')
 for name in ['index.html','app.js','score.js','keymap.html','keymap.js','ui.css','ui-text.js','navigation.js','device-api.js']:assert (ROOT/'shouji'/name).read_text(encoding='utf-8') in header
 assert not (ROOT/'shouji/android').exists()
 text=(ROOT/'yinjiao/wifi_pins.cst').read_text()
 assert '\"wifi_uart_rx\" B19' in text and '\"wifi_uart_tx\" A17' in text
 for p in [BASE/'src/yinyue_fashengqi.cst',BASE/'boards/tang_mega_138k_pro/src/yinyue_fashengqi.cst']:
  assert ' B19' not in p.read_text() and ' A17' not in p.read_text()

def firmware_build():
 report=json.loads((OUT/'esp32_compile.json').read_text(encoding='utf-8'))
 assert report['status']=='PASS'
 for name,h in report['sources'].items():
  assert hashlib.sha256((ROOT/'esp32/ESP32_FPGA_Music_Controller'/name).read_bytes()).hexdigest()==h,name
 assert (OUT/'esp32_build/ESP32_FPGA_Music_Controller.ino.bin').exists()

def outside():
 b=json.loads((ROOT/'sim/outside_before_20261019.json').read_text())
 changed=[p for p,h in b.items() if not (BASE/p).exists() or hashlib.sha256((BASE/p).read_bytes()).hexdigest()!=h]
 if changed:raise RuntimeError(changed)
prepare()
check('python_protocol',python_protocol)
for top in ['tb_uart','tb_packet','tb_control','tb_core','tb_steps','tb_existing_controls','tb_volume','tb_player']:check(top,lambda top=top:sim(top))
check('firmware_rtl_closed_loop',bridge);check('phone_state_feedback',phone);check('midi_json_import',midi_import);check('keymap_phone',keymap_phone);check('async_device_api',device_api);check('strict_lint',lint);check('structure_check',structure)
check('packaging_pins',packaging);check('esp32_real_build',firmware_build);check('outside_scope_hashes',outside)
report={'status':'FAIL' if errors else 'PASS','results':results,'errors':errors,
 'scope':'ESP32 shared firmware -> FPGA UART RTL -> actual gain/BPM, score revision and play/stop readback; PCM, player, MIDI/JSON and phone queue tests. 32-key atomic mapping/version/readback and independent Wi-Fi/UART UI. No live board/main piano integration.',
 'not_run':['Gowin build/timing','Physical ESP32-FPGA wiring, flash and live audio'],
 'protected_files':len(json.loads((ROOT/'sim/outside_before_20261019.json').read_text())),
 'source_sha256':{p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in SOURCES},
 'client_sha256':{p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in list((ROOT/'esp32/ESP32_FPGA_Music_Controller').iterdir())+list((ROOT/'shouji').glob('*.js')) if p.is_file()}}
(OUT/'report.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
(OUT/'report.md').write_text('# 独立验证报告\n\n'+'\n'.join(f'- {k}: {v}' for k,v in results.items())+'\n\n'+report['scope']+'\n\n未执行：Gowin构建、实物ESP32-FPGA接线/烧录/音频验证。ESP32实际编译记录另见esp32_compile.log。\n',encoding='utf-8')
print('ALL CHECKS PASS' if not errors else 'FAILED',flush=True)
sys.exit(bool(errors))
