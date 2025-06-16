/**************************************************************************/
// CopyrigBCH (c) 2023, SI2 Lab
// MODULE: TESTBED
// FILE NAME: TESTBED.v
// VERSRION: 1.0
// DATE: July 5, 2023
// AUTHOR: SHAO-HUA LIEN, NYCU IEE
// CODE TYPE: RTL or Behavioral Level (Verilog)
// 
/**************************************************************************/

`timescale 1ns/1ps

// PATTERN
`include "PATTERN.v"
// DESIGN
`ifdef RTL
	`include "BCH_TOP.v"
`elsif GATE
	`include "BCH_TOP_SYN.v"
`endif


module TESTBED();

	wire clk, in_valid, out_valid;
	wire [3:0] in_syndrome, out_location;

initial begin
 	`ifdef RTL
    	$fsdbDumpfile("BCH_TOP.fsdb");
		$fsdbDumpvars(0,"+mda");
	`elsif GATE
		//$fsdbDumpfile("BCH_TOP_SYN.fsdb");
		//$fsdbDumpvars(0,"+mda");
		$sdf_annotate("BCH_TOP_SYN.sdf",I_BCH); 
	`endif
end

BCH_TOP I_BCH
(
	 // Input signals
    .clk(clk),
	.rst_n(rst_n),
	.in_valid(in_valid),
    .in_syndrome(in_syndrome),
    // Output signals
    .out_valid(out_valid), 
	.out_location(out_location)
);


PATTERN I_PATTERN
(
	// Output signals
    .clk(clk),
	.rst_n(rst_n),
	.in_valid(in_valid),
    .in_syndrome(in_syndrome),
    // Input signals
    .out_valid(out_valid), 
	.out_location(out_location)
);

endmodule
