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
#include <deque>
#include <sys/socket.h>
#include <netdb.h>

using namespace std;

typedef unsigned long ul;
typedef unsigned int ui;
typedef uint8_t u8;
typedef uint32_t u32;
typedef struct {
	size_t size;
	unsigned long physAddr;
} xaxaxadma_allocArg;

static const int bufSize=1024*1024*4;
static const int bufCount=10;

#define H2F_BASE (0xC0000000) // axi_master
#define H2F_SPAN (0x40000000) // Bridge size
#define HW_REGS_BASE ( 0xFC000000 )     //misc. registers
#define HW_REGS_SPAN ( 0x04000000 )
#define LWH2F_OFFSET 52428800

#define STREAM2HPS_CONFIG_OFFSET 0x40
#define STREAM2HPS_IRQ "/dev/uio1"

volatile u32* s2hRegs=NULL;

int dmafd[bufCount];
ui baseAddr[bufCount];
u8* buffers[bufCount];


int mod(int a, int b) {
	while(a>=b) a-=b;
	while(a<0) a+=b;
	return a;
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

//clear outstanding irqs if any
void clearIrq(int fd) {
	pollfd pfd;
	pfd.fd = fd;
	pfd.events = POLLIN;
	while(poll(&pfd, 1, 0)>0) {
		_readIrq(fd);
	}
}


int tcpAccept(const char* host, const char* port) {
	struct addrinfo hints;
	struct addrinfo *result, *rp;
	int s,sfd;
	memset(&hints, 0, sizeof(struct addrinfo));
	hints.ai_family = AF_UNSPEC;    /* Allow IPv4 or IPv6 */
	hints.ai_socktype = SOCK_STREAM;
	hints.ai_flags = AI_PASSIVE;
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
		
		int enable = 1;
		if (setsockopt(sfd, SOL_SOCKET, SO_REUSEADDR, &enable, sizeof(int)) < 0)
			perror("warning: setsockopt(SO_REUSEADDR) failed");
		if (bind(sfd, rp->ai_addr, rp->ai_addrlen) == 0)
		   break;                  /* Success */
		close(sfd);
	}
	freeaddrinfo(result);
	if (rp == NULL) return -1;
	
	listen(sfd,1);
	fprintf(stderr,"waiting for a client to connect... ");
	fflush(stderr);
	int cfd=accept(sfd,NULL,NULL);
	if(cfd<0) return cfd;
	close(sfd);
	fprintf(stderr,"connected\n");
	
	socklen_t len, trysize, gotsize;
	len = sizeof(int);
	trysize = 67108864+32768;
	do {
		trysize -= 32768;
		setsockopt(cfd,SOL_SOCKET,SO_SNDBUF,(char*)&trysize,len);
		int err = getsockopt(cfd,SOL_SOCKET,SO_SNDBUF,(char*)&gotsize,&len);
		if (err < 0) { perror("getsockopt"); break; }
	} while (gotsize < trysize);
	fprintf(stderr,"Socket send buffer size set to %d\n",gotsize);
	return cfd;
}

void handleExit(int sig) {
	//disable device
	if(s2hRegs!=NULL) {
		s2hRegs[0]=s2hRegs[0]&(~(ui)1);
		struct timespec ts;
		ts.tv_sec=0;
		ts.tv_nsec=1000*1000*100;
		fprintf(stderr,"disabling device\n");
		nanosleep(&ts,NULL);
	}
	if(sig!=0) fprintf(stderr,"got signal %d\n",sig);
	exit(1);
}

void* writerThread(void* v) {
	
	return NULL;
}

int main(int argc,char** argv) {
	int outfd;
	
	const char* ip=NULL;
	const char* port;
	if(argc==2) {
		ip="::0";
		port=argv[1];
	} else if(argc>2) {
		ip=argv[1];
		port=argv[2];
	}
	if(ip!=NULL) {
		if((outfd=tcpAccept(ip,port))<0) {
			perror("could not bind to specified address");
			return 1;
		}
	} else outfd=1;
	
	int flags = fcntl(outfd, F_GETFL);
	fcntl(outfd, F_SETFL, flags | O_NONBLOCK);

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
	
	
	//map device registers and dma buffer into VM
	int memfd;
	if((memfd = open("/dev/mem", O_RDWR | O_SYNC)) < 0) {
		printf( "ERROR: could not open \"/dev/mem\"...\n" ); return 1;
	}
	
	//allocate the dma buffers
	
	for(int i=0;i<bufCount;i++) {
		if((dmafd[i]=open("/dev/xaxaxadma",O_RDWR))<0) {
			perror("open /dev/xaxaxadma");
			return 1;
		}
		xaxaxadma_allocArg arg;
		arg.size=bufSize;
		if(ioctl(dmafd[i],1,&arg)<0) {
			perror("ioctl on /dev/xaxaxadma"); return -1;
		}
		baseAddr[i]=arg.physAddr;
		buffers[i]=(u8*)mmap(NULL, bufSize, (PROT_READ | PROT_WRITE), MAP_SHARED, memfd, arg.physAddr);
	}
	
	//u8* h2f = (u8*)mmap( NULL, H2F_SPAN, ( PROT_READ | PROT_WRITE ), MAP_SHARED, memfd, H2F_BASE);
	u8* hwreg = (u8*)mmap( NULL, HW_REGS_SPAN, ( PROT_READ | PROT_WRITE ), MAP_SHARED, memfd, HW_REGS_BASE);
	
	s2hRegs=(volatile u32*)(hwreg+LWH2F_OFFSET+STREAM2HPS_CONFIG_OFFSET);
	
	
	struct timespec ts;
	ts.tv_sec=0;
	ts.tv_nsec=1000*1000*10;

	
	//disable device first
	s2hRegs[0]=s2hRegs[0]&(~(ui)1);	
	nanosleep(&ts,NULL);
	
	//set addresses but don't enable device
	s2hRegs[1]=baseAddr[0]+bufSize;
	s2hRegs[0]=baseAddr[0]&(~(ui)1);
	
	//wait to ensure device received the newest config
	nanosleep(&ts,NULL);
	
	//open interrupts fd
	int irqfd = open(STREAM2HPS_IRQ, O_RDWR|O_SYNC);
	if(irqfd<0) {
		perror("open irqfd");
		return 1;
	}
	int irqcount,irqen=1,irqcount2=0,irqprev;
	write(irqfd,&irqen,sizeof(irqen));
	
	//clear interrupts
	clearIrq(irqfd);
	
	int curDeviceBuf=0;
	
	//wait for events
	pollfd pfd[2];
	pfd[0].fd = irqfd;
	pfd[0].events = POLLIN;
	pfd[1].fd = outfd;
	pfd[1].events = 0;
	deque<int> q;	//queue of buffers to be written out
	int currentBufferWritten=0;
	
	//enable device
	s2hRegs[0]=baseAddr[0]|1;
	
	while(poll(pfd,2,-1)>0) {
		if(pfd[1].revents&~(short)POLLOUT) {
			fprintf(stderr,"output fd was closed\n");
			break;
		}
		if(pfd[1].revents&POLLOUT) {
			if(q.empty()) {
				fprintf(stderr,"got POLLOUT event when it should not be possible\n");
				break;
			}
			//output fd is now writable
			u8* buf=buffers[q.front()];
			int bw=write(outfd,buf+currentBufferWritten,bufSize-currentBufferWritten);
			if(bw<0) {
				perror("write");
				break;
			}
			currentBufferWritten+=bw;
			if(currentBufferWritten==bufSize) {
				currentBufferWritten=0;
				q.pop_front();
			}
			if(q.empty()) pfd[1].events=0;
		}
		if(pfd[0].revents&POLLIN) {
			int bufferCompleted=mod(curDeviceBuf-1,bufCount);
			int prevDeviceBuf=curDeviceBuf;
			curDeviceBuf=(curDeviceBuf+1)%bufCount;
			s2hRegs[1]=baseAddr[curDeviceBuf]+bufSize;
			s2hRegs[0]=baseAddr[curDeviceBuf]|(ui)1;
			
			if(q.size()>=bufCount-1)
				fprintf(stderr,"!!! QUEUE FULL !!!\n");
			else q.push_back(bufferCompleted);
			if(!q.empty()) pfd[1].events=POLLOUT;
			
			irqcount=_readIrq(irqfd);
			
			//check the current hardware write position
			//to see how close we are to the deadline
			ui pos=s2hRegs[2];
			double percent;
			if(pos<baseAddr[prevDeviceBuf] ||
				pos>=(baseAddr[prevDeviceBuf]+bufSize)) {
				percent=1;
			} else {
				percent=double(pos-baseAddr[prevDeviceBuf])/bufSize;
			}
			
			fprintf(stderr,"%d irqs; hwWpos: %x; bC: %x; qLen: %d; used %.1f%% of deadline\n",
				irqcount,pos,baseAddr[bufferCompleted],(int)q.size(),percent*100);
			
			irqcount2++;
			if(irqcount2==1) {
				irqprev=irqcount;
				continue;
			}
			
			
			if(irqcount!=irqprev+1)
				fprintf(stderr,"!!!!!MISSED %d INTERRUPTS!!!!!\n",irqcount-irqprev-1);
			irqprev=irqcount;
		}
	}
	perror("poll");
	handleExit(0);
	return 0;
}
