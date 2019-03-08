#include <stdio.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdlib.h>
#include <math.h>
#include <stdint.h>
typedef uint8_t u8;

int set_params(int fd, int freq_khz, int atten) {
	double freq = double(freq_khz)/1000.;
	int N = (int)round(freq*100);
	int txpower = 0b11;
	u8 buf[] = {
		0, 0,
		1, u8(N>>16),
		2, u8(N>>8),
		3, u8(N),
		5, u8(atten*2),
		6, u8(0b00001000 | txpower),
		7, 0,
		0, 0,
		4, 1
	};
	if(write(fd,buf,sizeof(buf))!=(int)sizeof(buf)) return -1;
	return 0;
}
int main(int argc, char** argv) {
	if(argc<2) {
		fprintf(stderr, "usage: %s /dev/TTY freq_khz\n", argv[0]);
		return 1;
	}
	int fd = open(argv[1], O_RDWR);
	if(fd < 0) {
		perror("open");
		return 2;
	}
	if(set_params(fd, atoi(argv[2]), 10) < 0) {
		perror("set_params");
		return 3;
	}
	return 0;
}
