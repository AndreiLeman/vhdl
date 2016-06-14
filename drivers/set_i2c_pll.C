#include <stdio.h>
#include <sys/mman.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <time.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <signal.h>
#include <string>
#include <assert.h>
#include <math.h>
using namespace std;


typedef unsigned long ul;
typedef unsigned int ui;
typedef uint64_t u64;
typedef uint32_t u32;
typedef uint16_t u16;
typedef uint8_t u8;


int gpiorate=2000000;
int i2crate=250000;
int i2crepeat=gpiorate/i2crate;

u8 i2cscl=1<<2;
u8 i2csda=1<<3;
//bit:
//	0: sda low, scl pulsed
//	1: sda high, scl pulsed
//	4: sda low, scl low
//	5: sda high, scl low
//	6: sda low, scl high
//	7: sda high, scl high
void sendBit(string& out,u8 bit) {
	u8 buf[4*i2crepeat];
	
	bool data=bit&1;
	bool pulseclk=!(bit&4);
	bool overrideclk=bit&2;
	u8 datasda=data?i2csda:0;
	u8 overrideclkscl=overrideclk?i2cscl:0;
	
	//put data on bus
	u8 out1=datasda | (pulseclk?0:overrideclkscl);
	//scl high
	u8 out2=datasda | (pulseclk?i2cscl:overrideclkscl);
	
	for(int i=0;i<i2crepeat;i++)
		buf[i]=out1;
	for(int i=i2crepeat;i<i2crepeat*3;i++)
		buf[i]=out2;
	for(int i=i2crepeat*3;i<i2crepeat*4;i++)
		buf[i]=out1;
	out.append((char*)buf,sizeof(buf));
}
//same convention as above, but with ascii numbers instead of raw numbers
void sendBits(string& out, string data) {
	for(int i=0;i<(int)data.length();i++)
		sendBit(out,((u8)data[i])-48);
}
void sendStart(string& out) {
	sendBits(out,"764");
}
void sendStop(string& out) {
	sendBits(out,"467");
}
void sendByte(string& out, u8 byte) {
	for(int i=7;i>=0;i--)
		sendBit(out,(byte&(1<<i))?1:0);
	//ack bit
	sendBit(out,1);
}


void writeBits(u64 bits, int bitcount) {
	string s;
	for(int i=bitcount-1;i>=0;i--) {
		const char* tmp;
		tmp=((bits>>i)&1)?"█":" ";
		s+=tmp;
	}
	printf("%s %lu\n",s.c_str(),bits);
}

u8 devAddr=0xd4;

void doWrite(string buf) {
	//set the enable bits
	u8 enables=(1<<4)|(1<<5)|(1<<6)|(1<<7);
	for(int i=0;i<(int)buf.length();i++)
		buf[i]|=enables;
	assert(write(1,buf.data(),buf.length())==(int)buf.length());
}
void sendConfig() {
	string buf;
	/*sendStart(buf);
	sendByte(buf,devAddr);
	
	sendByte(buf,0x17);
	sendByte(buf,0b00000111);		//feedback
	sendByte(buf,0b00000000);		//feedback
	
	sendStop(buf);*/
	
	sendStart(buf);
	sendByte(buf,devAddr);
	
	sendByte(buf,0x31);
	sendByte(buf,0b10000001);		//clock2 control
	
	sendStop(buf);
	sendStart(buf);
	sendByte(buf,devAddr);
	
	sendByte(buf,0x62);
	sendByte(buf,0b10111011);		//clock2 cfg
	sendByte(buf,0b00000001);		//clock2 cfg
	
	sendStop(buf);
	sendStart(buf);
	sendByte(buf,devAddr);
	
	sendByte(buf,0x68);
	sendByte(buf,0b00000111);		//CLK_OE
	sendByte(buf,0b11111100);		//CLK_OS
	
	sendStop(buf);
	
	doWrite(buf);
}

void sendN(int N, int frac) {
	assert(outputnum>=1 && outputnum<=4);
	u8 dividerAddr=0x17;
	u8 dividerFAddr=0x19;
	
	string buf;
	sendStart(buf);
	sendByte(buf,devAddr);
	
	sendByte(buf,dividerAddr);
	sendByte(buf,N>>4);				//N divider
	sendByte(buf,(N&0b1111)<<4);	//N divider
	
	sendStop(buf);
	
	sendStart(buf);
	sendByte(buf,devAddr);
	
	sendByte(buf,dividerFAddr);			//N divider f
	sendByte(buf,(frac>>16) & 255);
	sendByte(buf,(frac>>8) & 255);
	sendByte(buf,(frac>>0) & 255);
	
	sendStop(buf);
	
	doWrite(buf);
}
void sendO(int outputnum, int N, int frac, bool spread=false) {
	assert(outputnum>=1 && outputnum<=4);
	u8 dividerAddr=0x1d + outputnum*0x10;
	u8 dividerFAddr=0x12 + outputnum*0x10;
	
	string buf;
	sendStart(buf);
	sendByte(buf,devAddr);
	
	sendByte(buf,dividerAddr);
	sendByte(buf,N>>4);				//clockN divider
	sendByte(buf,(N&0b1111)<<4);	//clockN divider
	
	sendStop(buf);
	
	sendStart(buf);
	sendByte(buf,devAddr);
	
	sendByte(buf,dividerFAddr);			//clockN divider f
	sendByte(buf,(frac>>22) & 255);
	sendByte(buf,(frac>>14) & 255);
	sendByte(buf,(frac>>6) & 255);
	sendByte(buf,((frac<<2) & 0b11111100) | (spread?0b10:0));
	
	if(spread) {
		sendByte(buf,0b00000000);
		sendByte(buf,0b00000000);
		sendByte(buf,0b00001111);
		
		sendByte(buf,0b11111111);
		sendByte(buf,0b11111000);
	}
	
	sendStop(buf);
	
	doWrite(buf);
}
//if outputnum==-1, then sets the N divider (pll multiplication factor)
void sendFracN(int outputnum, const char* N, bool spread=false) {
	int fracMax=1<<24;
	int Nint,Nfrac;
	
	char* endptr=NULL;
	const char* Nend=N+strlen(N);
	long tmp=strtol(N,&endptr,10);
	if(endptr==Nend) {
		//N is an integer
		Nint=(int)tmp;
		Nfrac=0;
	} else {
		//N is a fraction
		double d=strtod(N,NULL);
		Nint=(int)floor(d);
		Nfrac=(d-double(Nint))*fracMax;
		if(Nfrac>=fracMax) Nfrac=fracMax-1;
	}
	
	fprintf(stderr,"int: %d, frac: %d\n",Nint,Nfrac);
	
	if(outputnum==-1) sendN(Nint,Nfrac);
	else sendO(outputnum,Nint,Nfrac,spread);
}

void nSleep(long nanoseconds) {
	struct timespec ts = {
		0, nanoseconds
	};
	nanosleep(&ts,NULL);
}
int main(int argc,char** argv) {
	if(argc<3) {
		fprintf(stderr,"usage: %s N O1 O2\n",argv[0]);
		return 1;
	}
	const char* N=argv[1];
	const char* O1=argv[2];
	const char* O2=argv[3];
	
	sendConfig();
	
	sendFracN(-1,N);
	sendFracN(1,O1);
	sendFracN(2,O2);
	
	/*
	for(int i=0;i<50;i++) {
		sendN(2,N2,i*10000);
		nSleep(100000000);
		//sleep(1);
	}*/
	
	
	
	string buf;
	//return the bus control to the hw by deasserting enables
	buf+=((char)(i2csda|i2cscl));
	assert(write(1,buf.data(),buf.length())==(int)buf.length());
	return 0;
}
