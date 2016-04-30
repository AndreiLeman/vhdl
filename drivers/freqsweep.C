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
#define FREQDETECTOR_W 0x20
#define FREQDETECTOR_R (FREQDETECTOR_W+8)

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
	int d=100;
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
u8 spi_recv(spi_gpio_info inf,u8 addr) {
	u16 spi_cs=inf.cs,spi_scl=inf.scl,spi_sdi=inf.sdi,spi_sdo=inf.sdo;
	addr=(addr<<1)|1;
	u8 result=0;
	int d=100;
	*gpiow |= spi_cs;						//make sure cs is high
	*gpiooe |= spi_cs|spi_scl|spi_sdi;		//enable write for spi output pins
	*gpiooe &= ~spi_sdo;					//make sure sdo pin is set to read
	delay(d);
	
	*gpiow &= ~spi_cs;		//pull down cs
	delay(d);
	for(int i=7;i>=0;i--) {
		*gpiow &= ~spi_scl;		//scl low
		if(addr&(1<<i))			//put bit on bus
			*gpiow |= spi_sdi;
		else
			*gpiow &= ~spi_sdi;
		
		delay(d);
		*gpiow |= spi_scl;		//scl high
		delay(d);
	}
	for(int i=7;i>=0;i--) {
		*gpiow &= ~spi_scl;				//scl low
		delay(d);
		
		int bit=(*gpior) & spi_sdo;		//read sdo
		if(bit) result|=(1<<i);
		*gpiow |= spi_scl;				//scl high
		
		delay(d);
	}
	*gpiow &= ~spi_scl;		//scl low
	delay(d);
	*gpiow |= spi_cs;		//cs high
	delay(d);
	//fprintf(stderr,"received: %x\n",(int)result);
	return result;
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
	
	//calculate addresses of device registers
	gpiow=(volatile u16*)(lwh2f+GPIO0_W);
	gpiooe=gpiow+1;
	gpior=(volatile u16*)(lwh2f+GPIO0_R);
	freqdetector_w=(volatile u32*)(lwh2f+FREQDETECTOR_W);
	freqdetector_r=(volatile s32*)(lwh2f+FREQDETECTOR_R);
	
	//signal generator pll board gpios
	spi_gpio_info pll_signalgen = {
		.cs=1<<0,
		.scl=1<<1,
		.sdi=1<<2,
		.sdo=1<<3
	};
	
	//LO pll board gpios
	spi_gpio_info pll_lo = {
		.cs=1<<8,
		.scl=1<<9,
		.sdi=1<<7,
		.sdo=1<<7
	};
	
	
	
	int srate=50000000;								//sample rate; Hz
	int pll_pfd=1000000;							//pll channel separation, Hz
	int pll_od=4;									//pll output frequency divider value
	double freqIncrement=double(pll_pfd)/pll_od;	//pll frequency increment
	double ffreqIncrement=freqIncrement/srate;
	
	while(1) {
		for(int basefreq=600;basefreq<1000;basefreq+=10) {
			for(int x=0;x<2;x++)
				spi_send(pll_lo,
					"00000010"		//addr
					"00100000"		//1
					"00001100"		//2
					"01010000"		//3
					"00000001"		//4
					+ toBinaryString(basefreq/10*4,16) +
					"01100011"		//7
					"01101010"		//8		OD=010
					"00010100"		//9
					"11000000"		//a
					);
			
			//i is the N offset of the pll; frequency offset is freqIncrement*i
			for(int i=4;i<=40;i+=4) {
				double freq=ffreqIncrement*i;
				
				//set pll
				int N=basefreq*pll_od+i;
			do_set_pll:
				spi_send(pll_signalgen,
					"00000010"		//addr
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
				while((spi_recv(pll_signalgen,0)&(1<<2)) == 0);
				if(spi_recv(pll_signalgen,6) != u8(N&0xff)) {
					fprintf(stderr,"PLL SPI TRANSMISSION ERROR DETECTED!!!! N=%d\n",N);
					goto do_set_pll;
				}
				
			sdfgh:;
				//set freqdetector frequency
				u32 hwfreq=u32(freq*(1<<28));
				if(hwfreq==(1<<28)) hwfreq--;
				freqdetector_w[0]=hwfreq;			//set frequency register
				freqdetector_w[1]=u32(1)<<31;		//enable device
				
				//wait for freqdetector to settle
				delay(1000000);
				
				//disable device to avoid race condition when reading data
				freqdetector_w[1]=0;
				delay(100);
				
				//read out i/q data
				s32 datai,dataq;
				datai=freqdetector_r[0];
				dataq=freqdetector_r[1];
				
				//i/q data spans only the lower 17 bits, so shift it to fullscale
				datai <<= 15;
				dataq <<= 15;
				
				//calculate and print signal power i^2 + q^2 in dB
				double datai1=datai/pow(2,31);
				double dataq1=dataq/pow(2,31);
				double data=pow(datai1,2)+pow(dataq1,2);
				double dataangle=atan2(dataq,datai);
				double datadb=log(data)/log(10)*10;
				printf("%lf %lf\n",freqIncrement*i+basefreq*1000000,datadb);
				//printf("%lf %lf\n",freqIncrement*i,dataangle);
			}
		}
		printf("\n");
		fflush(stdout);
	}
	return 0;
}
