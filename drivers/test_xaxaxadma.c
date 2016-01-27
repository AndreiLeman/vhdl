#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <stdlib.h>

typedef unsigned long ul;
typedef unsigned int ui;
typedef struct {
	size_t size;
	unsigned long physAddr;
} xaxaxadma_allocArg;

int main(int argc,char** argv) {
	if(argc<2) {
		printf("usage: %s SIZE\nSIZE is in hex (without 0x)\n",argv[0]);
		return 1;
	}
	int fd=open("/dev/xaxaxadma",O_RDWR);
	if(fd<0) {
		perror("open"); return -1;
	}
	
	xaxaxadma_allocArg arg;
	arg.size=strtol(argv[1],NULL,16);
	if(ioctl(fd,1,&arg)<0) {
		perror("ioctl"); return -1;
	}
	
}
