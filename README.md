Rautanoppa
==========

Hardware random number generator for FPGAs


Design
------

Rautanoppa implements a basic HWRNG in Verilog, by combining the
outputs of ring oscillators. With a sufficient number of them, the
natural jitter produces a random stream of bits that passes the FIPS
140-2 test, as used in rng-tools. The bitstream is output via RS-232
serial port.

The serial port (UART) code is adapted verbatim from
https://github.com/progranism/Open-Source-FPGA-Bitcoin-Miner. A
USB-serial adapter and/or TTL level signals can be used instead of a
traditional RS-232 port.


Implementations
---------------

* Digilent Nexys2 / Xilinx Spartan 3E 500k
* Terasic DE2-115 / Altera Cyclone IV 4CE115

The bulk of the code is the same in both cases. The necessary
differences between these implementations are mainly due to

* Clock management (Altera PLL / Xilinx DCM)
* Debug display

It should be trivial to port these to other Xilinx or Altera boards
with suitable I/O. The clock management code may vary between
different chip families (e.g. this DCM might not work on a Virtex).


Testing and usage
-----------------

For Linux/unix, a test script is provided. It requires the rng-tools
package. The script sets up the computer's serial port and runs
rngtest. After a succesful test, you can use rngd from the same
package to import the randomness into your system entropy pool.

Once rngd is running, you can cat /dev/random to check that it
works. It is generally quite slow if there are no hardware randomness
sources, only a few characters per second on average, but this device
should give you a flood of random chars.

cat /proc/sys/kernel/random/entropy_avail is another way to monitor
the overall picture of randomness sources and sinks.


Performance
-----------

The serial port is easily maxed out at the default 115200 baud,
producing about 90 Kibits/s for rngd. This is similar to the rate of
TPM hardware, and the effect on /dev/random output is drastic. The
code should work on higher baud rates, but may require tweaking to
maintain the quality of randomness.


Known issues
------------

The reset button is not really necessary in my experience. Its main
purpose, in fact, is to provide a signal that cannot be optimized
away, so it could be connected to any unused I/O port.

The quality of randomness depends on the FPGA model as well as the
bitstream synthesis. There may even be variations across individual
FPGAs of the same model. Generally, you should try to vary
NUM_RINGOSCS until a working value is found. A bigger value is not
necessarily better, though...

The Nexys2 version, in particular, is very sensitive to changes in
NUM_RINGOSCS and even the display code. My hypothesis is that the ring
oscillators are picking up nearby electromagnetic noise, and locking
on to a pattern (although the individual oscillators, being of
different lengths, cannot all have the same actual frequencies).

This is exacerbated by the fact that the display code in Nexys2 is
more involved and uses a number of frequencies, compared to the simple
wiring in the DE2-115.


Nomenclature
------------

'Rautanoppa' is Finnish for 'iron dice' or 'hardware dice'.


Further reading
---------------

http://en.wikipedia.org/wiki/Ring_oscillator

http://www.csm.ornl.gov/~dunigan/fips140.txt -- Specifies the test used by rng-tools

http://www.xilinx.com/products/boards/s3estarter/files/s3esk_frequency_counter.pdf -- Ring oscillator implementation on page 9

http://www.cosic.esat.kuleuven.be/publications/article-790.ps -- includes statistical analysis on the randomness produced this way