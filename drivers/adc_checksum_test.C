#include <stdio.h>
#include <unistd.h>
#include <assert.h>
#include <stdint.h>
#include <fcntl.h>
#include <termios.h>
#include <stdlib.h>

using namespace std;
#define bufsize 1024*32
typedef int16_t s16;
typedef int32_t s32;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint8_t u8;
typedef uint64_t u64;

int main() {
	u8 buf[bufsize];
	int br;
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
	int x=0;
	while((br=read(0,buf,sizeof(buf)))>0) {
		for(int i=0;i<br;i++) {
			u8 data=buf[i];
			bool checksum=bool(data&1) ^ bool((data>>1)&1) ^ bool((data>>2)&1) ^
				bool((data>>3)&1) ^ bool((data>>4)&1) ^ bool((data>>5)&1) ^
				bool((data>>6)&1);
			bool receivedChecksum=bool((data>>7)&1);
			if(checksum!=receivedChecksum) {
				fprintf(stderr,"checksum failed: %d\n",(int)data);
			} else x++;
			if(x>=10000000) {
				fprintf(stderr,"%d checksum passed\n",x);
				x=0;
			}
		}
	}
	return 0;
}
