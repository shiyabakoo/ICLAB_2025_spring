`timescale 1ns/1ps

`include "Usertype.sv"
`include "INF.sv"
`include "PATTERN.sv"
// `include "PATTERN_aaron.svp" 
// `include "PATTERN_hsien_v2.svp"
`include "../00_TESTBED/pseudo_DRAM.sv"

`ifdef RTL
  `include "AFS.sv"
  `define CYCLE_TIME 2.9
`endif

`ifdef GATE
  `include "AFS_SYN.v"
  `include "AFS_Wrapper.sv"
  `define CYCLE_TIME 2.9
`endif

module TESTBED;
  
parameter simulation_cycle = `CYCLE_TIME;
  reg  SystemClock;

  INF             inf();
  PATTERN         test_p(.clk(SystemClock), .inf(inf.PATTERN));
  pseudo_DRAM     dram_r(.clk(SystemClock), .inf(inf.DRAM)); 

  `ifdef RTL
	AFS      dut_p(.clk(SystemClock), .inf(inf.AFS_inf) );
  `endif
  
  `ifdef GATE
	AFS_svsim     dut_p(.clk(SystemClock), .inf(inf.AFS_inf) );
  `endif  
 //------ Generate Clock ------------
  initial begin
    SystemClock = 0;
	#10
    forever begin
      #(simulation_cycle/2.0)
        SystemClock = ~SystemClock;
    end
  end

//------ Dump FSDB File ------------  
initial begin
  `ifdef RTL
    $fsdbDumpfile("AFS.fsdb");
    $fsdbDumpvars(0,"+all");
    $fsdbDumpSVA;
  `elsif GATE
    $fsdbDumpfile("AFS_SYN.fsdb");  
    $sdf_annotate("AFS_SYN.sdf",dut_p.AFS);      
    $fsdbDumpvars(0,"+all");
  `endif
end

endmodule