'use strict';
const assert=require('node:assert/strict'),fs=require('fs'),path=require('path');
const b=path.resolve(__dirname,'..'),s=require(b+'/firmware/remote_music_ble/shouji/score.js');
function input(notes){return {groups:[{name:'piano',ppqn:500,notes}],bpm:120};}
const chord=input([{note:60,velocity:100,start:0,end:500},{note:64,velocity:90,start:0,end:300},{note:67,velocity:80,start:0,end:700}]);
assert.throws(()=>s.splitScore(chord),/和弦/);
assert.deepEqual(s.timelineScore(chord).events,[[0,60,100],[0,64,90],[0,67,80],[300,64,0],[500,60,0],[700,67,0]]);
const dup=input([{note:60,velocity:100,start:0,end:300},{note:60,velocity:90,start:100,end:500}]);
assert.deepEqual(s.timelineScore(dup).events,[[0,60,100],[500,60,0]]);
const repeat=input([{note:60,velocity:100,start:0,end:100},{note:60,velocity:90,start:100,end:200}]);
assert.deepEqual(s.timelineScore(repeat).events,[[0,60,100],[100,60,0],[100,60,90],[200,60,0]]);
assert.throws(()=>s.timelineScore(input(Array.from({length:33},(_,i)=>({note:36+i,velocity:100,start:0,end:100})))),/32/);
assert.throws(()=>s.timelineScore(input([{note:22,velocity:100,start:0,end:100}])),/36/);
const file=path.resolve(b,'scores/卡农_原版全声部.mid'),canon=s.parseScoreFile(new Uint8Array(fs.readFileSync(file)));
const whole=s.timelineScore(canon),part=s.timelineScore(canon,0);
assert(whole.maxVoices>1);assert(whole.events.length>part.events.length);assert(whole.events.at(-1)[0]>200000);
console.log('PASS simultaneous chord, independent offs, shared-pitch reference counts, reattack order, max32/range rejection, legacy guidance rejects chords unchanged');
console.log('CANON',JSON.stringify({wholeEvents:whole.events.length,maxVoices:whole.maxVoices,baseDurationMs:whole.events.at(-1)[0],singleTrackEvents:part.events.length}));
