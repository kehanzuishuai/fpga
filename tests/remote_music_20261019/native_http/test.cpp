// Actual production WavService, with HTTP callback/queue/hardware boundaries
// mocked. This checks binary bodies and transaction semantics, not RF/network.
#include <cstdint>
#include <cstring>
#include <cstdlib>
#include <cassert>
#include <string>
#include <vector>
#include <deque>
#include <map>
#include <set>
#include <functional>
#include <iostream>
struct String {
 std::string s;String(){}String(const char *p):s(p){}String(std::string p):s(p){}
 size_t length()const{return s.size();}char operator[](size_t i)const{return s[i];}
 const char *c_str()const{return s.c_str();}bool startsWith(const char *p)const{return s.compare(0,strlen(p),p)==0;}
 String &operator+=(const char *p){s+=p;return *this;}
 template<class T>String &operator+=(T n){s+=std::to_string(n);return *this;}
};
enum HTTPRawStatus{RAW_START,RAW_WRITE,RAW_END,RAW_ABORTED};
struct HTTPRaw {HTTPRawStatus status;size_t currentSize=0,totalSize=0;uint8_t buf[1436];};
enum {HTTP_GET,HTTP_POST};
struct FakeServer {
 struct Route{std::function<void()> fn,raw;};std::map<std::string,Route> routes;
 std::map<std::string,String> args,headers;std::set<std::string> collected;
 HTTPRaw input;int length=0,code=0,rawAccesses=0;String reply;
 String arg(const char *k){return args[k];}String header(const char *k){return headers[k];}
 int clientContentLength(){return length;}HTTPRaw &raw(){rawAccesses++;return input;}
 void sendHeader(const char*,const char*){}void send(int c,const char*,String b){code=c;reply=b;}
 void collectHeaders(const char **p,size_t n){for(size_t i=0;i<n;i++)collected.insert(p[i]);}
 void on(const char *p,int,std::function<void()> fn,std::function<void()> raw={}){routes[p]={fn,raw};}
} server;
void bad(const char *message,int code=400){server.send(code,"application/json",message);}
struct Queue {size_t count,bytes;std::deque<std::vector<uint8_t>> items;};
using QueueHandle_t=Queue*;using SemaphoreHandle_t=int*;
enum {pdTRUE=1,pdFALSE=0,pdPASS=1,OUTPUT=1,HIGH=1,LOW=0};
const unsigned portMAX_DELAY=~0U;
QueueHandle_t xQueueCreate(size_t n,size_t b){return new Queue{n,b,{}};}
SemaphoreHandle_t xSemaphoreCreateMutex(){static int mutex;return &mutex;}
void xSemaphoreTake(SemaphoreHandle_t,unsigned){}void xSemaphoreGive(SemaphoreHandle_t){}
int xQueueSend(QueueHandle_t q,const void *p,unsigned){if(q->items.size()==q->count)return pdFALSE;const auto b=static_cast<const uint8_t*>(p);q->items.emplace_back(b,b+q->bytes);return pdTRUE;}
int xQueueReceive(QueueHandle_t,void*,unsigned){return pdFALSE;}
void xQueueReset(QueueHandle_t q){q->items.clear();}
unsigned pdMS_TO_TICKS(unsigned n){return n;}
int xTaskCreate(void(*)(void*),const char*,unsigned,void*,unsigned,void*){return pdPASS;}
void pinMode(int,int){}void digitalWrite(int,int){}void delayMicroseconds(unsigned){}
uint32_t fakeTime=0;void delay(unsigned n){fakeTime+=n;}uint32_t millis(){return fakeTime;}uint32_t esp_random(){return 17;}
#include "../../../firmware/remote_music/esp32/ESP32_FPGA_Music_Controller/WavService.h"
using namespace WavService;
void upload(uint32_t id,uint32_t offset,const std::vector<uint8_t>& data,int declared=-1,bool abort=false,bool metadata=true){
 server.args.clear(); // Real core RAW path does not parse URL query arguments.
 server.headers={{"Content-Type","application/octet-stream"}};
 if(metadata){server.headers["X-WAV-Session"]=String(std::to_string(id));server.headers["X-WAV-Offset"]=String(std::to_string(offset));}
 server.length=declared<0?int(data.size()):declared;auto &r=server.routes.at("/api/wav/chunk");assert(bool(r.raw));
 server.input.status=RAW_START;r.raw();
 for(size_t p=0;p<data.size();){size_t n=std::min(data.size()-p,size_t(137));
  server.input.status=RAW_WRITE;server.input.currentSize=n;memcpy(server.input.buf,data.data()+p,n);r.raw();p+=n;}
 server.input.status=abort?RAW_ABORTED:RAW_END;r.raw();r.fn();
}
void queuedEquals(const std::vector<uint8_t>& bytes){
 assert(!queue->items.empty());Block b;memcpy(&b,queue->items.back().data(),sizeof(b));
 assert(b.length==bytes.size()&&!b.end&&memcmp(b.data,bytes.data(),bytes.size())==0);
}
int main(){
 setup();assert(ready&&server.collected.count("X-WAV-Session")&&server.collected.count("X-WAV-Offset")&&server.collected.count("Content-Type"));
 session=Session{};session.id=17;session.size=CHUNK*3+17;session.active=true;session.started=true;
 std::vector<uint8_t> bytes(CHUNK);for(size_t i=0;i<bytes.size();i++)bytes[i]=uint8_t(i*73);
 assert(bytes[0]==0&&bytes[256]==0&&strlen(reinterpret_cast<const char*>(bytes.data()))==0);
 upload(17,0,bytes);assert(server.code==202&&session.accepted==CHUNK);queuedEquals(bytes);
 upload(17,0,bytes);assert(server.code==200&&session.accepted==CHUNK&&queue->items.size()==1);
 auto changed=bytes;changed[100]^=1;upload(17,0,changed);assert(server.code==409&&queue->items.size()==1);
 upload(17,CHUNK,bytes);assert(server.code==202&&queue->items.size()==2);queuedEquals(bytes);
 upload(17,CHUNK*2,bytes);assert(server.code==503&&session.accepted==CHUNK*2);
 queue->items.pop_front();upload(17,CHUNK*2,bytes);assert(server.code==202&&session.accepted==CHUNK*3);queuedEquals(bytes);
 const auto accepted=session.accepted;const auto count=queue->items.size();
 upload(17,accepted,{0,1,0},4);assert(server.code==400&&session.accepted==accepted&&queue->items.size()==count);
 upload(17,accepted,{0,1,0},3,true);assert(server.code==400&&session.accepted==accepted);
 upload(17,accepted,std::vector<uint8_t>(CHUNK+1,0));assert(server.code==400&&session.accepted==accepted);
 upload(17,accepted,{0,1,0},-1,false,false);assert(server.code==400&&session.accepted==accepted);
 upload(16,accepted,{0,1,0});assert(server.code==409&&session.accepted==accepted);
 int accesses=server.rawAccesses;server.headers["Content-Type"]="multipart/form-data";server.routes.at("/api/wav/chunk").raw();
 assert(server.rawAccesses==accesses);server.routes.at("/api/wav/chunk").fn();assert(server.code==400);
 queue->items.clear();std::vector<uint8_t> tail(17,0);upload(17,accepted,tail);assert(server.code==202);queuedEquals(tail);
 server.args={{"session","17"},{"offset",String(std::to_string(session.size))}};server.routes.at("/api/wav/end").fn();
 assert(server.code==202&&session.ended&&queue->items.size()==2);
 server.routes.at("/api/wav/end").fn();assert(server.code==200&&queue->items.size()==2);
 std::cout<<"PASS actual WavService RAW callbacks: 8192-byte NUL/all-byte bodies exact, header metadata without query args, duplicate/CRC/queue backpressure, overflow/truncation/abort/multipart/stale-session rejection and END retries\n";
}
