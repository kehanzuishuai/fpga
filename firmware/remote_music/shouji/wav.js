'use strict';
// File bytes remain unchanged. The browser only checks the header early;
// the FPGA independently validates RIFF, decodes PCM and resamples to 48 kHz.
async function inspectWav(file){
 if(!file||file.size<44||file.size>0xffffffff)throw Error('请选择有效的WAV文件');
 const bytes=new Uint8Array(await file.slice(0,Math.min(file.size,1048576)).arrayBuffer());
 const v=new DataView(bytes.buffer),text=(p,n)=>String.fromCharCode(...bytes.slice(p,p+n));
 if(text(0,4)!=='RIFF'||text(8,4)!=='WAVE'||v.getUint32(4,true)+8!==file.size)throw Error('需要标准RIFF/WAVE文件');
 let format=null;
 for(let p=12;p+8<=bytes.length;){
  const id=text(p,4),size=v.getUint32(p+4,true),end=p+8+size;
  if(end+(size&1)>file.size)throw Error('WAV块长度超出文件');
  if(id==='fmt '){
   if(size<16||p+24>bytes.length)throw Error('WAV格式块无效');
   const code=v.getUint16(p+8,true),channels=v.getUint16(p+10,true),rate=v.getUint32(p+12,true),align=v.getUint16(p+20,true),bits=v.getUint16(p+22,true);
   if(code!==1||![1,2].includes(channels)||![16,24].includes(bits)||![44100,48000].includes(rate)||align!==channels*bits/8||v.getUint32(p+16,true)!==rate*align)throw Error('支持16/24位、单/双声道、44.1/48kHz的PCM WAV');
   format={channels,rate,bits,align};
  }
  if(id==='data'){
   if(!format||!size||size%format.align)throw Error('WAV音频块无效');
   return {...format,seconds:size/format.align/format.rate};
  }
  p=end+(size&1);
 }
 throw Error('前1MB内没有找到WAV格式及音频块');
}
function createWavPlayer(fetchFn,show){
 let generation=0,session=null;
 const sleep=ms=>new Promise(resolve=>setTimeout(resolve,ms));
 async function request(path,options={}){
  const abort=new AbortController(),timer=setTimeout(()=>abort.abort(),12000);
  try{
   const response=await fetchFn(path,{cache:'no-store',...options,signal:abort.signal});
   let data;try{data=await response.json();}catch{throw Error('ESP32响应无效');}
   return {response,data};
  }finally{clearTimeout(timer);}
 }
 async function play(file){
  const token=++generation,format=await inspectWav(file);
  if(token!==generation)return;
  show(`正在连接：${format.rate/1000}kHz · ${format.bits}位 · ${format.channels}声道`);
  let result=await request('/api/wav/start?size='+file.size,{method:'POST'});
  if(!result.response.ok||!result.data.ok)throw Error('WAV服务未启动');
  const id=result.data.session;session=id;let offset=0;
  try{
   const begun=Date.now();
   while(!result.data.started){
    if(token!==generation)return;
    if(Date.now()-begun>5000)throw Error('FPGA的SPI接口未确认，请检查接线');
    await sleep(20);result=await request('/api/wav/status');
    if(result.data.session!==id||!result.data.ok)throw Error('FPGA未接受WAV会话');
   }
   while(offset<file.size){
    if(token!==generation)return;
    const block=await file.slice(offset,offset+8192).arrayBuffer(),begun=Date.now();
    while(true){
     if(token!==generation)return;
     try{result=await request(`/api/wav/chunk?session=${id}&offset=${offset}`,{method:'POST',headers:{'Content-Type':'application/octet-stream','X-WAV-Session':String(id),'X-WAV-Offset':String(offset)},body:block});}
     catch(e){if(Date.now()-begun>5000)throw e;await sleep(20);continue;}
     if(result.data.session!==id||result.data.ok===false||result.data.error)throw Error('FPGA播放失败，错误码 '+result.data.error);
     if(result.response.ok&&result.data.accepted===offset+block.byteLength)break;
     if(result.response.status!==503||Date.now()-begun>5000)throw Error('WAV传输被拒绝，请重新播放');
     await sleep(2);
    }
    offset+=block.byteLength;
    show(`边传边播 ${Math.floor(offset*100/file.size)}% · FPGA已播放 ${(result.data.frames/48000).toFixed(1)}秒`);
   }
   const endStart=Date.now();
   do{
    result=await request(`/api/wav/end?session=${id}&offset=${offset}`,{method:'POST'});
    if(result.response.ok)break;
    if(result.response.status!==503||Date.now()-endStart>5000)throw Error('WAV结束确认失败');await sleep(5);
   }while(token===generation);
   while(token===generation){
    result=await request('/api/wav/status');const s=result.data;
    if(s.session!==id)return;
    if(!s.ok||s.error)throw Error('FPGA播放失败，错误码 '+s.error);
    if(s.state===3){show(`播放完成 · FPGA输出 ${s.frames} 帧`);return;}
    show(`传输完成，FPGA播放中 · ${(s.frames/48000).toFixed(1)}秒`);await sleep(200);
   }
  }catch(e){
   if(token===generation){await request('/api/wav/stop',{method:'POST'}).catch(()=>{});throw e;}
  }
 }
 async function stop(){generation++;session=null;const r=await request('/api/wav/stop',{method:'POST'});show(r.response.ok?'已请求停止':'停止未确认');return r.response.ok;}
 return {play,stop};
}
if(typeof module!=='undefined')module.exports={inspectWav,createWavPlayer};
if(typeof document!=='undefined'){
 const el=id=>document.getElementById(id),player=createWavPlayer(window.fetch.bind(window),s=>el('wavStatus').textContent=s);
 el('wavPlay').onclick=()=>{const file=el('wavFile').files[0];player.play(file).catch(e=>el('wavStatus').textContent=e.message);};
 el('wavStop').onclick=()=>player.stop().catch(e=>el('wavStatus').textContent=e.message);
 el('wavFile').onchange=()=>inspectWav(el('wavFile').files[0]).then(f=>el('wavStatus').textContent=`${f.seconds.toFixed(1)}秒 · ${f.rate/1000}kHz · ${f.bits}位 · ${f.channels}声道`).catch(e=>el('wavStatus').textContent=e.message);
}
