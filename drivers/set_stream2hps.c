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
#define STREAM2HPS_CONFIG_OFFSET 0x40

typedef unsigned long ul;
typedef unsigned int ui;
typedef uint8_t u8;

int main(int argc,char** argv) {
	if(argc<3) {
		printf("usage: %s ADDR LEN\nall values in hex (without 0x)\n",argv[0]);
		return 1;
	}
	int fd;
	if((fd = open("/dev/mem", O_RDWR | O_SYNC)) < 0) {
		printf( "ERROR: could not open \"/dev/mem\"...\n" ); return 1;
	}
	//u8* h2f = (u8*)mmap( NULL, H2F_SPAN, ( PROT_READ | PROT_WRITE ), MAP_SHARED, fd, H2F_BASE);
	u8* hwreg = (u8*)mmap( NULL, HW_REGS_SPAN, ( PROT_READ | PROT_WRITE ), MAP_SHARED, fd, HW_REGS_BASE);
	u8* tmp_=hwreg+LWH2F_OFFSET+STREAM2HPS_CONFIG_OFFSET;
	volatile ui* tmp=(volatile ui*)tmp_;

	tmp[0]=tmp[0]&(~(ui)1);	//disable device first
	//wait to ensure device is disabled
	struct timespec ts;
	ts.tv_sec=0;
	ts.tv_nsec=1000*1000*10;
	nanosleep(&ts,NULL);

	ui baseAddr=strtol(argv[1],NULL,16);
	ui endAddr=baseAddr+strtol(argv[2],NULL,16);
	if(baseAddr==endAddr) return 0;

	//set addresses but don't enable device
	tmp[1]=endAddr;
	tmp[0]=baseAddr&(~(ui)1);

	//wait to ensure device received the newest config
	ts.tv_sec=0;
	ts.tv_nsec=1000*1000*10;
	nanosleep(&ts,NULL);

	//enable device
	tmp[0]=baseAddr|1;
	
	//wait for irqs
	int irqfd = open("/dev/uio1", O_RDWR|O_SYNC);
	if(irqfd<0) {
		perror("open irqfd");
		return 1;
	}
	int irqcount,irqen=1;
	write(irqfd,&irqen,sizeof(irqen));
	while(read(irqfd,&irqcount,sizeof(irqcount))>0) {
		write(irqfd,&irqen,sizeof(irqen));
		printf("received %d interrupts; devInfo=%x\n",irqcount,tmp[2]);
	}

	return 0;
}
