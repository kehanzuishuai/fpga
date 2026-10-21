const assert=require('assert');
const {parseScoreFile,splitScore,scoreText}=require('../shouji/score.js');
const enc=new TextEncoder();
const json=x=>enc.encode(JSON.stringify(x));
const score=parseScoreFile(json({name:'测试',bpm:120,events:[[60,100,500],[0,0,250]]}));
assert.deepStrictEqual(splitScore(score)[0],[[60,100,500],[0,0,250]]);
assert.strictEqual(scoreText(splitScore(score)[0]),'60,100,500\n0,0,250\n');
assert.strictEqual(splitScore(parseScoreFile(json({bpm:120,events:Array.from({length:65},()=>[60,100,500])}))).length,3);
for(const x of [{bpm:0,events:[[60,1,1]]},{bpm:120,events:[]},{bpm:120,events:[[60,100,0]]},{bpm:120,events:[[1,100,500]]}])assert.throws(()=>parseScoreFile(json(x)));
assert.throws(()=>parseScoreFile(new Uint8Array(65537)));
// Hand-authored SMF0, PPQN96, one quarter note C4 followed by D4 with running status.
const be32=n=>[(n>>>24)&255,(n>>>16)&255,(n>>>8)&255,n&255];
function midi(track,format=0,division=96){return new Uint8Array([77,84,104,100,0,0,0,6,0,format,0,1,division>>8,division&255,77,84,114,107,...be32(track.length),...track]);}
const bytes=midi([0,255,81,3,7,161,32,0,144,60,100,96,60,0,0,144,62,100,96,128,62,0,0,255,47,0]);
const mid=parseScoreFile(bytes);assert.strictEqual(mid.bpm,120);assert.deepStrictEqual(splitScore(mid)[0],[[60,100,500],[62,100,500]]);
const chord=midi([0,144,60,100,0,144,64,100,96,128,60,0,0,128,64,0,0,255,47,0]);
assert.throws(()=>splitScore(parseScoreFile(chord)),/和弦/);
assert.throws(()=>parseScoreFile(bytes.slice(0,-1)),/不完整/);
assert.throws(()=>parseScoreFile(midi([0,255,47,0],2)),/格式/);
assert.throws(()=>parseScoreFile(midi([0,255,47,0],0,0xe728)),/PPQN/);
assert.throws(()=>parseScoreFile(midi([0,144,60,100,0,255,47,0])),/松开/);
console.log('PASS MIDI/JSON: running status, beat timing, rest, segments, bounds, polyphony, malformed files and dangling notes');

const fs=require('fs');if(fs.existsSync('sim/out/online_sample.mid')){const online=parseScoreFile(fs.readFileSync('sim/out/online_sample.mid'));assert(splitScore(online).length>0);console.log('PASS downloaded real HTTPS MIDI sample');}
