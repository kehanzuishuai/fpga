'use strict';
const fs=require('fs'),path=require('path'),crypto=require('crypto'),assert=require('assert');
const branch=path.resolve(__dirname,'..'),workspace=branch;
const scoring=require(path.join(branch,'firmware/remote_music_ble/shouji/score.js'));
const input=path.join(branch,'scores/卡农_多旋律_音域适配.mid');
const output=path.join(branch,'scores/卡农_最新ESP32_20261103');
const audit=path.join(workspace,'build/canon_esp32_20261103');
fs.mkdirSync(output,{recursive:true});fs.mkdirSync(audit,{recursive:true});
const digest=b=>crypto.createHash('sha256').update(b).digest('hex');
const sourceBytes=fs.readFileSync(input),source=scoring.parseScoreFile(sourceBytes);
const ppqn=source.groups[0].ppqn,bpm=source.bpm;
assert(source.groups.every(g=>g.ppqn===ppqn));
function vlq(value){assert(Number.isInteger(value)&&value>=0&&value<=0x0fffffff);const b=[value&127];while(value=Math.floor(value/128))b.unshift((value&127)|128);return Buffer.from(b);}
function meta(type,value){const bytes=Buffer.from(value);return Buffer.concat([Buffer.from([255,type]),vlq(bytes.length),bytes]);}
function track(events){
 events.sort((a,b)=>a.tick-b.tick||a.order-b.order||a.note-b.note);
 let previous=0;const parts=[];
 for(const event of events){parts.push(vlq(event.tick-previous),event.bytes);previous=event.tick;}
 parts.push(Buffer.from([0,255,47,0]));const data=Buffer.concat(parts),header=Buffer.alloc(8);
 header.write('MTrk');header.writeUInt32BE(data.length,4);return Buffer.concat([header,data]);
}
const tempo=Math.round(60000000/bpm),lastTick=Math.max(...source.groups.flatMap(g=>g.notes.map(n=>n.end)));
const conductor=track([
 {tick:0,order:0,note:0,bytes:meta(3,Buffer.from('Canon in D - ESP32 V21 20261103'))},
 {tick:0,order:1,note:0,bytes:meta(81,Buffer.from([tempo>>16,(tempo>>8)&255,tempo&255]))},
 {tick:0,order:2,note:0,bytes:meta(88,Buffer.from([4,2,24,8]))},
 {tick:0,order:3,note:0,bytes:meta(89,Buffer.from([2,0]))},
 {tick:lastTick,order:4,note:0,bytes:meta(1,Buffer.from('End'))}
]);
const names=['低音一','高音旋律','分解和弦','低音二','主旋律','中音对位','副旋律'];
const tracks=source.groups.map((group,index)=>{
 assert(index<9);const channel=index;
 const events=[{tick:0,order:-2,note:0,bytes:meta(3,Buffer.from(`${String(index+1).padStart(2,'0')} ${names[index]||group.name}`))}];
 for(const n of group.notes){
  assert(n.end>n.start&&n.note>=36&&n.note<=96&&n.velocity>0&&n.velocity<=127);
  events.push({tick:n.start,order:1,note:n.note,bytes:Buffer.from([0x90|channel,n.note,n.velocity])});
  events.push({tick:n.end,order:0,note:n.note,bytes:Buffer.from([0x80|channel,n.note,0])});
 }
 return track(events);
});
const header=Buffer.alloc(14);header.write('MThd');header.writeUInt32BE(6,4);header.writeUInt16BE(1,8);header.writeUInt16BE(tracks.length+1,10);header.writeUInt16BE(ppqn,12);
const bytes=Buffer.concat([header,conductor,...tracks]);assert(bytes.length<=65536);
const parsed=scoring.parseScoreFile(bytes),timeline=scoring.timelineScore(parsed,-1),expected=scoring.timelineScore(source,-1);
assert.deepStrictEqual(timeline,expected);assert.equal(parsed.groups.length,7);
for(let i=0;i<source.groups.length;i++){
 const sorted=g=>[...g.notes].sort((a,b)=>a.start-b.start||a.end-b.end||a.note-b.note);
 assert.deepStrictEqual(sorted(parsed.groups[i]),sorted(source.groups[i]));
}
const name='卡农_多音轨_20261103.mid';fs.writeFileSync(path.join(output,name),bytes);
fs.writeFileSync(path.join(audit,'timeline.txt'),scoring.streamText(timeline.events));
fs.writeFileSync(path.join(audit,'events.hex'),timeline.events.map(([t,n,v])=>((BigInt(t)<<16n)|(BigInt(v)<<8n)|BigInt(n)).toString(16).padStart(12,'0')).join('\n')+'\n');
const notes=parsed.groups.flatMap(g=>g.notes);
const info={file:name,sha256:digest(bytes),bytes:bytes.length,midi_format:1,midi_tracks:tracks.length+1,musical_tracks:tracks.length,ppqn,bpm,
 duration_ms_at_bpm:Math.round(timeline.events.at(-1)[0]*120/bpm),source_notes:notes.length,fpga_events:timeline.events.length,
 max_simultaneous_pitches:timeline.maxVoices,min_note:Math.min(...notes.map(n=>n.note)),max_note:Math.max(...notes.map(n=>n.note)),
 stream_body_bytes:Buffer.byteLength(scoring.streamText(timeline.events)),same_note_overlap_handling:'Latest phone timelineScore reference counts; shared pitches are merged',
 firmware_id:'v21-autoplay-confirm-20261103',parser_source_sha256:digest(fs.readFileSync(path.join(branch,'firmware/remote_music_ble/shouji/score.js'))),
 source_file:path.relative(workspace,input),source_sha256:digest(sourceBytes),source_url:'https://www.pachelbelcanon.com/pachelbel-canon-files/category/1-pachelbel-canon.html?download=4%3Acanonstr.mid',
 normalization:'Retain all seven sounding tracks, notes, timing, velocity and initial tempo; write one tempo track and remove unused MIDI data',
 note_and_timeline_preservation:'PASS',phone_import_parser:'PASS',esp32_stream_parser:'PENDING',phone_import_upload_play_stop:'PENDING',fpga_stream_rtl:'PENDING',hardware_tested:false};
assert(info.stream_body_bytes<=768*1024&&info.fpga_events<=32768&&info.max_simultaneous_pitches<=32);
fs.writeFileSync(path.join(audit,'generation.json'),JSON.stringify(info,null,2)+'\n');
console.log(JSON.stringify({output:path.join(output,name),...info},null,2));
