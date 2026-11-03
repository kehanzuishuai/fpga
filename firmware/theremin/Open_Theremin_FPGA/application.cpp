#include "Arduino.h"

#include "application.h"

#include "hw.h"
#include "mcpDac.h"
#include "ihandlers.h"
#include "timer.h"
#include "EEPROM.h"
#include "fpga_bridge.h"
#include <util/atomic.h>

const AppMode AppModeValues[] = {MUTE,NORMAL};
const int16_t CalibrationTolerance = 15;
const int16_t PitchFreqOffset = 700;
const int16_t VolumeFreqOffset = 700;
const int8_t HYST_VAL = 40;

static int32_t pitchCalibrationBase = 0;



static int16_t pitchDAC = 0;
static int16_t volumeDAC = 0;
static float qMeasurement = 0;

static int32_t volCalibrationBase   = 0;

Application::Application()
  : _state(PLAYING),
    _mode(NORMAL) {
};

void Application::setup() {
#if SERIAL_ENABLED
  BridgeDebug.begin(Application::BAUD);
#endif

  HW_LED1_ON;HW_LED2_OFF;

  pinMode(Application::BUTTON_PIN, INPUT_PULLUP);
  pinMode(Application::LED_PIN_1,    OUTPUT);
  pinMode(Application::LED_PIN_2,    OUTPUT);

  digitalWrite(Application::LED_PIN_1, HIGH);    // turn the LED off by making the voltage LOW

   mcpDacInit();

EEPROM.get(0,pitchDAC);
EEPROM.get(2,volumeDAC);
bridgeBegin();
bridgeSetCalibrated(bridgeStoredCalibrationValid());
if(!bridgeCalibrated()){pitchDAC=2048;volumeDAC=1600;}

mcpDac2ASend(pitchDAC);
mcpDac2BSend(volumeDAC);

  
initialiseTimer();
initialiseInterrupts();


  EEPROM.get(4,pitchCalibrationBase);
  EEPROM.get(8,volCalibrationBase);
 


}

void Application::initialiseTimer() {
  ihInitialiseTimer();
}

void Application::initialiseInterrupts() {
  ihInitialiseInterrupts();
}

void Application::InitialisePitchMeasurement() {
   ihInitialisePitchMeasurement();
}

void Application::InitialiseVolumeMeasurement() {
   ihInitialiseVolumeMeasurement();
}

unsigned long Application::GetQMeasurement()
{
  int qn=0;
  
  TCCR1B = (1<<CS10);	

{uint32_t guard=40000;while(!(PIND & (1<<PORTD3)) && --guard);if(!guard){bridgeSetFault();return 0;}}
{uint32_t guard=40000;while((PIND & (1<<PORTD3)) && --guard);if(!guard){bridgeSetFault();return 0;}}

TCNT1 = 0;
  timer_overflow_counter = 0;
while(qn<31250){
if(timer_overflow_counter>400){bridgeSetFault();return 0;}
{uint32_t guard=40000;while(!(PIND & (1<<PORTD3)) && --guard);if(!guard){bridgeSetFault();return 0;}}
qn++;
{uint32_t guard=40000;while((PIND & (1<<PORTD3)) && --guard);if(!guard){bridgeSetFault();return 0;}}
};

 
  
  TCCR1B = 0;	

 unsigned long frequency = TCNT1;
 unsigned long temp = 65536*(unsigned long)timer_overflow_counter;
  frequency += temp;

return frequency;

}


unsigned long Application::GetPitchMeasurement()
{
  TCNT1 = 0;
  timer_overflow_counter = 0;
  TCCR1B = (1<<CS12) | (1<<CS11) | (1<<CS10);	

  delay(1000);  
  
  TCCR1B = 0;	

 unsigned long frequency = TCNT1;
 unsigned long temp = 65536*(unsigned long)timer_overflow_counter;
  frequency += temp;

return frequency;

}

unsigned long Application::GetVolumeMeasurement()
{timer_overflow_counter = 0;

  TCNT0=0;
  TCNT1=49911;
  TCCR0B = (1<<CS02) | (1<<CS01) | (1<<CS00);	 // //External clock source on T0 pin. Clock on rising edge.
  TIFR1  = (1<<TOV1);        //Timer1 INT Flag Reg: Clear Timer Overflow Flag

{uint32_t guard=20000000UL;while(!(TIFR1&(1<<TOV1)) && --guard);if(!guard){bridgeSetFault();return 0;}} // on Timer 1 overflow (1s)
  TCCR0B = 0;	 // Stop TimerCounter 0
 unsigned long frequency = TCNT0; // get counter 0 value
 unsigned long temp = (unsigned long)timer_overflow_counter; // and overflow counter

 frequency += temp*256;

return frequency;
}



#if CV_ENABLED                                 // Initialise PWM Generator for CV output
void initialiseCVOut() {

}
#endif

AppMode Application::nextMode() {
  return _mode == NORMAL ? MUTE : AppModeValues[_mode + 1];
}

void Application::loop() {
  int32_t pitch_v = 0, pitch_l = 0;            // Last value of pitch  (for filtering)
  int32_t vol_v = 0,   vol_l = 0;              // Last value of volume (for filtering)

  uint16_t volumePotValue = 0;
  uint16_t pitchPotValue = 0;
  int registerPotValue,registerPotValueL = 0;
  int wavePotValue,wavePotValueL = 0;
  uint8_t registerValue = 0;



  mloop:                   // Main loop avoiding the GCC "optimization"

  pitchPotValue    = analogRead(PITCH_POT);
  volumePotValue   = analogRead(VOLUME_POT);
  registerPotValue   = analogRead(REGISTER_SELECT_POT);
  wavePotValue = analogRead(WAVE_SELECT_POT);
  
  if ((registerPotValue-registerPotValueL) >= HYST_VAL || (registerPotValueL-registerPotValue) >= HYST_VAL) registerPotValueL=registerPotValue;
  if (((wavePotValue-wavePotValueL) >= HYST_VAL) || ((wavePotValueL-wavePotValue) >= HYST_VAL)) wavePotValueL=wavePotValue;

  vWavetableSelector=wavePotValueL>>7;
  registerValue=4-(registerPotValueL>>8);  

  if (_state == PLAYING && HW_BUTTON_PRESSED) {
    _state = CALIBRATING;
    resetTimer();
  }

  if (_state == CALIBRATING && HW_BUTTON_RELEASED) {
    if (timerExpiredMillis(50)) {
     
         _mode = nextMode();
 if (_mode==NORMAL) {HW_LED1_ON;HW_LED2_OFF;} else {HW_LED1_OFF;HW_LED2_ON;};
   // playModeSettingSound();
   
   
    }
    _state = PLAYING;
  };

  if (_state == CALIBRATING && timerExpiredMillis(2000)) {

      HW_LED2_ON;
      
  bridgeStartCalibration();
  playStartupSound();
  

   calibrate_pitch();
   if(!bridgeFault())calibrate_volume();
   initialiseTimer(); initialiseInterrupts();
   if(!bridgeFault())calibrate();
   if(!bridgeFault()) { bridgeCommitCalibration(); playCalibratingCountdownSound(); }
   bridgeFinishCalibration();
      _mode=NORMAL;
      HW_LED2_OFF;
      
    while (HW_BUTTON_PRESSED)
      ; // NOP
    _state = PLAYING;
  };

#if CV_ENABLED
  OCR0A = pitch & 0xff;
#endif

#if SERIAL_ENABLED
  if (timerExpired(TICKS_100_MILLIS)) {
    resetTimer();
    BridgeDebug.write(pitch & 0xff);              // Send char on serial (if used)
    BridgeDebug.write((pitch >> 8) & 0xff);
  }
#endif

  if (pitchValueAvailable) {                        // If capture event

    ATOMIC_BLOCK(ATOMIC_RESTORESTATE){pitch_v=pitch;} bridgePitchSeen();                         // Averaging pitch values
    pitch_v=pitch_l+((pitch_v-pitch_l)>>2);
    pitch_l=pitch_v;


//HW_LED2_ON;


    // set wave frequency for each mode
    switch (_mode) {
      case MUTE : /* NOTHING! */;                                        break;
      case NORMAL: { int32_t advance=(pitchCalibrationBase-pitch_v)/registerValue+2048-(pitchPotValue<<2); advance=constrain(advance,42L,8388L); setWavetableSampleAdvance((uint16_t)advance); } break;
    };
    
  //  HW_LED2_OFF;

    pitchValueAvailable = false;
  }

  if (volumeValueAvailable) {
    // Clamp the local atomic snapshot, never write ISR-owned vol here.

    ATOMIC_BLOCK(ATOMIC_RESTORESTATE){vol_v=vol;} bridgeVolumeSeen();                  // Averaging volume values
    vol_v=max(vol_v,5000L); vol_v=vol_l+((vol_v-vol_l)>>2);
    vol_l=vol_v;

    switch (_mode) {
      case MUTE:  vol_v = 0;                                                      break;
      case NORMAL:      vol_v = MAX_VOLUME-(volCalibrationBase-vol_v)/2+(volumePotValue<<2)-1024;                                     break;
    };

    // Limit and set volume value
    vol_v = min(vol_v, 4095);
    //    vol_v = vol_v - (1 + MAX_VOLUME - (volumePotValue << 2));
    vol_v = vol_v ;
    vol_v = max(vol_v, 0);
    vScaledVolume = vol_v >> 4;

    volumeValueAvailable = false;
  }

  if(!bridgeCalibrated() || bridgeFault()) vScaledVolume=0;
  bridgeService(_mode==NORMAL);
  goto mloop;                           // End of main loop
}

void Application::calibrate()
{
  resetPitchFlag();
  resetTimer();
  savePitchCounter();
  while (!pitchValueAvailable && timerUnexpiredMillis(10))
    ; // NOP
  if(!pitchValueAvailable){bridgeSetFault();return;}
  ATOMIC_BLOCK(ATOMIC_RESTORESTATE){pitchCalibrationBase=pitch;}
  if(pitchCalibrationBase<=0){bridgeSetFault();return;}

  resetVolFlag();
  resetTimer();
  saveVolCounter();
  while (!volumeValueAvailable && timerUnexpiredMillis(10))
    ; // NOP
  if(!volumeValueAvailable){bridgeSetFault();return;}
  ATOMIC_BLOCK(ATOMIC_RESTORESTATE){volCalibrationBase=vol;}
  if(volCalibrationBase<=0){bridgeSetFault();return;}
  
  
  EEPROM.put(4,pitchCalibrationBase);
  EEPROM.put(8,volCalibrationBase);
  
}

// Bounded bracketed tuning. At most 14 one-second measurements per axis.
void Application::calibrate_pitch() {
 InitialisePitchMeasurement(); interrupts(); mcpDacInit();mcpDac2BSend(1600);
 qMeasurement=GetQMeasurement();
 if(bridgeFault() || qMeasurement<8000000.0f || qMeasurement>24000000.0f){bridgeSetFault();return;}
 long target=(long)(16000000.0f/qMeasurement*500000.0f)-PitchFreqOffset;
 int lo=0,hi=4095,best=0;long bestError=2147483647L;
 mcpDac2ASend(lo);delay(100);long fl=GetPitchMeasurement();
 mcpDac2ASend(hi);delay(100);long fh=GetPitchMeasurement();
 if(fl==0 || fh==0 || fl==fh || target<min(fl,fh) || target>max(fl,fh)){bridgeSetFault();return;}
 for(uint8_t i=0;i<12 && lo<=hi;i++) {
  int mid=lo+(hi-lo)/2;mcpDac2ASend(mid);delay(100);long f=GetPitchMeasurement();
  if(f==0 || bridgeFault()){bridgeSetFault();return;}
  long error=labs(f-target);if(error<bestError){bestError=error;best=mid;}
  if(error<=CalibrationTolerance)break;
  if((f<target)==(fl<fh))lo=mid+1;else hi=mid-1;
 }
 if(bestError>CalibrationTolerance*2L){bridgeSetFault();return;}
 pitchDAC=best;mcpDac2ASend(best);EEPROM.put(0,pitchDAC);
}
void Application::calibrate_volume() {
 InitialiseVolumeMeasurement();interrupts();mcpDacInit();
 long target=(long)(16000000.0f/qMeasurement*460765.0f)-VolumeFreqOffset;
 int lo=0,hi=4095,best=0;long bestError=2147483647L;
 mcpDac2BSend(lo);delay_NOP(44316);long fl=GetVolumeMeasurement();
 mcpDac2BSend(hi);delay_NOP(44316);long fh=GetVolumeMeasurement();
 if(fl==0 || fh==0 || fl==fh || target<min(fl,fh) || target>max(fl,fh)){bridgeSetFault();return;}
 for(uint8_t i=0;i<12 && lo<=hi;i++) {
  int mid=lo+(hi-lo)/2;mcpDac2BSend(mid);delay_NOP(44316);long f=GetVolumeMeasurement();
  if(f==0 || bridgeFault()){bridgeSetFault();return;}
  long error=labs(f-target);if(error<bestError){bestError=error;best=mid;}
  if(error<=CalibrationTolerance)break;
  if((f<target)==(fl<fh))lo=mid+1;else hi=mid-1;
 }
 if(bestError>CalibrationTolerance*2L){bridgeSetFault();return;}
 volumeDAC=best;mcpDac2BSend(best);EEPROM.put(2,volumeDAC);
}

void Application::hzToAddVal(float hz) {
  setWavetableSampleAdvance((uint16_t)(hz * HZ_ADDVAL_FACTOR));
}

void Application::playNote(float hz, uint16_t milliseconds = 500, uint8_t volume = 255) {
  vScaledVolume = volume;
  hzToAddVal(hz);
  millitimer(milliseconds);
  vScaledVolume = 0;
}

void Application::playStartupSound() {
  playNote(MIDDLE_C, 150, 25);
  playNote(MIDDLE_C * 2, 150, 25);
  playNote(MIDDLE_C * 4, 150, 25);
}

void Application::playCalibratingCountdownSound() {
  playNote(MIDDLE_C * 2, 150, 25);
  playNote(MIDDLE_C * 2, 150, 25);
}

void Application::playModeSettingSound() {
  for (int i = 0; i <= _mode; i++) {
    playNote(MIDDLE_C * 2, 200, 25);
    millitimer(100);
  }
}

void Application::delay_NOP(unsigned long time) {
  volatile unsigned long i = 0;
  for (i = 0; i < time; i++) {
      __asm__ __volatile__ ("nop");
  }
}




