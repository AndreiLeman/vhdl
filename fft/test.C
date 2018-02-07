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
ull rdtscl(void) {
    unsigned int lo, hi;
    __asm__ __volatile__ ("rdtsc" : "=a"(lo), "=d"(hi));                        
    return ( (ull)lo)|( ((ull)hi)<<32 );  
}


void doTests() {
	srand(12345);
	int range = 100;
	int errors = 0;
	
	vector<int> sizes = {8,16,1024*8,1024*256,1024*1024};
	vector<int> cnt = {200000,20000,200,20,1};
	assert(sizeof(complexd) == sizeof(fftw_complex));
	for(int ii=0;ii<(int)sizes.size();ii++) {
		int sz = sizes[ii];
		ull avgTime1=0,avgTime2=0,avgTime2a=0;
		
		complexd* inp1 = (complexd*) fftw_malloc(sz*sizeof(complexd));
		complexd* inp2 = (complexd*) fftw_malloc(sz*sizeof(complexd));
		complexd* out1 = (complexd*) fftw_malloc(sz*sizeof(complexd));
		complexd* out2 = (complexd*) fftw_malloc(sz*sizeof(complexd));
		
		fftw_plan p = fftw_plan_dft_1d(sz, (fftw_complex*)inp1, (fftw_complex*)out1, FFTW_FORWARD, FFTW_ESTIMATE);
		fft fft2;
		fft2.size = sz;
		fft2.arr = out2;
		fft2.prepare();
		
		for(int j=0;j<cnt[ii];j++) {
			for(int i=0;i<sz;i++)
				inp1[i] = inp2[i] = complexd(drand48() * range, drand48() * range);
			
			// compute using fftw
			ull tsc1 = rdtscl();
			fftw_execute(p);
			ull time1 = rdtscl() - tsc1;
			
			
			// compute using custom fft
			/*
			ull tsc2a = rdtscl();
			fft2.rearrange(inp2, fft2.arr);
			ull tsc2b = rdtscl();
			fft2.combineAll();
			ull tsc2c = rdtscl();
			ull time2 = tsc2c-tsc2a;
			ull time2a = tsc2b-tsc2a;*/
			
			fft2.arr = inp2;
			ull tsc2a = rdtscl();
			fft2.combineAll_dif();
			ull tsc2b = rdtscl();
			fft2.rearrange(fft2.arr, out2);
			ull tsc2c = rdtscl();
			ull time2 = tsc2c-tsc2a;
			ull time2a = tsc2c-tsc2b;
			
			// compare
			for(int i=0;i<sz;i++) {
				complexd diff = out1[i] - out2[i];
				if(norm(diff) > 1e-9) {
					cout << "fft size " << sz << ": element "
						<< i << " should be " << out1[i]
						<< ", is " << out2[i] << endl;
					if((++errors) > 10)
						return;
				}
			}
			avgTime1 += time1;
			avgTime2 += time2;
			avgTime2a += time2a;
		}
		double timeRatio = double(avgTime1)/double(avgTime2);
		printf("size %10d: custom fft %.0f%% performance of fftw - ",sz,timeRatio*100);
		double rearrangeTimeRatio = double(avgTime2a)/double(avgTime2);
		printf("%.0f%% time spent in rearrange\n", rearrangeTimeRatio*100);
	}
	cout << "tests passed" << endl;
}
int main(int argc, char** argv) {
	if(argc == 1) {
		doTests();
		return 0;
	}
	complexd* inp = new complexd[argc-1];
	for(int i=1;i<argc;i++) {
		inp[i-1] = atof(argv[i]);
	}
	fft fft1;
	fft1.size = argc-1;
	fft1.arr = new complexd[fft1.size];
	fft1.prepare();
	fft1.perform(inp);
	for(int i=0;i<fft1.size; i++) {
		cout << fft1.arr[i] << endl;
	}
	return 0;
}

