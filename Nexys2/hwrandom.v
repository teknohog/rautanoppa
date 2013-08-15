// Original Nexys2 version of rautanoppa, teknohog's hwrng

`include "main_pll.v"
`include "../common_hdl/uart_transmitter.v"
`include "../common_hdl/ringosc.v"

`include "raw7seg.v"

module hwrandom (osc_clk, TxD, reset, segment, anode, disp_switch);
//module hwrandom (osc_clk, TxD, reset);

   input reset;
   input       osc_clk;
   wire  clk;

   parameter comm_clk_frequency = 50_000_000;
   
   main_pll pll_blk (.CLKIN_IN(osc_clk), .CLK0_OUT(clk));

   wire       sample_clk;
   
   // Ring oscillators; with the common reset, use different lengths
   // to ensure they do not sync up that way

   // Primes are nice; 73 and 101 were enough for good randomness, 137
   // was too much for the Spartan 3E 500k. 127 was bad again --
   // perhaps a routing glitch at the chip limit.
   parameter NUM_RINGOSC = 101;

   wire [NUM_RINGOSC-1:0] ringout;

   generate
      genvar 	      i;
      for (i = 0; i < NUM_RINGOSC; i = i + 1)
	begin: for_ringosc
	   ringosc #(.NUMGATES(i + 1)) osc (.reset(reset), .clkout(ringout[i]));
	end
   endgenerate
   
   wire       ringxor;
   assign ringxor = ^ringout;
	
   // De-bias and collect the bits; output only completely new bytes

   // Von Neumann de-bias: split the ringxor stream into pairs and map
   // 10 -> 1, 01 -> 0
   reg [1:0]  pair = 2'b00;
   wire       newbit, have_newbit;
   reg pair_counter;
   assign have_newbit = (^pair) & pair_counter;
   assign newbit = pair[1];
  
   reg [7:0]  temp_byte, out_byte;
   reg [2:0]  bit_counter = 0;

   // Serial send
   output TxD;
   
   wire   TxD_ready;
   reg 	  TxD_start;
   
   uart_transmitter #(.comm_clk_frequency(comm_clk_frequency)) utx (.clk(clk), .uart_tx(TxD), .rx_new_byte(TxD_start), .rx_byte(out_byte), .tx_ready(TxD_ready));

   // For serial send, the sample clock should equal the serial
   // clock. It would be bad to have a byte change in the midst of
   // sending, that would make partial dupes. Even worse would be
   // sampling at exact fractions of the serial clock, causing full
   // dupes.

   always @(posedge clk)
     begin
	// De-bias
	pair[pair_counter] <= ringxor;
	pair_counter <= pair_counter + 1;

	if (have_newbit)
	  begin
	     temp_byte[bit_counter] <= newbit;
	     bit_counter <= bit_counter + 1;

	     if (bit_counter == 3'b111)
	       begin
		  out_byte <= temp_byte;
		  if (TxD_ready) TxD_start <= 1;
		  else TxD_start <= 0;
	       end
	  end
     end

   // Debug: show something in 7seg at slow sampling
   output [7:0] segment;
   output [3:0] anode;

   input 	disp_switch;
   
   wire [7:0] 	segment_data;

   // inverted signals, so 1111.. to turn it off
   assign segment = disp_switch? segment_data : {8{1'b1}};
   
   reg [31:0] 	disp_word;

   reg [24:0] 	disp_counter;
   always @ (posedge clk)
     begin
	disp_counter <= disp_counter + 1;
	if (disp_counter == 0)
	  begin
	     disp_word <= disp_word << 8;
	     disp_word[7:0] <= out_byte;
	  end
     end
   
   raw7seg disp(.clk(clk), .segment(segment_data), .anode(anode), .word(disp_word));
endmodule   
