#include <deque>
#include <cstdio>
#include <cstdlib>
#include "ControlLink.h"
struct Peer:Music::Transport {
 std::deque<unsigned char> rx;unsigned tick=0,writes=0;unsigned char glide=0,vibrato=0;bool legacy=false,mismatch=false;
 uint32_t now(){return tick;}void idle(){++tick;}int read(){if(rx.empty())return -1;int x=rx.front();rx.pop_front();return x;}
 void write(const uint8_t* b,size_t n){
  if(n!=16||!Music::valid(b))std::abort();++writes;uint8_t data[6]={b[4],0,0,0,0,0},out[16];
  switch(b[4]){
   case 1:data[2]=0x31;data[3]=0x30;data[4]=0x54;data[5]=0x42;break;
   case 2:data[4]=255;data[5]=255;break;
   case 3:data[2]=255;data[3]=255;data[4]=120;break;
   case 4:break;
   case 8:if(legacy)data[1]=2;else {data[2]=100;data[3]=mismatch?uint8_t(glide^1):glide;data[4]=vibrato;data[5]=1;}break;
   case 0x19:if(legacy)data[1]=2;else {glide=b[6];data[2]=glide;}break;
   case 0x1a:if(legacy)data[1]=2;else {vibrato=b[6];data[2]=vibrato;}break;
   default:data[1]=2;
  }
  Music::frame(out,b[3],0x80,data,6);for(auto v:out)rx.push_back(v);
 }
};
void check(bool b){if(!b){std::puts("FAIL expression link");std::exit(1);}}
int main(){Peer p;Music::Link link(p);check(link.fullState()&&link.state.valid&&link.state.expressionValid);
check(link.setExpression(1,70)&&p.glide==70&&link.state.expressionGlide==70&&link.state.valid);
check(link.setExpression(2,80)&&p.vibrato==80&&link.state.expressionVibrato==80&&link.state.valid);
unsigned n=p.writes;check(!link.setExpression(1,101)&&p.writes==n);check(!link.setExpression(3,50)&&p.writes==n);
p.mismatch=true;check(!link.setExpression(1,30)&&link.error==Music::Error::NotApplied);
Peer old;old.legacy=true;Music::Link legacy(old);check(legacy.fullState()&&legacy.state.valid&&!legacy.state.expressionValid);check(!legacy.setExpression(1,50));
std::puts("PASS actual ControlLink header: glide/vibrato dispatch, actual readback, mismatch rejection, bounds, legacy unsupported");}
