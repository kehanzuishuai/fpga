#pragma once
#include <Arduino.h>
const char PAGE[] PROGMEM=R"MUSICWEB(<!doctype html><html lang="zh-CN"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>电子乐器控制</title><link rel="stylesheet" href="/ui.css"></head>
<body><header class="page-header"><div><div class="eyebrow">弦动智音</div><h1 id="pageTitle">电子乐器控制</h1></div></header>
<section class="status-card"><div class="section-head"><h2>设备连接</h2><button class="quiet" id="refresh">刷新状态</button></div><p class="status-row" data-state="waiting" id="wifiLink" role="status">Wi-Fi 连接中…</p><p class="status-row" data-state="waiting" id="uartLink" role="status">FPGA 连接中…</p><p id="message" role="status" aria-live="polite" hidden></p></section>
<main id="controlView" class="page-view"><section><div class="section-head"><h2>选择音色</h2></div><div id="timbres" class="timbres" aria-label="音色"></div><small id="timbreSelection" class="selection-caption" role="status" hidden></small></section>
<section><h2>演奏模式</h2><div id="modes" class="segments" aria-label="演奏模式"></div><small id="modeSelection" class="selection-caption" role="status" hidden></small></section>
<section class="sound-control"><h2>声音控制</h2>
<div class="sound-row"><div class="sound-icon"><svg viewBox="0 0 24 24" aria-hidden="true"><path d="M4 9h4l5-4v14l-5-4H4z M16 8c3 2 3 6 0 8 M19 5c5 4 5 10 0 14"/></svg></div><div class="sound-body"><div class="sound-head"><label for="volume">音量</label><output id="volumeValue">100%</output><button class="reset-icon" id="volumeDefault" aria-label="恢复默认音量" title="恢复默认音量100%">↺</button></div><input id="volume" type="range" min="0" max="100" value="100" step="1"></div></div>
<div class="sound-row"><div class="sound-icon"><svg viewBox="0 0 24 24" aria-hidden="true"><path d="M4 18a9 9 0 1 1 16 0 M12 13l5-6 M6 8l1 1 M12 4v2 M18 8l-1 1"/></svg></div><div class="sound-body"><div class="sound-head"><label for="tempo">播放速度</label><output id="tempoValue">120 BPM</output><button class="reset-icon" id="tempoDefault" aria-label="恢复默认速度" title="恢复默认速度120 BPM">↺</button></div><div class="tempo-track"><button class="step-button" id="tempoMinus" aria-label="速度减1 BPM">−</button><input id="tempo" type="range" min="30" max="240" value="120" step="1"><button class="step-button" id="tempoPlus" aria-label="速度加1 BPM">＋</button></div></div></div></section>
</main><main id="scoresView" class="page-view" hidden><section class="practice-card"><h2>演奏方式</h2><div id="practiceModes" class="segments" aria-label="曲谱演奏方式"><button data-practice="0" aria-pressed="true">自由演奏</button><button data-practice="1" aria-pressed="false">自动演奏</button><button data-practice="2" aria-pressed="false">指导模式</button></div><small id="practiceStatus" class="selection-caption" role="status">自由演奏 · 待设备接入</small></section><section><div class="section-head"><h2>曲谱播放</h2><span class="badge">MIDI / JSON</span></div><p id="scoreInfo">尚未选择曲谱</p><details class="score-import" id="importPanel"><summary>导入或在线下载曲谱</summary><label for="scoreUrl">曲谱链接</label><input id="scoreUrl" type="url" placeholder="https://…/music.mid"><button class="secondary" id="download">在线下载</button><label for="scoreFile">从手机导入（不超过64KB）</label><input id="scoreFile" type="file" accept=".mid,.midi,.json,audio/midi,application/json"></details>
<label for="track">音轨</label><select id="track"></select><label for="part">分段</label><select id="part"></select><div class="score-actions"><button class="primary" id="upload">传输</button><button id="play">▷ 播放</button><button class="secondary" id="stop">□ 停止</button></div><p id="scoreActual"></p></section>
</main><main id="settingsView" class="page-view" hidden><details class="card"><summary>联网设置</summary><p class="hint">下载曲谱前，请连接可上网的 Wi-Fi。</p><label for="ssid">上网Wi-Fi名称</label><input id="ssid" autocomplete="off"><label for="password">Wi-Fi密码</label><input id="password" type="password" autocomplete="off"><div class="button-row"><button id="connect">连接上网Wi-Fi</button><button class="secondary" id="network">检查联网状态</button></div><p id="networkState" class="hint">未检查</p></details>
<details class="debug-panel card"><summary>调试信息</summary><p id="actual">尚未读取设备状态</p><p id="volumeActual"></p><p id="tempoActual"></p><pre id="debugInfo">暂无记录</pre></details></main><nav class="bottom-nav" aria-label="主导航"><a href="/" data-page="control"><svg viewBox="0 0 24 24" aria-hidden="true"><path d="M3 11 12 3l9 8 M5 10v11h5v-6h4v6h5V10"/></svg><span>控制</span></a><a href="/keymap" data-page="keymap"><svg viewBox="0 0 24 24" aria-hidden="true"><path d="M3 5h18v15H3z M7 5v9 M11 5v9 M15 5v9 M19 5v9 M7 14v6 M11 14v6 M15 14v6"/></svg><span>键位</span></a><a href="/#scores" data-page="scores"><svg viewBox="0 0 24 24" aria-hidden="true"><path d="M7 4h13v15 M7 4v12 M7 9h13 M7 16c-6-2-7 6-2 5 2 0 2-2 2-5 M20 16c-6-2-7 6-2 5 2 0 2-2 2-5"/></svg><span>曲谱</span></a><a href="/#settings" data-page="settings"><svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 8a4 4 0 1 0 0 8 4 4 0 0 0 0-8 M10 3h4l1 3 3 1 3 3v4l-3 1-1 3-3 3h-4l-1-3-3-1-3-3v-4l3-1 1-3z"/></svg><span>设置</span></a></nav><script src="device-api.js"></script><script src="navigation.js"></script><script src="ui-text.js"></script><script src="score.js"></script><script src="app.js"></script></body></html>
)MUSICWEB";
const char APP_JS[] PROGMEM=R"MUSICWEB('use strict';
const deviceRequest=typeof module!=='undefined'?require('./device-api.js').deviceJSON:deviceJSON;
const TIMBRES=['钢琴','管风琴','长笛','吉他','钟琴'];
const MODES=['琴键','特雷门琴','合奏'];
const PRACTICE_MODES=['自由演奏','自动演奏','指导模式'];
function createPracticeController(request,onChange){
 let selected=0,generation=0;
 const show=status=>onChange({selected,status});
 return {select(value){
  if(!Number.isInteger(value)||value<0||value>2)return Promise.resolve(false);
  selected=value;const token=++generation;show('应用中…');
  return Promise.resolve().then(()=>request(value)).then(({response,data})=>{
   if(token!==generation)return false;
   const applied=response.ok&&data.ok===true&&data.supported===true&&data.mode===value;
   show(applied?'已应用':data.supported===false?'待设备接入':'未应用');return applied;
  }).catch(()=>{if(token===generation)show('未应用');return false;});
 },selected:()=>selected};
}
function createSelection(){
 const groups={timbre:{desired:null,actual:null,applied:false,pending:false},mode:{desired:null,actual:null,applied:false,pending:false}};
 return {groups,choose(kind,value){const g=groups[kind];g.desired=value;g.pending=true;g.applied=false;},
 result(kind,value,status){const g=groups[kind];if(!g||g.desired!==value)return;g.pending=status==='pending';if(status==='error')g.applied=false;},
 actual(data){for(const kind of ['timbre','mode']){const g=groups[kind],valid=data.stateValid===true&&Number.isInteger(data[kind]);g.actual=valid?data[kind]:null;
  if(g.desired===null&&valid)g.desired=g.actual;
  g.applied=valid&&!data.switching&&!data.fault&&g.desired===g.actual;
 }} };
}
function createController(fetchFn,view){
  let busy=false,activeBackground=false,delay=1500,health=null;const queue=[],rendered=new Map();
  function show(method,value,background){
    const signature=JSON.stringify(value),previous=rendered.get(method);rendered.set(method,signature);
    if(background&&previous===signature)return;
    if(method==='links'){if(view.links)view.links(...value);}else if(view[method])view[method](value);
  }
  async function pump(){
    if(busy||!queue.length)return;
    const job=queue.shift();busy=true;activeBackground=job.background;
    if(!job.background)view.busy(true);
    try{job.resolve(await job.fn());}catch(e){view.message(e.message||'操作失败');job.resolve(false);}
    finally{busy=false;activeBackground=false;if(!job.background)view.busy(false);pump();}
  }
  function enqueue(fn,key,background=false){
    return new Promise(resolve=>{
      if(key){const i=queue.findIndex(j=>j.key===key);if(i>=0){queue[i].resolve(false);queue.splice(i,1);}}
      queue.push({fn,key,resolve,background});pump();
    });
  }
  async function run(kind,value,events,background=false){
    const previousHealth=health;
    let httpReached=false,outcome=false;
    if(view.operation&&kind)view.operation(kind,value,'pending');
    if(!background)show('links',[null,'waiting'],false);
    const abort=new AbortController(),timeout=setTimeout(()=>abort.abort(),15000);
    try{
      if(!background)show('message',kind?'正在等待 FPGA 确认…':'正在读取状态…',false);
      let url=kind?'/api/control':'/api/status';
      let options=kind?{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:new URLSearchParams({kind,value:String(value)}).toString()}:{cache:'no-store'};
      if(events){url='/api/score';options={method:'POST',headers:{'Content-Type':'text/plain'},body:events.map(e=>e.join(',')).join('\n')+'\n'};}
      const result=await deviceRequest(fetchFn,url,{...options,signal:abort.signal});httpReached=true;
      const res=result.response,data=result.data;
      show('links',[true,data.uartConnected===true?'connected':'error'],background);
      const validState=data.stateValid===true && typeof data.switching==='boolean' && typeof data.fault==='boolean' && Number.isInteger(data.mode)&&data.mode>=0&&data.mode<3&&Number.isInteger(data.timbre)&&data.timbre>=0&&data.timbre<5;
      health=data.uartConnected!==true?'uart_error':!validState?'invalid':data.fault?'fault':'ready';
      delay=health==='ready'?1500:10000;
      show('state',validState?`当前音色：${TIMBRES[data.timbre]}　模式：${MODES[data.mode]}${data.switching?'（切换中）':''}${data.fault?'（故障）':''}`:'尚未确认 FPGA 状态',background);
      const display={stateValid:validState,switching:data.switching,fault:data.fault,mode:data.mode,timbre:data.timbre,settingsValid:data.settingsValid,volume:data.volume,tempo:data.tempo,scoreValid:data.scoreValid,scoreCount:data.scoreCount,playing:data.playing};
      show('data',display,background);
      let confirmed=validState&&!data.fault;
      if(kind==='mode'||kind==='timbre')confirmed=confirmed&&!data.switching&&data[kind]===value;
      if(kind==='volume'||kind==='tempo')confirmed=confirmed&&data.settingsValid===true&&data[kind]===value;
      if(kind==='play')confirmed=confirmed&&data.scoreValid===true&&data.playing===Boolean(value);
      if(events)confirmed=confirmed&&data.scoreValid===true&&data.scoreCount===events.length;
      if(!res.ok||!data.ok||!confirmed){if(!background||health!==previousHealth)show('message',data.message||'FPGA 尚未确认',background);return false;}
      outcome=true;if(!background||health!==previousHealth)show('message',events?'曲谱已传入 FPGA':kind==='volume'?'音量已生效':kind==='tempo'?'速度已生效':kind==='play'?(value?'正在播放':'已停止'):kind?'切换完成':data.switching?'正在切换，请稍候':'FPGA 已连接',background);return true;
    }catch(e){health=httpReached?'invalid':'offline';delay=10000;show('data',{stateValid:false},background);show('links',[httpReached,'error'],background);show('state','连接中断，当前状态未知',background);if(!background||health!==previousHealth)show('message',httpReached?'ESP32响应异常，请刷新重试':'无法访问 ESP32，请检查 Wi-Fi 后刷新',background);return false;}finally{clearTimeout(timeout);if(view.operation&&kind)view.operation(kind,value,outcome?'success':'error');}
  }
  return {
    refresh:({background=false}={})=>busy||queue.length?Promise.resolve(false):enqueue(()=>run(undefined,undefined,undefined,background),undefined,background),
    pollDelay:()=>delay,
    set:(kind,value)=>enqueue(()=>run(kind,value),['volume','tempo','timbre','mode'].includes(kind)?kind:null),
    upload:events=>enqueue(()=>run('score',0,events)),
    task:fn=>enqueue(fn),isBusy:()=>busy||queue.length>0,
    pending:kind=>queue.some(j=>j.key===kind)
  };
}
if(typeof module!=='undefined')module.exports={createController,createSelection,createPracticeController,PRACTICE_MODES,TIMBRES,MODES};
if(typeof document!=='undefined'){
  const byId=id=>document.getElementById(id),buttons=[],selection=createSelection();let score=null,parts=[],dragging=new Set();
  const controller=createController(window.fetch.bind(window),{
    links:showConnections,
    operation:(kind,value,status)=>{selection.result(kind,value,status);renderSelection();const target=kind==='timbre'||kind==='mode'?document.querySelector(`[data-kind="${kind}"][data-value="${value}"]`):byId(kind==='score'?'upload':kind==='play'?(value?'play':'stop'):kind+'Value');if(!target)return;if(status==='pending'){target.dataset.pending='true';delete target.dataset.result;}else{delete target.dataset.pending;target.dataset.result=status;setTimeout(()=>delete target.dataset.result,900);}},
    busy:()=>{},message:showNotice,state:s=>byId('actual').textContent=s,
    data:d=>{
      selection.actual(d);renderSelection();
      for(const kind of ['volume','tempo']){
        const valid=d.settingsValid===true&&Number.isInteger(d[kind]);
        byId(kind+'Actual').textContent=valid?`当前${kind==='volume'?'音量':'速度'}：${d[kind]}${kind==='volume'?'%':' BPM'}`:'当前值尚未确认';
        if(valid&&!dragging.has(kind)&&document.activeElement!==byId(kind)&&!controller.pending(kind)){byId(kind).value=d[kind];byId(kind+'Value').textContent=d[kind]+(kind==='volume'?'%':' BPM');paintRange(byId(kind));}
      }
      byId('scoreActual').textContent=d.scoreValid?(d.playing?'播放中':d.scoreCount?`已传输 · ${d.scoreCount}项`:'暂无曲谱'):'';
    }
  });
  function renderSelection(){
    for(const kind of ['timbre','mode']){const g=selection.groups[kind];document.querySelectorAll(`[data-kind="${kind}"]`).forEach(b=>{b.setAttribute('aria-pressed',Number(b.dataset.value)===g.desired);b.dataset.applied=g.applied&&Number(b.dataset.value)===g.desired;});
      const caption=byId(kind+'Selection');caption.hidden=g.desired===null;caption.textContent=g.desired===null?'':(kind==='timbre'?TIMBRES:MODES)[g.desired]+' · '+(g.applied?'已应用':g.pending?'应用中…':'未应用');
    }
  }
  function selectInstrument(kind,value){selection.choose(kind,value);renderSelection();return controller.set(kind,value);}
  function paintRange(input){input.style.setProperty('--range-fill',((Number(input.value)-Number(input.min))/(Number(input.max)-Number(input.min))*100)+'%');}
  function bind(id,fn){const b=byId(id);b.onclick=fn;buttons.push(b);}
  for(const [id,kind,names] of [['timbres','timbre',TIMBRES],['modes','mode',MODES]]){
    names.forEach((name,value)=>{const b=document.createElement('button');b.dataset.kind=kind;b.dataset.value=value;b.setAttribute('aria-pressed','false');
      if(kind==='timbre'){
        b.className='timbre-button';const paths=['M4 5h16v14H4z M8 5v8 M12 5v8 M16 5v8 M8 13v6 M12 13v6 M16 13v6','M4 19V9h3v10 M10 19V4h4v15 M17 19V7h3v12','M5 19 19 5 M7 17l-2-2 M10 14l-2-2 M13 11l-2-2 M16 8l-2-2','M14 9 20 3 M17 3l4 4 M12 10c-5-4-11 4-6 8s12-2 8-6 M9 14h.01','M5 17c3-3 0-9 7-11 7 2 4 8 7 11H5 M9 20h6 M12 3v3'];
        const svg=document.createElementNS('http://www.w3.org/2000/svg','svg');svg.setAttribute('viewBox','0 0 24 24');svg.setAttribute('aria-hidden','true');const path=document.createElementNS(svg.namespaceURI,'path');path.setAttribute('d',paths[value]);svg.append(path);b.append(svg);
      }
      if(kind==='mode'){const svg=document.createElementNS('http://www.w3.org/2000/svg','svg');svg.setAttribute('viewBox','0 0 24 24');svg.setAttribute('aria-hidden','true');const path=document.createElementNS(svg.namespaceURI,'path');path.setAttribute('d',['M4 5h16v14H4z M8 5v8 M12 5v8 M16 5v8 M8 13v6 M12 13v6 M16 13v6','M4 10v4 M8 6v12 M12 3v18 M16 6v12 M20 10v4','M8 12a3 3 0 1 0 0-6 3 3 0 0 0 0 6 M16 12a3 3 0 1 0 0-6 3 3 0 0 0 0 6 M2 21v-3c0-5 12-5 12 0v3 M13 14c5-2 9 0 9 4v3'][value]);svg.append(path);b.append(svg);}
      const label=document.createElement('span');label.textContent=name;b.append(label);b.onclick=()=>selectInstrument(kind,value);byId(id).appendChild(b);buttons.push(b);});
  }
  const practice=createPracticeController(value=>controller.task(()=>deviceRequest(window.fetch.bind(window),'/api/performance',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:new URLSearchParams({mode:String(value)}).toString()})),({selected,status})=>{
    document.querySelectorAll('[data-practice]').forEach(b=>b.setAttribute('aria-pressed',Number(b.dataset.practice)===selected));
    byId('practiceStatus').textContent=PRACTICE_MODES[selected]+' · '+status;
  });
  document.querySelectorAll('[data-practice]').forEach(b=>b.onclick=()=>practice.select(Number(b.dataset.practice)));
  bind('refresh',controller.refresh);
  const sliderTimers={};
  function setSlider(kind,value,immediate=false){
    const input=byId(kind);input.value=Math.max(Number(input.min),Math.min(Number(input.max),value));dragging.add(kind);paintRange(input);byId(kind+'Value').textContent=input.value+(kind==='volume'?'%':' BPM');clearTimeout(sliderTimers[kind]);
    const send=()=>controller.set(kind,Number(input.value)).finally(()=>dragging.delete(kind));
    if(immediate)return send();sliderTimers[kind]=setTimeout(send,160);
  }
  for(const kind of ['volume','tempo']){
    const input=byId(kind);paintRange(input);input.addEventListener('input',()=>setSlider(kind,Number(input.value)));
    input.addEventListener('change',()=>setSlider(kind,Number(input.value),true));input.addEventListener('blur',()=>dragging.delete(kind));
    bind(kind+'Default',()=>setSlider(kind,kind==='volume'?100:120,true));
  }
  bind('tempoMinus',()=>setSlider('tempo',Number(byId('tempo').value)-1));bind('tempoPlus',()=>setSlider('tempo',Number(byId('tempo').value)+1));
  function chooseTrack(){
    try{parts=splitScore(score,Number(byId('track').value));byId('part').replaceChildren();parts.forEach((e,i)=>byId('part').add(new Option(`第${i+1}段 · ${e.length}项`,i)));byId('scoreInfo').textContent=`${score.name} · ${score.bpm} BPM · ${parts.length}段`;}
    catch(e){parts=[];byId('part').replaceChildren();byId('scoreInfo').textContent=e.message;}
  }
  function load(bytes){score=null;parts=[];byId('track').replaceChildren();byId('part').replaceChildren();score=parseScoreFile(bytes);byId('track').replaceChildren();score.groups.forEach((g,i)=>byId('track').add(new Option(g.name,i)));chooseTrack();}
  byId('track').onchange=chooseTrack;
  byId('scoreFile').onchange=async()=>{try{const f=byId('scoreFile').files[0];if(!f)return;if(f.size>65536)throw Error('文件超过64KB');load(await f.arrayBuffer());}catch(e){byId('scoreInfo').textContent=e.message;}};
  bind('download',()=>controller.task(async()=>{
    showNotice('正在下载…');const r=await fetch('/api/download',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:new URLSearchParams({url:byId('scoreUrl').value.trim()})});
    if(!r.ok)throw Error((await r.json()).message||'下载失败');load(await r.arrayBuffer());showNotice('已下载');return true;
  }));
  bind('upload',async()=>{const events=parts[Number(byId('part').value)];if(!events){showNotice('请先选择曲谱');return;}
    const bpm=score.bpm;if(await controller.upload(events))await controller.set('tempo',bpm);
  });
  bind('play',()=>controller.set('play',1));bind('stop',()=>controller.set('play',0));
  bind('connect',()=>controller.task(async()=>{const r=await fetch('/api/network',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:new URLSearchParams({ssid:byId('ssid').value,password:byId('password').value})});const d=await r.json();byId('password').value='';byId('networkState').textContent=d.message;return r.ok;}));
  bind('network',()=>controller.task(async()=>{const d=await (await fetch('/api/network',{cache:'no-store'})).json();byId('networkState').textContent=d.connected?(d.clockReady?'已联网，可以在线下载':'Wi-Fi已连接，等待联网校时'):'尚未连接上网Wi-Fi';return true;}));
  async function poll(){
    if(!document.hidden&&!controller.isBusy())await controller.refresh({background:true});
    setTimeout(poll,controller.pollDelay());
  }
  controller.refresh().finally(()=>setTimeout(poll,controller.pollDelay()));
}
)MUSICWEB";
const char SCORE_JS[] PROGMEM=R"MUSICWEB('use strict';
const MAX_BYTES=65536;
function checkedEvents(events){
  if(!Array.isArray(events)||!events.length||events.length>4096)throw Error('曲谱事件数量应为1～4096');
  return events.map(e=>{
    if(!e||typeof e!=='object')throw Error('曲谱事件格式不正确');
    const a=Array.isArray(e)?e:[e.note,e.velocity,e.duration_ms];
    if(a.length!==3||!a.every(Number.isInteger)||a[0]<0||a[0]>127||a[1]<0||a[1]>127||a[2]<1||a[2]>65535)throw Error('音符、力度或时长不正确');
    if(a[1]&&(a[0]<36||a[0]>96))throw Error('当前音源支持MIDI音符36～96，请先移调');
    return [...a];
  });
}
function parseMidi(bytes){
  let p=0;
  const need=n=>{if(n<0||p+n>bytes.length)throw Error('MIDI文件不完整');};
  const u8=()=>{need(1);return bytes[p++];};
  const u16=()=>u8()*256+u8();
  const u32=()=>u8()*16777216+u8()*65536+u8()*256+u8();
  const tag=()=>String.fromCharCode(u8(),u8(),u8(),u8());
  const vlq=()=>{let v=0;for(let i=0;i<4;i++){const b=u8();v=v*128+(b&127);if(!(b&128))return v;}throw Error('MIDI时间字段过长');};
  if(tag()!=='MThd')throw Error('不是标准MIDI文件');
  const h=u32();if(h<6)throw Error('MIDI文件头不正确');need(h);
  const format=u16(),tracks=u16(),ppqn=u16();p+=h-6;
  if(format>1||!tracks||tracks>64||(ppqn&32768)||!ppqn)throw Error('仅支持PPQN计时的MIDI格式0/1，最多64轨');
  const groups=[];let bpm=120,tempoFound=false;
  for(let t=0;t<tracks;t++){
    if(tag()!=='MTrk')throw Error('缺少MIDI音轨');
    const size=u32();need(size);const end=p+size;let tick=0,running=0,name=`音轨${t+1}`,events=0;
    const channels=new Map();
    const channel=c=>{if(!channels.has(c))channels.set(c,{notes:[],held:new Map()});return channels.get(c);};
    while(p<end){
      tick+=vlq();if(++events>16384||tick>1e9)throw Error('MIDI音轨过长');
      let status=u8();if(status<128){if(!running)throw Error('MIDI运行状态无效');p--;status=running;}
      if(status===255){
        const type=u8(),n=vlq();need(n);if(p+n>end)throw Error('MIDI事件越过音轨');
        if(type===3)name=new TextDecoder().decode(bytes.slice(p,p+n)).trim().slice(0,50)||name;
        if(type===81&&n===3&&!tempoFound){const us=bytes[p]*65536+bytes[p+1]*256+bytes[p+2];if(!us)throw Error('MIDI速度无效');bpm=Math.round(60000000/us);tempoFound=true;}
        p+=n;if(type===47){if(n!==0||p!==end)throw Error('MIDI结束标记不正确');break;}continue;
      }
      if(status===240||status===247){running=0;const n=vlq();need(n);p+=n;if(p>end)throw Error('MIDI系统事件越界');continue;}
      if(status>=240)throw Error('不支持该MIDI系统事件');
      running=status;const type=status>>4,c=status&15,a=u8(),b=(type===12||type===13)?0:u8();
      if(a>127||b>127||p>end)throw Error('MIDI数据无效');
      if(type===9&&b){
        const group=channel(c);if(group.held.has(a))throw Error('同一个音符重复按下且未松开');group.held.set(a,{start:tick,velocity:b});
      }else if(type===8||(type===9&&!b)){
        const group=channel(c),on=group.held.get(a);
        if(on){group.notes.push({start:on.start,end:tick,note:a,velocity:on.velocity});group.held.delete(a);}
      }
    }
    if(p!==end)throw Error('MIDI音轨长度不匹配');
    for(const [c,g] of channels){
      if(g.held.size)throw Error('MIDI存在没有松开的音符');
      if(g.notes.length)groups.push({name:`${name} · 通道${c+1}${c===9?'（打击乐）':''}`,notes:g.notes,ppqn});
    }
  }
  if(!groups.length)throw Error('文件里没有可用音符');
  return {name:'MIDI曲谱',bpm:bpm>=30&&bpm<=240?bpm:120,groups,notice:'按所选音轨和统一BPM播放；不导入踏板、音色指令及中途变速。'};
}
function melodyEvents(group){
  const notes=[...group.notes].sort((a,b)=>a.start-b.start||a.end-b.end);let cursor=0;const out=[];
  for(const n of notes){
    if(n.start<cursor)throw Error('该音轨含和弦或重叠音符，请选择单旋律音轨');
    const start=Math.round(n.start*500/group.ppqn),end=Math.round(n.end*500/group.ppqn),before=Math.round(cursor*500/group.ppqn);
    if(start>before)out.push([0,0,start-before]);
    out.push([n.note,n.velocity,Math.max(1,end-start)]);cursor=n.end;
  }
  return checkedEvents(out);
}
function parseScoreFile(data){
  const b=data instanceof Uint8Array?data:new Uint8Array(data);
  if(!b.length||b.length>MAX_BYTES)throw Error('曲谱文件应小于64KB');
  if(String.fromCharCode(...b.slice(0,4))==='MThd')return parseMidi(b);
  let j;try{j=JSON.parse(new TextDecoder().decode(b));}catch(e){throw Error('请选择MIDI文件或音符JSON文件，不支持图片/PDF');}
  if(!Number.isInteger(j.bpm)||j.bpm<30||j.bpm>240)throw Error('曲谱BPM应为30～240');
  return {name:String(j.name||'音符曲谱').slice(0,80),bpm:j.bpm,groups:[{name:'旋律',events:checkedEvents(j.events)}],notice:'时长以120 BPM为基准，播放时随速度滑条变化。'};
}
function splitScore(score,index=0){
  const g=score.groups[index];if(!g)throw Error('请选择音轨');
  const events=g.events||melodyEvents(g),parts=[];
  for(let i=0;i<events.length;i+=32)parts.push(events.slice(i,i+32));
  return parts;
}
function scoreText(events){return checkedEvents(events).map(e=>e.join(',')).join('\n')+'\n';}
if(typeof module!=='undefined')module.exports={parseScoreFile,splitScore,scoreText,checkedEvents};
)MUSICWEB";
const char KEYMAP_PAGE[] PROGMEM=R"MUSICWEB(<!doctype html><html lang="zh-CN"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>键位自定义</title><link rel="stylesheet" href="/ui.css"></head>
<body class="keymap-page"><header class="page-header"><div><div class="eyebrow">弦动智音</div><h1>键位自定义</h1></div></header>
<section class="status-card compact-status"><div class="connection-line"><p class="status-row" data-state="waiting" id="wifiLink" role="status">Wi-Fi 连接中…</p><p class="status-row" data-state="waiting" id="uartLink" role="status">FPGA 连接中…</p><button class="quiet" id="read">重新读取</button></div><p id="message" role="status" aria-live="polite" hidden></p></section>
<div id="boards"></div>
<section class="editor-card" id="editor"><div class="section-head"><h2>编辑琴键</h2><span id="selectedKey">第一块 · K1</span></div><div class="editor-row"><div><label for="note">目标音符</label><select id="note"></select></div><button id="edit">保存</button></div></section>
<details class="card"><summary>音阶预设与默认映射</summary><div class="preset-fields"><div><label for="presetBoard">选择琴</label><select id="presetBoard"><option value="0">第一块琴</option><option value="1">第二块琴</option></select></div><div><label for="preset">键位预设</label><select id="preset"><option value="chromatic">半音阶（标准琴键）</option><option value="major">C大调自然音阶</option><option value="pentatonic">C宫五声音阶</option></select></div></div><label for="octave">起始八度 <output id="octaveValue">C4</output></label><input id="octave" type="range" min="2" max="6" value="4" step="1"><div class="button-row"><button id="presetApply">使用预设</button><button class="secondary" id="defaults">恢复默认映射</button></div><p class="hint">默认从C4、C5开始；断电后恢复默认。</p></details>
<details class="debug-panel"><summary>调试信息</summary><p id="revision">尚未读取配置</p><pre id="debugInfo">暂无记录</pre></details>
<footer class="apply-bar"><p id="draftState">本地配置</p><button class="primary" id="apply" disabled>应用</button></footer><nav class="bottom-nav" aria-label="主导航"><a href="/" data-page="control"><svg viewBox="0 0 24 24" aria-hidden="true"><path d="M3 11 12 3l9 8 M5 10v11h5v-6h4v6h5V10"/></svg><span>控制</span></a><a href="/keymap" data-page="keymap"><svg viewBox="0 0 24 24" aria-hidden="true"><path d="M3 5h18v15H3z M7 5v9 M11 5v9 M15 5v9 M19 5v9 M7 14v6 M11 14v6 M15 14v6"/></svg><span>键位</span></a><a href="/#scores" data-page="scores"><svg viewBox="0 0 24 24" aria-hidden="true"><path d="M7 4h13v15 M7 4v12 M7 9h13 M7 16c-6-2-7 6-2 5 2 0 2-2 2-5 M20 16c-6-2-7 6-2 5 2 0 2-2 2-5"/></svg><span>曲谱</span></a><a href="/#settings" data-page="settings"><svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 8a4 4 0 1 0 0 8 4 4 0 0 0 0-8 M10 3h4l1 3 3 1 3 3v4l-3 1-1 3-3 3h-4l-1-3-3-1-3-3v-4l3-1 1-3z"/></svg><span>设置</span></a></nav><script src="device-api.js"></script><script src="navigation.js"></script><script src="ui-text.js"></script><script src="keymap.js"></script></body></html>
)MUSICWEB";
const char KEYMAP_JS[] PROGMEM=R"MUSICWEB( 'use strict';
const deviceRequest=typeof module!=='undefined'?require('./device-api.js').deviceJSON:deviceJSON;
const SCALES={chromatic:[0,1,2,3,4,5,6,7,8,9,10,11],major:[0,2,4,5,7,9,11],pentatonic:[0,2,4,7,9]};
function noteName(n){return ['C','C♯','D','D♯','E','F','F♯','G','G♯','A','A♯','B'][n%12]+(Math.floor(n/12)-1);}
function defaultMap(){return Array.from({length:32},(_,i)=>60+(i%16)+12*Math.floor(i/16));}
function presetMap(kind,octave){const steps=SCALES[kind];if(!steps||!Number.isInteger(octave)||octave<2||octave>6)throw Error('请选择有效的音阶与八度');const notes=Array.from({length:16},(_,i)=>(octave+1)*12+steps[i%steps.length]+12*Math.floor(i/steps.length));validateMap([...notes,...notes]);return notes;}
function validateMap(notes){if(!Array.isArray(notes)||notes.length!==32||notes.some(n=>!Number.isInteger(n)||n<36||n>96))throw Error('完整32键必须在MIDI 36～96内，请降低起始八度');return notes;}
function createKeymapClient(fetchFn){
 return async function(method,notes){
  const abort=new AbortController(),timer=setTimeout(()=>abort.abort(),30000);let reached=false;
  try{const result=await deviceRequest(fetchFn,'/api/keymap',{method,cache:'no-store',signal:abort.signal,...(method==='POST'?{headers:{'Content-Type':'text/plain'},body:validateMap(notes).join('\n')+'\n'}:{})});reached=true;
   const response=result.response,data=result.data;if(!response.ok||!data.ok){const e=Error(data.message||'FPGA尚未确认');e.uart=data.uartConnected===true;throw e;}
   validateMap(data.notes);if(!Number.isInteger(data.revision)||data.revision<0||data.revision>65535)throw Error('FPGA返回版本无效');
   if(method==='POST'&&notes.some((n,i)=>n!==data.notes[i]))throw Error('映射回读不一致，应用结果尚未确认');return data;
  }catch(e){e.reached=reached;throw e;}finally{clearTimeout(timer);}
 };
}
// Logical K numbering remains in chromatic order; physical sensor channels are mapped in the main project.
const KEY_LAYOUT=[
 {kind:'white',slot:0},{kind:'black',boundary:1},{kind:'white',slot:1},{kind:'black',boundary:2},
 {kind:'white',slot:2},{kind:'white',slot:3},{kind:'black',boundary:4},{kind:'white',slot:4},
 {kind:'black',boundary:5},{kind:'white',slot:5},{kind:'black',boundary:6},{kind:'white',slot:6},
 {kind:'white',slot:7},{kind:'black',boundary:8},{kind:'white',slot:8},{kind:'extra'}
];
function changedIndices(notes,confirmed){return notes?notes.flatMap((n,i)=>!confirmed||confirmed[i]!==n?[i]:[]):[];}
function createKeymapDraft(){
 return {notes:defaultMap(),confirmed:null,generation:0,connected:false,
 change(fn){const next=[...this.notes];fn(next);validateMap(next);this.notes=next;this.generation++;},
 receive(data,generation){this.connected=true;this.confirmed=[...data.notes];if(this.generation===generation)this.notes=[...data.notes];},
 changes(){return changedIndices(this.notes,this.confirmed||defaultMap());},dirty(){return this.changes().length>0;}};
}
if(typeof module!=='undefined')module.exports={noteName,defaultMap,presetMap,validateMap,createKeymapClient,KEY_LAYOUT,changedIndices,createKeymapDraft};
if(typeof document!=='undefined'){
 const el=id=>document.getElementById(id),client=createKeymapClient(window.fetch.bind(window)),draft=createKeymapDraft();
 let selected=0,busy=false;const keys=[],chips=[],boardTitles=[];
 const names=['第一块','第二块'],kinds={white:'白键',black:'黑键',extra:'附加键'};
 const message=(s,tone='',shortText)=>{showNotice(s,shortText);el('message').dataset.tone=tone;};
 function choose(index){selected=index;el('presetBoard').value=Math.floor(selected/16);render();}
 function buildBoards(){
  for(let board=0;board<2;board++){
   const card=document.createElement('section');card.className='board-card';
   const head=document.createElement('div');head.className='board-head';const title=document.createElement('button');title.className='board-title';title.textContent='触摸钢琴 '+(board+1);title.onclick=()=>choose(board*16+selected%16);boardTitles.push(title);head.append(title);
   const scroll=document.createElement('div');scroll.className='keyboard-scroll';const piano=document.createElement('div');piano.className='keyboard';piano.setAttribute('role','group');piano.setAttribute('aria-label',names[board]+'琴的16个键位');scroll.append(piano);
   const picker=document.createElement('details'),summary=document.createElement('summary');picker.className='key-picker';summary.textContent='按编号选择';picker.append(summary);
   const row=document.createElement('div');row.className='key-chips';row.setAttribute('aria-label',names[board]+'琴辅助键位选择');
   KEY_LAYOUT.forEach((shape,i)=>{const index=board*16+i,b=document.createElement('button');b.type='button';b.className='piano-key '+shape.kind;b.dataset.index=index;
    if(shape.kind==='white')b.style.left=(shape.slot*100/9)+'%';if(shape.kind==='black')b.style.left=(shape.boundary*100/9-3.6)+'%';
    const id=document.createElement('span');id.className='key-id';id.textContent='K'+(i+1);const note=document.createElement('span');note.className='key-note';b.append(id);if(shape.kind!=='extra')b.append(note);b.onclick=()=>choose(index);keys[index]={button:b,note};piano.append(b);
    const chip=document.createElement('button');chip.className='key-chip';chip.textContent='K'+(i+1);chip.onclick=()=>choose(index);chips[index]=chip;row.append(chip);
   });
   picker.append(row);card.append(head,scroll,picker);el('boards').append(card);
  }
 }
 function render(){
  const notes=draft.notes,changed=draft.changes(),board=Math.floor(selected/16),local=selected%16;
  boardTitles.forEach((b,i)=>{b.setAttribute('aria-pressed',i===board);});
  keys.forEach(({button,note},index)=>{const k=index%16,kind=KEY_LAYOUT[k].kind,pressed=index===selected,label=names[Math.floor(index/16)]+' K'+(k+1)+' '+kinds[kind]+' '+noteName(notes[index]);button.setAttribute('aria-label',label);button.setAttribute('aria-pressed',pressed);button.classList.toggle('changed',changed.includes(index));note.textContent=noteName(notes[index]);button.title=label;chips[index].setAttribute('aria-label',label+'，辅助选择');chips[index].setAttribute('aria-pressed',pressed);chips[index].classList.toggle('changed',changed.includes(index));});
  el('selectedKey').textContent=names[board]+' · K'+(local+1);el('note').value=notes[selected];
  el('draftState').textContent=changed.length?'未应用修改：'+changed.length:draft.connected?'已应用':'本地配置';
  el('apply').disabled=busy||!draft.connected;el('apply').title=draft.connected?'应用到FPGA':'连接设备后应用';el('read').disabled=busy;
 }
 function localEdit(fn){try{draft.change(fn);render();message('已保存到本地配置','','已保存');}catch(e){message(e.message,'error');}}
 async function request(method){
  if(busy)return;if(method==='GET'&&draft.dirty()&&!window.confirm('放弃未应用的修改，重新读取？'))return;
  const generation=draft.generation,snapshot=[...draft.notes];busy=true;render();const target=el(method==='GET'?'read':'apply');target.dataset.pending='true';delete target.dataset.result;showConnections(null,'waiting');
  if(method==='POST')message('正在应用…');
  try{const data=await client(method,snapshot);draft.receive(data,generation);showConnections(true,'connected');el('revision').textContent='FPGA映射版本：'+data.revision;message(method==='GET'?'已读取当前映射':'全部32键已提交并回读确认','success',method==='GET'?'':'已应用');target.dataset.result='success';}
  catch(e){draft.connected=false;showConnections(e.reached,e.uart?'connected':'error');message(e.message+'；本地配置保留','error',method==='GET'?'':'应用失败');el('revision').textContent='当前配置尚未确认';target.dataset.result='error';}
  finally{busy=false;delete target.dataset.pending;render();setTimeout(()=>delete target.dataset.result,800);}
 }
 for(let n=36;n<=96;n++)el('note').add(new Option(noteName(n)+' (MIDI '+n+')',n));
 el('octave').oninput=()=>el('octaveValue').textContent='C'+el('octave').value;
 el('presetBoard').onchange=()=>{el('octave').value=Number(el('presetBoard').value)?5:4;el('octaveValue').textContent='C'+el('octave').value;};
 el('presetApply').onclick=()=>localEdit(notes=>{const part=presetMap(el('preset').value,Number(el('octave').value));notes.splice(Number(el('presetBoard').value)*16,16,...part);});
 el('edit').onclick=()=>localEdit(notes=>{notes[selected]=Number(el('note').value);});
 el('defaults').onclick=()=>localEdit(notes=>{notes.splice(0,32,...defaultMap());});el('apply').onclick=()=>request('POST');el('read').onclick=()=>request('GET');
 window.addEventListener('beforeunload',e=>{if(draft.dirty()){e.preventDefault();e.returnValue='';}});buildBoards();render();request('GET');
}
)MUSICWEB";
const char UI_CSS[] PROGMEM=R"MUSICWEB( :root{color-scheme:dark;--bg:#101722;--panel:#192536;--line:#2a3b50;--text:#eef4fc;--muted:#9bafc7;--accent:#8ac6ff;--blue:#316fa5;--good:#6edbb2;--warn:#f3c771;--bad:#ff9a9a;--radius:18px}*{box-sizing:border-box}body{margin:0 auto;padding:28px 18px 36px;max-width:600px;color:var(--text);background:radial-gradient(ellipse at top,#1b2b42 0,transparent 480px),var(--bg);font:15px/1.6 system-ui,"Microsoft YaHei",sans-serif}body.keymap-page{max-width:760px;padding-bottom:150px}h1{font-size:27px;line-height:1.3;letter-spacing:.02em;margin:6px 0 8px}h2{font-size:19px;line-height:1.4;margin:0 0 16px}h3{font-size:16px;margin:0}p{margin:10px 0}small,.muted{color:var(--muted);font-size:12px}a{color:var(--accent);text-decoration:none}a:hover{text-decoration:underline}.eyebrow{color:var(--accent);font-size:10px;font-weight:700;letter-spacing:.22em}.page-header{display:flex;justify-content:space-between;align-items:center;margin-bottom:22px;gap:14px}.nav-link{padding:8px 12px;border:1px solid var(--line);border-radius:12px;white-space:nowrap;font-size:13px}.back-link{display:inline-block;margin-bottom:12px}section,.card{padding:20px;background:linear-gradient(135deg,#1c2a3d,var(--panel));border:1px solid var(--line);border-radius:var(--radius);margin:16px 0;box-shadow:0 8px 24px #00000012}.section-head,.field-head,.board-head{display:flex;align-items:center;justify-content:space-between;gap:10px}.section-head{margin-bottom:14px}.section-head h2{margin:0}.status-card{padding:16px 18px}.status-row{display:flex;align-items:center;gap:9px;font-size:13px;margin:6px 0}.status-row:before{content:"";width:7px;height:7px;flex:0 0 7px;border-radius:50%;background:var(--muted)}.status-row[data-state=connected]:before{background:var(--good);box-shadow:0 0 8px #6edbb233}.status-row[data-state=waiting]:before{background:var(--warn);animation:breathe 1.2s ease-in-out infinite}.status-row[data-state=error]:before{background:var(--bad)}#actual{font-size:12px;color:var(--muted);margin-top:12px}#message{font-size:13px;color:#c0dcf4;min-height:22px;margin:8px 0 0}button,.button{font:inherit;min-height:44px;border:1px solid #406283;border-radius:11px;background:#244c70;color:var(--text);padding:10px 14px;cursor:pointer;touch-action:manipulation;position:relative;transition:transform .12s ease,background .16s ease,border-color .16s ease,box-shadow .16s ease}button:not(:disabled):active,.button:active{transform:translateY(1px) scale(.97);background:#397ab0}button:disabled{cursor:default;opacity:.48}button[aria-pressed=true]{background:#264f75;border-color:var(--accent);box-shadow:inset 0 0 0 1px #8ac6ff44}.primary{background:#448ec7;color:#071626;border-color:#76b9ef;font-weight:700}.secondary{background:#1b2c40;border-color:var(--line)}.quiet{background:transparent;border-color:var(--line);color:var(--muted);font-size:12px;padding:6px 10px;min-height:36px}.button-row{display:flex;gap:8px;flex-wrap:wrap}.button-row button{flex:1}.timbres{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:9px}.timbre-button{min-height:86px;display:flex;flex-direction:column;gap:7px;align-items:center;justify-content:center;background:#162234;border-color:var(--line);font-size:13px}.timbre-button svg{width:24px;height:24px;stroke:var(--accent);fill:none;stroke-width:1.5;stroke-linecap:round;stroke-linejoin:round}.timbre-button[aria-pressed=true]:before{content:"✓";position:absolute;right:8px;top:3px;font-size:11px;color:var(--accent)}.segments{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:4px;padding:4px;background:#101c2c;border:1px solid var(--line);border-radius:13px}.segments button{font-size:13px;padding:9px 4px;border-color:transparent;background:transparent}.segments button[aria-pressed=true]{background:#294f72;border-color:#5d8ab3;box-shadow:none}label{display:block;margin:14px 0 7px;font-size:13px}input:not([type=range]),select{width:100%;padding:11px 12px;border:1px solid #40536b;border-radius:10px;background:#101d2d;color:var(--text);font:inherit;min-height:44px}input[type=file]{font-size:12px}input::file-selector-button{border:0;border-radius:5px;padding:6px;background:#294c6b;color:var(--text);margin-right:8px}input[type=range]{width:100%;min-height:36px;margin:5px 0;accent-color:var(--accent);cursor:pointer}output{font-size:20px;font-weight:600;color:var(--accent);font-variant-numeric:tabular-nums;transition:transform .12s}.slider-block{margin-top:17px}.slider-block label{margin:0;font-size:14px}.field-head .quiet{margin-left:auto}.field-head output{min-width:72px;text-align:right}.slider-block:focus-within output{transform:scale(1.06)}.slider-actual{display:block;min-height:20px}.hint{font-size:12px;color:var(--muted)}details{margin:14px 0}summary{cursor:pointer;color:#bcd9f3;padding:8px 0;min-height:40px;font-size:13px}details[open]>summary{margin-bottom:10px}.score-import{border-top:1px solid var(--line);padding-top:8px}.score-actions{margin-top:12px;display:grid;grid-template-columns:1.4fr 1fr 1fr;gap:8px}.score-actions button{padding:10px 4px;font-size:13px}#scoreInfo,#scoreActual{font-size:12px;color:var(--muted)}.footer-note{display:block;margin-top:22px}.badge{font-size:11px;color:var(--muted);padding:3px 9px;border:1px solid var(--line);border-radius:99px;white-space:nowrap}.spinner,[data-pending=true]:after{content:"";display:inline-block;width:12px;height:12px;border:2px solid currentColor;border-right-color:transparent;border-radius:50%;animation:spin .7s linear infinite}[data-pending=true]{padding-right:28px!important}[data-pending=true]:after{position:absolute;right:9px;top:calc(50% - 6px)}[data-result=success]{box-shadow:0 0 0 2px #6edbb266;border-color:var(--good)}[data-result=error]{border-color:var(--bad)}button:focus-visible,a:focus-visible,input:focus-visible,select:focus-visible,summary:focus-visible{outline:3px solid var(--accent);outline-offset:3px}.board-head{margin:0 0 12px}.board-title{background:transparent;border:0;padding:0;text-align:left;min-height:32px;font-weight:600}.board-title[aria-pressed=true]{background:transparent;box-shadow:none;color:var(--accent)}.keyboard-scroll{overflow-x:auto;border:1px solid #35465b;background:#0c1523;border-radius:12px;padding:10px;scrollbar-width:thin;scrollbar-color:#406283 #101722}.keyboard{position:relative;min-width:0;width:100%;height:160px;isolation:isolate}.piano-key{position:absolute;margin:0;padding:0 1px;border-radius:0 0 5px 5px;transition:background .15s,box-shadow .15s,transform .1s;font-size:11px;display:flex;align-items:center;justify-content:flex-end;flex-direction:column;gap:2px}.piano-key.white{top:0;height:160px;width:calc(100% / 9 - 2px);background:linear-gradient(#f5f8fc,#dce5f0);border:1px solid #b3c2d5;color:#172b40;z-index:1;padding-bottom:12px}.piano-key.black{top:0;height:92px;width:7.2%;background:linear-gradient(#26364c,#101927);border:1px solid #53647e;z-index:2;padding-bottom:7px;color:#e7effb}.piano-key.extra{right:1%;top:3px;width:8.5%;min-width:31px;height:32px;min-height:32px;border-radius:5px;background:#315d77;border-color:#79b8cf;color:white;z-index:3;font-size:10px;justify-content:center}.piano-key.white[aria-pressed=true]{background:linear-gradient(#a4daff,#72b9ec);border-color:#b4e7ff;box-shadow:inset 0 -4px 0 #4d98cf}.piano-key.black[aria-pressed=true],.piano-key.extra[aria-pressed=true]{background:#377ba9;border-color:#a9deff;box-shadow:0 0 0 2px #8ac6ff66}.piano-key:not(:disabled):active{transform:translateY(2px);background:#64b7f0}.piano-key .key-id{font-size:9px;opacity:.65}.piano-key .key-note{font-size:clamp(8px,2.3vw,11px);font-weight:650}.piano-key.changed:after{content:"";position:absolute;width:5px;height:5px;border-radius:50%;background:#2e89cc;bottom:5px;right:4px}.piano-key.black.changed:after,.piano-key.extra.changed:after{background:#92d8ff}.key-chips{display:grid;grid-template-columns:repeat(8,minmax(0,1fr));gap:4px;margin-top:10px}.key-chip{padding:4px 0;min-height:44px;font-size:11px;background:#142133;border-color:var(--line)}.key-chip.changed{border-bottom:2px solid var(--accent)}.key-chip[aria-pressed=true]{background:#315b80}.board-card{margin:14px 0}.board-caption{margin:9px 0 0;color:var(--muted);font-size:11px}.editor-row{display:grid;grid-template-columns:1fr auto;gap:9px;align-items:end}.editor-row button{white-space:nowrap}.editor-row label{margin-top:0}#selectedKey{color:var(--accent);font-size:12px}.preset-fields{display:grid;grid-template-columns:1fr 1fr;gap:12px}.preset-fields label{margin-top:0}.apply-bar{position:fixed;z-index:10;bottom:0;left:0;right:0;margin:0 auto;max-width:760px;padding:12px 18px calc(12px + env(safe-area-inset-bottom));background:#101b2af5;border-top:1px solid #36516e;box-shadow:0 -10px 30px #0003}.apply-bar p{margin:0 0 8px;font-size:12px;color:var(--muted)}.apply-bar .primary{width:100%}.editor-card{scroll-margin-top:16px}@keyframes spin{to{transform:rotate(360deg)}}@keyframes breathe{50%{opacity:.4}}@media(min-width:600px){.timbres{grid-template-columns:repeat(5,minmax(0,1fr))}.key-chips{grid-template-columns:repeat(16,minmax(0,1fr))}}@media(max-width:380px){body{padding-left:12px;padding-right:12px}section,.card{padding:16px}.field-head{gap:6px}.quiet{font-size:11px;padding:6px}.page-header .nav-link{padding:8px;font-size:12px}.preset-fields{grid-template-columns:1fr}.editor-row{grid-template-columns:1fr}.key-chips{grid-template-columns:repeat(8,minmax(0,1fr))}}@media(prefers-reduced-motion:reduce){*,*:before,*:after{animation:none!important;transition:none!important;scroll-behavior:auto!important}}

#message[data-tone=success]{color:var(--good)}#message[data-tone=error]{color:var(--bad)}

[hidden]{display:none!important}.connection-line{display:flex;gap:8px 18px;flex-wrap:wrap;align-items:center}.connection-line .quiet{margin-left:auto}.compact-status{padding:10px 16px}.key-picker{margin:8px 0 0}.key-picker summary{color:var(--muted);font-size:11px;min-height:32px;padding:6px 0}.key-picker .key-chips{margin-top:4px}.board-card{padding-top:16px;padding-bottom:10px}.debug-panel{color:var(--muted);font-size:12px}.debug-panel pre{white-space:pre-wrap;overflow-wrap:anywhere;font:inherit}.debug-panel #actual{margin:8px 0}.eyebrow{letter-spacing:.08em}#scoreActual:empty{display:none}

/* Reference palette: navy glass, cyan light, misty violet and muted rose. */
:root{--bg:#102237;--panel:rgba(122,157,190,.13);--line:rgba(216,235,255,.22);--text:#f5f8ff;--muted:#c0cddd;--accent:#9ad8ff;--good:#62e6d1;--bad:#ff8e9d;--radius:25px;--nav-height:74px;--nav-space:calc(94px + env(safe-area-inset-bottom,0px))}
html{min-height:100%;background:#102237}body{position:relative;isolation:isolate;min-height:100svh;background:none;padding-top:34px;padding-bottom:calc(var(--nav-space) + 24px);-webkit-font-smoothing:antialiased}body:before{content:"";position:fixed;inset:0;z-index:-1;pointer-events:none;background:radial-gradient(ellipse 82% 61% at 106% -7%,rgba(206,158,203,.8),transparent 76%),radial-gradient(ellipse 67% 55% at -13% 20%,rgba(42,154,180,.58),transparent 73%),radial-gradient(ellipse 80% 60% at 108% 74%,rgba(66,115,175,.38),transparent 75%),radial-gradient(ellipse 65% 52% at -9% 105%,rgba(147,128,201,.69),transparent 78%),radial-gradient(ellipse 47% 45% at 100% 112%,rgba(48,157,183,.47),transparent 80%),linear-gradient(150deg,#263c57 0%,#0e2036 47%,#1a304b 100%)}
.page-header{margin-bottom:24px}.eyebrow{color:#9bdcff;font-size:12px;font-weight:650}.page-header h1{font-size:29px;font-weight:730;letter-spacing:-.025em;margin-top:7px;text-shadow:0 2px 18px #0e1c3430}
section,.card{background:linear-gradient(132deg,rgba(173,215,239,.16),rgba(145,160,198,.1) 52%,rgba(177,173,208,.14));border:1px solid rgba(217,237,255,.2);box-shadow:inset 0 1px 0 #ffffff13,0 14px 38px #05112024;-webkit-backdrop-filter:blur(26px) saturate(135%);backdrop-filter:blur(26px) saturate(135%);border-radius:var(--radius)}
.status-card{background:linear-gradient(105deg,#8cdbef23,#c2abc629);padding:16px 18px}.status-card .section-head{margin-bottom:8px}.status-row{font-size:13px;font-weight:550}.status-row:before{width:9px;height:9px;flex-basis:9px}.status-row[data-state=connected]:before{box-shadow:0 0 14px #62e6d169}.status-row[data-state=error]:before{box-shadow:0 0 12px #ff8e9d3b}.compact-status{padding:10px 16px}
button,.button{background:linear-gradient(140deg,#d5edff1b,#b3c5e50a);border-color:#e0efff38;border-radius:15px;box-shadow:inset 0 1px 0 #ffffff0d,0 4px 12px #06152412;transition:transform .16s cubic-bezier(.2,.8,.2,1),background .2s,border-color .2s,box-shadow .2s}button:not(:disabled):active{transform:scale(.975);background:#94ceff30}button[aria-pressed=true]{background:linear-gradient(135deg,#5ebeff55,#2d85c94d 65%,#a4c9ff21);border-color:#98d9ffbb;box-shadow:inset 0 0 18px #a6dcff38,0 0 14px #4399e333}.primary{color:#f7fbff;background:linear-gradient(110deg,#bd9bedb8,#4f91e7c9 49%,#54c5f0d9);border-color:#cfddff91;box-shadow:inset 0 1px 0 #fff5,inset 0 -1px 0 #b5e5ff44,0 7px 22px #2f85ce30}.primary:not(:disabled):active{background:linear-gradient(110deg,#af8ce4d9,#4886d8e6 49%,#4ab4dfed)}.secondary,.quiet{background:#b6d5ff0b;border-color:#d2e5ff24}.quiet{color:#c6d7e9;border-radius:12px}.timbre-button{background:linear-gradient(138deg,#b8d7f41c,#a7c0ee09);border-color:#d8eaff36;min-height:88px}.timbre-button svg{stroke:#a9deff;filter:drop-shadow(0 2px 5px #64baff20)}.timbre-button[aria-pressed=true]{background:linear-gradient(140deg,#4ba9e477,#497db347 65%,#5ca9e940);box-shadow:inset 0 0 22px #9fdcff55,0 0 18px #4ca8f82e}.timbre-button[aria-pressed=true]:before{color:#c9eeff}.segments{background:#0a1a2b22;border-color:#d2e5ff1f;border-radius:18px;gap:8px;padding:6px}.segments button{border-color:#e0efff24;background:linear-gradient(140deg,#d5edff12,#b3c5e505);padding:12px 4px}.segments button[aria-pressed=true]{background:linear-gradient(135deg,#59b9ed60,#416eaa40);border-color:#98d9ffb0;box-shadow:inset 0 0 15px #9fdcff33}
input:not([type=range]),select{background:linear-gradient(110deg,#b7d3f20e,#9bbed30a);border-color:#d7e9ff33;border-radius:14px;box-shadow:inset 0 1px 0 #ffffff09}select option{background:#21364d;color:#f5f8ff}input::file-selector-button{background:#87bcf52b;border:1px solid #c9e6ff33;border-radius:8px}input[type=range]{accent-color:#9ddcff}input[type=range]::-webkit-slider-thumb{filter:drop-shadow(0 0 7px #7ac9ff70)}output{color:#9bd7ff}summary{color:#d2e4f5}.badge{background:#18304920;border-color:#d6e9ff20}.hint,small,.muted{color:var(--muted)}.score-import{border-color:#d2e5ff25}
.keyboard-scroll{background:linear-gradient(135deg,#10223948,#172b4033);border-color:#d8e8f51f;box-shadow:inset 0 2px 14px #00000012;border-radius:18px}.piano-key.white{background:linear-gradient(100deg,#fafbff,#e2e7ed);border-color:#fafcff80;box-shadow:inset 0 -3px 5px #485e761a,0 3px 5px #0613212b;border-radius:4px 4px 7px 7px}.piano-key.black{background:linear-gradient(115deg,#424849,#141c22);border-color:#49535d;box-shadow:inset 0 1px 0 #ffffff1c,0 4px 6px #0006;border-radius:3px 3px 5px 5px}.piano-key.extra{background:linear-gradient(135deg,#adcbe65c,#6f8ca441);border-color:#c9ecffc7;box-shadow:inset 0 1px 4px #ffffff39,0 4px 12px #0a233f55;border-radius:9px}.piano-key.white[aria-pressed=true]{background:linear-gradient(100deg,#c2efff,#83cfff 55%,#b4e6ff);border-color:#d5f4ff;box-shadow:inset 0 0 16px #ceefff80,0 0 15px #6dc9ff65}.piano-key.black[aria-pressed=true],.piano-key.extra[aria-pressed=true]{background:linear-gradient(120deg,#5dabcfa6,#3874b570);border-color:#bceaff;box-shadow:0 0 12px #70bfff4d}.board-title{box-shadow:none!important;background:none!important;border:0}.key-chip{background:#c1dfff0b;border-color:#d5e9ff29}.key-chip[aria-pressed=true]{background:#70baff3d}.board-title[aria-pressed=true]{color:#b3e3ff}.editor-card{scroll-margin-top:18px}
.bottom-nav{position:fixed;z-index:30;left:12px;right:12px;bottom:calc(10px + env(safe-area-inset-bottom,0px));max-width:564px;margin:0 auto;height:var(--nav-height);display:grid;grid-template-columns:repeat(4,minmax(0,1fr));padding:7px;gap:5px;background:linear-gradient(120deg,#a6c9e82c,#a0abc324 70%,#a9d9e425);border:1px solid #d9eeff42;border-radius:26px;box-shadow:inset 0 1px 0 #fff2,0 10px 32px #030d263d;-webkit-backdrop-filter:blur(34px) saturate(155%);backdrop-filter:blur(34px) saturate(155%)}.bottom-nav a{display:flex;flex-direction:column;align-items:center;justify-content:center;gap:3px;min-height:55px;border:1px solid transparent;border-radius:18px;color:#bdcede;font-size:11px;line-height:1.2;transition:background .2s,color .2s,transform .15s}.bottom-nav a:hover{text-decoration:none;background:#c2dfff0a}.bottom-nav a:active{transform:scale(.95)}.bottom-nav svg{width:23px;height:23px;fill:none;stroke:currentColor;stroke-width:1.65;stroke-linecap:round;stroke-linejoin:round}.bottom-nav a[aria-current=page]{color:#a6ddff;background:linear-gradient(145deg,#8dd4ff27,#7ba9ee10);border-color:#bbdfff20;text-shadow:0 0 12px #8acbff33}.bottom-nav a[aria-current=page] svg{filter:drop-shadow(0 0 6px #70bfff66)}
body.keymap-page{padding-bottom:calc(var(--nav-space) + 150px)}.apply-bar{bottom:var(--nav-space);left:12px;right:12px;max-width:724px;padding:13px 16px;background:linear-gradient(120deg,#abc6e52e,#b1add31b,#83c3db25);border:1px solid #d9eeff38;border-radius:24px;box-shadow:inset 0 1px 0 #fff2,0 8px 30px #06132933;-webkit-backdrop-filter:blur(28px) saturate(145%);backdrop-filter:blur(28px) saturate(145%)}.apply-bar .primary{border-radius:16px;min-height:48px}.apply-bar p{color:#d3e0ee}.page-view:not([hidden]){animation:pane-in .22s cubic-bezier(.2,.8,.2,1)}@keyframes pane-in{from{opacity:.55;transform:translateY(6px)}to{opacity:1;transform:translateY(0)}}
@supports not ((backdrop-filter:blur(1px)) or (-webkit-backdrop-filter:blur(1px))){section,.card{background:#263b52ee}.bottom-nav,.apply-bar{background:#2a4059f2}}
@media(max-width:380px){body{padding-top:28px}.page-header h1{font-size:26px}.bottom-nav{left:10px;right:10px}.apply-bar{left:10px;right:10px}.segments{gap:5px}.keyboard-scroll{padding:8px}.connection-line{gap:6px 12px}}
@media(prefers-reduced-motion:reduce){.page-view:not([hidden]){animation:none}.bottom-nav a{transition:none}}

/* Tactile glass: light rolls inward on press, then eases back without changing the confirmed selection. */
button{transition:transform .16s cubic-bezier(.2,.8,.2,1),background .2s,border-color .2s,box-shadow .2s,filter .2s}
button:not(.piano-key):not([data-pending=true]):after{content:"";position:absolute;inset:0;border-radius:inherit;pointer-events:none;background:linear-gradient(145deg,#dcf5ff3b 0%,#d5eeff08 42%,transparent 55%,#9dccff16 100%);opacity:0;transition:opacity .18s ease}
button:not(.piano-key):not(:disabled):active:after,button:not(.piano-key)[aria-pressed=true]:not([data-pending=true]):after{opacity:1}
button:not(.piano-key):not(:disabled):active{background:radial-gradient(ellipse at 25% 0%,#b1e4ff3b,transparent 70%),linear-gradient(135deg,#64bcf44f,#4f86bc38);border-color:#c6ecffb3;box-shadow:inset 0 2px 5px #09244833,inset 0 0 20px #b4e6ff3b,0 0 16px #6cc4ff26;filter:brightness(1.07)}
button.primary:not(:disabled):active{background:linear-gradient(110deg,#c7a9f2cc,#619ff0e0 49%,#6ed1f7e8);box-shadow:inset 0 2px 7px #27528c35,inset 0 0 18px #e8faff44,0 0 18px #7ccfff40}
.piano-key.white:not(:disabled):active{background:linear-gradient(105deg,#d7f7ff,#88ceff 55%,#c1eaff);border-color:#edfbff;box-shadow:inset 0 3px 8px #3f8bc144,inset 0 0 20px #d4f6ff9c,0 0 18px #75d0ff6b;transform:translateY(2px)}
.piano-key.black:not(:disabled):active,.piano-key.extra:not(:disabled):active{background:linear-gradient(130deg,#9cddff7a,#397ebdaf);border-color:#d9f5ff;box-shadow:inset 0 2px 5px #112f4d66,inset 0 0 12px #a2dcff66,0 0 12px #79c6ff55;transform:translateY(2px)}
.bottom-nav a:active{background:linear-gradient(135deg,#cbecff2e,#82b6fa22);box-shadow:inset 0 1px 8px #deefff20}
@media(prefers-reduced-motion:reduce){button:not(.piano-key):not([data-pending=true]):after{transition:none}}

/* Keep dock labels readable when pale piano keys pass underneath the glass. */
.bottom-nav{background:linear-gradient(120deg,#739bc52b,#7b88b41c),rgba(16,34,56,.73)}.bottom-nav a{color:#c4d4e7}.bottom-nav a[aria-current=page]{color:#abe2ff}.apply-bar{background:linear-gradient(120deg,#9cb9df22,#a0a3cb16,#83bdd524),rgba(24,43,68,.68)}

/* Compact scale: keep the reference colors and glass, reduce empty area. */
:root{--radius:21px;--nav-height:62px;--nav-space:calc(80px + env(safe-area-inset-bottom,0px))}body{font-size:14px;padding-top:24px}.page-header{margin-bottom:16px}.page-header h1{font-size:25px}.eyebrow{font-size:11px}h2{font-size:17px;margin-bottom:12px}section,.card{padding:15px;margin:12px 0}.section-head{margin-bottom:10px}.status-card{padding:12px 15px}.compact-status{padding:8px 12px}.status-row{font-size:12px}.timbres{gap:8px}.timbre-button{min-height:72px;padding:9px 8px;gap:5px;border-radius:13px}.timbre-button svg{width:22px;height:22px}.segments{padding:4px;gap:6px;border-radius:15px}.segments button{padding:9px 4px;min-height:54px;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:4px;font-size:12px}.segments button svg{width:21px;height:21px;fill:none;stroke:#a9deff;stroke-width:1.7;stroke-linecap:round;stroke-linejoin:round}.selection-caption{display:block;color:#bedff6;font-size:11px;margin-top:8px;line-height:1.4}.timbre-button[aria-pressed=true]:before{content:""}.timbre-button[aria-pressed=true][data-applied=true]:before{content:"✓"}.timbre-button[aria-pressed=true],.segments button[aria-pressed=true]{background:radial-gradient(ellipse at 18% 10%,#8ed6ff47,transparent 70%),linear-gradient(135deg,#4dace86b,#3772a64a 70%,#66b5ed36);border-color:#8dd6ffdc;box-shadow:inset 0 0 18px #9cdcff55,inset 0 1px 2px #d7f4ff66,0 0 12px #55b8fb3d}.keyboard,.piano-key.white{height:128px}.piano-key.black{height:75px}.piano-key.white{padding-bottom:10px}.keyboard-scroll{padding:8px;border-radius:15px}.board-head{margin-bottom:8px}.board-card{padding-top:12px;padding-bottom:6px}.board-title{font-size:14px;min-height:28px}.key-picker{margin-top:3px}.editor-row label{font-size:12px}.editor-row select{font-size:13px;min-height:40px;padding:8px 10px}.editor-row button{min-height:40px;padding:8px 12px}.bottom-nav{border-radius:21px;padding:5px}.bottom-nav a{min-height:49px;font-size:10px;border-radius:15px;gap:2px}.bottom-nav svg{width:21px;height:21px}.apply-bar{display:flex;align-items:center;justify-content:space-between;gap:12px;padding:10px 12px;border-radius:18px}.apply-bar p{margin:0;font-size:12px;flex:1}.apply-bar .primary{width:auto;min-width:100px;min-height:40px;padding:8px 20px;font-size:13px;border-radius:12px}body.keymap-page{padding-bottom:calc(var(--nav-space) + 92px)}
.sound-control h2{margin-bottom:13px}.sound-row{display:grid;grid-template-columns:38px minmax(0,1fr);gap:11px;align-items:start;margin-top:16px}.sound-icon{width:38px;height:38px;border-radius:50%;display:flex;align-items:center;justify-content:center;background:linear-gradient(140deg,#b1d8f229,#82b3df0c);box-shadow:inset 0 1px 0 #ffffff10}.sound-icon svg{width:23px;height:23px;fill:none;stroke:#d3edff;stroke-width:1.8;stroke-linecap:round;stroke-linejoin:round}.sound-body{min-width:0}.sound-head{display:flex;align-items:center;gap:7px;min-height:29px}.sound-head label{margin:0;font-size:14px;font-weight:550;white-space:nowrap}.sound-head output{margin-left:auto;font-size:22px;white-space:nowrap;float:none;line-height:1.2}.reset-icon{padding:0;min-height:28px;width:28px;flex:0 0 28px;border-radius:9px;font-size:18px;color:#d3e6f7;background:transparent;border-color:transparent;box-shadow:none}.tempo-track{display:grid;grid-template-columns:28px minmax(0,1fr) 28px;gap:9px;align-items:center}.step-button{padding:0;width:28px;min-height:28px;height:28px;border-radius:9px;font-size:20px;line-height:1;background:linear-gradient(#b3d5f22b,#6885a51a);border-color:#cce5ff26}.sound-control input[type=range]{--range-fill:0%;appearance:none;-webkit-appearance:none;background:transparent;min-height:28px;height:28px;margin:5px 0;width:100%}.sound-control input[type=range]::-webkit-slider-runnable-track{height:6px;border-radius:8px;background:linear-gradient(to right,#7cc6ff var(--range-fill),#b7d1e333 var(--range-fill));box-shadow:inset 0 1px 2px #051c4033,0 0 4px #8dd6ff16}.sound-control input[type=range]::-webkit-slider-thumb{appearance:none;-webkit-appearance:none;width:21px;height:21px;border:1px solid #e4f8ff;border-radius:50%;background:linear-gradient(145deg,#e0f8ff,#9bd5fc);margin-top:-7.5px;box-shadow:0 0 10px #88d4ff66}.sound-control input[type=range]::-moz-range-track{height:6px;border-radius:8px;background:#b7d1e333}.sound-control input[type=range]::-moz-range-progress{height:6px;border-radius:8px;background:#7cc6ff}.sound-control input[type=range]::-moz-range-thumb{width:21px;height:21px;border:1px solid #e4f8ff;border-radius:50%;background:#bfeaff;box-shadow:0 0 10px #88d4ff66}.sound-control input[type=range]:focus-visible{outline-offset:0;border-radius:9px}.sound-control .reset-icon:after{display:none}.sound-control .step-button:after{border-radius:9px}
@media(max-width:380px){body{padding-top:22px}.page-header h1{font-size:23px}section,.card{padding:13px}.compact-status{padding:8px 11px}.board-card{padding-top:11px;padding-bottom:5px}.sound-row{grid-template-columns:34px minmax(0,1fr);gap:9px}.sound-icon{width:34px;height:34px}.sound-head label{font-size:13px}.sound-head output{font-size:20px}.editor-row{grid-template-columns:minmax(0,1fr) auto}.apply-bar{padding:9px 11px}}

/* Board headings are text labels, not glass buttons. K16 remains legible over pale keys. */
.board-title,.board-title[aria-pressed=true],.board-title:not(:disabled):active{background:transparent!important;box-shadow:none!important;border:0!important;filter:none!important;transform:none!important;color:#e3f0fc}.board-title:before,.board-title:after{display:none!important}.piano-key.extra{background:linear-gradient(145deg,#355a7b,#19364f);border:1px solid #a7d5f2;color:#fff;box-shadow:inset 0 1px 0 #d8f3ff2b,0 3px 8px #071d3b55}.piano-key.extra .key-id{font-size:11px;font-weight:700;opacity:1}.piano-key.extra[aria-pressed=true]{background:linear-gradient(135deg,#559bd0,#28618f);border-color:#d2f2ff;box-shadow:inset 0 0 10px #b9e9ff44,0 0 12px #71caff55}

/* Final control-page density; score/keymap cards keep their own proportions. */
.page-header{justify-content:center;text-align:center;margin-bottom:15px}
.page-header>div{width:100%}
body{padding-top:23px}
body[data-page=control] section{padding:11px 13px;margin:9px 0;border-radius:18px}
body[data-page=control] h2{font-size:16px;margin-bottom:10px}
body[data-page=control] .section-head{margin-bottom:8px}
body[data-page=control] .section-head h2{margin-bottom:0}
body[data-page=control] .status-card{padding:10px 13px}
body[data-page=control] .status-row{margin:4px 0;font-size:12px}
body[data-page=control] .timbres{gap:7px}
body[data-page=control] .timbre-button{min-height:61px;padding:7px 4px;gap:4px;font-size:12px;border-radius:12px}
body[data-page=control] .timbre-button svg{width:21px;height:21px}
body[data-page=control] .segments{padding:4px;gap:5px;border-radius:14px}
body[data-page=control] .segments button{min-height:47px;padding:6px 3px;gap:3px;font-size:12px;border-radius:11px}
body[data-page=control] .segments svg{width:19px;height:19px}
body[data-page=control] .selection-caption{margin-top:6px;font-size:10px}
body[data-page=control] .sound-row{margin-top:11px;gap:9px;grid-template-columns:32px minmax(0,1fr)}
body[data-page=control] .sound-icon{width:32px;height:32px}
body[data-page=control] .sound-icon svg{width:19px;height:19px}
body[data-page=control] .sound-head label{font-size:13px}
body[data-page=control] .sound-head output{font-size:20px}
.practice-card .segments button{min-height:44px;font-size:13px;padding:8px 3px}
.practice-card .selection-caption{margin-top:9px}
)MUSICWEB";
const char UI_TEXT_JS[] PROGMEM=R"MUSICWEB( 'use strict';
// Presentation only. Detailed transport errors stay available in the collapsed panel.
function noticeText(text){
 if(/FPGA未应答|无法访问 ESP32|FPGA 已连接|正在读取状态|已读取当前映射/.test(text))return '';
 if(/下载失败|下载内存不足/.test(text))return '下载失败';
 if(/FPGA报告故障/.test(text))return '设备故障';
 if(/完整32键|MIDI.*范围|起始八度/.test(text))return '音符超出范围';
 if(/正在等待 FPGA/.test(text))return '正在应用…';
 if(/音量已生效|速度已生效|提交并回读确认/.test(text))return '已应用';
 if(/切换完成/.test(text))return '已切换';
 if(/曲谱已传入/.test(text))return '已传输';
 if(/已保存到页面草稿/.test(text))return '已保存';
 if(/尚未生效|尚未确认|协议|FPGA拒绝|FPGA拒绝了|读取失败|响应异常|状态无效/.test(text))return '操作未完成';
 return text;
}
function showNotice(text,shortText){
 const notice=document.getElementById('message'),detail=document.getElementById('debugInfo');
 if(detail)detail.textContent=text;const value=shortText===undefined?noticeText(text):shortText;
 notice.textContent=value;notice.hidden=!value;
}
function showConnections(wifi,uart){
 const w=document.getElementById('wifiLink'),u=document.getElementById('uartLink');
 if(wifi!==null){w.textContent=wifi?'Wi-Fi 已连接':'Wi-Fi 未连接';w.dataset.state=wifi?'connected':'error';}
 u.textContent=wifi===false?'FPGA 状态未知':uart==='connected'?'FPGA 已连接':uart==='waiting'?'FPGA 连接中…':'FPGA 未连接';u.dataset.state=wifi===false?'unknown':uart;
}
if(typeof module!=='undefined')module.exports={noticeText};
)MUSICWEB";
const char NAV_JS[] PROGMEM=R"MUSICWEB( 'use strict';
function navigationPage(path,hash){return path==='/keymap'?'keymap':hash==='#scores'?'scores':hash==='#settings'?'settings':'control';}
if(typeof module!=='undefined')module.exports={navigationPage};
if(typeof document!=='undefined'){
 const keymap=document.body.classList.contains('keymap-page');
 function renderNavigation(){
  const page=keymap?'keymap':navigationPage(location.pathname,location.hash);
  document.body.dataset.page=page;
  document.querySelectorAll('.bottom-nav a').forEach(link=>{if(link.dataset.page===page)link.setAttribute('aria-current','page');else link.removeAttribute('aria-current');});
  if(keymap)return;
  for(const name of ['control','scores','settings'])document.getElementById(name+'View').hidden=name!==page;
  document.getElementById('pageTitle').textContent={control:'电子乐器控制',scores:'曲谱',settings:'设置'}[page];
 }
 document.querySelectorAll('.bottom-nav a').forEach(link=>link.addEventListener('click',event=>{
  const target=new URL(link.href,location.href);
  if(!keymap&&target.pathname==='/'&&target.origin===location.origin){event.preventDefault();if(location.hash!==target.hash)location.hash=target.hash;else renderNavigation();window.scrollTo(0,0);}
 }));
 window.addEventListener('hashchange',renderNavigation);renderNavigation();
}
)MUSICWEB";
const char DEVICE_API_JS[] PROGMEM=R"MUSICWEB( 'use strict';
// A 202 only acknowledges a queued job. Success still comes from its final device result.
async function deviceJSON(fetchFn,url,options={},wait=ms=>new Promise(resolve=>setTimeout(resolve,ms))){
 const started=Date.now();let response,data;
 const check=()=>{if(options.signal&&options.signal.aborted)throw Error('请求已取消，操作结果未知');if(Date.now()-started>30000)throw Error('设备等待超时，操作结果未知');};
 do{check();response=await fetchFn(url,options);data=await response.json();if(data.jobBusy===true)await wait(80);}while(data.jobBusy===true);
 if(response.status!==202||data.pending!==true)return {response,data};
 const job=data.job;if(!Number.isInteger(job)||job<1||job>65535)throw Error('设备任务编号无效');
 while(response.status===202&&data.pending===true){check();await wait(35);check();response=await fetchFn('/api/job?id='+job,{cache:'no-store',signal:options.signal});data=await response.json();}
 return {response,data};
}
if(typeof module!=='undefined')module.exports={deviceJSON};
)MUSICWEB";
