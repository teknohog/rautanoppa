#!/bin/bash

SER=/dev/ttyS0
SPEED=115200

# The timeout (deciseconds) seems to be essential, otherwise readers
# exit too soon
stty -F $SER $SPEED time 10

# From rng-tools
rngtest -t 1 < $SER
