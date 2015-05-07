// Altera version of rautanoppa, teknohog's hwrng

`ifdef DISPLAY
module hwrandom (osc_clk, TxD, segment, disp_switch, reset_button);
`else
module hwrandom (osc_clk, TxD, reset_button);
`endif
   
`ifdef NUM_PORTS
   parameter NUM_PORTS = `NUM_PORTS;
`else
   parameter NUM_PORTS = 1;
`endif
   
   // DE2-115 buttons have inverted logic
   input 	      reset_button;
   wire 	      reset;
   assign reset = ~reset_button;

   input       osc_clk;
   wire  clk;

   output [NUM_PORTS-1:0] TxD;
   
   parameter comm_clk_frequency = 50_000_000;

   main_pll pll_blk (osc_clk, clk);

   // 241 and 499 are both good on DE2-115 for near-perfect rngtest
   // 337 is near-perfect for 2 ports
`ifdef NUM_RINGOSCS
   parameter NUM_RINGOSCS = `NUM_RINGOSCS;
`else
   parameter NUM_RINGOSCS = 241;
`endif

`ifdef DISPLAY   
   wire [31:0] disp_word;

   hwrandom_core #(.NUM_PORTS(NUM_PORTS), .NUM_RINGOSCS(NUM_RINGOSCS), .comm_clk_frequency(comm_clk_frequency)) hwc (.clk(clk), .TxD(TxD), .reset(reset), .disp_word(disp_word));

   output [55:0] segment;
   input         disp_switch;
   wire [55:0] 	 segment_data;

   // inverted signals, so 1111.. to turn it off
   assign segment = disp_switch? segment_data : {56{1'b1}};

   hexdisp disp(.inword(disp_word), .outword(segment_data));
`else
   hwrandom_core #(.NUM_PORTS(NUM_PORTS), .NUM_RINGOSCS(NUM_RINGOSCS), .comm_clk_frequency(comm_clk_frequency)) hwc (.clk(clk), .TxD(TxD), .reset(reset));
`endif   
endmodule   
