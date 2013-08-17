// Altera version of rautanoppa, teknohog's hwrng

module hwrandom (osc_clk, TxD, segment, disp_switch, reset_button);
   
   // DE2-115 buttons have inverted logic
   input 	      reset_button;
   wire 	      reset;
   assign reset = ~reset_button;

   input       osc_clk;
   wire  clk;

   output TxD;
   
   parameter comm_clk_frequency = 50_000_000;

   main_pll pll_blk (osc_clk, clk);

   wire [31:0] disp_word;

   // 241 and 499 are both good on DE2-115 for near-perfect rngtest
   parameter NUM_RINGOSCS = 241;
   
   hwrandom_core #(.NUM_RINGOSCS(NUM_RINGOSCS), .comm_clk_frequency(comm_clk_frequency)) hwc (.clk(clk), .TxD(TxD), .reset(reset), .disp_word(disp_word));

   output [55:0] segment;
   input         disp_switch;
   wire [55:0] 	 segment_data;

   // inverted signals, so 1111.. to turn it off
   assign segment = disp_switch? segment_data : {56{1'b1}};

   hexdisp disp(.inword(disp_word), .outword(segment_data));
endmodule   
