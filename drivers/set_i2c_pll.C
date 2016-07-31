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
#include <string>
#include <assert.h>
#include <math.h>
#include "common_types.h"
#include "versaclock5_board.H"

using namespace std;
using namespace versaclock5Board;

//writes the commands in the buffer to stdout
void doWrite(string buf) {
	assert(write(1,buf.data(),buf.length())==(int)buf.length());
}

int main(int argc,char** argv) {
	if(argc<4) {
		fprintf(stderr,"usage: %s N O1 O2\n",argv[0]);
		return 1;
	}
	const char* N=argv[1];
	const char* O1=argv[2];
	const char* O2=argv[3];
	
	doWrite(sendConfig());
	
	doWrite(sendFracN(-1,N));
	doWrite(sendFracN(1,O1));
	doWrite(sendFracN(2,O2));
	
	/*
	for(int i=0;i<50;i++) {
		sendN(2,N2,i*10000);
		nSleep(100000000);
		//sleep(1);
	}*/
	
	
	
	string buf;
	//return the bus control to the hw by deasserting enables
	doDisableAccess(buf);
	assert(write(1,buf.data(),buf.length())==(int)buf.length());
	return 0;
}
