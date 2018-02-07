#ifndef __ADF4350_BOARD_H
#define __ADF4350_BOARD_H
#include "common_types.h"
#include <string>
#include <stdexcept>
using namespace std;

namespace adf4350Board {
	int gpiorate=2000000;
	int spirate=250000;
	int spirepeat=gpiorate/spirate;
	u8 spiclk=1<<0;
	u8 spile=1<<1;
	u8 spidata=1<<2;

	void sendWord(string& out,u32 word) {
		for(int i=31;i>=0;i--) {
			u8 bit=((word>>i)&1)?spidata:0;
			
			//put bit on data line; clk low
			for(int x=0;x<spirepeat;x++)
				out+=(char)bit;
			//clk high
			for(int x=0;x<spirepeat;x++)
				out+=(char)(bit|spiclk);
			
		}
		//pulse le
		for(int x=0;x<spirepeat;x++)
			out+=(char)0;
		for(int x=0;x<spirepeat;x++)
			out+=(char)spile;
		for(int x=0;x<spirepeat;x++)
			out+=(char)0;
	}
	
	//odiv: output division factor, 1 to 16
	void sendConfig(string& out, int odiv) {
		int O;
		switch(odiv) {
			case 1:  O=0b000; break;
			case 2:  O=0b001; break;
			case 4:  O=0b010; break;
			case 8:  O=0b011; break;
			case 16: O=0b100; break;
			default: throw logic_error("unsupported output divider value");
		}
		
		int R=1;
		// reg 5
		//             LD pin      register 5
		sendWord(out, (0b01<<22) | 0b101);
		// reg 4
		//             fb      rf divider    bs divider   aux en    aux pwr    rf en     rf pwr     register 4
		sendWord(out, (1<<23) | (O<<20) 	| (255<<12) | (0<<8) | (0b01<<6) | (1<<5) | (0b01<<3) | 0b100);
		
		// reg 3
		//           clkdiv mode   register 3
		sendWord(out, (0b00<<15) | 0b011);
		
		// reg 2
		//          low spur mode     muxout        R       CP current    int-N    LDP     PD pol   register 2
		sendWord(out, (0b11<<29) | (0b001<<26) | (R<<14) | (0b1111<<9) | (1<<8) | (0<<7) | (1<<6) | 0b010);
		
		// reg 1
		//           prescaler   phase  frac modulus
		sendWord(out, (1<<27) | (1<<15) | (32<<3) | 0b001);
		
	}
	void sendN(string& out, u16 N) {
		sendWord(out, (N<<15));	//register 0
	}
}

#endif
