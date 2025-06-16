//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2024 Fall
//   Lab01 Exercise		: Snack Shopping Calculator
//   Author     		: Yu-Hsiang Wang
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : TESTBED.v
//   Module Name : TESTBED
//   Release version : V1.0 (Release Date: 2024-09)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

`timescale 1ns/10ps
`include "PATTERN.v"
`ifdef RTL
  `include "HF.v"
`endif
`ifdef GATE
  `include "HF_SYN.v"
`endif
 
module TESTBED;

//Connection wires
wire [24:0] symbol_freq;

wire [19:0] out_encoded;

initial begin
  `ifdef RTL
    $fsdbDumpfile("HF.fsdb");
	$fsdbDumpvars(0,"+mda");
    $fsdbDumpvars();
  `endif
  `ifdef GATE
    $sdf_annotate("HF_SYN.sdf", DUT_HF);
    $fsdbDumpfile("HF_SYN.fsdb");
	$fsdbDumpvars(0,"+mda");
    $fsdbDumpvars();    
  `endif
end

HF DUT_HF(
  .symbol_freq(symbol_freq),

  .out_encoded(out_encoded)
);

PATTERN My_PATTERN(
  .symbol_freq(symbol_freq),

  .out_encoded(out_encoded)
);
 
endmodule
