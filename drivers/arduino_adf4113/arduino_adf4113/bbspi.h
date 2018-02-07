#include "Arduino.h"

class BitBangedSPI {
public:
  int clkPin, sdiPin, sdoPin, csPin;
  int delayUs;  //half clock period in microseconds
  
  //sdi is input into the arduino, sdo is output from
  //set sdi to -1 to indicate do not use
  //sdi is NOT IMPLEMENTED YET
  BitBangedSPI(int clkPin, int sdiPin, int sdoPin, int csPin):
    clkPin(clkPin), sdiPin(sdiPin), sdoPin(sdoPin), csPin(csPin) {
    delayUs = 20;  //25kHz
    pinMode(clkPin, OUTPUT);
    pinMode(sdoPin, OUTPUT);
    pinMode(csPin, OUTPUT);
    digitalWrite(csPin, HIGH);
    digitalWrite(clkPin, LOW);
  }

  //transfers the lower n bits of _data
  unsigned long transfer(unsigned long _data, int bits) {
    _data <<= (32-bits);
    
    digitalWrite(csPin, LOW);    //pull down cs
    _delay();
    for(int i=0;i<bits;i++) {
      digitalWrite(sdoPin, (_data>>31)?HIGH:LOW);  //put data on bus
      _delay();
      digitalWrite(clkPin, HIGH);  //clk rising edge
      _delay();
      digitalWrite(clkPin, LOW);
      _data <<= 1;
    }
    _delay();
    digitalWrite(csPin, HIGH);    //release cs
  }
  
  void _delay() {
    delayMicroseconds(delayUs);
  }
};



