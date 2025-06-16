//############################################################################
//   2025 ICLAB Spring Course
//   Sparse Matrix Multiplier (SMM)
//############################################################################

`timescale 1ns/10ps

`include "PATTERN.vp"
`ifdef RTL
  `include "SMM.v"
`endif
`ifdef GATE
  `include "SMM_SYN.v"
`endif
            
module TESTBED;

// Signal
wire        rst_n, clk, in_valid_size, in_valid_a, in_valid_b;
wire        in_size;
wire [4:0]  in_row_a, in_col_a, in_row_b, in_col_b;
wire [3:0]  in_val_a, in_val_b;
wire        out_valid;
wire [4:0]  out_row, out_col;
wire [8:0] out_val;



initial begin
  `ifdef RTL
    $fsdbDumpfile("SMM.fsdb");
    $fsdbDumpvars(0,"+mda");
    $fsdbDumpvars();
  `endif
  `ifdef GATE
    $sdf_annotate("SMM_SYN.sdf", u_SMM);
    // $fsdbDumpfile("SMM_SYN.fsdb");
    // $fsdbDumpvars();    
  `endif
end

`ifdef RTL
SMM u_SMM(
  .clk(clk),
  .rst_n(rst_n),
  .in_valid_size(in_valid_size),
  .in_size(in_size),
  .in_valid_a(in_valid_a),
  .in_row_a(in_row_a),
  .in_col_a(in_col_a),
  .in_val_a(in_val_a),
  .in_valid_b(in_valid_b),
  .in_row_b(in_row_b),
  .in_col_b(in_col_b),
  .in_val_b(in_val_b),
  .out_valid(out_valid),
  .out_row(out_row),
  .out_col(out_col),
  .out_val(out_val)
);
`endif

`ifdef GATE
SMM u_SMM(
  .clk(clk),
  .rst_n(rst_n),
  .in_valid_size(in_valid_size),
  .in_size(in_size),
  .in_valid_a(in_valid_a),
  .in_row_a(in_row_a),
  .in_col_a(in_col_a),
  .in_val_a(in_val_a),
  .in_valid_b(in_valid_b),
  .in_row_b(in_row_b),
  .in_col_b(in_col_b),
  .in_val_b(in_val_b),
  .out_valid(out_valid),
  .out_row(out_row),
  .out_col(out_col),
  .out_val(out_val)
);
`endif

PATTERN u_PATTERN(
  .clk(clk),
  .rst_n(rst_n),
  .in_valid_size(in_valid_size),
  .in_size(in_size),
  .in_valid_a(in_valid_a),
  .in_row_a(in_row_a),
  .in_col_a(in_col_a),
  .in_val_a(in_val_a),
  .in_valid_b(in_valid_b),
  .in_row_b(in_row_b),
  .in_col_b(in_col_b),
  .in_val_b(in_val_b),
  .out_valid(out_valid),
  .out_row(out_row),
  .out_col(out_col),
  .out_val(out_val)
);


endmodule
