'use strict';
const assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path'),vm=require('node:vm');
const root=path.resolve(__dirname,'..'),phone=path.join(root,'firmware/remote_music_ble/shouji');
const source=fs.readFileSync(path.join(phone,'keymap.js'),'utf8');
const {KEY_LAYOUT,defaultMap}=require(path.join(phone,'keymap.js'));
const {deviceJSON}=require(path.join(phone,'device-api.js'));
const embedded=fs.readFileSync(path.join(phone,'../esp32/ESP32_FPGA_Music_Controller/web_page.h'),'utf8');
assert.equal(embedded.match(/const char KEYMAP_JS\[\] PROGMEM=R"MUSICWEB\(([\s\S]*?)\)MUSICWEB";/)[1],source);
for(let k=0;k<16;k++){
 const shape=KEY_LAYOUT[k];assert.equal(shape.kind,k<9?'white':k<15?'black':'extra');
 if(k<9)assert.equal(shape.slot,k);else if(k<15)assert.equal(shape.boundary,[1,2,4,5,7,8][k-9]);
}
class Element{
 constructor(tag='div'){this.tag=tag;this.children=[];this.attrs={};this.dataset={};this.style={};this.value='';this.textContent='';this.classList={toggle(){}};}
 append(...nodes){this.children.push(...nodes);}add(node){this.append(node);}setAttribute(k,v){this.attrs[k]=String(v);}
}
async function boot(initial){
 const nodes=new Map(),all=[],posts=[];let active=[...initial],revision=7;
 const get=id=>{if(!nodes.has(id))nodes.set(id,new Element());return nodes.get(id);};
 const document={getElementById:get,createElement:tag=>{const n=new Element(tag);all.push(n);return n;}};
 const fetch=async(url,options={})=>{
  assert.equal(url,'/api/keymap');
  if(options.method==='POST'){active=options.body.trim().split('\n').map(Number);posts.push([...active]);revision++;}
  return {ok:true,status:200,json:async()=>({ok:true,uartConnected:true,notes:[...active],revision})};
 };
 const context={document,window:{fetch,addEventListener(){},confirm:()=>true},console,AbortController,
  Option:class extends Element{constructor(text,value){super('option');this.textContent=text;this.value=value;}},
  setTimeout:()=>1,clearTimeout(){},showNotice(){},showConnections(){},
  require:()=>({deviceJSON}),module:{exports:{}}};
 vm.runInNewContext(source,context);
 for(let n=0;n<40;n++)await Promise.resolve();
 assert.equal(get('apply').disabled,false);
 const buttons=all.filter(n=>n.className?.startsWith('piano-key '));assert.equal(buttons.length,32);
 for(let i=0;i<32;i++){
  const key=buttons.find(b=>b.dataset.index===i),local=i%16;
  assert.equal(key.className,'piano-key '+(local<9?'white':local<15?'black':'extra'));
  if(local<9)assert.equal(key.style.left,(local*100/9)+'%');
  else if(local<15)assert.equal(key.style.left,([1,2,4,5,7,8][local-9]*100/9-3.6)+'%');
  key.onclick();assert.equal(get('note').value,initial[i]);assert(key.attrs['aria-label'].includes('K'+(local+1)+' '));
  assert.equal(key.attrs['aria-pressed'],'true');assert.equal(get('presetBoard').value,Math.floor(i/16));
 }
 // Submit through the real draft/client path and verify channel-order payload.
 await get('apply').onclick();
 assert.deepEqual(posts[0],initial);assert.equal(get('revision').textContent,'FPGA映射版本：8');
 if(initial[0]===60){
 // Real slider -> draft -> HTTP payload, without pressing presetApply.
 get('presetBoard').value='0';get('preset').value='chromatic';get('octave').value='3';get('octave').oninput();
 assert.equal(get('apply').disabled,false);
 await get('apply').onclick();assert.deepEqual(posts[1].slice(0,16),Array.from({length:16},(_,i)=>48+i));
 assert.equal(get('draftState').textContent,'已应用');
 // C6 needs MIDI 84..99: reject, do not silently submit old mapping.
 get('octave').value='6';get('octave').oninput();assert.equal(get('apply').disabled,true);
 const count=posts.length;await get('apply').onclick();assert.equal(posts.length,count);
 assert(get('draftState').textContent.startsWith('预设无效'));
 // Recover from an invalid preset; defaults remain usable.
 get('octave').value='3';get('octave').oninput();assert.equal(get('apply').disabled,false);
 get('defaults').onclick();await get('apply').onclick();assert.deepEqual(posts.at(-1),defaultMap());
 }
 return buttons.length;
}
(async()=>{
 const n=await boot(defaultMap())+await boot([...defaultMap()].reverse());
 console.log(`PASS web: ${n} physical-key selections, correct black-key geometry, custom-map roundtrip, embedded assets exact`);
})().catch(e=>{console.error(e);process.exitCode=1;});
