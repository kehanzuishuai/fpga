'use strict';
const assert=require('assert'),fs=require('fs'),path=require('path');
const root=path.resolve(__dirname,'../..'),phone=path.join(root,'firmware/remote_music/shouji');
const {inspectWav,createWavPlayer}=require(path.join(phone,'wav.js'));
const {defaultMap,validateMap}=require(path.join(phone,'keymap.js'));
const {parseScoreFile,splitScore}=require(path.join(phone,'score.js'));
const file=(bytes)=>({size:bytes.length,slice:(a,b)=>({arrayBuffer:async()=>Uint8Array.from(bytes.slice(a,b)).buffer})});
const jsonFile=x=>new TextEncoder().encode(JSON.stringify(x));
const be32=n=>[(n>>>24)&255,(n>>>16)&255,(n>>>8)&255,n&255];
const chunk=(tag,data)=>Buffer.from([...Buffer.from(tag),...be32(data.length),...data]);
const smf=(format,tracks)=>Buffer.concat([chunk('MThd',[0,format,0,tracks.length,1,224]),...tracks.map(t=>chunk('MTrk',t))]);
async function main(){
 assert.deepEqual(defaultMap(),Array.from({length:32},(_,i)=>60+i));
 assert.throws(()=>validateMap(Array(32).fill(60)),/不同/);
 const wav=fs.readFileSync(path.join(__dirname,'out/stereo24_48000.wav'));
 const info=await inspectWav(file(wav));assert.equal(info.bits,24);assert.equal(info.channels,2);assert.equal(info.rate,48000);
 const invalid=Buffer.from(wav);invalid[0]=0;await assert.rejects(()=>inspectWav(file(invalid)),/RIFF/);
 const compressed=Buffer.from(wav),fmt=compressed.indexOf('fmt ');compressed[fmt+8]=3;
 await assert.rejects(()=>inspectWav(file(compressed)),/PCM/);
 assert.deepEqual(splitScore(parseScoreFile(jsonFile({bpm:120,events:[[60,100,500],[0,0,250]]})))[0],[[60,100,500],[0,0,250]]);
 // Real SMF bytes: 480 PPQN, running-status velocity-zero Note Off, a rest,
 // and explicit Note Off. Durations stay normalized to 120 BPM for FPGA tempo.
 const tempo=[0,255,81,3,10,44,42],end=[0,255,47,0];
 const melody=[0,144,60,100,131,96,60,0,129,112,144,62,80,129,112,128,62,0];
 for(const [format,tracks] of [[0,[[...tempo,...melody,...end]]],[1,[[...tempo,...end],[...melody,...end]]]]){
  const score=parseScoreFile(smf(format,tracks));assert.equal(score.bpm,90);assert.equal(score.groups.length,1);
  assert.deepEqual(splitScore(score),[[[60,100,500],[0,0,250],[62,80,250]]]);
 }
 const chord=smf(0,[[0,144,60,100,0,64,100,131,96,128,60,0,0,64,0,...end]]);
 assert.throws(()=>splitScore(parseScoreFile(chord)),/和弦或重叠/);
 assert.throws(()=>parseScoreFile(smf(0,[[0,144,60,100,...end]])),/没有松开/);
 assert.throws(()=>parseScoreFile(smf(0,[[...melody,...end]]).subarray(0,24)),/不完整/);
 assert.deepEqual(splitScore(parseScoreFile(jsonFile({bpm:120,events:Array.from({length:33},()=>[60,100,500])}))).map(p=>p.length),[32,1]);
 let session=20,accepted=0,started=false,ended=false,chunks=[],retries=0,failOnce=true,done=false;
 const reply=(code,data)=>({ok:code>=200&&code<300,status:code,json:async()=>data});
 const status=()=>({ok:true,session,started,accepted,frames:ended?12000:0,state:done?3:1,error:0});
 const fetch=async(url,options={})=>{
  const u=new URL(url,'http://fpga');
  if(u.pathname==='/api/wav/start'){accepted=0;return reply(202,status());}
  if(u.pathname==='/api/wav/status'){started=true;if(ended)done=true;return reply(200,status());}
  if(u.pathname==='/api/wav/chunk'){
   assert.equal(u.searchParams.get('session'),String(session));assert.equal(Number(u.searchParams.get('offset')),accepted);
   if(failOnce){failOnce=false;retries++;return reply(503,status());}
   assert.equal(options.headers['Content-Type'],'application/octet-stream');
   assert.equal(options.headers['X-WAV-Session'],String(session));assert.equal(Number(options.headers['X-WAV-Offset']),accepted);
   chunks.push(Buffer.from(options.body));accepted+=options.body.byteLength;return reply(202,status());
  }
  if(u.pathname==='/api/wav/end'){assert.equal(accepted,wav.length);ended=true;return reply(202,status());}
  if(u.pathname==='/api/wav/stop'){session++;return reply(202,status());}
  throw Error(url);
 };
 const messages=[];await createWavPlayer(fetch,x=>messages.push(x)).play(file(wav));
 assert.equal(retries,1);assert.equal(Buffer.compare(Buffer.concat(chunks),wav),0);
 assert(messages.at(-1).includes('播放完成'));
 assert(fs.readFileSync(path.join(phone,'index.html'),'utf8').includes('wav.js'));
 console.log('PASS phone: WAV format rejection, byte-exact long upload with backpressure, FPGA completion feedback; real SMF0/1 tempo/running-status/rest conversion, chord/truncation rejection, JSON 32-event segmentation and distinct32 defaults');
}
main().catch(e=>{console.error(e);process.exit(1);});
