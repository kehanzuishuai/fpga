'use strict';
const assert=require('assert'),fs=require('fs'),path=require('path'),vm=require('vm');
const root=path.resolve(__dirname,'..'),phone=path.join(root,'firmware/remote_music_ble/shouji');
const scoring=require(path.join(phone,'score.js'));
const {deviceJSON}=require(path.join(phone,'device-api.js'));
class Element{
 constructor(tag='div'){this.tag=tag;this.dataset={};this.children=[];this.attrs={};this.hidden=false;this.textContent='';this.value='0';this.min='0';this.max='100';this.style={setProperty(){}};this.classList={add:c=>this.attrs.class=c};}
 setAttribute(k,v){this.attrs[k]=String(v);}append(...n){this.children.push(...n);}appendChild(n){this.append(n);}addEventListener(){} add(n){this.append(n);}
 closest(){return this.card;}replaceChildren(...n){this.children=n;}
}
async function boot(capability){
 const nodes=new Map(),all=[],timers=[],requests=[],notices=[];
 const get=id=>{if(!nodes.has(id)){const n=new Element();nodes.set(id,n);all.push(n);}return nodes.get(id);};
 const card=new Element();card.hidden=true;get('practiceModes').card=card;
 get('volume').value='100';get('tempo').value='120';get('tempo').min='30';get('tempo').max='240';
 const doc={hidden:false,activeElement:null,getElementById:get,
  createElement:t=>{const n=new Element(t);all.push(n);return n;},
  createElementNS:(ns,t)=>{const n=new Element(t);n.namespaceURI=ns;all.push(n);return n;},
  querySelectorAll:selector=>all.filter(n=>selector==='[data-practice]'?n.dataset.practice!==undefined:
   selector.startsWith('[data-kind=')?selector.includes(`"${n.dataset.kind}"`):false),
  querySelector:()=>null};
 let actualMode=0,reject=false,playing=false,count=4,loaded=false;
 const response=(status,data)=>({status,ok:status>=200&&status<300,json:async()=>data});
 const fetch=async(url,options={})=>{
  requests.push({url,options});
  const state=()=>({ok:true,uartConnected:true,stateValid:true,mode:0,timbre:0,switching:false,fault:false,settingsValid:true,volume:100,tempo:120,scoreValid:true,scoreCount:count,playing,streamLoaded:loaded,streamPlaying:loaded&&playing,performanceMode:actualMode});
  if(url==='/api/status')return response(200,state());
  if(url==='/api/stream'){loaded=true;return response(200,state());}
  if(url==='/api/score'){loaded=false;count=options.body.trim().split('\n').length;return response(200,state());}
  if(url==='/api/control'){const p=new URLSearchParams(options.body);if(p.get('kind')==='play')playing=p.get('value')==='1';return response(200,state());}
  if(url==='/api/performance'){
   if(capability===false)return response(501,{ok:false,supported:false});
   if(capability==='offline')return response(503,{ok:false,supported:false});
   if(options.method==='POST'){
    if(!reject)actualMode=Number(new URLSearchParams(options.body).get('mode'));
    return response(202,{pending:true,job:1});
   }
   return response(200,{ok:true,supported:true,mode:actualMode,state:0});
  }
  if(url==='/api/job?id=1')return response(reject?503:200,{ok:!reject,supported:true,mode:actualMode,state:0});
  throw Error(url);
 };
 const ctx={...scoring,Option:class extends Element{constructor(text,value){super('option');this.textContent=text;this.value=value;}},document:doc,window:{fetch},URLSearchParams,AbortController,console,
  showNotice:s=>notices.push(s),showConnections(){},setTimeout:fn=>{timers.push(fn);return timers.length;},clearTimeout(){},
  require:()=>({deviceJSON:(f,u,o)=>deviceJSON(f,u,o,()=>Promise.resolve())}),module:{exports:{}}};
 vm.runInNewContext(fs.readFileSync(path.join(phone,'app.js'),'utf8'),ctx);
 for(let i=0;i<60;i++)await Promise.resolve();
 return {nodes,card,requests,timers,notices,setReject:v=>reject=v,exports:ctx.module.exports};
}
(async()=>{
 const app=await boot(true),get=id=>app.nodes.get(id);
 const buffer=fs.readFileSync(path.resolve(root,'scores/卡农_最新ESP32_20261103/卡农_多音轨_20261103.mid'));
 get('scoreFile').files=[{size:buffer.length,arrayBuffer:async()=>new Uint8Array(buffer)}];await get('scoreFile').onchange();
 assert(get('scoreInfo').textContent.includes('4286事件'));assert.equal(get('track').value,'-1');
 await get('upload').onclick();const stream=app.requests.find(r=>r.url==='/api/stream');assert(stream);assert.equal(stream.options.body.trim().split('\n').length,4286);
 assert.strictEqual(await get('play').onclick(),true);assert(app.requests.some(r=>r.url==='/api/control'&&r.options.body.includes('kind=play')));
 assert.strictEqual(app.notices.at(-1),'正在播放');
 assert.strictEqual(await get('stop').onclick(),true);
 // Guidance still uploads the selected 32-item segment through the original endpoint.
 const buttons=get('practiceModes').children;await buttons[2].onclick();assert.equal(get('track').value,'0');
 const guide=Buffer.from(JSON.stringify({name:'guide',bpm:120,events:Array.from({length:40},(_,i)=>[60+i%2,100,100])}));
 get('scoreFile').files=[{size:guide.length,arrayBuffer:async()=>new Uint8Array(guide)}];await get('scoreFile').onchange();
 assert.equal(get('part').children.length,2);get('part').value='1';await buttons[2].onclick();
 assert.equal(get('part').value,'1');await get('upload').onclick();
 const legacy=app.requests.find(r=>r.url==='/api/score');assert(legacy);assert.equal(legacy.options.body.trim().split('\n').length,8);
 assert.strictEqual(await get('play').onclick(),true);assert.strictEqual(app.notices.at(-1),'正在播放');
 assert.strictEqual(await get('stop').onclick(),true);
 console.log('PASS real APP_JS DOM: Canon all-track import -> 4286-event whole-song upload -> confirmed play/stop; guidance segment upload -> confirmed play/stop');
})().catch(e=>{console.error(e);process.exitCode=1;});
