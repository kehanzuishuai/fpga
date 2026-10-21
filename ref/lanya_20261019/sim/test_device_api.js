 'use strict';
const assert=require('assert');const {deviceJSON}=require('../shouji/device-api.js');
(async()=>{
 const calls=[],responses=[{status:202,ok:true,data:{pending:true,job:7}},{status:202,ok:true,data:{pending:true,job:7}},{status:200,ok:true,data:{ok:true,stateValid:true}}];
 const reply=async(url,options)=>{calls.push([url,options]);const r=responses.shift();return {...r,json:async()=>r.data};};
 const result=await deviceJSON(reply,'/api/control',{method:'POST',body:'kind=timbre&value=1'},async()=>{});
 assert(result.data.ok);assert.deepEqual(calls.map(c=>c[0]),['/api/control','/api/job?id=7','/api/job?id=7']);assert.equal(calls.filter(c=>c[1].method==='POST').length,1);
 let count=0;const busy=await deviceJSON(async()=>{count++;return {status:count===1?503:200,ok:count!==1,json:async()=>count===1?{jobBusy:true}:{ok:true}};},'/api/control',{method:'POST'},async()=>{});assert(busy.data.ok&&count===2);
 const failed=await deviceJSON(async url=>({status:url.includes('/api/job')?503:202,ok:false,json:async()=>url.includes('/api/job')?{ok:false,message:'未应答'}:{pending:true,job:8}}),'/api/control',{},async()=>{});assert(!failed.data.ok);
 const aborted=new AbortController();aborted.abort();await assert.rejects(()=>deviceJSON(reply,'/api/status',{signal:aborted.signal}),/取消/);
 console.log('PASS asynchronous HTTP job polling: no duplicate command, busy-before-accept retry, final failure, abort');
})().catch(e=>{console.error(e);process.exit(1);});
