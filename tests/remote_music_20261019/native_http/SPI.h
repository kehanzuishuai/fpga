#pragma once
#define FSPI 0
#define MSBFIRST 1
#define SPI_MODE0 0
struct SPISettings {SPISettings(unsigned,int,int){}};
struct SPIClass {
 explicit SPIClass(int){} void begin(int,int,int,int){}
 void beginTransaction(SPISettings){} void endTransaction(){}
 void transferBytes(uint8_t*,uint8_t *rx,size_t n){memset(rx,0,n);}
};
