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


module ATTN(
    //Input Port
    clk,
    rst_n,

    in_valid,
    in_str,
    q_weight,
    k_weight,
    v_weight,
    out_weight,

    //Output Port
    out_valid,
    out
    );

//---------------------------------------------------------------------
//   PARAMETER
//---------------------------------------------------------------------

// IEEE floating point parameter
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch_type = 0;
parameter inst_arch = 0;
parameter inst_faithful_round = 0;
parameter sqare_root_2 = 32'b00111111101101010000010011110011;

parameter IDLE = 3'd0;
parameter IN = 3'd1;
parameter CAL = 3'd2;
parameter OUT = 3'd3;

input rst_n, clk, in_valid;
input [inst_sig_width+inst_exp_width:0] in_str, q_weight, k_weight, v_weight, out_weight;

output reg	out_valid;
output reg [inst_sig_width+inst_exp_width:0] out;


//---------------------------------------------------------------------
//   Reg & Wires
//---------------------------------------------------------------------
reg       weight_in_valid;
reg [2:0] c_state;
reg [2:0] n_state;
reg [6:0] counter;

reg [2:0] row;
reg [2:0] col;
reg [2:0] row_ff;
reg [2:0] col_ff;
reg       counter_div_en;
reg       div_score2;
reg       softmax_score2_en;
reg       mult_use_cnt_div;

reg [inst_sig_width+inst_exp_width:0] softmax_row0;
reg [inst_sig_width+inst_exp_width:0] softmax_row1;
reg [inst_sig_width+inst_exp_width:0] softmax_row2;
reg [inst_sig_width+inst_exp_width:0] softmax_row3;
reg [inst_sig_width+inst_exp_width:0] softmax_row4;

reg [inst_sig_width+inst_exp_width:0] in_str_ff;
reg [inst_sig_width+inst_exp_width:0] q_weight_ff;
reg [inst_sig_width+inst_exp_width:0] k_weight_ff;
reg [inst_sig_width+inst_exp_width:0] v_weight_ff;
reg [inst_sig_width+inst_exp_width:0] out_weight_ff;

reg [inst_sig_width+inst_exp_width:0] in_str_arr [0:4][0:3];
reg [inst_sig_width+inst_exp_width:0] q_weight_arr [0:3][0:3];
reg [inst_sig_width+inst_exp_width:0] k_weight_arr [0:3][0:3];
reg [inst_sig_width+inst_exp_width:0] v_weight_arr [0:3][0:3];
reg [inst_sig_width+inst_exp_width:0] out_weight_arr [0:3][0:3];
// reg [inst_sig_width+inst_exp_width:0] in_str_arr [0:19];
// reg [inst_sig_width+inst_exp_width:0] q_weight_arr [0:15];
// reg [inst_sig_width+inst_exp_width:0] k_weight_arr [0:15];
// reg [inst_sig_width+inst_exp_width:0] v_weight_arr [0:15];
// reg [inst_sig_width+inst_exp_width:0] out_weight_arr [0:15];

reg [inst_sig_width+inst_exp_width:0] q_matrix [0:4][0:3];
reg [inst_sig_width+inst_exp_width:0] k_matrix [0:4][0:3];
reg [inst_sig_width+inst_exp_width:0] v_matrix [0:4][0:3];
reg [inst_sig_width+inst_exp_width:0] score_1_matrix [0:4][0:4];
reg [inst_sig_width+inst_exp_width:0] score_2_matrix [0:4][0:4];

reg [inst_sig_width+inst_exp_width:0] head_out [0:4][0:3];
reg [inst_sig_width+inst_exp_width:0] final_matrix [0:4][0:3];

reg [inst_sig_width+inst_exp_width:0] mul1_a;
reg [inst_sig_width+inst_exp_width:0] mul1_b;
reg [inst_sig_width+inst_exp_width:0] mul1_res;
reg [7:0]                             mul_status1;

reg [inst_sig_width+inst_exp_width:0] mul2_a;
reg [inst_sig_width+inst_exp_width:0] mul2_b;
reg [inst_sig_width+inst_exp_width:0] mul2_res;
reg [7:0]                             mul_status2;

reg [inst_sig_width+inst_exp_width:0] mul3_a;
reg [inst_sig_width+inst_exp_width:0] mul3_b;
reg [inst_sig_width+inst_exp_width:0] mul3_res;
reg [7:0]                             mul_status3;

reg [inst_sig_width+inst_exp_width:0] mul4_a;
reg [inst_sig_width+inst_exp_width:0] mul4_b;
reg [inst_sig_width+inst_exp_width:0] mul4_res;
reg [7:0]                             mul_status4;

reg [inst_sig_width+inst_exp_width:0] mul5_a;
reg [inst_sig_width+inst_exp_width:0] mul5_b;
reg [inst_sig_width+inst_exp_width:0] mul5_res;
reg [7:0]                             mul_status5;

reg [inst_sig_width+inst_exp_width:0] mul6_a;
reg [inst_sig_width+inst_exp_width:0] mul6_b;
reg [inst_sig_width+inst_exp_width:0] mul6_res;
reg [7:0]                             mul_status6;

reg [inst_sig_width+inst_exp_width:0] mul7_a;
reg [inst_sig_width+inst_exp_width:0] mul7_b;
reg [inst_sig_width+inst_exp_width:0] mul7_res;
reg [7:0]                             mul_status7;

reg [inst_sig_width+inst_exp_width:0] mul8_a;
reg [inst_sig_width+inst_exp_width:0] mul8_b;
reg [inst_sig_width+inst_exp_width:0] mul8_res;
reg [7:0]                             mul_status8;

reg [inst_sig_width+inst_exp_width:0] add1_a;
reg [inst_sig_width+inst_exp_width:0] add1_b;
reg [inst_sig_width+inst_exp_width:0] add1_res;
reg [7:0]                             add_status1;

reg [inst_sig_width+inst_exp_width:0] add2_a;
reg [inst_sig_width+inst_exp_width:0] add2_b;
reg [inst_sig_width+inst_exp_width:0] add2_res;
reg [7:0]                             add_status2;

reg [inst_sig_width+inst_exp_width:0] add3_a;
reg [inst_sig_width+inst_exp_width:0] add3_b;
reg [inst_sig_width+inst_exp_width:0] add3_res;
reg [7:0]                             add_status3;

reg [inst_sig_width+inst_exp_width:0] add4_a;
reg [inst_sig_width+inst_exp_width:0] add4_b;
reg [inst_sig_width+inst_exp_width:0] add4_res;
reg [7:0]                             add_status4;

reg [inst_sig_width+inst_exp_width:0] add5_a;
reg [inst_sig_width+inst_exp_width:0] add5_b;
reg [inst_sig_width+inst_exp_width:0] add5_res;
reg [7:0]                             add_status5;

reg [inst_sig_width+inst_exp_width:0] add6_a;
reg [inst_sig_width+inst_exp_width:0] add6_b;
reg [inst_sig_width+inst_exp_width:0] add6_res;
reg [7:0]                             add_status6;

reg [inst_sig_width+inst_exp_width:0] add7_a;
reg [inst_sig_width+inst_exp_width:0] add7_b;
reg [inst_sig_width+inst_exp_width:0] add7_res;
reg [7:0]                             add_status7;

reg [inst_sig_width+inst_exp_width:0] exp1_in;
reg [inst_sig_width+inst_exp_width:0] exp1_res;
reg [7:0]                             exp_status1;

reg [inst_sig_width+inst_exp_width:0] div1_a;
reg [inst_sig_width+inst_exp_width:0] div1_b;
reg [inst_sig_width+inst_exp_width:0] div1_res;
reg [7:0]                             div_status1;

reg [inst_sig_width+inst_exp_width:0] div2_a;
reg [inst_sig_width+inst_exp_width:0] div2_b;
reg [inst_sig_width+inst_exp_width:0] div2_res;
reg [7:0]                             div_status2;

integer k, m;
genvar i, j;
//---------------------------------------------------------------------
// IPs
//---------------------------------------------------------------------
// ex.
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
MUL1 ( .a(mul1_a), .b(mul1_b), .rnd(3'b000), .z(mul1_res), .status(mul_status1));
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
MUL2 ( .a(mul2_a), .b(mul2_b), .rnd(3'b000), .z(mul2_res), .status(mul_status2));
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
MUL3 ( .a(mul3_a), .b(mul3_b), .rnd(3'b000), .z(mul3_res), .status(mul_status3));
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
MUL4 ( .a(mul4_a), .b(mul4_b), .rnd(3'b000), .z(mul4_res), .status(mul_status4));
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
ADD1 ( .a(add1_a), .b(add1_b), .rnd(3'b000), .z(add1_res), .status(add_status1));
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
ADD2 ( .a(add2_a), .b(add2_b), .rnd(3'b000), .z(add2_res), .status(add_status2));
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
ADD3 ( .a(add3_a), .b(add3_b), .rnd(3'b000), .z(add3_res), .status(add_status3));

DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
MUL5 ( .a(mul5_a), .b(mul5_b), .rnd(3'b000), .z(mul5_res), .status(mul_status5));
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
MUL6 ( .a(mul6_a), .b(mul6_b), .rnd(3'b000), .z(mul6_res), .status(mul_status6));
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
MUL7 ( .a(mul7_a), .b(mul7_b), .rnd(3'b000), .z(mul7_res), .status(mul_status7));
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
MUL8 ( .a(mul8_a), .b(mul8_b), .rnd(3'b000), .z(mul8_res), .status(mul_status8));
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
ADD4 ( .a(add4_a), .b(add4_b), .rnd(3'b000), .z(add4_res), .status(add_status4));
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
ADD5 ( .a(add5_a), .b(add5_b), .rnd(3'b000), .z(add5_res), .status(add_status5));
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
ADD6 ( .a(add6_a), .b(add6_b), .rnd(3'b000), .z(add6_res), .status(add_status6));

DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance, 0) 
EXP1 (.a(exp1_in), .z(exp1_res), .status(exp_status1));

DW_fp_div #(inst_sig_width, inst_exp_width, inst_ieee_compliance, 0) 
DIV1 ( .a(div1_a), .b(sqare_root_2), .rnd(3'b000), .z(div1_res), .status(div_status1));

DW_fp_div #(inst_sig_width, inst_exp_width, inst_ieee_compliance, 0) 
DIV2 ( .a(div2_a), .b(div2_b), .rnd(3'b000), .z(div2_res), .status(div_status2));

DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
ADD7 ( .a(add7_a), .b(add7_b), .rnd(3'b000), .z(add7_res), .status(add_status7));
//---------------------------------------------------------------------
// Design
//---------------------------------------------------------------------

//=================================//
//              fsm                //
//=================================//
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        c_state <= IDLE;
    else
        c_state <= n_state;
end

always @(*) begin
    case (c_state)
        IDLE: if (in_valid) 
                n_state = IN;
              else
                n_state = IDLE;
        IN  : if (!in_valid)
                n_state = CAL;
              else
                n_state = IN;
        CAL : if (counter == 90)
                n_state = OUT;
              else
                n_state = CAL;
        OUT : if (counter == 110)
                n_state = IDLE;
              else
                n_state = OUT;
        default: n_state = IDLE; 
    endcase
end


always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        out_valid <= 0;
    else if (c_state == IDLE)
        out_valid <= 0;
    else begin
        if (c_state == OUT)
            out_valid <= 1;
        else
            out_valid <= 0;
    end      
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        out <= 0;
    else if (c_state == IDLE)
        out <= 0;
    else if (c_state == OUT)
        out <= final_matrix[0][0];
    else
        out <= 0;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        counter <= 0;
    else if (!in_valid && (counter == 0))
        counter <= 0 ;
    else begin
        if (counter == 110)
            counter <= 0;
        else
            counter <= counter + 1;
    end  
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        counter_div_en <= 0;
    else if (c_state == IDLE)
        counter_div_en <= 0;
    else begin
        if (counter == 28)
            counter_div_en <= 1;
        else
            counter_div_en <= counter_div_en; 
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        row <= 'd0;
    else if (c_state == IDLE)
        row <= 0;
    else begin
        if (col == 4) begin
            if (row == 4)
                row <= 0;
            else
                row <= row + 1;
        end
        else
            row <= row; 
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        col <= 'd0;
    else if (c_state == IDLE)
        col <= 0;
    else begin
        if (counter_div_en) begin
            if (col == 4)
                col <= 0;
            else
                col <= col + 1;
        end
        else
            col <= col; 
    end
end


always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        div_score2 <= 0;
    else if (c_state == IDLE)
        div_score2 <= 0;
    else begin
        if (row == 4 && col == 4)
            div_score2 <= 1;
        else
            div_score2 <= div_score2; 
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        softmax_score2_en <= 0;
    else if (c_state == IDLE)
        softmax_score2_en <= 0;
    else begin
        if (row == 1 && col == 2 && div_score2)
            softmax_score2_en <= 1;
        else
            softmax_score2_en <= softmax_score2_en;
    end
end

// always @(posedge clk or negedge rst_n) begin
//     if (!rst_n)
//         mult_use_cnt_div <= 0;
//     else if (c_state == IDLE)
//         mult_use_cnt_div <= 0;
//     else begin
//         if (counter == 50)
//             mult_use_cnt_div <= 1;
//         else
//             mult_use_cnt_div <= mult_use_cnt_div; 
//     end
// end
//=================================//
//            save input           //
//=================================//
generate
    for (i = 0; i < 5; i = i + 1) begin
        for (j = 0; j < 4; j = j + 1) begin 
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n)
                    in_str_arr[i][j] <= 0;
                // else if (counter == 110)
                //     in_str_arr[i][j] <= 0;
                else if ((counter == j + i * 4) && in_valid)
                    in_str_arr[i][j] <= in_str; 
                else
                    in_str_arr[i][j] <= in_str_arr[i][j];
            end
        end
    end
endgenerate

generate
    for (i = 0; i < 4; i = i + 1) begin
        for (j = 0; j < 4; j = j + 1) begin
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n)
                    q_weight_arr[i][j] <= 0;
                // else if (counter == 110)
                //     q_weight_arr[i][j] <= 0;
                else if ((counter == j + i * 4) && in_valid)
                    q_weight_arr[i][j] <= q_weight; 
                else
                    q_weight_arr[i][j] <= q_weight_arr[i][j];
            end
        end
    end
endgenerate

generate
    for (i = 0; i < 4; i = i + 1) begin
        for (j = 0; j < 4; j = j + 1) begin
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n)
                    v_weight_arr[i][j] <= 0;
                // else if (counter == 110)
                //     v_weight_arr[i][j] <= 0;
                else if ((counter == j + i * 4) && in_valid)
                    v_weight_arr[i][j] <= v_weight; 
                else
                    v_weight_arr[i][j] <= v_weight_arr[i][j];
            end
        end
    end
endgenerate

generate
    for (i = 0; i < 4; i = i + 1) begin
        for (j = 0; j < 4; j = j + 1) begin
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n)
                    k_weight_arr[i][j] <= 0;
                // else if (counter == 110)
                //     k_weight_arr[i][j] <= 0;
                else if ((counter == j + i * 4) && in_valid)
                    k_weight_arr[i][j] <= k_weight; 
                else
                    k_weight_arr[i][j] <= k_weight_arr[i][j];
            end
        end
    end
endgenerate

generate
    for (i = 0; i < 4; i = i + 1) begin
        for (j = 0; j < 4; j = j + 1) begin
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n)
                    out_weight_arr[i][j] <= 0;
                // else if (counter == 110)
                //     out_weight_arr[i][j] <= 0;
                else if ((counter == j + i * 4) && in_valid)
                    out_weight_arr[i][j] <= out_weight; 
                else
                    out_weight_arr[i][j] <= out_weight_arr[i][j];
            end
        end
    end
endgenerate
//===========================================================
//=================================//
//            calculate            //
//=================================//

//=========================================//
//           in_str x k_weight             //
//=========================================//
always @(*) begin
    case (counter)
        // k
        'd4:  mul1_a = in_str_arr[0][0];
        'd8:  mul1_a = in_str_arr[1][0];
        'd9:  mul1_a = in_str_arr[0][0];
        'd10: mul1_a = in_str_arr[1][0];
        'd12: mul1_a = in_str_arr[2][0];
        'd13: mul1_a = in_str_arr[0][0];
        'd14: mul1_a = in_str_arr[1][0];
        'd15: mul1_a = in_str_arr[2][0];
        'd16: mul1_a = in_str_arr[3][0];
        'd17: mul1_a = in_str_arr[0][0];
        'd18: mul1_a = in_str_arr[1][0];
        'd19: mul1_a = in_str_arr[2][0];
        'd20: mul1_a = in_str_arr[4][0];
        'd21: mul1_a = in_str_arr[2][0];
        'd22: mul1_a = in_str_arr[3][0];
        'd23: mul1_a = in_str_arr[4][0];
        'd24: mul1_a = in_str_arr[3][0];
        'd25: mul1_a = in_str_arr[4][0];
        'd26: mul1_a = in_str_arr[3][0];
        'd27: mul1_a = in_str_arr[4][0];
        // v
        'd28: mul1_a = in_str_arr[0][0];
        'd29: mul1_a = in_str_arr[1][0];
        'd30: mul1_a = in_str_arr[2][0];
        'd31: mul1_a = in_str_arr[3][0];
        'd32: mul1_a = in_str_arr[4][0];
        'd33: mul1_a = in_str_arr[0][0];
        'd34: mul1_a = in_str_arr[1][0];
        'd35: mul1_a = in_str_arr[2][0];
        'd36: mul1_a = in_str_arr[3][0];
        'd37: mul1_a = in_str_arr[4][0];
        'd38: mul1_a = in_str_arr[0][0];
        'd39: mul1_a = in_str_arr[1][0];
        'd40: mul1_a = in_str_arr[2][0];
        'd41: mul1_a = in_str_arr[3][0];
        'd42: mul1_a = in_str_arr[4][0];
        'd43: mul1_a = in_str_arr[0][0];
        'd44: mul1_a = in_str_arr[1][0];
        'd45: mul1_a = in_str_arr[2][0];
        'd46: mul1_a = in_str_arr[3][0];
        'd47: mul1_a = in_str_arr[4][0];
        // score2
        'd48: mul1_a = q_matrix[3][2];
        'd49: mul1_a = q_matrix[3][2];
        'd50: mul1_a = q_matrix[4][2];
        // head_out 1
        'd51: mul1_a = score_1_matrix[0][0];
        'd52: mul1_a = score_1_matrix[0][0];
        'd53: mul1_a = score_1_matrix[1][0];
        'd54: mul1_a = score_1_matrix[1][0];
        'd55: mul1_a = score_1_matrix[2][0];
        'd56: mul1_a = score_1_matrix[2][0];
        'd57: mul1_a = score_1_matrix[3][0];
        'd58: mul1_a = score_1_matrix[3][0];
        'd62: mul1_a = score_1_matrix[4][0];
        'd63: mul1_a = score_1_matrix[4][0];
        // head_out 2
        'd67: mul1_a = score_2_matrix[0][0];
        'd68: mul1_a = score_2_matrix[0][0];
        'd72: mul1_a = score_2_matrix[1][0];
        'd73: mul1_a = score_2_matrix[1][0];
        'd77: mul1_a = score_2_matrix[2][0];
        'd78: mul1_a = score_2_matrix[2][0];
        'd82: mul1_a = score_2_matrix[3][0];
        'd83: mul1_a = score_2_matrix[3][0];
        'd87: mul1_a = score_2_matrix[4][0];
        'd88: mul1_a = score_2_matrix[4][0];
        // final
        'd74: mul1_a = head_out[0][0];
        'd75: mul1_a = head_out[1][0];
        'd76: mul1_a = head_out[1][0];
        'd79: mul1_a = head_out[2][0];
        'd80: mul1_a = head_out[2][0];
        'd84: mul1_a = head_out[3][0];
        'd85: mul1_a = head_out[3][0];
        'd89: mul1_a = head_out[4][0];
        'd90: mul1_a = head_out[4][0];
        default: mul1_a = 0;
    endcase
end

always @(*) begin
    case (counter)
        'd4:  mul1_b = k_weight_arr[0][0];
        'd8:  mul1_b = k_weight_arr[0][0];
        'd9:  mul1_b = k_weight_arr[1][0];
        'd10: mul1_b = k_weight_arr[1][0];
        'd12: mul1_b = k_weight_arr[0][0];
        'd13: mul1_b = k_weight_arr[2][0];
        'd14: mul1_b = k_weight_arr[2][0];
        'd15: mul1_b = k_weight_arr[1][0];
        'd16: mul1_b = k_weight_arr[0][0];
        'd17: mul1_b = k_weight_arr[3][0];
        'd18: mul1_b = k_weight_arr[3][0];
        'd19: mul1_b = k_weight_arr[2][0];
        'd20: mul1_b = k_weight_arr[0][0];
        'd21: mul1_b = k_weight_arr[3][0];
        'd22: mul1_b = k_weight_arr[1][0];
        'd23: mul1_b = k_weight_arr[1][0];
        'd24: mul1_b = k_weight_arr[2][0];
        'd25: mul1_b = k_weight_arr[2][0];
        'd26: mul1_b = k_weight_arr[3][0];
        'd27: mul1_b = k_weight_arr[3][0];

        'd28: mul1_b = v_weight_arr[0][0];
        'd29: mul1_b = v_weight_arr[0][0];
        'd30: mul1_b = v_weight_arr[0][0];
        'd31: mul1_b = v_weight_arr[0][0];
        'd32: mul1_b = v_weight_arr[0][0];
        'd33: mul1_b = v_weight_arr[1][0];
        'd34: mul1_b = v_weight_arr[1][0];
        'd35: mul1_b = v_weight_arr[1][0];
        'd36: mul1_b = v_weight_arr[1][0];
        'd37: mul1_b = v_weight_arr[1][0];
        'd38: mul1_b = v_weight_arr[2][0];
        'd39: mul1_b = v_weight_arr[2][0];
        'd40: mul1_b = v_weight_arr[2][0];
        'd41: mul1_b = v_weight_arr[2][0];
        'd42: mul1_b = v_weight_arr[2][0];
        'd43: mul1_b = v_weight_arr[3][0];
        'd44: mul1_b = v_weight_arr[3][0];
        'd45: mul1_b = v_weight_arr[3][0];
        'd46: mul1_b = v_weight_arr[3][0];
        'd47: mul1_b = v_weight_arr[3][0];
        // score2
        'd48: mul1_b = k_matrix[0][2];
        'd49: mul1_b = k_matrix[4][2];
        'd50: mul1_b = k_matrix[3][2];
        // head_out 1
        'd51: mul1_b = v_matrix[0][0];
        'd52: mul1_b = v_matrix[0][1];
        'd53: mul1_b = v_matrix[0][0];
        'd54: mul1_b = v_matrix[0][1];
        'd55: mul1_b = v_matrix[0][0];
        'd56: mul1_b = v_matrix[0][1];
        'd57: mul1_b = v_matrix[0][0];
        'd58: mul1_b = v_matrix[0][1];
        'd62: mul1_b = v_matrix[0][0];
        'd63: mul1_b = v_matrix[0][1];
        // head_out 2
        'd67: mul1_b = v_matrix[0][2];
        'd68: mul1_b = v_matrix[0][3];
        'd72: mul1_b = v_matrix[0][2];
        'd73: mul1_b = v_matrix[0][3];
        'd77: mul1_b = v_matrix[0][2];
        'd78: mul1_b = v_matrix[0][3];
        'd82: mul1_b = v_matrix[0][2];
        'd83: mul1_b = v_matrix[0][3];
        'd87: mul1_b = v_matrix[0][2];
        'd88: mul1_b = v_matrix[0][3];
        // final
        'd74: mul1_b = out_weight_arr[3][0];
        'd75: mul1_b = out_weight_arr[1][0];
        'd76: mul1_b = out_weight_arr[3][0];
        'd79: mul1_b = out_weight_arr[0][0];
        'd80: mul1_b = out_weight_arr[2][0];
        'd84: mul1_b = out_weight_arr[0][0];
        'd85: mul1_b = out_weight_arr[2][0];
        'd89: mul1_b = out_weight_arr[0][0];
        'd90: mul1_b = out_weight_arr[2][0];
        default: mul1_b = 0;
    endcase
end

always @(*) begin
    case (counter)
        'd4:  mul2_a = in_str_arr[0][1];
        'd8:  mul2_a = in_str_arr[1][1];
        'd9:  mul2_a = in_str_arr[0][1];
        'd10: mul2_a = in_str_arr[1][1];
        'd12: mul2_a = in_str_arr[2][1];
        'd13: mul2_a = in_str_arr[0][1];
        'd14: mul2_a = in_str_arr[1][1];
        'd15: mul2_a = in_str_arr[2][1];
        'd16: mul2_a = in_str_arr[3][1];
        'd17: mul2_a = in_str_arr[0][1];
        'd18: mul2_a = in_str_arr[1][1];
        'd19: mul2_a = in_str_arr[2][1];
        'd20: mul2_a = in_str_arr[4][1];
        'd21: mul2_a = in_str_arr[2][1];
        'd22: mul2_a = in_str_arr[3][1];
        'd23: mul2_a = in_str_arr[4][1];
        'd24: mul2_a = in_str_arr[3][1];
        'd25: mul2_a = in_str_arr[4][1];
        'd26: mul2_a = in_str_arr[3][1];
        'd27: mul2_a = in_str_arr[4][1];

        'd28: mul2_a = in_str_arr[0][1];
        'd29: mul2_a = in_str_arr[1][1];
        'd30: mul2_a = in_str_arr[2][1];
        'd31: mul2_a = in_str_arr[3][1];
        'd32: mul2_a = in_str_arr[4][1];
        'd33: mul2_a = in_str_arr[0][1];
        'd34: mul2_a = in_str_arr[1][1];
        'd35: mul2_a = in_str_arr[2][1];
        'd36: mul2_a = in_str_arr[3][1];
        'd37: mul2_a = in_str_arr[4][1];
        'd38: mul2_a = in_str_arr[0][1];
        'd39: mul2_a = in_str_arr[1][1];
        'd40: mul2_a = in_str_arr[2][1];
        'd41: mul2_a = in_str_arr[3][1];
        'd42: mul2_a = in_str_arr[4][1];
        'd43: mul2_a = in_str_arr[0][1];
        'd44: mul2_a = in_str_arr[1][1];
        'd45: mul2_a = in_str_arr[2][1];
        'd46: mul2_a = in_str_arr[3][1];
        'd47: mul2_a = in_str_arr[4][1];
        // score2
        'd48: mul2_a = q_matrix[3][3];
        'd49: mul2_a = q_matrix[3][3];
        'd50: mul2_a = q_matrix[4][3];
        // head_out 1
        'd51: mul2_a = score_1_matrix[0][1];
        'd52: mul2_a = score_1_matrix[0][1];
        'd53: mul2_a = score_1_matrix[1][1];
        'd54: mul2_a = score_1_matrix[1][1];
        'd55: mul2_a = score_1_matrix[2][1];
        'd56: mul2_a = score_1_matrix[2][1];
        'd57: mul2_a = score_1_matrix[3][1];
        'd58: mul2_a = score_1_matrix[3][1];
        'd62: mul2_a = score_1_matrix[4][1];
        'd63: mul2_a = score_1_matrix[4][1];
        // head_out 2
        'd67: mul2_a = score_2_matrix[0][1];
        'd68: mul2_a = score_2_matrix[0][1];
        'd72: mul2_a = score_2_matrix[1][1];
        'd73: mul2_a = score_2_matrix[1][1];
        'd77: mul2_a = score_2_matrix[2][1];
        'd78: mul2_a = score_2_matrix[2][1];
        'd82: mul2_a = score_2_matrix[3][1];
        'd83: mul2_a = score_2_matrix[3][1];
        'd87: mul2_a = score_2_matrix[4][1];
        'd88: mul2_a = score_2_matrix[4][1];
        // final
        'd74: mul2_a = head_out[0][1];
        'd75: mul2_a = head_out[1][1];
        'd76: mul2_a = head_out[1][1];
        'd79: mul2_a = head_out[2][1];
        'd80: mul2_a = head_out[2][1];
        'd84: mul2_a = head_out[3][1];
        'd85: mul2_a = head_out[3][1];
        'd89: mul2_a = head_out[4][1];
        'd90: mul2_a = head_out[4][1];
        default: mul2_a = 0;
    endcase
end

always @(*) begin
    case (counter)
        'd4:  mul2_b = k_weight_arr[0][1];
        'd8:  mul2_b = k_weight_arr[0][1];
        'd9:  mul2_b = k_weight_arr[1][1];
        'd10: mul2_b = k_weight_arr[1][1];
        'd12: mul2_b = k_weight_arr[0][1];
        'd13: mul2_b = k_weight_arr[2][1];
        'd14: mul2_b = k_weight_arr[2][1];
        'd15: mul2_b = k_weight_arr[1][1];
        'd16: mul2_b = k_weight_arr[0][1];
        'd17: mul2_b = k_weight_arr[3][1];
        'd18: mul2_b = k_weight_arr[3][1];
        'd19: mul2_b = k_weight_arr[2][1];
        'd20: mul2_b = k_weight_arr[0][1];
        'd21: mul2_b = k_weight_arr[3][1];
        'd22: mul2_b = k_weight_arr[1][1];
        'd23: mul2_b = k_weight_arr[1][1];
        'd24: mul2_b = k_weight_arr[2][1];
        'd25: mul2_b = k_weight_arr[2][1];
        'd26: mul2_b = k_weight_arr[3][1];
        'd27: mul2_b = k_weight_arr[3][1];

        'd28: mul2_b = v_weight_arr[0][1];
        'd29: mul2_b = v_weight_arr[0][1];
        'd30: mul2_b = v_weight_arr[0][1];
        'd31: mul2_b = v_weight_arr[0][1];
        'd32: mul2_b = v_weight_arr[0][1];
        'd33: mul2_b = v_weight_arr[1][1];
        'd34: mul2_b = v_weight_arr[1][1];
        'd35: mul2_b = v_weight_arr[1][1];
        'd36: mul2_b = v_weight_arr[1][1];
        'd37: mul2_b = v_weight_arr[1][1];
        'd38: mul2_b = v_weight_arr[2][1];
        'd39: mul2_b = v_weight_arr[2][1];
        'd40: mul2_b = v_weight_arr[2][1];
        'd41: mul2_b = v_weight_arr[2][1];
        'd42: mul2_b = v_weight_arr[2][1];
        'd43: mul2_b = v_weight_arr[3][1];
        'd44: mul2_b = v_weight_arr[3][1];
        'd45: mul2_b = v_weight_arr[3][1];
        'd46: mul2_b = v_weight_arr[3][1];
        'd47: mul2_b = v_weight_arr[3][1];
        // score2
        'd48: mul2_b = k_matrix[0][3];
        'd49: mul2_b = k_matrix[4][3];
        'd50: mul2_b = k_matrix[3][3];
        // head_out 1
        'd51: mul2_b = v_matrix[1][0];
        'd52: mul2_b = v_matrix[1][1];
        'd53: mul2_b = v_matrix[1][0];
        'd54: mul2_b = v_matrix[1][1];
        'd55: mul2_b = v_matrix[1][0];
        'd56: mul2_b = v_matrix[1][1];
        'd57: mul2_b = v_matrix[1][0];
        'd58: mul2_b = v_matrix[1][1];
        'd62: mul2_b = v_matrix[1][0];
        'd63: mul2_b = v_matrix[1][1];
        // head_out 2
        'd67: mul2_b = v_matrix[1][2];
        'd68: mul2_b = v_matrix[1][3];
        'd72: mul2_b = v_matrix[1][2];
        'd73: mul2_b = v_matrix[1][3];
        'd77: mul2_b = v_matrix[1][2];
        'd78: mul2_b = v_matrix[1][3];
        'd82: mul2_b = v_matrix[1][2];
        'd83: mul2_b = v_matrix[1][3];
        'd87: mul2_b = v_matrix[1][2];
        'd88: mul2_b = v_matrix[1][3];
         // final
        'd74: mul2_b = out_weight_arr[3][1];
        'd75: mul2_b = out_weight_arr[1][1];
        'd76: mul2_b = out_weight_arr[3][1];
        'd79: mul2_b = out_weight_arr[0][1];
        'd80: mul2_b = out_weight_arr[2][1];
        'd84: mul2_b = out_weight_arr[0][1];
        'd85: mul2_b = out_weight_arr[2][1];
        'd89: mul2_b = out_weight_arr[0][1];
        'd90: mul2_b = out_weight_arr[2][1];
        default: mul2_b = 0;
        
    endcase
end

always @(*) begin
    case (counter)
        'd4:  mul3_a = in_str_arr[0][2];
        'd8:  mul3_a = in_str_arr[1][2];
        'd9:  mul3_a = in_str_arr[0][2];
        'd10: mul3_a = in_str_arr[1][2];
        'd12: mul3_a = in_str_arr[2][2];
        'd13: mul3_a = in_str_arr[0][2];
        'd14: mul3_a = in_str_arr[1][2];
        'd15: mul3_a = in_str_arr[2][2];
        'd16: mul3_a = in_str_arr[3][2];
        'd17: mul3_a = in_str_arr[0][2];
        'd18: mul3_a = in_str_arr[1][2];
        'd19: mul3_a = in_str_arr[2][2];
        'd20: mul3_a = in_str_arr[4][2];
        'd21: mul3_a = in_str_arr[2][2];
        'd22: mul3_a = in_str_arr[3][2];
        'd23: mul3_a = in_str_arr[4][2];
        'd24: mul3_a = in_str_arr[3][2];
        'd25: mul3_a = in_str_arr[4][2];
        'd26: mul3_a = in_str_arr[3][2];
        'd27: mul3_a = in_str_arr[4][2];

        'd28: mul3_a = in_str_arr[0][2];
        'd29: mul3_a = in_str_arr[1][2];
        'd30: mul3_a = in_str_arr[2][2];
        'd31: mul3_a = in_str_arr[3][2];
        'd32: mul3_a = in_str_arr[4][2];
        'd33: mul3_a = in_str_arr[0][2];
        'd34: mul3_a = in_str_arr[1][2];
        'd35: mul3_a = in_str_arr[2][2];
        'd36: mul3_a = in_str_arr[3][2];
        'd37: mul3_a = in_str_arr[4][2];
        'd38: mul3_a = in_str_arr[0][2];
        'd39: mul3_a = in_str_arr[1][2];
        'd40: mul3_a = in_str_arr[2][2];
        'd41: mul3_a = in_str_arr[3][2];
        'd42: mul3_a = in_str_arr[4][2];
        'd43: mul3_a = in_str_arr[0][2];
        'd44: mul3_a = in_str_arr[1][2];
        'd45: mul3_a = in_str_arr[2][2];
        'd46: mul3_a = in_str_arr[3][2];
        'd47: mul3_a = in_str_arr[4][2];
        // score2
        'd48: mul3_a = q_matrix[3][2];
        'd49: mul3_a = q_matrix[4][2];
        'd50: mul3_a = q_matrix[4][2];
        // head_out 1
        'd51: mul3_a = score_1_matrix[0][2];
        'd52: mul3_a = score_1_matrix[0][2];
        'd53: mul3_a = score_1_matrix[1][2];
        'd54: mul3_a = score_1_matrix[1][2];
        'd55: mul3_a = score_1_matrix[2][2];
        'd56: mul3_a = score_1_matrix[2][2];
        'd57: mul3_a = score_1_matrix[3][2];
        'd58: mul3_a = score_1_matrix[3][2];
        'd62: mul3_a = score_1_matrix[4][2];
        'd63: mul3_a = score_1_matrix[4][2];
        // head_out 2
        'd67: mul3_a = score_2_matrix[0][2];
        'd68: mul3_a = score_2_matrix[0][2];
        'd72: mul3_a = score_2_matrix[1][2];
        'd73: mul3_a = score_2_matrix[1][2];
        'd77: mul3_a = score_2_matrix[2][2];
        'd78: mul3_a = score_2_matrix[2][2];
        'd82: mul3_a = score_2_matrix[3][2];
        'd83: mul3_a = score_2_matrix[3][2];
        'd87: mul3_a = score_2_matrix[4][2];
        'd88: mul3_a = score_2_matrix[4][2];
        // final
        'd74: mul3_a = head_out[0][2];
        'd75: mul3_a = head_out[1][2];
        'd76: mul3_a = head_out[1][2];
        'd79: mul3_a = head_out[2][2];
        'd80: mul3_a = head_out[2][2];
        'd84: mul3_a = head_out[3][2];
        'd85: mul3_a = head_out[3][2];
        'd89: mul3_a = head_out[4][2];
        'd90: mul3_a = head_out[4][2];
        default: mul3_a = 0;
    endcase
end

always @(*) begin
    case (counter)
        'd4:  mul3_b = k_weight_arr[0][2];
        'd8:  mul3_b = k_weight_arr[0][2];
        'd9:  mul3_b = k_weight_arr[1][2];
        'd10: mul3_b = k_weight_arr[1][2];
        'd12: mul3_b = k_weight_arr[0][2];
        'd13: mul3_b = k_weight_arr[2][2];
        'd14: mul3_b = k_weight_arr[2][2];
        'd15: mul3_b = k_weight_arr[1][2];
        'd16: mul3_b = k_weight_arr[0][2];
        'd17: mul3_b = k_weight_arr[3][2];
        'd18: mul3_b = k_weight_arr[3][2];
        'd19: mul3_b = k_weight_arr[2][2];
        'd20: mul3_b = k_weight_arr[0][2];
        'd21: mul3_b = k_weight_arr[3][2];
        'd22: mul3_b = k_weight_arr[1][2];
        'd23: mul3_b = k_weight_arr[1][2];
        'd24: mul3_b = k_weight_arr[2][2];
        'd25: mul3_b = k_weight_arr[2][2];
        'd26: mul3_b = k_weight_arr[3][2];
        'd27: mul3_b = k_weight_arr[3][2];

        'd28: mul3_b = v_weight_arr[0][2];
        'd29: mul3_b = v_weight_arr[0][2];
        'd30: mul3_b = v_weight_arr[0][2];
        'd31: mul3_b = v_weight_arr[0][2];
        'd32: mul3_b = v_weight_arr[0][2];
        'd33: mul3_b = v_weight_arr[1][2];
        'd34: mul3_b = v_weight_arr[1][2];
        'd35: mul3_b = v_weight_arr[1][2];
        'd36: mul3_b = v_weight_arr[1][2];
        'd37: mul3_b = v_weight_arr[1][2];
        'd38: mul3_b = v_weight_arr[2][2];
        'd39: mul3_b = v_weight_arr[2][2];
        'd40: mul3_b = v_weight_arr[2][2];
        'd41: mul3_b = v_weight_arr[2][2];
        'd42: mul3_b = v_weight_arr[2][2];
        'd43: mul3_b = v_weight_arr[3][2];
        'd44: mul3_b = v_weight_arr[3][2];
        'd45: mul3_b = v_weight_arr[3][2];
        'd46: mul3_b = v_weight_arr[3][2];
        'd47: mul3_b = v_weight_arr[3][2];
        // score2
        'd48: mul3_b = k_matrix[1][2];
        'd49: mul3_b = k_matrix[0][2];
        'd50: mul3_b = k_matrix[4][2];
        // head_out 1
        'd51: mul3_b = v_matrix[2][0];
        'd52: mul3_b = v_matrix[2][1];
        'd53: mul3_b = v_matrix[2][0];
        'd54: mul3_b = v_matrix[2][1];
        'd55: mul3_b = v_matrix[2][0];
        'd56: mul3_b = v_matrix[2][1];
        'd57: mul3_b = v_matrix[2][0];
        'd58: mul3_b = v_matrix[2][1];
        'd62: mul3_b = v_matrix[2][0];
        'd63: mul3_b = v_matrix[2][1];
        // head_out 2
        'd67: mul3_b = v_matrix[2][2];
        'd68: mul3_b = v_matrix[2][3];
        'd72: mul3_b = v_matrix[2][2];
        'd73: mul3_b = v_matrix[2][3];
        'd77: mul3_b = v_matrix[2][2];
        'd78: mul3_b = v_matrix[2][3];
        'd82: mul3_b = v_matrix[2][2];
        'd83: mul3_b = v_matrix[2][3];
        'd87: mul3_b = v_matrix[2][2];
        'd88: mul3_b = v_matrix[2][3];
        // final
        'd74: mul3_b = out_weight_arr[3][2];
        'd75: mul3_b = out_weight_arr[1][2];
        'd76: mul3_b = out_weight_arr[3][2];
        'd79: mul3_b = out_weight_arr[0][2];
        'd80: mul3_b = out_weight_arr[2][2];
        'd84: mul3_b = out_weight_arr[0][2];
        'd85: mul3_b = out_weight_arr[2][2];
        'd89: mul3_b = out_weight_arr[0][2];
        'd90: mul3_b = out_weight_arr[2][2];
        default: mul3_b = 0;
    endcase
end

always @(*) begin
    case (counter)
        'd4:  mul4_a = in_str_arr[0][3];
        'd8:  mul4_a = in_str_arr[1][3];
        'd9:  mul4_a = in_str_arr[0][3];
        'd10: mul4_a = in_str_arr[1][3];
        'd12: mul4_a = in_str_arr[2][3];
        'd13: mul4_a = in_str_arr[0][3];
        'd14: mul4_a = in_str_arr[1][3];
        'd15: mul4_a = in_str_arr[2][3];
        'd16: mul4_a = in_str_arr[3][3];
        'd17: mul4_a = in_str_arr[0][3];
        'd18: mul4_a = in_str_arr[1][3];
        'd19: mul4_a = in_str_arr[2][3];
        'd20: mul4_a = in_str_arr[4][3];
        'd21: mul4_a = in_str_arr[2][3];
        'd22: mul4_a = in_str_arr[3][3];
        'd23: mul4_a = in_str_arr[4][3];
        'd24: mul4_a = in_str_arr[3][3];
        'd25: mul4_a = in_str_arr[4][3];
        'd26: mul4_a = in_str_arr[3][3];
        'd27: mul4_a = in_str_arr[4][3];

        'd28: mul4_a = in_str_arr[0][3];
        'd29: mul4_a = in_str_arr[1][3];
        'd30: mul4_a = in_str_arr[2][3];
        'd31: mul4_a = in_str_arr[3][3];
        'd32: mul4_a = in_str_arr[4][3];
        'd33: mul4_a = in_str_arr[0][3];
        'd34: mul4_a = in_str_arr[1][3];
        'd35: mul4_a = in_str_arr[2][3];
        'd36: mul4_a = in_str_arr[3][3];
        'd37: mul4_a = in_str_arr[4][3];
        'd38: mul4_a = in_str_arr[0][3];
        'd39: mul4_a = in_str_arr[1][3];
        'd40: mul4_a = in_str_arr[2][3];
        'd41: mul4_a = in_str_arr[3][3];
        'd42: mul4_a = in_str_arr[4][3];
        'd43: mul4_a = in_str_arr[0][3];
        'd44: mul4_a = in_str_arr[1][3];
        'd45: mul4_a = in_str_arr[2][3];
        'd46: mul4_a = in_str_arr[3][3];
        'd47: mul4_a = in_str_arr[4][3];
        // score2
        'd48: mul4_a = q_matrix[3][3];
        'd49: mul4_a = q_matrix[4][3];
        'd50: mul4_a = q_matrix[4][3];
        // head_out 1
        'd51: mul4_a = score_1_matrix[0][3];
        'd52: mul4_a = score_1_matrix[0][3];
        'd53: mul4_a = score_1_matrix[1][3];
        'd54: mul4_a = score_1_matrix[1][3];
        'd55: mul4_a = score_1_matrix[2][3];
        'd56: mul4_a = score_1_matrix[2][3];
        'd57: mul4_a = score_1_matrix[3][3];
        'd58: mul4_a = score_1_matrix[3][3];
        'd62: mul4_a = score_1_matrix[4][3];
        'd63: mul4_a = score_1_matrix[4][3];
        // head_out 2
        'd67: mul4_a = score_2_matrix[0][3];
        'd68: mul4_a = score_2_matrix[0][3];
        'd72: mul4_a = score_2_matrix[1][3];
        'd73: mul4_a = score_2_matrix[1][3];
        'd77: mul4_a = score_2_matrix[2][3];
        'd78: mul4_a = score_2_matrix[2][3];
        'd82: mul4_a = score_2_matrix[3][3];
        'd83: mul4_a = score_2_matrix[3][3];
        'd87: mul4_a = score_2_matrix[4][3];
        'd88: mul4_a = score_2_matrix[4][3];
        // final
        'd74: mul4_a = head_out[0][3];
        'd75: mul4_a = head_out[1][3];
        'd76: mul4_a = head_out[1][3];
        'd79: mul4_a = head_out[2][3];
        'd80: mul4_a = head_out[2][3];
        'd84: mul4_a = head_out[3][3];
        'd85: mul4_a = head_out[3][3];
        'd89: mul4_a = head_out[4][3];
        'd90: mul4_a = head_out[4][3];
        default: mul4_a = 0;
    endcase
end

always @(*) begin
    case (counter)
        'd4:  mul4_b = k_weight_arr[0][3];
        'd8:  mul4_b = k_weight_arr[0][3];
        'd9:  mul4_b = k_weight_arr[1][3];
        'd10: mul4_b = k_weight_arr[1][3];
        'd12: mul4_b = k_weight_arr[0][3];
        'd13: mul4_b = k_weight_arr[2][3];
        'd14: mul4_b = k_weight_arr[2][3];
        'd15: mul4_b = k_weight_arr[1][3];
        'd16: mul4_b = k_weight_arr[0][3];
        'd17: mul4_b = k_weight_arr[3][3];
        'd18: mul4_b = k_weight_arr[3][3];
        'd19: mul4_b = k_weight_arr[2][3];
        'd20: mul4_b = k_weight_arr[0][3];
        'd21: mul4_b = k_weight_arr[3][3];
        'd22: mul4_b = k_weight_arr[1][3];
        'd23: mul4_b = k_weight_arr[1][3];
        'd24: mul4_b = k_weight_arr[2][3];
        'd25: mul4_b = k_weight_arr[2][3];
        'd26: mul4_b = k_weight_arr[3][3];
        'd27: mul4_b = k_weight_arr[3][3];

        'd28: mul4_b = v_weight_arr[0][3];
        'd29: mul4_b = v_weight_arr[0][3];
        'd30: mul4_b = v_weight_arr[0][3];
        'd31: mul4_b = v_weight_arr[0][3];
        'd32: mul4_b = v_weight_arr[0][3];
        'd33: mul4_b = v_weight_arr[1][3];
        'd34: mul4_b = v_weight_arr[1][3];
        'd35: mul4_b = v_weight_arr[1][3];
        'd36: mul4_b = v_weight_arr[1][3];
        'd37: mul4_b = v_weight_arr[1][3];
        'd38: mul4_b = v_weight_arr[2][3];
        'd39: mul4_b = v_weight_arr[2][3];
        'd40: mul4_b = v_weight_arr[2][3];
        'd41: mul4_b = v_weight_arr[2][3];
        'd42: mul4_b = v_weight_arr[2][3];
        'd43: mul4_b = v_weight_arr[3][3];
        'd44: mul4_b = v_weight_arr[3][3];
        'd45: mul4_b = v_weight_arr[3][3];
        'd46: mul4_b = v_weight_arr[3][3];
        'd47: mul4_b = v_weight_arr[3][3];
        // score2
        'd48: mul4_b = k_matrix[1][3];
        'd49: mul4_b = k_matrix[0][3];
        'd50: mul4_b = k_matrix[4][3];
        // head_out 1
        'd51: mul4_b = v_matrix[3][0];
        'd52: mul4_b = v_matrix[3][1];
        'd53: mul4_b = v_matrix[3][0];
        'd54: mul4_b = v_matrix[3][1];
        'd55: mul4_b = v_matrix[3][0];
        'd56: mul4_b = v_matrix[3][1];
        'd57: mul4_b = v_matrix[3][0];
        'd58: mul4_b = v_matrix[3][1];
        'd62: mul4_b = v_matrix[3][0];
        'd63: mul4_b = v_matrix[3][1];
        // head_out 2
        'd67: mul4_b = v_matrix[3][2];
        'd68: mul4_b = v_matrix[3][3];
        'd72: mul4_b = v_matrix[3][2];
        'd73: mul4_b = v_matrix[3][3];
        'd77: mul4_b = v_matrix[3][2];
        'd78: mul4_b = v_matrix[3][3];
        'd82: mul4_b = v_matrix[3][2];
        'd83: mul4_b = v_matrix[3][3];
        'd87: mul4_b = v_matrix[3][2];
        'd88: mul4_b = v_matrix[3][3];
        // final
        'd74: mul4_b = out_weight_arr[3][3];
        'd75: mul4_b = out_weight_arr[1][3];
        'd76: mul4_b = out_weight_arr[3][3];
        'd79: mul4_b = out_weight_arr[0][3];
        'd80: mul4_b = out_weight_arr[2][3];
        'd84: mul4_b = out_weight_arr[0][3];
        'd85: mul4_b = out_weight_arr[2][3];
        'd89: mul4_b = out_weight_arr[0][3];
        'd90: mul4_b = out_weight_arr[2][3];
        default: mul4_b = 0;
    endcase
end

always @(*) begin
    add1_a = mul1_res;
    add1_b = mul2_res;
    add2_a = mul3_res;
    add2_b = mul4_res;
    add3_a = add1_res;
    add3_b = add2_res;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (k = 0; k < 5; k = k + 1) begin
            for (m = 0; m < 4; m = m + 1) begin
                k_matrix[k][m] <= 0;
            end
        end
    end
    else if (c_state == IDLE) begin
        for (k = 0; k < 5; k = k + 1) begin
            for (m = 0; m < 4; m = m + 1) begin
                k_matrix[k][m] <= 0;
            end
        end
    end
    else begin
        case (counter)
            'd4: k_matrix[0][0] <= add3_res;
            'd8: k_matrix[1][0] <= add3_res;
            'd9: k_matrix[0][1] <= add3_res;
            'd10:k_matrix[1][1] <= add3_res;
            'd12:k_matrix[2][0] <= add3_res;
            'd13:k_matrix[0][2] <= add3_res;
            'd14:k_matrix[1][2] <= add3_res;
            'd15:k_matrix[2][1] <= add3_res;
            'd16:k_matrix[3][0] <= add3_res;
            'd17:k_matrix[0][3] <= add3_res;
            'd18:k_matrix[1][3] <= add3_res;
            'd19:k_matrix[2][2] <= add3_res;
            'd20:k_matrix[4][0] <= add3_res;
            'd21:k_matrix[2][3] <= add3_res;
            'd22:k_matrix[3][1] <= add3_res;
            'd23:k_matrix[4][1] <= add3_res;
            'd24:k_matrix[3][2] <= add3_res;
            'd25:k_matrix[4][2] <= add3_res;
            'd26:k_matrix[3][3] <= add3_res;
            'd27:k_matrix[4][3] <= add3_res;
            default: begin
                for (k = 0; k < 5; k = k + 1) begin
                    for (m = 0; m < 4; m = m + 1) begin
                        k_matrix[k][m] <= k_matrix[k][m];
                    end
                end
            end
        endcase
    end
end

//=========================================//
//           in_str x q_weight             //
//=========================================//
always @(*) begin
    case (counter)
        'd4:  mul5_a = in_str_arr[0][0];
        'd8:  mul5_a = in_str_arr[1][0];
        'd9:  mul5_a = in_str_arr[0][0];
        'd10: mul5_a = in_str_arr[1][0];
        'd12: mul5_a = in_str_arr[2][0];
        'd13: mul5_a = in_str_arr[0][0];
        'd14: mul5_a = in_str_arr[1][0];
        'd15: mul5_a = in_str_arr[2][0];
        'd16: mul5_a = in_str_arr[3][0];
        'd17: mul5_a = in_str_arr[0][0];
        'd18: mul5_a = in_str_arr[1][0];
        'd19: mul5_a = in_str_arr[2][0];
        'd20: mul5_a = in_str_arr[4][0];
        'd21: mul5_a = in_str_arr[2][0];
        'd22: mul5_a = in_str_arr[3][0];
        'd23: mul5_a = in_str_arr[4][0];
        'd24: mul5_a = in_str_arr[3][0];
        'd25: mul5_a = in_str_arr[4][0];
        'd26: mul5_a = in_str_arr[3][0];
        'd27: mul5_a = in_str_arr[4][0];
        // score1
        'd28: mul5_a = q_matrix[0][0];
        'd29: mul5_a = q_matrix[0][0];
        'd30: mul5_a = q_matrix[0][0];
        'd31: mul5_a = q_matrix[1][0];
        'd32: mul5_a = q_matrix[1][0];
        'd33: mul5_a = q_matrix[2][0];
        'd34: mul5_a = q_matrix[2][0];
        'd35: mul5_a = q_matrix[2][0];
        'd36: mul5_a = q_matrix[3][0];
        'd37: mul5_a = q_matrix[3][0];
        'd38: mul5_a = q_matrix[4][0];
        'd39: mul5_a = q_matrix[4][0];
        'd40: mul5_a = q_matrix[4][0];
        // score2
        'd41: mul5_a = q_matrix[0][2];
        'd42: mul5_a = q_matrix[0][2];
        'd43: mul5_a = q_matrix[1][2];
        'd44: mul5_a = q_matrix[1][2];
        'd45: mul5_a = q_matrix[1][2];
        'd46: mul5_a = q_matrix[2][2];
        'd47: mul5_a = q_matrix[2][2];
        'd48: mul5_a = q_matrix[3][2];
        'd49: mul5_a = q_matrix[4][2];
        // head_out 1
        'd51: mul5_a = score_1_matrix[0][4];
        'd52: mul5_a = score_1_matrix[0][4];
        'd53: mul5_a = score_1_matrix[1][4];
        'd54: mul5_a = score_1_matrix[1][4];
        'd55: mul5_a = score_1_matrix[2][4];
        'd56: mul5_a = score_1_matrix[2][4];
        'd57: mul5_a = score_1_matrix[3][4];
        'd58: mul5_a = score_1_matrix[3][4];
        'd62: mul5_a = score_1_matrix[4][4];
        'd63: mul5_a = score_1_matrix[4][4];
        // head_out 2
        'd67: mul5_a = score_2_matrix[0][4];
        'd68: mul5_a = score_2_matrix[0][4];
        'd72: mul5_a = score_2_matrix[1][4];
        'd73: mul5_a = score_2_matrix[1][4];
        'd77: mul5_a = score_2_matrix[2][4];
        'd78: mul5_a = score_2_matrix[2][4];
        'd82: mul5_a = score_2_matrix[3][4];
        'd83: mul5_a = score_2_matrix[3][4];
        'd87: mul5_a = score_2_matrix[4][4];
        'd88: mul5_a = score_2_matrix[4][4];
        // final res
        'd69: mul5_a = head_out[0][0];
        'd70: mul5_a = head_out[0][0];
        'd71: mul5_a = head_out[0][0];
        'd74: mul5_a = head_out[1][0];
        'd75: mul5_a = head_out[1][0];
        'd79: mul5_a = head_out[2][0];
        'd80: mul5_a = head_out[2][0];
        'd84: mul5_a = head_out[3][0];
        'd85: mul5_a = head_out[3][0];
        'd89: mul5_a = head_out[4][0];
        'd90: mul5_a = head_out[4][0];
        default: mul5_a = 0;
    endcase
end

always @(*) begin
    case (counter)
        'd4:  mul5_b = q_weight_arr[0][0];
        'd8:  mul5_b = q_weight_arr[0][0];
        'd9:  mul5_b = q_weight_arr[1][0];
        'd10: mul5_b = q_weight_arr[1][0];
        'd12: mul5_b = q_weight_arr[0][0];
        'd13: mul5_b = q_weight_arr[2][0];
        'd14: mul5_b = q_weight_arr[2][0];
        'd15: mul5_b = q_weight_arr[1][0];
        'd16: mul5_b = q_weight_arr[0][0];
        'd17: mul5_b = q_weight_arr[3][0];
        'd18: mul5_b = q_weight_arr[3][0];
        'd19: mul5_b = q_weight_arr[2][0];
        'd20: mul5_b = q_weight_arr[0][0];
        'd21: mul5_b = q_weight_arr[3][0];
        'd22: mul5_b = q_weight_arr[1][0];
        'd23: mul5_b = q_weight_arr[1][0];
        'd24: mul5_b = q_weight_arr[2][0];
        'd25: mul5_b = q_weight_arr[2][0];
        'd26: mul5_b = q_weight_arr[3][0];
        'd27: mul5_b = q_weight_arr[3][0];
        // score1
        'd28: mul5_b = k_matrix[0][0];
        'd29: mul5_b = k_matrix[2][0];
        'd30: mul5_b = k_matrix[4][0];
        'd31: mul5_b = k_matrix[1][0];
        'd32: mul5_b = k_matrix[3][0];
        'd33: mul5_b = k_matrix[0][0];
        'd34: mul5_b = k_matrix[2][0];
        'd35: mul5_b = k_matrix[4][0];
        'd36: mul5_b = k_matrix[1][0];
        'd37: mul5_b = k_matrix[3][0];
        'd38: mul5_b = k_matrix[0][0];
        'd39: mul5_b = k_matrix[2][0];
        'd40: mul5_b = k_matrix[4][0];
        // score2
        'd41: mul5_b = k_matrix[1][2];
        'd42: mul5_b = k_matrix[3][2];
        'd43: mul5_b = k_matrix[0][2];
        'd44: mul5_b = k_matrix[2][2];
        'd45: mul5_b = k_matrix[4][2];
        'd46: mul5_b = k_matrix[1][2];
        'd47: mul5_b = k_matrix[3][2];
        'd48: mul5_b = k_matrix[2][2];
        'd49: mul5_b = k_matrix[1][2];
        // head_out 1
        'd51: mul5_b = v_matrix[4][0];
        'd52: mul5_b = v_matrix[4][1];
        'd53: mul5_b = v_matrix[4][0];
        'd54: mul5_b = v_matrix[4][1];
        'd55: mul5_b = v_matrix[4][0];
        'd56: mul5_b = v_matrix[4][1];
        'd57: mul5_b = v_matrix[4][0];
        'd58: mul5_b = v_matrix[4][1];
        'd62: mul5_b = v_matrix[4][0];
        'd63: mul5_b = v_matrix[4][1];
        // head_out 2
        'd67: mul5_b = v_matrix[4][2];
        'd68: mul5_b = v_matrix[4][3];
        'd72: mul5_b = v_matrix[4][2];
        'd73: mul5_b = v_matrix[4][3];
        'd77: mul5_b = v_matrix[4][2];
        'd78: mul5_b = v_matrix[4][3];
        'd82: mul5_b = v_matrix[4][2];
        'd83: mul5_b = v_matrix[4][3]; 
        'd87: mul5_b = v_matrix[4][2];
        'd88: mul5_b = v_matrix[4][3];
        // final res
        'd69: mul5_b = out_weight_arr[0][0];
        'd70: mul5_b = out_weight_arr[1][0];
        'd71: mul5_b = out_weight_arr[2][0];
        'd74: mul5_b = out_weight_arr[0][0];
        'd75: mul5_b = out_weight_arr[2][0];
        'd79: mul5_b = out_weight_arr[1][0];
        'd80: mul5_b = out_weight_arr[3][0];
        'd84: mul5_b = out_weight_arr[1][0];
        'd85: mul5_b = out_weight_arr[3][0];
        'd89: mul5_b = out_weight_arr[1][0];
        'd90: mul5_b = out_weight_arr[3][0];
        default: mul5_b = 0;
    endcase
end

always @(*) begin
    case (counter)
        'd4:  mul6_a = in_str_arr[0][1];
        'd8:  mul6_a = in_str_arr[1][1];
        'd9:  mul6_a = in_str_arr[0][1];
        'd10: mul6_a = in_str_arr[1][1];
        'd12: mul6_a = in_str_arr[2][1];
        'd13: mul6_a = in_str_arr[0][1];
        'd14: mul6_a = in_str_arr[1][1];
        'd15: mul6_a = in_str_arr[2][1];
        'd16: mul6_a = in_str_arr[3][1];
        'd17: mul6_a = in_str_arr[0][1];
        'd18: mul6_a = in_str_arr[1][1];
        'd19: mul6_a = in_str_arr[2][1];
        'd20: mul6_a = in_str_arr[4][1];
        'd21: mul6_a = in_str_arr[2][1];
        'd22: mul6_a = in_str_arr[3][1];
        'd23: mul6_a = in_str_arr[4][1];
        'd24: mul6_a = in_str_arr[3][1];
        'd25: mul6_a = in_str_arr[4][1];
        'd26: mul6_a = in_str_arr[3][1];
        'd27: mul6_a = in_str_arr[4][1];
        // score1
        'd28: mul6_a = q_matrix[0][1];
        'd29: mul6_a = q_matrix[0][1];
        'd30: mul6_a = q_matrix[0][1];
        'd31: mul6_a = q_matrix[1][1];
        'd32: mul6_a = q_matrix[1][1];
        'd33: mul6_a = q_matrix[2][1];
        'd34: mul6_a = q_matrix[2][1];
        'd35: mul6_a = q_matrix[2][1];
        'd36: mul6_a = q_matrix[3][1];
        'd37: mul6_a = q_matrix[3][1];
        'd38: mul6_a = q_matrix[4][1];
        'd39: mul6_a = q_matrix[4][1];
        'd40: mul6_a = q_matrix[4][1];
        // score2
        'd41: mul6_a = q_matrix[0][3];
        'd42: mul6_a = q_matrix[0][3];
        'd43: mul6_a = q_matrix[1][3];
        'd44: mul6_a = q_matrix[1][3];
        'd45: mul6_a = q_matrix[1][3];
        'd46: mul6_a = q_matrix[2][3];
        'd47: mul6_a = q_matrix[2][3];
        'd48: mul6_a = q_matrix[3][3];
        'd49: mul6_a = q_matrix[4][3];
        // final res
        'd69: mul6_a = head_out[0][1];
        'd70: mul6_a = head_out[0][1];
        'd71: mul6_a = head_out[0][1];
        'd74: mul6_a = head_out[1][1];
        'd75: mul6_a = head_out[1][1];
        'd79: mul6_a = head_out[2][1];
        'd80: mul6_a = head_out[2][1];
        'd84: mul6_a = head_out[3][1];
        'd85: mul6_a = head_out[3][1];
        'd89: mul6_a = head_out[4][1];
        'd90: mul6_a = head_out[4][1];
        default: mul6_a = 0;
    endcase
end

always @(*) begin
    case (counter)
        'd4:  mul6_b = q_weight_arr[0][1];
        'd8:  mul6_b = q_weight_arr[0][1];
        'd9:  mul6_b = q_weight_arr[1][1];
        'd10: mul6_b = q_weight_arr[1][1];
        'd12: mul6_b = q_weight_arr[0][1];
        'd13: mul6_b = q_weight_arr[2][1];
        'd14: mul6_b = q_weight_arr[2][1];
        'd15: mul6_b = q_weight_arr[1][1];
        'd16: mul6_b = q_weight_arr[0][1];
        'd17: mul6_b = q_weight_arr[3][1];
        'd18: mul6_b = q_weight_arr[3][1];
        'd19: mul6_b = q_weight_arr[2][1];
        'd20: mul6_b = q_weight_arr[0][1];
        'd21: mul6_b = q_weight_arr[3][1];
        'd22: mul6_b = q_weight_arr[1][1];
        'd23: mul6_b = q_weight_arr[1][1];
        'd24: mul6_b = q_weight_arr[2][1];
        'd25: mul6_b = q_weight_arr[2][1];
        'd26: mul6_b = q_weight_arr[3][1];
        'd27: mul6_b = q_weight_arr[3][1];
        // score1
        'd28: mul6_b = k_matrix[0][1];
        'd29: mul6_b = k_matrix[2][1];
        'd30: mul6_b = k_matrix[4][1];
        'd31: mul6_b = k_matrix[1][1];
        'd32: mul6_b = k_matrix[3][1];
        'd33: mul6_b = k_matrix[0][1];
        'd34: mul6_b = k_matrix[2][1];
        'd35: mul6_b = k_matrix[4][1];
        'd36: mul6_b = k_matrix[1][1];
        'd37: mul6_b = k_matrix[3][1];
        'd38: mul6_b = k_matrix[0][1];
        'd39: mul6_b = k_matrix[2][1];
        'd40: mul6_b = k_matrix[4][1];
        // score2
        'd41: mul6_b = k_matrix[1][3];
        'd42: mul6_b = k_matrix[3][3];
        'd43: mul6_b = k_matrix[0][3];
        'd44: mul6_b = k_matrix[2][3];
        'd45: mul6_b = k_matrix[4][3];
        'd46: mul6_b = k_matrix[1][3];
        'd47: mul6_b = k_matrix[3][3];
        'd48: mul6_b = k_matrix[2][3];
        'd49: mul6_b = k_matrix[1][3];
        // final res
        'd69: mul6_b = out_weight_arr[0][1];
        'd70: mul6_b = out_weight_arr[1][1];
        'd71: mul6_b = out_weight_arr[2][1];
        'd74: mul6_b = out_weight_arr[0][1];
        'd75: mul6_b = out_weight_arr[2][1];
        'd79: mul6_b = out_weight_arr[1][1];
        'd80: mul6_b = out_weight_arr[3][1];
        'd84: mul6_b = out_weight_arr[1][1];
        'd85: mul6_b = out_weight_arr[3][1];
        'd89: mul6_b = out_weight_arr[1][1];
        'd90: mul6_b = out_weight_arr[3][1];
        default: mul6_b = 0;
    endcase
end

always @(*) begin
    case (counter)
        'd4:  mul7_a = in_str_arr[0][2];
        'd8:  mul7_a = in_str_arr[1][2];
        'd9:  mul7_a = in_str_arr[0][2];
        'd10: mul7_a = in_str_arr[1][2];
        'd12: mul7_a = in_str_arr[2][2];
        'd13: mul7_a = in_str_arr[0][2];
        'd14: mul7_a = in_str_arr[1][2];
        'd15: mul7_a = in_str_arr[2][2];
        'd16: mul7_a = in_str_arr[3][2];
        'd17: mul7_a = in_str_arr[0][2];
        'd18: mul7_a = in_str_arr[1][2];
        'd19: mul7_a = in_str_arr[2][2];
        'd20: mul7_a = in_str_arr[4][2];
        'd21: mul7_a = in_str_arr[2][2];
        'd22: mul7_a = in_str_arr[3][2];
        'd23: mul7_a = in_str_arr[4][2];
        'd24: mul7_a = in_str_arr[3][2];
        'd25: mul7_a = in_str_arr[4][2];
        'd26: mul7_a = in_str_arr[3][2];
        'd27: mul7_a = in_str_arr[4][2];
        // score1
        'd28: mul7_a = q_matrix[0][0];
        'd29: mul7_a = q_matrix[0][0];
        'd30: mul7_a = q_matrix[1][0];
        'd31: mul7_a = q_matrix[1][0];
        'd32: mul7_a = q_matrix[1][0];
        'd33: mul7_a = q_matrix[2][0];
        'd34: mul7_a = q_matrix[2][0];
        'd35: mul7_a = q_matrix[3][0];
        'd36: mul7_a = q_matrix[3][0];
        'd37: mul7_a = q_matrix[3][0];
        'd38: mul7_a = q_matrix[4][0];
        'd39: mul7_a = q_matrix[4][0];
        // score2
        'd40: mul7_a = q_matrix[0][2];
        'd41: mul7_a = q_matrix[0][2];
        'd42: mul7_a = q_matrix[0][2];
        'd43: mul7_a = q_matrix[1][2];
        'd44: mul7_a = q_matrix[1][2];
        'd45: mul7_a = q_matrix[2][2];
        'd46: mul7_a = q_matrix[2][2];
        'd47: mul7_a = q_matrix[2][2];
        'd48: mul7_a = q_matrix[3][2];
        'd49: mul7_a = q_matrix[4][2];
        // final res
        'd69: mul7_a = head_out[0][2];
        'd70: mul7_a = head_out[0][2];
        'd71: mul7_a = head_out[0][2];
        'd74: mul7_a = head_out[1][2];
        'd75: mul7_a = head_out[1][2];
        'd79: mul7_a = head_out[2][2];
        'd80: mul7_a = head_out[2][2];
        'd84: mul7_a = head_out[3][2];
        'd85: mul7_a = head_out[3][2];
        'd89: mul7_a = head_out[4][2];
        'd90: mul7_a = head_out[4][2];
        default: mul7_a = 0;
    endcase
end

always @(*) begin
    case (counter)
        'd4:  mul7_b = q_weight_arr[0][2];
        'd8:  mul7_b = q_weight_arr[0][2];
        'd9:  mul7_b = q_weight_arr[1][2];
        'd10: mul7_b = q_weight_arr[1][2];
        'd12: mul7_b = q_weight_arr[0][2];
        'd13: mul7_b = q_weight_arr[2][2];
        'd14: mul7_b = q_weight_arr[2][2];
        'd15: mul7_b = q_weight_arr[1][2];
        'd16: mul7_b = q_weight_arr[0][2];
        'd17: mul7_b = q_weight_arr[3][2];
        'd18: mul7_b = q_weight_arr[3][2];
        'd19: mul7_b = q_weight_arr[2][2];
        'd20: mul7_b = q_weight_arr[0][2];
        'd21: mul7_b = q_weight_arr[3][2];
        'd22: mul7_b = q_weight_arr[1][2];
        'd23: mul7_b = q_weight_arr[1][2];
        'd24: mul7_b = q_weight_arr[2][2];
        'd25: mul7_b = q_weight_arr[2][2];
        'd26: mul7_b = q_weight_arr[3][2];
        'd27: mul7_b = q_weight_arr[3][2];

        'd28: mul7_b = k_matrix[1][0];
        'd29: mul7_b = k_matrix[3][0];
        'd30: mul7_b = k_matrix[0][0];
        'd31: mul7_b = k_matrix[2][0];
        'd32: mul7_b = k_matrix[4][0];
        'd33: mul7_b = k_matrix[1][0];
        'd34: mul7_b = k_matrix[3][0];
        'd35: mul7_b = k_matrix[0][0];
        'd36: mul7_b = k_matrix[2][0];
        'd37: mul7_b = k_matrix[4][0];
        'd38: mul7_b = k_matrix[1][0];
        'd39: mul7_b = k_matrix[3][0];
        // score2
        'd40: mul7_b = k_matrix[0][2];
        'd41: mul7_b = k_matrix[2][2];
        'd42: mul7_b = k_matrix[4][2];
        'd43: mul7_b = k_matrix[1][2];
        'd44: mul7_b = k_matrix[3][2];
        'd45: mul7_b = k_matrix[0][2];
        'd46: mul7_b = k_matrix[2][2];
        'd47: mul7_b = k_matrix[4][2];
        'd48: mul7_b = k_matrix[3][2];
        'd49: mul7_b = k_matrix[2][2];
        // final res
        'd69: mul7_b = out_weight_arr[0][2];
        'd70: mul7_b = out_weight_arr[1][2];
        'd71: mul7_b = out_weight_arr[2][2];
        'd74: mul7_b = out_weight_arr[0][2];
        'd75: mul7_b = out_weight_arr[2][2];
        'd79: mul7_b = out_weight_arr[1][2];
        'd80: mul7_b = out_weight_arr[3][2];
        'd84: mul7_b = out_weight_arr[1][2];
        'd85: mul7_b = out_weight_arr[3][2];
        'd89: mul7_b = out_weight_arr[1][2];
        'd90: mul7_b = out_weight_arr[3][2];
        default: mul7_b = 0;
    endcase
end

always @(*) begin
    case (counter)
        'd4:  mul8_a = in_str_arr[0][3];
        'd8:  mul8_a = in_str_arr[1][3];
        'd9:  mul8_a = in_str_arr[0][3];
        'd10: mul8_a = in_str_arr[1][3];
        'd12: mul8_a = in_str_arr[2][3];
        'd13: mul8_a = in_str_arr[0][3];
        'd14: mul8_a = in_str_arr[1][3];
        'd15: mul8_a = in_str_arr[2][3];
        'd16: mul8_a = in_str_arr[3][3];
        'd17: mul8_a = in_str_arr[0][3];
        'd18: mul8_a = in_str_arr[1][3];
        'd19: mul8_a = in_str_arr[2][3];
        'd20: mul8_a = in_str_arr[4][3];
        'd21: mul8_a = in_str_arr[2][3];
        'd22: mul8_a = in_str_arr[3][3];
        'd23: mul8_a = in_str_arr[4][3];
        'd24: mul8_a = in_str_arr[3][3];
        'd25: mul8_a = in_str_arr[4][3];
        'd26: mul8_a = in_str_arr[3][3];
        'd27: mul8_a = in_str_arr[4][3];

        'd28: mul8_a = q_matrix[0][1];
        'd29: mul8_a = q_matrix[0][1];
        'd30: mul8_a = q_matrix[1][1];
        'd31: mul8_a = q_matrix[1][1];
        'd32: mul8_a = q_matrix[1][1];
        'd33: mul8_a = q_matrix[2][1];
        'd34: mul8_a = q_matrix[2][1];
        'd35: mul8_a = q_matrix[3][1];
        'd36: mul8_a = q_matrix[3][1];
        'd37: mul8_a = q_matrix[3][1];
        'd38: mul8_a = q_matrix[4][1];
        'd39: mul8_a = q_matrix[4][1];
        // score2
        'd40: mul8_a = q_matrix[0][3];
        'd41: mul8_a = q_matrix[0][3];
        'd42: mul8_a = q_matrix[0][3];
        'd43: mul8_a = q_matrix[1][3];
        'd44: mul8_a = q_matrix[1][3];
        'd45: mul8_a = q_matrix[2][3];
        'd46: mul8_a = q_matrix[2][3];
        'd47: mul8_a = q_matrix[2][3];
        'd48: mul8_a = q_matrix[3][3];
        'd49: mul8_a = q_matrix[4][3];
        // final res
        'd69: mul8_a = head_out[0][3];
        'd70: mul8_a = head_out[0][3];
        'd71: mul8_a = head_out[0][3];
        'd74: mul8_a = head_out[1][3];
        'd75: mul8_a = head_out[1][3];
        'd79: mul8_a = head_out[2][3];
        'd80: mul8_a = head_out[2][3];
        'd84: mul8_a = head_out[3][3];
        'd85: mul8_a = head_out[3][3];
        'd89: mul8_a = head_out[4][3];
        'd90: mul8_a = head_out[4][3];
        default: mul8_a = 0;
    endcase
end

always @(*) begin
    case (counter)
        'd4:  mul8_b = q_weight_arr[0][3];
        'd8:  mul8_b = q_weight_arr[0][3];
        'd9:  mul8_b = q_weight_arr[1][3];
        'd10: mul8_b = q_weight_arr[1][3];
        'd12: mul8_b = q_weight_arr[0][3];
        'd13: mul8_b = q_weight_arr[2][3];
        'd14: mul8_b = q_weight_arr[2][3];
        'd15: mul8_b = q_weight_arr[1][3];
        'd16: mul8_b = q_weight_arr[0][3];
        'd17: mul8_b = q_weight_arr[3][3];
        'd18: mul8_b = q_weight_arr[3][3];
        'd19: mul8_b = q_weight_arr[2][3];
        'd20: mul8_b = q_weight_arr[0][3];
        'd21: mul8_b = q_weight_arr[3][3];
        'd22: mul8_b = q_weight_arr[1][3];
        'd23: mul8_b = q_weight_arr[1][3];
        'd24: mul8_b = q_weight_arr[2][3];
        'd25: mul8_b = q_weight_arr[2][3];
        'd26: mul8_b = q_weight_arr[3][3];
        'd27: mul8_b = q_weight_arr[3][3];

        'd28: mul8_b = k_matrix[1][1];
        'd29: mul8_b = k_matrix[3][1];
        'd30: mul8_b = k_matrix[0][1];
        'd31: mul8_b = k_matrix[2][1];
        'd32: mul8_b = k_matrix[4][1];
        'd33: mul8_b = k_matrix[1][1];
        'd34: mul8_b = k_matrix[3][1];
        'd35: mul8_b = k_matrix[0][1];
        'd36: mul8_b = k_matrix[2][1];
        'd37: mul8_b = k_matrix[4][1];
        'd38: mul8_b = k_matrix[1][1];
        'd39: mul8_b = k_matrix[3][1];
        // score2
        'd40: mul8_b = k_matrix[0][3];
        'd41: mul8_b = k_matrix[2][3];
        'd42: mul8_b = k_matrix[4][3];
        'd43: mul8_b = k_matrix[1][3];
        'd44: mul8_b = k_matrix[3][3];
        'd45: mul8_b = k_matrix[0][3];
        'd46: mul8_b = k_matrix[2][3];
        'd47: mul8_b = k_matrix[4][3];
        'd48: mul8_b = k_matrix[3][3];
        'd49: mul8_b = k_matrix[2][3];
        // final res
        'd69: mul8_b = out_weight_arr[0][3];
        'd70: mul8_b = out_weight_arr[1][3];
        'd71: mul8_b = out_weight_arr[2][3];
        'd74: mul8_b = out_weight_arr[0][3];
        'd75: mul8_b = out_weight_arr[2][3];
        'd79: mul8_b = out_weight_arr[1][3];
        'd80: mul8_b = out_weight_arr[3][3];
        'd84: mul8_b = out_weight_arr[1][3];
        'd85: mul8_b = out_weight_arr[3][3];
        'd89: mul8_b = out_weight_arr[1][3];
        'd90: mul8_b = out_weight_arr[3][3];
        default: mul8_b = 0;
    endcase
end

always @(*) begin
    add6_a = add4_res;
    add6_b = add5_res;
end

always @(*) begin
    if (counter > 50 && counter < 69) begin
        add4_a = add1_res;
        add4_b = add2_res;
    end
    else if ((counter == 72) || (counter == 73) || (counter == 77) || (counter == 78) || (counter == 82) || (counter == 83) || (counter == 87) || (counter == 88)) begin
        add4_a = add1_res;
        add4_b = add2_res;
    end
    else begin
        add4_a = mul5_res; 
        add4_b = mul6_res;
    end
end

always @(*) begin
    if (counter > 50 && counter < 69) begin
        add5_a = add4_res;
        add5_b = mul5_res;
    end
    else if ((counter == 72) || (counter == 73) || (counter == 77) || (counter == 78) || (counter == 82) || (counter == 83) || (counter == 87) || (counter == 88)) begin
        add5_a = add4_res;
        add5_b = mul5_res;
    end
    else begin
        add5_a = mul7_res; 
        add5_b = mul8_res;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (k = 0; k < 5; k = k + 1) begin
            for (m = 0; m < 4; m = m + 1) begin
                q_matrix[k][m] <= 0;
            end
        end
    end
    else if (c_state == IDLE) begin
        for (k = 0; k < 5; k = k + 1) begin
            for (m = 0; m < 4; m = m + 1) begin
                q_matrix[k][m] <= 0;
            end
        end
    end
    else begin
        case (counter)
            'd4: q_matrix[0][0] <= add6_res;
            'd8: q_matrix[1][0] <= add6_res;
            'd9: q_matrix[0][1] <= add6_res;
            'd10:q_matrix[1][1] <= add6_res;
            'd12:q_matrix[2][0] <= add6_res;
            'd13:q_matrix[0][2] <= add6_res;
            'd14:q_matrix[1][2] <= add6_res;
            'd15:q_matrix[2][1] <= add6_res;
            'd16:q_matrix[3][0] <= add6_res;
            'd17:q_matrix[0][3] <= add6_res;
            'd18:q_matrix[1][3] <= add6_res;
            'd19:q_matrix[2][2] <= add6_res;
            'd20:q_matrix[4][0] <= add6_res;
            'd21:q_matrix[2][3] <= add6_res;
            'd22:q_matrix[3][1] <= add6_res;
            'd23:q_matrix[4][1] <= add6_res;
            'd24:q_matrix[3][2] <= add6_res;
            'd25:q_matrix[4][2] <= add6_res;
            'd26:q_matrix[3][3] <= add6_res;
            'd27:q_matrix[4][3] <= add6_res;
            default: begin
                for (k = 0; k < 5; k = k + 1) begin
                    for (m = 0; m < 4; m = m + 1) begin
                        q_matrix[k][m] <= q_matrix[k][m];
                    end
                end
            end
        endcase
    end
end

//=========================================//
//           in_str x v_weight             //
//=========================================//
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (k = 0; k < 5; k = k + 1) begin
            for (m = 0; m < 4; m = m + 1) begin
                v_matrix[k][m] <= 0;
            end
        end
    end
    else if (c_state == IDLE) begin
        for (k = 0; k < 5; k = k + 1) begin
            for (m = 0; m < 4; m = m + 1) begin
                v_matrix[k][m] <= 0;
            end
        end
    end
    else begin
        case (counter)
            'd28: v_matrix[0][0] <= add3_res;
            'd29: v_matrix[1][0] <= add3_res;
            'd30: v_matrix[2][0] <= add3_res;
            'd31: v_matrix[3][0] <= add3_res;
            'd32: v_matrix[4][0] <= add3_res;
            'd33: v_matrix[0][1] <= add3_res;
            'd34: v_matrix[1][1] <= add3_res;
            'd35: v_matrix[2][1] <= add3_res;
            'd36: v_matrix[3][1] <= add3_res;
            'd37: v_matrix[4][1] <= add3_res;
            'd38: v_matrix[0][2] <= add3_res;
            'd39: v_matrix[1][2] <= add3_res;
            'd40: v_matrix[2][2] <= add3_res;
            'd41: v_matrix[3][2] <= add3_res;
            'd42: v_matrix[4][2] <= add3_res;
            'd43: v_matrix[0][3] <= add3_res;
            'd44: v_matrix[1][3] <= add3_res;
            'd45: v_matrix[2][3] <= add3_res;
            'd46: v_matrix[3][3] <= add3_res;
            'd47: v_matrix[4][3] <= add3_res;
            default: begin
                for (k = 0; k < 5; k = k + 1) begin
                    for (m = 0; m < 4; m = m + 1) begin
                        v_matrix[k][m] <= v_matrix[k][m];
                    end
                end
            end
        endcase
    end
end

//=========================================//
//                score_1                  //
//=========================================//
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (k = 0; k < 5; k = k + 1) begin
            for (m = 0; m < 5; m = m + 1) begin
                score_1_matrix[k][m] <= 0;
            end
        end
    end
    else if (c_state == IDLE) begin
        for (k = 0; k < 5; k = k + 1) begin
            for (m = 0; m < 5; m = m + 1) begin
                score_1_matrix[k][m] <= 0;
            end
        end
    end
    else begin
        case (counter)
            'd28: begin
                score_1_matrix[0][0] <= add4_res;
                score_1_matrix[0][1] <= add5_res;
            end
            'd29: begin
                score_1_matrix[0][2] <= add4_res;
                score_1_matrix[0][3] <= add5_res;
            end
            'd30: begin
                score_1_matrix[0][4] <= add4_res;
                score_1_matrix[1][0] <= add5_res;
                score_1_matrix[0][0] <= exp1_res;
                // if (row == 0 && col == 1) 
                //     score_1_matrix[0][0] <= exp1_res;
            end
            'd31: begin
                score_1_matrix[1][1] <= add4_res;
                score_1_matrix[1][2] <= add5_res;
                score_1_matrix[0][1] <= exp1_res;
                // if (row == 0 && col == 2) 
                //     score_1_matrix[0][1] <= exp1_res;
            end
            'd32: begin
                score_1_matrix[1][3] <= add4_res;
                score_1_matrix[1][4] <= add5_res;
                score_1_matrix[0][2] <= exp1_res;
                // if (row == 0 && col == 3) 
                //     score_1_matrix[0][2] <= exp1_res;
            end
            'd33: begin
                score_1_matrix[2][0] <= add4_res;
                score_1_matrix[2][1] <= add5_res;
                score_1_matrix[0][3] <= exp1_res;
                // if (row == 0 && col == 4) 
                //     score_1_matrix[0][3] <= exp1_res;
            end
            'd34: begin
                score_1_matrix[2][2] <= add4_res;
                score_1_matrix[2][3] <= add5_res;
                score_1_matrix[0][4] <= exp1_res;
                // if (row == 1 && col == 0) 
                //     score_1_matrix[0][4] <= exp1_res;
            end
            'd35: begin
                score_1_matrix[2][4] <= add4_res;
                score_1_matrix[3][0] <= add5_res;
                score_1_matrix[1][0] <= exp1_res;
                // if (row == 1 && col == 1) 
                //     score_1_matrix[1][0] <= exp1_res;
            end
            'd36: begin
                score_1_matrix[3][1] <= add4_res;
                score_1_matrix[3][2] <= add5_res;
                score_1_matrix[1][1] <= exp1_res;
                // if (row == 1 && col == 2) 
                //     score_1_matrix[1][1] <= exp1_res;
            end
            'd37: begin
                score_1_matrix[3][3] <= add4_res;
                score_1_matrix[3][4] <= add5_res;
                score_1_matrix[1][2] <= exp1_res;
                score_1_matrix[0][0] <= div2_res;
                // if (row == 1 && col == 3) 
                //     score_1_matrix[1][2] <= exp1_res;
            end
            'd38: begin
                score_1_matrix[4][0] <= add4_res;
                score_1_matrix[4][1] <= add5_res;
                score_1_matrix[1][3] <= exp1_res;
                score_1_matrix[0][1] <= div2_res;
                // if (row == 1 && col == 4) 
                //     score_1_matrix[1][3] <= exp1_res;
            end
            'd39: begin
                score_1_matrix[4][2] <= add4_res;
                score_1_matrix[4][3] <= add5_res;
                score_1_matrix[1][4] <= exp1_res;
                score_1_matrix[0][2] <= div2_res;
                // if (row == 2 && col == 0) 
                //     score_1_matrix[1][4] <= exp1_res;
            end
            'd40: begin
                score_1_matrix[4][4] <= add4_res;
                score_1_matrix[2][0] <= exp1_res;
                score_1_matrix[0][3] <= div2_res;
                // if (row == 2 && col == 1) 
                //     score_1_matrix[2][0] <= exp1_res;
            end
            'd41:begin
                score_1_matrix[2][1] <= exp1_res;
                score_1_matrix[0][4] <= div2_res;
            end
            'd42:begin
                score_1_matrix[2][2] <= exp1_res;
                score_1_matrix[1][0] <= div2_res;
            end
            'd43:begin
                score_1_matrix[2][3] <= exp1_res;
                score_1_matrix[1][1] <= div2_res;
            end
            'd44:begin
                score_1_matrix[2][4] <= exp1_res;
                score_1_matrix[1][2] <= div2_res;
            end
            'd45:begin
                score_1_matrix[3][0] <= exp1_res;
                score_1_matrix[1][3] <= div2_res;
            end
            'd46:begin
                score_1_matrix[3][1] <= exp1_res;
                score_1_matrix[1][4] <= div2_res;
            end
            'd47:begin
                score_1_matrix[3][2] <= exp1_res;
                score_1_matrix[2][0] <= div2_res;
            end
            'd48:begin
                score_1_matrix[3][3] <= exp1_res;
                score_1_matrix[2][1] <= div2_res;
            end
            'd49:begin
                score_1_matrix[3][4] <= exp1_res;
                score_1_matrix[2][2] <= div2_res;
            end
            'd50:begin
                score_1_matrix[4][0] <= exp1_res;
                score_1_matrix[2][3] <= div2_res;
            end
            'd51:begin
                score_1_matrix[4][1] <= exp1_res;
                score_1_matrix[2][4] <= div2_res;
            end
            'd52:begin
                score_1_matrix[4][2] <= exp1_res;
                score_1_matrix[3][0] <= div2_res;
            end
            'd53:begin
                score_1_matrix[4][3] <= exp1_res;
                score_1_matrix[3][1] <= div2_res;
            end
            'd54:begin
                score_1_matrix[4][4] <= exp1_res;
                score_1_matrix[3][2] <= div2_res;
            end
            'd55:begin
                score_1_matrix[3][3] <= div2_res;
            end
            'd56:begin
                score_1_matrix[3][4] <= div2_res;
            end
            'd57:begin
                score_1_matrix[4][0] <= div2_res;
            end
            'd58:begin
                score_1_matrix[4][1] <= div2_res;
            end
            'd59:begin
                score_1_matrix[4][2] <= div2_res;
            end
            'd60:begin
                score_1_matrix[4][3] <= div2_res;
            end
            'd61:begin
                score_1_matrix[4][4] <= div2_res;
            end
            default: begin
                for (k = 0; k < 5; k = k + 1) begin
                    for (m = 0; m < 5; m = m + 1) begin
                        score_1_matrix[k][m] <= score_1_matrix[k][m];
                    end
                end
            end 
        endcase
    end
end

//=========================================//
//                score_2                  //
//=========================================//
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (k = 0; k < 5; k = k + 1) begin
            for (m = 0; m < 5; m = m + 1) begin
                score_2_matrix[k][m] <= 0;
            end
        end
    end
    else if (c_state == IDLE) begin
        for (k = 0; k < 5; k = k + 1) begin
            for (m = 0; m < 5; m = m + 1) begin
                score_2_matrix[k][m] <= 0;
            end
        end
    end
    else begin
        case (counter)
            'd40: begin
                score_2_matrix[0][0] <= add5_res;
            end
            'd41: begin
                score_2_matrix[0][1] <= add4_res;
                score_2_matrix[0][2] <= add5_res;
            end
            'd42: begin
                score_2_matrix[0][3] <= add4_res;
                score_2_matrix[0][4] <= add5_res;
            end
            'd43: begin
                score_2_matrix[1][0] <= add4_res;
                score_2_matrix[1][1] <= add5_res;
            end
            'd44: begin
                score_2_matrix[1][2] <= add4_res;
                score_2_matrix[1][3] <= add5_res;
            end
            'd45: begin
                score_2_matrix[1][4] <= add4_res;
                score_2_matrix[2][0] <= add5_res;
            end
            'd46: begin
                score_2_matrix[2][1] <= add4_res;
                score_2_matrix[2][2] <= add5_res;
            end
            'd47: begin
                score_2_matrix[2][3] <= add4_res;
                score_2_matrix[2][4] <= add5_res;
            end
            'd48: begin
                score_2_matrix[3][0] <= add1_res;
                score_2_matrix[3][1] <= add2_res;
                score_2_matrix[3][2] <= add4_res;
                score_2_matrix[3][3] <= add5_res;
            end
            'd49: begin
                score_2_matrix[3][4] <= add1_res;
                score_2_matrix[4][0] <= add2_res;
                score_2_matrix[4][1] <= add4_res;
                score_2_matrix[4][2] <= add5_res;
            end
            'd50: begin
                score_2_matrix[4][3] <= add1_res;
                score_2_matrix[4][4] <= add2_res;
            end
            'd55:begin
                score_2_matrix[0][0] <= exp1_res;
            end
            'd56:begin
                score_2_matrix[0][1] <= exp1_res;
            end
            'd57:begin
                score_2_matrix[0][2] <= exp1_res;
            end
            'd58:begin
                score_2_matrix[0][3] <= exp1_res;
            end
            'd59:begin
                score_2_matrix[0][4] <= exp1_res;
            end
            'd60:begin
                score_2_matrix[1][0] <= exp1_res;
            end
            'd61:begin
                score_2_matrix[1][1] <= exp1_res;
            end
            'd62:begin
                score_2_matrix[1][2] <= exp1_res;
                score_2_matrix[0][0] <= div2_res;
            end
            'd63:begin
                score_2_matrix[1][3] <= exp1_res;
                score_2_matrix[0][1] <= div2_res;
            end
            'd64:begin
                score_2_matrix[1][4] <= exp1_res;
                score_2_matrix[0][2] <= div2_res;
            end
            'd65:begin
                score_2_matrix[2][0] <= exp1_res;
                score_2_matrix[0][3] <= div2_res;
            end
            'd66:begin
                score_2_matrix[2][1] <= exp1_res;
                score_2_matrix[0][4] <= div2_res;
            end
            'd67:begin
                score_2_matrix[2][2] <= exp1_res;
                score_2_matrix[1][0] <= div2_res;
            end
            'd68:begin
                score_2_matrix[2][3] <= exp1_res;
                score_2_matrix[1][1] <= div2_res;
            end
            'd69:begin
                score_2_matrix[2][4] <= exp1_res;
                score_2_matrix[1][2] <= div2_res;
            end
            'd70:begin
                score_2_matrix[3][0] <= exp1_res;
                score_2_matrix[1][3] <= div2_res;
            end
            'd71:begin
                score_2_matrix[3][1] <= exp1_res;
                score_2_matrix[1][4] <= div2_res;
            end
            'd72:begin
                score_2_matrix[3][2] <= exp1_res;
                score_2_matrix[2][0] <= div2_res;
            end
            'd73:begin
                score_2_matrix[3][3] <= exp1_res;
                score_2_matrix[2][1] <= div2_res;
            end
            'd74:begin
                score_2_matrix[3][4] <= exp1_res;
                score_2_matrix[2][2] <= div2_res;
            end
            'd75:begin
                score_2_matrix[4][0] <= exp1_res;
                score_2_matrix[2][3] <= div2_res;
            end
            'd76:begin
                score_2_matrix[4][1] <= exp1_res;
                score_2_matrix[2][4] <= div2_res;
            end
            'd77:begin
                score_2_matrix[4][2] <= exp1_res;
                score_2_matrix[3][0] <= div2_res;
            end
            'd78:begin
                score_2_matrix[4][3] <= exp1_res;
                score_2_matrix[3][1] <= div2_res;
            end
            'd79:begin
                score_2_matrix[4][4] <= exp1_res;
                score_2_matrix[3][2] <= div2_res;
            end
            'd80:begin
                score_2_matrix[3][3] <= div2_res;
            end
            'd81:begin
                score_2_matrix[3][4] <= div2_res;
            end
            'd82:begin
                score_2_matrix[4][0] <= div2_res;
            end
            'd83:begin
                score_2_matrix[4][1] <= div2_res;
            end
            'd84:begin
                score_2_matrix[4][2] <= div2_res;
            end
            'd85:begin
                score_2_matrix[4][3] <= div2_res;
            end
            'd86:begin
                score_2_matrix[4][4] <= div2_res;
            end

            default: begin
                for (k = 0; k < 5; k = k + 1) begin
                    for (m = 0; m < 5; m = m + 1) begin
                        score_2_matrix[k][m] <= score_2_matrix[k][m];
                    end
                end
            end 
        endcase
    end
end

//=========================================//
//                DIVIDER                  //
//=========================================//
always @(*) begin
    if (counter_div_en) begin
        if (div_score2)
            div1_a = score_2_matrix[row][col];
        else
            div1_a = score_1_matrix[row][col];
    end
    else
        div1_a = 0;
end
// always @(*) begin
//     div1_b = sqare_root_2;
// end

//=========================================//
//                   EXP                   //
//=========================================//
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        exp1_in <= 0;
    else if (c_state == IDLE)
        exp1_in <= 0;
    else begin
        if (counter_div_en)
            exp1_in <= div1_res;
        else
            exp1_in <= 0; 
    end
end
//=========================================//
//                accumlation              //
//=========================================//
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        add7_a <= 0;
    end
    else if (c_state == IDLE)
        add7_a <= 0;
    else 
        add7_a <= exp1_res;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        add7_b <= 0;
    else if (c_state == IDLE)
        add7_b <= 0;
    else begin
        if (col == 1)
            add7_b <= 0;
        else
            add7_b <= add7_res; 
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        softmax_row0 <= 0;
    else if (c_state == IDLE)
        softmax_row0 <= 0;
    else if (row == 1 && col == 1)
        softmax_row0 <= add7_res;
    else
        softmax_row0 <= softmax_row0;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        softmax_row1 <= 0;
    else if (c_state == IDLE)
        softmax_row1 <= 0;
    else if (row == 2 && col == 1)
        softmax_row1 <= add7_res;
    else
        softmax_row1 <= softmax_row1;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        softmax_row2 <= 0;
    else if (c_state == IDLE)
        softmax_row2 <= 0;
    else if (row == 3 && col == 1)
        softmax_row2 <= add7_res;
    else
        softmax_row2 <= softmax_row2;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        softmax_row3 <= 0;
    else if (c_state == IDLE)
        softmax_row3 <= 0;
    else if (row == 4 && col == 1)
        softmax_row3 <= add7_res;
    else
        softmax_row3 <= softmax_row3;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        softmax_row4 <= 0;
    else if (c_state == IDLE)
        softmax_row4 <= 0;
    else if (row == 0 && col == 1 && div_score2)
        softmax_row4 <= add7_res;
    else
        softmax_row4 <= softmax_row4;
end
//=========================================//
//            DIVIDER_second               //
//=========================================//
always @(*) begin
    if (softmax_score2_en) begin
        case ({row, col})
            6'b001_011: begin
                div2_a = score_2_matrix[0][0];
                div2_b = softmax_row0;
            end
            6'b001_100: begin
                div2_a = score_2_matrix[0][1];
                div2_b = softmax_row0;
            end
            6'b010_000: begin
                div2_a = score_2_matrix[0][2];
                div2_b = softmax_row0;
            end
            6'b010_001: begin
                div2_a = score_2_matrix[0][3];
                div2_b = softmax_row0;
            end
            6'b010_010: begin
                div2_a = score_2_matrix[0][4];
                div2_b = softmax_row0;
            end
            6'b010_011: begin
                div2_a = score_2_matrix[1][0];
                div2_b = softmax_row1;
            end
            6'b010_100: begin
                div2_a = score_2_matrix[1][1];
                div2_b = softmax_row1;
            end
            6'b011_000: begin
                div2_a = score_2_matrix[1][2];
                div2_b = softmax_row1;
            end
            6'b011_001: begin
                div2_a = score_2_matrix[1][3];
                div2_b = softmax_row1;
            end
            6'b011_010: begin
                div2_a = score_2_matrix[1][4];
                div2_b = softmax_row1;
            end
            6'b011_011: begin
                div2_a = score_2_matrix[2][0];
                div2_b = softmax_row2;
            end
            6'b011_100: begin
                div2_a = score_2_matrix[2][1];
                div2_b = softmax_row2;
            end
            6'b100_000: begin
                div2_a = score_2_matrix[2][2];
                div2_b = softmax_row2;
            end
            6'b100_001: begin
                div2_a = score_2_matrix[2][3];
                div2_b = softmax_row2;
            end
            6'b100_010: begin
                div2_a = score_2_matrix[2][4];
                div2_b = softmax_row2;
            end
            6'b100_011: begin
                div2_a = score_2_matrix[3][0];
                div2_b = softmax_row3;
            end
            6'b100_100: begin
                div2_a = score_2_matrix[3][1];
                div2_b = softmax_row3;
            end
            6'b000_000: begin
                div2_a = score_2_matrix[3][2];
                div2_b = softmax_row3;
            end
            6'b000_001: begin
                div2_a = score_2_matrix[3][3];
                div2_b = softmax_row3;
            end
            6'b000_010: begin
                div2_a = score_2_matrix[3][4];
                div2_b = softmax_row3;
            end
            6'b000_011: begin
                div2_a = score_2_matrix[4][0];
                div2_b = softmax_row4;
            end
            6'b000_100: begin
                div2_a = score_2_matrix[4][1];
                div2_b = softmax_row4;
            end
            6'b001_000: begin
                div2_a = score_2_matrix[4][2];
                div2_b = softmax_row4;
            end
            6'b001_001: begin
                div2_a = score_2_matrix[4][3];
                div2_b = softmax_row4;
            end
            6'b001_010: begin
                div2_a = score_2_matrix[4][4];
                div2_b = softmax_row4;
            end
            default: begin
                div2_a = 0;
                div2_b = 0;
            end
        endcase
        
    end
    else begin
        case ({row, col})
            6'b001_011: begin
                div2_a = score_1_matrix[0][0];
                div2_b = softmax_row0;
            end
            6'b001_100: begin
                div2_a = score_1_matrix[0][1];
                div2_b = softmax_row0;
            end
            6'b010_000: begin
                div2_a = score_1_matrix[0][2];
                div2_b = softmax_row0;
            end
            6'b010_001: begin
                div2_a = score_1_matrix[0][3];
                div2_b = softmax_row0;
            end
            6'b010_010: begin
                div2_a = score_1_matrix[0][4];
                div2_b = softmax_row0;
            end
            6'b010_011: begin
                div2_a = score_1_matrix[1][0];
                div2_b = softmax_row1;
            end
            6'b010_100: begin
                div2_a = score_1_matrix[1][1];
                div2_b = softmax_row1;
            end
            6'b011_000: begin
                div2_a = score_1_matrix[1][2];
                div2_b = softmax_row1;
            end
            6'b011_001: begin
                div2_a = score_1_matrix[1][3];
                div2_b = softmax_row1;
            end
            6'b011_010: begin
                div2_a = score_1_matrix[1][4];
                div2_b = softmax_row1;
            end
            6'b011_011: begin
                div2_a = score_1_matrix[2][0];
                div2_b = softmax_row2;
            end
            6'b011_100: begin
                div2_a = score_1_matrix[2][1];
                div2_b = softmax_row2;
            end
            6'b100_000: begin
                div2_a = score_1_matrix[2][2];
                div2_b = softmax_row2;
            end
            6'b100_001: begin
                div2_a = score_1_matrix[2][3];
                div2_b = softmax_row2;
            end
            6'b100_010: begin
                div2_a = score_1_matrix[2][4];
                div2_b = softmax_row2;
            end
            6'b100_011: begin
                div2_a = score_1_matrix[3][0];
                div2_b = softmax_row3;
            end
            6'b100_100: begin
                div2_a = score_1_matrix[3][1];
                div2_b = softmax_row3;
            end
            6'b000_000: begin
                div2_a = score_1_matrix[3][2];
                div2_b = softmax_row3;
            end
            6'b000_001: begin
                div2_a = score_1_matrix[3][3];
                div2_b = softmax_row3;
            end
            6'b000_010: begin
                div2_a = score_1_matrix[3][4];
                div2_b = softmax_row3;
            end
            6'b000_011: begin
                div2_a = score_1_matrix[4][0];
                div2_b = softmax_row4;
            end
            6'b000_100: begin
                div2_a = score_1_matrix[4][1];
                div2_b = softmax_row4;
            end
            6'b001_000: begin
                div2_a = score_1_matrix[4][2];
                div2_b = softmax_row4;
            end
            6'b001_001: begin
                div2_a = score_1_matrix[4][3];
                div2_b = softmax_row4;
            end
            6'b001_010: begin
                div2_a = score_1_matrix[4][4];
                div2_b = softmax_row4;
            end
            default: begin
                div2_a = 0;
                div2_b = 0;
            end
        endcase
    end
end
//=========================================//
//                  HEAD_OUT               //
//=========================================//
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (k = 0; k < 5; k = k + 1) begin
            for (m = 0; m < 2; m = m + 1) begin
                head_out[k][m] <= 0;
            end
        end
    end
    else if (c_state == IDLE) begin
        for (k = 0; k < 5; k = k + 1) begin
            for (m = 0; m < 2; m = m + 1) begin
                head_out[k][m] <= 0;
            end
        end
    end
    else begin
        case (counter)
            'd51: head_out[0][0] <= add5_res;
            'd52: head_out[0][1] <= add5_res;
            'd53: head_out[1][0] <= add5_res;
            'd54: head_out[1][1] <= add5_res;
            'd55: head_out[2][0] <= add5_res;
            'd56: head_out[2][1] <= add5_res;
            'd57: head_out[3][0] <= add5_res;
            'd58: head_out[3][1] <= add5_res;
            'd62: head_out[4][0] <= add5_res;
            'd63: head_out[4][1] <= add5_res;
            'd67: head_out[0][2] <= add5_res;
            'd68: head_out[0][3] <= add5_res;
            'd72: head_out[1][2] <= add5_res;
            'd73: head_out[1][3] <= add5_res;
            'd77: head_out[2][2] <= add5_res;
            'd78: head_out[2][3] <= add5_res;
            'd82: head_out[3][2] <= add5_res;
            'd83: head_out[3][3] <= add5_res;
            'd87: head_out[4][2] <= add5_res;
            'd88: head_out[4][3] <= add5_res;
            default:  begin
                for (k = 0; k < 5; k = k + 1) begin
                    for (m = 0; m < 2; m = m + 1) begin
                        head_out[k][m] <= head_out[k][m];
                    end
                end
            end
        endcase
    end
end

//=========================================//
//                    FINAL                //
//=========================================//
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (k = 0; k < 5; k = k + 1) begin
            for (m = 0; m < 4; m = m + 1) begin
                final_matrix[k][m] <= 0;
            end
        end
    end
    else if (c_state == IDLE) begin
        for (k = 0; k < 5; k = k + 1) begin
            for (m = 0; m < 4; m = m + 1) begin
                final_matrix[k][m] <= 0;
            end
        end
    end
    else if (c_state == OUT) begin
        for (m = 0; m < 5; m = m + 1) begin
            for (k = 0; k < 3; k = k + 1) begin
                final_matrix[m][k] <= final_matrix[m][k + 1];
            end
        end
        final_matrix[0][3] <= final_matrix[1][0];
        final_matrix[1][3] <= final_matrix[2][0];
        final_matrix[2][3] <= final_matrix[3][0];
        final_matrix[3][3] <= final_matrix[4][0];
        final_matrix[4][3] <= 0;
    end
    else begin
        case (counter)
            'd69: begin
                final_matrix[0][0] <= add6_res;
            end
            'd70: begin
                final_matrix[0][1] <= add6_res;
            end
            'd71: begin
                final_matrix[0][2] <= add6_res;
            end
            'd74: begin
                final_matrix[0][3] <= add3_res;
                final_matrix[1][0] <= add6_res;
            end
            'd75: begin
                final_matrix[1][1] <= add3_res;
                final_matrix[1][2] <= add6_res;
            end
            'd76: begin
                final_matrix[1][3] <= add3_res;
            end
            'd79: begin
                final_matrix[2][0] <= add3_res;
                final_matrix[2][1] <= add6_res;
            end
            'd80: begin
                final_matrix[2][2] <= add3_res;
                final_matrix[2][3] <= add6_res;
            end
            'd84: begin
                final_matrix[3][0] <= add3_res;
                final_matrix[3][1] <= add6_res;
            end
            'd85: begin
                final_matrix[3][2] <= add3_res;
                final_matrix[3][3] <= add6_res;
            end
            'd89: begin
                final_matrix[4][0] <= add3_res;
                final_matrix[4][1] <= add6_res;
            end
            'd90: begin
                final_matrix[4][2] <= add3_res;
                final_matrix[4][3] <= add6_res;
            end
            default:  begin
                for (k = 0; k < 5; k = k + 1) begin
                    for (m = 0; m < 2; m = m + 1) begin
                        final_matrix[k][m] <= final_matrix[k][m];
                    end
                end
            end
        endcase
    end
end
endmodule



// //############################################################################
// //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// //   (C) Copyright Laboratory System Integration and Silicon Implementation
// //   All Right Reserved
// //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// //
// //   ICLAB 2023 Fall
// //   Lab04 Exercise		: Two Head Attention
// //   Author     		: Yu-Chi Lin (a6121461214.st12@nycu.edu.tw)
// //
// //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// //
// //   File Name   : ATTN.v
// //   Module Name : ATTN
// //   Release version : V1.0 (Release Date: 2025-3)
// //
// //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// //############################################################################


// module ATTN(
//     //Input Port
//     clk,
//     rst_n,

//     in_valid,
//     in_str,
//     q_weight,
//     k_weight,
//     v_weight,
//     out_weight,

//     //Output Port
//     out_valid,
//     out
//     );

// //---------------------------------------------------------------------
// //   PARAMETER
// //---------------------------------------------------------------------

// // IEEE floating point parameter
// parameter inst_sig_width = 23;
// parameter inst_exp_width = 8;
// parameter inst_ieee_compliance = 0;
// parameter inst_arch_type = 0;
// parameter inst_arch = 0;
// parameter inst_faithful_round = 0;
// parameter sqare_root_2 = 32'b00111111101101010000010011110011;

// parameter IDLE = 3'd0;
// parameter IN = 3'd1;
// parameter CAL = 3'd2;
// parameter OUT = 3'd3;

// input rst_n, clk, in_valid;
// input [inst_sig_width+inst_exp_width:0] in_str, q_weight, k_weight, v_weight, out_weight;

// output reg	out_valid;
// output reg [inst_sig_width+inst_exp_width:0] out;


// //---------------------------------------------------------------------
// //   Reg & Wires
// //---------------------------------------------------------------------
// reg       weight_in_valid;
// reg [2:0] c_state;
// reg [2:0] n_state;
// reg [6:0] counter;

// reg [2:0] row;
// reg [2:0] col;
// reg [2:0] row_ff;
// reg [2:0] col_ff;
// reg       counter_div_en;
// reg       div_score2;
// reg       softmax_score2_en;
// reg       mult_use_cnt_div;

// reg [inst_sig_width+inst_exp_width:0] softmax_row0;
// reg [inst_sig_width+inst_exp_width:0] softmax_row1;
// reg [inst_sig_width+inst_exp_width:0] softmax_row2;
// reg [inst_sig_width+inst_exp_width:0] softmax_row3;
// reg [inst_sig_width+inst_exp_width:0] softmax_row4;

// reg [inst_sig_width+inst_exp_width:0] in_str_ff;
// reg [inst_sig_width+inst_exp_width:0] q_weight_ff;
// reg [inst_sig_width+inst_exp_width:0] k_weight_ff;
// reg [inst_sig_width+inst_exp_width:0] v_weight_ff;
// reg [inst_sig_width+inst_exp_width:0] out_weight_ff;

// reg [inst_sig_width+inst_exp_width:0] in_str_arr [0:4][0:3];
// reg [inst_sig_width+inst_exp_width:0] q_weight_arr [0:3][0:3];
// reg [inst_sig_width+inst_exp_width:0] k_weight_arr [0:3][0:3];
// reg [inst_sig_width+inst_exp_width:0] v_weight_arr [0:3][0:3];
// reg [inst_sig_width+inst_exp_width:0] out_weight_arr [0:3][0:3];
// // reg [inst_sig_width+inst_exp_width:0] in_str_arr [0:19];
// // reg [inst_sig_width+inst_exp_width:0] q_weight_arr [0:15];
// // reg [inst_sig_width+inst_exp_width:0] k_weight_arr [0:15];
// // reg [inst_sig_width+inst_exp_width:0] v_weight_arr [0:15];
// // reg [inst_sig_width+inst_exp_width:0] out_weight_arr [0:15];

// reg [inst_sig_width+inst_exp_width:0] q_matrix [0:4][0:3];
// reg [inst_sig_width+inst_exp_width:0] k_matrix [0:4][0:3];
// reg [inst_sig_width+inst_exp_width:0] v_matrix [0:4][0:3];
// reg [inst_sig_width+inst_exp_width:0] score_1_matrix [0:4][0:4];
// reg [inst_sig_width+inst_exp_width:0] score_2_matrix [0:4][0:4];

// reg [inst_sig_width+inst_exp_width:0] head_out [0:4][0:3];
// reg [inst_sig_width+inst_exp_width:0] final_matrix [0:4][0:3];

// reg [inst_sig_width+inst_exp_width:0] mul1_a;
// reg [inst_sig_width+inst_exp_width:0] mul1_b;
// reg [inst_sig_width+inst_exp_width:0] mul1_res;
// reg [7:0]                             mul_status1;

// reg [inst_sig_width+inst_exp_width:0] mul2_a;
// reg [inst_sig_width+inst_exp_width:0] mul2_b;
// reg [inst_sig_width+inst_exp_width:0] mul2_res;
// reg [7:0]                             mul_status2;

// reg [inst_sig_width+inst_exp_width:0] mul3_a;
// reg [inst_sig_width+inst_exp_width:0] mul3_b;
// reg [inst_sig_width+inst_exp_width:0] mul3_res;
// reg [7:0]                             mul_status3;

// reg [inst_sig_width+inst_exp_width:0] mul4_a;
// reg [inst_sig_width+inst_exp_width:0] mul4_b;
// reg [inst_sig_width+inst_exp_width:0] mul4_res;
// reg [7:0]                             mul_status4;

// reg [inst_sig_width+inst_exp_width:0] mul5_a;
// reg [inst_sig_width+inst_exp_width:0] mul5_b;
// reg [inst_sig_width+inst_exp_width:0] mul5_res;
// reg [7:0]                             mul_status5;

// reg [inst_sig_width+inst_exp_width:0] mul6_a;
// reg [inst_sig_width+inst_exp_width:0] mul6_b;
// reg [inst_sig_width+inst_exp_width:0] mul6_res;
// reg [7:0]                             mul_status6;

// reg [inst_sig_width+inst_exp_width:0] mul7_a;
// reg [inst_sig_width+inst_exp_width:0] mul7_b;
// reg [inst_sig_width+inst_exp_width:0] mul7_res;
// reg [7:0]                             mul_status7;

// reg [inst_sig_width+inst_exp_width:0] mul8_a;
// reg [inst_sig_width+inst_exp_width:0] mul8_b;
// reg [inst_sig_width+inst_exp_width:0] mul8_res;
// reg [7:0]                             mul_status8;

// reg [inst_sig_width+inst_exp_width:0] add1_a;
// reg [inst_sig_width+inst_exp_width:0] add1_b;
// reg [inst_sig_width+inst_exp_width:0] add1_res;
// reg [7:0]                             add_status1;

// reg [inst_sig_width+inst_exp_width:0] add2_a;
// reg [inst_sig_width+inst_exp_width:0] add2_b;
// reg [inst_sig_width+inst_exp_width:0] add2_res;
// reg [7:0]                             add_status2;

// reg [inst_sig_width+inst_exp_width:0] add3_a;
// reg [inst_sig_width+inst_exp_width:0] add3_b;
// reg [inst_sig_width+inst_exp_width:0] add3_res;
// reg [7:0]                             add_status3;

// reg [inst_sig_width+inst_exp_width:0] add4_a;
// reg [inst_sig_width+inst_exp_width:0] add4_b;
// reg [inst_sig_width+inst_exp_width:0] add4_res;
// reg [7:0]                             add_status4;

// reg [inst_sig_width+inst_exp_width:0] add5_a;
// reg [inst_sig_width+inst_exp_width:0] add5_b;
// reg [inst_sig_width+inst_exp_width:0] add5_res;
// reg [7:0]                             add_status5;

// reg [inst_sig_width+inst_exp_width:0] add6_a;
// reg [inst_sig_width+inst_exp_width:0] add6_b;
// reg [inst_sig_width+inst_exp_width:0] add6_res;
// reg [7:0]                             add_status6;

// reg [inst_sig_width+inst_exp_width:0] add7_a;
// reg [inst_sig_width+inst_exp_width:0] add7_b;
// reg [inst_sig_width+inst_exp_width:0] add7_res;
// reg [7:0]                             add_status7;

// reg [inst_sig_width+inst_exp_width:0] exp1_in;
// reg [inst_sig_width+inst_exp_width:0] exp1_res;
// reg [7:0]                             exp_status1;

// reg [inst_sig_width+inst_exp_width:0] div1_a;
// reg [inst_sig_width+inst_exp_width:0] div1_b;
// reg [inst_sig_width+inst_exp_width:0] div1_res;
// reg [7:0]                             div_status1;

// reg [inst_sig_width+inst_exp_width:0] div2_a;
// reg [inst_sig_width+inst_exp_width:0] div2_b;
// reg [inst_sig_width+inst_exp_width:0] div2_res;
// reg [7:0]                             div_status2;

// integer k, m;
// genvar i, j;
// //---------------------------------------------------------------------
// // IPs
// //---------------------------------------------------------------------
// // ex.
// DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
// MUL1 ( .a(mul1_a), .b(mul1_b), .rnd(3'b000), .z(mul1_res), .status(mul_status1));
// DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
// MUL2 ( .a(mul2_a), .b(mul2_b), .rnd(3'b000), .z(mul2_res), .status(mul_status2));
// DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
// MUL3 ( .a(mul3_a), .b(mul3_b), .rnd(3'b000), .z(mul3_res), .status(mul_status3));
// DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
// MUL4 ( .a(mul4_a), .b(mul4_b), .rnd(3'b000), .z(mul4_res), .status(mul_status4));
// DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
// ADD1 ( .a(add1_a), .b(add1_b), .rnd(3'b000), .z(add1_res), .status(add_status1));
// DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
// ADD2 ( .a(add2_a), .b(add2_b), .rnd(3'b000), .z(add2_res), .status(add_status2));
// DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
// ADD3 ( .a(add3_a), .b(add3_b), .rnd(3'b000), .z(add3_res), .status(add_status3));

// DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
// MUL5 ( .a(mul5_a), .b(mul5_b), .rnd(3'b000), .z(mul5_res), .status(mul_status5));
// DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
// MUL6 ( .a(mul6_a), .b(mul6_b), .rnd(3'b000), .z(mul6_res), .status(mul_status6));
// DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
// MUL7 ( .a(mul7_a), .b(mul7_b), .rnd(3'b000), .z(mul7_res), .status(mul_status7));
// DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
// MUL8 ( .a(mul8_a), .b(mul8_b), .rnd(3'b000), .z(mul8_res), .status(mul_status8));
// DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
// ADD4 ( .a(add4_a), .b(add4_b), .rnd(3'b000), .z(add4_res), .status(add_status4));
// DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
// ADD5 ( .a(add5_a), .b(add5_b), .rnd(3'b000), .z(add5_res), .status(add_status5));
// DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
// ADD6 ( .a(add6_a), .b(add6_b), .rnd(3'b000), .z(add6_res), .status(add_status6));

// DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance, 0) 
// EXP1 (.a(exp1_in), .z(exp1_res), .status(exp_status1));

// DW_fp_div #(inst_sig_width, inst_exp_width, inst_ieee_compliance, 0) 
// DIV1 ( .a(div1_a), .b(sqare_root_2), .rnd(3'b000), .z(div1_res), .status(div_status1));

// DW_fp_div #(inst_sig_width, inst_exp_width, inst_ieee_compliance, 0) 
// DIV2 ( .a(div2_a), .b(div2_b), .rnd(3'b000), .z(div2_res), .status(div_status2));

// DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
// ADD7 ( .a(add7_a), .b(add7_b), .rnd(3'b000), .z(add7_res), .status(add_status7));
// //---------------------------------------------------------------------
// // Design
// //---------------------------------------------------------------------

// //=================================//
// //              fsm                //
// //=================================//
// always @(posedge clk or negedge rst_n) begin
//     if (!rst_n)
//         c_state <= IDLE;
//     else
//         c_state <= n_state;
// end

// always @(*) begin
//     case (c_state)
//         IDLE: if (in_valid) 
//                 n_state = IN;
//               else
//                 n_state = IDLE;
//         IN  : if (!in_valid)
//                 n_state = CAL;
//               else
//                 n_state = IN;
//         CAL : if (counter == 90)
//                 n_state = OUT;
//               else
//                 n_state = CAL;
//         OUT : if (counter == 110)
//                 n_state = IDLE;
//               else
//                 n_state = OUT;
//         default: n_state = IDLE; 
//     endcase
// end


// always @(posedge clk or negedge rst_n) begin
//     if (!rst_n)
//         out_valid <= 0;
//     else if (c_state == IDLE)
//         out_valid <= 0;
//     else begin
//         if (c_state == OUT)
//             out_valid <= 1;
//         else
//             out_valid <= 0;
//     end      
// end

// always @(posedge clk or negedge rst_n) begin
//     if (!rst_n)
//         out <= 0;
//     else if (c_state == IDLE)
//         out <= 0;
//     else if (c_state == OUT)
//         out <= final_matrix[0][0];
//     else
//         out <= 0;
// end

// always @(posedge clk or negedge rst_n) begin
//     if (!rst_n)
//         counter <= 0;
//     else if (!in_valid && (counter == 0))
//         counter <= 0 ;
//     else
//         counter <= counter + 1;
// end
// always @(posedge clk or negedge rst_n) begin
//     if (!rst_n)
//         counter_div_en <= 0;
//     else if (c_state == IDLE)
//         counter_div_en <= 0;
//     else begin
//         if (counter == 28)
//             counter_div_en <= 1;
//         else
//             counter_div_en <= counter_div_en; 
//     end
// end

// always @(posedge clk or negedge rst_n) begin
//     if (!rst_n)
//         row <= 'd0;
//     else if (c_state == IDLE)
//         row <= 0;
//     else begin
//         if (col == 4) begin
//             if (row == 4)
//                 row <= 0;
//             else
//                 row <= row + 1;
//         end
//         else
//             row <= row; 
//     end
// end

// always @(posedge clk or negedge rst_n) begin
//     if (!rst_n)
//         col <= 'd0;
//     else if (c_state == IDLE)
//         col <= 0;
//     else begin
//         if (counter_div_en) begin
//             if (col == 4)
//                 col <= 0;
//             else
//                 col <= col + 1;
//         end
//         else
//             col <= col; 
//     end
// end

// always @(posedge clk or negedge rst_n) begin
//     if (!rst_n)
//         row_ff <= 0;
//     else
//         row_ff <= row;
// end

// always @(posedge clk or negedge rst_n) begin
//     if (!rst_n)
//         col_ff <= 0;
//     else
//         col_ff <= col;
// end
// always @(posedge clk or negedge rst_n) begin
//     if (!rst_n)
//         div_score2 <= 0;
//     else if (c_state == IDLE)
//         div_score2 <= 0;
//     else begin
//         if (row == 4 && col == 4)
//             div_score2 <= 1;
//         else
//             div_score2 <= div_score2; 
//     end
// end

// always @(posedge clk or negedge rst_n) begin
//     if (!rst_n)
//         softmax_score2_en <= 0;
//     else begin
//         if (row == 1 && col == 2 && div_score2)
//             softmax_score2_en <= 1;
//         else
//             softmax_score2_en <= softmax_score2_en;
//     end
// end

// always @(posedge clk or negedge rst_n) begin
//     if (!rst_n)
//         mult_use_cnt_div <= 0;
//     else begin
//         if (counter == 50)
//             mult_use_cnt_div <= 1;
//         else
//             mult_use_cnt_div <= mult_use_cnt_div; 
//     end
// end
// //=================================//
// //            save input           //
// //=================================//
// generate
//     for (i = 0; i < 5; i = i + 1) begin
//         for (j = 0; j < 4; j = j + 1) begin 
//             always @(posedge clk or negedge rst_n) begin
//                 if (!rst_n)
//                     in_str_arr[i][j] <= 0;
//                 else if ((counter == j + i * 4) && in_valid)
//                     in_str_arr[i][j] <= in_str; 
//                 else
//                     in_str_arr[i][j] <= in_str_arr[i][j];
//             end
//         end
//     end
// endgenerate

// generate
//     for (i = 0; i < 4; i = i + 1) begin
//         for (j = 0; j < 4; j = j + 1) begin
//             always @(posedge clk or negedge rst_n) begin
//                 if (!rst_n)
//                     q_weight_arr[i][j] <= 0;
//                 else if ((counter == j + i * 4) && in_valid)
//                     q_weight_arr[i][j] <= q_weight; 
//                 else
//                     q_weight_arr[i][j] <= q_weight_arr[i][j];
//             end
//         end
//     end
// endgenerate

// generate
//     for (i = 0; i < 4; i = i + 1) begin
//         for (j = 0; j < 4; j = j + 1) begin
//             always @(posedge clk or negedge rst_n) begin
//                 if (!rst_n)
//                     v_weight_arr[i][j] <= 0;
//                 else if ((counter == j + i * 4) && in_valid)
//                     v_weight_arr[i][j] <= v_weight; 
//                 else
//                     v_weight_arr[i][j] <= v_weight_arr[i][j];
//             end
//         end
//     end
// endgenerate

// generate
//     for (i = 0; i < 4; i = i + 1) begin
//         for (j = 0; j < 4; j = j + 1) begin
//             always @(posedge clk or negedge rst_n) begin
//                 if (!rst_n)
//                     k_weight_arr[i][j] <= 0;
//                 else if ((counter == j + i * 4) && in_valid)
//                     k_weight_arr[i][j] <= k_weight; 
//                 else
//                     k_weight_arr[i][j] <= k_weight_arr[i][j];
//             end
//         end
//     end
// endgenerate

// generate
//     for (i = 0; i < 4; i = i + 1) begin
//         for (j = 0; j < 4; j = j + 1) begin
//             always @(posedge clk or negedge rst_n) begin
//                 if (!rst_n)
//                     out_weight_arr[i][j] <= 0;
//                 else if ((counter == j + i * 4) && in_valid)
//                     out_weight_arr[i][j] <= out_weight; 
//                 else
//                     out_weight_arr[i][j] <= out_weight_arr[i][j];
//             end
//         end
//     end
// endgenerate
// //===========================================================
// //=================================//
// //            calculate            //
// //=================================//

// //=========================================//
// //           in_str x k_weight             //
// //=========================================//
// always @(*) begin
//     case (counter)
//         // k
//         'd4:  mul1_a = in_str_arr[0][0];
//         'd8:  mul1_a = in_str_arr[1][0];
//         'd9:  mul1_a = in_str_arr[0][0];
//         'd10: mul1_a = in_str_arr[1][0];
//         'd12: mul1_a = in_str_arr[2][0];
//         'd13: mul1_a = in_str_arr[0][0];
//         'd14: mul1_a = in_str_arr[1][0];
//         'd15: mul1_a = in_str_arr[2][0];
//         'd16: mul1_a = in_str_arr[3][0];
//         'd17: mul1_a = in_str_arr[0][0];
//         'd18: mul1_a = in_str_arr[1][0];
//         'd19: mul1_a = in_str_arr[2][0];
//         'd20: mul1_a = in_str_arr[4][0];
//         'd21: mul1_a = in_str_arr[2][0];
//         'd22: mul1_a = in_str_arr[3][0];
//         'd23: mul1_a = in_str_arr[4][0];
//         'd24: mul1_a = in_str_arr[3][0];
//         'd25: mul1_a = in_str_arr[4][0];
//         'd26: mul1_a = in_str_arr[3][0];
//         'd27: mul1_a = in_str_arr[4][0];
//         // v
//         'd28: mul1_a = in_str_arr[0][0];
//         'd29: mul1_a = in_str_arr[1][0];
//         'd30: mul1_a = in_str_arr[2][0];
//         'd31: mul1_a = in_str_arr[3][0];
//         'd32: mul1_a = in_str_arr[4][0];
//         'd33: mul1_a = in_str_arr[0][0];
//         'd34: mul1_a = in_str_arr[1][0];
//         'd35: mul1_a = in_str_arr[2][0];
//         'd36: mul1_a = in_str_arr[3][0];
//         'd37: mul1_a = in_str_arr[4][0];
//         'd38: mul1_a = in_str_arr[0][0];
//         'd39: mul1_a = in_str_arr[1][0];
//         'd40: mul1_a = in_str_arr[2][0];
//         'd41: mul1_a = in_str_arr[3][0];
//         'd42: mul1_a = in_str_arr[4][0];
//         'd43: mul1_a = in_str_arr[0][0];
//         'd44: mul1_a = in_str_arr[1][0];
//         'd45: mul1_a = in_str_arr[2][0];
//         'd46: mul1_a = in_str_arr[3][0];
//         'd47: mul1_a = in_str_arr[4][0];
//         // score2
//         'd48: mul1_a = q_matrix[3][2];
//         'd49: mul1_a = q_matrix[3][2];
//         'd50: mul1_a = q_matrix[4][2];
//         // head_out 1
//         'd51: mul1_a = score_1_matrix[0][0];
//         'd52: mul1_a = score_1_matrix[0][0];
//         'd53: mul1_a = score_1_matrix[1][0];
//         'd54: mul1_a = score_1_matrix[1][0];
//         'd55: mul1_a = score_1_matrix[2][0];
//         'd56: mul1_a = score_1_matrix[2][0];
//         'd57: mul1_a = score_1_matrix[3][0];
//         'd58: mul1_a = score_1_matrix[3][0];
//         'd62: mul1_a = score_1_matrix[4][0];
//         'd63: mul1_a = score_1_matrix[4][0];
//         // head_out 2
//         'd67: mul1_a = score_2_matrix[0][0];
//         'd68: mul1_a = score_2_matrix[0][0];
//         'd72: mul1_a = score_2_matrix[1][0];
//         'd73: mul1_a = score_2_matrix[1][0];
//         'd77: mul1_a = score_2_matrix[2][0];
//         'd78: mul1_a = score_2_matrix[2][0];
//         'd82: mul1_a = score_2_matrix[3][0];
//         'd83: mul1_a = score_2_matrix[3][0];
//         'd87: mul1_a = score_2_matrix[4][0];
//         'd88: mul1_a = score_2_matrix[4][0];
//         // final
//         'd74: mul1_a = head_out[0][0];
//         'd75: mul1_a = head_out[1][0];
//         'd76: mul1_a = head_out[1][0];
//         'd79: mul1_a = head_out[2][0];
//         'd80: mul1_a = head_out[2][0];
//         'd84: mul1_a = head_out[3][0];
//         'd85: mul1_a = head_out[3][0];
//         'd89: mul1_a = head_out[4][0];
//         'd90: mul1_a = head_out[4][0];
//         default: mul1_a = 0;
//     endcase
// end

// always @(*) begin
//     case (counter)
//         'd4:  mul1_b = k_weight_arr[0][0];
//         'd8:  mul1_b = k_weight_arr[0][0];
//         'd9:  mul1_b = k_weight_arr[1][0];
//         'd10: mul1_b = k_weight_arr[1][0];
//         'd12: mul1_b = k_weight_arr[0][0];
//         'd13: mul1_b = k_weight_arr[2][0];
//         'd14: mul1_b = k_weight_arr[2][0];
//         'd15: mul1_b = k_weight_arr[1][0];
//         'd16: mul1_b = k_weight_arr[0][0];
//         'd17: mul1_b = k_weight_arr[3][0];
//         'd18: mul1_b = k_weight_arr[3][0];
//         'd19: mul1_b = k_weight_arr[2][0];
//         'd20: mul1_b = k_weight_arr[0][0];
//         'd21: mul1_b = k_weight_arr[3][0];
//         'd22: mul1_b = k_weight_arr[1][0];
//         'd23: mul1_b = k_weight_arr[1][0];
//         'd24: mul1_b = k_weight_arr[2][0];
//         'd25: mul1_b = k_weight_arr[2][0];
//         'd26: mul1_b = k_weight_arr[3][0];
//         'd27: mul1_b = k_weight_arr[3][0];

//         'd28: mul1_b = v_weight_arr[0][0];
//         'd29: mul1_b = v_weight_arr[0][0];
//         'd30: mul1_b = v_weight_arr[0][0];
//         'd31: mul1_b = v_weight_arr[0][0];
//         'd32: mul1_b = v_weight_arr[0][0];
//         'd33: mul1_b = v_weight_arr[1][0];
//         'd34: mul1_b = v_weight_arr[1][0];
//         'd35: mul1_b = v_weight_arr[1][0];
//         'd36: mul1_b = v_weight_arr[1][0];
//         'd37: mul1_b = v_weight_arr[1][0];
//         'd38: mul1_b = v_weight_arr[2][0];
//         'd39: mul1_b = v_weight_arr[2][0];
//         'd40: mul1_b = v_weight_arr[2][0];
//         'd41: mul1_b = v_weight_arr[2][0];
//         'd42: mul1_b = v_weight_arr[2][0];
//         'd43: mul1_b = v_weight_arr[3][0];
//         'd44: mul1_b = v_weight_arr[3][0];
//         'd45: mul1_b = v_weight_arr[3][0];
//         'd46: mul1_b = v_weight_arr[3][0];
//         'd47: mul1_b = v_weight_arr[3][0];
//         // score2
//         'd48: mul1_b = k_matrix[0][2];
//         'd49: mul1_b = k_matrix[4][2];
//         'd50: mul1_b = k_matrix[3][2];
//         // head_out 1
//         'd51: mul1_b = v_matrix[0][0];
//         'd52: mul1_b = v_matrix[0][1];
//         'd53: mul1_b = v_matrix[0][0];
//         'd54: mul1_b = v_matrix[0][1];
//         'd55: mul1_b = v_matrix[0][0];
//         'd56: mul1_b = v_matrix[0][1];
//         'd57: mul1_b = v_matrix[0][0];
//         'd58: mul1_b = v_matrix[0][1];
//         'd62: mul1_b = v_matrix[0][0];
//         'd63: mul1_b = v_matrix[0][1];
//         // head_out 2
//         'd67: mul1_b = v_matrix[0][2];
//         'd68: mul1_b = v_matrix[0][3];
//         'd72: mul1_b = v_matrix[0][2];
//         'd73: mul1_b = v_matrix[0][3];
//         'd77: mul1_b = v_matrix[0][2];
//         'd78: mul1_b = v_matrix[0][3];
//         'd82: mul1_b = v_matrix[0][2];
//         'd83: mul1_b = v_matrix[0][3];
//         'd87: mul1_b = v_matrix[0][2];
//         'd88: mul1_b = v_matrix[0][3];
//         // final
//         'd74: mul1_b = out_weight_arr[3][0];
//         'd75: mul1_b = out_weight_arr[1][0];
//         'd76: mul1_b = out_weight_arr[3][0];
//         'd79: mul1_b = out_weight_arr[0][0];
//         'd80: mul1_b = out_weight_arr[2][0];
//         'd84: mul1_b = out_weight_arr[0][0];
//         'd85: mul1_b = out_weight_arr[2][0];
//         'd89: mul1_b = out_weight_arr[0][0];
//         'd90: mul1_b = out_weight_arr[2][0];
//         default: mul1_b = 0;
//     endcase
// end

// always @(*) begin
//     case (counter)
//         'd4:  mul2_a = in_str_arr[0][1];
//         'd8:  mul2_a = in_str_arr[1][1];
//         'd9:  mul2_a = in_str_arr[0][1];
//         'd10: mul2_a = in_str_arr[1][1];
//         'd12: mul2_a = in_str_arr[2][1];
//         'd13: mul2_a = in_str_arr[0][1];
//         'd14: mul2_a = in_str_arr[1][1];
//         'd15: mul2_a = in_str_arr[2][1];
//         'd16: mul2_a = in_str_arr[3][1];
//         'd17: mul2_a = in_str_arr[0][1];
//         'd18: mul2_a = in_str_arr[1][1];
//         'd19: mul2_a = in_str_arr[2][1];
//         'd20: mul2_a = in_str_arr[4][1];
//         'd21: mul2_a = in_str_arr[2][1];
//         'd22: mul2_a = in_str_arr[3][1];
//         'd23: mul2_a = in_str_arr[4][1];
//         'd24: mul2_a = in_str_arr[3][1];
//         'd25: mul2_a = in_str_arr[4][1];
//         'd26: mul2_a = in_str_arr[3][1];
//         'd27: mul2_a = in_str_arr[4][1];

//         'd28: mul2_a = in_str_arr[0][1];
//         'd29: mul2_a = in_str_arr[1][1];
//         'd30: mul2_a = in_str_arr[2][1];
//         'd31: mul2_a = in_str_arr[3][1];
//         'd32: mul2_a = in_str_arr[4][1];
//         'd33: mul2_a = in_str_arr[0][1];
//         'd34: mul2_a = in_str_arr[1][1];
//         'd35: mul2_a = in_str_arr[2][1];
//         'd36: mul2_a = in_str_arr[3][1];
//         'd37: mul2_a = in_str_arr[4][1];
//         'd38: mul2_a = in_str_arr[0][1];
//         'd39: mul2_a = in_str_arr[1][1];
//         'd40: mul2_a = in_str_arr[2][1];
//         'd41: mul2_a = in_str_arr[3][1];
//         'd42: mul2_a = in_str_arr[4][1];
//         'd43: mul2_a = in_str_arr[0][1];
//         'd44: mul2_a = in_str_arr[1][1];
//         'd45: mul2_a = in_str_arr[2][1];
//         'd46: mul2_a = in_str_arr[3][1];
//         'd47: mul2_a = in_str_arr[4][1];
//         // score2
//         'd48: mul2_a = q_matrix[3][3];
//         'd49: mul2_a = q_matrix[3][3];
//         'd50: mul2_a = q_matrix[4][3];
//         // head_out 1
//         'd51: mul2_a = score_1_matrix[0][1];
//         'd52: mul2_a = score_1_matrix[0][1];
//         'd53: mul2_a = score_1_matrix[1][1];
//         'd54: mul2_a = score_1_matrix[1][1];
//         'd55: mul2_a = score_1_matrix[2][1];
//         'd56: mul2_a = score_1_matrix[2][1];
//         'd57: mul2_a = score_1_matrix[3][1];
//         'd58: mul2_a = score_1_matrix[3][1];
//         'd62: mul2_a = score_1_matrix[4][1];
//         'd63: mul2_a = score_1_matrix[4][1];
//         // head_out 2
//         'd67: mul2_a = score_2_matrix[0][1];
//         'd68: mul2_a = score_2_matrix[0][1];
//         'd72: mul2_a = score_2_matrix[1][1];
//         'd73: mul2_a = score_2_matrix[1][1];
//         'd77: mul2_a = score_2_matrix[2][1];
//         'd78: mul2_a = score_2_matrix[2][1];
//         'd82: mul2_a = score_2_matrix[3][1];
//         'd83: mul2_a = score_2_matrix[3][1];
//         'd87: mul2_a = score_2_matrix[4][1];
//         'd88: mul2_a = score_2_matrix[4][1];
//         // final
//         'd74: mul2_a = head_out[0][1];
//         'd75: mul2_a = head_out[1][1];
//         'd76: mul2_a = head_out[1][1];
//         'd79: mul2_a = head_out[2][1];
//         'd80: mul2_a = head_out[2][1];
//         'd84: mul2_a = head_out[3][1];
//         'd85: mul2_a = head_out[3][1];
//         'd89: mul2_a = head_out[4][1];
//         'd90: mul2_a = head_out[4][1];
//         default: mul2_a = 0;
//     endcase
// end

// always @(*) begin
//     case (counter)
//         'd4:  mul2_b = k_weight_arr[0][1];
//         'd8:  mul2_b = k_weight_arr[0][1];
//         'd9:  mul2_b = k_weight_arr[1][1];
//         'd10: mul2_b = k_weight_arr[1][1];
//         'd12: mul2_b = k_weight_arr[0][1];
//         'd13: mul2_b = k_weight_arr[2][1];
//         'd14: mul2_b = k_weight_arr[2][1];
//         'd15: mul2_b = k_weight_arr[1][1];
//         'd16: mul2_b = k_weight_arr[0][1];
//         'd17: mul2_b = k_weight_arr[3][1];
//         'd18: mul2_b = k_weight_arr[3][1];
//         'd19: mul2_b = k_weight_arr[2][1];
//         'd20: mul2_b = k_weight_arr[0][1];
//         'd21: mul2_b = k_weight_arr[3][1];
//         'd22: mul2_b = k_weight_arr[1][1];
//         'd23: mul2_b = k_weight_arr[1][1];
//         'd24: mul2_b = k_weight_arr[2][1];
//         'd25: mul2_b = k_weight_arr[2][1];
//         'd26: mul2_b = k_weight_arr[3][1];
//         'd27: mul2_b = k_weight_arr[3][1];

//         'd28: mul2_b = v_weight_arr[0][1];
//         'd29: mul2_b = v_weight_arr[0][1];
//         'd30: mul2_b = v_weight_arr[0][1];
//         'd31: mul2_b = v_weight_arr[0][1];
//         'd32: mul2_b = v_weight_arr[0][1];
//         'd33: mul2_b = v_weight_arr[1][1];
//         'd34: mul2_b = v_weight_arr[1][1];
//         'd35: mul2_b = v_weight_arr[1][1];
//         'd36: mul2_b = v_weight_arr[1][1];
//         'd37: mul2_b = v_weight_arr[1][1];
//         'd38: mul2_b = v_weight_arr[2][1];
//         'd39: mul2_b = v_weight_arr[2][1];
//         'd40: mul2_b = v_weight_arr[2][1];
//         'd41: mul2_b = v_weight_arr[2][1];
//         'd42: mul2_b = v_weight_arr[2][1];
//         'd43: mul2_b = v_weight_arr[3][1];
//         'd44: mul2_b = v_weight_arr[3][1];
//         'd45: mul2_b = v_weight_arr[3][1];
//         'd46: mul2_b = v_weight_arr[3][1];
//         'd47: mul2_b = v_weight_arr[3][1];
//         // score2
//         'd48: mul2_b = k_matrix[0][3];
//         'd49: mul2_b = k_matrix[4][3];
//         'd50: mul2_b = k_matrix[3][3];
//         // head_out 1
//         'd51: mul2_b = v_matrix[1][0];
//         'd52: mul2_b = v_matrix[1][1];
//         'd53: mul2_b = v_matrix[1][0];
//         'd54: mul2_b = v_matrix[1][1];
//         'd55: mul2_b = v_matrix[1][0];
//         'd56: mul2_b = v_matrix[1][1];
//         'd57: mul2_b = v_matrix[1][0];
//         'd58: mul2_b = v_matrix[1][1];
//         'd62: mul2_b = v_matrix[1][0];
//         'd63: mul2_b = v_matrix[1][1];
//         // head_out 2
//         'd67: mul2_b = v_matrix[1][2];
//         'd68: mul2_b = v_matrix[1][3];
//         'd72: mul2_b = v_matrix[1][2];
//         'd73: mul2_b = v_matrix[1][3];
//         'd77: mul2_b = v_matrix[1][2];
//         'd78: mul2_b = v_matrix[1][3];
//         'd82: mul2_b = v_matrix[1][2];
//         'd83: mul2_b = v_matrix[1][3];
//         'd87: mul2_b = v_matrix[1][2];
//         'd88: mul2_b = v_matrix[1][3];
//          // final
//         'd74: mul2_b = out_weight_arr[3][1];
//         'd75: mul2_b = out_weight_arr[1][1];
//         'd76: mul2_b = out_weight_arr[3][1];
//         'd79: mul2_b = out_weight_arr[0][1];
//         'd80: mul2_b = out_weight_arr[2][1];
//         'd84: mul2_b = out_weight_arr[0][1];
//         'd85: mul2_b = out_weight_arr[2][1];
//         'd89: mul2_b = out_weight_arr[0][1];
//         'd90: mul2_b = out_weight_arr[2][1];
//         default: mul2_b = 0;
        
//     endcase
// end

// always @(*) begin
//     case (counter)
//         'd4:  mul3_a = in_str_arr[0][2];
//         'd8:  mul3_a = in_str_arr[1][2];
//         'd9:  mul3_a = in_str_arr[0][2];
//         'd10: mul3_a = in_str_arr[1][2];
//         'd12: mul3_a = in_str_arr[2][2];
//         'd13: mul3_a = in_str_arr[0][2];
//         'd14: mul3_a = in_str_arr[1][2];
//         'd15: mul3_a = in_str_arr[2][2];
//         'd16: mul3_a = in_str_arr[3][2];
//         'd17: mul3_a = in_str_arr[0][2];
//         'd18: mul3_a = in_str_arr[1][2];
//         'd19: mul3_a = in_str_arr[2][2];
//         'd20: mul3_a = in_str_arr[4][2];
//         'd21: mul3_a = in_str_arr[2][2];
//         'd22: mul3_a = in_str_arr[3][2];
//         'd23: mul3_a = in_str_arr[4][2];
//         'd24: mul3_a = in_str_arr[3][2];
//         'd25: mul3_a = in_str_arr[4][2];
//         'd26: mul3_a = in_str_arr[3][2];
//         'd27: mul3_a = in_str_arr[4][2];

//         'd28: mul3_a = in_str_arr[0][2];
//         'd29: mul3_a = in_str_arr[1][2];
//         'd30: mul3_a = in_str_arr[2][2];
//         'd31: mul3_a = in_str_arr[3][2];
//         'd32: mul3_a = in_str_arr[4][2];
//         'd33: mul3_a = in_str_arr[0][2];
//         'd34: mul3_a = in_str_arr[1][2];
//         'd35: mul3_a = in_str_arr[2][2];
//         'd36: mul3_a = in_str_arr[3][2];
//         'd37: mul3_a = in_str_arr[4][2];
//         'd38: mul3_a = in_str_arr[0][2];
//         'd39: mul3_a = in_str_arr[1][2];
//         'd40: mul3_a = in_str_arr[2][2];
//         'd41: mul3_a = in_str_arr[3][2];
//         'd42: mul3_a = in_str_arr[4][2];
//         'd43: mul3_a = in_str_arr[0][2];
//         'd44: mul3_a = in_str_arr[1][2];
//         'd45: mul3_a = in_str_arr[2][2];
//         'd46: mul3_a = in_str_arr[3][2];
//         'd47: mul3_a = in_str_arr[4][2];
//         // score2
//         'd48: mul3_a = q_matrix[3][2];
//         'd49: mul3_a = q_matrix[4][2];
//         'd50: mul3_a = q_matrix[4][2];
//         // head_out 1
//         'd51: mul3_a = score_1_matrix[0][2];
//         'd52: mul3_a = score_1_matrix[0][2];
//         'd53: mul3_a = score_1_matrix[1][2];
//         'd54: mul3_a = score_1_matrix[1][2];
//         'd55: mul3_a = score_1_matrix[2][2];
//         'd56: mul3_a = score_1_matrix[2][2];
//         'd57: mul3_a = score_1_matrix[3][2];
//         'd58: mul3_a = score_1_matrix[3][2];
//         'd62: mul3_a = score_1_matrix[4][2];
//         'd63: mul3_a = score_1_matrix[4][2];
//         // head_out 2
//         'd67: mul3_a = score_2_matrix[0][2];
//         'd68: mul3_a = score_2_matrix[0][2];
//         'd72: mul3_a = score_2_matrix[1][2];
//         'd73: mul3_a = score_2_matrix[1][2];
//         'd77: mul3_a = score_2_matrix[2][2];
//         'd78: mul3_a = score_2_matrix[2][2];
//         'd82: mul3_a = score_2_matrix[3][2];
//         'd83: mul3_a = score_2_matrix[3][2];
//         'd87: mul3_a = score_2_matrix[4][2];
//         'd88: mul3_a = score_2_matrix[4][2];
//         // final
//         'd74: mul3_a = head_out[0][2];
//         'd75: mul3_a = head_out[1][2];
//         'd76: mul3_a = head_out[1][2];
//         'd79: mul3_a = head_out[2][2];
//         'd80: mul3_a = head_out[2][2];
//         'd84: mul3_a = head_out[3][2];
//         'd85: mul3_a = head_out[3][2];
//         'd89: mul3_a = head_out[4][2];
//         'd90: mul3_a = head_out[4][2];
//         default: mul3_a = 0;
//     endcase
// end

// always @(*) begin
//     case (counter)
//         'd4:  mul3_b = k_weight_arr[0][2];
//         'd8:  mul3_b = k_weight_arr[0][2];
//         'd9:  mul3_b = k_weight_arr[1][2];
//         'd10: mul3_b = k_weight_arr[1][2];
//         'd12: mul3_b = k_weight_arr[0][2];
//         'd13: mul3_b = k_weight_arr[2][2];
//         'd14: mul3_b = k_weight_arr[2][2];
//         'd15: mul3_b = k_weight_arr[1][2];
//         'd16: mul3_b = k_weight_arr[0][2];
//         'd17: mul3_b = k_weight_arr[3][2];
//         'd18: mul3_b = k_weight_arr[3][2];
//         'd19: mul3_b = k_weight_arr[2][2];
//         'd20: mul3_b = k_weight_arr[0][2];
//         'd21: mul3_b = k_weight_arr[3][2];
//         'd22: mul3_b = k_weight_arr[1][2];
//         'd23: mul3_b = k_weight_arr[1][2];
//         'd24: mul3_b = k_weight_arr[2][2];
//         'd25: mul3_b = k_weight_arr[2][2];
//         'd26: mul3_b = k_weight_arr[3][2];
//         'd27: mul3_b = k_weight_arr[3][2];

//         'd28: mul3_b = v_weight_arr[0][2];
//         'd29: mul3_b = v_weight_arr[0][2];
//         'd30: mul3_b = v_weight_arr[0][2];
//         'd31: mul3_b = v_weight_arr[0][2];
//         'd32: mul3_b = v_weight_arr[0][2];
//         'd33: mul3_b = v_weight_arr[1][2];
//         'd34: mul3_b = v_weight_arr[1][2];
//         'd35: mul3_b = v_weight_arr[1][2];
//         'd36: mul3_b = v_weight_arr[1][2];
//         'd37: mul3_b = v_weight_arr[1][2];
//         'd38: mul3_b = v_weight_arr[2][2];
//         'd39: mul3_b = v_weight_arr[2][2];
//         'd40: mul3_b = v_weight_arr[2][2];
//         'd41: mul3_b = v_weight_arr[2][2];
//         'd42: mul3_b = v_weight_arr[2][2];
//         'd43: mul3_b = v_weight_arr[3][2];
//         'd44: mul3_b = v_weight_arr[3][2];
//         'd45: mul3_b = v_weight_arr[3][2];
//         'd46: mul3_b = v_weight_arr[3][2];
//         'd47: mul3_b = v_weight_arr[3][2];
//         // score2
//         'd48: mul3_b = k_matrix[1][2];
//         'd49: mul3_b = k_matrix[0][2];
//         'd50: mul3_b = k_matrix[4][2];
//         // head_out 1
//         'd51: mul3_b = v_matrix[2][0];
//         'd52: mul3_b = v_matrix[2][1];
//         'd53: mul3_b = v_matrix[2][0];
//         'd54: mul3_b = v_matrix[2][1];
//         'd55: mul3_b = v_matrix[2][0];
//         'd56: mul3_b = v_matrix[2][1];
//         'd57: mul3_b = v_matrix[2][0];
//         'd58: mul3_b = v_matrix[2][1];
//         'd62: mul3_b = v_matrix[2][0];
//         'd63: mul3_b = v_matrix[2][1];
//         // head_out 2
//         'd67: mul3_b = v_matrix[2][2];
//         'd68: mul3_b = v_matrix[2][3];
//         'd72: mul3_b = v_matrix[2][2];
//         'd73: mul3_b = v_matrix[2][3];
//         'd77: mul3_b = v_matrix[2][2];
//         'd78: mul3_b = v_matrix[2][3];
//         'd82: mul3_b = v_matrix[2][2];
//         'd83: mul3_b = v_matrix[2][3];
//         'd87: mul3_b = v_matrix[2][2];
//         'd88: mul3_b = v_matrix[2][3];
//         // final
//         'd74: mul3_b = out_weight_arr[3][2];
//         'd75: mul3_b = out_weight_arr[1][2];
//         'd76: mul3_b = out_weight_arr[3][2];
//         'd79: mul3_b = out_weight_arr[0][2];
//         'd80: mul3_b = out_weight_arr[2][2];
//         'd84: mul3_b = out_weight_arr[0][2];
//         'd85: mul3_b = out_weight_arr[2][2];
//         'd89: mul3_b = out_weight_arr[0][2];
//         'd90: mul3_b = out_weight_arr[2][2];
//         default: mul3_b = 0;
//     endcase
// end

// always @(*) begin
//     case (counter)
//         'd4:  mul4_a = in_str_arr[0][3];
//         'd8:  mul4_a = in_str_arr[1][3];
//         'd9:  mul4_a = in_str_arr[0][3];
//         'd10: mul4_a = in_str_arr[1][3];
//         'd12: mul4_a = in_str_arr[2][3];
//         'd13: mul4_a = in_str_arr[0][3];
//         'd14: mul4_a = in_str_arr[1][3];
//         'd15: mul4_a = in_str_arr[2][3];
//         'd16: mul4_a = in_str_arr[3][3];
//         'd17: mul4_a = in_str_arr[0][3];
//         'd18: mul4_a = in_str_arr[1][3];
//         'd19: mul4_a = in_str_arr[2][3];
//         'd20: mul4_a = in_str_arr[4][3];
//         'd21: mul4_a = in_str_arr[2][3];
//         'd22: mul4_a = in_str_arr[3][3];
//         'd23: mul4_a = in_str_arr[4][3];
//         'd24: mul4_a = in_str_arr[3][3];
//         'd25: mul4_a = in_str_arr[4][3];
//         'd26: mul4_a = in_str_arr[3][3];
//         'd27: mul4_a = in_str_arr[4][3];

//         'd28: mul4_a = in_str_arr[0][3];
//         'd29: mul4_a = in_str_arr[1][3];
//         'd30: mul4_a = in_str_arr[2][3];
//         'd31: mul4_a = in_str_arr[3][3];
//         'd32: mul4_a = in_str_arr[4][3];
//         'd33: mul4_a = in_str_arr[0][3];
//         'd34: mul4_a = in_str_arr[1][3];
//         'd35: mul4_a = in_str_arr[2][3];
//         'd36: mul4_a = in_str_arr[3][3];
//         'd37: mul4_a = in_str_arr[4][3];
//         'd38: mul4_a = in_str_arr[0][3];
//         'd39: mul4_a = in_str_arr[1][3];
//         'd40: mul4_a = in_str_arr[2][3];
//         'd41: mul4_a = in_str_arr[3][3];
//         'd42: mul4_a = in_str_arr[4][3];
//         'd43: mul4_a = in_str_arr[0][3];
//         'd44: mul4_a = in_str_arr[1][3];
//         'd45: mul4_a = in_str_arr[2][3];
//         'd46: mul4_a = in_str_arr[3][3];
//         'd47: mul4_a = in_str_arr[4][3];
//         // score2
//         'd48: mul4_a = q_matrix[3][3];
//         'd49: mul4_a = q_matrix[4][3];
//         'd50: mul4_a = q_matrix[4][3];
//         // head_out 1
//         'd51: mul4_a = score_1_matrix[0][3];
//         'd52: mul4_a = score_1_matrix[0][3];
//         'd53: mul4_a = score_1_matrix[1][3];
//         'd54: mul4_a = score_1_matrix[1][3];
//         'd55: mul4_a = score_1_matrix[2][3];
//         'd56: mul4_a = score_1_matrix[2][3];
//         'd57: mul4_a = score_1_matrix[3][3];
//         'd58: mul4_a = score_1_matrix[3][3];
//         'd62: mul4_a = score_1_matrix[4][3];
//         'd63: mul4_a = score_1_matrix[4][3];
//         // head_out 2
//         'd67: mul4_a = score_2_matrix[0][3];
//         'd68: mul4_a = score_2_matrix[0][3];
//         'd72: mul4_a = score_2_matrix[1][3];
//         'd73: mul4_a = score_2_matrix[1][3];
//         'd77: mul4_a = score_2_matrix[2][3];
//         'd78: mul4_a = score_2_matrix[2][3];
//         'd82: mul4_a = score_2_matrix[3][3];
//         'd83: mul4_a = score_2_matrix[3][3];
//         'd87: mul4_a = score_2_matrix[4][3];
//         'd88: mul4_a = score_2_matrix[4][3];
//         // final
//         'd74: mul4_a = head_out[0][3];
//         'd75: mul4_a = head_out[1][3];
//         'd76: mul4_a = head_out[1][3];
//         'd79: mul4_a = head_out[2][3];
//         'd80: mul4_a = head_out[2][3];
//         'd84: mul4_a = head_out[3][3];
//         'd85: mul4_a = head_out[3][3];
//         'd89: mul4_a = head_out[4][3];
//         'd90: mul4_a = head_out[4][3];
//         default: mul4_a = 0;
//     endcase
// end

// always @(*) begin
//     case (counter)
//         'd4:  mul4_b = k_weight_arr[0][3];
//         'd8:  mul4_b = k_weight_arr[0][3];
//         'd9:  mul4_b = k_weight_arr[1][3];
//         'd10: mul4_b = k_weight_arr[1][3];
//         'd12: mul4_b = k_weight_arr[0][3];
//         'd13: mul4_b = k_weight_arr[2][3];
//         'd14: mul4_b = k_weight_arr[2][3];
//         'd15: mul4_b = k_weight_arr[1][3];
//         'd16: mul4_b = k_weight_arr[0][3];
//         'd17: mul4_b = k_weight_arr[3][3];
//         'd18: mul4_b = k_weight_arr[3][3];
//         'd19: mul4_b = k_weight_arr[2][3];
//         'd20: mul4_b = k_weight_arr[0][3];
//         'd21: mul4_b = k_weight_arr[3][3];
//         'd22: mul4_b = k_weight_arr[1][3];
//         'd23: mul4_b = k_weight_arr[1][3];
//         'd24: mul4_b = k_weight_arr[2][3];
//         'd25: mul4_b = k_weight_arr[2][3];
//         'd26: mul4_b = k_weight_arr[3][3];
//         'd27: mul4_b = k_weight_arr[3][3];

//         'd28: mul4_b = v_weight_arr[0][3];
//         'd29: mul4_b = v_weight_arr[0][3];
//         'd30: mul4_b = v_weight_arr[0][3];
//         'd31: mul4_b = v_weight_arr[0][3];
//         'd32: mul4_b = v_weight_arr[0][3];
//         'd33: mul4_b = v_weight_arr[1][3];
//         'd34: mul4_b = v_weight_arr[1][3];
//         'd35: mul4_b = v_weight_arr[1][3];
//         'd36: mul4_b = v_weight_arr[1][3];
//         'd37: mul4_b = v_weight_arr[1][3];
//         'd38: mul4_b = v_weight_arr[2][3];
//         'd39: mul4_b = v_weight_arr[2][3];
//         'd40: mul4_b = v_weight_arr[2][3];
//         'd41: mul4_b = v_weight_arr[2][3];
//         'd42: mul4_b = v_weight_arr[2][3];
//         'd43: mul4_b = v_weight_arr[3][3];
//         'd44: mul4_b = v_weight_arr[3][3];
//         'd45: mul4_b = v_weight_arr[3][3];
//         'd46: mul4_b = v_weight_arr[3][3];
//         'd47: mul4_b = v_weight_arr[3][3];
//         // score2
//         'd48: mul4_b = k_matrix[1][3];
//         'd49: mul4_b = k_matrix[0][3];
//         'd50: mul4_b = k_matrix[4][3];
//         // head_out 1
//         'd51: mul4_b = v_matrix[3][0];
//         'd52: mul4_b = v_matrix[3][1];
//         'd53: mul4_b = v_matrix[3][0];
//         'd54: mul4_b = v_matrix[3][1];
//         'd55: mul4_b = v_matrix[3][0];
//         'd56: mul4_b = v_matrix[3][1];
//         'd57: mul4_b = v_matrix[3][0];
//         'd58: mul4_b = v_matrix[3][1];
//         'd62: mul4_b = v_matrix[3][0];
//         'd63: mul4_b = v_matrix[3][1];
//         // head_out 2
//         'd67: mul4_b = v_matrix[3][2];
//         'd68: mul4_b = v_matrix[3][3];
//         'd72: mul4_b = v_matrix[3][2];
//         'd73: mul4_b = v_matrix[3][3];
//         'd77: mul4_b = v_matrix[3][2];
//         'd78: mul4_b = v_matrix[3][3];
//         'd82: mul4_b = v_matrix[3][2];
//         'd83: mul4_b = v_matrix[3][3];
//         'd87: mul4_b = v_matrix[3][2];
//         'd88: mul4_b = v_matrix[3][3];
//         // final
//         'd74: mul4_b = out_weight_arr[3][3];
//         'd75: mul4_b = out_weight_arr[1][3];
//         'd76: mul4_b = out_weight_arr[3][3];
//         'd79: mul4_b = out_weight_arr[0][3];
//         'd80: mul4_b = out_weight_arr[2][3];
//         'd84: mul4_b = out_weight_arr[0][3];
//         'd85: mul4_b = out_weight_arr[2][3];
//         'd89: mul4_b = out_weight_arr[0][3];
//         'd90: mul4_b = out_weight_arr[2][3];
//         default: mul4_b = 0;
//     endcase
// end

// always @(*) begin
//     add1_a = mul1_res;
//     add1_b = mul2_res;
//     add2_a = mul3_res;
//     add2_b = mul4_res;
//     add3_a = add1_res;
//     add3_b = add2_res;
// end

// always @(posedge clk or negedge rst_n) begin
//     if (!rst_n) begin
//         for (k = 0; k < 5; k = k + 1) begin
//             for (m = 0; m < 4; m = m + 1) begin
//                 k_matrix[k][m] <= 0;
//             end
//         end
//     end
//     else if (c_state == IDLE) begin
//         for (k = 0; k < 5; k = k + 1) begin
//             for (m = 0; m < 4; m = m + 1) begin
//                 k_matrix[k][m] <= 0;
//             end
//         end
//     end
//     else begin
//         case (counter)
//             'd4: k_matrix[0][0] <= add3_res;
//             'd8: k_matrix[1][0] <= add3_res;
//             'd9: k_matrix[0][1] <= add3_res;
//             'd10:k_matrix[1][1] <= add3_res;
//             'd12:k_matrix[2][0] <= add3_res;
//             'd13:k_matrix[0][2] <= add3_res;
//             'd14:k_matrix[1][2] <= add3_res;
//             'd15:k_matrix[2][1] <= add3_res;
//             'd16:k_matrix[3][0] <= add3_res;
//             'd17:k_matrix[0][3] <= add3_res;
//             'd18:k_matrix[1][3] <= add3_res;
//             'd19:k_matrix[2][2] <= add3_res;
//             'd20:k_matrix[4][0] <= add3_res;
//             'd21:k_matrix[2][3] <= add3_res;
//             'd22:k_matrix[3][1] <= add3_res;
//             'd23:k_matrix[4][1] <= add3_res;
//             'd24:k_matrix[3][2] <= add3_res;
//             'd25:k_matrix[4][2] <= add3_res;
//             'd26:k_matrix[3][3] <= add3_res;
//             'd27:k_matrix[4][3] <= add3_res;
//             default: begin
//                 for (k = 0; k < 5; k = k + 1) begin
//                     for (m = 0; m < 4; m = m + 1) begin
//                         k_matrix[k][m] <= k_matrix[k][m];
//                     end
//                 end
//             end
//         endcase
//     end
// end

// //=========================================//
// //           in_str x q_weight             //
// //=========================================//
// always @(*) begin
//     case (counter)
//         'd4:  mul5_a = in_str_arr[0][0];
//         'd8:  mul5_a = in_str_arr[1][0];
//         'd9:  mul5_a = in_str_arr[0][0];
//         'd10: mul5_a = in_str_arr[1][0];
//         'd12: mul5_a = in_str_arr[2][0];
//         'd13: mul5_a = in_str_arr[0][0];
//         'd14: mul5_a = in_str_arr[1][0];
//         'd15: mul5_a = in_str_arr[2][0];
//         'd16: mul5_a = in_str_arr[3][0];
//         'd17: mul5_a = in_str_arr[0][0];
//         'd18: mul5_a = in_str_arr[1][0];
//         'd19: mul5_a = in_str_arr[2][0];
//         'd20: mul5_a = in_str_arr[4][0];
//         'd21: mul5_a = in_str_arr[2][0];
//         'd22: mul5_a = in_str_arr[3][0];
//         'd23: mul5_a = in_str_arr[4][0];
//         'd24: mul5_a = in_str_arr[3][0];
//         'd25: mul5_a = in_str_arr[4][0];
//         'd26: mul5_a = in_str_arr[3][0];
//         'd27: mul5_a = in_str_arr[4][0];
//         // score1
//         'd28: mul5_a = q_matrix[0][0];
//         'd29: mul5_a = q_matrix[0][0];
//         'd30: mul5_a = q_matrix[0][0];
//         'd31: mul5_a = q_matrix[1][0];
//         'd32: mul5_a = q_matrix[1][0];
//         'd33: mul5_a = q_matrix[2][0];
//         'd34: mul5_a = q_matrix[2][0];
//         'd35: mul5_a = q_matrix[2][0];
//         'd36: mul5_a = q_matrix[3][0];
//         'd37: mul5_a = q_matrix[3][0];
//         'd38: mul5_a = q_matrix[4][0];
//         'd39: mul5_a = q_matrix[4][0];
//         'd40: mul5_a = q_matrix[4][0];
//         // score2
//         'd41: mul5_a = q_matrix[0][2];
//         'd42: mul5_a = q_matrix[0][2];
//         'd43: mul5_a = q_matrix[1][2];
//         'd44: mul5_a = q_matrix[1][2];
//         'd45: mul5_a = q_matrix[1][2];
//         'd46: mul5_a = q_matrix[2][2];
//         'd47: mul5_a = q_matrix[2][2];
//         'd48: mul5_a = q_matrix[3][2];
//         'd49: mul5_a = q_matrix[4][2];
//         // head_out 1
//         'd51: mul5_a = score_1_matrix[0][4];
//         'd52: mul5_a = score_1_matrix[0][4];
//         'd53: mul5_a = score_1_matrix[1][4];
//         'd54: mul5_a = score_1_matrix[1][4];
//         'd55: mul5_a = score_1_matrix[2][4];
//         'd56: mul5_a = score_1_matrix[2][4];
//         'd57: mul5_a = score_1_matrix[3][4];
//         'd58: mul5_a = score_1_matrix[3][4];
//         'd62: mul5_a = score_1_matrix[4][4];
//         'd63: mul5_a = score_1_matrix[4][4];
//         // head_out 2
//         'd67: mul5_a = score_2_matrix[0][4];
//         'd68: mul5_a = score_2_matrix[0][4];
//         'd72: mul5_a = score_2_matrix[1][4];
//         'd73: mul5_a = score_2_matrix[1][4];
//         'd77: mul5_a = score_2_matrix[2][4];
//         'd78: mul5_a = score_2_matrix[2][4];
//         'd82: mul5_a = score_2_matrix[3][4];
//         'd83: mul5_a = score_2_matrix[3][4];
//         'd87: mul5_a = score_2_matrix[4][4];
//         'd88: mul5_a = score_2_matrix[4][4];
//         // final res
//         'd69: mul5_a = head_out[0][0];
//         'd70: mul5_a = head_out[0][0];
//         'd71: mul5_a = head_out[0][0];
//         'd74: mul5_a = head_out[1][0];
//         'd75: mul5_a = head_out[1][0];
//         'd79: mul5_a = head_out[2][0];
//         'd80: mul5_a = head_out[2][0];
//         'd84: mul5_a = head_out[3][0];
//         'd85: mul5_a = head_out[3][0];
//         'd89: mul5_a = head_out[4][0];
//         'd90: mul5_a = head_out[4][0];
//         default: mul5_a = 0;
//     endcase
// end

// always @(*) begin
//     case (counter)
//         'd4:  mul5_b = q_weight_arr[0][0];
//         'd8:  mul5_b = q_weight_arr[0][0];
//         'd9:  mul5_b = q_weight_arr[1][0];
//         'd10: mul5_b = q_weight_arr[1][0];
//         'd12: mul5_b = q_weight_arr[0][0];
//         'd13: mul5_b = q_weight_arr[2][0];
//         'd14: mul5_b = q_weight_arr[2][0];
//         'd15: mul5_b = q_weight_arr[1][0];
//         'd16: mul5_b = q_weight_arr[0][0];
//         'd17: mul5_b = q_weight_arr[3][0];
//         'd18: mul5_b = q_weight_arr[3][0];
//         'd19: mul5_b = q_weight_arr[2][0];
//         'd20: mul5_b = q_weight_arr[0][0];
//         'd21: mul5_b = q_weight_arr[3][0];
//         'd22: mul5_b = q_weight_arr[1][0];
//         'd23: mul5_b = q_weight_arr[1][0];
//         'd24: mul5_b = q_weight_arr[2][0];
//         'd25: mul5_b = q_weight_arr[2][0];
//         'd26: mul5_b = q_weight_arr[3][0];
//         'd27: mul5_b = q_weight_arr[3][0];
//         // score1
//         'd28: mul5_b = k_matrix[0][0];
//         'd29: mul5_b = k_matrix[2][0];
//         'd30: mul5_b = k_matrix[4][0];
//         'd31: mul5_b = k_matrix[1][0];
//         'd32: mul5_b = k_matrix[3][0];
//         'd33: mul5_b = k_matrix[0][0];
//         'd34: mul5_b = k_matrix[2][0];
//         'd35: mul5_b = k_matrix[4][0];
//         'd36: mul5_b = k_matrix[1][0];
//         'd37: mul5_b = k_matrix[3][0];
//         'd38: mul5_b = k_matrix[0][0];
//         'd39: mul5_b = k_matrix[2][0];
//         'd40: mul5_b = k_matrix[4][0];
//         // score2
//         'd41: mul5_b = k_matrix[1][2];
//         'd42: mul5_b = k_matrix[3][2];
//         'd43: mul5_b = k_matrix[0][2];
//         'd44: mul5_b = k_matrix[2][2];
//         'd45: mul5_b = k_matrix[4][2];
//         'd46: mul5_b = k_matrix[1][2];
//         'd47: mul5_b = k_matrix[3][2];
//         'd48: mul5_b = k_matrix[2][2];
//         'd49: mul5_b = k_matrix[1][2];
//         // head_out 1
//         'd51: mul5_b = v_matrix[4][0];
//         'd52: mul5_b = v_matrix[4][1];
//         'd53: mul5_b = v_matrix[4][0];
//         'd54: mul5_b = v_matrix[4][1];
//         'd55: mul5_b = v_matrix[4][0];
//         'd56: mul5_b = v_matrix[4][1];
//         'd57: mul5_b = v_matrix[4][0];
//         'd58: mul5_b = v_matrix[4][1];
//         'd62: mul5_b = v_matrix[4][0];
//         'd63: mul5_b = v_matrix[4][1];
//         // head_out 2
//         'd67: mul5_b = v_matrix[4][2];
//         'd68: mul5_b = v_matrix[4][3];
//         'd72: mul5_b = v_matrix[4][2];
//         'd73: mul5_b = v_matrix[4][3];
//         'd77: mul5_b = v_matrix[4][2];
//         'd78: mul5_b = v_matrix[4][3];
//         'd82: mul5_b = v_matrix[4][2];
//         'd83: mul5_b = v_matrix[4][3]; 
//         'd87: mul5_b = v_matrix[4][2];
//         'd88: mul5_b = v_matrix[4][3];
//         // final res
//         'd69: mul5_b = out_weight_arr[0][0];
//         'd70: mul5_b = out_weight_arr[1][0];
//         'd71: mul5_b = out_weight_arr[2][0];
//         'd74: mul5_b = out_weight_arr[0][0];
//         'd75: mul5_b = out_weight_arr[2][0];
//         'd79: mul5_b = out_weight_arr[1][0];
//         'd80: mul5_b = out_weight_arr[3][0];
//         'd84: mul5_b = out_weight_arr[1][0];
//         'd85: mul5_b = out_weight_arr[3][0];
//         'd89: mul5_b = out_weight_arr[1][0];
//         'd90: mul5_b = out_weight_arr[3][0];
//         default: mul5_b = 0;
//     endcase
// end

// always @(*) begin
//     case (counter)
//         'd4:  mul6_a = in_str_arr[0][1];
//         'd8:  mul6_a = in_str_arr[1][1];
//         'd9:  mul6_a = in_str_arr[0][1];
//         'd10: mul6_a = in_str_arr[1][1];
//         'd12: mul6_a = in_str_arr[2][1];
//         'd13: mul6_a = in_str_arr[0][1];
//         'd14: mul6_a = in_str_arr[1][1];
//         'd15: mul6_a = in_str_arr[2][1];
//         'd16: mul6_a = in_str_arr[3][1];
//         'd17: mul6_a = in_str_arr[0][1];
//         'd18: mul6_a = in_str_arr[1][1];
//         'd19: mul6_a = in_str_arr[2][1];
//         'd20: mul6_a = in_str_arr[4][1];
//         'd21: mul6_a = in_str_arr[2][1];
//         'd22: mul6_a = in_str_arr[3][1];
//         'd23: mul6_a = in_str_arr[4][1];
//         'd24: mul6_a = in_str_arr[3][1];
//         'd25: mul6_a = in_str_arr[4][1];
//         'd26: mul6_a = in_str_arr[3][1];
//         'd27: mul6_a = in_str_arr[4][1];
//         // score1
//         'd28: mul6_a = q_matrix[0][1];
//         'd29: mul6_a = q_matrix[0][1];
//         'd30: mul6_a = q_matrix[0][1];
//         'd31: mul6_a = q_matrix[1][1];
//         'd32: mul6_a = q_matrix[1][1];
//         'd33: mul6_a = q_matrix[2][1];
//         'd34: mul6_a = q_matrix[2][1];
//         'd35: mul6_a = q_matrix[2][1];
//         'd36: mul6_a = q_matrix[3][1];
//         'd37: mul6_a = q_matrix[3][1];
//         'd38: mul6_a = q_matrix[4][1];
//         'd39: mul6_a = q_matrix[4][1];
//         'd40: mul6_a = q_matrix[4][1];
//         // score2
//         'd41: mul6_a = q_matrix[0][3];
//         'd42: mul6_a = q_matrix[0][3];
//         'd43: mul6_a = q_matrix[1][3];
//         'd44: mul6_a = q_matrix[1][3];
//         'd45: mul6_a = q_matrix[1][3];
//         'd46: mul6_a = q_matrix[2][3];
//         'd47: mul6_a = q_matrix[2][3];
//         'd48: mul6_a = q_matrix[3][3];
//         'd49: mul6_a = q_matrix[4][3];
//         // final res
//         'd69: mul6_a = head_out[0][1];
//         'd70: mul6_a = head_out[0][1];
//         'd71: mul6_a = head_out[0][1];
//         'd74: mul6_a = head_out[1][1];
//         'd75: mul6_a = head_out[1][1];
//         'd79: mul6_a = head_out[2][1];
//         'd80: mul6_a = head_out[2][1];
//         'd84: mul6_a = head_out[3][1];
//         'd85: mul6_a = head_out[3][1];
//         'd89: mul6_a = head_out[4][1];
//         'd90: mul6_a = head_out[4][1];
//         default: mul6_a = 0;
//     endcase
// end

// always @(*) begin
//     case (counter)
//         'd4:  mul6_b = q_weight_arr[0][1];
//         'd8:  mul6_b = q_weight_arr[0][1];
//         'd9:  mul6_b = q_weight_arr[1][1];
//         'd10: mul6_b = q_weight_arr[1][1];
//         'd12: mul6_b = q_weight_arr[0][1];
//         'd13: mul6_b = q_weight_arr[2][1];
//         'd14: mul6_b = q_weight_arr[2][1];
//         'd15: mul6_b = q_weight_arr[1][1];
//         'd16: mul6_b = q_weight_arr[0][1];
//         'd17: mul6_b = q_weight_arr[3][1];
//         'd18: mul6_b = q_weight_arr[3][1];
//         'd19: mul6_b = q_weight_arr[2][1];
//         'd20: mul6_b = q_weight_arr[0][1];
//         'd21: mul6_b = q_weight_arr[3][1];
//         'd22: mul6_b = q_weight_arr[1][1];
//         'd23: mul6_b = q_weight_arr[1][1];
//         'd24: mul6_b = q_weight_arr[2][1];
//         'd25: mul6_b = q_weight_arr[2][1];
//         'd26: mul6_b = q_weight_arr[3][1];
//         'd27: mul6_b = q_weight_arr[3][1];
//         // score1
//         'd28: mul6_b = k_matrix[0][1];
//         'd29: mul6_b = k_matrix[2][1];
//         'd30: mul6_b = k_matrix[4][1];
//         'd31: mul6_b = k_matrix[1][1];
//         'd32: mul6_b = k_matrix[3][1];
//         'd33: mul6_b = k_matrix[0][1];
//         'd34: mul6_b = k_matrix[2][1];
//         'd35: mul6_b = k_matrix[4][1];
//         'd36: mul6_b = k_matrix[1][1];
//         'd37: mul6_b = k_matrix[3][1];
//         'd38: mul6_b = k_matrix[0][1];
//         'd39: mul6_b = k_matrix[2][1];
//         'd40: mul6_b = k_matrix[4][1];
//         // score2
//         'd41: mul6_b = k_matrix[1][3];
//         'd42: mul6_b = k_matrix[3][3];
//         'd43: mul6_b = k_matrix[0][3];
//         'd44: mul6_b = k_matrix[2][3];
//         'd45: mul6_b = k_matrix[4][3];
//         'd46: mul6_b = k_matrix[1][3];
//         'd47: mul6_b = k_matrix[3][3];
//         'd48: mul6_b = k_matrix[2][3];
//         'd49: mul6_b = k_matrix[1][3];
//         // final res
//         'd69: mul6_b = out_weight_arr[0][1];
//         'd70: mul6_b = out_weight_arr[1][1];
//         'd71: mul6_b = out_weight_arr[2][1];
//         'd74: mul6_b = out_weight_arr[0][1];
//         'd75: mul6_b = out_weight_arr[2][1];
//         'd79: mul6_b = out_weight_arr[1][1];
//         'd80: mul6_b = out_weight_arr[3][1];
//         'd84: mul6_b = out_weight_arr[1][1];
//         'd85: mul6_b = out_weight_arr[3][1];
//         'd89: mul6_b = out_weight_arr[1][1];
//         'd90: mul6_b = out_weight_arr[3][1];
//         default: mul6_b = 0;
//     endcase
// end

// always @(*) begin
//     case (counter)
//         'd4:  mul7_a = in_str_arr[0][2];
//         'd8:  mul7_a = in_str_arr[1][2];
//         'd9:  mul7_a = in_str_arr[0][2];
//         'd10: mul7_a = in_str_arr[1][2];
//         'd12: mul7_a = in_str_arr[2][2];
//         'd13: mul7_a = in_str_arr[0][2];
//         'd14: mul7_a = in_str_arr[1][2];
//         'd15: mul7_a = in_str_arr[2][2];
//         'd16: mul7_a = in_str_arr[3][2];
//         'd17: mul7_a = in_str_arr[0][2];
//         'd18: mul7_a = in_str_arr[1][2];
//         'd19: mul7_a = in_str_arr[2][2];
//         'd20: mul7_a = in_str_arr[4][2];
//         'd21: mul7_a = in_str_arr[2][2];
//         'd22: mul7_a = in_str_arr[3][2];
//         'd23: mul7_a = in_str_arr[4][2];
//         'd24: mul7_a = in_str_arr[3][2];
//         'd25: mul7_a = in_str_arr[4][2];
//         'd26: mul7_a = in_str_arr[3][2];
//         'd27: mul7_a = in_str_arr[4][2];
//         // score1
//         'd28: mul7_a = q_matrix[0][0];
//         'd29: mul7_a = q_matrix[0][0];
//         'd30: mul7_a = q_matrix[1][0];
//         'd31: mul7_a = q_matrix[1][0];
//         'd32: mul7_a = q_matrix[1][0];
//         'd33: mul7_a = q_matrix[2][0];
//         'd34: mul7_a = q_matrix[2][0];
//         'd35: mul7_a = q_matrix[3][0];
//         'd36: mul7_a = q_matrix[3][0];
//         'd37: mul7_a = q_matrix[3][0];
//         'd38: mul7_a = q_matrix[4][0];
//         'd39: mul7_a = q_matrix[4][0];
//         // score2
//         'd40: mul7_a = q_matrix[0][2];
//         'd41: mul7_a = q_matrix[0][2];
//         'd42: mul7_a = q_matrix[0][2];
//         'd43: mul7_a = q_matrix[1][2];
//         'd44: mul7_a = q_matrix[1][2];
//         'd45: mul7_a = q_matrix[2][2];
//         'd46: mul7_a = q_matrix[2][2];
//         'd47: mul7_a = q_matrix[2][2];
//         'd48: mul7_a = q_matrix[3][2];
//         'd49: mul7_a = q_matrix[4][2];
//         // final res
//         'd69: mul7_a = head_out[0][2];
//         'd70: mul7_a = head_out[0][2];
//         'd71: mul7_a = head_out[0][2];
//         'd74: mul7_a = head_out[1][2];
//         'd75: mul7_a = head_out[1][2];
//         'd79: mul7_a = head_out[2][2];
//         'd80: mul7_a = head_out[2][2];
//         'd84: mul7_a = head_out[3][2];
//         'd85: mul7_a = head_out[3][2];
//         'd89: mul7_a = head_out[4][2];
//         'd90: mul7_a = head_out[4][2];
//         default: mul7_a = 0;
//     endcase
// end

// always @(*) begin
//     case (counter)
//         'd4:  mul7_b = q_weight_arr[0][2];
//         'd8:  mul7_b = q_weight_arr[0][2];
//         'd9:  mul7_b = q_weight_arr[1][2];
//         'd10: mul7_b = q_weight_arr[1][2];
//         'd12: mul7_b = q_weight_arr[0][2];
//         'd13: mul7_b = q_weight_arr[2][2];
//         'd14: mul7_b = q_weight_arr[2][2];
//         'd15: mul7_b = q_weight_arr[1][2];
//         'd16: mul7_b = q_weight_arr[0][2];
//         'd17: mul7_b = q_weight_arr[3][2];
//         'd18: mul7_b = q_weight_arr[3][2];
//         'd19: mul7_b = q_weight_arr[2][2];
//         'd20: mul7_b = q_weight_arr[0][2];
//         'd21: mul7_b = q_weight_arr[3][2];
//         'd22: mul7_b = q_weight_arr[1][2];
//         'd23: mul7_b = q_weight_arr[1][2];
//         'd24: mul7_b = q_weight_arr[2][2];
//         'd25: mul7_b = q_weight_arr[2][2];
//         'd26: mul7_b = q_weight_arr[3][2];
//         'd27: mul7_b = q_weight_arr[3][2];

//         'd28: mul7_b = k_matrix[1][0];
//         'd29: mul7_b = k_matrix[3][0];
//         'd30: mul7_b = k_matrix[0][0];
//         'd31: mul7_b = k_matrix[2][0];
//         'd32: mul7_b = k_matrix[4][0];
//         'd33: mul7_b = k_matrix[1][0];
//         'd34: mul7_b = k_matrix[3][0];
//         'd35: mul7_b = k_matrix[0][0];
//         'd36: mul7_b = k_matrix[2][0];
//         'd37: mul7_b = k_matrix[4][0];
//         'd38: mul7_b = k_matrix[1][0];
//         'd39: mul7_b = k_matrix[3][0];
//         // score2
//         'd40: mul7_b = k_matrix[0][2];
//         'd41: mul7_b = k_matrix[2][2];
//         'd42: mul7_b = k_matrix[4][2];
//         'd43: mul7_b = k_matrix[1][2];
//         'd44: mul7_b = k_matrix[3][2];
//         'd45: mul7_b = k_matrix[0][2];
//         'd46: mul7_b = k_matrix[2][2];
//         'd47: mul7_b = k_matrix[4][2];
//         'd48: mul7_b = k_matrix[3][2];
//         'd49: mul7_b = k_matrix[2][2];
//         // final res
//         'd69: mul7_b = out_weight_arr[0][2];
//         'd70: mul7_b = out_weight_arr[1][2];
//         'd71: mul7_b = out_weight_arr[2][2];
//         'd74: mul7_b = out_weight_arr[0][2];
//         'd75: mul7_b = out_weight_arr[2][2];
//         'd79: mul7_b = out_weight_arr[1][2];
//         'd80: mul7_b = out_weight_arr[3][2];
//         'd84: mul7_b = out_weight_arr[1][2];
//         'd85: mul7_b = out_weight_arr[3][2];
//         'd89: mul7_b = out_weight_arr[1][2];
//         'd90: mul7_b = out_weight_arr[3][2];
//         default: mul7_b = 0;
//     endcase
// end

// always @(*) begin
//     case (counter)
//         'd4:  mul8_a = in_str_arr[0][3];
//         'd8:  mul8_a = in_str_arr[1][3];
//         'd9:  mul8_a = in_str_arr[0][3];
//         'd10: mul8_a = in_str_arr[1][3];
//         'd12: mul8_a = in_str_arr[2][3];
//         'd13: mul8_a = in_str_arr[0][3];
//         'd14: mul8_a = in_str_arr[1][3];
//         'd15: mul8_a = in_str_arr[2][3];
//         'd16: mul8_a = in_str_arr[3][3];
//         'd17: mul8_a = in_str_arr[0][3];
//         'd18: mul8_a = in_str_arr[1][3];
//         'd19: mul8_a = in_str_arr[2][3];
//         'd20: mul8_a = in_str_arr[4][3];
//         'd21: mul8_a = in_str_arr[2][3];
//         'd22: mul8_a = in_str_arr[3][3];
//         'd23: mul8_a = in_str_arr[4][3];
//         'd24: mul8_a = in_str_arr[3][3];
//         'd25: mul8_a = in_str_arr[4][3];
//         'd26: mul8_a = in_str_arr[3][3];
//         'd27: mul8_a = in_str_arr[4][3];

//         'd28: mul8_a = q_matrix[0][1];
//         'd29: mul8_a = q_matrix[0][1];
//         'd30: mul8_a = q_matrix[1][1];
//         'd31: mul8_a = q_matrix[1][1];
//         'd32: mul8_a = q_matrix[1][1];
//         'd33: mul8_a = q_matrix[2][1];
//         'd34: mul8_a = q_matrix[2][1];
//         'd35: mul8_a = q_matrix[3][1];
//         'd36: mul8_a = q_matrix[3][1];
//         'd37: mul8_a = q_matrix[3][1];
//         'd38: mul8_a = q_matrix[4][1];
//         'd39: mul8_a = q_matrix[4][1];
//         // score2
//         'd40: mul8_a = q_matrix[0][3];
//         'd41: mul8_a = q_matrix[0][3];
//         'd42: mul8_a = q_matrix[0][3];
//         'd43: mul8_a = q_matrix[1][3];
//         'd44: mul8_a = q_matrix[1][3];
//         'd45: mul8_a = q_matrix[2][3];
//         'd46: mul8_a = q_matrix[2][3];
//         'd47: mul8_a = q_matrix[2][3];
//         'd48: mul8_a = q_matrix[3][3];
//         'd49: mul8_a = q_matrix[4][3];
//         // final res
//         'd69: mul8_a = head_out[0][3];
//         'd70: mul8_a = head_out[0][3];
//         'd71: mul8_a = head_out[0][3];
//         'd74: mul8_a = head_out[1][3];
//         'd75: mul8_a = head_out[1][3];
//         'd79: mul8_a = head_out[2][3];
//         'd80: mul8_a = head_out[2][3];
//         'd84: mul8_a = head_out[3][3];
//         'd85: mul8_a = head_out[3][3];
//         'd89: mul8_a = head_out[4][3];
//         'd90: mul8_a = head_out[4][3];
//         default: mul8_a = 0;
//     endcase
// end

// always @(*) begin
//     case (counter)
//         'd4:  mul8_b = q_weight_arr[0][3];
//         'd8:  mul8_b = q_weight_arr[0][3];
//         'd9:  mul8_b = q_weight_arr[1][3];
//         'd10: mul8_b = q_weight_arr[1][3];
//         'd12: mul8_b = q_weight_arr[0][3];
//         'd13: mul8_b = q_weight_arr[2][3];
//         'd14: mul8_b = q_weight_arr[2][3];
//         'd15: mul8_b = q_weight_arr[1][3];
//         'd16: mul8_b = q_weight_arr[0][3];
//         'd17: mul8_b = q_weight_arr[3][3];
//         'd18: mul8_b = q_weight_arr[3][3];
//         'd19: mul8_b = q_weight_arr[2][3];
//         'd20: mul8_b = q_weight_arr[0][3];
//         'd21: mul8_b = q_weight_arr[3][3];
//         'd22: mul8_b = q_weight_arr[1][3];
//         'd23: mul8_b = q_weight_arr[1][3];
//         'd24: mul8_b = q_weight_arr[2][3];
//         'd25: mul8_b = q_weight_arr[2][3];
//         'd26: mul8_b = q_weight_arr[3][3];
//         'd27: mul8_b = q_weight_arr[3][3];

//         'd28: mul8_b = k_matrix[1][1];
//         'd29: mul8_b = k_matrix[3][1];
//         'd30: mul8_b = k_matrix[0][1];
//         'd31: mul8_b = k_matrix[2][1];
//         'd32: mul8_b = k_matrix[4][1];
//         'd33: mul8_b = k_matrix[1][1];
//         'd34: mul8_b = k_matrix[3][1];
//         'd35: mul8_b = k_matrix[0][1];
//         'd36: mul8_b = k_matrix[2][1];
//         'd37: mul8_b = k_matrix[4][1];
//         'd38: mul8_b = k_matrix[1][1];
//         'd39: mul8_b = k_matrix[3][1];
//         // score2
//         'd40: mul8_b = k_matrix[0][3];
//         'd41: mul8_b = k_matrix[2][3];
//         'd42: mul8_b = k_matrix[4][3];
//         'd43: mul8_b = k_matrix[1][3];
//         'd44: mul8_b = k_matrix[3][3];
//         'd45: mul8_b = k_matrix[0][3];
//         'd46: mul8_b = k_matrix[2][3];
//         'd47: mul8_b = k_matrix[4][3];
//         'd48: mul8_b = k_matrix[3][3];
//         'd49: mul8_b = k_matrix[2][3];
//         // final res
//         'd69: mul8_b = out_weight_arr[0][3];
//         'd70: mul8_b = out_weight_arr[1][3];
//         'd71: mul8_b = out_weight_arr[2][3];
//         'd74: mul8_b = out_weight_arr[0][3];
//         'd75: mul8_b = out_weight_arr[2][3];
//         'd79: mul8_b = out_weight_arr[1][3];
//         'd80: mul8_b = out_weight_arr[3][3];
//         'd84: mul8_b = out_weight_arr[1][3];
//         'd85: mul8_b = out_weight_arr[3][3];
//         'd89: mul8_b = out_weight_arr[1][3];
//         'd90: mul8_b = out_weight_arr[3][3];
//         default: mul8_b = 0;
//     endcase
// end

// always @(*) begin
//     add6_a = add4_res;
//     add6_b = add5_res;
// end

// always @(*) begin
//     if (counter > 50 && counter < 69) begin
//         add4_a = add1_res;
//         add4_b = add2_res;
//     end
//     else if ((counter == 72) || (counter == 73) || (counter == 77) || (counter == 78) || (counter == 82) || (counter == 83) || (counter == 87) || (counter == 88)) begin
//         add4_a = add1_res;
//         add4_b = add2_res;
//     end
//     else begin
//         add4_a = mul5_res; 
//         add4_b = mul6_res;
//     end
// end

// always @(*) begin
//     if (counter > 50 && counter < 69) begin
//         add5_a = add4_res;
//         add5_b = mul5_res;
//     end
//     else if ((counter == 72) || (counter == 73) || (counter == 77) || (counter == 78) || (counter == 82) || (counter == 83) || (counter == 87) || (counter == 88)) begin
//         add5_a = add4_res;
//         add5_b = mul5_res;
//     end
//     else begin
//         add5_a = mul7_res; 
//         add5_b = mul8_res;
//     end
// end

// always @(posedge clk or negedge rst_n) begin
//     if (!rst_n) begin
//         for (k = 0; k < 5; k = k + 1) begin
//             for (m = 0; m < 4; m = m + 1) begin
//                 q_matrix[k][m] <= 0;
//             end
//         end
//     end
//     else if (c_state == IDLE) begin
//         for (k = 0; k < 5; k = k + 1) begin
//             for (m = 0; m < 4; m = m + 1) begin
//                 q_matrix[k][m] <= 0;
//             end
//         end
//     end
//     else begin
//         case (counter)
//             'd4: q_matrix[0][0] <= add6_res;
//             'd8: q_matrix[1][0] <= add6_res;
//             'd9: q_matrix[0][1] <= add6_res;
//             'd10:q_matrix[1][1] <= add6_res;
//             'd12:q_matrix[2][0] <= add6_res;
//             'd13:q_matrix[0][2] <= add6_res;
//             'd14:q_matrix[1][2] <= add6_res;
//             'd15:q_matrix[2][1] <= add6_res;
//             'd16:q_matrix[3][0] <= add6_res;
//             'd17:q_matrix[0][3] <= add6_res;
//             'd18:q_matrix[1][3] <= add6_res;
//             'd19:q_matrix[2][2] <= add6_res;
//             'd20:q_matrix[4][0] <= add6_res;
//             'd21:q_matrix[2][3] <= add6_res;
//             'd22:q_matrix[3][1] <= add6_res;
//             'd23:q_matrix[4][1] <= add6_res;
//             'd24:q_matrix[3][2] <= add6_res;
//             'd25:q_matrix[4][2] <= add6_res;
//             'd26:q_matrix[3][3] <= add6_res;
//             'd27:q_matrix[4][3] <= add6_res;
//             default: begin
//                 for (k = 0; k < 5; k = k + 1) begin
//                     for (m = 0; m < 4; m = m + 1) begin
//                         q_matrix[k][m] <= q_matrix[k][m];
//                     end
//                 end
//             end
//         endcase
//     end
// end

// //=========================================//
// //           in_str x v_weight             //
// //=========================================//
// always @(posedge clk or negedge rst_n) begin
//     if (!rst_n) begin
//         for (k = 0; k < 5; k = k + 1) begin
//             for (m = 0; m < 4; m = m + 1) begin
//                 v_matrix[k][m] <= 0;
//             end
//         end
//     end
//     else if (c_state == IDLE) begin
//         for (k = 0; k < 5; k = k + 1) begin
//             for (m = 0; m < 4; m = m + 1) begin
//                 v_matrix[k][m] <= 0;
//             end
//         end
//     end
//     else begin
//         case (counter)
//             'd28: v_matrix[0][0] <= add3_res;
//             'd29: v_matrix[1][0] <= add3_res;
//             'd30: v_matrix[2][0] <= add3_res;
//             'd31: v_matrix[3][0] <= add3_res;
//             'd32: v_matrix[4][0] <= add3_res;
//             'd33: v_matrix[0][1] <= add3_res;
//             'd34: v_matrix[1][1] <= add3_res;
//             'd35: v_matrix[2][1] <= add3_res;
//             'd36: v_matrix[3][1] <= add3_res;
//             'd37: v_matrix[4][1] <= add3_res;
//             'd38: v_matrix[0][2] <= add3_res;
//             'd39: v_matrix[1][2] <= add3_res;
//             'd40: v_matrix[2][2] <= add3_res;
//             'd41: v_matrix[3][2] <= add3_res;
//             'd42: v_matrix[4][2] <= add3_res;
//             'd43: v_matrix[0][3] <= add3_res;
//             'd44: v_matrix[1][3] <= add3_res;
//             'd45: v_matrix[2][3] <= add3_res;
//             'd46: v_matrix[3][3] <= add3_res;
//             'd47: v_matrix[4][3] <= add3_res;
//             default: begin
//                 for (k = 0; k < 5; k = k + 1) begin
//                     for (m = 0; m < 4; m = m + 1) begin
//                         v_matrix[k][m] <= v_matrix[k][m];
//                     end
//                 end
//             end
//         endcase
//     end
// end

// //=========================================//
// //                score_1                  //
// //=========================================//
// always @(posedge clk or negedge rst_n) begin
//     if (!rst_n) begin
//         for (k = 0; k < 5; k = k + 1) begin
//             for (m = 0; m < 5; m = m + 1) begin
//                 score_1_matrix[k][m] <= 0;
//             end
//         end
//     end
//     else if (c_state == IDLE) begin
//         for (k = 0; k < 5; k = k + 1) begin
//             for (m = 0; m < 5; m = m + 1) begin
//                 score_1_matrix[k][m] <= 0;
//             end
//         end
//     end
//     else begin
//         case (counter)
//             'd28: begin
//                 score_1_matrix[0][0] <= add4_res;
//                 score_1_matrix[0][1] <= add5_res;
//             end
//             'd29: begin
//                 score_1_matrix[0][2] <= add4_res;
//                 score_1_matrix[0][3] <= add5_res;
//             end
//             'd30: begin
//                 score_1_matrix[0][4] <= add4_res;
//                 score_1_matrix[1][0] <= add5_res;
//                 score_1_matrix[0][0] <= exp1_res;
//                 // if (row == 0 && col == 1) 
//                 //     score_1_matrix[0][0] <= exp1_res;
//             end
//             'd31: begin
//                 score_1_matrix[1][1] <= add4_res;
//                 score_1_matrix[1][2] <= add5_res;
//                 score_1_matrix[0][1] <= exp1_res;
//                 // if (row == 0 && col == 2) 
//                 //     score_1_matrix[0][1] <= exp1_res;
//             end
//             'd32: begin
//                 score_1_matrix[1][3] <= add4_res;
//                 score_1_matrix[1][4] <= add5_res;
//                 score_1_matrix[0][2] <= exp1_res;
//                 // if (row == 0 && col == 3) 
//                 //     score_1_matrix[0][2] <= exp1_res;
//             end
//             'd33: begin
//                 score_1_matrix[2][0] <= add4_res;
//                 score_1_matrix[2][1] <= add5_res;
//                 score_1_matrix[0][3] <= exp1_res;
//                 // if (row == 0 && col == 4) 
//                 //     score_1_matrix[0][3] <= exp1_res;
//             end
//             'd34: begin
//                 score_1_matrix[2][2] <= add4_res;
//                 score_1_matrix[2][3] <= add5_res;
//                 score_1_matrix[0][4] <= exp1_res;
//                 // if (row == 1 && col == 0) 
//                 //     score_1_matrix[0][4] <= exp1_res;
//             end
//             'd35: begin
//                 score_1_matrix[2][4] <= add4_res;
//                 score_1_matrix[3][0] <= add5_res;
//                 score_1_matrix[1][0] <= exp1_res;
//                 // if (row == 1 && col == 1) 
//                 //     score_1_matrix[1][0] <= exp1_res;
//             end
//             'd36: begin
//                 score_1_matrix[3][1] <= add4_res;
//                 score_1_matrix[3][2] <= add5_res;
//                 score_1_matrix[1][1] <= exp1_res;
//                 // if (row == 1 && col == 2) 
//                 //     score_1_matrix[1][1] <= exp1_res;
//             end
//             'd37: begin
//                 score_1_matrix[3][3] <= add4_res;
//                 score_1_matrix[3][4] <= add5_res;
//                 score_1_matrix[1][2] <= exp1_res;
//                 score_1_matrix[0][0] <= div2_res;
//                 // if (row == 1 && col == 3) 
//                 //     score_1_matrix[1][2] <= exp1_res;
//             end
//             'd38: begin
//                 score_1_matrix[4][0] <= add4_res;
//                 score_1_matrix[4][1] <= add5_res;
//                 score_1_matrix[1][3] <= exp1_res;
//                 score_1_matrix[0][1] <= div2_res;
//                 // if (row == 1 && col == 4) 
//                 //     score_1_matrix[1][3] <= exp1_res;
//             end
//             'd39: begin
//                 score_1_matrix[4][2] <= add4_res;
//                 score_1_matrix[4][3] <= add5_res;
//                 score_1_matrix[1][4] <= exp1_res;
//                 score_1_matrix[0][2] <= div2_res;
//                 // if (row == 2 && col == 0) 
//                 //     score_1_matrix[1][4] <= exp1_res;
//             end
//             'd40: begin
//                 score_1_matrix[4][4] <= add4_res;
//                 score_1_matrix[2][0] <= exp1_res;
//                 score_1_matrix[0][3] <= div2_res;
//                 // if (row == 2 && col == 1) 
//                 //     score_1_matrix[2][0] <= exp1_res;
//             end
//             'd41:begin
//                 score_1_matrix[2][1] <= exp1_res;
//                 score_1_matrix[0][4] <= div2_res;
//             end
//             'd42:begin
//                 score_1_matrix[2][2] <= exp1_res;
//                 score_1_matrix[1][0] <= div2_res;
//             end
//             'd43:begin
//                 score_1_matrix[2][3] <= exp1_res;
//                 score_1_matrix[1][1] <= div2_res;
//             end
//             'd44:begin
//                 score_1_matrix[2][4] <= exp1_res;
//                 score_1_matrix[1][2] <= div2_res;
//             end
//             'd45:begin
//                 score_1_matrix[3][0] <= exp1_res;
//                 score_1_matrix[1][3] <= div2_res;
//             end
//             'd46:begin
//                 score_1_matrix[3][1] <= exp1_res;
//                 score_1_matrix[1][4] <= div2_res;
//             end
//             'd47:begin
//                 score_1_matrix[3][2] <= exp1_res;
//                 score_1_matrix[2][0] <= div2_res;
//             end
//             'd48:begin
//                 score_1_matrix[3][3] <= exp1_res;
//                 score_1_matrix[2][1] <= div2_res;
//             end
//             'd49:begin
//                 score_1_matrix[3][4] <= exp1_res;
//                 score_1_matrix[2][2] <= div2_res;
//             end
//             'd50:begin
//                 score_1_matrix[4][0] <= exp1_res;
//                 score_1_matrix[2][3] <= div2_res;
//             end
//             'd51:begin
//                 score_1_matrix[4][1] <= exp1_res;
//                 score_1_matrix[2][4] <= div2_res;
//             end
//             'd52:begin
//                 score_1_matrix[4][2] <= exp1_res;
//                 score_1_matrix[3][0] <= div2_res;
//             end
//             'd53:begin
//                 score_1_matrix[4][3] <= exp1_res;
//                 score_1_matrix[3][1] <= div2_res;
//             end
//             'd54:begin
//                 score_1_matrix[4][4] <= exp1_res;
//                 score_1_matrix[3][2] <= div2_res;
//             end
//             'd55:begin
//                 score_1_matrix[3][3] <= div2_res;
//             end
//             'd56:begin
//                 score_1_matrix[3][4] <= div2_res;
//             end
//             'd57:begin
//                 score_1_matrix[4][0] <= div2_res;
//             end
//             'd58:begin
//                 score_1_matrix[4][1] <= div2_res;
//             end
//             'd59:begin
//                 score_1_matrix[4][2] <= div2_res;
//             end
//             'd60:begin
//                 score_1_matrix[4][3] <= div2_res;
//             end
//             'd61:begin
//                 score_1_matrix[4][4] <= div2_res;
//             end
//             default: begin
//                 for (k = 0; k < 5; k = k + 1) begin
//                     for (m = 0; m < 5; m = m + 1) begin
//                         score_1_matrix[k][m] <= score_1_matrix[k][m];
//                     end
//                 end
//             end 
//         endcase
//     end
// end

// //=========================================//
// //                score_2                  //
// //=========================================//
// always @(posedge clk or negedge rst_n) begin
//     if (!rst_n) begin
//         for (k = 0; k < 5; k = k + 1) begin
//             for (m = 0; m < 5; m = m + 1) begin
//                 score_2_matrix[k][m] <= 0;
//             end
//         end
//     end
//     else if (c_state == IDLE) begin
//         for (k = 0; k < 5; k = k + 1) begin
//             for (m = 0; m < 5; m = m + 1) begin
//                 score_2_matrix[k][m] <= 0;
//             end
//         end
//     end
//     else begin
//         case (counter)
//             'd40: begin
//                 score_2_matrix[0][0] <= add5_res;
//             end
//             'd41: begin
//                 score_2_matrix[0][1] <= add4_res;
//                 score_2_matrix[0][2] <= add5_res;
//             end
//             'd42: begin
//                 score_2_matrix[0][3] <= add4_res;
//                 score_2_matrix[0][4] <= add5_res;
//             end
//             'd43: begin
//                 score_2_matrix[1][0] <= add4_res;
//                 score_2_matrix[1][1] <= add5_res;
//             end
//             'd44: begin
//                 score_2_matrix[1][2] <= add4_res;
//                 score_2_matrix[1][3] <= add5_res;
//             end
//             'd45: begin
//                 score_2_matrix[1][4] <= add4_res;
//                 score_2_matrix[2][0] <= add5_res;
//             end
//             'd46: begin
//                 score_2_matrix[2][1] <= add4_res;
//                 score_2_matrix[2][2] <= add5_res;
//             end
//             'd47: begin
//                 score_2_matrix[2][3] <= add4_res;
//                 score_2_matrix[2][4] <= add5_res;
//             end
//             'd48: begin
//                 score_2_matrix[3][0] <= add1_res;
//                 score_2_matrix[3][1] <= add2_res;
//                 score_2_matrix[3][2] <= add4_res;
//                 score_2_matrix[3][3] <= add5_res;
//             end
//             'd49: begin
//                 score_2_matrix[3][4] <= add1_res;
//                 score_2_matrix[4][0] <= add2_res;
//                 score_2_matrix[4][1] <= add4_res;
//                 score_2_matrix[4][2] <= add5_res;
//             end
//             'd50: begin
//                 score_2_matrix[4][3] <= add1_res;
//                 score_2_matrix[4][4] <= add2_res;
//             end
//             'd55:begin
//                 score_2_matrix[0][0] <= exp1_res;
//             end
//             'd56:begin
//                 score_2_matrix[0][1] <= exp1_res;
//             end
//             'd57:begin
//                 score_2_matrix[0][2] <= exp1_res;
//             end
//             'd58:begin
//                 score_2_matrix[0][3] <= exp1_res;
//             end
//             'd59:begin
//                 score_2_matrix[0][4] <= exp1_res;
//             end
//             'd60:begin
//                 score_2_matrix[1][0] <= exp1_res;
//             end
//             'd61:begin
//                 score_2_matrix[1][1] <= exp1_res;
//             end
//             'd62:begin
//                 score_2_matrix[1][2] <= exp1_res;
//                 score_2_matrix[0][0] <= div2_res;
//             end
//             'd63:begin
//                 score_2_matrix[1][3] <= exp1_res;
//                 score_2_matrix[0][1] <= div2_res;
//             end
//             'd64:begin
//                 score_2_matrix[1][4] <= exp1_res;
//                 score_2_matrix[0][2] <= div2_res;
//             end
//             'd65:begin
//                 score_2_matrix[2][0] <= exp1_res;
//                 score_2_matrix[0][3] <= div2_res;
//             end
//             'd66:begin
//                 score_2_matrix[2][1] <= exp1_res;
//                 score_2_matrix[0][4] <= div2_res;
//             end
//             'd67:begin
//                 score_2_matrix[2][2] <= exp1_res;
//                 score_2_matrix[1][0] <= div2_res;
//             end
//             'd68:begin
//                 score_2_matrix[2][3] <= exp1_res;
//                 score_2_matrix[1][1] <= div2_res;
//             end
//             'd69:begin
//                 score_2_matrix[2][4] <= exp1_res;
//                 score_2_matrix[1][2] <= div2_res;
//             end
//             'd70:begin
//                 score_2_matrix[3][0] <= exp1_res;
//                 score_2_matrix[1][3] <= div2_res;
//             end
//             'd71:begin
//                 score_2_matrix[3][1] <= exp1_res;
//                 score_2_matrix[1][4] <= div2_res;
//             end
//             'd72:begin
//                 score_2_matrix[3][2] <= exp1_res;
//                 score_2_matrix[2][0] <= div2_res;
//             end
//             'd73:begin
//                 score_2_matrix[3][3] <= exp1_res;
//                 score_2_matrix[2][1] <= div2_res;
//             end
//             'd74:begin
//                 score_2_matrix[3][4] <= exp1_res;
//                 score_2_matrix[2][2] <= div2_res;
//             end
//             'd75:begin
//                 score_2_matrix[4][0] <= exp1_res;
//                 score_2_matrix[2][3] <= div2_res;
//             end
//             'd76:begin
//                 score_2_matrix[4][1] <= exp1_res;
//                 score_2_matrix[2][4] <= div2_res;
//             end
//             'd77:begin
//                 score_2_matrix[4][2] <= exp1_res;
//                 score_2_matrix[3][0] <= div2_res;
//             end
//             'd78:begin
//                 score_2_matrix[4][3] <= exp1_res;
//                 score_2_matrix[3][1] <= div2_res;
//             end
//             'd79:begin
//                 score_2_matrix[4][4] <= exp1_res;
//                 score_2_matrix[3][2] <= div2_res;
//             end
//             'd80:begin
//                 score_2_matrix[3][3] <= div2_res;
//             end
//             'd81:begin
//                 score_2_matrix[3][4] <= div2_res;
//             end
//             'd82:begin
//                 score_2_matrix[4][0] <= div2_res;
//             end
//             'd83:begin
//                 score_2_matrix[4][1] <= div2_res;
//             end
//             'd84:begin
//                 score_2_matrix[4][2] <= div2_res;
//             end
//             'd85:begin
//                 score_2_matrix[4][3] <= div2_res;
//             end
//             'd86:begin
//                 score_2_matrix[4][4] <= div2_res;
//             end

//             default: begin
//                 for (k = 0; k < 5; k = k + 1) begin
//                     for (m = 0; m < 5; m = m + 1) begin
//                         score_2_matrix[k][m] <= score_2_matrix[k][m];
//                     end
//                 end
//             end 
//         endcase
//     end
// end

// //=========================================//
// //                DIVIDER                  //
// //=========================================//
// always @(*) begin
//     if (counter_div_en) begin
//         if (div_score2)
//             div1_a = score_2_matrix[row][col];
//         else
//             div1_a = score_1_matrix[row][col];
//     end
//     else
//         div1_a = 0;
// end
// // always @(*) begin
// //     div1_b = sqare_root_2;
// // end

// //=========================================//
// //                   EXP                   //
// //=========================================//
// always @(posedge clk or negedge rst_n) begin
//     if (!rst_n)
//         exp1_in <= 0;
//     else if (c_state == IDLE)
//         exp1_in <= 0;
//     else begin
//         if (counter_div_en)
//             exp1_in <= div1_res;
//         else
//             exp1_in <= 0; 
//     end
// end
// //=========================================//
// //                accumlation              //
// //=========================================//
// always @(posedge clk or negedge rst_n) begin
//     if (!rst_n) begin
//         add7_a <= 0;
//     end
//     else if (c_state == IDLE)
//         add7_a <= 0;
//     else 
//         add7_a <= exp1_res;
// end

// always @(posedge clk or negedge rst_n) begin
//     if (!rst_n)
//         add7_b <= 0;
//     else if (c_state == IDLE)
//         add7_b <= 0;
//     else begin
//         if (col == 1)
//             add7_b <= 0;
//         else
//             add7_b <= add7_res; 
//     end
// end

// always @(posedge clk or negedge rst_n) begin
//     if (!rst_n)
//         softmax_row0 <= 0;
//     else if (c_state == IDLE)
//         softmax_row0 <= 0;
//     else if (row == 1 && col == 1)
//         softmax_row0 <= add7_res;
//     else
//         softmax_row0 <= softmax_row0;
// end

// always @(posedge clk or negedge rst_n) begin
//     if (!rst_n)
//         softmax_row1 <= 0;
//     else if (c_state == IDLE)
//         softmax_row1 <= 0;
//     else if (row == 2 && col == 1)
//         softmax_row1 <= add7_res;
//     else
//         softmax_row1 <= softmax_row1;
// end

// always @(posedge clk or negedge rst_n) begin
//     if (!rst_n)
//         softmax_row2 <= 0;
//     else if (c_state == IDLE)
//         softmax_row2 <= 0;
//     else if (row == 3 && col == 1)
//         softmax_row2 <= add7_res;
//     else
//         softmax_row2 <= softmax_row2;
// end

// always @(posedge clk or negedge rst_n) begin
//     if (!rst_n)
//         softmax_row3 <= 0;
//     else if (c_state == IDLE)
//         softmax_row3 <= 0;
//     else if (row == 4 && col == 1)
//         softmax_row3 <= add7_res;
//     else
//         softmax_row3 <= softmax_row3;
// end

// always @(posedge clk or negedge rst_n) begin
//     if (!rst_n)
//         softmax_row4 <= 0;
//     else if (c_state == IDLE)
//         softmax_row4 <= 0;
//     else if (row == 0 && col == 1 && div_score2)
//         softmax_row4 <= add7_res;
//     else
//         softmax_row4 <= softmax_row4;
// end
// //=========================================//
// //            DIVIDER_second               //
// //=========================================//
// always @(*) begin
//     if (softmax_score2_en) begin
//         case ({row, col})
//             6'b001_011: begin
//                 div2_a = score_2_matrix[0][0];
//                 div2_b = softmax_row0;
//             end
//             6'b001_100: begin
//                 div2_a = score_2_matrix[0][1];
//                 div2_b = softmax_row0;
//             end
//             6'b010_000: begin
//                 div2_a = score_2_matrix[0][2];
//                 div2_b = softmax_row0;
//             end
//             6'b010_001: begin
//                 div2_a = score_2_matrix[0][3];
//                 div2_b = softmax_row0;
//             end
//             6'b010_010: begin
//                 div2_a = score_2_matrix[0][4];
//                 div2_b = softmax_row0;
//             end
//             6'b010_011: begin
//                 div2_a = score_2_matrix[1][0];
//                 div2_b = softmax_row1;
//             end
//             6'b010_100: begin
//                 div2_a = score_2_matrix[1][1];
//                 div2_b = softmax_row1;
//             end
//             6'b011_000: begin
//                 div2_a = score_2_matrix[1][2];
//                 div2_b = softmax_row1;
//             end
//             6'b011_001: begin
//                 div2_a = score_2_matrix[1][3];
//                 div2_b = softmax_row1;
//             end
//             6'b011_010: begin
//                 div2_a = score_2_matrix[1][4];
//                 div2_b = softmax_row1;
//             end
//             6'b011_011: begin
//                 div2_a = score_2_matrix[2][0];
//                 div2_b = softmax_row2;
//             end
//             6'b011_100: begin
//                 div2_a = score_2_matrix[2][1];
//                 div2_b = softmax_row2;
//             end
//             6'b100_000: begin
//                 div2_a = score_2_matrix[2][2];
//                 div2_b = softmax_row2;
//             end
//             6'b100_001: begin
//                 div2_a = score_2_matrix[2][3];
//                 div2_b = softmax_row2;
//             end
//             6'b100_010: begin
//                 div2_a = score_2_matrix[2][4];
//                 div2_b = softmax_row2;
//             end
//             6'b100_011: begin
//                 div2_a = score_2_matrix[3][0];
//                 div2_b = softmax_row3;
//             end
//             6'b100_100: begin
//                 div2_a = score_2_matrix[3][1];
//                 div2_b = softmax_row3;
//             end
//             6'b000_000: begin
//                 div2_a = score_2_matrix[3][2];
//                 div2_b = softmax_row3;
//             end
//             6'b000_001: begin
//                 div2_a = score_2_matrix[3][3];
//                 div2_b = softmax_row3;
//             end
//             6'b000_010: begin
//                 div2_a = score_2_matrix[3][4];
//                 div2_b = softmax_row3;
//             end
//             6'b000_011: begin
//                 div2_a = score_2_matrix[4][0];
//                 div2_b = softmax_row4;
//             end
//             6'b000_100: begin
//                 div2_a = score_2_matrix[4][1];
//                 div2_b = softmax_row4;
//             end
//             6'b001_000: begin
//                 div2_a = score_2_matrix[4][2];
//                 div2_b = softmax_row4;
//             end
//             6'b001_001: begin
//                 div2_a = score_2_matrix[4][3];
//                 div2_b = softmax_row4;
//             end
//             6'b001_010: begin
//                 div2_a = score_2_matrix[4][4];
//                 div2_b = softmax_row4;
//             end
//             default: begin
//                 div2_a = 0;
//                 div2_b = 0;
//             end
//         endcase
        
//     end
//     else begin
//         case ({row, col})
//             6'b001_011: begin
//                 div2_a = score_1_matrix[0][0];
//                 div2_b = softmax_row0;
//             end
//             6'b001_100: begin
//                 div2_a = score_1_matrix[0][1];
//                 div2_b = softmax_row0;
//             end
//             6'b010_000: begin
//                 div2_a = score_1_matrix[0][2];
//                 div2_b = softmax_row0;
//             end
//             6'b010_001: begin
//                 div2_a = score_1_matrix[0][3];
//                 div2_b = softmax_row0;
//             end
//             6'b010_010: begin
//                 div2_a = score_1_matrix[0][4];
//                 div2_b = softmax_row0;
//             end
//             6'b010_011: begin
//                 div2_a = score_1_matrix[1][0];
//                 div2_b = softmax_row1;
//             end
//             6'b010_100: begin
//                 div2_a = score_1_matrix[1][1];
//                 div2_b = softmax_row1;
//             end
//             6'b011_000: begin
//                 div2_a = score_1_matrix[1][2];
//                 div2_b = softmax_row1;
//             end
//             6'b011_001: begin
//                 div2_a = score_1_matrix[1][3];
//                 div2_b = softmax_row1;
//             end
//             6'b011_010: begin
//                 div2_a = score_1_matrix[1][4];
//                 div2_b = softmax_row1;
//             end
//             6'b011_011: begin
//                 div2_a = score_1_matrix[2][0];
//                 div2_b = softmax_row2;
//             end
//             6'b011_100: begin
//                 div2_a = score_1_matrix[2][1];
//                 div2_b = softmax_row2;
//             end
//             6'b100_000: begin
//                 div2_a = score_1_matrix[2][2];
//                 div2_b = softmax_row2;
//             end
//             6'b100_001: begin
//                 div2_a = score_1_matrix[2][3];
//                 div2_b = softmax_row2;
//             end
//             6'b100_010: begin
//                 div2_a = score_1_matrix[2][4];
//                 div2_b = softmax_row2;
//             end
//             6'b100_011: begin
//                 div2_a = score_1_matrix[3][0];
//                 div2_b = softmax_row3;
//             end
//             6'b100_100: begin
//                 div2_a = score_1_matrix[3][1];
//                 div2_b = softmax_row3;
//             end
//             6'b000_000: begin
//                 div2_a = score_1_matrix[3][2];
//                 div2_b = softmax_row3;
//             end
//             6'b000_001: begin
//                 div2_a = score_1_matrix[3][3];
//                 div2_b = softmax_row3;
//             end
//             6'b000_010: begin
//                 div2_a = score_1_matrix[3][4];
//                 div2_b = softmax_row3;
//             end
//             6'b000_011: begin
//                 div2_a = score_1_matrix[4][0];
//                 div2_b = softmax_row4;
//             end
//             6'b000_100: begin
//                 div2_a = score_1_matrix[4][1];
//                 div2_b = softmax_row4;
//             end
//             6'b001_000: begin
//                 div2_a = score_1_matrix[4][2];
//                 div2_b = softmax_row4;
//             end
//             6'b001_001: begin
//                 div2_a = score_1_matrix[4][3];
//                 div2_b = softmax_row4;
//             end
//             6'b001_010: begin
//                 div2_a = score_1_matrix[4][4];
//                 div2_b = softmax_row4;
//             end
//             default: begin
//                 div2_a = 0;
//                 div2_b = 0;
//             end
//         endcase
//     end
// end
// //=========================================//
// //                  HEAD_OUT               //
// //=========================================//
// always @(posedge clk or negedge rst_n) begin
//     if (!rst_n) begin
//         for (k = 0; k < 5; k = k + 1) begin
//             for (m = 0; m < 2; m = m + 1) begin
//                 head_out[k][m] <= 0;
//             end
//         end
//     end
//     else if (c_state == IDLE) begin
//         for (k = 0; k < 5; k = k + 1) begin
//             for (m = 0; m < 2; m = m + 1) begin
//                 head_out[k][m] <= 0;
//             end
//         end
//     end
//     else begin
//         case (counter)
//             'd51: head_out[0][0] = add5_res;
//             'd52: head_out[0][1] = add5_res;
//             'd53: head_out[1][0] = add5_res;
//             'd54: head_out[1][1] = add5_res;
//             'd55: head_out[2][0] = add5_res;
//             'd56: head_out[2][1] = add5_res;
//             'd57: head_out[3][0] = add5_res;
//             'd58: head_out[3][1] = add5_res;
//             'd62: head_out[4][0] = add5_res;
//             'd63: head_out[4][1] = add5_res;
//             'd67: head_out[0][2] = add5_res;
//             'd68: head_out[0][3] = add5_res;
//             'd72: head_out[1][2] = add5_res;
//             'd73: head_out[1][3] = add5_res;
//             'd77: head_out[2][2] = add5_res;
//             'd78: head_out[2][3] = add5_res;
//             'd82: head_out[3][2] = add5_res;
//             'd83: head_out[3][3] = add5_res;
//             'd87: head_out[4][2] = add5_res;
//             'd88: head_out[4][3] = add5_res;
//             default:  begin
//                 for (k = 0; k < 5; k = k + 1) begin
//                     for (m = 0; m < 2; m = m + 1) begin
//                         head_out[k][m] <= head_out[k][m];
//                     end
//                 end
//             end
//         endcase
//     end
// end

// //=========================================//
// //                    FINAL                //
// //=========================================//
// always @(posedge clk or negedge rst_n) begin
//     if (!rst_n) begin
//         for (k = 0; k < 5; k = k + 1) begin
//             for (m = 0; m < 4; m = m + 1) begin
//                 final_matrix[k][m] <= 0;
//             end
//         end
//     end
//     else if (c_state == IDLE) begin
//         for (k = 0; k < 5; k = k + 1) begin
//             for (m = 0; m < 4; m = m + 1) begin
//                 final_matrix[k][m] <= 0;
//             end
//         end
//     end
//     else if (c_state == OUT) begin
//         for (m = 0; m < 5; m = m + 1) begin
//             for (k = 0; k < 3; k = k + 1) begin
//                 final_matrix[m][k] <= final_matrix[m][k + 1];
//             end
//         end
//             final_matrix[0][3] <= final_matrix[1][0];
//             final_matrix[1][3] <= final_matrix[2][0];
//             final_matrix[2][3] <= final_matrix[3][0];
//             final_matrix[3][3] <= final_matrix[4][0];
//             final_matrix[4][3] <= 0;
//     end
//     else begin
//         case (counter)
//             'd69: begin
//                 final_matrix[0][0] <= add6_res;
//             end
//             'd70: begin
//                 final_matrix[0][1] <= add6_res;
//             end
//             'd71: begin
//                 final_matrix[0][2] <= add6_res;
//             end
//             'd74: begin
//                 final_matrix[0][3] <= add3_res;
//                 final_matrix[1][0] <= add6_res;
//             end
//             'd75: begin
//                 final_matrix[1][1] <= add3_res;
//                 final_matrix[1][2] <= add6_res;
//             end
//             'd76: begin
//                 final_matrix[1][3] <= add3_res;
//             end
//             'd79: begin
//                 final_matrix[2][0] <= add3_res;
//                 final_matrix[2][1] <= add6_res;
//             end
//             'd80: begin
//                 final_matrix[2][2] <= add3_res;
//                 final_matrix[2][3] <= add6_res;
//             end
//             'd84: begin
//                 final_matrix[3][0] <= add3_res;
//                 final_matrix[3][1] <= add6_res;
//             end
//             'd85: begin
//                 final_matrix[3][2] <= add3_res;
//                 final_matrix[3][3] <= add6_res;
//             end
//             'd89: begin
//                 final_matrix[4][0] <= add3_res;
//                 final_matrix[4][1] <= add6_res;
//             end
//             'd90: begin
//                 final_matrix[4][2] <= add3_res;
//                 final_matrix[4][3] <= add6_res;
//             end
//             default:  begin
//                 for (k = 0; k < 5; k = k + 1) begin
//                     for (m = 0; m < 2; m = m + 1) begin
//                         head_out[k][m] <= head_out[k][m];
//                     end
//                 end
//             end
//         endcase
//     end
// end
// endmodule