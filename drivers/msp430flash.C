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
#include <poll.h>
#include <stdexcept>
#include <arpa/inet.h>

using namespace std;

#define sbarrier() asm volatile("": : :"memory")
#define hbarrier() __sync_synchronize()
#define cpu_relax() __sync_synchronize()
#define ACCESS_ONCE(x) (*(volatile typeof(x) *)&(x))

#define H2F_BASE (0xC0000000) // axi_master
#define H2F_SPAN (0x40000000) // Bridge span
#define HW_REGS_BASE ( 0xFC000000 )     //misc. registers
#define HW_REGS_SPAN ( 0x04000000 )


#define LWH2F_OFFSET 52428800
#define CMDBUF_SRAM_ADDR 0
#define CMDBUF_SRAM_SIZE 1024
#define REGS_ADDR 0x10
#define TDOIN_ADDR 0x0

//jtag commands
#define IR_ADDR_16BIT		0x83
#define IR_ADDR_CAPTURE		0x84
#define IR_DATA_TO_ADDR		0x85
#define IR_DATA_16BIT		0x41

#define IR_DATA_QUICK		0x43
#define IR_BYPASS			0xFF
#define IR_CNTRL_SIG_16BIT	0x13
#define IR_CNTRL_SIG_CAPTURE 0x14
#define IR_CNTRL_SIG_RELEASE 0x15

typedef unsigned long ul;
typedef uint8_t u8;
typedef uint64_t u64;


struct msp430flash_device {
	uint32_t* regs;
	uint32_t* tdoIn;
	u8* cmdBuf;
	u8* bufPtr;
	int cmdBufSize;	//bytes
	bool tclk;
	//# of instructions that can fit into remaining buffer space
	int spaceLeft() {
		return (int((cmdBuf+cmdBufSize)-bufPtr))*2;
	}
};
#define FLASH_SIZE (2*1024)
/*
 * device specs:
 *  * 2 32-bit registers, one readonly, one readwrite
 *  * one command buffer sram
 * 
 * buffer sram:
 *  * stores temporary commands
 *  * order: lowest address (0) contains the first command to be executed
 * 
 * control register (32 bit):
 *  * bits [23..0]: number of commands to fetch from the commmand buffer and execute
 *  * bit 31: do execution; write a 0 followed by a 1 to start executing commands
 *  * bit 24: use test and rst ports
 * 
 * tdo shift register (32 bit):
 *  * contains last 31 values shifted in from tdo
 *  * the highest bit (bit 31) contains the "done" register that indicates
 *    whether the device is ready to accept new commands
 *  * shift order: low to high
 * */
//useTestRst must be set to true when committing these instructions
void startJtag(msp430flash_device& dev) {
	*(dev.bufPtr++)=(2<<4)|2;		//test low, rst high
	*(dev.bufPtr++)=(6<<4)|6;		//test high, rst high
	*(dev.bufPtr++)=(4<<4)|4;		//test high, rst low
	*(dev.bufPtr++)=0;				//test low, rst low
	*(dev.bufPtr++)=(4<<4)|4;		//test high, rst low
}
//useTestRst must be set to false
void resetJtag(msp430flash_device& dev) {
	*(dev.bufPtr++)=0;
	for(int i=0;i<3;i++)
		*(dev.bufPtr++)=(3<<4)|3;		//tck enabled, tdi low, tms high
	*(dev.bufPtr++)=(0<<4)|1;			//tck enabled, tdi low, tms low
}
//useTestRst must be set to false
void doFuseCheck(msp430flash_device& dev) {
	resetJtag(dev);
	*(dev.bufPtr++)=(4<<4)|4;			//tck disabled, tdi high, tms low
	for(int ii=0;ii<3;ii++) {
		for(int i=0;i<20;i++)
			*(dev.bufPtr++)=(6<<4)|6;		//tck disabled, tdi high, tms high
		for(int i=0;i<30;i++)
			*(dev.bufPtr++)=(4<<4)|4;		//tck disabled, tdi high, tms low
	}
}
inline char createDataCommand(int data1, int data2, int capture1, int capture2) {
	return ((data2?5:1)<<4)|((capture2?8:0)<<4)|(data1?5:1)|(capture1?8:0);
}
inline char createDataCommand1(uint32_t data, uint32_t capture, int index) {
	return createDataCommand((data>>index)&1,(data>>(index+1))&1,
		(capture>>index)&1,(capture>>(index+1))&1);
}
void irShift(msp430flash_device& dev, char data, char captureEnableMask) {
	*(dev.bufPtr++)=(3<<4)|3|(dev.tclk?4:0);	//tck enabled, tdi unchanged, tms high
												//tck enabled, tdi low, tms high
	*(dev.bufPtr++)=(1<<4)|1;					//tck enabled, tdi low, tms low
	for(int i=0;i<4;i++)
		*(dev.bufPtr++)=createDataCommand1(data,captureEnableMask,i*2);
	*(dev.bufPtr-1)|=32;							//set tms to high for the last instruction
	*(dev.bufPtr++)=(dev.tclk?(4<<4):0)|(1<<4)|3;	//tck enabled, tdi low, tms high then low
}
inline char createDataCommand2(uint32_t data, uint32_t capture, int index) {
	return createDataCommand((data>>(index+1))&1,(data>>index)&1,
		(capture>>(index+1))&1,(capture>>index)&1);
}
void drShift(msp430flash_device& dev, uint16_t data, uint16_t captureEnableMask) {
	*(dev.bufPtr++)=(3<<4)|1|(dev.tclk?4:0);	//tck enabled, tdi low, tms low then high
	*(dev.bufPtr++)=(1<<4)|1;					//tck enabled, tdi low, tms low
	for(int i=7;i>=0;i--)
		*(dev.bufPtr++)=createDataCommand2(data,captureEnableMask,i*2);
	*(dev.bufPtr-1)|=32;							//set tms to high for the last instruction
	*(dev.bufPtr++)=(dev.tclk?(4<<4):0)|(1<<4)|3;	//tck enabled, tdi low, tms high then low
}
inline void setTclk1(msp430flash_device& dev) {
	*(dev.bufPtr++)=(4<<4)|4;
}
inline void clrTclk1(msp430flash_device& dev) {
	*(dev.bufPtr++)=0;
}
inline void setTclk(msp430flash_device& dev) {
	*(dev.bufPtr++)=(4<<4)|4;
	dev.tclk=true;
}
inline void clrTclk(msp430flash_device& dev) {
	*(dev.bufPtr++)=0;
	dev.tclk=false;
}
inline void pulseTclk(msp430flash_device& dev, int pulses=1) {
	clrTclk(dev);
	for(int i=0;i<pulses;i++) {
		setTclk(dev);
		clrTclk(dev);
	}
}
void commitCommands(msp430flash_device& dev, bool useTestRst, int commands=0) {
	uint32_t cmdcount=(commands==0?(uint32_t(dev.bufPtr-dev.cmdBuf)*2):uint32_t(commands));
	if(cmdcount==0) return;
	hbarrier();
	uint32_t status=ACCESS_ONCE(*dev.tdoIn)&(1<<31);
	ACCESS_ONCE(*dev.regs)=0;
	ACCESS_ONCE(*dev.regs)=uint32_t(1<<31)|(useTestRst?(1<<24):0)|(cmdcount&0xffffff);
	dev.bufPtr=dev.cmdBuf;
	
	timespec ts;
	ts.tv_sec=0;
	ts.tv_nsec=1000000;
	//printf("cmdcount = %i\n",cmdcount);
	if(cmdcount<500)
		while((ACCESS_ONCE(*dev.tdoIn)&(1<<31))==status) cpu_relax();
	else while((ACCESS_ONCE(*dev.tdoIn)&(1<<31))==status) nanosleep(&ts,NULL);
}
void GetDevice(msp430flash_device& dev) {
	irShift(dev,IR_CNTRL_SIG_16BIT,0);
	drShift(dev,0x2401,0);
	uint32_t tdoIn;
	do {
		irShift(dev,IR_CNTRL_SIG_CAPTURE,0);
		drShift(dev,0,1<<9);
		commitCommands(dev,false);
		tdoIn=ACCESS_ONCE(*dev.tdoIn);
		printf("tdo_sr value: %x\n",tdoIn);
	} while((tdoIn&1)==0);
}
void ReleaseDevice(msp430flash_device& dev) {
	irShift(dev,IR_CNTRL_SIG_16BIT,0);
	drShift(dev,0x2C01,0);
	drShift(dev,0x2401,0);
	irShift(dev,IR_CNTRL_SIG_RELEASE,0);
	*(dev.bufPtr++)=0;
	commitCommands(dev,false);
	*(dev.bufPtr++)=0;
	commitCommands(dev,true);
}
void SetInstrFetch(msp430flash_device& dev) {
	for(int i=0;i<7;i++) {
		irShift(dev,IR_CNTRL_SIG_CAPTURE,0);
		*(dev.bufPtr++)=(1<<4)|1;
		clrTclk(dev);
		setTclk(dev);
		drShift(dev,0,1<<7);
		commitCommands(dev,false);
		if((ACCESS_ONCE(*dev.tdoIn)&1)!=0) return;
	}
	
	throw runtime_error("SetInstrFetch failed");
}
void HaltCPU(msp430flash_device& dev) {
	irShift(dev,IR_DATA_16BIT,0);
	drShift(dev,0x3FFF,0);
	clrTclk(dev);
	irShift(dev,IR_CNTRL_SIG_16BIT,0);
	drShift(dev,0x2409,0);
	setTclk(dev);
}
void ReleaseCPU(msp430flash_device& dev) {
	clrTclk(dev);
	irShift(dev,IR_CNTRL_SIG_16BIT,0);
	drShift(dev,0x2401,0);
	irShift(dev,IR_ADDR_CAPTURE,0);
	setTclk(dev);
}
void writeMem(msp430flash_device& dev, uint16_t addr, uint16_t data) {
	irShift(dev,IR_ADDR_16BIT,0);
	drShift(dev,addr,0);
	irShift(dev,IR_DATA_TO_ADDR,0);
	drShift(dev,data,0);
}
void readMem(msp430flash_device& dev, uint16_t addr, uint16_t datamask=0xffff) {
	irShift(dev,IR_ADDR_16BIT,0);
	drShift(dev,addr,0);
	irShift(dev,IR_DATA_TO_ADDR,0);
	setTclk(dev);
	clrTclk(dev);
	drShift(dev,0,datamask);
}
void ExecutePOR(msp430flash_device& dev, bool resume=true) {
	clrTclk(dev);
	irShift(dev,IR_CNTRL_SIG_16BIT,0);
	drShift(dev,0x2C01,0);
	drShift(dev,0x2401,0);
	pulseTclk(dev,2);
	irShift(dev,IR_ADDR_CAPTURE,0);
	setTclk(dev);
	//clrTclk(dev);
	//disable wdt
	HaltCPU(dev);
	clrTclk(dev);
	irShift(dev,IR_CNTRL_SIG_16BIT,0);
	drShift(dev,0x2408,0);
	writeMem(dev,0x0120,0x5A80);
	setTclk(dev);
	if(resume) ReleaseCPU(dev);
	else clrTclk(dev);
}
//device buffer must be empty before calling this function
void doPulseTclk(msp430flash_device& dev, int pulsesNeeded) {
	int bufferCommands=dev.spaceLeft();
	int pulsesPerBuffer=bufferCommands/20;
	int commandsLeft=bufferCommands-pulsesPerBuffer*20;
	int longPulses=commandsLeft/2;
	for(int i=0;i<longPulses;i++) {
		for(int x=0;x<5;x++) *(dev.bufPtr++)=(4<<4)|4;
		*(dev.bufPtr++)=(0<<4)|4;
		for(int x=0;x<5;x++) *(dev.bufPtr++)=0;
	}
	for(int i=longPulses;i<pulsesPerBuffer;i++) {
		for(int x=0;x<5;x++) *(dev.bufPtr++)=(4<<4)|4;
		for(int x=0;x<5;x++) *(dev.bufPtr++)=0;
	}
	int commandsNeeded=0;
	while(true) {
		if(pulsesNeeded<=longPulses) {
			commandsNeeded+=22*pulsesNeeded;
			break;
		}
		if(pulsesNeeded<=pulsesPerBuffer) {
			commandsNeeded+=22*longPulses+20*(pulsesNeeded-longPulses);
			break;
		}
		commandsNeeded+=bufferCommands;
		pulsesNeeded-=pulsesPerBuffer;
	}
	commitCommands(dev,false,commandsNeeded);
}
void EraseFLASH(msp430flash_device& dev) {
	clrTclk(dev);
	irShift(dev,IR_CNTRL_SIG_16BIT,0);
	drShift(dev,0x2408,0);
	writeMem(dev,0x0128,0xA506);
	pulseTclk(dev);
	writeMem(dev,0x012A,0xA540);
	pulseTclk(dev);
	writeMem(dev,0x012C,0xA500);
	pulseTclk(dev);
	writeMem(dev,0xfffe,0x55AA);
	pulseTclk(dev);
	irShift(dev,IR_CNTRL_SIG_16BIT,0);
	drShift(dev,0x2409,0);
	commitCommands(dev,false);
	
	doPulseTclk(dev,10600);
	
	irShift(dev,IR_CNTRL_SIG_16BIT,0);
	drShift(dev,0x2408,0);
	writeMem(dev,0x0128,0xA500);
	pulseTclk(dev);
	writeMem(dev,0x012C,0xA500);
	pulseTclk(dev);
	commitCommands(dev,false);
}
void prepareWriteFlash(msp430flash_device& dev) {
	clrTclk(dev);
	irShift(dev,IR_CNTRL_SIG_16BIT,0);
	drShift(dev,0x2408,0);
	writeMem(dev,0x0128,0xA540);
	setTclk(dev);
	clrTclk(dev);
	writeMem(dev,0x012A,0xA540);
	setTclk(dev);
	clrTclk(dev);
	writeMem(dev,0x012C,0xA500);
	setTclk(dev);
	clrTclk(dev);
}
void doWriteFlashWord(msp430flash_device& dev, uint16_t addr, uint16_t value) {
	irShift(dev,IR_CNTRL_SIG_16BIT,0);
	drShift(dev,0x2408,0);
	writeMem(dev,addr,value);
	for(int x=0;x<5;x++) *(dev.bufPtr++)=(4<<4)|4;
	for(int x=0;x<5;x++) *(dev.bufPtr++)=0;
	irShift(dev,IR_CNTRL_SIG_16BIT,0);
	drShift(dev,0x2409,0);
	commitCommands(dev,false);
	for(int i=0;i<35;i++) {
		for(int x=0;x<5;x++) *(dev.bufPtr++)=(4<<4)|4;
		for(int x=0;x<5;x++) *(dev.bufPtr++)=0;
	}
	commitCommands(dev,false);
}
void endWriteFlash(msp430flash_device& dev) {
	irShift(dev,IR_CNTRL_SIG_16BIT,0);
	drShift(dev,0x2408,0);
	writeMem(dev,0x0128,0xA500);
	setTclk(dev);
	clrTclk(dev);
	writeMem(dev,0x012C,0xA500);
	setTclk(dev);
}
void setReadMode(msp430flash_device& dev) {
	clrTclk(dev);
	irShift(dev,IR_CNTRL_SIG_16BIT,0);
	drShift(dev,0x2409,0);
}
//device must be in read mode
void printMem(msp430flash_device& dev, uint16_t addr) {
	readMem(dev,addr);
	commitCommands(dev,false);
	printf("read %x: %x\n",addr,(*dev.tdoIn & 0xffff));
}
uint16_t doReadMem(msp430flash_device& dev, uint16_t addr) {
	readMem(dev,addr);
	commitCommands(dev,false);
	return uint16_t(*dev.tdoIn & 0xffff);
}
void printMem2(msp430flash_device& dev) {
	for(int i=0xf800;i<0xf900;i+=2) {
		printMem(dev,i);
	}
}
int main(int argc, char** argv) {
	if(argc<2) {
	print_usage:
		printf("usage: %s [r|f|v]\nr: reset\nf: flash\nv: verify\n"
			"Input file must be in ihex format and is taken from stdin\n",argv[0]);
		return 1;
	}
	
	int fd;
	if((fd = open("/dev/mem", O_RDWR | O_SYNC)) < 0) {
		printf( "ERROR: could not open \"/dev/mem\"...\n" ); return 1;
	}
	u8* h2f = (u8*)mmap( NULL, H2F_SPAN, ( PROT_READ | PROT_WRITE ), MAP_SHARED, fd, H2F_BASE);
	u8* hwreg = (u8*)mmap( NULL, HW_REGS_SPAN, ( PROT_READ | PROT_WRITE ), MAP_SHARED, fd, HW_REGS_BASE);
	u8* sram=(u8*)(h2f+CMDBUF_SRAM_ADDR);
	uint32_t* regs=(uint32_t*)(hwreg+LWH2F_OFFSET+REGS_ADDR);
	uint32_t* tdoIn=(uint32_t*)(hwreg+LWH2F_OFFSET+TDOIN_ADDR);
	msp430flash_device dev = {regs,tdoIn,sram,sram,CMDBUF_SRAM_SIZE,false};
	
	switch(argv[1][0]) {
		case 'r': {
			*(dev.bufPtr++)=0;
			commitCommands(dev,false);
			for(int i=0;i<500;i++)
				*(dev.bufPtr++)=0;
			*(dev.bufPtr++)=2<<4;
			commitCommands(dev,true);
			return 0;
		}
		case 'f':
		case 'v':
		case 'x':
			break;
		default:
			goto print_usage;
	}
	startJtag(dev);
	commitCommands(dev,true);
	doFuseCheck(dev);
	commitCommands(dev,false);
	
	if(argv[1][0]=='x') {
		doPulseTclk(dev,8388608);
		return 0;
	}
	GetDevice(dev);
	SetInstrFetch(dev);
	
	ExecutePOR(dev,true);
	
	if(argv[1][0]=='f') {
		HaltCPU(dev);
		EraseFLASH(dev);
		ReleaseCPU(dev);
		HaltCPU(dev);
		prepareWriteFlash(dev);
	} else {
		setReadMode(dev);
	}
	while(true) {
		char* line=NULL;
		size_t _n=0;
		ssize_t n;
		if((n=getline(&line,&_n,stdin))<=0) break;
		if(line[0]!=':') throw runtime_error("error: line does not begin with \":\"");
		if(n<9) throw runtime_error("error: line length < 9");
		int datalen,addr,type;
		sscanf(line+1,"%02x%04x%02x",&datalen,&addr,&type);
		if(type!=0) continue;
		if(n<(9+datalen*2)) throw runtime_error("error: byte count larger than actual data length");
		for(int i=0;i<datalen/2;i++) {
			int data;
			uint16_t a=addr+i*2,rdata;
			sscanf(line+9+i*4,"%04x",&data);
			data=ntohs((uint16_t)data);
			if(argv[1][0]=='f')
				doWriteFlashWord(dev,a,(uint16_t)data);
			else {
				if((rdata=doReadMem(dev,a))!=(uint16_t)data) {
					printf("error at address %x: should be %x but is %x\n",(int)a,data,(int)rdata);
				}
			}
		}
	}
	if(argv[1][0]=='f') {
		endWriteFlash(dev);
		commitCommands(dev,false);
		ReleaseCPU(dev);
	} else {
		printf("Verify done\n");
		pulseTclk(dev);
	}
	
	
	/*setReadMode(dev);
	printMem2(dev);
	printMem(dev,0xfffe);
	
	
	
	setReadMode(dev);
	while(true) {
		char* line=NULL;
		size_t _n=0;
		ssize_t n;
		if((n=getline(&line,&_n,stdin))<=0) break;
		if(line[0]!=':') throw runtime_error("error: line does not begin with \":\"");
		if(n<9) throw runtime_error("error: line length < 9");
		int datalen,addr,type;
		sscanf(line+1,"%02x%04x%02x",&datalen,&addr,&type);
		if(type!=0) continue;
		if(n<(9+datalen*2)) throw runtime_error("error: byte count larger than actual data length");
		for(int i=0;i<datalen/2;i++) {
			int data;
			uint16_t a=addr+i*2,rdata;
			sscanf(line+9+i*4,"%04x",&data);
			if((rdata=doReadMem(dev,a))!=(uint16_t)data) {
				printf("error at address %x: should be %x but is %x\n",(int)a,data,(int)rdata);
			}
		}
	}
	*/
	
	
	irShift(dev,IR_CNTRL_SIG_16BIT,0);
	drShift(dev,0x3401,0);
	
	irShift(dev,IR_DATA_16BIT,0);
	drShift(dev,0x43c2,0);
	clrTclk(dev);
	setTclk(dev);
	clrTclk(dev);
	drShift(dev,0x0026,0);
	clrTclk(dev);
	setTclk(dev);
	clrTclk(dev);
	setTclk(dev);
	clrTclk(dev);
	setTclk(dev);
	clrTclk(dev);
	
	drShift(dev,0x43f2,0);
	clrTclk(dev);
	setTclk(dev);
	clrTclk(dev);
	drShift(dev,0x0022,0);
	clrTclk(dev);
	setTclk(dev);
	clrTclk(dev);
	setTclk(dev);
	clrTclk(dev);
	setTclk(dev);
	clrTclk(dev);
	
	drShift(dev,0x43f2,0);
	clrTclk(dev);
	setTclk(dev);
	clrTclk(dev);
	drShift(dev,0x0021,0);
	clrTclk(dev);
	setTclk(dev);
	clrTclk(dev);
	setTclk(dev);
	clrTclk(dev);
	setTclk(dev);
	clrTclk(dev);
	commitCommands(dev,false);
}
