"""Local UI preview only: optional offline and delayed asynchronous jobs. No hardware access."""
from http.server import BaseHTTPRequestHandler,HTTPServer
from pathlib import Path
from urllib.parse import urlparse,parse_qs
import json,time,argparse
ROOT=Path(__file__).resolve().parents[1]/'shouji'
class Handler(BaseHTTPRequestHandler):
 notes=[60+i%16+(i//16)*12 for i in range(32)];revision=0;offline=False;online=False;delay=0;job=0;ready=0;result=None;result_code=200
 state=dict(ok=True,uartConnected=True,stateValid=True,mode=0,timbre=0,switching=False,fault=False,settingsValid=True,volume=100,tempo=120,scoreValid=True,scoreCount=0,playing=False)
 def reply(self,obj,code=200):
  body=json.dumps(obj).encode();self.send_response(code);self.send_header('Content-Type','application/json');self.send_header('Cache-Control','no-store');self.end_headers();self.wfile.write(body)
 def device(self,obj,code=200):
  if self.delay<=0:return self.reply(obj,code)
  if time.monotonic()<Handler.ready:return self.reply(dict(jobBusy=True),503)
  Handler.job+=1;Handler.ready=time.monotonic()+self.delay;Handler.result=obj;Handler.result_code=code;self.reply(dict(pending=True,job=Handler.job),202)
 def do_GET(self):
  path=urlparse(self.path).path
  if path=='/api/job':
   identity=int(parse_qs(urlparse(self.path).query).get('id',['0'])[0])
   if identity!=self.job:return self.reply(dict(ok=False,message='任务已过期'),409)
   if time.monotonic()<self.ready:return self.reply(dict(pending=True,job=self.job),202)
   return self.reply(self.result,self.result_code)
  if path in ['/mobile-keymap','/mobile-control']:
   target='/keymap' if path=='/mobile-keymap' else '/'
   body=('<!doctype html><meta charset="utf-8"><title>375px手机预览（模拟数据）</title><body style="margin:0;background:#080e18;display:flex;justify-content:center"><iframe title="375px手机预览" src="'+target+'" style="width:375px;height:100vh;border:0"></iframe>').encode();self.send_response(200);self.send_header('Content-Type','text/html; charset=utf-8');self.end_headers();self.wfile.write(body);return
  if path=='/api/performance':return self.reply(dict(ok=False,supported=False,mode=None,message='待设备接入'),501)
  if path=='/api/keymap':
   if self.offline:return self.device(dict(ok=False,uartConnected=False,stateValid=False,message='FPGA未应答（模拟）'),503)
   return self.device(dict(ok=True,uartConnected=True,notes=self.notes,revision=self.revision))
  if path=='/api/status':return self.device(self.state if self.online else dict(ok=False,uartConnected=False,stateValid=False,message='FPGA未应答（模拟）'),200 if self.online else 503)
  name={'/':'index.html','/keymap':'keymap.html'}.get(path,path.lstrip('/'))
  if name not in ['index.html','app.js','score.js','keymap.html','keymap.js','ui.css','ui-text.js','navigation.js','device-api.js']:return self.reply({},404)
  body=(ROOT/name).read_bytes();self.send_response(200);self.send_header('Content-Type','application/javascript; charset=utf-8' if name.endswith('.js') else ('text/css; charset=utf-8' if name.endswith('.css') else 'text/html; charset=utf-8'));self.end_headers();self.wfile.write(body)
 def do_POST(self):
  body=self.rfile.read(int(self.headers.get('Content-Length',0))).decode()
  if self.path=='/api/performance':
   data=parse_qs(body);value=data.get('mode',[''])[0]
   if value not in ['0','1','2']:return self.reply(dict(ok=False,message='演奏方式无效'),400)
   return self.reply(dict(ok=False,supported=False,mode=None,message='待设备接入'),501)
  if self.delay and time.monotonic()<self.ready:return self.reply(dict(jobBusy=True),503)
  if self.offline or not self.online and self.path!='/api/keymap':return self.device(dict(ok=False,uartConnected=False,stateValid=False,message='FPGA未应答（模拟）'),503)
  if self.path=='/api/keymap':
   notes=list(map(int,body.splitlines()))
   if len(notes)!=32 or any(n<36 or n>96 for n in notes):return self.reply(dict(ok=False),400)
   Handler.notes=notes;Handler.revision+=1;return self.device(dict(ok=True,uartConnected=True,notes=self.notes,revision=self.revision))
  if self.path=='/api/control':
   data=parse_qs(body);kind=data['kind'][0];value=int(data['value'][0]);Handler.state[kind if kind!='play' else 'playing']=value if kind!='play' else bool(value);return self.device(self.state.copy())
  self.reply(dict(ok=False,message='模拟未实现'),503)
if __name__=='__main__':
 parser=argparse.ArgumentParser();parser.add_argument('--offline',action='store_true');parser.add_argument('--online',action='store_true');parser.add_argument('--delay',type=float,default=0);parser.add_argument('--port',type=int,default=8765);args=parser.parse_args();Handler.offline=args.offline;Handler.online=args.online and not args.offline;Handler.delay=args.delay;HTTPServer(('127.0.0.1',args.port),Handler).serve_forever()
