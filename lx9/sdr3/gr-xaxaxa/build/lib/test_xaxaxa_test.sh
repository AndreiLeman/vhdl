#!/bin/sh
export VOLK_GENERIC=1
export GR_DONT_LOAD_PREFS=1
export srcdir=/persist/vhdl/lx9/sdr4/gr-xaxaxa/lib
export PATH=/persist/vhdl/lx9/sdr4/gr-xaxaxa/build/lib:$PATH
export LD_LIBRARY_PATH=/persist/vhdl/lx9/sdr4/gr-xaxaxa/build/lib:$LD_LIBRARY_PATH
export PYTHONPATH=$PYTHONPATH
test-xaxaxa 
