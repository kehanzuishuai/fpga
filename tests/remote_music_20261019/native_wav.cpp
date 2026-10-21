#include <fstream>
#include <iostream>
#include <iomanip>
#include <vector>
#include <iterator>
#include <stdexcept>
#include "../../firmware/remote_music/esp32/ESP32_FPGA_Music_Controller/WavLink.h"
static void check(bool ok,const char *s){if(!ok)throw std::runtime_error(s);}
struct Mock:Music::SpiTransport {
 std::ofstream trace;std::vector<uint8_t> bytes;
 uint32_t clock=0,size=0;uint16_t next=0,lastSeq=0,lastCrc=0;
 uint8_t lastCmd=0;uint16_t lastLength=0;bool cache=false,cancel=false,first=true,badStatus=false;
 int hidden=0,retries=0;
 explicit Mock(const char *name):trace(name){}
 uint32_t now() override{return clock;}
 void idle() override{clock++;}
 bool cancelled() override{return cancel;}
 static uint16_t u16(const uint8_t *p){return uint16_t(p[0])|uint16_t(p[1])<<8;}
 void transfer(uint8_t *tx,uint8_t *rx,size_t n) override {
  trace<<std::dec<<n;for(size_t k=0;k<n;k++)trace<<' '<<std::hex<<std::setw(2)<<std::setfill('0')<<unsigned(tx[k]);trace<<'\n';
  memset(rx,0,n);
  if(tx[3]==0){
   check(n==24,"status length");rx[0]=0x57;rx[1]=0x41;rx[2]=1;
   const uint16_t reported=hidden>0?uint16_t(next-1):next;if(hidden>0)hidden--;
   rx[4]=uint8_t(reported);rx[5]=uint8_t(reported>>8);rx[7]=64;
   const uint32_t received=uint32_t(bytes.size());for(int k=0;k<4;k++)rx[12+k]=uint8_t(received>>(k*8));
   uint16_t c=Music::crc16(rx,22);if(badStatus){c^=1;badStatus=false;}
   rx[22]=uint8_t(c);rx[23]=uint8_t(c>>8);return;
  }
  const uint16_t seq=u16(tx+4),length=u16(tx+6),crc=u16(tx+n-2);
  check(tx[0]==0x57&&tx[1]==0x41&&tx[2]==1&&length+10==n&&Music::crc16(tx,n-2)==crc,"actual firmware frame encoding");
  if(cache&&seq==lastSeq&&tx[3]==lastCmd&&length==lastLength&&crc==lastCrc){retries++;hidden=0;return;}
  if(tx[3]==4){bytes.clear();size=0;}
  else if(tx[3]==1){check(length==4,"START");size=uint32_t(u16(tx+8))|(uint32_t(u16(tx+10))<<16);bytes.clear();}
  else {
   check(seq==next,"sequence / wrap");
   if(tx[3]==2){check(length&&length<=1024&&bytes.size()+length<=size,"DATA bounds");bytes.insert(bytes.end(),tx+8,tx+8+length);if(first){hidden=35;first=false;}}
   else check(tx[3]==3&&length==0&&bytes.size()==size,"END length");
  }
  next=uint16_t(seq+1);cache=true;lastSeq=seq;lastCrc=crc;lastLength=length;lastCmd=tx[3];
 }
};
int main(int argc,char **argv){try{
 check(argc==3,"arguments");std::ifstream input(argv[1],std::ios::binary);
 check(input.good(),"fixture");std::vector<uint8_t> source((std::istreambuf_iterator<char>(input)),std::istreambuf_iterator<char>());
 Mock io(argv[2]);Music::WavLink link(io,65534);
 check(link.stop()&&link.begin(uint32_t(source.size())),"STOP / START acknowledgement");
 for(size_t p=0;p<source.size();p+=1024)check(link.write(source.data()+p,uint16_t(source.size()-p>1024?1024:source.size()-p)),"write");
 check(link.end()&&io.bytes==source&&io.retries==1,"byte-exact WAV and lost-ACK duplicate");
 io.badStatus=true;check(!link.poll()&&link.poll(),"status CRC rejection");
 io.cancel=true;const size_t before=io.bytes.size();check(!link.write(source.data(),1)&&io.bytes.size()==before,"cancellation");
 std::cout<<"PASS real WavLink.h: sequence wrap, lost ACK retry, byte-exact "<<source.size()<<" bytes, status CRC rejection, cancellation; actual transfers recorded for RTL replay\n";return 0;
 }catch(const std::exception &e){std::cerr<<e.what()<<'\n';return 1;}}
