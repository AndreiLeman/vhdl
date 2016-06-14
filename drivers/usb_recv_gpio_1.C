#include <stdio.h>
#include <unistd.h>
#include <assert.h>
#include <stdint.h>
#include <string>

using namespace std;
#define bufsize 4096
typedef int16_t s16;
typedef int32_t s32;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint8_t u8;
typedef uint64_t u64;

void writeBits(u64 bits, int bitcount) {
	string s;
	for(int i=bitcount-1;i>=0;i--) {
		const char* tmp;
		tmp=((bits>>i)&1)?"█":" ";
		s+=tmp;
	}
	printf("%s %lu\n",s.c_str(),bits);
}
int main() {
	u8 buf[bufsize];
	int br;
	int fuck=0;
	while((br=read(0,buf,sizeof(buf)))>0) {
		for(int i=0;i<br;i++) {
			if(fuck>50000) writeBits(buf[i],8);
			fuck++;
		}
	}
}
