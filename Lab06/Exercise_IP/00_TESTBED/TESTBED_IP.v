/**************************************************************************/
// Copyright (c) 2023, SI2 Lab
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
`include "PATTERN_IP.v"
// DESIGN
`ifdef RTL
	`include "Division_IP_demo.v"
`elsif GATE
	`include "Division_IP_demo_SYN.v"
`endif


module TESTBED(); 

// Parameter
parameter IP_WIDTH = 7; 

// Connection wires
wire [IP_WIDTH*4-1:0] dividend, divisor;
wire [IP_WIDTH*4-1:0] quotient;

initial begin
 	`ifdef RTL
    	$fsdbDumpfile("Division_IP_demo.fsdb");
		$fsdbDumpvars(0,"+mda");
	`elsif GATE
		//$fsdbDumpfile("Division_IP_demo_SYN.fsdb");
		//$fsdbDumpvars(0,"+mda");
		$sdf_annotate("Division_IP_demo_SYN.sdf",IP_Division); 
	`endif
end

`ifdef RTL
	Division_IP_demo #(.IP_WIDTH(IP_WIDTH)) IP_Division (
		.IN_Dividend(dividend),
		.IN_Divisor(divisor),
		.OUT_Quotient(quotient)
	);


	PATTERN #(.IP_WIDTH(IP_WIDTH)) I_PATTERN(
		.IN_Dividend(dividend),
		.IN_Divisor(divisor),
		.OUT_Quotient(quotient)
	);
	
`elsif GATE
    Division_IP_demo IP_Division  (
        .IN_Dividend(dividend),
		.IN_Divisor(divisor),
		.OUT_Quotient(quotient)
    );
    
    PATTERN #(.IP_WIDTH(IP_WIDTH)) My_PATTERN (
        .IN_Dividend(dividend),
		.IN_Divisor(divisor),
		.OUT_Quotient(quotient)
    );

`endif  

endmodule
