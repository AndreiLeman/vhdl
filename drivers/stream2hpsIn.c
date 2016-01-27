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
#include <sys/ioctl.h>
#include <assert.h>

typedef unsigned long ul;
typedef unsigned int ui;
typedef uint8_t u8;
typedef uint32_t u32;
typedef struct {
	size_t size;
	unsigned long physAddr;
} xaxaxadma_allocArg;

static const int bufSize=1024*1024*8;

#define H2F_BASE (0xC0000000) // axi_master
#define H2F_SPAN (0x40000000) // Bridge size
#define HW_REGS_BASE ( 0xFC000000 )     //misc. registers
#define HW_REGS_SPAN ( 0x04000000 )
#define LWH2F_OFFSET 52428800

#define STREAM2HPS_CONFIG_OFFSET 0x40
#define STREAM2HPS_IRQ "/dev/uio1"

volatile u32* s2hRegs=NULL;

void handleExit(int sig) {
	//disable device
	if(s2hRegs!=NULL) {
		s2hRegs[0]=s2hRegs[0]&(~(ui)1);
		struct timespec ts;
		ts.tv_sec=0;
		ts.tv_nsec=1000*1000*10;
		fprintf(stderr,"disabling device\n");
		nanosleep(&ts,NULL);
	}
	exit(1);
}
int main(int argc,char** argv) {
	//should always do this at the beginning of EVERY program you ever write
	//***************************************
	//ignore SIGHUP and SIGPIPE
	struct sigaction sa;
	sa.sa_handler = SIG_IGN;
	sigemptyset(&sa.sa_mask);
	sa.sa_flags = SA_RESTART; /* Restart system calls if interrupted by handler */
	assert(sigaction(SIGHUP, &sa, NULL)==0);
	assert(sigaction(SIGPIPE, &sa, NULL)==0);
	sa.sa_handler = SIG_DFL;
	assert(sigaction(SIGCONT, &sa, NULL)==0);
	assert(sigaction(SIGTSTP, &sa, NULL)==0);
	assert(sigaction(SIGTTIN, &sa, NULL)==0);
	assert(sigaction(SIGTTOU, &sa, NULL)==0);
	//***************************************
	sa.sa_handler=handleExit;
	assert(sigaction(SIGINT, &sa, NULL)==0);
	assert(sigaction(SIGQUIT, &sa, NULL)==0);
	assert(sigaction(SIGILL, &sa, NULL)==0);
	assert(sigaction(SIGFPE, &sa, NULL)==0);
	assert(sigaction(SIGTERM, &sa, NULL)==0);
	assert(sigaction(SIGABRT, &sa, NULL)==0);
	assert(sigaction(SIGSEGV, &sa, NULL)==0);
	
	//allocate the dma buffer
	int dmafd=open("/dev/xaxaxadma",O_RDWR);
	if(dmafd<0) {
		perror("open"); return -1;
	}
	xaxaxadma_allocArg arg;
	arg.size=bufSize;
	if(ioctl(dmafd,1,&arg)<0) {
		perror("ioctl"); return -1;
	}
	
	//map device registers and dma buffer into VM
	int memfd;
	if((memfd = open("/dev/mem", O_RDWR | O_SYNC)) < 0) {
		printf( "ERROR: could not open \"/dev/mem\"...\n" ); return 1;
	}
	//u8* h2f = (u8*)mmap( NULL, H2F_SPAN, ( PROT_READ | PROT_WRITE ), MAP_SHARED, memfd, H2F_BASE);
	u8* hwreg = (u8*)mmap( NULL, HW_REGS_SPAN, ( PROT_READ | PROT_WRITE ), MAP_SHARED, memfd, HW_REGS_BASE);
	u8* buffer = (u8*)mmap( NULL, bufSize, ( PROT_READ | PROT_WRITE ), MAP_SHARED, memfd, arg.physAddr);
	
	s2hRegs=(volatile u32*)(hwreg+LWH2F_OFFSET+STREAM2HPS_CONFIG_OFFSET);
	
	
	struct timespec ts;
	ts.tv_sec=0;
	ts.tv_nsec=1000*1000*10;
	
	
	ui baseAddr=arg.physAddr;
	ui endAddr=baseAddr+bufSize;
	ui midAddr=baseAddr/2+endAddr/2;
	
	//disable device first
	s2hRegs[0]=s2hRegs[0]&(~(ui)1);	
	nanosleep(&ts,NULL);
	
	//set addresses but don't enable device
	s2hRegs[1]=endAddr;
	s2hRegs[0]=baseAddr&(~(ui)1);
	//wait to ensure device received the newest config
	nanosleep(&ts,NULL);
	
	//enable device
	s2hRegs[0]=baseAddr|1;
	
	//wait for interrupts
	int irqfd = open(STREAM2HPS_IRQ, O_RDWR|O_SYNC);
	if(irqfd<0) {
		perror("open irqfd");
		return 1;
	}
	int irqcount,irqen=1,irqcount2=0,irqprev;
	write(irqfd,&irqen,sizeof(irqen));
	while(read(irqfd,&irqcount,sizeof(irqcount))>0) {
		write(irqfd,&irqen,sizeof(irqen));
		irqcount2++;
		if(irqcount2==1) {
			irqprev=irqcount;
			continue;
		}
		ui pos=s2hRegs[2];
		fprintf(stderr,"received %d interrupts; position=%x\n",irqcount,pos);
		if(irqcount!=irqprev+1)
			fprintf(stderr,"!!!!!MISSED %d INTERRUPTS!!!!!\n",irqcount-irqprev-1);
		irqprev=irqcount;
		
		if(pos>=midAddr)
			write(1,buffer,bufSize/2);
		else
			write(1,buffer+bufSize/2,bufSize/2);
	}
	return 0;
}
