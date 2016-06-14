#include <stdio.h>
#include <unistd.h>
#include <assert.h>
#include <stdint.h>
#include <string>
#include <termios.h>
#include <map>
using namespace std;
#define bufsize 4096
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
	struct termios tc;
	int fd=0;
	/* Set TTY mode. */
	if (tcgetattr(fd, &tc) < 0) {
		perror("tcgetattr");
		//exit(1);
	}
	tc.c_iflag &= ~(INLCR|IGNCR|ICRNL|IGNBRK|IUCLC|INPCK|ISTRIP|IXON|IXOFF|IXANY);
	tc.c_oflag &= ~OPOST;
	tc.c_cflag &= ~(CSIZE|CSTOPB|PARENB|PARODD|CRTSCTS);
	tc.c_cflag |= CS8 | CREAD | CLOCAL;
	tc.c_lflag &= ~(ICANON|ECHO|ECHOE|ECHOK|ECHONL|ISIG|IEXTEN);
	tc.c_cc[VMIN] = 1;
	tc.c_cc[VTIME] = 0;
	if (tcsetattr(fd, TCSANOW, &tc) < 0) {
		perror("tcsetattr");
		//exit(1);
	}
	
	map<u8,int> errorPairs[256];
	
	u8 buf[bufsize];
	int br;
	u8 prev=0;
	int cnt=0;
	int errorcnt=0;
	while((br=read(0,buf,sizeof(buf)))>0) {
		for(int i=0;i<br;i++) {
			u8 d=buf[i];
			
			/*bool checksum=bool(d&1) ^ bool((d>>1)&1) ^ (not bool((d>>2)&1)) ^
				(not bool((d>>3)&1)) ^ bool((d>>4)&1) ^ bool((d>>5)&1) ^
				(not bool((d>>6)&1));
			bool receivedChecksum=bool((d>>7)&1);
			if(checksum!=receivedChecksum) {
				fprintf(stderr,"checksum failed: %d\n",(int)d);
			}*/
			bool seq=bool(d>>7);
			bool prevSeq=bool(prev>>7);
			if(seq==prevSeq) {
				printf("sequence bit error: %d, %d\n",(int)prev, (int)d);
				int start=i-5, end=i+5;
				if(start<0) start=0;
				if(end>br) end=br;
				for(int fuck=start;fuck<end;fuck++)
					writeBits(buf[fuck],8);
			}
			
			if(cnt>1000000){
				//writeBits(d,8);
				if((prev&63) != ((d>>1)&63)) {
					
					/*auto& m=errorPairs[prev];
					auto it=m.find(d);
					if(it==m.end())
						m[d]=1;
					else m[d]++;*/
					
					/*printf("error:\n");
					int start=i-5, end=i+5;
					if(start<0) start=0;
					if(end>br) end=br;
					for(int fuck=start;fuck<end;fuck++)
						writeBits(buf[fuck],8,fuck==i?" ERROR":"");*/
					
					printf("e\n");
					//writeBits(prev,8);
					//writeBits(d,8);
					//printf("e");
					//*/
					
					/*errorcnt++;
					if(errorcnt>=1000000) {
						errorcnt=0;
						printf("e\n");
						return 1;
					}*/
					
					//i++;
					//if(i>=br) break;
				}
			}
			cnt++;
			prev=buf[i];
		}
	}
display_stats:
	for(int i=0;i<256;i++) {
		
		auto& m=errorPairs[i];
		if(m.empty()) continue;
		writeBits_nonl(i,8);
		printf(":\n=================\n");
		for(auto it=m.begin();it!=m.end();it++) {
			printf("  --> ");
			writeBits_nonl((*it).first,8);
			printf(" (%d counts)\n",(*it).second);
		}
	}
}
