
test: test.C fft.H
	g++ -o test test.C -Ofast -march=native -lfftw3

printsteps: printsteps.C fft.H
	g++ -o printsteps printsteps.C -g3 -lfftw3

run: test
	./test
