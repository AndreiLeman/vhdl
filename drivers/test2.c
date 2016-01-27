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
#include <poll.h>

#define H2F_BASE (0xC0000000) // axi_master
#define H2F_SPAN (0x40000000) // Bridge span
#define HW_REGS_BASE ( 0xFC000000 )	//misc. registers
#define HW_REGS_SPAN ( 0x04000000 )


#define LWH2F_OFFSET 52428800
#define AUDIO_SRAM_ADDR 0
#define AUDIO_SRAM_SIZE 65536
#define AUDIO_REGS_ADDR 0

#define AUDIO_REG_RPOS 1

typedef unsigned long ul;
typedef uint8_t u8;
typedef uint64_t u64;
typedef struct pollfd pollfd;

volatile u8* sram;
void handle_signal(int sig) {
	memset((void*)sram,0,AUDIO_SRAM_SIZE);
	exit(0);
}
int readAll(int fd,void* buf, int len) {
	u8* buf1=(u8*)buf;
	int off=0;
	int r;
	while(off<len) {
		if((r=read(fd,buf1+off,len-off))<=0) break;
		off+=r;
	}
	return off;
}
u64 timerBegin();
void timerEnd(u64 tmp);
int _readIrq(int fd) {
	int irqcount;
	u64 tmp=timerBegin();
	if(read(fd,&irqcount,sizeof(irqcount))>0) {
//		timerEnd(tmp);
		return irqcount;
	}
	return -1;
}
int waitForIrq(int fd) {
	int irqen=1;
	write(fd,&irqen,sizeof(irqen));
	int irqcount;
	pollfd pfd;
	pfd.fd = fd;
	pfd.events = POLLIN;
	while(poll(&pfd, 1, 0)>0) {
		fprintf(stderr,"missed interrupt\n");
		_readIrq(fd);
		write(fd,&irqen,sizeof(irqen));
	}
	return _readIrq(fd);
}
u64 timerBegin() {
	struct timespec t;
	clock_gettime(CLOCK_MONOTONIC,&t);
	return (u64)t.tv_sec*1000+t.tv_nsec/1000000;
}
void timerEnd(u64 tmp) {
	struct timespec t;
	clock_gettime(CLOCK_MONOTONIC,&t);
	u64 t1=(u64)t.tv_sec*1000+t.tv_nsec/1000000;
	fprintf(stderr,"%.2f seconds\n",(double)(t1-tmp)/1000);
}
int main() {
	int irqfd = open("/dev/uio0", O_RDWR|O_SYNC);
	int fd;
	if((fd = open("/dev/mem", O_RDWR | O_SYNC)) < 0) {
		printf( "ERROR: could not open \"/dev/mem\"...\n" ); return 1;
	}
	u8* h2f = (u8*)mmap( NULL, H2F_SPAN, ( PROT_READ | PROT_WRITE ), MAP_SHARED, fd, H2F_BASE);
	u8* hwreg = (u8*)mmap( NULL, HW_REGS_SPAN, ( PROT_READ | PROT_WRITE ), MAP_SHARED, fd, HW_REGS_BASE);
	sram=(u8*)(h2f+AUDIO_SRAM_ADDR);
	volatile u8* regs=(u8*)(hwreg+LWH2F_OFFSET+AUDIO_REGS_ADDR);
	signal(SIGINT, handle_signal);
	signal(SIGTERM, handle_signal);
	int irqcount,irqen=2;
	write(irqfd,&irqen,sizeof(irqen));
	
	//u8* buf=(u8*)malloc(AUDIO_SRAM_SIZE/2);
	while((irqcount=waitForIrq(irqfd))>=0) {
		//printf("%i\n",irqcount);
		int rpos1; rpos1=(*regs)&AUDIO_REG_RPOS;
		int rpos2; rpos2=rpos1!=0;
		int rpos; rpos=rpos2?(AUDIO_SRAM_SIZE/2):0;
		int wpos; wpos=rpos2?0:(AUDIO_SRAM_SIZE/2);
		if(readAll(0,(void*)(sram+wpos),AUDIO_SRAM_SIZE/2)<=0) {
			//eof reached; clear next buffer, wait for current buffer to finish playing,
			//then exit
			memset((void*)(sram+wpos),0,AUDIO_SRAM_SIZE/2);
			waitForIrq(irqfd);
			break;
		}
		if(rpos1!=((*regs)&AUDIO_REG_RPOS)) {
			//data arrived too late; we're already on the next buffer
			memcpy((void*)(sram+rpos),(void*)(sram+wpos),AUDIO_SRAM_SIZE/2);
			memset((void*)(sram+wpos),0,AUDIO_SRAM_SIZE/2);
			fprintf(stderr,"buffer underrun\n");
		}
	}
	handle_signal(0);
}
