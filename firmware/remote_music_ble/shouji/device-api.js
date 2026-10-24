 'use strict';
// A 202 only acknowledges a queued job. Success still comes from its final device result.
async function deviceJSON(fetchFn,url,options={},wait=ms=>new Promise(resolve=>setTimeout(resolve,ms))){
 const started=Date.now();let response,data;
 const check=()=>{if(options.signal&&options.signal.aborted)throw Error('请求已取消，操作结果未知');if(Date.now()-started>30000)throw Error('设备等待超时，操作结果未知');};
 do{check();response=await fetchFn(url,options);data=await response.json();if(data.jobBusy===true)await wait(80);}while(data.jobBusy===true);
 if(response.status!==202||data.pending!==true)return {response,data};
 const job=data.job;if(!Number.isInteger(job)||job<1||job>65535)throw Error('设备任务编号无效');
 while(response.status===202&&data.pending===true){check();await wait(35);check();response=await fetchFn('/api/job?id='+job,{cache:'no-store',signal:options.signal});data=await response.json();}
 return {response,data};
}
if(typeof module!=='undefined')module.exports={deviceJSON};
