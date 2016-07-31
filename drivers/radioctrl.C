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
#include <assert.h>

using namespace std;

#define H2F_BASE (0xC0000000) // axi_master
#define H2F_SPAN (0x40000000) // Bridge span
#define HW_REGS_BASE ( 0xFC000000 )     //misc. registers
#define HW_REGS_SPAN ( 0x04000000 )


#define LWH2F_OFFSET 52428800
#define PIO_0 0x10

typedef unsigned long ul;
typedef unsigned int ui;
typedef uint64_t u64;
typedef uint32_t u32;
typedef uint16_t u16;
typedef uint8_t u8;

volatile u32* gpio;

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

int mask=1<<31;

void handleExit(int sig) {
	//disable device
	if(gpio!=NULL) {
		*gpio &= ~mask;
	}
	if(sig!=0) fprintf(stderr,"got signal %d\n",sig);
	exit(1);
}
int main(int argc,char** argv) {
	//read commands from stdin, one line at a time:
	//commands:
	//e		// turn on device
	//d		// turn off device
	
	
	
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
	
	sa.sa_handler=handleExit;
	assert(sigaction(SIGINT, &sa, NULL)==0);
	assert(sigaction(SIGQUIT, &sa, NULL)==0);
	assert(sigaction(SIGILL, &sa, NULL)==0);
	assert(sigaction(SIGFPE, &sa, NULL)==0);
	assert(sigaction(SIGTERM, &sa, NULL)==0);
	assert(sigaction(SIGABRT, &sa, NULL)==0);
	assert(sigaction(SIGSEGV, &sa, NULL)==0);
	
	int fd;
	if((fd = open("/dev/mem", O_RDWR | O_SYNC)) < 0) {
		printf( "ERROR: could not open \"/dev/mem\"...\n" ); return 1;
	}
	//u8* h2f = (u8*)mmap( NULL, H2F_SPAN, ( PROT_READ | PROT_WRITE ), MAP_SHARED, fd, H2F_BASE);
	u8* hwreg = (u8*)mmap( NULL, HW_REGS_SPAN, ( PROT_READ | PROT_WRITE ), MAP_SHARED, fd, HW_REGS_BASE);
	u8* lwh2f=hwreg+LWH2F_OFFSET;
	gpio=(volatile u32*)(lwh2f+PIO_0);
	*gpio&=~mask;
	
	char cmd=0;
	//timer_t timerid;
	while(scanf(" %c",&cmd)>=1) {
		switch(cmd) {
			case 'e':
				*gpio |= mask;
				/*timerid=0;
				struct sigevent sev;
				sev.sigev_notify = SIGEV_SIGNAL;
				sev.sigev_signo = SIGRTMIN;
				sev.sigev_value.sival_ptr = &timerid;
				timer_create(CLOCK_MONOTONIC,&sev,&timerid);*/
				fprintf(stderr,"enabling device\n");
				break;
			case 'd':
				*gpio &= ~mask;
				fprintf(stderr,"disabling device\n");
				break;
		}
	}
	
	return 0;
}
