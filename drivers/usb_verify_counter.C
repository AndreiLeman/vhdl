#include <stdio.h>
#include <unistd.h>
#include <assert.h>
#include <stdint.h>
#include <string>

using namespace std;
#define bufsize 1024*1024
typedef int16_t s16;
typedef int32_t s32;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint8_t u8;
typedef uint64_t u64;

int mask=255;
int incr=3;

int main() {
	int bitcount=14;
	u8 buf[bufsize];
	int br;
	
	int skipbuffers=10000;
	
	for(int i=0;i<skipbuffers;i++)
		if((br=read(0,buf,sizeof(buf)))<=0) return 1;
	u8 lastValue=buf[br-1];
	
	lastValue+=incr;
	lastValue&=mask;
	
	while((br=read(0,buf,sizeof(buf)))>0) {
		for(int i=0;i<br;i++) {
			if(lastValue!=(buf[i]&mask)) {
				fprintf(stderr,"i=%d out of %d\n",i,br);
				fprintf(stderr,"ERROR: should be %d but got:\n",(int)lastValue);
				for(int x=i,y=0;x<br && y<10; x++,y++) {
					fprintf(stderr,"%d\n",(int)(buf[x]&mask));
				}
				i++;
				if(i>=br) break;
				lastValue=buf[i];
			}
			lastValue+=incr;
			lastValue&=mask;
		}
	}
	return 0;
}
