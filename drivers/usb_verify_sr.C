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

void writeBits_nonl(u64 bits, int bitcount) {
	string s;
	for(int i=bitcount-1;i>=0;i--) {
		const char* tmp;
		tmp=((bits>>i)&1)?"█":" ";
		//tmp=((bits>>i)&1)?"1":"0";
		s+=tmp;
	}
	printf("%s %lu",s.c_str(),bits);
}
void writeBits(u64 bits, int bitcount, const char* msg="") {
	writeBits_nonl(bits,bitcount);
	printf("%s\n",msg);
}

int main() {
	u8 buf[bufsize];
	int br;
	
	int skipbuffers=10000;
	
	for(int i=0;i<skipbuffers;i++)
		if((br=read(0,buf,sizeof(buf)))<=0) return 1;
	u8 lastValue=buf[br-1];
	
	while((br=read(0,buf,sizeof(buf)))>0) {
		for(int i=0;i<br;i++) {
			lastValue = lastValue << 1;
			if(lastValue != (buf[i] & 0b11111110)) {
				fprintf(stderr,"error at index %d:\n",i);
				int s=i-5;
				if(s<0) s=0;
				for(int x=s,y=0;x<br && y<10; x++,y++) {
					writeBits(buf[x],8);
				}
				//return 1;
			}
			lastValue = buf[i];
		}
	}
	return 0;
}
