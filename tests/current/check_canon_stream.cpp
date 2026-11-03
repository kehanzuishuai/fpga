#include <cstdio>
#include <fstream>
#include <iterator>
#include <string>
#include <vector>
#include "StreamScore.h"
int main(int argc,char **argv) {
    if(argc!=3) return 1;
    std::ifstream input(argv[1],std::ios::binary);
    const std::string body((std::istreambuf_iterator<char>(input)),{});
    std::vector<Music::StreamEvent> events(32768);uint32_t count=0;
    if(body.empty()||!Music::parseStream(body.data(),body.size(),events.data(),events.size(),count)) return 2;
    if(count!=static_cast<unsigned>(std::stoul(argv[2]))) return 3;
    unsigned sounding=0,peak=0,ons=0,offs=0;bool active[128]={};
    for(const auto &event:std::vector<Music::StreamEvent>(events.begin(),events.begin()+count)) {
        if(event.velocity) { if(active[event.note]) return 4;active[event.note]=true;++sounding;++ons; }
        else { if(!active[event.note]) return 5;active[event.note]=false;--sounding;++offs; }
        if(sounding>peak) peak=sounding;
    }
    if(sounding||ons!=offs||peak>32) return 6;
    std::printf("PASS latest ESP32 StreamScore.h: %u events, %u On/%u Off, peak %u simultaneous pitches, all notes released\n",count,ons,offs,peak);
    return 0;
}
