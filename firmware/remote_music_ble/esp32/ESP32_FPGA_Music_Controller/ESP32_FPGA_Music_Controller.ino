#include <Arduino.h>
#include <WiFi.h>
#include <WebServer.h>
#include <esp_system.h>
#include <HTTPClient.h>
#include <NetworkClientSecure.h>
// Arduino-ESP32 3.3.10 embeds the configured full CA bundle in libmbedtls.
extern const uint8_t ca_bundle_start[] asm("_binary_x509_crt_bundle_start");
extern const uint8_t ca_bundle_end[] asm("_binary_x509_crt_bundle_end");
#include <time.h>
#include <memory>
#include <freertos/FreeRTOS.h>
#include <freertos/queue.h>
#include <freertos/semphr.h>
#include "ControlLink.h"
#include "FpgaUart.h"
#include "web_page.h"
#include "BleBridge.h"
#include "StreamScore.h"
#include <esp_heap_caps.h>

WebServer server(80);
static const char *FIRMWARE_ID="v21-autoplay-confirm-20261103";
FpgaUart uart(Serial1);
Music::Link *fpgaLink=nullptr;

// Only the existing UART worker reads/writes this state and the FPGA link.
Music::StreamEvent *streamEvents=nullptr;uint32_t streamCount=0,streamCursor=0;
bool streamFeeding=false,streamSealed=false,streamError=false;
Music::Link::StreamStatus streamSnapshot;
bool fillStream(unsigned limit){
 if(!fpgaLink->streamStatus(streamSnapshot))return false;
 if(streamSnapshot.fault){streamError=true;return false;}
 if(streamSnapshot.finished){streamFeeding=false;return true;}
 unsigned free=256-streamSnapshot.queued;
 while(free && limit && streamCursor<streamCount){
  const auto &e=streamEvents[streamCursor];if(!fpgaLink->streamPush(e.time,e.note,e.velocity))return false;
  streamCursor++;free--;limit--;
 }
 if(streamCursor==streamCount&&!streamSealed){if(!fpgaLink->streamSeal())return false;streamSealed=true;}
 return true;
}
bool prepareStream(){
 if(!streamEvents || !fpgaLink->streamBegin())return false;
 streamFeeding=false;streamSealed=false;streamError=false;streamCursor=0;
 if(!fillStream(256))return false;
 return fpgaLink->streamStatus(streamSnapshot) && streamSnapshot.loaded && !streamSnapshot.fault && streamSnapshot.queued>0;
}
String responseBody(bool ok) {
  auto &s=fpgaLink->state;
  String body="{\"ok\":";body+=ok?"true":"false";
  body+=",\"uartConnected\":";body+=fpgaLink->uartConnected?"true":"false";
  body+=",\"message\":\"";
  if(fpgaLink->error==Music::Error::Timeout) {
    body+=fpgaLink->diagnostics.requestRxBytes==0?
      "串口已发送，但本次未收到FPGA返回字节；操作结果未知":
      "收到串口字节，但没有匹配的有效应答，请核对FPGA版本及串口参数；操作结果未知";
  }else body+=Music::message(fpgaLink->error);
  body+="\",\"stateValid\":";body+=s.valid?"true":"false";
  if(s.valid) {
    body+=",\"mode\":";body+=s.mode;body+=",\"timbre\":";body+=s.timbre;
    body+=",\"switching\":";body+=s.switching?"true":"false";
    body+=",\"fault\":";body+=s.fault?"true":"false";
  }
  body+=",\"settingsValid\":";body+=s.settingsValid?"true":"false";
  if(s.settingsValid){body+=",\"volume\":";body+=unsigned((uint32_t(s.volume)*100+32767)/65535);body+=",\"tempo\":";body+=s.tempo;}
  body+=",\"scoreValid\":";body+=s.scoreValid?"true":"false";
  if(s.scoreValid){body+=",\"scoreCount\":";body+=s.count;body+=",\"playing\":";body+=s.playing?"true":"false";body+=",\"scoreRevision\":";body+=s.revision;}
  body+=",\"streamLoaded\":";body+=streamEvents?"true":"false";
  body+=",\"streamPlaying\":";body+=streamFeeding?"true":"false";
  body+=",\"expressionVelocity\":";body+=unsigned(fpgaLink->state.expressionVelocity);
  body+=",\"expressionGlide\":";body+=unsigned(fpgaLink->state.expressionGlide);
  body+=",\"expressionVibrato\":";body+=unsigned(fpgaLink->state.expressionVibrato);
  body+=",\"expressionValid\":";body+=fpgaLink->state.expressionValid?"true":"false";
  body+=",\"performanceMode\":";body+=unsigned(fpgaLink->performanceMode);
  body+=",\"streamFault\":";body+=(streamError||streamSnapshot.fault)?"true":"false";
  body+=",\"streamFaultCode\":";body+=streamSnapshot.faultCode;
  body+=",\"streamEvents\":";body+=streamCount;
  body+=",\"streamSent\":";body+=streamCursor;
  body+="}";return body;
}
void bad(const char *text,int status=400) {
  server.send(status,"application/json; charset=utf-8",String("{\"ok\":false,\"stateValid\":false,\"message\":\"")+text+"\"}");
}
bool number(const String &s,unsigned max,unsigned &value){
  if(!s.length()||s.length()>5)return false;value=0;
  for(size_t i=0;i<s.length();i++){if(s[i]<'0'||s[i]>'9')return false;value=value*10+unsigned(s[i]-'0');if(value>max)return false;}return true;
}
// Only this worker owns Music::Link. The HTTP loop never waits for UART.
enum class JobKind:uint8_t {Status,Control,ReadKeys,WriteKeys,WriteScore,ReadPerformance,WritePerformance,WriteStream};
struct DeviceJob{JobKind kind=JobKind::Status;uint16_t id=0,value=0;uint8_t cmd=0,count=0,notes[32]{};Music::Event events[32]{};Music::StreamEvent *stream=nullptr;uint32_t streamCount=0;};
QueueHandle_t deviceQueue=nullptr;SemaphoreHandle_t jobMutex=nullptr;
bool workerReady=false,jobRunning=false;uint16_t jobId=0;String jobBody,jobDiagnostic;int jobStatus=503;
String hexFrame(const uint8_t *data) {
 const char digits[]="0123456789abcdef";char out[33];
 for(int i=0;i<16;i++){out[i*2]=digits[data[i]>>4];out[i*2+1]=digits[data[i]&15];}
 out[32]=0;return String(out);
}
// Called only by setup before the worker exists, or by the UART worker itself.
// HTTP reads a completed snapshot under jobMutex instead of racing live counters.
String captureDiagnostics() {
 const auto &d=fpgaLink->diagnostics;
 String s="{\"firmware\":\"";s+=FIRMWARE_ID;
 s+="\",\"profile\":\"ESP32-S3-DevKitC-1-N32R16V\",\"uartReady\":";s+=uart.ready()?"true":"false";
 s+=",\"txPin\":17,\"rxPin\":18,\"baud\":115200,\"format\":\"8N1\",\"updatedMs\":";s+=millis();
 s+=",\"flashBytes\":";s+=ESP.getFlashChipSize();s+=",\"psramBytes\":";s+=ESP.getPsramSize();
 s+=",\"rxBufferBytes\":";s+=unsigned(uart.rxBufferBytes);
 s+=",\"txBytes\":";s+=uart.txBytes;s+=",\"shortWrites\":";s+=uart.shortWrites;
 s+=",\"rxBytes\":";s+=d.rxBytes;s+=",\"validFrames\":";s+=d.validFrames;
 s+=",\"invalidFrames\":";s+=d.invalidFrames;s+=",\"ignoredFrames\":";s+=d.ignoredFrames;
 s+=",\"txPackets\":";s+=d.txPackets;s+=",\"timeouts\":";s+=d.timeouts;s+=",\"retries\":";s+=d.retries;
 s+=",\"requestRxBytes\":";s+=d.requestRxBytes;s+=",\"requestValidFrames\":";s+=d.requestValidFrames;
 s+=",\"lastCommand\":";s+=unsigned(d.lastCommand);s+=",\"lastSequence\":";s+=unsigned(d.lastSequence);
 s+=",\"lastTx\":\"";s+=hexFrame(d.lastTx);s+="\",\"lastRx\":\"";s+=hexFrame(d.lastRx);s+="\"}";
 return s;
}
void diagnosticsStatus() {
 String snapshot;
 if(jobMutex){xSemaphoreTake(jobMutex,portMAX_DELAY);snapshot=jobDiagnostic;xSemaphoreGive(jobMutex);}
 else snapshot=jobDiagnostic;
 server.sendHeader("Cache-Control","no-store");
 server.send(200,"application/json; charset=utf-8",String("{\"workerReady\":")+
   (workerReady?"true":"false")+",\"diagnostics\":"+snapshot+"}");
}
String keymapBody(const uint8_t *notes,uint16_t revision){
 String s="{\"ok\":true,\"uartConnected\":true,\"revision\":";s+=revision;s+=",\"notes\":[";
 for(int i=0;i<32;i++){if(i)s+=",";s+=notes[i];}s+="]}";return s;
}
void deviceWorker(void*){
 DeviceJob job;
 for(;;){
  // No HTTP job within 5 ms: serve the phone app over BLE (same task owns the FPGA link).
  if(xQueueReceive(deviceQueue,&job,pdMS_TO_TICKS(1))!=pdTRUE){
   if(streamFeeding){if(!fillStream(16)){streamError=true;streamFeeding=false;fpgaLink->play(false);}}
   else Ble::service(*fpgaLink);continue;
  }
  bool ok=false;uint8_t notes[32]{};uint16_t revision=0;
  switch(job.kind){
   case JobKind::Status:ok=fpgaLink->fullState();break;
   case JobKind::Control:
    if(job.cmd==0x12||job.cmd==0x14)ok=fpgaLink->setSetting(job.cmd,job.value);
    else if(job.cmd==0x15){
      if(job.value && streamEvents){
       ok=fpgaLink->readPerformance()&&fpgaLink->fullState();
       if(ok && fpgaLink->performanceMode!=2){
        // Repeated Play is idempotent; never stop feeding an active timeline.
        if(!fpgaLink->state.playing){ok=prepareStream()&&fpgaLink->play(true);streamFeeding=ok;}
       }else if(ok)ok=fpgaLink->play(true);
      }else {if(!job.value)streamFeeding=false;ok=fpgaLink->play(job.value!=0);}
    }
    else if(job.cmd>=0x18&&job.cmd<=0x1a)ok=fpgaLink->setExpression(uint8_t(job.cmd-0x18),uint8_t(job.value));
    else ok=fpgaLink->set(job.cmd,uint8_t(job.value));
    if(ok&&job.cmd>=0x18&&job.cmd<=0x1a){fpgaLink->state.expressionValid=true;if(job.cmd==0x18)fpgaLink->state.expressionVelocity=uint8_t(job.value);if(job.cmd==0x19)fpgaLink->state.expressionGlide=uint8_t(job.value);if(job.cmd==0x1a)fpgaLink->state.expressionVibrato=uint8_t(job.value);}
    break;
   case JobKind::ReadKeys:ok=fpgaLink->keymap(notes,revision);break;
   case JobKind::WriteKeys:ok=fpgaLink->uploadKeymap(job.notes,revision);if(ok)memcpy(notes,job.notes,32);break;
   case JobKind::WriteScore:ok=fpgaLink->upload(job.events,job.count);
    if(ok){free(streamEvents);streamEvents=nullptr;streamCount=0;streamCursor=0;streamFeeding=false;streamError=false;streamSnapshot={};}break;
   case JobKind::WriteStream:
    if(fpgaLink->fullState() && !fpgaLink->state.playing && !fpgaLink->state.switching && fpgaLink->readPerformance() && fpgaLink->performanceMode!=2){
     free(streamEvents);streamEvents=job.stream;job.stream=nullptr;streamCount=job.streamCount;ok=prepareStream()&&fpgaLink->fullState();
     if(!ok){free(streamEvents);streamEvents=nullptr;streamCount=0;streamError=true;}
    }else fpgaLink->error=Music::Error::Rejected;
    free(job.stream);break;
   case JobKind::ReadPerformance:ok=fpgaLink->readPerformance();break;
   case JobKind::WritePerformance:ok=fpgaLink->setPerformance(uint8_t(job.value));break;
  }
  String result=ok&&(job.kind==JobKind::ReadKeys||job.kind==JobKind::WriteKeys)?keymapBody(notes,revision):responseBody(ok);
  int code=ok?200:(fpgaLink->error==Music::Error::Invalid?400:503);
  if(job.kind==JobKind::ReadPerformance||job.kind==JobKind::WritePerformance){
   const bool unsupported=fpgaLink->error==Music::Error::Rejected&&fpgaLink->remoteStatus==2;
   if(unsupported)code=501;
   result=String("{\"ok\":")+(ok?"true":"false")+",\"supported\":"+
    (fpgaLink->performanceSupported&&!unsupported?"true":"false")+",\"mode\":"+
    (fpgaLink->performanceSupported&&!unsupported?String(fpgaLink->performanceMode):String("null"))+
    ",\"state\":"+String(fpgaLink->performanceState)+",\"message\":\""+Music::message(fpgaLink->error)+"\"}";
  }
  const String snapshot=captureDiagnostics();
  result.remove(result.length()-1);result+=",\"diagnostics\":";result+=snapshot;result+="}";
  Serial.printf("[FPGA] job=%u ok=%u error=%u tx=%lu rx=%lu frames=%lu\n",job.id,unsigned(ok),unsigned(fpgaLink->error),
    (unsigned long)uart.txBytes,(unsigned long)fpgaLink->diagnostics.rxBytes,(unsigned long)fpgaLink->diagnostics.validFrames);
  xSemaphoreTake(jobMutex,portMAX_DELAY);jobBody=result;jobDiagnostic=snapshot;jobStatus=code;jobRunning=false;xSemaphoreGive(jobMutex);
 }
}
void submitJob(DeviceJob job);
void submitJob(DeviceJob job){
 if(!workerReady){free(job.stream);bad("ESP32串口后台任务未启动，尚未向FPGA发送请求",503);return;}
 xSemaphoreTake(jobMutex,portMAX_DELAY);
 if(jobRunning){free(job.stream);xSemaphoreGive(jobMutex);server.send(503,"application/json","{\"ok\":false,\"jobBusy\":true,\"message\":\"设备忙\"}");return;}
 jobId=uint16_t(jobId+1);if(!jobId)jobId=1;job.id=jobId;jobRunning=true;jobBody="";
 if(xQueueSend(deviceQueue,&job,0)!=pdTRUE){free(job.stream);jobRunning=false;xSemaphoreGive(jobMutex);bad("设备队列忙",503);return;}
 xSemaphoreGive(jobMutex);server.sendHeader("Cache-Control","no-store");server.send(202,"application/json",String("{\"pending\":true,\"job\":")+job.id+"}");
}
void pollJob(){
 unsigned requested;if(!number(server.arg("id"),65535,requested)){bad("任务编号无效");return;}
 if(!workerReady){bad("设备服务未启动",503);return;}
 xSemaphoreTake(jobMutex,portMAX_DELAY);
 const uint16_t current=jobId;const bool running=jobRunning;const String result=jobBody;const int code=jobStatus;
 xSemaphoreGive(jobMutex);
 server.sendHeader("Cache-Control","no-store");
 if(requested!=current){bad("任务结果已过期，操作结果未知，请刷新设备状态",409);return;}
 if(running)server.send(202,"application/json",String("{\"pending\":true,\"job\":")+current+"}");
 else server.send(code,"application/json; charset=utf-8",result);
}
void control(){
 const String kind=server.arg("kind");unsigned v;
 if(!number(server.arg("value"),65535,v)){bad("参数无效");return;}
 DeviceJob job;job.kind=JobKind::Control;job.value=uint16_t(v);
 if(kind=="mode"&&v<=2)job.cmd=0x10;
 else if(kind=="timbre"&&v<=4)job.cmd=0x11;
 else if(kind=="volume"&&v<=100){job.cmd=0x12;job.value=uint16_t((v*65535U+50)/100);}
 else if(kind=="tempo"&&v>=30&&v<=240)job.cmd=0x14;
 else if(kind=="play"&&v<=1)job.cmd=0x15;
 else{bad("参数无效");return;}submitJob(job);
}
void expression(){
  const String kind=server.arg("kind");unsigned value;
  if(!number(server.arg("value"),100,value)){bad("演奏表现参数无效");return;}
  uint8_t which=kind=="expressionVelocity"?0:kind=="expressionGlide"?1:kind=="expressionVibrato"?2:255;
  if(which==255){bad("演奏表现参数无效");return;}
  DeviceJob job;job.kind=JobKind::Control;job.cmd=uint8_t(0x18+which);job.value=uint16_t(value);submitJob(job);
}
void readKeymap(){DeviceJob job;job.kind=JobKind::ReadKeys;submitJob(job);}
void writeKeymap(){
 const String text=server.arg("plain");DeviceJob job;job.kind=JobKind::WriteKeys;size_t pos=0;
 for(int i=0;i<32;i++){
  const int end=text.indexOf('\n',pos);const size_t last=end<0?text.length():size_t(end);unsigned value;
  if(pos>=text.length()||!number(text.substring(pos,last),96,value)||value<36){bad("键位格式无效");return;}
  job.notes[i]=uint8_t(value);pos=last+(end<0?0:1);
 }
 if(pos!=text.length()){bad("键位数量必须为32");return;}
 for(int i=0;i<32;i++)for(int j=i+1;j<32;j++)if(job.notes[i]==job.notes[j]){bad("32键需要32个不同音高");return;}
 submitJob(job);
}
void uploadScore(){
 const String text=server.arg("plain");DeviceJob job;job.kind=JobKind::WriteScore;
 if(text.length()>2048||!Music::parseScore(text.c_str(),text.length(),job.events,job.count)){bad("曲谱格式无效");return;}submitJob(job);
}
void uploadStream(){
 const String body=server.arg("plain");
 if(!body.length()||body.length()>768*1024){bad("整曲数据为空或超过768KB");return;}
 uint32_t capacity=0;for(size_t i=0;i<body.length();i++)if(body[i]=='\n')capacity++;
 if(body[body.length()-1]!='\n')capacity++;
 if(!capacity||capacity>32768){bad("整曲最多32768个起音/松音事件");return;}
 auto *events=static_cast<Music::StreamEvent*>(heap_caps_malloc(capacity*sizeof(Music::StreamEvent),MALLOC_CAP_SPIRAM|MALLOC_CAP_8BIT));
 if(!events){bad("整曲缓存分配失败，请检查PSRAM配置",503);return;}
 uint32_t count=0;
 if(!Music::parseStream(body.c_str(),body.length(),events,capacity,count)){free(events);bad("整曲事件无效：请检查音域、时间顺序、独立松音及最多32个同时音符");return;}
 DeviceJob job;job.kind=JobKind::WriteStream;job.stream=events;job.streamCount=count;submitJob(job);
}
class DownloadSink:public Stream{
 public:uint8_t *data;size_t length=0;bool overflow=false;uint32_t started=millis();
 explicit DownloadSink(uint8_t *p):data(p){}
 size_t write(uint8_t b) override{return write(&b,1);}
 size_t write(const uint8_t *b,size_t n) override{if(length+n>65536||uint32_t(millis()-started)>15000){overflow=true;return 0;}memcpy(data+length,b,n);length+=n;return n;}
 int available() override{return 0;}int read() override{return -1;}int peek() override{return -1;}void flush() override{}
};
void downloadScore(){
  if(WiFi.status()!=WL_CONNECTED){bad("ESP32尚未连接能上网的Wi-Fi",503);return;}
  if(time(nullptr)<1700000000){bad("正在联网校时，请稍后再下载",503);return;}
  const String url=server.arg("url");
  if(url.length()>512||!url.startsWith("https://")||url.indexOf('\r')>=0||url.indexOf('\n')>=0){bad("请输入HTTPS文件直链");return;}
  std::unique_ptr<uint8_t[]> buffer(new(std::nothrow) uint8_t[65536]);
  if(!buffer){bad("下载内存不足，请稍后再试",503);return;}
  NetworkClientSecure secure;
  secure.setCACertBundle(ca_bundle_start,size_t(ca_bundle_end-ca_bundle_start));
  secure.setHandshakeTimeout(8);
  HTTPClient http;http.setTimeout(8000);http.setConnectTimeout(8000);http.setFollowRedirects(HTTPC_DISABLE_FOLLOW_REDIRECTS);
  if(!http.begin(secure,url)){bad("无法打开下载地址",502);return;}
  const int status=http.GET();
  if(status!=200){http.end();bad("下载失败，请使用无需登录和跳转的HTTPS文件直链",502);return;}
  if(http.getSize()>65536){http.end();bad("文件超过64KB");return;}
  DownloadSink sink(buffer.get());const int result=http.writeToStream(&sink);http.end();
  if(result<0||sink.overflow||!sink.length){bad("下载失败或文件超过64KB",502);return;}
  server.sendHeader("Cache-Control","no-store");server.setContentLength(sink.length);
  server.send(200,"application/octet-stream","");server.sendContent(reinterpret_cast<const char*>(buffer.get()),sink.length);
}
void networkStatus(){
  String s="{\"connected\":";s+=WiFi.status()==WL_CONNECTED?"true":"false";
  s+=",\"clockReady\":";s+=time(nullptr)>=1700000000?"true":"false";s+="}";
  server.sendHeader("Cache-Control","no-store");server.send(200,"application/json",s);
}
void performanceMode(){
 DeviceJob job;job.kind=JobKind::ReadPerformance;
 if(server.method()==HTTP_POST){unsigned mode;if(!number(server.arg("mode"),2,mode)){bad("演奏方式无效");return;}
  job.kind=JobKind::WritePerformance;job.value=uint16_t(mode);}
 submitJob(job);
}

void setup() {
  Serial.begin(115200);
  const bool uartStarted=uart.begin();
  static Music::Link controlLink(uart,uint8_t(esp_random()));fpgaLink=&controlLink;
  jobDiagnostic=captureDiagnostics();
  deviceQueue=xQueueCreate(1,sizeof(DeviceJob));jobMutex=xSemaphoreCreateMutex();
  Ble::setup();
  if(deviceQueue&&jobMutex)workerReady=xTaskCreate(deviceWorker,"fpga_uart",8192,nullptr,1,nullptr)==pdPASS;
  Serial.printf("[FPGA] firmware=%s uart=%u worker=%u TX=17 RX=18 baud=115200 flash=%lu psram=%lu\n",
    FIRMWARE_ID,unsigned(uartStarted),unsigned(workerReady),(unsigned long)ESP.getFlashChipSize(),(unsigned long)ESP.getPsramSize());
  WiFi.persistent(false);WiFi.mode(WIFI_AP_STA);
  configTime(0,0,"pool.ntp.org","time.cloudflare.com");
  if(!WiFi.softAP("FPGA_MUSIC","fpga2026",1,0,1)){Serial.println("Wi-Fi启动失败");return;}
  server.on("/",HTTP_GET,[]{server.send_P(200,"text/html; charset=utf-8",PAGE);});
  server.on("/device-api.js",HTTP_GET,[]{server.send_P(200,"application/javascript; charset=utf-8",DEVICE_API_JS);});
  server.on("/api/job",HTTP_GET,pollJob);
  server.on("/api/diagnostics",HTTP_GET,diagnosticsStatus);
  server.on("/api/performance",HTTP_GET,performanceMode);
  server.on("/api/performance",HTTP_POST,performanceMode);
  server.on("/navigation.js",HTTP_GET,[]{server.send_P(200,"application/javascript; charset=utf-8",NAV_JS);});
  server.on("/ui-text.js",HTTP_GET,[]{server.send_P(200,"application/javascript; charset=utf-8",UI_TEXT_JS);});
  server.on("/ui.css",HTTP_GET,[]{server.send_P(200,"text/css; charset=utf-8",UI_CSS);});
  server.on("/keymap",HTTP_GET,[]{server.send_P(200,"text/html; charset=utf-8",KEYMAP_PAGE);});
  server.on("/keymap.js",HTTP_GET,[]{server.send_P(200,"application/javascript; charset=utf-8",KEYMAP_JS);});
  server.on("/api/keymap",HTTP_GET,readKeymap);
  server.on("/api/keymap",HTTP_POST,writeKeymap);
  server.on("/app.js",HTTP_GET,[]{server.send_P(200,"application/javascript; charset=utf-8",APP_JS);});
  server.on("/api/status",HTTP_GET,[]{DeviceJob job;job.kind=JobKind::Status;submitJob(job);});
  server.on("/score.js",HTTP_GET,[]{server.send_P(200,"application/javascript; charset=utf-8",SCORE_JS);});
  server.on("/api/control",HTTP_POST,control);
  server.on("/api/expression",HTTP_POST,expression);
  server.on("/api/score",HTTP_POST,uploadScore);
  server.on("/api/stream",HTTP_POST,uploadStream);
  server.on("/api/download",HTTP_POST,downloadScore);
  server.on("/api/network",HTTP_GET,networkStatus);
  server.on("/api/network",HTTP_POST,[]{
    String ssid=server.arg("ssid"),password=server.arg("password");
    if(ssid.length()<1||ssid.length()>32||password.length()>63){bad("Wi-Fi名称或密码长度不正确");return;}
    WiFi.begin(ssid.c_str(),password.c_str());
    server.send(202,"application/json; charset=utf-8","{\"ok\":true,\"message\":\"正在连接，控制热点仍保留；如手机掉线请重新连接\"}");
  });
  // Compatibility with the user's original buttons. Explicit mapping, never c-'1'.
  server.on("/cmd",HTTP_GET,[]{
    String c=server.arg("c");
    if(c=="P"||c=="S"){DeviceJob job;job.kind=JobKind::Control;job.cmd=0x15;job.value=c=="P";submitJob(job);return;}
    if(c.length()!=1||c[0]<'1'||c[0]>'5'){bad("无效命令");return;}
    const uint8_t map[5]={0,3,1,2,4};DeviceJob job;job.kind=JobKind::Control;job.cmd=0x11;job.value=map[c[0]-'1'];submitJob(job);
  });
  server.onNotFound([]{bad("没有这个接口",404);});server.begin();
  Serial.print("控制页面：http://");Serial.println(WiFi.softAPIP());
}
void loop(){server.handleClient();}
