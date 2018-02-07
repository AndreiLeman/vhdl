#!/bin/bash
./sdr2_sweep a 2>&1 >/dev/ttyACM1 </dev/ttyACM1 |tail -n1

