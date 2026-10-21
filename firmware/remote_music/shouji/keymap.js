 'use strict';
const deviceRequest=typeof module!=='undefined'?require('./device-api.js').deviceJSON:deviceJSON;
const SCALES={chromatic:[0,1,2,3,4,5,6,7,8,9,10,11],major:[0,2,4,5,7,9,11],pentatonic:[0,2,4,7,9]};
function noteName(n){return ['C','C♯','D','D♯','E','F','F♯','G','G♯','A','A♯','B'][n%12]+(Math.floor(n/12)-1);}
function defaultMap(){return Array.from({length:32},(_,i)=>60+i);}
function presetMap(kind,octave){const steps=SCALES[kind];if(!steps||!Number.isInteger(octave)||octave<2||octave>6)throw Error('请选择有效的音阶与八度');const notes=Array.from({length:16},(_,i)=>(octave+1)*12+steps[i%steps.length]+12*Math.floor(i/steps.length));if(notes.some(n=>n<36||n>96))throw Error('音阶超出MIDI 36～96，请降低起始八度');return notes;}
function validateMap(notes){if(!Array.isArray(notes)||notes.length!==32||notes.some(n=>!Number.isInteger(n)||n<36||n>96))throw Error('完整32键必须在MIDI 36～96内，请降低起始八度');if(new Set(notes).size!==32)throw Error('32键需要32个不同音高，请避免两块键盘音域重叠');return notes;}
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
