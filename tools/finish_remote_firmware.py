from pathlib import Path
r=Path(__file__).resolve().parents[1]/'firmware/remote_music'
p=r/'esp32/ESP32_FPGA_Music_Controller/ESP32_FPGA_Music_Controller.ino';s=p.read_text(encoding='utf-8-sig')
s=s.replace('void setup() {','#include "WavService.h"\n\nvoid setup() {',1)
s=s.replace('  server.onNotFound(', '  WavService::setup();\n  server.on("/wav.js",HTTP_GET,[]{server.send_P(200,"application/javascript; charset=utf-8",WAV_JS);});\n  server.onNotFound(',1)
s=s.replace('if(kind=="mode"&&v<=2)','if(kind=="mode"&&v==0)')
p.write_text(s,encoding='utf-8')
p=r/'shouji/index.html';s=p.read_text(encoding='utf-8-sig')
a=s.index('<section><h2>演奏模式');b=s.index('<section class="sound-control">',a)
s=s[:a]+'<section hidden><div id="modes"></div><small id="modeSelection"></small></section>\n'+s[b:]
a=s.index('<section class="practice-card">');b=s.index('<section><div class="section-head"><h2>曲谱播放',a)
s=s[:a]+'''<section><div class="section-head"><h2>WAV音乐播放</h2><span class="badge">FPGA解码</span></div>
<p>支持PCM WAV：16/24位，单/双声道，44.1/48kHz。播放期间请保持本页与Wi-Fi连接。WAV保留录音原声，音色选择用于琴键和MIDI/JSON。</p>
<input id="wavFile" type="file" accept=".wav,audio/wav"><div class="score-actions"><button id="wavPlay" class="primary">传输并播放</button><button id="wavStop">停止WAV</button></div><p id="wavStatus" role="status">尚未选择WAV文件</p></section>
<section class="practice-card" hidden><div id="practiceModes"></div><small id="practiceStatus"></small></section>'''+s[b:]
s=s.replace('<script src="app.js"></script>','<script src="app.js"></script><script src="wav.js"></script>')
p.write_text(s,encoding='utf-8')
p=r/'esp32/build_web.py';s=p.read_text(encoding='utf-8-sig').replace("('PAGE','index.html')","('WAV_JS','wav.js'),('PAGE','index.html')");p.write_text(s,encoding='utf-8')
p=r/'shouji/keymap.js';s=p.read_text(encoding='utf-8-sig').replace('60+(i%16)+12*Math.floor(i/16)','60+i')
p.write_text(s,encoding='utf-8')
p=r/'esp32/compile.py';s=p.read_text(encoding='utf-8-sig').replace("out=r/'sim/out';out.mkdir(exist_ok=True)","out=r.parents[1]/'tests/remote_music_20261019/esp32';out.mkdir(parents=True,exist_ok=True)")
p.write_text(s,encoding='utf-8')
print('Firmware endpoints, raw WAV streaming page and actual 60..91 default map updated.')
