`timescale 1ns/1ps

`include "PATTERN.vp"
`ifdef RTL
  `include "MAZE.v"
`endif
`ifdef GATE
  `include "MAZE_SYN.v"
`endif

module TESTBED;

wire clk;
wire rst_n;
wire in_valid;
wire [1:0] in;
wire out_valid;
wire [1:0] out;

initial begin
    `ifdef RTL
        $fsdbDumpfile("MAZE.fsdb");
  	$fsdbDumpvars(0,"+all");
  	$fsdbDumpSVA;
        // $fsdbDumpvars(0, "+mda");
        // $fsdbDumpvars();
    `endif
    `ifdef GATE
        $sdf_annotate("MAZE_SYN.sdf", U_MAZE);
        $fsdbDumpfile("MAZE_SYN.fsdb");
        $fsdbDumpvars(0, "+mda");
        $fsdbDumpvars();    
    `endif
end

MAZE U_MAZE(
    //Input Port
    .clk      (clk),
    .rst_n    (rst_n),
    .in_valid (in_valid),
    .in       (in),

    //Output Port
    .out_valid(out_valid),
    .out      (out)
);

PATTERN U_PATTERN(
    //Input Port
    .clk      (clk),
    .rst_n    (rst_n),
    .in_valid (in_valid),
    .in       (in),

    //Output Port
    .out_valid(out_valid),
    .out      (out)
);

endmodule
