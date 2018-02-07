import matplotlib.pyplot as plt
import numpy as np
import sys

N=80

calib=None

if len(sys.argv)>1:
	tmp=open(sys.argv[1]).read()
	calib=[float(x) for x in tmp.strip().split(' ')]

limits_line = [float(x) for x in raw_input().strip().split(' ')]

x = np.linspace(limits_line[0], limits_line[1], N)

plt.ion()

fig = plt.figure()
ax = fig.add_subplot(111)
line1, = ax.plot(x, [0]*N, 'r-') # Returns a tuple of line objects, thus the comma


#ax.set_ylim([-40,20])
ax.set_ylim([-20,30])

while True:
	data = raw_input().strip().split(' ')
	if calib:
		for i in xrange(len(data)):
			data[i]=float(data[i])-calib[i]
	else:
		data = [float(x) for x in data]
	line1.set_ydata(data)
	fig.canvas.draw()
