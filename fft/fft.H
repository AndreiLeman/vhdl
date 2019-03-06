#include <complex>
using namespace std;
typedef complex<double> complexd;

#ifndef DBGPRNT
#define DBGPRNT(...) 
#endif

static constexpr unsigned char lookup[16] = {
0x0, 0x8, 0x4, 0xc, 0x2, 0xa, 0x6, 0xe,
0x1, 0x9, 0x5, 0xd, 0x3, 0xb, 0x7, 0xf, };

// bit-reversals; ripped off of stackoverflow
uint8_t reverse8(uint8_t n) {
   // Reverse the top and bottom nibble then swap them.
   return (lookup[n&0b1111] << 4) | lookup[n>>4];
}
uint16_t reverse16(uint16_t n) {
	return (reverse8((uint8_t)n) << 8) | reverse8(n>>8);
}
uint32_t reverse32(uint32_t n) {
	return (reverse16((uint16_t)n) << 16) | reverse16(n>>16);
}

// usage:
// 1. set .arr (you allocate array), .size, and .direction
// 2. call prepare()
// 3. call perform() passing in input array
// 4. use the results in .arr
// 5. repeat (3) and (4) as necessary

struct fft {
	complexd* arr;
	int size; // must be power of 2
	int direction=1; //1 for forward, -1 for inverse
	
	complexd* twiddles;
	
	void prepare() {
		twiddles = new complexd[size];
		for(int i=0;i<size;i++) {
			double phase = -double(i)*direction*2*M_PI/size;
			twiddles[i] = polar(1., phase);
		}
		//arr = new complexd[size];
	}
	void perform(complexd* inp) {
		rearrange(inp, arr);
		combineAll();
	}
	void combineAll() {
		int partitionSize=1;
		int i=0;
		//combine2Steps(partitionSize);
		//partitionSize*=4;
		while(partitionSize<size) {
			/*if((partitionSize*8) <= size) {
				combine3Steps(partitionSize);
				partitionSize*=8;
			} else*/ if((partitionSize*4) <= size) {
				DBGPRNT("PASS %d: partitionSize = %10d, partitions = 4\n", i, partitionSize);
				combine2Steps(partitionSize);
				partitionSize*=4;
			} else {
				DBGPRNT("PASS %d: partitionSize = %10d, partitions = 2\n", i, partitionSize);
				combineStep(partitionSize);
				partitionSize*=2;
			}
			i++;
		}
	}
	void combineAll_dif() {
		int partitionSize=size/2;
		while(partitionSize>=1) {
			if(partitionSize >= 8) {
				combine3Steps_dif(partitionSize/4);
				partitionSize /= 8;
			} else {
				combineStep_dif(partitionSize);
				partitionSize /= 2;
			}
		}
	}
	void rearrange(complexd* inp, complexd* outp) {
		int order = (int)log2(size);
		for(int i=0;i<size;i++) {
			int i2=reverse32(i<<(32-order));
			outp[i2] = inp[i];
		}
	}
	void rearrange(complexd* arr) {
		int order = (int)log2(size);
		for(int i=0;i<size;i++) {
			int i2=reverse32(i<<(32-order));
			if(i2>i) {
				complexd tmp = arr[i2];
				arr[i2] = arr[i];
				arr[i] = tmp;
			}
		}
	}
	
	// input is two subpartitions of size partitionSize, at arr index startIndex
	// output is one subpartition of size partitionSize*2
	void combinePartition(int startIndex, int partitionSize) {
		int size_div_2 = size/2;
		int twiddleStep = size/2/partitionSize;
		int twiddleIndex = 0;
		int index = startIndex;
		for(int i=0;i<partitionSize;i++) {
			complexd evenValue = arr[index];
			complexd oddValue = arr[index+partitionSize];
			complexd twiddle1 = twiddles[twiddleIndex];
			
			complexd res1 = evenValue + oddValue*twiddle1;
			complexd res2 = evenValue - oddValue*twiddle1;
			arr[index] = res1;
			arr[index+partitionSize] = res2;
			twiddleIndex += twiddleStep;
			index++;
		}
	}
	// input is 4 subpartitions of size partitionSize, at arr index startIndex
	// output is one subpartition of size partitionSize*4
	// old function
	void combinePartition2(int startIndex, int partitionSize) {
		int size_div_2 = size/2;
		int size_div_4 = size/4;
		int twiddleStep = size/2/partitionSize;
		int StwiddleStep = size/4/partitionSize;
		int twiddleIndex = 0, StwiddleIndex = 0;
		int index = startIndex;
		for(int i=0;i<partitionSize;i++) {
			complexd evenValueA = arr[index];
			complexd oddValueA = arr[index+partitionSize];
			complexd evenValueB = arr[index+partitionSize*2];
			complexd oddValueB = arr[index+partitionSize*3];
			complexd twiddle1 = twiddles[twiddleIndex];
			
			complexd resA1 = evenValueA + oddValueA*twiddle1;
			complexd resA2 = evenValueA - oddValueA*twiddle1;
			complexd resB1 = evenValueB + oddValueB*twiddle1;
			complexd resB2 = evenValueB - oddValueB*twiddle1;
			
			complexd Stwiddle1 = twiddles[StwiddleIndex];
			complexd Stwiddle2 = twiddles[StwiddleIndex + size_div_4];
			
			
			complexd SresA1 = resA1 + resB1*Stwiddle1;
			complexd SresA2 = resA1 - resB1*Stwiddle1;
			complexd SresB1 = resA2 + resB2*Stwiddle2;
			complexd SresB2 = resA2 - resB2*Stwiddle2;
			
			
			arr[index] = SresA1;
			arr[index+partitionSize*2] = SresA2;
			arr[index+partitionSize] = SresB1;
			arr[index+partitionSize*3] = SresB2;
			
			twiddleIndex += twiddleStep;
			StwiddleIndex += StwiddleStep;
			index++;
		}
	}
	
	// input is 4 subpartitions of size partitionSize, at arr index startIndex
	// output is one subpartition of size partitionSize*4
	void combinePartition2_2(int startIndex, int partitionSize) {
		int size_div_2 = size/2;
		int size_div_4 = size/4;
		int StwiddleStep = size/4/partitionSize;
		int StwiddleIndex = 0;
		int index = startIndex;
		for(int i=0;i<partitionSize;i++) {
			// read values
			complexd evenValueA = arr[index];
			complexd oddValueA = arr[index+partitionSize];
			complexd evenValueB = arr[index+partitionSize*2];
			complexd oddValueB = arr[index+partitionSize*3];
			
			//StwiddleIndex = i*size/(4*partitionSize)
			complexd twiddle1 = twiddles[StwiddleIndex*2];
			complexd Stwiddle1 = twiddles[StwiddleIndex];
			complexd Stwiddle3 = twiddles[StwiddleIndex*3];
			
			DBGPRNT("\tindex = %10d  twiddleIndex = %10d\n", index, 0);
			DBGPRNT("\tindex = %10d  twiddleIndex = %10d\n", index+partitionSize*1, StwiddleIndex*2);
			DBGPRNT("\tindex = %10d  twiddleIndex = %10d\n", index+partitionSize*2, StwiddleIndex*1);
			DBGPRNT("\tindex = %10d  twiddleIndex = %10d\n", index+partitionSize*3, StwiddleIndex*3);
			
			// multiply by twiddle factors
			oddValueA *= twiddle1;
			evenValueB *= Stwiddle1;
			oddValueB *= Stwiddle3;
			
			// perform 4-fft
			fft4(evenValueA, evenValueB, oddValueA, oddValueB);
			arr[index] = evenValueA;
			arr[index+partitionSize] = evenValueB;
			arr[index+partitionSize*2] = oddValueA;
			arr[index+partitionSize*3] = oddValueB;
			
			StwiddleIndex += StwiddleStep;
			index++;
		}
		DBGPRNT("\n");
	}
	
	static inline void fft2(complexd& a0, complexd& a1) {
		complexd tmp = a0 + a1;
		a1 = a0 - a1;
		a0 = tmp;
	}
	static inline void fft4(complexd& a0, complexd& a1, complexd& a2, complexd& a3) {
		// perform 4-fft
		complexd resA1 = a0 + a2;
		complexd resA2 = a0 - a2;
		complexd resB1 = a1 + a3;
		// resB2 = (a1 - a3) * -quarter rotation
		complexd resB2 = complexd(a1.imag() - a3.imag(),
									a3.real() - a1.real());
		
		a0 = resA1 + resB1; // 0: a0 + a1   + a2 + a3
		a1 = resA2 + resB2; // 1: a0 + a1*q - a2 - a3*q
		a2 = resA1 - resB1; // 2: a0 - a1   + a2 - a3
		a3 = resA2 - resB2; // 3: a0 - a1*q - a2 + a3*q
	}
	static inline void fft8(complexd& a0, complexd& a1, complexd& a2, complexd& a3, 
					complexd& a4, complexd& a5, complexd& a6, complexd& a7) {
		// fft on even and odd parts
		fft4(a0,a2,a4,a6);
		fft4(a1,a3,a5,a7);
		
		// multiply by twiddles
		static const complexd t1 = polar(1., -1./8*2*M_PI);
		static const complexd t2 = polar(1., -2./8*2*M_PI);
		static const complexd t3 = polar(1., -3./8*2*M_PI);
		
		complexd r0 = a0;
		complexd r1 = a1;
		complexd r2 = a2;
		complexd r3 = a3 * t1;
		complexd r4 = a4;
		complexd r5 = a5 * t2;
		complexd r6 = a6;
		complexd r7 = a7 * t3;
		
		// combine
		a0 = r0 + r1;
		a4 = r0 - r1;
		a1 = r2 + r3;
		a5 = r2 - r3;
		a2 = r4 + r5;
		a6 = r4 - r5;
		a3 = r6 + r7;
		a7 = r6 - r7;
	}
	
	// input is 8 subpartitions of size partitionSize, at arr index startIndex
	// output is one subpartition of size partitionSize*8
	void combinePartition3(int startIndex, int partitionSize) {
		int size_div_2 = size/2;
		int size_div_4 = size/4;
		int StwiddleStep = size/8/partitionSize;
		int StwiddleIndex = 0;
		int index = startIndex;
		for(int i=0;i<partitionSize;i++) {
			// read values
			complexd i0 = arr[index];
			complexd i4 = arr[index+partitionSize];
			complexd i2 = arr[index+partitionSize*2];
			complexd i6 = arr[index+partitionSize*3];
			complexd i1 = arr[index+partitionSize*4];
			complexd i5 = arr[index+partitionSize*5];
			complexd i3 = arr[index+partitionSize*6];
			complexd i7 = arr[index+partitionSize*7];
			
			i1 *= twiddles[StwiddleIndex];
			i2 *= twiddles[StwiddleIndex*2];
			i3 *= twiddles[StwiddleIndex*3];
			i4 *= twiddles[StwiddleIndex*4];
			i5 *= twiddles[StwiddleIndex*5];
			i6 *= twiddles[StwiddleIndex*6];
			i7 *= twiddles[StwiddleIndex*7];
			
			// perform 8-fft
			fft8(i0,i1,i2,i3,i4,i5,i6,i7);
			
			// writeback results
			arr[index] = i0;
			arr[index+partitionSize] = i1;
			arr[index+partitionSize*2] = i2;
			arr[index+partitionSize*3] = i3;
			arr[index+partitionSize*4] = i4;
			arr[index+partitionSize*5] = i5;
			arr[index+partitionSize*6] = i6;
			arr[index+partitionSize*7] = i7;
			
			StwiddleIndex += StwiddleStep;
			index++;
		}
	}
	
	void combineStep(int partitionSize) {
		for(int i=0;i<size;i+=(partitionSize*2)) {
			combinePartition(i, partitionSize);
		}
	}
	void combine2Steps(int partitionSize) {
		for(int i=0;i<size;i+=(partitionSize*4)) {
			combinePartition2_2(i, partitionSize);
		}
	}
	void combine3Steps(int partitionSize) {
		for(int i=0;i<size;i+=(partitionSize*8)) {
			/*combinePartition(i, partitionSize);
			combinePartition(i+partitionSize*2, partitionSize);
			combinePartition(i+partitionSize*4, partitionSize);
			combinePartition(i+partitionSize*6, partitionSize);
			
			combinePartition(i, partitionSize*2);
			combinePartition(i+partitionSize*4, partitionSize*2);
			
			combinePartition(i, partitionSize*4);*/
			combinePartition3(i, partitionSize);
		}
		
	}
	
	
	
	
	// output is two subpartitions of size partitionSize, at arr index startIndex
	// input is one subpartition of size partitionSize*2
	void combinePartition_dif(int startIndex, int partitionSize) {
		int size_div_2 = size/2;
		int twiddleStep = size/2/partitionSize;
		int twiddleIndex = 0;
		int index = startIndex;
		for(int i=0;i<partitionSize;i++) {
			complexd evenValue = arr[index];
			complexd oddValue = arr[index+partitionSize];
			complexd twiddle1 = twiddles[twiddleIndex];
			
			complexd res1 = evenValue + oddValue;
			complexd res2 = (evenValue - oddValue)*twiddle1;
			arr[index] = res1;
			arr[index+partitionSize] = res2;
			twiddleIndex += twiddleStep;
			index++;
		}
	}
	
	void combineStep_dif(int partitionSize) {
		for(int i=0;i<size;i+=(partitionSize*2)) {
			combinePartition_dif(i, partitionSize);
		}
	}
	void combine3Steps_dif(int partitionSize) {
		for(int i=0;i<size;i+=(partitionSize*8)) {
			combinePartition_dif(i, partitionSize*4);
			
			combinePartition_dif(i, partitionSize*2);
			combinePartition_dif(i+partitionSize*4, partitionSize*2);
			
			combinePartition_dif(i, partitionSize);
			combinePartition_dif(i+partitionSize*2, partitionSize);
			combinePartition_dif(i+partitionSize*4, partitionSize);
			combinePartition_dif(i+partitionSize*6, partitionSize);
		}
	}
};
