//############################################################################
//   2025 ICLAB Spring Course
//   Sparse Matrix Multiplier (SMM)
//############################################################################

module SMM(
  // Input Port
  clk,
  rst_n,
  in_valid_size,
  in_size,
  in_valid_a,
  in_row_a,
  in_col_a,
  in_val_a,
  in_valid_b,
  in_row_b,
  in_col_b,
  in_val_b,
  // Output Port
  out_valid,
  out_row,
  out_col,
  out_val
);



//==============================================//
//                   PARAMETER                  //
//==============================================//



//==============================================//
//                   I/O PORTS                  //
//==============================================//
input             clk, rst_n, in_valid_size, in_valid_a, in_valid_b;
input             in_size;
input      [4:0]  in_row_a, in_col_a, in_row_b, in_col_b;
input      [3:0]  in_val_a, in_val_b;
output reg        out_valid;
output reg [4:0]  out_row, out_col;
output reg [8:0] out_val;


//==============================================//
//            reg & wire declaration            //
//==============================================//
reg      [4:0]  in_row_a_ff, in_col_a_ff, in_row_b_ff, in_col_b_ff;
reg      [3:0]  in_val_a_ff, in_val_b_ff;
reg             in_valid_a_ff;
reg               in_size_ff;
reg [3:0] matrix_a [0:31][0:31];
reg [3:0] matrix_b [0:31][0:31];
reg [8:0] result_matrix [0:31][0:31];
reg [4:0] row_cnt;
reg [4:0] col_cnt;
reg [4:0] mul_cnt;
reg [8:0] out_temp [0:45];
reg [4:0] row_temp [0:45];
reg [4:0] col_temp [0:45];
reg [5:0] out_cnt;
reg [5:0] final_cnt;
integer i, j;
//==============================================//
//                    fsm                       //
//==============================================//
reg [2:0] c_state;
reg [2:0] n_state;
localparam IDLE = 'd0,
            INPUT = 'd1,
            MUL = 'd2,
            COUNT = 'd3,
            OUT = 'd4; 

always @(posedge clk or negedge rst_n) begin
  if (!rst_n)
    c_state <= IDLE;
  else
    c_state <= n_state;
end

always @(*) begin
  casex (c_state)
    IDLE: begin
        if (in_valid_a || in_valid_b)
          n_state = INPUT;
        else
          n_state = IDLE;
    end 
    INPUT: begin
        if(!(in_valid_a || in_valid_b))
          n_state = MUL;
        else
          n_state = INPUT;
    end
    MUL: begin
       if(mul_cnt == 'd31)
         n_state = COUNT;
        else
          n_state = MUL;
    end
    COUNT: begin
      if ((col_cnt == 'd31) && (row_cnt == 'd31))
        n_state = OUT;
      else
        n_state = COUNT;
    end
    OUT: begin
      if (final_cnt == (out_cnt - 1))
        n_state = IDLE;
      else
        n_state = OUT;
    end
    default: n_state = IDLE;
  endcase
end
//==============================================//
//                   Design                     //
//==============================================//

//==============================================//
//                    input                     //
//==============================================//

always @(posedge clk) begin
  if (!rst_n) begin
    in_col_a_ff <= 0;
    in_row_a_ff <= 0;
    in_val_a_ff <= 0;
  end
  else if (in_valid_a) begin
    in_col_a_ff <= in_col_a;
    in_row_a_ff <= in_row_a;
    in_val_a_ff <= in_val_a;
  end
  else begin
    in_col_a_ff <= in_col_a_ff;
    in_row_a_ff <= in_row_a_ff;
    in_val_a_ff <= in_val_a_ff;
  end
  
end

always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    in_col_b_ff <= 0;
    in_row_b_ff <= 0;
    in_val_b_ff <= 0;
  end
  else if (in_valid_b) begin
    in_col_b_ff <= in_col_b;
    in_row_b_ff <= in_row_b;
    in_val_b_ff <= in_val_b;
  end
  else begin
    in_col_b_ff <= in_col_b_ff;
    in_row_b_ff <= in_row_b_ff;
    in_val_b_ff <= in_val_b_ff;
  end
end

always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    for (i = 0; i < 32; i = i + 1) begin
      for (j = 0; j < 32; j = j + 1) begin
        matrix_a[i][j] <= 0;
      end
    end
  end
  else if (c_state == IDLE) begin
    for (i = 0; i < 32; i = i + 1) begin
      for (j = 0; j < 32; j = j + 1) begin
        matrix_a[i][j] <= 0;
      end
    end
  end
  else if (c_state == INPUT) begin
    matrix_a[in_row_a_ff][in_col_a_ff] <= in_val_a_ff;
  end
  else begin
    for (i = 0; i < 32; i = i + 1) begin
      for (j = 0; j < 32; j = j + 1) begin
        matrix_a[i][j] <= matrix_a[i][j];
      end
    end
  end
end

always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    for (i = 0; i < 32; i = i + 1) begin
      for (j = 0; j < 32; j = j + 1) begin
        matrix_b[i][j] <= 0;
      end
    end
  end
  else if (c_state == IDLE) begin
    for (i = 0; i < 32; i = i + 1) begin
      for (j = 0; j < 32; j = j + 1) begin
        matrix_b[i][j] <= 0;
      end
    end
  end
  else if (c_state == INPUT) begin
    matrix_b[in_row_b_ff][in_col_b_ff] <= in_val_b_ff;
  end
  else begin
    for (i = 0; i < 32; i = i + 1) begin
      for (j = 0; j < 32; j = j + 1) begin
        matrix_b[i][j] <= matrix_b[i][j];
      end
    end
  end
end

//==============================================//
//                      MUL                     //
//==============================================//
always @(posedge clk or negedge rst_n) begin
  if (!rst_n)
    mul_cnt <= 0;
  else if (c_state == IDLE)
    mul_cnt <= 0;
  else if (c_state == MUL)
    mul_cnt <= mul_cnt + 1;
  else
    mul_cnt <= mul_cnt;
end
genvar k, s;
generate
  for (k = 0; k < 32; k = k + 1) begin
    for (s = 0; s < 32; s = s + 1) begin
      always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
          result_matrix[k][s] <= 0;
        end
        else if (c_state == IDLE) begin 
          result_matrix[k][s] <= 0;
        end
        else if (c_state == MUL) begin
          result_matrix[k][s] <= result_matrix[k][s] + matrix_a[k][mul_cnt] * matrix_b[mul_cnt][s];
        end
        else begin
          result_matrix[k][s] <= result_matrix[k][s];
        end
    end
  end
end
endgenerate
//==============================================//
//                   output                     //
//==============================================//
always @(posedge clk or negedge rst_n) begin
  if (!rst_n)
    col_cnt <= 0;
  else if (c_state == IDLE)
    col_cnt <= 0;
  else if (c_state == COUNT) begin
    col_cnt <= col_cnt + 1;
  end
  else begin
    col_cnt <= col_cnt;
  end
end

always @(posedge clk or negedge rst_n) begin
  if (!rst_n)
    row_cnt <= 0;
  else if (c_state == IDLE)
    row_cnt <= 0;
  else if (c_state == COUNT) begin
    if (col_cnt == 31)
      row_cnt <= row_cnt + 1;
    else 
      row_cnt <= row_cnt;
  end
  else begin
    row_cnt <= row_cnt;
  end
end

always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    for (i = 0; i < 45; i = i + 1) begin
      out_temp[i] <= 'd0;
    end
  end
  else if (c_state == IDLE) begin
    for (i = 0; i < 45; i = i + 1) begin
      out_temp[i] <= 'd0;
    end
  end
  else if (c_state == COUNT)
    if (result_matrix[row_cnt][col_cnt] != 0) begin
      out_temp[0] <= result_matrix[row_cnt][col_cnt];
      for (i = 0; i < 45; i = i + 1) begin
        out_temp[i + 1] <= out_temp[i];
      end
    end
    else
      out_temp <= out_temp;
  else
    out_temp <= out_temp;
end

always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    for (i = 0; i < 45; i = i + 1) begin
      row_temp[i] <= 'd0;
    end
  end
  else if (c_state == IDLE) begin
    for (i = 0; i < 45; i = i + 1) begin
      row_temp[i] <= 'd0;
    end
  end
  else if (c_state == COUNT)
    if (result_matrix[row_cnt][col_cnt] != 0) begin
      row_temp[0] <= row_cnt;
      for (i = 0; i < 45; i = i + 1) begin
        row_temp[i + 1] <= row_temp[i];
      end
    end
    else
      row_temp <= row_temp;
  else
    row_temp <= row_temp;
end

always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    for (i = 0; i < 45; i = i + 1) begin
      col_temp[i] <= 'd0;
    end
  end
  else if (c_state == IDLE) begin
    for (i = 0; i < 45; i = i + 1) begin
      col_temp[i] <= 'd0;
    end
  end
  else if (c_state == COUNT)
    if (result_matrix[row_cnt][col_cnt] != 0) begin
      col_temp[0] <= col_cnt;
      for (i = 0; i < 45; i = i + 1) begin
        col_temp[i + 1] <= col_temp[i];
      end
    end
    else begin
      col_temp <= col_temp;
    end
  else begin
    col_temp <= col_temp;
  end
end


always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    out_cnt <= 0;
  end
  else if (c_state == IDLE)
    out_cnt <= 0;
  else if (c_state == COUNT)
    if (result_matrix[row_cnt][col_cnt] != 0) begin
      out_cnt <= out_cnt + 1;
    end
    else begin
      out_cnt <= out_cnt;
    end
  else begin
    out_cnt <= out_cnt;
  end
end


always @(posedge clk or negedge rst_n) begin
  if (!rst_n)
    out_valid <= 0 ;
  else if (c_state == OUT)
    out_valid <= 1;
  else 
    out_valid <= 0;
end

always @(posedge clk or negedge rst_n) begin
  if (!rst_n)
    out_col <= 0;
  else if (c_state == OUT)
    out_col <= col_temp[final_cnt];
  else
    out_col <= 0;
end

always @(posedge clk or negedge rst_n) begin
  if (!rst_n)
    out_row <= 0;
  else if (c_state == OUT)
    out_row <= row_temp[final_cnt];
  else
    out_row <= 0;
end

always @(posedge clk or negedge rst_n) begin
  if (!rst_n)
    out_val <= 0;
  else if (c_state == OUT)
    out_val <= out_temp[final_cnt];
  else
    out_val <= 0;
end

always @(posedge clk or negedge rst_n) begin
  if (!rst_n)
    final_cnt <= 0;
  else if (c_state == OUT)
    final_cnt <= final_cnt + 1;
  else
    final_cnt <= 0;
end
endmodule