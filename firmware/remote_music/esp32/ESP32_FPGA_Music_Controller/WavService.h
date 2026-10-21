#pragma once
#include <SPI.h>
#include "WavLink.h"

// Only the dedicated SPI task touches SPI. HTTP remains responsive during FIFO
// backpressure, and the independent UART worker can still change master volume.
namespace WavService {
constexpr int CS=10,MOSI_PIN=11,SCK=12,MISO_PIN=13;
constexpr size_t CHUNK=8192;
struct Block {uint32_t generation=0,offset=0;uint16_t length=0;bool end=false;uint8_t data[CHUNK]{};};
struct Session {
 uint32_t id=0,size=0,accepted=0,sent=0,frames=0,lastOffset=0,lastCrc=0;
 uint16_t lastLength=0;
 bool active=false,started=false,ended=false,failed=false;
 uint8_t state=0,error=0,transportError=0;
};
static QueueHandle_t queue=nullptr;static SemaphoreHandle_t mutex=nullptr;
static Session session;static bool ready=false;static uint32_t workerGeneration=0;
static Block httpBlock;static size_t httpReceived=0;
static bool httpValid=false,httpComplete=false;
static SPIClass bus(FSPI);
static uint32_t crc32(const uint8_t *p,size_t n){
 uint32_t c=0xffffffff;while(n--){c^=*p++;for(int k=0;k<8;k++)c=(c>>1)^(0xedb88320U&uint32_t(-int32_t(c&1)));}return ~c;
}
struct Transport:Music::SpiTransport {
 bool ignoreCancel=false;
 void transfer(uint8_t *tx,uint8_t *rx,size_t n) override {
  bus.beginTransaction(SPISettings(4000000,MSBFIRST,SPI_MODE0));
  digitalWrite(CS,LOW);delayMicroseconds(1);bus.transferBytes(tx,rx,n);
  delayMicroseconds(1);digitalWrite(CS,HIGH);delayMicroseconds(1);bus.endTransaction();
 }
 void idle() override {delay(1);}
 uint32_t now() override {return millis();}
 bool cancelled() override {
  if(ignoreCancel)return false;
  xSemaphoreTake(mutex,portMAX_DELAY);bool changed=session.id!=workerGeneration||!session.active;
  xSemaphoreGive(mutex);return changed;
 }
};
static Session snapshot(){Session s;xSemaphoreTake(mutex,portMAX_DELAY);s=session;xSemaphoreGive(mutex);return s;}
static void worker(void*){
 Transport io;Music::WavLink link(io,uint16_t(esp_random()));Block block;
 for(;;){
  Session current=snapshot();
  if(current.id!=workerGeneration){
   io.ignoreCancel=true;link.stop();io.ignoreCancel=false;workerGeneration=current.id;
   if(current.active){
    const bool ok=link.begin(current.size);
    xSemaphoreTake(mutex,portMAX_DELAY);
    if(session.id==workerGeneration){session.started=ok;session.failed=!ok;}
    xSemaphoreGive(mutex);
   }
  }
  if(xQueueReceive(queue,&block,pdMS_TO_TICKS(2))==pdTRUE){
   current=snapshot();
   if(block.generation!=workerGeneration||!current.active||!current.started||current.failed)continue;
   bool ok=true;
   if(block.end)ok=link.end();
   else for(size_t at=0;at<block.length&&ok;at+=1024){
    const uint16_t n=uint16_t(block.length-at>1024?1024:block.length-at);
    ok=link.write(block.data+at,n);
   }
   xSemaphoreTake(mutex,portMAX_DELAY);
   if(session.id==workerGeneration){if(ok&&!block.end)session.sent=block.offset+block.length;if(!ok)session.failed=true;}
   xSemaphoreGive(mutex);
  }
  if(link.poll()){
   xSemaphoreTake(mutex,portMAX_DELAY);
   if(session.id==workerGeneration){
    session.state=link.status.state;session.error=link.status.error;
    session.transportError=link.status.transportError;session.frames=link.status.frames;
    if(session.error)session.failed=true;
   }
   xSemaphoreGive(mutex);
  }
 }
}
static String body(const Session &s){
 String b="{\"ok\":";b+=s.failed?"false":"true";
 b+=",\"session\":";b+=s.id;b+=",\"size\":";b+=s.size;
 b+=",\"accepted\":";b+=s.accepted;b+=",\"sent\":";b+=s.sent;
 b+=",\"started\":";b+=s.started?"true":"false";
 b+=",\"ended\":";b+=s.ended?"true":"false";
 b+=",\"active\":";b+=s.active?"true":"false";
 b+=",\"state\":";b+=s.state;b+=",\"error\":";b+=s.error;
 b+=",\"transportError\":";b+=s.transportError;b+=",\"frames\":";b+=s.frames;b+="}";return b;
}
static bool decimal(const String &s,uint32_t &v){
 if(!s.length()||s.length()>10)return false;uint64_t n=0;
 for(size_t i=0;i<s.length();i++){if(s[i]<'0'||s[i]>'9')return false;n=n*10+unsigned(s[i]-'0');if(n>0xffffffff)return false;}v=uint32_t(n);return true;
}
static void sendStatus(){
 server.sendHeader("Cache-Control","no-store");server.send(200,"application/json",body(snapshot()));
}
static void begin(){
 uint32_t size;
 if(!decimal(server.arg("size"),size)||size<44){bad("WAV文件长度无效");return;}
 if(!ready){bad("SPI服务未启动",503);return;}
 xSemaphoreTake(mutex,portMAX_DELAY);
 uint32_t id=session.id+1;if(!id)id=1;session=Session{};session.id=id;session.size=size;session.active=true;
 xQueueReset(queue);const Session s=session;xSemaphoreGive(mutex);
 server.send(202,"application/json",body(s));
}
static void stop(){
 if(!ready){bad("SPI服务未启动",503);return;}
 xSemaphoreTake(mutex,portMAX_DELAY);session.active=false;session.id++;if(!session.id)session.id=1;
 session.started=false;session.accepted=0;session.sent=0;session.ended=false;xQueueReset(queue);
 const Session s=session;xSemaphoreGive(mutex);server.send(202,"application/json",body(s));
}
// WebServer's arg("plain") constructs String(char*) and truncates at binary
// NUL. Use its length-delimited RAW callbacks, never a text-body conversion.
// This core does not parse query arguments on the RAW path, so chunk metadata
// travels in explicitly collected headers. End/start keep their query API.
static void rawChunk(){
 if(!server.header("Content-Type").startsWith("application/octet-stream")){
  httpValid=false;httpComplete=false;return;
 }
 HTTPRaw &raw=server.raw();
 switch(raw.status){
  case RAW_START:
   httpReceived=0;httpComplete=false;httpBlock.length=0;httpBlock.end=false;
   httpValid=ready && server.clientContentLength()>0 && size_t(server.clientContentLength())<=CHUNK &&
    decimal(server.header("X-WAV-Session"),httpBlock.generation) && decimal(server.header("X-WAV-Offset"),httpBlock.offset);
   break;
  case RAW_WRITE:
   if(httpValid && raw.currentSize<=CHUNK-httpReceived){
    memcpy(httpBlock.data+httpReceived,raw.buf,raw.currentSize);httpReceived+=raw.currentSize;
   }else httpValid=false;
   break;
  case RAW_END:
   httpComplete=httpValid && httpReceived==size_t(server.clientContentLength());
   httpBlock.length=uint16_t(httpReceived);break;
  case RAW_ABORTED:httpValid=false;httpComplete=false;break;
 }
}
static void chunk(bool end){
 Block &b=httpBlock;
 if(end){
  if(!ready||!decimal(server.arg("session"),b.generation)||!decimal(server.arg("offset"),b.offset)){bad("WAV会话无效");return;}
  b.length=0;b.end=true;
 }else if(!httpComplete){bad("WAV二进制分块长度或请求头无效");return;}
 httpComplete=false;
 const uint32_t id=b.generation,offset=b.offset,crc=crc32(b.data,b.length);
 xSemaphoreTake(mutex,portMAX_DELAY);
 int code=202;
 if(id!=session.id||!session.active||session.failed)code=409;
 else if(!end&&offset==session.lastOffset&&b.length==session.lastLength&&crc==session.lastCrc&&offset+b.length==session.accepted){code=200;}
 else if(end&&session.ended&&offset==session.size){code=200;}
 else if(!session.started)code=503;
 else if(session.ended||offset!=session.accepted||uint64_t(offset)+b.length>session.size||(end&&offset!=session.size))code=409;
 else if(xQueueSend(queue,&b,0)!=pdTRUE)code=503;
 else if(end)session.ended=true;
 else{session.lastOffset=offset;session.lastLength=b.length;session.lastCrc=crc;session.accepted+=b.length;}
 const Session s=session;xSemaphoreGive(mutex);
 server.send(code,"application/json",body(s));
}
static void setup(){
 mutex=xSemaphoreCreateMutex();queue=xQueueCreate(2,sizeof(Block));
 pinMode(CS,OUTPUT);digitalWrite(CS,HIGH);bus.begin(SCK,MISO_PIN,MOSI_PIN,CS);
 if(mutex&&queue)ready=xTaskCreate(worker,"fpga_wav",16384,nullptr,2,nullptr)==pdPASS;
 const char *headers[]={"Content-Type","X-WAV-Session","X-WAV-Offset"};server.collectHeaders(headers,3);
 server.on("/api/wav/start",HTTP_POST,begin);server.on("/api/wav/stop",HTTP_POST,stop);
 server.on("/api/wav/chunk",HTTP_POST,[]{chunk(false);},rawChunk);server.on("/api/wav/end",HTTP_POST,[]{chunk(true);});
 server.on("/api/wav/status",HTTP_GET,[]{if(!ready)bad("SPI服务未启动",503);else sendStatus();});
}
}
