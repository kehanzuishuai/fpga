'use strict';
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
 },sync(value){
  if(!Number.isInteger(value)||value<0||value>2)return false;
  ++generation;selected=value;show('已应用');return true;
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
  const practiceContainer=byId('practiceModes'),practiceCard=practiceContainer.closest('.practice-card');
  practiceContainer.classList.add('segments');
  PRACTICE_MODES.forEach((name,value)=>{
    const b=document.createElement('button');b.type='button';b.dataset.practice=String(value);b.textContent=name;
    b.setAttribute('aria-pressed','false');b.onclick=()=>practice.select(value);practiceContainer.append(b);
  });
  let practiceUnsupported=false,practicePoll=0;
  function refreshPractice(){
    if(practiceUnsupported)return Promise.resolve(false);
    return controller.task(async()=>{
      const {response,data}=await deviceRequest(window.fetch.bind(window),'/api/performance',{cache:'no-store'});
      if(response.status===501){practiceUnsupported=true;practiceCard.hidden=true;return false;}
      if(response.ok&&data.ok===true&&data.supported===true&&practice.sync(data.mode)){
        practiceCard.hidden=false;return true;
      }
      byId('practiceStatus').textContent='演奏方式尚未确认';return false;
    });
  }
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
    if(!document.hidden&&!controller.isBusy()){
      await controller.refresh({background:true});
      if(++practicePoll>=4){practicePoll=0;await refreshPractice();}
    }
    setTimeout(poll,controller.pollDelay());
  }
  controller.refresh().finally(async()=>{await refreshPractice();setTimeout(poll,controller.pollDelay());});
}
