module ringosc (reset, clkout);
   // p. 9 of http://www.xilinx.com/products/boards/s3estarter/files/s3esk_frequency_counter.pdf

   // Not necessarily an odd number, since there is only one invert anyway
   parameter NUMGATES = 3;

   input reset;

   (* keep="true" *)
   wire [NUMGATES-1:0] patch;
   
   generate
      genvar 	      i;
      for (i = 0; i < NUMGATES-1; i = i + 1)
	begin: for_gates
	   (* keep="true" *)
	   assign patch[i+1] = patch[i] & ~reset;
	end
   endgenerate
   
   (* keep="true" *)
   assign patch[0] = ~patch[NUMGATES-1] & ~reset;

   // Plain output
   output 	      clkout;
   assign clkout = patch[0];

   // Freq halver to de-bias and clean up the waveform
   //output reg clkout;
   //always @(posedge patch[0]) clkout <= clkout + 1;
endmodule
