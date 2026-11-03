'use strict';
const assert=require('assert'),path=require('path');
const phone=process.argv[2]||path.resolve(__dirname,'../firmware/remote_music_ble/shouji');
const {createController}=require(path.join(phone,'app.js'));
const baseline={ok:true,uartConnected:true,stateValid:true,mode:0,timbre:0,switching:false,fault:false,
 settingsValid:true,volume:100,tempo:120,scoreValid:true,scoreCount:4,playing:false,
 streamLoaded:false,streamPlaying:false,performanceMode:1};
async function playCase(name,on,extra,expected,status=200){
 const state={...baseline,...extra},messages=[],links=[];
 const controller=createController(async()=>({status,ok:status>=200&&status<300,json:async()=>state}),
  {busy(){},state(){},data(){},message:s=>messages.push(s),links:(...s)=>links.push(s)});
 const result=await controller.set('play',on);
 assert.strictEqual(result,expected,name+': confirmation');
 assert(!messages.some(s=>s.includes('ESP32响应异常')),name+': valid response must not become a connection error');
 assert.strictEqual(links.at(-1)[1],'connected',name+': UART remains connected');
 if(extra.scoreCount===0&&!extra.streamLoaded&&!extra.fault&&on)
  assert(messages.at(-1).includes('传入设备'),name+': explain import versus transfer');
 return name;
}
(async()=>{
 const names=[];
 names.push(await playCase('legacy play',1,{playing:true},true));
 names.push(await playCase('legacy stop',0,{playing:false},true));
 names.push(await playCase('guidance play',1,{performanceMode:2,playing:true},true));
 names.push(await playCase('guidance stop',0,{performanceMode:2,playing:false},true));
 names.push(await playCase('stream play',1,{streamLoaded:true,streamPlaying:true,scoreCount:0,playing:true},true));
 names.push(await playCase('stream stop',0,{streamLoaded:true,streamPlaying:false,scoreCount:0,playing:false},true));
 names.push(await playCase('play not applied',1,{playing:false},false));
 names.push(await playCase('guidance not running',1,{performanceMode:2,playing:false},false));
 names.push(await playCase('guidance ignores unrelated stream feed',1,{performanceMode:2,playing:false,streamLoaded:true,streamPlaying:true},false));
 names.push(await playCase('empty device score',1,{ok:false,scoreCount:0,playing:false,message:'FPGA拒绝了请求'},false,503));
 names.push(await playCase('unconfirmed empty score',1,{scoreCount:0,playing:false},false));
 names.push(await playCase('device fault preserved',1,{ok:false,scoreCount:0,fault:true,message:'FPGA报告故障'},false,503));
 console.log('PASS actual phone playback confirmation: '+names.join(', '));
})().catch(e=>{console.error(e);process.exitCode=1;});
