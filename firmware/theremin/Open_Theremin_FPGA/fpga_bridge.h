#ifndef TL_FPGA_BRIDGE_H
#define TL_FPGA_BRIDGE_H
#include <Arduino.h>
#if !defined(__AVR_ATmega328P__) || F_CPU != 16000000UL
#error "This sketch requires a classic 16MHz ATmega328P UNO-compatible target."
#endif
struct BridgeNullDebug {
 void begin(unsigned long) {}
 template<typename T> void print(const T&) {}
 template<typename T> void println(const T&) {}
 void println() {}
};
extern BridgeNullDebug BridgeDebug;
void bridgeBegin();
bool bridgeStoredCalibrationValid();
bool bridgeCalibrated();
bool bridgeFault();
void bridgeSetFault();
void bridgeSetCalibrated(bool value);
void bridgePitchSeen();
void bridgeVolumeSeen();
void bridgeStartCalibration();
void bridgeCommitCalibration();
void bridgeFinishCalibration();
void bridgeService(bool playing);
#endif
