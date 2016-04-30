#include <stdio.h>
#include <unistd.h>
#include <assert.h>
#include <stdint.h>

#define bufsize 4096
typedef int16_t s16;
typedef int32_t s32;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint8_t u8;
typedef uint64_t u64;

void writeBits(u64 bits, int bitcount) {
	char buf[bitcount+1];
	buf[bitcount]=0;
	for(int i=0;i<bitcount;i++) {
		buf[bitcount-i-1]=((bits>>i)&1)?'1':'0';
	}
	printf("%s %lu\n",buf,bits);
}
int main() {
	int bitcount=14;
	u8 buf[bufsize];
	int br;
	u64 bits=0;
	int j=0;
	
	u8 msb=1<<7;
	u8 mask=msb-1;
	
	while((br=read(0,buf,sizeof(buf)))>0) {
		for(int i=0;i<br;i++) {
			if(buf[i]&msb) {
				//fprintf(stderr,"fuck %u\n");
				bits|=u64(buf[i]&mask) << j;
				j+=7;
			} else {
				writeBits(bits,bitcount);
				bits=u64(buf[i]&mask);
				j=7;
			}
		}
	}
}
