#!/bin/bash

if [ -n "$1" ]; then
    SER=$1
else
    SER=/dev/ttyS0
    #SER=/dev/ttyUSB0
fi

SPEED=115200

# The timeout (deciseconds) seems to be essential, otherwise readers
# exit too soon
stty -F $SER $SPEED time 10

# From rng-tools
rngtest -t 1 < $SER
