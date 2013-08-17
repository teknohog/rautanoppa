// Altera version of rautanoppa, teknohog's hwrng

module hwrandom (osc_clk, TxD, segment, disp_switch, reset_button);
   
   // DE2-115 buttons have inverted logic
   input 	      reset_button;
   wire 	      reset;
   assign reset = ~reset_button;

   input       osc_clk;
   wire  clk;

   parameter comm_clk_frequency = 50_000_000;

   main_pll pll_blk (osc_clk, clk);

   // Ring oscillators; with the common reset, use different lengths
   // to ensure they do not sync up that way

   // 241 and 499 are both good on DE2-115 for near-perfect rngtest
   parameter NUM_RINGOSCS = 241;

   wire [NUM_RINGOSCS-1:0] ringout;

   generate
      genvar 	      i;
      for (i = 0; i < NUM_RINGOSCS; i = i + 1)
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
   reg [3:0]  bit_counter = 0;

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
   
   // Update the word continuously, but change the displayed word more
   // slowly
   reg [31:0] 	disp_word, disp_word_copy;
   
   always @(posedge clk)
     begin
	// De-bias
	pair[pair_counter] <= ringxor;
	pair_counter <= pair_counter + 1;

	if (have_newbit)
	  begin
	     temp_byte[bit_counter[2:0]] <= newbit;

	     if (bit_counter == 4'b0111)
	       begin
		  out_byte <= temp_byte;
		  if (TxD_ready) TxD_start <= 1;
		  else TxD_start <= 0;

		  // Wait stage to ensure that the same byte cannot be
		  // sent twice. This will waste one new bit per byte,
		  // but I think we can afford it ;)
		  bit_counter <= 4'b1111;
		  
		  disp_word <= disp_word << 8;
		  disp_word[7:0] <= out_byte;
	       end // if (bit_counter == 4'b0111)
	     else
	       bit_counter <= bit_counter + 1;
	  end
     end

   // Debug: show something in 7seg at slow sampling

   reg [24:0] 	disp_counter;
   always @ (posedge clk)
     begin
	disp_counter <= disp_counter + 1;
	if (disp_counter == 0) disp_word_copy <= disp_word;
     end

   output [55:0] segment;
   input         disp_switch;
   wire [55:0] 	 segment_data;

   // inverted signals, so 1111.. to turn it off
   assign segment = disp_switch? segment_data : {56{1'b1}};

   hexdisp disp(.inword(disp_word_copy), .outword(segment_data));
endmodule   
