#pragma once
#include <stdint.h>
#include <stddef.h>
#include <string.h>
#include "ControlLink.h"

namespace Music {
struct WavStatus {
 bool valid=false,busy=false;
 uint16_t next=0,free=0;
 uint8_t transportError=0,state=0,error=0;
 uint32_t received=0,frames=0;
};
struct SpiTransport {
 virtual ~SpiTransport()=default;
 virtual void transfer(uint8_t *tx,uint8_t *rx,size_t n)=0;
 virtual void idle()=0;
 virtual uint32_t now()=0;
 virtual bool cancelled()=0;
};
class WavLink {
 SpiTransport &io;uint16_t sequence;uint8_t packet[1034]{},reply[1034]{};
 static uint16_t u16(const uint8_t *p){return uint16_t(p[0])|uint16_t(p[1])<<8;}
 static uint32_t u32(const uint8_t *p){return uint32_t(u16(p))|uint32_t(u16(p+2))<<16;}
public:
 WavStatus status;
 explicit WavLink(SpiTransport &transport,uint16_t seed):io(transport),sequence(seed){}
 bool poll(){
  uint8_t tx[24]{0x57,0x41,1},rx[24]{};io.transfer(tx,rx,24);
  status.valid=rx[0]==0x57&&rx[1]==0x41&&rx[2]==1&&crc16(rx,22)==u16(rx+22);
  if(!status.valid)return false;
  status.busy=rx[3]&1;status.next=u16(rx+4);status.free=u16(rx+6);
  status.transportError=rx[8];status.state=rx[9];status.error=rx[10];
  status.received=u32(rx+12);status.frames=u32(rx+16);return true;
 }
 bool command(uint8_t cmd,const uint8_t *data,uint16_t size){
  if(size>1024)return false;
  const uint32_t waitStart=io.now();
  while(true){
   if(io.cancelled())return false;
   if(poll()&&!status.busy&&(cmd!=2||status.free>=size))break;
   if(uint32_t(io.now()-waitStart)>10000)return false;io.idle();
  }
  if(cmd==2&&status.error)return false;
  memset(packet,0,8);packet[0]=0x57;packet[1]=0x41;packet[2]=1;packet[3]=cmd;
  packet[4]=uint8_t(sequence);packet[5]=uint8_t(sequence>>8);
  packet[6]=uint8_t(size);packet[7]=uint8_t(size>>8);
  if(size)memcpy(packet+8,data,size);
  const uint16_t crc=crc16(packet,size+8);packet[size+8]=uint8_t(crc);packet[size+9]=uint8_t(crc>>8);
  for(int attempt=0;attempt<4;attempt++){
   if(io.cancelled())return false;
   io.transfer(packet,reply,size+10);
   const uint32_t begun=io.now();
   do{
    if(poll()&&status.next==uint16_t(sequence+1)&&status.transportError==0){sequence++;return true;}
    if(io.cancelled())return false;
    io.idle();
   }while(uint32_t(io.now()-begun)<30);
  }
  return false;
 }
 bool begin(uint32_t bytes){uint8_t p[4]={uint8_t(bytes),uint8_t(bytes>>8),uint8_t(bytes>>16),uint8_t(bytes>>24)};return command(1,p,4);}
 bool write(const uint8_t *p,uint16_t bytes){return bytes&&command(2,p,bytes);}
 bool end(){return command(3,nullptr,0);}
 bool stop(){return command(4,nullptr,0);}
};
}
