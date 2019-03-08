import sys

#b = [6.72036648960684e-05, -0.00022175068682014806, 0.00031643496561885044, -0.00015412278750151793, -0.00015412278750151764, 0.00031643496561885, -0.00022175068682014792, 6.720366489606831e-05]
#a = [1.0, -6.385240561058668, 17.621683655309567, -27.23712762724277, 25.457809601446595, -14.385662608130943, 4.549755683613482, -0.6212026136248732]

b = [2.6266183390846345e-05, 8.499817989080047e-06, 8.499817989080114e-06, 2.6266183390846334e-05]
a = [1.0, -2.9278447834672447, 2.858970423187072, -0.9310561077170687]


order = len(a)
coeffBits = 12

assert(len(a) == len(b))
outpMax = 2**(coeffBits-1)-1

maxA = 0.
maxB = 0.
for x in a:
	if abs(x) > maxA:
		maxA = abs(x)
for x in b:
	if abs(x) > maxB:
		maxB = abs(x)



dcB = 0.
for x in b:
	dcB += x

print dcB
print maxB

if dcB > maxB:
	maxB = dcB



sys.stdout.write('coeffAint <= (')
first = True
for x in a:
	tmp = x/maxA*outpMax
	tmp = int(round(tmp))
	if tmp > outpMax: tmp = outpMax
	if tmp < -outpMax: tmp = -outpMax
	
	if first: sys.stdout.write('%d' % tmp)
	else: sys.stdout.write(', %d' % tmp)
	first = False
sys.stdout.write(');\n')


sys.stdout.write('coeffBint <= (')
first = True
for x in b:
	tmp = x/maxB*outpMax
	tmp = int(round(tmp))
	if tmp > outpMax: tmp = outpMax
	if tmp < -outpMax: tmp = -outpMax
	
	if first: sys.stdout.write('%d' % tmp)
	else: sys.stdout.write(', %d' % tmp)
	first = False
sys.stdout.write(');\n')


