// Nexys2 version of rautanoppa, teknohog's hwrng

`include "main_pll.v"
`include "../common_hdl/hwrandom_core.v"
`include "../common_hdl/uart_transmitter.v"
`include "../common_hdl/ringosc.v"

`include "raw7seg.v"

module hwrandom (osc_clk, TxD, reset, segment, anode, disp_switch);
   
   input reset;
   input       osc_clk;
   wire  clk;

   output TxD;

   parameter comm_clk_frequency = 50_000_000;
   
   main_pll pll_blk (.CLKIN_IN(osc_clk), .CLK0_OUT(clk));

   // 73, 101 are good for Nexys2 500k, 137 is too much, 131 seems best
   parameter NUM_RINGOSCS = 131;

   wire [31:0] disp_word;

   hwrandom_core #(.NUM_RINGOSCS(NUM_RINGOSCS), .comm_clk_frequency(comm_clk_frequency)) hwc (.clk(clk), .TxD(TxD), .reset(reset), .disp_word(disp_word));

   // Debug: show something in 7seg at slow sampling
   output [7:0] segment;
   output [3:0] anode;

   input 	disp_switch;
   
   wire [7:0] 	segment_data;

   // inverted signals, so 1111.. to turn it off
   assign segment = disp_switch? segment_data : {8{1'b1}};
   
   raw7seg disp(.clk(clk), .segment(segment_data), .anode(anode), .word(disp_word));
endmodule   
