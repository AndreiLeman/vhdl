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
#include "adf4350_board.H"

using namespace std;


int devfd=-1;

//writes the commands in the buffer to stdout
void doWrite(string buf) {
	assert(write(devfd,buf.data(),buf.length())==(int)buf.length());
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

//freq is in units of cycles per sample
//returns mag**2
double doMeasure(double freq, double srate) {
	int samplesToDiscard=1000000;		//40ms @ 25MSPS
	int samplesToMeasure=5000;		//0.2 ms @ 25MSPS
	
	
	{
		s8 buf[samplesToDiscard];
		readAll(devfd,buf,samplesToDiscard);
	}
	{
		s8 buf[samplesToMeasure];
		int res=readAll(devfd,buf,samplesToMeasure);
		if(res!=samplesToMeasure) {
			fprintf(stderr,"short read on tty device\n");
			_exit(1);
		}
		
		//process the samples
		double accumReal=0,accumImag=0;
		for(int i=0;i<res;i++) {
			double sinReal=cos(double(i)*freq*2*M_PI/srate);
			double sinImag=sin(double(i)*freq*2*M_PI/srate);
			accumReal+=sinReal*double(buf[i]);
			accumImag+=sinImag*double(buf[i]);
		}
		return pow(accumReal,2)+pow(accumImag,2);
	}
}

int main(int argc,char** argv) {
	//to use this program, connect both stdin and stdout to the usb serial
	//device of the sdr2 board
	
	if(argc<2) {
		fprintf(stderr,"usage: %s TTY_DEVICE\n",argv[0]);
		return 1;
	}
	devfd=open(argv[1],O_RDWR);
	assert(devfd>=0);
	
	double basebandOffsetFreqMHz=9.3456;
	double basebandSampleRateMHz=25;
	double correction=1-(10-9.820)/(150*20);
	
	double dividerInputMHz=1500;
	
	double freqStart=130;
	double freqEnd=180;
	int nPoints=51;
	
	
	doWrite(versaclock5Board::sendConfig());
	doWrite(versaclock5Board::sendFracN(-1,"120"));	//25MHz * 112 = 2800MHz vco frequency
	
	//print out the lower and upper frequency limit
	printf("%lf %lf\n",freqStart,freqEnd);
	
	while(true) {
		for(int i=0;i<nPoints;i++) {
			//calculate the test frequency (sent to DUT) and the LO frequency
			double testFreqMHz=freqStart+double(i)*(freqEnd-freqStart)/(nPoints-1);
			double loFreqMHz=(testFreqMHz-basebandOffsetFreqMHz)*correction;
			
			//configure the clock generator
			double od1=dividerInputMHz/loFreqMHz;
			double od2=dividerInputMHz/testFreqMHz;
			doWrite(versaclock5Board::sendO_double(1,od1));
			
			//doWrite(versaclock5Board::sendO_double(2,od2));
			string buf1;
			int n1=(int)(testFreqMHz*16);
			if(fabs(testFreqMHz-double(n1)/16)>0.001) {
				fprintf(stderr,"pll can not generate %lf MHz\n",testFreqMHz);
				return 1;
			}
			adf4350Board::sendN(buf1,n1);
			//fill in the register address in every byte
			for(int i=0;i<(int)buf1.length();i++)
				buf1[i] |= 2 << 4;
			doWrite(buf1);
			
			
			double res=doMeasure(basebandOffsetFreqMHz,basebandSampleRateMHz);
			
			printf("%lf ",log10(res)*10);
			
			//fprintf(stderr,"%.2lf MHz: %.3lf dB\n",testFreqMHz,log10(res)*10);
			//usleep(200000);
		}
		printf("\n");
		fflush(stdout);
		if(argc>2) break;
	}
	
	
	string buf;
	//return the bus control to the hw by deasserting enables
	buf+=((char)(versaclock5Board::i2csda|versaclock5Board::i2cscl));
	doWrite(buf);
	return 0;
}
