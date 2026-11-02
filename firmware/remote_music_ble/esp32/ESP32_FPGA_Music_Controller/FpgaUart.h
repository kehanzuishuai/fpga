#pragma once
#include <Arduino.h>
#include "ControlLink.h"

// UART1 is dedicated to the FPGA; debug output stays on the USB-UART port.
class FpgaUart:public Music::Transport {
  HardwareSerial &port;
  bool initialized=false,lastWriteOk=true;
public:
  static constexpr int RX_PIN=18,TX_PIN=17;
  static constexpr unsigned BAUD=115200;
  size_t rxBufferBytes=0;
  uint32_t txBytes=0,shortWrites=0;
  explicit FpgaUart(HardwareSerial &serial):port(serial){}
  bool begin() {
    rxBufferBytes=port.setRxBufferSize(1024);
    port.begin(BAUD,SERIAL_8N1,RX_PIN,TX_PIN);
    initialized=bool(port)&&rxBufferBytes>=1024;
    if(initialized) {
      // Deliver short 16-byte replies without waiting for a large FIFO.
      // The hardware connection has no CTS/RTS lines.
      const bool flow=port.setHwFlowCtrlMode(UART_HW_FLOWCTRL_DISABLE);
      const bool timeout=port.setRxTimeout(2);
      const bool fifo=port.setRxFIFOFull(1);
      initialized=flow&&timeout&&fifo;
    }
    return initialized;
  }
  bool ready() override {return initialized&&bool(port);}
  bool writeComplete() override {return lastWriteOk;}
  uint32_t now() override {return millis();}
  void idle() override {delay(1);}
  void write(const uint8_t *p,size_t n) override {
    const size_t sent=port.write(p,n);txBytes+=sent;lastWriteOk=sent==n;
    if(!lastWriteOk)shortWrites++;
  }
  int read() override {return port.read();}
};
