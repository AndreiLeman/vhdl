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

using namespace std;

#define H2F_BASE (0xC0000000) // axi_master
#define H2F_SPAN (0x40000000) // Bridge span
#define HW_REGS_BASE ( 0xFC000000 )     //misc. registers
#define HW_REGS_SPAN ( 0x04000000 )


#define LWH2F_OFFSET 52428800
#define GPIO0_W 0x10
#define GPIO0_R 0x10

typedef unsigned long ul;
typedef unsigned int ui;
typedef uint64_t u64;
typedef uint32_t u32;
typedef uint16_t u16;
typedef uint8_t u8;


volatile u16* gpiow;
volatile u16* gpiooe;
volatile u16* gpior;

u64 tsToNs(const struct timespec& ts) {
	return u64(ts.tv_sec)*1000000000+ts.tv_nsec;
}
void delay(u64 ns) {
	struct timespec t,t2;
	clock_gettime(CLOCK_MONOTONIC,&t);
	while(1) {
		clock_gettime(CLOCK_MONOTONIC,&t2);
		if((tsToNs(t2)-tsToNs(t))>=ns) break;
	}
}
/*
 * gpio:
 *	 bit 0: cs
 *	 bit 1: scl
 *	 bit 2: sdi
 *	 bit 3: sdo
 * bin format:
 *	 string, "0" for 0, "1" for 1
 * example:
 *	 bin="100011101", len=9
 */
void spi_send(string bin) {
	int d=1000;
	*gpiow=1;
	*gpiooe=1+2+4;
	delay(d);
	
	*gpiow=0;	//pull down cs
	delay(d);
	
	for(int i=0;i<(int)bin.length();i++) {
		int bus=(bin[i]=='0'?0:1)<<2;
		*gpiow=bus;		//put bit on bus, sclk low
		delay(d);
		*gpiow=bus|2;	//sclk high
		delay(d);
	}
	*gpiow=0;	//sclk low
	delay(d);
	*gpiow=1;	//release cs
}
//returns binary string, MSB first
string toBinaryString(u64 val, int len) {
	char buf[len+1];
	for(int i=0;i<len;i++) {
		int bitpos=len-i-1;
		buf[i]=(val&(u64(1)<<bitpos))?'1':'0';
	}
	buf[len]=0;
	return string(buf);
}
int main(int argc,char** argv) {
	if(argc<2) {
		fprintf(stderr,"usage: %s N\n",argv[0]);
		return 1;
	}
	int N=atoi(argv[1]);
	int fd;
	if((fd = open("/dev/mem", O_RDWR | O_SYNC)) < 0) {
		printf( "ERROR: could not open \"/dev/mem\"...\n" ); return 1;
	}
	//u8* h2f = (u8*)mmap( NULL, H2F_SPAN, ( PROT_READ | PROT_WRITE ), MAP_SHARED, fd, H2F_BASE);
	u8* hwreg = (u8*)mmap( NULL, HW_REGS_SPAN, ( PROT_READ | PROT_WRITE ), MAP_SHARED, fd, HW_REGS_BASE);
	u8* lwh2f=hwreg+LWH2F_OFFSET;
	gpiow=(volatile u16*)(lwh2f+GPIO0_W);
	gpiooe=gpiow+1;
	gpior=(volatile u16*)(lwh2f+GPIO0_R);
	spi_send("00000010"		//addr
			"00100000"		//1
			"00001100"		//2
			"01010000"		//3
			"00000001"		//4
			+ toBinaryString(N,16) +
			"01100011"		//7
			"01111100"		//8		OD=100
			"00011100"		//9
			"11000000"		//a
			);
	return 0;
}
