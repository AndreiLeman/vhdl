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

#define H2F_BASE (0xC0000000) // axi_master
#define H2F_SPAN (0x40000000) // Bridge span
#define HW_REGS_BASE ( 0xFC000000 )     //misc. registers
#define HW_REGS_SPAN ( 0x04000000 )


#define LWH2F_OFFSET 52428800
#define FB_CONFIG_OFFSET 0x20

typedef unsigned long ul;
typedef unsigned int ui;
typedef uint8_t u8;

int main(int argc,char** argv) {
        if(argc<2) {
                printf("usage: %s ADDR\n",argv[0]);
                return 1;
        }
        int fd;
        if((fd = open("/dev/mem", O_RDWR | O_SYNC)) < 0) {
                printf( "ERROR: could not open \"/dev/mem\"...\n" ); return 1;
        }
        //u8* h2f = (u8*)mmap( NULL, H2F_SPAN, ( PROT_READ | PROT_WRITE ), MAP_SHARED, fd, H2F_BASE);
        u8* hwreg = (u8*)mmap( NULL, HW_REGS_SPAN, ( PROT_READ | PROT_WRITE ), MAP_SHARED, fd, HW_REGS_BASE);
        u8* tmp=hwreg+LWH2F_OFFSET+FB_CONFIG_OFFSET;
        volatile ui* tmp1=(volatile ui*)tmp;

        int w,h;
        unsigned long long hf,hb,hd,vf,vb,vd;

        w=1280; h=1024; vd=3; vb=38; vf=1; hd=144; hb=248; hf=16;
        //w=1024; h=768; vd=6; vb=29; vf=3; hd=136; hb=160; hf=24;

        //fb address
        tmp1[0]=strtol(argv[1],NULL,16);
        //resolution
        tmp1[1]=w+(h<<16);
        //timings
        //uint64_t asdfg=(1LL<<60) | (3LL<<50) | (208LL<<40) | (1LL<<30) | (34LL<<20) | (120LL<<10) | 328LL;
        uint64_t asdfg=(1LL<<60) | (vd<<50) | (vb<<40) | (vf<<30) | (hd<<20) | (hb<<10) | hf;
        tmp1[2]=asdfg&0xFFFFFFFF;
        tmp1[3]=asdfg>>32;

        return 0;
}
