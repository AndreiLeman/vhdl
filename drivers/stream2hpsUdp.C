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
#include <poll.h>
#include <sys/socket.h>
#include <netdb.h>

typedef unsigned long ul;
typedef unsigned int ui;
typedef uint8_t u8;
typedef uint32_t u32;
typedef struct {
	size_t size;
	unsigned long physAddr;
} xaxaxadma_allocArg;

static const int bufSize=1024*1024*16;

#define H2F_BASE (0xC0000000) // axi_master
#define H2F_SPAN (0x40000000) // Bridge size
#define HW_REGS_BASE ( 0xFC000000 )     //misc. registers
#define HW_REGS_SPAN ( 0x04000000 )
#define LWH2F_OFFSET 52428800

#define STREAM2HPS_CONFIG_OFFSET 0x40
#define STREAM2HPS_IRQ "/dev/uio1"

volatile u32* s2hRegs=NULL;


int udpConnect(const char* host, const char* port) {
	struct addrinfo hints;
	struct addrinfo *result, *rp;
	int s,sfd;
	memset(&hints, 0, sizeof(struct addrinfo));
	hints.ai_family = AF_UNSPEC;    /* Allow IPv4 or IPv6 */
	hints.ai_socktype = SOCK_DGRAM; /* Datagram socket */
	hints.ai_flags = 0;
	hints.ai_protocol = 0;          /* Any protocol */

	s = getaddrinfo(host, port, &hints, &result);
	if (s != 0) {
	   fprintf(stderr, "getaddrinfo: %s\n", gai_strerror(s));
	   return -1;
	}
	for (rp = result; rp != NULL; rp = rp->ai_next) {
		sfd = socket(rp->ai_family, rp->ai_socktype,
			   rp->ai_protocol);
		if (sfd == -1)
		   continue;
		if (connect(sfd, rp->ai_addr, rp->ai_addrlen) == 0)
		   break;                  /* Success */
		close(sfd);
	}
	freeaddrinfo(result);
	if (rp == NULL) return -1;
	
	socklen_t len, trysize, gotsize;
	len = sizeof(int);
	trysize = 67108864+32768;
	do {
		trysize -= 32768;
		setsockopt(sfd,SOL_SOCKET,SO_SNDBUF,(char*)&trysize,len);
		int err = getsockopt(sfd,SOL_SOCKET,SO_SNDBUF,(char*)&gotsize,&len);
		if (err < 0) { perror("getsockopt"); break; }
	} while (gotsize < trysize);
	printf("Size set to %d\n",gotsize);
	return sfd;
}
int sendAll(int fd, const u8* data, int len) {
	int written=0;
	int maxlen=1024*48;
	while(written<len) {
		int sz=len-written;
		if(sz>maxlen) sz=maxlen;
		int br=send(fd,data+written,sz,0);
		if(br<=0) break;
		written+=br;
	}
	//printf("sent %d MB\n",written/1024/1024);
	return written;
}

int _readIrq(int fd) {
	int irqcount;
	int irqen=1;
	if(read(fd,&irqcount,sizeof(irqcount))>0) {
		write(fd,&irqen,sizeof(irqen));
		return irqcount;
	}
	return -1;
}
int waitForIrq(int fd) {
	//return _readIrq(fd);
	pollfd pfd;
	pfd.fd = fd;
	pfd.events = POLLIN;
	if(poll(&pfd, 1, 0)>0) {
		fprintf(stderr,"missed interrupt\n");
		//_readIrq(fd);
	}
	return _readIrq(fd);
}


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
	if(argc<3) {
		printf("usage: %s ip port\n",argv[0]);
		return 1;
	}
	int sfd=udpConnect(argv[1],argv[2]);
	if(sfd<0) {
		printf("udp connect failed\n");
		return 1;
	}
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
	while((irqcount=waitForIrq(irqfd))>0) {
		//write(irqfd,&irqen,sizeof(irqen));
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
			sendAll(sfd,buffer,bufSize/2);
		else
			sendAll(sfd,buffer+bufSize/2,bufSize/2);
	}
	return 0;
}
