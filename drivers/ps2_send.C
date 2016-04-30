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
#define GPIO0_W 0x0
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
 *	 bit 4: ps2_clk
 *	 bit 5: ps2_dat
 * sends 1 byte.
 */
u16 PS2_CLK=1<<4;
u16 PS2_DAT=1<<5;
int ps2_delay=30000;	//ns; half a clock cycle
void ps2_pulldat() {
	*gpiooe |= PS2_DAT;
}
void ps2_releasedat() {
	*gpiooe &= ~PS2_DAT;
}
void ps2_pullclk() {
	*gpiooe |= PS2_CLK;
}
void ps2_releaseclk() {
	*gpiooe &= ~PS2_CLK;
}/*
void ps2_pulldat() {
	*gpiow &= ~PS2_DAT;
}
void ps2_releasedat() {
	*gpiow |= PS2_DAT;
}
void ps2_pullclk() {
	*gpiow &= ~PS2_CLK;
}
void ps2_releaseclk() {
	*gpiow |= PS2_CLK;
}*/

int ps2_sendbit(int bit) {
	int d=ps2_delay;
	//put data on bus
	if(bit) ps2_releasedat();		//release dat
	else ps2_pulldat();				//pull down dat
	
	delay(d/2);
	ps2_pullclk();		//pull down clk
	delay(d);
	int readdata=int((*gpior & PS2_DAT)!=0);
	ps2_releaseclk();	//release clk
	delay(d/2);
	return readdata;
}
void ps2_send(u8 data) {
	
	int d=ps2_delay;		//ns
	
	*gpiooe &= ~(PS2_CLK|PS2_DAT);
	*gpiooe = 0;
	*gpiow &= ~(PS2_CLK|PS2_DAT);
	printf("sending: %x\n",(int)data);
	printf("gpior: %x\n",(int)*gpior);
	printf("dat: %d\n",int((*gpior & PS2_DAT)!=0));
	printf("clk: %d\n",int((*gpior & PS2_CLK)!=0));
	
	//*gpiow |= PS2_CLK|PS2_DAT;
	//*gpiooe |= PS2_CLK|PS2_DAT;
	
	//pulse the clock until dat goes high for 10 cycles
	/*int cnt=0;
	while(1) {
		if((*gpior & PS2_DAT)==0) {
			cnt=0;
		} else {
			cnt++;
			if(cnt>50) break;
		}
		ps2_pullclk();		//pull down clk
		delay(d);
		ps2_releaseclk();	//release clk
		delay(d);
	}*/
	
	ps2_sendbit(0);			//start bit
	
	int parity=1;
	for(int i=0;i<8;i++) {
		if(data&(1<<i)) parity++;
		ps2_sendbit(data&(1<<i));
	}
	//put parity bit on bus
	ps2_sendbit(parity&1);
	
	//put stop bit on bus
	ps2_sendbit(1);
	
	
	
	delay(d);
	printf("dat: %d\n",int((*gpior & PS2_DAT)!=0));
	printf("clk: %d\n",int((*gpior & PS2_CLK)!=0));
}
int main(int argc,char** argv) {
	if(argc<2) {
		fprintf(stderr,"usage: %s XX\n",argv[0]);
		return 1;
	}
	u8 data=(u8)strtol(argv[1],NULL,16);
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
	
	int d=ps2_delay;
	
	if(data!=0)
		ps2_send(data);
	//respond to host communications
	while(1) {
		//check if host pulled down clk
		if((*gpior & PS2_CLK)==0) {
			for(int i=0;i<100;i++)
				if((*gpior & PS2_CLK)!=0) goto cont1;
			//wait for clk to go high
			while(1) {
				while((*gpior & PS2_CLK)==0);
				for(int i=0;i<100;i++)
					if((*gpior & PS2_CLK)==0) goto cont;
				break;
			cont:;
			}
			int readdata=0;
			for(int i=0;i<10;i++)
				readdata |= ps2_sendbit(1) << i;
			ps2_sendbit(0);		//ack bit
			
			printf("READ DATA: %x\n",readdata);
			
			int req=readdata&0xFF;
			int resp;
			switch(req) {
				case 0xEE:
					resp=0xEE;
					break;
				case 0xFF:
					resp=0xAA;
					break;
				default:
					resp=0xFA;
			}
			ps2_send(resp);
			if(req==0xF2) {
				delay(d);
				ps2_send(0xAB);
				//delay(d);
				//ps2_send(0xC1);
			}
		}
		cont1:;
	}
	return 0;
}
