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

#define H2F_BASE (0xC0000000) // axi_master
#define H2F_SPAN (0x40000000) // Bridge span
#define HW_REGS_BASE ( 0xFC000000 )     //misc. registers
#define HW_REGS_SPAN ( 0x04000000 )

//registers; relative to HW_REGS_BASE
#define REG_sdr 0x3c20000
#define REG_sdr_mppriority 0x50AC	// relative to REG_sdr

#define LWH2F_OFFSET 52428800
#define FB_CONFIG_OFFSET 0x50

typedef unsigned long ul;
typedef unsigned int ui;
typedef uint8_t u8;

int main(int argc,char** argv) {
	if(argc<2) {
		printf("usage: %s ADDR\n",argv[0]);
		return 1;
	}
	int fd;
	if((fd = open("/dev/mem", O_RDWR | O_SYNC)) < 0) {
		printf( "ERROR: could not open \"/dev/mem\"...\n" ); return 1;
	}
	//u8* h2f = (u8*)mmap( NULL, H2F_SPAN, ( PROT_READ | PROT_WRITE ), MAP_SHARED, fd, H2F_BASE);
	u8* hwreg = (u8*)mmap( NULL, HW_REGS_SPAN, ( PROT_READ | PROT_WRITE ), MAP_SHARED, fd, HW_REGS_BASE);
	u8* tmp=hwreg+LWH2F_OFFSET+FB_CONFIG_OFFSET;
	volatile ui* tmp1=(volatile ui*)tmp;

	
	ul addr=strtol(argv[1],NULL,16);

	//fb address
	tmp1[0]=addr & ~(ul)1;
	//size
	tmp1[1]=addr+(320*240)*4;
	
	usleep(1000);	//1ms
	
	//enable device
	tmp1[0]=addr | 1;

	//set sdram priority
	volatile ui* mppriority=(volatile ui*)(hwreg+REG_sdr+REG_sdr_mppriority);
	*mppriority=7;

	return 0;
}
