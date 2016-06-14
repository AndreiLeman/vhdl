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
//	u64 tmp=timerBegin();
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
inline int readRpos(volatile u8* regs) {
	return ((*regs)&AUDIO_REG_RPOS)!=0;
}
int main() {
	//should always do this at the beginning of EVERY program you ever write
	//***************************************
	//ignore SIGHUP and SIGPIPE
	struct sigaction sa;
	sa.sa_handler = SIG_IGN;
	sigemptyset(&sa.sa_mask);
	sa.sa_flags = SA_RESTART; /* Restart system calls if interrupted by handler */
	sigaction(SIGHUP, &sa, NULL);
	sigaction(SIGPIPE, &sa, NULL);
	sa.sa_handler = SIG_DFL;
	sigaction(SIGCONT, &sa, NULL);
	sigaction(SIGTSTP, &sa, NULL);
	sigaction(SIGTTIN, &sa, NULL);
	sigaction(SIGTTOU, &sa, NULL);
	//***************************************
	
	
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
	int irqcount,irqen=1;
	write(irqfd,&irqen,sizeof(irqen));
	irqcount=_readIrq(irqfd);
	write(irqfd,&irqen,sizeof(irqen));
	
	int lastRpos=readRpos(regs);
	int woffset=0;
	pollfd pfd[2];
	pfd[0].fd = 0;	//stdin
	pfd[0].events = POLLIN;
	pfd[1].fd=irqfd;
	pfd[1].events=POLLIN;
	while(poll(pfd, 2, -1)>0) {
		int shouldClear=0;
		if(pfd[1].revents!=0) {	//one or more interrupts were received
			int newirqcount=_readIrq(irqfd);
			if(newirqcount!=(irqcount+1)) {
				fprintf(stderr,"missed interrupt\n");
			}
			irqcount=newirqcount;
			shouldClear=1;
			woffset=0;
			//enable monitoring stdin
			if(pfd[0].events==0) {
				pfd[0].events=POLLIN;
				//set POLLIN since we know stdin is readable because
				//monitoring is only disabled after a readable notification
				//has happened
				pfd[0].revents |= POLLIN;
			}
			write(irqfd,&irqen,sizeof(irqen));
			lastRpos=readRpos(regs);
		}
		int wpos=lastRpos?0:(AUDIO_SRAM_SIZE/2);
		if(pfd[0].revents!=0) {	//data is available on stdin
			if(woffset==AUDIO_SRAM_SIZE/2) {
				//buffer full; disable monitoring stdin
				pfd[0].events=0;
				continue;
			}
			int br=read(0,(void*)(sram+wpos+woffset),AUDIO_SRAM_SIZE/2-woffset);
			if(br<=0) {
				//eof reached; clear next buffer and wait for current buffer to finish playing
				memset((void*)(sram+wpos+woffset),0,AUDIO_SRAM_SIZE/2-woffset);
				waitForIrq(irqfd);
				if(woffset>0) {	//next (now current) buffer had partial data in it; wait for it too
					wpos=readRpos(regs)?0:(AUDIO_SRAM_SIZE/2);
					memset((void*)(sram+wpos),0,AUDIO_SRAM_SIZE/2);
					waitForIrq(irqfd);
				}
				break;
			}
			woffset+=br;
			if(shouldClear) {
				//if this is the first time this buffer is written,
				//	clear the remaining space so that garbage does not
				//	get played in case not enough audio data was available
				//	in time to fill the buffer
				memset((void*)(sram+wpos+woffset),0,AUDIO_SRAM_SIZE/2-woffset);
			}
			if(lastRpos!=readRpos(regs))
				fprintf(stderr,"buffer underrun caused by slow execution\n");
		} else if(shouldClear) {
			//data wasn't available in time; clear buffer to avoid playing garbage
			//memset((void*)(sram+wpos),0,AUDIO_SRAM_SIZE/2);
			for(int i=wpos;i<wpos+(AUDIO_SRAM_SIZE/2);i++) {
				sram[i]=0;
			}
			fprintf(stderr,"buffer underrun\n");
		}
	}
	
	handle_signal(0);
	return 0;
}
