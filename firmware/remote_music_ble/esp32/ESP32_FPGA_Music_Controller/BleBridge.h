#pragma once
// BLE bridge for the phone app (C:/fpga/piano_app/BLE_PROTOCOL.md, v1).
// Requests arrive as text lines on the RX characteristic; the FPGA worker task
// (deviceWorker) calls Ble::service() whenever it has no HTTP job, so Music::Link
// stays owned by that one task. Responses and events leave as JSON lines on TX.
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <freertos/FreeRTOS.h>
#include <freertos/queue.h>
#include "ControlLink.h"

namespace Ble {
static const char *SERVICE_UUID="6b1f0001-2a4c-4d8e-9f31-7c5e2026a0f1";
static const char *RX_UUID="6b1f0002-2a4c-4d8e-9f31-7c5e2026a0f1";
static const char *TX_UUID="6b1f0003-2a4c-4d8e-9f31-7c5e2026a0f1";
static const char *FW="xdzy-ble-1";
struct Line{uint16_t length;bool overflow;char text[1025];};

QueueHandle_t lines=nullptr;
BLECharacteristic *tx=nullptr;
volatile bool connected=false;
volatile uint16_t mtu=23;
// RX assembly (BLE host task only)
char rxText[1025];uint16_t rxLength=0;bool rxOverflow=false;
// Worker-task state
bool recording=false,overflowSent=false,lastFpga=false,fpgaKnown=false;
uint32_t recTime=0,lastPoll=0,batchStart=0;uint16_t recLast=0;
String batch;uint8_t batchCount=0;

class ServerCallbacks:public BLEServerCallbacks{
  void onConnect(BLEServer *)override{connected=true;}
  void onDisconnect(BLEServer *)override{connected=false;mtu=23;BLEDevice::startAdvertising();}
  // Core 3.3.10 builds the ESP32-S3 BLE library on NimBLE; keep both stacks.
#if defined(CONFIG_NIMBLE_ENABLED)
  void onMtuChanged(BLEServer *,ble_gap_conn_desc *,uint16_t value)override{mtu=value;}
#else
  void onMtuChanged(BLEServer *,esp_ble_gatts_cb_param_t *param)override{mtu=param->mtu.mtu;}
#endif
};
class RxCallbacks:public BLECharacteristicCallbacks{
  void onWrite(BLECharacteristic *c)override{
    String v=c->getValue();
    for(size_t i=0;i<v.length();i++){
      const char ch=v[i];
      if(ch=='\n'){
        Line line;line.length=rxLength;line.overflow=rxOverflow;memcpy(line.text,rxText,rxLength);line.text[rxLength]=0;
        xQueueSend(lines,&line,0);rxLength=0;rxOverflow=false;
      }else if(rxLength<1024)rxText[rxLength++]=ch;
      else rxOverflow=true;
    }
  }
};

void send(const String &json){
  if(!connected||!tx)return;
  const String s=json+"\n";
  size_t chunk=mtu>23?size_t(mtu-3):20;if(chunk>244)chunk=244;
  for(size_t i=0;i<s.length();i+=chunk){
    const size_t n=min(chunk,size_t(s.length()-i));
    tx->setValue((uint8_t *)(s.c_str()+i),n);tx->notify();delay(3);
  }
}
const char *code(const Music::Link &link){
  switch(link.error){
    case Music::Error::Timeout:return "timeout";
    case Music::Error::Rejected:return link.remoteStatus==2?"unsupported":"rejected";
    case Music::Error::WrongDevice:return "wrong_device";
    case Music::Error::Fault:return "fault";
    case Music::Error::NotApplied:return "not_applied";
    case Music::Error::Invalid:return "invalid";
    case Music::Error::StateInvalid:return "state_invalid";
    case Music::Error::WrongMode:return "wrong_mode";
    default:return "rejected";
  }
}
String head(unsigned id,bool ok){return String("{\"id\":")+id+",\"ok\":"+(ok?"true":"false");}
void fail(unsigned id,const char *err,const char *msg){send(head(id,false)+",\"err\":\""+err+"\",\"msg\":\""+msg+"\"}");}
void failLink(unsigned id,Music::Link &link){fail(id,code(link),Music::message(link.error));}
// Unsigned decimal, at most max; advances p.
bool num(const char *&p,unsigned max,unsigned &v){
  if(*p<'0'||*p>'9')return false;v=0;
  while(*p>='0'&&*p<='9'){v=v*10+unsigned(*p++-'0');if(v>max)return false;}return true;
}
String notesJson(const uint8_t *notes,uint16_t revision){
  String s=",\"notes\":[";for(int i=0;i<32;i++){if(i)s+=",";s+=notes[i];}s+="],\"revision\":";s+=revision;return s;
}
void startRecording(){recording=true;overflowSent=false;recTime=0;recLast=0;batch="";batchCount=0;lastPoll=0;}
void flush(){
  if(!batchCount)return;
  send(String("{\"ev\":\"rec\",\"e\":[")+batch+"]}");batch="";batchCount=0;
}
void advance(uint16_t ms){recTime+=uint16_t(ms-recLast);recLast=ms;}
// Drain up to 8 events per call; an empty reply also carries the current time.
void poll(Music::Link &link){
  for(int k=0;k<8;k++){
    uint32_t w;if(!link.recRead(w))return;
    if(!(w>>31)){
      advance(uint16_t(w));
      if((w>>30)&1){if(!overflowSent){overflowSent=true;send("{\"ev\":\"rec_overflow\"}");}}
      return;
    }
    advance(uint16_t(w));
    if(!batchCount)batchStart=millis();
    if(batchCount)batch+=",";
    batch+="[";batch+=recTime;batch+=",";batch+=unsigned((w>>23)&127);batch+=",";batch+=unsigned((w>>16)&127);batch+=",";batch+=unsigned((w>>30)&1);batch+="]";
    if(++batchCount>=20)flush();
  }
}
void handle(Music::Link &link,const Line &line){
  unsigned id=0;const char *p=line.text;
  if(line.overflow){fail(0,"too_long","请求过长");return;}
  if(!num(p,65535,id)||*p++!=' '){fail(id,"bad_request","请求格式无效");return;}
  const char *op=p;while(*p&&*p!=' ')p++;
  const String name(op,p-op);if(*p==' ')p++;
  if(name=="hello"){
    if(link.handshake())send(head(id,true)+",\"proto\":1,\"fw\":\""+FW+"\",\"fpga\":true}");
    else send(head(id,false)+",\"err\":\""+code(link)+"\",\"msg\":\""+Music::message(link.error)+"\",\"proto\":1,\"fw\":\""+FW+"\",\"fpga\":false}");
  }else if(name=="status"){
    if(!link.fullState()){failLink(id,link);return;}
    const Music::State s=link.state;
    const bool perf=link.readPerformance();
    String r=head(id,true);
    r+=",\"mode\":";r+=s.mode;r+=",\"timbre\":";r+=s.timbre;
    r+=",\"switching\":";r+=s.switching?"true":"false";r+=",\"fault\":";r+=s.fault?"true":"false";
    r+=",\"effects\":";r+=s.effects;r+=",\"volume\":";r+=unsigned((uint32_t(s.volume)*100+32767)/65535);
    r+=",\"tempo\":";r+=s.tempo;
    r+=",\"score\":{\"count\":";r+=s.count;r+=",\"playing\":";r+=s.playing?"true":"false";r+=",\"revision\":";r+=s.revision;r+="}";
    r+=",\"performance\":{\"supported\":";r+=(perf&&link.performanceSupported)?"true":"false";
    r+=",\"mode\":";r+=link.performanceMode;r+=",\"state\":";r+=link.performanceState;r+="}";
    r+=",\"recording\":";r+=recording?"true":"false";r+="}";send(r);
  }else if(name=="set"){
    const char *k=p;while(*p&&*p!=' ')p++;const String key(k,p-k);unsigned v;
    if(*p++!=' '||!num(p,65535,v)||*p){fail(id,"invalid","参数无效");return;}
    bool ok;
    if(key=="timbre"&&v<=4)ok=link.set(0x11,uint8_t(v));
    else if(key=="volume"&&v<=100)ok=link.setSetting(0x12,uint16_t((v*65535U+50)/100));
    else if(key=="tempo"&&v>=30&&v<=240)ok=link.setSetting(0x14,uint16_t(v));
    else if(key=="performance"&&v<=2)ok=link.setPerformance(uint8_t(v));
    else if(key=="mode"&&v==0)ok=link.set(0x10,0);
    else{fail(id,"invalid","参数无效");return;}
    if(ok)send(head(id,true)+"}");else failLink(id,link);
  }else if(name=="score"){
    Music::Event events[32];uint8_t count=0;
    while(*p){
      unsigned n,v,d;
      if(count==32||!num(p,127,n)||*p++!=','||!num(p,127,v)||*p++!=','||!num(p,65535,d)||(*p&&*p!=';')){fail(id,"invalid","曲谱格式无效");return;}
      if(*p==';')p++;
      events[count++]={uint8_t(n),uint8_t(v),uint16_t(d)};
    }
    if(!count){fail(id,"invalid","曲谱格式无效");return;}
    if(link.upload(events,count)){String r=head(id,true)+",\"count\":";r+=link.state.count;r+=",\"revision\":";r+=link.state.revision;r+="}";send(r);}
    else failLink(id,link);
  }else if(name=="play"){
    unsigned v;if(!num(p,1,v)||*p){fail(id,"invalid","参数无效");return;}
    if(link.play(v!=0))send(head(id,true)+"}");else failLink(id,link);
  }else if(name=="keymap_get"){
    uint8_t notes[32];uint16_t revision;
    if(link.keymap(notes,revision))send(head(id,true)+notesJson(notes,revision)+"}");else failLink(id,link);
  }else if(name=="keymap_set"){
    uint8_t notes[32];
    for(int i=0;i<32;i++){unsigned v;if(!num(p,96,v)||v<36||(i<31?*p++!=',':*p!=0)){fail(id,"invalid","键位格式无效");return;}notes[i]=uint8_t(v);}
    uint16_t revision;
    if(link.uploadKeymap(notes,revision))send(head(id,true)+notesJson(notes,revision)+"}");else failLink(id,link);
  }else if(name=="rec"){
    unsigned v;if(!num(p,1,v)||*p){fail(id,"invalid","参数无效");return;}
    if(!link.recEnable(v!=0)){failLink(id,link);return;}
    if(v)startRecording();else{flush();recording=false;}
    send(head(id,true)+",\"recording\":"+(v?"true":"false")+"}");
  }else fail(id,"bad_request","未知请求");
}
// Called by the FPGA worker task when it has no HTTP job.
void service(Music::Link &link){
  Line line;
  if(lines&&xQueueReceive(lines,&line,0)==pdTRUE)handle(link,line);
  if(recording&&!connected){link.recEnable(false);recording=false;batch="";batchCount=0;}
  if(recording&&uint32_t(millis()-lastPoll)>=15){lastPoll=millis();poll(link);}
  if(recording&&batchCount&&uint32_t(millis()-batchStart)>=100)flush();
  if(connected&&(!fpgaKnown||link.uartConnected!=lastFpga)){
    fpgaKnown=true;lastFpga=link.uartConnected;send(String("{\"ev\":\"link\",\"fpga\":")+(lastFpga?"true":"false")+"}");
  }
  if(!connected)fpgaKnown=false;
}
void setup(){
  lines=xQueueCreate(4,sizeof(Line));
  BLEDevice::init("XDZY-Piano");BLEDevice::setMTU(247);
  BLEServer *server=BLEDevice::createServer();server->setCallbacks(new ServerCallbacks());
  BLEService *svc=server->createService(SERVICE_UUID);
  BLECharacteristic *rx=svc->createCharacteristic(RX_UUID,BLECharacteristic::PROPERTY_WRITE|BLECharacteristic::PROPERTY_WRITE_NR);
  rx->setCallbacks(new RxCallbacks());
  tx=svc->createCharacteristic(TX_UUID,BLECharacteristic::PROPERTY_NOTIFY);tx->addDescriptor(new BLE2902());
  svc->start();
  BLEAdvertising *adv=BLEDevice::getAdvertising();adv->addServiceUUID(SERVICE_UUID);adv->setScanResponse(true);
  BLEDevice::startAdvertising();
}
}
