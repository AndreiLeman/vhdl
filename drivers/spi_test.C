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
#include <math.h>

using namespace std;

#define H2F_BASE (0xC0000000) // axi_master
#define H2F_SPAN (0x40000000) // Bridge span
#define HW_REGS_BASE ( 0xFC000000 )     //misc. registers
#define HW_REGS_SPAN ( 0x04000000 )


#define LWH2F_OFFSET 52428800
#define GPIO0_W 0x0
#define GPIO0_R 0x10

typedef unsigned long ul;
typedef unsigned int ui;
typedef uint64_t u64;
typedef uint32_t u32;
typedef uint16_t u16;
typedef uint8_t u8;

typedef int32_t s32;


volatile u16* gpiow;
volatile u16* gpiooe;
volatile u16* gpior;

volatile s32* freqdetector_r;
volatile u32* freqdetector_w;

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

struct spi_gpio_info {
	//bitmask of each pin
	u16 cs,scl,sdi,sdo;
};
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
void spi_send(spi_gpio_info inf,string bin) {
	u16 spi_cs=inf.cs,spi_scl=inf.scl,spi_sdi=inf.sdi,spi_sdo=inf.sdo;
	int d=10000;
	*gpiow |= spi_cs;						//make sure cs is high
	*gpiooe |= spi_cs|spi_scl|spi_sdi;		//enable write for spi output pins
	*gpiooe &= ~spi_sdo;					//make sure sdo pin is set to read
	delay(d);
	
	*gpiow &= ~spi_cs;		//pull down cs
	delay(d);
	
	for(int i=0;i<(int)bin.length();i++) {
		*gpiow &= ~spi_scl;		//scl low
		if(bin[i]!='0')			//put bit on bus
			*gpiow |= spi_sdi;
		else
			*gpiow &= ~spi_sdi;

		delay(d);
		*gpiow |= spi_scl;		//scl high
		delay(d);
	}
	*gpiow &= ~spi_scl;		//scl low
	delay(d);
	*gpiow |= spi_cs;		//cs high
	delay(d);
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
		fprintf(stderr,"usage: %s BITSTRING\n",argv[0]);
		return 1;
	}
	int fd;
	if((fd = open("/dev/mem", O_RDWR | O_SYNC)) < 0) {
		printf( "ERROR: could not open \"/dev/mem\"...\n" ); return 1;
	}
	//u8* h2f = (u8*)mmap( NULL, H2F_SPAN, ( PROT_READ | PROT_WRITE ), MAP_SHARED, fd, H2F_BASE);
	u8* hwreg = (u8*)mmap( NULL, HW_REGS_SPAN, ( PROT_READ | PROT_WRITE ), MAP_SHARED, fd, HW_REGS_BASE);
	u8* lwh2f=hwreg+LWH2F_OFFSET;
	
	//calculate addresses of device registers
	gpiow=(volatile u16*)(lwh2f+GPIO0_W);
	gpiooe=gpiow+1;
	gpior=(volatile u16*)(lwh2f+GPIO0_R);
	spi_gpio_info inf = {
		.cs=1<<12,
		.scl=1<<10,
		.sdi=1<<11,
		.sdo=1<<13
	};
	spi_send(inf,argv[1]);
	return 0;
}
