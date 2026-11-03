#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <deque>
#include <vector>
#include "ControlLink.h"
#include "StreamScore.h"
#include <fstream>
#include <iterator>

static void require(bool ok, const char *why) {
    if (!ok) { std::fprintf(stderr, "FAIL %s\n", why); std::exit(1); }
}
static std::vector<uint8_t> readHex(const char *path) {
    FILE *f=std::fopen(path,"r"); require(f,"open hex");
    std::vector<uint8_t> out; unsigned value;
    while(std::fscanf(f,"%x",&value)==1) out.push_back(uint8_t(value));
    std::fclose(f); return out;
}
struct Replay:Music::Transport {
    std::vector<uint8_t> tx,rx; std::deque<uint8_t> pending;
    size_t used=0; uint32_t ms=0;
    uint32_t now() override {return ms;}
    void idle() override {++ms;}
    void write(const uint8_t *p,size_t n) override {
        require(n==16 && used+n<=tx.size() && used+n<=rx.size(),"unexpected request");
        require(!std::memcmp(p,tx.data()+used,n),"actual Link request differs from RTL stimulus");
        for(size_t i=0;i<n;++i)pending.push_back(rx[used+i]);
        used+=n;
    }
    int read() override {
        if(pending.empty())return -1;
        int b=pending.front();pending.pop_front();return b;
    }
};
int main(int argc,char **argv){
 require(argc==3||argc==4,"args");
 if(argc==3){
  FILE *f=fopen(argv[2],"w");require(f,"open");uint8_t seq=0;
  auto emit=[&](uint8_t cmd,const uint8_t *p,uint8_t n){uint8_t b[16];Music::frame(b,seq++,cmd,p,n);for(auto x:b)fprintf(f,"%02x\n",unsigned(x));};
  emit(1,nullptr,0);emit(2,nullptr,0);emit(0x40,nullptr,0);emit(0x42,nullptr,0);
  const uint32_t ts[6]={0,0,0,100,200,300};const uint8_t ns[6]={60,64,67,64,60,67};
  for(int i=0;i<6;i++){uint8_t p[6]={ns[i],uint8_t(i<3?100:0),uint8_t(ts[i]),uint8_t(ts[i]>>8),0,0};emit(0x41,p,6);}
  emit(0x43,nullptr,0);emit(0x42,nullptr,0);fclose(f);return 0;
 }
 Replay t;t.tx=readHex(argv[2]);t.rx=readHex(argv[3]);Music::Link link(t,0);Music::Link::StreamStatus status;
 require(link.streamBegin(),"streamBegin actual RTL replies");require(link.streamStatus(status)&&status.loaded&&status.queued==0,"empty status");
 const uint32_t ts[6]={0,0,0,100,200,300};const uint8_t ns[6]={60,64,67,64,60,67};
 for(int i=0;i<6;i++)require(link.streamPush(ts[i],ns[i],i<3?100:0),"append");
 require(link.streamSeal()&&link.streamStatus(status)&&status.queued==6&&status.sealed&&!status.fault,"sealed status");
 require(t.used==192,"all12 packets consumed");
 std::ifstream input("../canon_stream.txt");std::string text((std::istreambuf_iterator<char>(input)),{});require(!text.empty(),"canon input");
 std::vector<Music::StreamEvent> events(32768);uint32_t count;
 require(Music::parseStream(text.data(),text.size(),events.data(),events.size(),count)&&count==3840,"real canon parser");
 const char *bad[]={"0,60,100\n","0,60,0\n","0,60,100\n1,60,100\n2,60,0\n","1,60,100\n0,60,0\n","0,22,100\n1,22,0\n"};
 for(auto p:bad)require(!Music::parseStream(p,strlen(p),events.data(),events.size(),count),"malformed accepted");
 puts("PASS actual ControlLink 12 request/reply frames across real RTL UART; 3840 Canon events validated; malformed/unreleased/duplicate/reordered/out-of-range input rejected");
}
