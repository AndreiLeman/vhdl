setMode -bscan
setCable -p svf -file a.svf
addDevice -p 1 -file top2.bit
program -e -p 1
quit

