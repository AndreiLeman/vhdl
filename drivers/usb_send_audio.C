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

int main() {
	s16 buf[bufsize*2];
	u8 bufOut[bufsize*7];
	int br;
	while((br=read(0,buf,bufsize*4))>0) {
		assert(br%4==0);
		br/=4;
		//memset(bufOut,0,sizeof(bufOut));
		for(int i=0;i<br;i++) {
			s32 value0=(buf[i*2]<<8);
			s32 value1=(buf[i*2+1]<<8);
			
			u32 u0=(u32)value0,u1=(u32)value1;
			
			u64 valuemask=(1<<24)-1;
			u64 data=(u0&valuemask) | (((u64)u1)<<24);
			
			//fprintf(stderr,"%llu\t%llu\n",data&valuemask,(data>>24)&valuemask);
			
			u32 mask=(1<<7)-1;
			bufOut[i*7+0]=	0<<7 | (data&mask);
			bufOut[i*7+1]=	1<<7 | ((data>>7)&mask);
			bufOut[i*7+2]=	1<<7 | ((data>>14)&mask);
			bufOut[i*7+3]=	1<<7 | ((data>>21)&mask);
			bufOut[i*7+4]=	1<<7 | ((data>>28)&mask);
			bufOut[i*7+5]=	1<<7 | ((data>>35)&mask);
			bufOut[i*7+6]=	1<<7 | ((data>>42)&mask);
		}
		write(1,bufOut,br*7);
	}
}
