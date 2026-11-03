#include <cassert>
#include <cstdio>
#include "ControlLink.h"
#include "StreamScore.h"
struct Fake {
 Music::Link::StreamStatus status;
 Music::State state;unsigned performanceMode=0,begins=0,pushes=0,seals=0,plays=0;
 bool allow=true;
 bool streamBegin(){if(!allow||state.playing)return false;begins++;status={};status.loaded=true;return true;}
 bool streamStatus(Music::Link::StreamStatus &s){s=status;return true;}
 bool streamPush(uint32_t,uint8_t,uint8_t){assert(status.queued<256);status.queued++;pushes++;return true;}
 bool streamSeal(){status.sealed=true;seals++;return true;}
 bool readPerformance(){return true;}bool fullState(){return true;}
 bool play(bool on){state.playing=on;status.playing=on;plays++;return true;}
} fake;
Fake *fpgaLink=&fake;
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

bool playRequest(bool value){struct {bool value;}job{value};bool ok=false;
if(job.value && streamEvents){
       ok=fpgaLink->readPerformance()&&fpgaLink->fullState();
       if(ok && fpgaLink->performanceMode!=2){
        // Repeated Play is idempotent; never stop feeding an active timeline.
        if(!fpgaLink->state.playing){ok=prepareStream()&&fpgaLink->play(true);streamFeeding=ok;}
       }else if(ok)ok=fpgaLink->play(true);
      }else {if(!job.value)streamFeeding=false;ok=fpgaLink->play(job.value!=0);}
return ok;}
int main(){
 Music::StreamEvent e[500];for(unsigned i=0;i<500;i++)e[i]={i*20,60,uint8_t(i%2?0:100)};
 streamEvents=e;streamCount=500;
 assert(prepareStream()&&streamCursor==256&&fake.status.queued==256);
 assert(playRequest(true)&&streamFeeding);unsigned begin=fake.begins,cursor=streamCursor,played=fake.plays;
 assert(playRequest(true)&&streamFeeding&&fake.begins==begin&&fake.plays==played&&streamCursor==cursor);
 assert(!prepareStream()&&streamFeeding&&streamCursor==cursor); // failed begin must preserve current playback
 fake.status.queued-=80;assert(fillStream(16)&&streamCursor==cursor+16&&fake.status.queued==192);
 fake.status.queued=0;assert(fillStream(256)&&streamCursor==500&&streamSealed);unsigned seals=fake.seals;
 assert(fillStream(16)&&fake.seals==seals);
 fake.status.finished=true;assert(fillStream(16)&&!streamFeeding);
 fake.status.finished=false;fake.status.fault=true;assert(!fillStream(16)&&streamError);
 puts("PASS actual sketch helper/lifecycle code: prefill256, capacity/refill, repeated Play stays feeding, failed begin preserves active session, seal once, completion and fault");
}
