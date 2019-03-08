#!/bin/sh
export VOLK_GENERIC=1
export GR_DONT_LOAD_PREFS=1
export srcdir=/persist/vhdl/lx9/sdr4/gr-xaxaxa/python
export PATH=/persist/vhdl/lx9/sdr4/gr-xaxaxa/build/python:$PATH
export LD_LIBRARY_PATH=/persist/vhdl/lx9/sdr4/gr-xaxaxa/build/lib:$LD_LIBRARY_PATH
export PYTHONPATH=/persist/vhdl/lx9/sdr4/gr-xaxaxa/build/swig:$PYTHONPATH
/usr/bin/python2 /persist/vhdl/lx9/sdr4/gr-xaxaxa/python/qa_sdr4.py 
