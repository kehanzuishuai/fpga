#pragma once
#include <stdint.h>
#include <stddef.h>
namespace Music {
struct StreamEvent {uint32_t time;uint8_t note,velocity;};
// Full validation occurs before the FPGA session is opened.
inline bool parseStream(const char *p,size_t size,StreamEvent *out,uint32_t capacity,uint32_t &count){
 count=0;size_t pos=0;uint32_t previous=0;bool active[128]={};unsigned held=0;
 while(pos<size){
  if(count>=capacity)return false;uint32_t v[3]={};
  for(unsigned k=0;k<3;k++){
   size_t first=pos;while(pos<size&&p[pos]>='0'&&p[pos]<='9'){
    const unsigned digit=p[pos++]-'0';if(v[k]>360000 || (v[k]==360000&&digit>0))return false;v[k]=v[k]*10+digit;
   }
   if(pos==first)return false;
   if(k<2){if(pos==size||p[pos++]!=',')return false;}
  }
  if(pos<size&&p[pos++]!='\n')return false;
  if(v[0]<previous||v[0]>3600000||v[1]<36||v[1]>96||v[2]>127)return false;
  if(v[2]){if(active[v[1]]||held>=32)return false;active[v[1]]=true;held++;}
  else{if(!active[v[1]])return false;active[v[1]]=false;held--;}
  out[count++]={v[0],uint8_t(v[1]),uint8_t(v[2])};previous=v[0];
 }
 return count>0&&held==0;
}
}
