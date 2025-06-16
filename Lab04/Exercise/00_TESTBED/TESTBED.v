//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2023 Fall
//   Lab04 Exercise		: Two Head Attention
//   Author     		: Yu-Chi Lin (a6121461214.st12@nycu.edu.tw)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : ATTN.v
//   Module Name : ATTN
//   Release version : V1.0 (Release Date: 2025-3)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################


`timescale 1ns/10ps

`include "PATTERN.v"

`ifdef RTL
  `include "ATTN.v"
`endif
`ifdef GATE
  `include "ATTN_SYN.v"
`endif

 		  	
module TESTBED;

wire          clk, rst_n, in_valid;
wire  [31:0]  in_str;
wire  [31:0]  q_weight;
wire  [31:0]  k_weight;
wire  [31:0]  v_weight;
wire  [31:0]  out_weight;
wire          out_valid;
wire  [31:0]  out;


initial begin
  `ifdef RTL
    $fsdbDumpfile("ATTN.fsdb");
	  $fsdbDumpvars(0,"+mda");
    $fsdbDumpvars();
  `endif
  `ifdef GATE
    $sdf_annotate("ATTN_SYN.sdf", u_ATTN);
    $fsdbDumpfile("ATTN_SYN.fsdb");
    $fsdbDumpvars();    
  `endif
end

`ifdef RTL
ATTN u_ATTN(
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(in_valid),
    .in_str(in_str),
    .q_weight(q_weight),
    .k_weight(k_weight),
    .v_weight(v_weight),
    .out_weight(out_weight),
    .out_valid(out_valid),
    .out(out)
    );
`endif

`ifdef GATE
ATTN u_ATTN(
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(in_valid),
    .in_str(in_str),
    .q_weight(q_weight),
    .k_weight(k_weight),
    .v_weight(v_weight),
    .out_weight(out_weight),
    .out_valid(out_valid),
    .out(out)
    );
`endif

PATTERN u_PATTERN(
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(in_valid),
    .in_str(in_str),
    .q_weight(q_weight),
    .k_weight(k_weight),
    .v_weight(v_weight),
    .out_weight(out_weight),
    .out_valid(out_valid),
    .out(out)
    );
 
endmodule
