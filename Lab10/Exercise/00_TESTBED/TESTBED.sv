/*
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
NYCU Institute of Electronic
2025 Spring IC Design Laboratory 
Lab09: SystemVerilog Design and Verification 
File Name   : TESTBED.sv
Module Name : TESTBED
Release version : v1.0 (Release Date: May-2025)
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*/

`timescale 1ns/1ps
`define CYCLE_TIME 12.0

`include "Usertype.sv"
`include "INF.sv"
`include "../00_TESTBED/pseudo_DRAM.sv"

`ifdef RTL
  `include "AFS.sv"
  `include "PATTERN.sv"
  `include "CHECKER.sv"
`elsif COV
  `include "TA_AFS.sv"
  `include "PATTERN.sv"
  `include "CHECKER.sv"
`elsif ASSERT
  `include "TA_AFS.sv"
  `include "TA_PATTERN.sv"
  `include "CHECKER.sv"
`endif

module TESTBED;
  
parameter simulation_cycle = `CYCLE_TIME;
  reg  SystemClock;

  INF             inf();
  PATTERN         test_p(.clk(SystemClock), .inf(inf.PATTERN));
  pseudo_DRAM     dram_r(.clk(SystemClock), .inf(inf.DRAM)); 
  Checker check_inst (.clk(SystemClock), .inf(inf.CHECKER));
	AFS      dut_p(.clk(SystemClock), .inf(inf.AFS_inf) );

 //------ Generate Clock ------------
  initial begin
    SystemClock = 0;
	#30
    forever begin
      #(simulation_cycle/2.0)
        SystemClock = ~SystemClock;
    end
  end

//------ Dump FSDB File ------------  
initial begin
  $fsdbDumpfile("AFS.fsdb");
  $fsdbDumpvars(0,"+all");
  $fsdbDumpSVA;
end

endmodule