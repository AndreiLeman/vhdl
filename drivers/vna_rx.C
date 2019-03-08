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
typedef long long ll;

u64 sx(u64 data, int bits) {
	u64 mask=~((1<<bits) - 1);
	return data|((data>>(bits-1))?mask:0);
}

void processValue(u64 data1,u64 data2) {
	data1=sx(data1,35);
	data2=sx(data2,35);
	printf("%lld %lld\n", (ll)data1, (ll)data2);
}
int main() {
	int bitcount=70;
	u8 buf[bufsize];
	int br;
	u64 data1,data2;
	u64* curData=&data1;
	int j=0;
	
	u8 msb=1<<7;
	u8 mask=msb-1;
	
	while((br=read(0,buf,sizeof(buf)))>0) {
		for(int i=0;i<br;i++) {
			if((buf[i]&msb)==0) {
				processValue(data1,data2);
				data1=0;
				data2=0;
				curData=&data1;
				j=0;
				//printf("a\n");
			}// else printf("b\n");
			(*curData)|=u64(buf[i]&mask) << j;
			j+=7;
			if(j>=35) {
				j=0;
				curData=&data2;
			}
		}
	}
}
