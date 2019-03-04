#!/usr/bin/python
import numpy
from numpy.fft import ifft
import sys

def reorderResult(arr):
	assert len(arr)==256
	res = []
	for i in xrange(256):
		row = i/16
		col = i%16
		col = (col%4)*4 + col/4
		row = (row%4)*4 + row/4
		i2 = col*16 + row
		x = arr[i2]
		res.append(x)
	return res

def printResult(arr):
	assert len(arr)==256
	res = reorderResult(arr)
	for i in xrange(256):
		x = res[i]
		# numpy ifft scales values by 1/n, but our library
		# scales it by 1/sqrt(n)
		print int(round(x.real*16)), int(round(x.imag*16))

arr = []
for i in xrange(512):
	re = (i*i) % 1024;
	im = (i*(i+13)) % 1024;
	arr.append(re + 1j*im);

if len(sys.argv)>1 and sys.argv[1] == 'verify':
	# reorderResult returns list, so += concatenates
	res = reorderResult(ifft(arr[:256]))
	res += reorderResult(ifft(arr[256:]))
	lines = sys.stdin.readlines()
	for line in lines:
		tmp = line.split(':')
		ind = int(tmp[0])
		vals = tmp[1].strip().split(' ')
		val = int(vals[0]) + 1j*int(vals[1])
		correctVal = res[ind]*16
		diff = abs(val-correctVal)
		if diff >= 8:
			print 'index %d should be %s, is %s' % (ind, str(correctVal), str(val))
else:
	printResult(ifft(arr[:256]))

