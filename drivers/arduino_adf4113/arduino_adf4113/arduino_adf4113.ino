#include "bbspi.h"
int led=13;

void setup() {
  //program the adf4113 PLL
  int clkPin=4, sdiPin=-1, sdoPin=2, csPin=3;
  BitBangedSPI bbspi(clkPin,sdiPin,sdoPin,csPin);
  
  unsigned long N=1063;
  unsigned long R=260;

  unsigned long B=N/8;
  unsigned long A=N%8;
  
  bbspi.transfer(0b000000000111111010010011, 24);
  bbspi.transfer(0b000100000000000000000000 + (R<<2), 24);
  bbspi.transfer(0b001000000000000000000001 + (B<<8) + (A<<2), 24);
}

// the loop routine runs over and over again forever:
void loop() {
  digitalWrite(led, HIGH);   // turn the LED on (HIGH is the voltage level)
  delay(10);               // wait for a second
  digitalWrite(led, LOW);    // turn the LED off by making the voltage LOW
  delay(1000);               // wait for a second
}
