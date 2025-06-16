/**************************************************************************/
// Copyright (c) 2025, OASIS Lab
// MODULE: TESTBED
// FILE NAME: TESTBED.v
// VERSRION: 1.0
// DATE: 2025/02/26
// AUTHOR: Yu-Hao Cheng, NYCU IEE
// DESCRIPTION: ICLAB 2025 Spring / LAB3 / STA
// MODIFICATION HISTORY:
// Date                 Description
// 
/**************************************************************************/
`timescale 1ns/10ps

`include "PATTERN.v"
`ifdef RTL
	`include "STA.v"
`endif
`ifdef GATE
    `include "STA_SYN.v"
`endif
`ifdef POST
    `include "CHIP.v"
`endif

module TESTBED;

wire			rst_n, clk, in_valid;
wire	[3:0]	delay;
wire	[3:0]	source;
wire	[3:0]	destination;

wire 			out_valid;
wire	[7:0]	worst_delay;
wire	[3:0]	path;

initial begin
    `ifdef RTL
        $fsdbDumpfile("STA.fsdb");
        $fsdbDumpvars(0,"+mda");
    `endif
    `ifdef GATE
        $sdf_annotate("STA_SYN.sdf", u_STA);
        $fsdbDumpfile("STA_SYN.fsdb");
        $fsdbDumpvars(0,"+mda"); 
    `endif
	`ifdef POST
        $sdf_annotate("CHIP.sdf", u_CHIP);
        $fsdbDumpfile("CHIP_POST.fsdb");
        $fsdbDumpvars(0,"+mda"); 
    `endif
end

`ifdef RTL
	STA u_STA(
		.rst_n(rst_n),
		.clk(clk),
		.in_valid(in_valid),
		.delay(delay),
		.source(source),
		.destination(destination),
		.out_valid(out_valid),
		.worst_delay(worst_delay),
		.path(path)
	);
`endif

`ifdef GATE
	STA u_STA(
		.rst_n(rst_n),
		.clk(clk),
		.in_valid(in_valid),
		.delay(delay),
		.source(source),
		.destination(destination),
		.out_valid(out_valid),
		.worst_delay(worst_delay),
		.path(path)
	);
`endif

`ifdef POST
	CHIP u_CHIP(
		.rst_n(rst_n),
		.clk(clk),
		.in_valid(in_valid),
		.delay(delay),
		.source(source),
		.destination(destination),
		.out_valid(out_valid),
		.worst_delay(worst_delay),
		.path(path)
	);
`endif
    
PATTERN u_PATTERN(
    .rst_n(rst_n),
	.clk(clk),
	.in_valid(in_valid),
	.delay(delay),
	.source(source),
	.destination(destination),
	.out_valid(out_valid),
	.worst_delay(worst_delay),
	.path(path)
);

endmodule
