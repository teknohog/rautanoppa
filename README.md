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


Testing and usage
-----------------

For Linux/unix, a test script is provided. It requires the rng-tools
package. The script sets up the computer's serial port and runs
rngtest. After a succesful test, you can use rngd from the same
package to import the randomness into your system entropy pool.


Known issues
------------

The quality of randomness depends on the FPGA model as well as the
bitstream synthesis. There may even be variations across individual
FPGAs of the same model. Generally, you should try to vary
NUM_RINGOSC until a working value is found.

The reset button is not necessary in my experience. Its main purpose,
in fact, is to provide a signal that cannot be optimized away, so it
could be connected to any I/O.