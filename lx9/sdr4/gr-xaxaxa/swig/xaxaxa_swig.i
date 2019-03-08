/* -*- c++ -*- */

#define XAXAXA_API

%include "gnuradio.i"			// the common stuff

//load generated python docstrings
%include "xaxaxa_swig_doc.i"

%{
#include "xaxaxa/sdr4.h"
%}


%include "xaxaxa/sdr4.h"
GR_SWIG_BLOCK_MAGIC2(xaxaxa, sdr4);
