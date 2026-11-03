#include "fpga_bridge.h"
#include "ihandlers.h"
#include "EEPROM.h"
#include "hw.h"
#include <util/atomic.h>
BridgeNullDebug BridgeDebug;
static bool calibrated=false,faulted=false,calibrating=false;
static uint32_t lastPitch=0,lastVolume=0,lastSend=0;
static uint8_t sequenceId=0;
static const uint32_t MARKER=0x544c0001UL;
static uint16_t crc16(const uint8_t* p,uint8_t n) {
 uint16_t c=0xffff;
 while(n--){c^=(uint16_t)*p++<<8;for(uint8_t b=0;b<8;b++)c=(c&0x8000)?(c<<1)^0x1021:c<<1;}
 return c;
}
static uint16_t calibrationCRC(){uint8_t b[12];for(uint8_t i=0;i<12;i++)b[i]=EEPROM.read(i);return crc16(b,12);}
static void sendFrame(uint8_t flags,uint32_t frequency,uint16_t amplitude) {
 if(Serial.availableForWrite()<16)return;
 uint8_t b[16]={0xa5,0x5a,1,sequenceId++,flags,0,0,0,0,0,0,0,0,0,0,0};
 for(uint8_t i=0;i<4;i++)b[5+i]=(uint8_t)(frequency>>(8*i));
 b[9]=(uint8_t)amplitude;b[10]=(uint8_t)(amplitude>>8);
 uint16_t stamp=(uint16_t)millis();b[12]=(uint8_t)stamp;b[13]=(uint8_t)(stamp>>8);
 uint16_t crc=crc16(b+2,12);b[14]=(uint8_t)crc;b[15]=(uint8_t)(crc>>8);
 Serial.write(b,sizeof(b));
}
void bridgeBegin(){Serial.begin(115200);}
bool bridgeStoredCalibrationValid(){
 uint32_t mark;int16_t p,v;int32_t pb,vb;uint16_t storedCRC;
 EEPROM.get(16,mark);EEPROM.get(20,storedCRC);EEPROM.get(0,p);EEPROM.get(2,v);EEPROM.get(4,pb);EEPROM.get(8,vb);
 return mark==MARKER && storedCRC==calibrationCRC() && p>=0 && p<=4095 && v>=0 && v<=4095 && pb>0 && pb<=65535 && vb>0 && vb<=65535;
}
bool bridgeCalibrated(){return calibrated;}
bool bridgeFault(){return faulted;}
void bridgeSetFault(){faulted=true;calibrated=false;}
void bridgeSetCalibrated(bool value){calibrated=value;}
void bridgePitchSeen(){lastPitch=micros();}
void bridgeVolumeSeen(){lastVolume=micros();}
void bridgeStartCalibration(){calibrating=true;calibrated=false;faulted=false;HW_LED1_OFF;HW_LED2_ON;uint32_t zero=0;EEPROM.put(16,zero);sendFrame(4,440000,0);}
void bridgeCommitCalibration(){uint16_t c=calibrationCRC();EEPROM.put(20,c);EEPROM.put(16,MARKER);calibrated=true;}
void bridgeFinishCalibration(){calibrating=false;lastPitch=lastVolume=0;}
void bridgeService(bool playing){
 uint32_t now=micros();if((uint32_t)(now-lastSend)<4000)return;lastSend=now;
 bool fresh=lastPitch!=0 && lastVolume!=0 && (uint32_t)(now-lastPitch)<100000 && (uint32_t)(now-lastVolume)<100000;
 uint16_t increment;uint8_t level;
 ATOMIC_BLOCK(ATOMIC_RESTORESTATE){increment=vPointerIncrement;level=vScaledVolume;}
 uint32_t frequency=(uint32_t)(((uint64_t)increment*31250000UL)/65536UL);
 bool valid=calibrated && !faulted && fresh && frequency>=20000 && frequency<=4000000;
 uint8_t flags=(valid?3:0)|(playing && valid?8:0)|(calibrating?4:0)|(faulted || (calibrated && !fresh)?16:0);
 if(!valid){level=0;vScaledVolume=0;}
 if(valid && playing){HW_LED1_ON;HW_LED2_OFF;}else{HW_LED1_OFF;HW_LED2_ON;}
 sendFrame(flags,valid?frequency:440000,(uint16_t)level*257U);
}
