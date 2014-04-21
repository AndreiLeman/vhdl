/* This program demonstrates use of parallel ports in the DE2 Basic Computer
 *
 * It performs the following: 
 * 	1. displays the SW switch values on the red LEDR
 * 	2. displays the KEY[3..1] pushbutton values on the green LEDG
 * 	3. displays a rotating pattern on the HEX displays
 * 	4. if KEY[3..1] is pressed, uses the SW switches as the pattern
*/
typedef unsigned int u32;
typedef unsigned char u8;
int main(void)
{
	/* Declare volatile pointers to I/O registers (volatile means that IO load
	 * and store instructions will be used to access these pointer locations, 
	 * instead of regular memory loads and stores)
	*/
	volatile int * red_LED_ptr 	= (int *) 0;	// red LED address
	volatile int * green_LED_ptr	= (int *) 0x10000010;	// green LED address
	volatile int * HEX3_HEX0_ptr	= (int *) 0x10000020;	// HEX3_HEX0 address
	volatile int * HEX7_HEX4_ptr	= (int *) 0x10000030;	// HEX7_HEX4 address
	volatile int * SW_switch_ptr	= (int *) 0x10000040;	// SW slider switch address
	volatile int * KEY_ptr			= (int *) 0x10000050;	// pushbutton KEY address

	int HEX_bits = 0x0000000F;					// pattern for HEX displays
	int SW_value, KEY_value;
	volatile int delay_count;					// volatile so the C compiler doesn't remove the loop
	int i,x;
	u32 b18=262143;
	u8 lut[16]={0x3f,0x06,0x5b,0x4F,0x66,0x6D,0x7D,0x07,0x7F,0x6F};
	/*while(1)
	{
		volatile u32 number=0;//*(volatile u32*)0x10000040;
		u32 a1=number*10;
		u32 a2=(a1&b18)*10;
		u32 a3=(a2&b18)*10;
		u32 a4=(a3&b18)*10;
		u8 d1=a1>>18; u8 d2=a2>>18; u8 d3=a3>>18; u8 d4=a4>>18;
		
		*(volatile u32*)HEX3_HEX0_ptr=(((u32)lut[0])<<24)|(((u32)lut[d2])<<16)|(((u32)lut[d3])<<8)|((u32)lut[d4]);
		
	}*/
	while(1) {
		*red_LED_ptr=0x2aaa;
	}
}
