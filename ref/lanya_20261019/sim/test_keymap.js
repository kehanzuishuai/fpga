 'use strict';
const assert=require('assert');const {defaultMap,presetMap,validateMap,noteName,createKeymapClient,KEY_LAYOUT,changedIndices,createKeymapDraft}=require('../shouji/keymap.js');
(async()=>{
 assert.equal(KEY_LAYOUT.length,16);assert.equal(KEY_LAYOUT.filter(k=>k.kind==='white').length,9);assert.equal(KEY_LAYOUT.filter(k=>k.kind==='black').length,6);assert.equal(KEY_LAYOUT[15].kind,'extra');
 assert.deepEqual(KEY_LAYOUT.flatMap((k,i)=>k.kind==='white'?[i+1]:[]),[1,3,5,6,8,10,12,13,15]);
 const notes=defaultMap();assert.equal(notes.length,32);assert.equal(notes[0],60);assert.equal(notes[16],72);assert.equal(notes[31],87);
 assert.deepEqual(presetMap('major',3).slice(0,8),[48,50,52,53,55,57,59,60]);assert.deepEqual(presetMap('pentatonic',2).slice(0,6),[36,38,40,43,45,48]);
 assert.throws(()=>presetMap('pentatonic',6));assert.throws(()=>validateMap(notes.slice(0,16)));assert.equal(noteName(60),'C4');
 const changed=[...notes];changed[31]=36;assert.deepEqual(changedIndices(changed,notes),[31]);assert.deepEqual(changedIndices(notes,notes),[]);
 const draft=createKeymapDraft();assert.equal(draft.notes.length,32);assert(!draft.dirty());assert(!draft.connected);
 const before=draft.generation;draft.change(n=>n[31]=36);draft.receive({notes:defaultMap()},before);assert.equal(draft.notes[31],36);assert(draft.connected&&draft.dirty());
 const applied=draft.generation;draft.receive({notes:[...draft.notes]},applied);assert(!draft.dirty());
 const snapshot=[...draft.notes],generation=draft.generation;draft.change(n=>n[0]=40);draft.receive({notes:snapshot},generation);assert.equal(draft.notes[0],40);assert(draft.dirty());
 assert.throws(()=>draft.change(n=>n[0]=0));assert.equal(draft.notes[0],40);
 let sent;const client=createKeymapClient(async(url,opts)=>{sent=opts;return {ok:true,json:async()=>({ok:true,notes,revision:1})};});
 assert.equal((await client('POST',notes)).revision,1);assert.equal(sent.body.split('\n').filter(Boolean).length,32);
 const mismatch=createKeymapClient(async()=>({ok:true,json:async()=>({ok:true,notes:notes.map(()=>36),revision:2})}));await assert.rejects(()=>mismatch('POST',notes),/回读不一致/);
 const noFPGA=createKeymapClient(async()=>({ok:false,json:async()=>({ok:false,uartConnected:false,message:'未应答'})}));try{await noFPGA('GET');assert.fail();}catch(e){assert(e.reached&&!e.uart);}
 const offline=createKeymapClient(async()=>{throw Error('offline');});try{await offline('GET');assert.fail();}catch(e){assert.equal(e.reached,false);}
 console.log('PASS 32-key defaults/presets/range, complete upload, readback mismatch, ESP32 reachable with FPGA absent, offline');
})().catch(e=>{console.error(e);process.exit(1);});
