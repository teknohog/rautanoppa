`ifdef DISPLAY
module hwrandom_core(clk, TxD, reset, disp_word);
`else
module hwrandom_core(clk, TxD, reset);
`endif
   
   parameter NUM_PORTS = 1;
   
   // Ring oscillators; with the common reset, use different lengths
   // to ensure they do not sync up that way

   parameter NUM_RINGOSCS = 241;

   wire [NUM_RINGOSCS-1:0] ringout;

   input 		   clk;
   input 		   reset;
   
   generate
      genvar 	      i;
      for (i = 0; i < NUM_RINGOSCS; i = i + 1)
	begin: for_ringosc
	   ringosc #(.NUMGATES(i + 1)) osc (.reset(reset), .clkout(ringout[i]));
	end
   endgenerate
   
   wire       ringxor;
   assign ringxor = ^ringout;

   // Collect the bits; output only completely new bytes

   // In the multiport setup, a single out_byte is enough because
   // fpgaminer's UART makes a local copy upon TxD_start, and we only
   // trigger one port at a time.
   
   // In fact, for the same reason, we don't need to copy temp_byte to
   // out_byte for sending, we can collect newbits directly into
   // out_byte.
   
   // Remember these limitations if the logic and/or UART changes....

   reg [7:0]  out_byte;
   reg [3:0]  bit_counter = 0;

   // Serial send
   output [NUM_PORTS-1:0] TxD;
   
   wire [NUM_PORTS-1:0]   TxD_ready;
   reg [NUM_PORTS-1:0] 	  TxD_start;

   parameter comm_clk_frequency = 50_000_000;

   generate
      genvar 		  j;
      for (j = 0; j < NUM_PORTS; j = j + 1)
	begin: for_uarts
	   uart_transmitter #(.comm_clk_frequency(comm_clk_frequency)) utx (.clk(clk), .uart_tx(TxD[j]), .rx_new_byte(TxD_start[j]), .rx_byte(out_byte), .tx_ready(TxD_ready[j]));
	end
   endgenerate

   reg [$clog2(NUM_PORTS)+1:0] port_counter = 0;

   always @(posedge clk)
     begin
	out_byte[bit_counter[2:0]] <= ringxor;

	if (bit_counter == 4'b0111)
	  begin
	     if (TxD_ready[port_counter])
	       begin
		  TxD_start[port_counter] <= 1;
		  
		  // Only increment upon succesful send,
		  // otherwise the port assignment will be, well,
		  // random, and possibly uneven
		  if (port_counter == NUM_PORTS-1)
		    port_counter <= 0;
		  else
		    port_counter <= port_counter + 1;
	       end
	     else TxD_start[port_counter] <= 0;
	     
	     // Wait stage to ensure that the same byte cannot be
	     // sent twice. This will waste one new bit per byte,
	     // but I think we can afford it ;)
	     bit_counter <= 4'b1111;
	  end // if (bit_counter == 4'b0111)
	else
	  bit_counter <= bit_counter + 1;
     end

`ifdef DISPLAY
   // Debug display
   output reg [31:0] 	disp_word;

   reg [24:0] 		disp_counter;
   always @ (posedge clk)
     begin
	disp_counter <= disp_counter + 1;
	if (disp_counter == 0)
	  begin
	     disp_word <= disp_word << 8;
	     disp_word[7:0] <= out_byte;
	  end
     end
`endif
endmodule
