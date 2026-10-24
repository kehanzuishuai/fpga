 'use strict';
// Presentation only. Detailed transport errors stay available in the collapsed panel.
function noticeText(text){
 if(/FPGA未应答|无法访问 ESP32|FPGA 已连接|正在读取状态|已读取当前映射/.test(text))return '';
 if(/下载失败|下载内存不足/.test(text))return '下载失败';
 if(/FPGA报告故障/.test(text))return '设备故障';
 if(/完整32键|MIDI.*范围|起始八度/.test(text))return '音符超出范围';
 if(/正在等待 FPGA/.test(text))return '正在应用…';
 if(/音量已生效|速度已生效|提交并回读确认/.test(text))return '已应用';
 if(/切换完成/.test(text))return '已切换';
 if(/曲谱已传入/.test(text))return '已传输';
 if(/已保存到页面草稿/.test(text))return '已保存';
 if(/尚未生效|尚未确认|协议|FPGA拒绝|FPGA拒绝了|读取失败|响应异常|状态无效/.test(text))return '操作未完成';
 return text;
}
function showNotice(text,shortText){
 const notice=document.getElementById('message'),detail=document.getElementById('debugInfo');
 if(detail)detail.textContent=text;const value=shortText===undefined?noticeText(text):shortText;
 notice.textContent=value;notice.hidden=!value;
}
function showConnections(wifi,uart){
 const w=document.getElementById('wifiLink'),u=document.getElementById('uartLink');
 if(wifi!==null){w.textContent=wifi?'Wi-Fi 已连接':'Wi-Fi 未连接';w.dataset.state=wifi?'connected':'error';}
 u.textContent=wifi===false?'FPGA 状态未知':uart==='connected'?'FPGA 已连接':uart==='waiting'?'FPGA 连接中…':'FPGA 未连接';u.dataset.state=wifi===false?'unknown':uart;
}
if(typeof module!=='undefined')module.exports={noticeText};
