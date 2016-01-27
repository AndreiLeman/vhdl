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


#define LWH2F_OFFSET 52428800

typedef unsigned long ul;
typedef unsigned int ui;
typedef uint8_t u8;

int main(int argc,char** argv) {
	if(argc<2) {
		printf("usage: %s ADDR\nADDR is the offset from the LWHPS2FPGA address\n"
			"reads one 32-bit word and displays it in hex\n"
			"all values in hex (without 0x)\n",argv[0]);
		return 1;
	}
	int fd;
	if((fd = open("/dev/mem", O_RDWR | O_SYNC)) < 0) {
		printf( "ERROR: could not open \"/dev/mem\"...\n" ); return 1;
	}
	//u8* h2f = (u8*)mmap( NULL, H2F_SPAN, ( PROT_READ | PROT_WRITE ), MAP_SHARED, fd, H2F_BASE);
	u8* hwreg = (u8*)mmap( NULL, HW_REGS_SPAN, ( PROT_READ | PROT_WRITE ), MAP_SHARED, fd, HW_REGS_BASE);
	u8* tmp_=hwreg+LWH2F_OFFSET+strtol(argv[1],NULL,16);
	volatile ui* tmp=(volatile ui*)tmp_;
	printf("%x\n",*tmp);
	return 0;
}
