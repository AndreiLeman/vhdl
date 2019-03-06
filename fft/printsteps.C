
#define DBGPRNT(...) printf(__VA_ARGS__)

#include <stdio.h>
#include <complex>
#include <stdlib.h>
#include <fftw3.h>
#include <assert.h>
#include <string.h>
#include <vector>
#include <iostream>
#include "fft.H"
using namespace std;

typedef unsigned long long ull;

void doTests() {
	srand(12345);
	
	vector<int> sizes = {4,16,64};
	assert(sizeof(complexd) == sizeof(fftw_complex));
	for(int ii=0;ii<(int)sizes.size();ii++) {
		int sz = sizes[ii];
		DBGPRNT("\n===== FFT SIZE %d =====\n\n", sz);
		
		complexd* inp1 = (complexd*) fftw_malloc(sz*sizeof(complexd));
		complexd* out1 = (complexd*) fftw_malloc(sz*sizeof(complexd));
		
		for(int i=0;i<sz;i++)
			inp1[i] = complexd(drand48(), drand48());
		
		fft fft2;
		fft2.size = sz;
		fft2.arr = out1;
		fft2.prepare();
		fft2.rearrange(inp1, fft2.arr);
		fft2.combineAll();
	}
}
int main(int argc, char** argv) {
	doTests();
	return 0;
}

