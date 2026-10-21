#pragma once
#include <stdint.h>
#include <stddef.h>
#include <string.h>

// Shared by the real Arduino sketch and the native/RTL regression.
namespace Music {
inline uint16_t crc16(const uint8_t *p, size_t n) {
  uint16_t c=0xffff;
  while(n--) { c^=uint16_t(*p++)<<8; for(int i=0;i<8;i++) c=(c&0x8000)?uint16_t((c<<1)^0x1021):uint16_t(c<<1); }
  return c;
}
inline void frame(uint8_t *b,uint8_t seq,uint8_t cmd,const uint8_t *p,uint8_t n) {
  memset(b,0,16);b[0]=0xa5;b[1]=0x5a;b[2]=1;b[3]=seq;b[4]=cmd;b[5]=n;
  if(n)memcpy(b+6,p,n);
  uint16_t c=crc16(b+2,12);b[14]=uint8_t(c);b[15]=uint8_t(c>>8);
}
inline bool valid(const uint8_t *b) {
  if(b[0]!=0xa5||b[1]!=0x5a||b[2]!=1||b[5]>6)return false;
  for(int i=6+b[5];i<14;i++)if(b[i])return false;
  return crc16(b+2,12)==uint16_t(b[14]|uint16_t(b[15])<<8);
}
struct Transport {
  virtual ~Transport()=default;
  virtual uint32_t now()=0;
  virtual void idle()=0;
  virtual void write(const uint8_t *,size_t)=0;
  virtual int read()=0;
};
enum class Error { None,Timeout,Rejected,WrongDevice,Fault,NotApplied,Invalid,StateInvalid,WrongMode };
struct State { uint8_t mode=0,timbre=0,effects=0,count=0;uint16_t commandedVolume=0,volume=0,tempo=120,revision=0;bool switching=false,fault=false,valid=false,settingsValid=false,scoreValid=false,playing=false; };
struct Event {uint8_t note,velocity;uint16_t duration;};
// Validate the entire upload before opening an FPGA transaction. No permissive atoi.
inline bool parseScore(const char *p,size_t n,Event *out,uint8_t &count) {
  count=0;size_t i=0;
  while(i<n){
    if(count==32)return false;
    uint32_t values[3]={};
    for(int k=0;k<3;k++){
      size_t start=i;
      while(i<n&&p[i]>='0'&&p[i]<='9') {values[k]=values[k]*10+uint32_t(p[i++]-'0');if(values[k]>65535)return false;}
      if(i==start)return false;
      if(k<2){if(i==n||p[i++]!=',')return false;}
    }
    if(i<n&&p[i++]!='\n')return false;
    if(values[0]>127||values[1]>127||values[2]==0)return false;
    if(values[1] && (values[0]<36||values[0]>96))return false;
    out[count++]={uint8_t(values[0]),uint8_t(values[1]),uint16_t(values[2])};
  }
  return count>0;
}
class Link {
  Transport &io;uint8_t sequence;uint8_t window[16]{};size_t count=0;
  bool receive(uint8_t *out) {
    int v;
    while((v=io.read())>=0) {
      if(count==16){memmove(window,window+1,15);count=15;}
      window[count++]=uint8_t(v);
      if(count==16 && Music::valid(window)){memcpy(out,window,16);count=0;return true;}
    }
    return false;
  }
public:
  bool uartConnected=false;
  State state;Error error=Error::None;uint8_t remoteStatus=0;
  explicit Link(Transport &t,uint8_t seed=0):io(t),sequence(seed){}
  bool request(uint8_t cmd,const uint8_t *payload,uint8_t length,uint8_t *result,uint32_t timeoutMs=500,int attempts=3) {
    error=Error::None;remoteStatus=0;
    if(length>6){error=Error::Invalid;return false;}
    // One request in flight. Retries reuse the entire packet and sequence.
    // A cached sequence conflict is explicitly rejected without execution; move on once.
    for(int collision=0;collision<2;collision++) {
      uint8_t tx[16],rx[16];const uint8_t seq=sequence++;
      frame(tx,seq,cmd,payload,length);bool conflict=false;
      for(int attempt=0;attempt<attempts && !conflict;attempt++) {
        io.write(tx,16);uint32_t start=io.now();
        while(uint32_t(io.now()-start)<timeoutMs) {
          if(receive(rx) && rx[3]==seq && rx[4]==0x80 && rx[5]==6 && rx[6]==cmd) {
            uartConnected=true;remoteStatus=rx[7];
            if(remoteStatus==4){conflict=true;break;}
            if(remoteStatus){error=Error::Rejected;return false;}
            memcpy(result,rx+8,4);return true;
          }
          io.idle();
        }
      }
      if(!conflict){error=Error::Timeout;uartConnected=false;state.valid=false;return false;}
    }
    error=Error::Rejected;return false;
  }
  bool handshake() {
    state.valid=false;state.settingsValid=false;state.scoreValid=false;
    uint8_t r[4];if(!request(1,nullptr,0,r,100,2))return false;
    const uint8_t magic[4]={0x31,0x30,0x54,0x42};
    if(memcmp(r,magic,4)){error=Error::WrongDevice;uartConnected=false;state.valid=false;return false;}return true;
  }
  bool query() {
    uint8_t r[4];state.valid=false;
    if(!request(2,nullptr,0,r))return false;
    if((r[0]&0x80)||(r[0]&3)>2||((r[0]>>2)&7)>4){error=Error::StateInvalid;return false;}
    state.mode=r[0]&3;state.timbre=(r[0]>>2)&7;state.switching=(r[0]&32)!=0;
    state.fault=(r[0]&64)!=0;state.effects=r[1];state.commandedVolume=uint16_t(r[2]|uint16_t(r[3])<<8);state.valid=true;
    if(state.fault){error=Error::Fault;return false;}return true;
  }
  bool set(uint8_t cmd,uint8_t value) {
    state.valid=false;
    if((cmd!=0x10&&cmd!=0x11)||(cmd==0x10?value>2:value>4)){error=Error::Invalid;return false;}
    if(!handshake())return false;
    uint8_t r[4];if(!request(cmd,&value,1,r))return false;
    // ACK is enqueue-only. Only actual state + completed switching proves success.
    uint32_t start=io.now();
    do {
      if(!query())return false;
      if(!state.switching && (cmd==0x10?state.mode:state.timbre)==value)return true;
      uint32_t pause=io.now();while(uint32_t(io.now()-pause)<30)io.idle();
    }while(uint32_t(io.now()-start)<2000);
    error=Error::NotApplied;return false;
  }
  bool settings(){
    uint8_t r[4];state.settingsValid=false;
    if(!request(3,nullptr,0,r))return false;
    state.volume=uint16_t(r[0]|uint16_t(r[1])<<8);state.tempo=uint16_t(r[2]|uint16_t(r[3])<<8);
    if(state.tempo<30||state.tempo>240){error=Error::StateInvalid;return false;}
    state.settingsValid=true;return true;
  }
  bool scoreState(){
    uint8_t r[4];state.scoreValid=false;
    if(!request(4,nullptr,0,r))return false;
    if(r[0]>32||r[1]>1){error=Error::StateInvalid;return false;}
    state.count=r[0];state.playing=r[1]!=0;state.revision=uint16_t(r[2]|uint16_t(r[3])<<8);state.scoreValid=true;return true;
  }
  bool fullState(){return handshake()&&query()&&settings()&&scoreState();}
  bool setSetting(uint8_t cmd,uint16_t value){
    if((cmd!=0x12&&cmd!=0x14)||(cmd==0x14&&(value<30||value>240))){error=Error::Invalid;return false;}
    if(!handshake())return false;
    uint8_t p[2]={uint8_t(value),uint8_t(value>>8)},r[4];
    if(!request(cmd,p,2,r))return false;
    uint32_t start=io.now();
    do {if(!query()||!settings())return false;
      if((cmd==0x12?state.volume:state.tempo)==value)return true;
      io.idle();
    }while(uint32_t(io.now()-start)<2000);
    error=Error::NotApplied;return false;
  }
  bool upload(const Event *events,uint8_t count){
    if(!count||count>32){error=Error::Invalid;return false;}
    for(int i=0;i<count;i++)if(events[i].duration==0||events[i].note>127||events[i].velocity>127||
      (events[i].velocity&&(events[i].note<36||events[i].note>96))){error=Error::Invalid;return false;}
    if(!handshake()||!query()||!scoreState())return false;
    if(state.playing||state.switching){error=Error::Rejected;return false;}
    uint16_t expected=uint16_t(state.revision+1);uint8_t r[4];
    if(!request(0x30,&count,1,r))return false;
    for(uint8_t i=0;i<count;i++){
      const auto &e=events[i];uint8_t p[5]={i,e.note,e.velocity,uint8_t(e.duration),uint8_t(e.duration>>8)};
      if(!request(0x31,p,5,r))return false; // Staging is never committed on this path.
    }
    if(!request(0x32,nullptr,0,r)||!scoreState())return false;
    if(state.count!=count||state.revision!=expected){error=Error::NotApplied;return false;}return true;
  }
  bool keymap(uint8_t *notes,uint16_t &revision){
    uint8_t r[4];if(!handshake()||!request(5,nullptr,0,r))return false;
    if(r[0]!=32||r[1]!=0){error=Error::StateInvalid;return false;}
    revision=uint16_t(r[2]|uint16_t(r[3])<<8);
    uint8_t snapshot[32];
    for(uint8_t i=0;i<32;i++){
      if(!request(0x24,&i,1,r))return false;
      if(r[0]!=i||r[1]<36||r[1]>96||uint16_t(r[2]|uint16_t(r[3])<<8)!=revision){error=Error::StateInvalid;return false;}
      snapshot[i]=r[1];
    }
    memcpy(notes,snapshot,32);return true;
  }
  bool uploadKeymap(const uint8_t *notes,uint16_t &revision){
    for(int i=0;i<32;i++)if(notes[i]<36||notes[i]>96){error=Error::Invalid;return false;}
    uint8_t old[32],readback[32];uint16_t before;
    if(!query()||!scoreState()||state.switching||state.playing){if(error==Error::None)error=Error::Rejected;return false;}
    if(!keymap(old,before))return false;
    uint8_t r[4];if(!request(0x20,nullptr,0,r))return false;
    for(uint8_t i=0;i<32;i++){uint8_t p[2]={i,notes[i]};if(!request(0x21,p,2,r))return false;}
    if(!request(0x22,nullptr,0,r)||!keymap(readback,revision))return false;
    if(revision!=uint16_t(before+1)||memcmp(notes,readback,32)){error=Error::NotApplied;return false;}
    return true;
  }
  bool play(bool on){
    if(!handshake()||!query())return false;
    if(on&&state.mode==1){error=Error::WrongMode;return false;}
    uint8_t p=on?1:0,r[4];if(!request(0x15,&p,1,r))return false;
    uint32_t start=io.now();
    do{if(!query()||!scoreState())return false;if(state.playing==on)return true;io.idle();}while(uint32_t(io.now()-start)<2000);
    error=Error::NotApplied;return false;
  }
};
inline const char *message(Error e) {
  switch(e) {
    case Error::None:return "已确认";
    case Error::Timeout:return "FPGA未应答，请检查供电、接线、波特率和FPGA程序；操作结果未知";
    case Error::Rejected:return "FPGA拒绝了请求";
    case Error::WrongDevice:return "FPGA协议不匹配";
    case Error::Fault:return "FPGA报告故障";
    case Error::NotApplied:return "FPGA已接收，但尚未生效或已播放结束；请刷新状态，切换音色时请先松开琴键";
    case Error::WrongMode:return "请先切换到琴键或合奏模式，再播放曲谱";
    case Error::StateInvalid:return "FPGA返回的状态无效";
    default:return "参数无效";
  }
}
}
