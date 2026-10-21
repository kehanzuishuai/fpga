'use strict';
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
