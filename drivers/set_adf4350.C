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
#include "adf4350_board.H"

using namespace std;
using namespace adf4350Board;

//writes the commands in the buffer to stdout
void doWrite(string buf) {
	assert(write(1,buf.data(),buf.length())==(int)buf.length());
}

int main(int argc,char** argv) {
	if(argc<3) {
		fprintf(stderr, "usage: %s N O\n",argv[0]);
		return 1;
	}
	string buf;
	
	sendConfig(buf,atoi(argv[2]));
	sendN(buf,atoi(argv[1]));
	
	//fill in the register address in every byte and set the data enable bit
	for(int i=0;i<(int)buf.length();i++)
		buf[i] |= 2 << 4 | 1<<3;
	
	
	//buf+=(char)((2<<4)|spiclk);
	doWrite(buf);
	return 0;
}
