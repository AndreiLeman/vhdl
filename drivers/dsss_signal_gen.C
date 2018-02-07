#include <stdio.h>
#include <stdint.h>
#include <unistd.h>
#include <math.h>
#include <stdlib.h>
#include <string>
#include <algorithm>
#include <random>

using namespace std;

typedef int8_t s8;
typedef uint8_t u8;
// one bit per byte format; byte value 0 (char '\0') => bit is 0; byte value !=0 => bit is 1
// the expanded dsss code used to generate the signal from
string code;


int writeAll(int fd,void* buf, int len) {
	u8* buf1=(u8*)buf;
	int off=0;
	int r;
	while(off<len) {
		if((r=write(fd,buf1+off,len-off))<=0) break;
		off+=r;
	}
	return off;
}

void gen_code() {
	// one bit per character format; char '0' => bit is 0; any other char => bit is 1
	// outer code is the fast code
	string inner="1111001101101001100001011101011011110110000100001110011101111000"
				"1011101000011111010100000010001010010001001111010111100101010000";
	string outer="1110000100100010001000010011111110011001011011110010000110110001"
				"0110101010010110100101111101101111101010100010011000110110011000";
	
	// reverse the codes because they were copied from vhdl where "downto" was used
	reverse(inner.begin(), inner.end());
	reverse(outer.begin(), outer.end());
	
	// convert strings to byte-bit format (byte value 0 instead of char '0')
	for(int i=0;i<(int)inner.length();i++) inner[i]=(inner[i]=='0'?0:1);
	for(int i=0;i<(int)outer.length();i++) outer[i]=(outer[i]=='0'?1:0);
	
	string outerInv;
	outerInv.resize(outer.length());
	for(int i=0;i<(int)outerInv.length();i++) outerInv[i]=(outer[i]==0?1:0);
	
	// expand the code
	string result;
	for(int i=0;i<(int)inner.length();i++) {
		bool invert = (inner[i]!=0);
		if(invert) result += outerInv;
		else result += outer;
	}
	
	code=result;
}

int main() {
	std::random_device rnd;
	std::mt19937 e2(rnd());
	
	// noise parameters:
	// stddev is 1; noise power is 1
	std::normal_distribution<> dist(0, 1);
	
	// signal parameters
	double signalPeak=1./30;
	
	
	// expand outer and inner code into flat code
	gen_code();
	
	int codeLen=code.length();
	double codeSignal[codeLen];
	
	for(int i=0;i<codeLen;i++) {
		codeSignal[i] = code[i]==0?-1:1;
	}
	
	// modulation by sin()
	bool modulate=true;
	double freq=47311730./pow(2,28);
	double phaseRate=freq*2*M_PI;
	double phase=0;
	
	// code rate (chips per sample)
	double codeRate=(225./256.)/25.*1.000005;
	double codePhase=0;
	
	
	codeRate=1;
	modulate=false;
	
	
	// calculate the signal to noise power spectral density ratio (for display)
	double noisePower=1.0*codeRate; // noise power in passband
	double signalPower=signalPeak*signalPeak/2;
	double snr=signalPower/noisePower;
	fprintf(stderr, "SNR (PSD): %.2lf dB\n", log10(snr)*10);
	
	
	
	int bufSize=1024*16;
	s8 buf[bufSize];
	// main output loop
	while(true) {
		for(int i=0;i<codeLen;i++) {
			// calculate carrier phase
			phase+=phaseRate;
			if(phase>2*M_PI) phase-=2*M_PI;
			
			// calculate code phase
			codePhase+=codeRate;
			if(codePhase>=codeLen) codePhase-=codeLen;
			int codeIndex=(int)codePhase;
			
			// get the code
			double tmp=codeSignal[codeIndex]*signalPeak;
			
			// add gaussian noise
			tmp+=dist(e2);
			
			// modulate
			if(modulate) tmp*=sin(phase);
			
			
			
			// scale by 5 to overcome quantization noise
			buf[i]=(int)round(tmp*5);
		}
		writeAll(1,buf,codeLen);
	}
}
