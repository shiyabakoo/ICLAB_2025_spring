//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright System Integration and Silicon Implementation Laboratory
//    All Right Reserved
//		Date		: 2025
//		Version		: v1.0
//   	File Name   : BCH_TOP.v
//   	Module Name : BCH_TOP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

`include "Division_IP.v" 


module BCH_TOP(
    // Input signals
    clk,
	rst_n,
	in_valid,
    in_syndrome, 
    // Output signals
    out_valid, 
	out_location
);

// ===============================================================
// Input & Output Declaration
// ===============================================================
input clk, rst_n, in_valid;
input [3:0] in_syndrome;
 
output reg out_valid;
output reg [3:0] out_location;

// ===============================================================
// Reg & Wire Declaration
// ===============================================================
reg [27:0] omega_arr_1; // 0 for dividend, 1 for divisor
reg [27:0] omega_arr_0;
reg [27:0] sigma_arr_1; // 0 for dividend, 1 for divisor
reg [27:0] sigma_arr_0;
reg        omega_degree_met;
reg        sigma_degree_met;
reg [3:0]  in_syndrome_ff;

wire [3:0] alpha_to_decimal [0:15];
wire [3:0] deciaml_to_alpha [0:15];

reg  [3:0]  mul_in1   [0:26];
reg  [3:0]  mul_in2   [0:26];
wire [3:0]  mul_out   [0:26];

reg  [3:0]  mul_in1_2   [0:26];
reg  [3:0]  mul_in2_2   [0:26];
wire [3:0]  mul_out_2   [0:26];

reg  [3:0] mul_in1_search [0:2];
reg  [3:0] mul_in2_search [0:2];
wire [3:0] mul_out_search [0:2];

wire [3:0] omega_to_mul    [0:6];
wire [3:0] sigma_to_mul   [0:6];
wire [3:0] Quotient_to_mul [0:6];
reg  [3:0] add_6, sigma_add_6;
reg  [3:0] add_5, sigma_add_5;
reg  [3:0] add_4, sigma_add_4;
reg  [3:0] add_3, sigma_add_3;
reg  [3:0] add_2, sigma_add_2;
reg  [3:0] add_1, sigma_add_1;
reg  [3:0] add_0, sigma_add_0;

reg  [3:0] x6_value, sigma_x6_value;
reg  [3:0] x5_value, sigma_x5_value;
reg  [3:0] x4_value, sigma_x4_value;
reg  [3:0] x3_value, sigma_x3_value;
reg  [3:0] x2_value, sigma_x2_value;
reg  [3:0] x1_value, sigma_x1_value;
reg  [3:0] x0_value, sigma_x0_value;
reg  [27:0] IN_Dividend;
reg  [27:0] IN_Divisor;
wire [27:0] OUT_Quotient;
reg  [27:0] Quotient_ff;

reg  [2:0] c_state;
reg  [2:0] n_state;

reg        find_error;
reg  [3:0] search_count;
reg  [3:0] error_cal;
reg  [1:0] error_count;
reg  [1:0] out_count;
reg  [3:0] out_temp [0:2];
// // ===============================================================
// // GF converter
// // ===============================================================
assign alpha_to_decimal[0] = 'd1;
assign alpha_to_decimal[1] = 'd2;
assign alpha_to_decimal[2] = 'd4;
assign alpha_to_decimal[3] = 'd8;
assign alpha_to_decimal[4] = 'd3;
assign alpha_to_decimal[5] = 'd6;
assign alpha_to_decimal[6] = 'd12;
assign alpha_to_decimal[7] = 'd11;
assign alpha_to_decimal[8] = 'd5;
assign alpha_to_decimal[9] = 'd10;
assign alpha_to_decimal[10] = 'd7;
assign alpha_to_decimal[11] = 'd14;
assign alpha_to_decimal[12] = 'd15;
assign alpha_to_decimal[13] = 'd13;
assign alpha_to_decimal[14] = 'd9;
assign alpha_to_decimal[15] = 'd0;

assign deciaml_to_alpha[0] = 'd15;
assign deciaml_to_alpha[1] = 'd0;
assign deciaml_to_alpha[2] = 'd1;
assign deciaml_to_alpha[3] = 'd4;
assign deciaml_to_alpha[4] = 'd2;
assign deciaml_to_alpha[5] = 'd8;
assign deciaml_to_alpha[6] = 'd5;
assign deciaml_to_alpha[7] = 'd10;
assign deciaml_to_alpha[8] = 'd3;
assign deciaml_to_alpha[9] = 'd14;
assign deciaml_to_alpha[10] = 'd9;
assign deciaml_to_alpha[11] = 'd7;
assign deciaml_to_alpha[12] = 'd6;
assign deciaml_to_alpha[13] = 'd13;
assign deciaml_to_alpha[14] = 'd11;
assign deciaml_to_alpha[15] = 'd12;
// // ===============================================================
// // module instance
// // ===============================================================
genvar i;
generate
    for (i = 0; i < 27; i = i + 1) begin
        GF_MUL u_mul(.mul_in1(mul_in1[i]), .mul_in2(mul_in2[i]), .mul_out(mul_out[i]));
    end

    for (i = 0; i < 27; i = i + 1) begin
        GF_MUL u_mul(.mul_in1(mul_in1_2[i]), .mul_in2(mul_in2_2[i]), .mul_out(mul_out_2[i]));
    end
endgenerate

GF_MUL search1_mul(.mul_in1(mul_in1_search[0]), .mul_in2(mul_in2_search[0]), .mul_out(mul_out_search[0]));
GF_MUL search2u_mul(.mul_in1(mul_in1_search[1]), .mul_in2(mul_in2_search[1]), .mul_out(mul_out_search[1]));
GF_MUL search3u_mul(.mul_in1(mul_in1_search[2]), .mul_in2(mul_in2_search[2]), .mul_out(mul_out_search[2]));
Division_IP #(.IP_WIDTH(7)) I_Division_IP(.IN_Dividend(IN_Dividend), .IN_Divisor(IN_Divisor), .OUT_Quotient(OUT_Quotient)); 
// // ===============================================================
// // FSM
// // ===============================================================
localparam IDLE   = 3'd0,
           INPUT  = 3'd1,
           DIV    = 3'd2, 
           MUL    = 3'd3,
           Search = 3'd4,
           OUT    = 3'd5;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        c_state <= IDLE;
    else
        c_state <= n_state;
end  

always @(*) begin
    case (c_state)
        IDLE: begin
            if (in_valid)
                n_state = INPUT;
            else
                n_state = IDLE; 
        end
        INPUT: begin
            if(!in_valid)
                n_state = DIV;
            else
                n_state = INPUT; 
        end
        DIV: begin
            n_state = MUL;
        end
        MUL: begin
            if (sigma_degree_met && omega_degree_met) 
                n_state = Search;
            else
                n_state = DIV;
        end
        Search: begin
            if ((error_count == 3) || (search_count == 14))
                n_state = OUT;
            else
                n_state = Search; 
        end
        OUT: begin
            if (out_count == 2)
                n_state = IDLE;
            else
                n_state = OUT; 
        end
        default: n_state = IDLE;
    endcase
end
// ===============================================================
// array
// ===============================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        in_syndrome_ff <= 4'd15;
    else if (in_valid)
        in_syndrome_ff <= in_syndrome;
    else 
        in_syndrome_ff <= 4'd15;
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        omega_arr_1 <= {7{4'd15}};
    end
    else if (c_state == IDLE)
        omega_arr_1 <= {7{4'd15}};
    else if (c_state == INPUT) begin
        omega_arr_1 <= {4'd15, in_syndrome_ff, omega_arr_1[23:4]};
    end
    else if (c_state == MUL)
        omega_arr_1 <= {deciaml_to_alpha[x6_value], deciaml_to_alpha[x5_value], deciaml_to_alpha[x4_value], deciaml_to_alpha[x3_value], deciaml_to_alpha[x2_value], deciaml_to_alpha[x1_value], deciaml_to_alpha[x0_value]};
    else  
        omega_arr_1 <= omega_arr_1;
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        omega_arr_0 <= {4'd0, {6{4'd15}}};
    else if (c_state == IDLE)
        omega_arr_0 <= {4'd0, {6{4'd15}}};
    else if (c_state == MUL)
        omega_arr_0 <= omega_arr_1;
    else
        omega_arr_0 <= omega_arr_0;
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        sigma_arr_0 <= {7{4'd15}};
    else if (c_state == IDLE)
        sigma_arr_0 <= {7{4'd15}};
    else if (c_state == MUL)
        sigma_arr_0 <= sigma_arr_1;
    else
        sigma_arr_0 <= sigma_arr_0;
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) 
        sigma_arr_1 <= {{6{4'd15}}, 4'd0};
    else if (c_state == IDLE)
        sigma_arr_1 <= {{6{4'd15}}, 4'd0};
    else if (c_state == MUL)    
        sigma_arr_1 <= {deciaml_to_alpha[sigma_x6_value], deciaml_to_alpha[sigma_x5_value], deciaml_to_alpha[sigma_x4_value], deciaml_to_alpha[sigma_x3_value], deciaml_to_alpha[sigma_x2_value], deciaml_to_alpha[sigma_x1_value], deciaml_to_alpha[sigma_x0_value]};
    else 
        sigma_arr_1 <= sigma_arr_1;
end
// ===============================================================
// DIV
// ===============================================================
assign IN_Dividend = omega_arr_0;
assign IN_Divisor = omega_arr_1;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        Quotient_ff <= 4'd15;
    else if (c_state == DIV)
        Quotient_ff <= OUT_Quotient;
    else
        Quotient_ff <= Quotient_ff;
end
// ===============================================================
// MUL & ADD OMEGA
// ===============================================================
assign omega_to_mul[0] = omega_arr_1[3:0];    assign Quotient_to_mul[0] = Quotient_ff[3:0];
assign omega_to_mul[1] = omega_arr_1[7:4];    assign Quotient_to_mul[1] = Quotient_ff[7:4];
assign omega_to_mul[2] = omega_arr_1[11:8];   assign Quotient_to_mul[2] = Quotient_ff[11:8];
assign omega_to_mul[3] = omega_arr_1[15:12];  assign Quotient_to_mul[3] = Quotient_ff[15:12];
assign omega_to_mul[4] = omega_arr_1[19:16];  assign Quotient_to_mul[4] = Quotient_ff[19:16];
assign omega_to_mul[5] = omega_arr_1[23:20];  assign Quotient_to_mul[5] = Quotient_ff[23:20];
assign omega_to_mul[6] = omega_arr_1[27:24];  assign Quotient_to_mul[6] = Quotient_ff[27:24];

assign mul_in1[0] = omega_to_mul[0];   assign mul_in2[0] = Quotient_to_mul[6];
assign mul_in1[1] = omega_to_mul[1];   assign mul_in2[1] = Quotient_to_mul[5];
assign mul_in1[2] = omega_to_mul[2];   assign mul_in2[2] = Quotient_to_mul[4];
assign mul_in1[3] = omega_to_mul[3];   assign mul_in2[3] = Quotient_to_mul[3];
assign mul_in1[4] = omega_to_mul[4];   assign mul_in2[4] = Quotient_to_mul[2];
assign mul_in1[5] = omega_to_mul[5];   assign mul_in2[5] = Quotient_to_mul[1];
assign mul_in1[6] = omega_to_mul[5];   assign mul_in2[6] = Quotient_to_mul[0];
assign mul_in1[7] = omega_to_mul[4];   assign mul_in2[7] = Quotient_to_mul[1];
assign mul_in1[8] = omega_to_mul[3];   assign mul_in2[8] = Quotient_to_mul[2];
assign mul_in1[9] = omega_to_mul[2];   assign mul_in2[9] = Quotient_to_mul[3];
assign mul_in1[10] = omega_to_mul[1];  assign mul_in2[10] = Quotient_to_mul[4];
assign mul_in1[11] = omega_to_mul[0];  assign mul_in2[11] = Quotient_to_mul[5];
assign mul_in1[12] = omega_to_mul[3];  assign mul_in2[12] = Quotient_to_mul[1];
assign mul_in1[13] = omega_to_mul[4];  assign mul_in2[13] = Quotient_to_mul[0];
assign mul_in1[14] = omega_to_mul[2];  assign mul_in2[14] = Quotient_to_mul[2];
assign mul_in1[15] = omega_to_mul[1];  assign mul_in2[15] = Quotient_to_mul[3];
assign mul_in1[16] = omega_to_mul[0];  assign mul_in2[16] = Quotient_to_mul[4];
assign mul_in1[17] = omega_to_mul[3];  assign mul_in2[17] = Quotient_to_mul[0];
assign mul_in1[18] = omega_to_mul[2];  assign mul_in2[18] = Quotient_to_mul[1];
assign mul_in1[19] = omega_to_mul[1];  assign mul_in2[19] = Quotient_to_mul[2];
assign mul_in1[20] = omega_to_mul[0];  assign mul_in2[20] = Quotient_to_mul[3];
assign mul_in1[21] = omega_to_mul[2];  assign mul_in2[21] = Quotient_to_mul[0];   
assign mul_in1[22] = omega_to_mul[1];  assign mul_in2[22] = Quotient_to_mul[1];
assign mul_in1[23] = omega_to_mul[0];  assign mul_in2[23] = Quotient_to_mul[2];
assign mul_in1[24] = omega_to_mul[1];  assign mul_in2[24] = Quotient_to_mul[0];
assign mul_in1[25] = omega_to_mul[0];  assign mul_in2[25] = Quotient_to_mul[1];
assign mul_in1[26] = omega_to_mul[0];  assign mul_in2[26] = Quotient_to_mul[0];

assign add_6 = (alpha_to_decimal[mul_out[0]] ^ alpha_to_decimal[mul_out[1]]) ^ (alpha_to_decimal[mul_out[2]] ^ alpha_to_decimal[mul_out[3]]) ^ (alpha_to_decimal[mul_out[4]] ^ alpha_to_decimal[mul_out[5]]);
assign add_5 = (alpha_to_decimal[mul_out[6]] ^ alpha_to_decimal[mul_out[7]]) ^ (alpha_to_decimal[mul_out[8]] ^ alpha_to_decimal[mul_out[9]]) ^ (alpha_to_decimal[mul_out[10]] ^ alpha_to_decimal[mul_out[11]]);
assign add_4 = (alpha_to_decimal[mul_out[12]] ^ alpha_to_decimal[mul_out[13]]) ^ (alpha_to_decimal[mul_out[14]] ^ alpha_to_decimal[mul_out[15]]) ^ alpha_to_decimal[mul_out[16]];
assign add_3 = (alpha_to_decimal[mul_out[17]] ^ alpha_to_decimal[mul_out[18]]) ^ (alpha_to_decimal[mul_out[19]] ^ alpha_to_decimal[mul_out[20]]);
assign add_2 = alpha_to_decimal[mul_out[21]] ^ alpha_to_decimal[mul_out[22]] ^ alpha_to_decimal[mul_out[23]];
assign add_1 = alpha_to_decimal[mul_out[24]] ^ alpha_to_decimal[mul_out[25]];
assign add_0 = alpha_to_decimal[mul_out[26]];
assign x6_value = add_6 ^ alpha_to_decimal[omega_arr_0[27:24]];
assign x5_value = add_5 ^ alpha_to_decimal[omega_arr_0[23:20]];
assign x4_value = add_4 ^ alpha_to_decimal[omega_arr_0[19:16]];
assign x3_value = add_3 ^ alpha_to_decimal[omega_arr_0[15:12]];
assign x2_value = add_2 ^ alpha_to_decimal[omega_arr_0[11:8]];
assign x1_value = add_1 ^ alpha_to_decimal[omega_arr_0[7:4]];
assign x0_value = add_0 ^ alpha_to_decimal[omega_arr_0[3:0]];
// ===============================================================
// MUL & ADD OMEGA
// ===============================================================
assign sigma_to_mul[0] = sigma_arr_1[3:0];   
assign sigma_to_mul[1] = sigma_arr_1[7:4];   
assign sigma_to_mul[2] = sigma_arr_1[11:8];  
assign sigma_to_mul[3] = sigma_arr_1[15:12]; 
assign sigma_to_mul[4] = sigma_arr_1[19:16]; 
assign sigma_to_mul[5] = sigma_arr_1[23:20]; 
assign sigma_to_mul[6] = sigma_arr_1[27:24]; 

assign mul_in1_2[0] = sigma_to_mul[0];   assign mul_in2_2[0] = Quotient_to_mul[6];
assign mul_in1_2[1] = sigma_to_mul[1];   assign mul_in2_2[1] = Quotient_to_mul[5];
assign mul_in1_2[2] = sigma_to_mul[2];   assign mul_in2_2[2] = Quotient_to_mul[4];
assign mul_in1_2[3] = sigma_to_mul[3];   assign mul_in2_2[3] = Quotient_to_mul[3];
assign mul_in1_2[4] = sigma_to_mul[4];   assign mul_in2_2[4] = Quotient_to_mul[2];
assign mul_in1_2[5] = sigma_to_mul[5];   assign mul_in2_2[5] = Quotient_to_mul[1];
assign mul_in1_2[6] = sigma_to_mul[5];   assign mul_in2_2[6] = Quotient_to_mul[0];
assign mul_in1_2[7] = sigma_to_mul[4];   assign mul_in2_2[7] = Quotient_to_mul[1];
assign mul_in1_2[8] = sigma_to_mul[3];   assign mul_in2_2[8] = Quotient_to_mul[2];
assign mul_in1_2[9] = sigma_to_mul[2];   assign mul_in2_2[9] = Quotient_to_mul[3];
assign mul_in1_2[10] = sigma_to_mul[1];  assign mul_in2_2[10] = Quotient_to_mul[4];
assign mul_in1_2[11] = sigma_to_mul[0];  assign mul_in2_2[11] = Quotient_to_mul[5];
assign mul_in1_2[12] = sigma_to_mul[3];  assign mul_in2_2[12] = Quotient_to_mul[1];
assign mul_in1_2[13] = sigma_to_mul[4];  assign mul_in2_2[13] = Quotient_to_mul[0];
assign mul_in1_2[14] = sigma_to_mul[2];  assign mul_in2_2[14] = Quotient_to_mul[2];
assign mul_in1_2[15] = sigma_to_mul[1];  assign mul_in2_2[15] = Quotient_to_mul[3];
assign mul_in1_2[16] = sigma_to_mul[0];  assign mul_in2_2[16] = Quotient_to_mul[4];
assign mul_in1_2[17] = sigma_to_mul[3];  assign mul_in2_2[17] = Quotient_to_mul[0];
assign mul_in1_2[18] = sigma_to_mul[2];  assign mul_in2_2[18] = Quotient_to_mul[1];
assign mul_in1_2[19] = sigma_to_mul[1];  assign mul_in2_2[19] = Quotient_to_mul[2];
assign mul_in1_2[20] = sigma_to_mul[0];  assign mul_in2_2[20] = Quotient_to_mul[3];
assign mul_in1_2[21] = sigma_to_mul[2];  assign mul_in2_2[21] = Quotient_to_mul[0];   
assign mul_in1_2[22] = sigma_to_mul[1];  assign mul_in2_2[22] = Quotient_to_mul[1];
assign mul_in1_2[23] = sigma_to_mul[0];  assign mul_in2_2[23] = Quotient_to_mul[2];
assign mul_in1_2[24] = sigma_to_mul[1];  assign mul_in2_2[24] = Quotient_to_mul[0];
assign mul_in1_2[25] = sigma_to_mul[0];  assign mul_in2_2[25] = Quotient_to_mul[1];
assign mul_in1_2[26] = sigma_to_mul[0];  assign mul_in2_2[26] = Quotient_to_mul[0];

assign sigma_add_6 = (alpha_to_decimal[mul_out_2[0]] ^ alpha_to_decimal[mul_out_2[1]]) ^ (alpha_to_decimal[mul_out_2[2]] ^ alpha_to_decimal[mul_out_2[3]]) ^ (alpha_to_decimal[mul_out_2[4]] ^ alpha_to_decimal[mul_out_2[5]]);
assign sigma_add_5 = (alpha_to_decimal[mul_out_2[6]] ^ alpha_to_decimal[mul_out_2[7]]) ^ (alpha_to_decimal[mul_out_2[8]] ^ alpha_to_decimal[mul_out_2[9]]) ^ (alpha_to_decimal[mul_out_2[10]] ^ alpha_to_decimal[mul_out_2[11]]);
assign sigma_add_4 = (alpha_to_decimal[mul_out_2[12]] ^ alpha_to_decimal[mul_out_2[13]]) ^ (alpha_to_decimal[mul_out_2[14]] ^ alpha_to_decimal[mul_out_2[15]]) ^ alpha_to_decimal[mul_out_2[16]];
assign sigma_add_3 = (alpha_to_decimal[mul_out_2[17]] ^ alpha_to_decimal[mul_out_2[18]]) ^ (alpha_to_decimal[mul_out_2[19]] ^ alpha_to_decimal[mul_out_2[20]]);
assign sigma_add_2 = alpha_to_decimal[mul_out_2[21]] ^ alpha_to_decimal[mul_out_2[22]] ^ alpha_to_decimal[mul_out_2[23]];
assign sigma_add_1 = alpha_to_decimal[mul_out_2[24]] ^ alpha_to_decimal[mul_out_2[25]];
assign sigma_add_0 = alpha_to_decimal[mul_out_2[26]];

assign sigma_x6_value = sigma_add_6 ^ alpha_to_decimal[sigma_arr_0[27:24]];
assign sigma_x5_value = sigma_add_5 ^ alpha_to_decimal[sigma_arr_0[23:20]];
assign sigma_x4_value = sigma_add_4 ^ alpha_to_decimal[sigma_arr_0[19:16]];
assign sigma_x3_value = sigma_add_3 ^ alpha_to_decimal[sigma_arr_0[15:12]];
assign sigma_x2_value = sigma_add_2 ^ alpha_to_decimal[sigma_arr_0[11:8]];
assign sigma_x1_value = sigma_add_1 ^ alpha_to_decimal[sigma_arr_0[7:4]];
assign sigma_x0_value = sigma_add_0 ^ alpha_to_decimal[sigma_arr_0[3:0]];
// ===============================================================
// check degree
// ===============================================================
always @(*) begin
    if ((c_state == MUL) && (x6_value == 0) && (x5_value == 0) && (x4_value == 0) && (x3_value == 0))
        omega_degree_met = 1;
    else
        omega_degree_met = 0;
end

always @(*) begin
    if ((c_state == MUL) && (sigma_x6_value == 0) && (sigma_x5_value == 0) && (sigma_x4_value == 0))
        sigma_degree_met = 1;
    else
        sigma_degree_met = 0;
end
// ===============================================================
// search
// ===============================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        search_count <= 0;
    else if (c_state == Search)
        search_count <= search_count + 1;
    else
        search_count <= 0;
end
always @(*) begin
    if (c_state == Search) begin
        case (search_count)
            0: mul_in1_search[0] = 0;
            1: mul_in1_search[0] = 12;
            2: mul_in1_search[0] = 9;
            3: mul_in1_search[0] = 6;
            4: mul_in1_search[0] = 3;
            5: mul_in1_search[0] = 0;
            6: mul_in1_search[0] = 12;
            7: mul_in1_search[0] = 9;
            8: mul_in1_search[0] = 6;
            9: mul_in1_search[0] = 3;
            10:mul_in1_search[0] = 0;
            11:mul_in1_search[0] = 12;
            12:mul_in1_search[0] = 9;
            13:mul_in1_search[0] = 6;
            14:mul_in1_search[0] = 3;
            default: mul_in1_search[0] = 15;
        endcase
    end
    else begin
        mul_in1_search[0] = 15;
    end
end
always @(*) begin
    if (c_state == Search) begin
        case (search_count)
            0: mul_in1_search[1] = 0;
            1: mul_in1_search[1] = 13;
            2: mul_in1_search[1] = 11;
            3: mul_in1_search[1] = 9;
            4: mul_in1_search[1] = 7;
            5: mul_in1_search[1] = 5;
            6: mul_in1_search[1] = 3;
            7: mul_in1_search[1] = 1;
            8: mul_in1_search[1] = 14;
            9: mul_in1_search[1] = 12;
            10:mul_in1_search[1] = 10;
            11:mul_in1_search[1] = 8;
            12:mul_in1_search[1] = 6;
            13:mul_in1_search[1] = 4;
            14:mul_in1_search[1] = 2;
            default: mul_in1_search[1] = 15;
        endcase
    end
    else begin
        mul_in1_search[1] = 15;
    end
end
always @(*) begin
    if (c_state == Search) begin
        case (search_count)
            0: mul_in1_search[2] = 0;
            1: mul_in1_search[2] = 14;
            2: mul_in1_search[2] = 13;
            3: mul_in1_search[2] = 12;
            4: mul_in1_search[2] = 11;
            5: mul_in1_search[2] = 10;
            6: mul_in1_search[2] = 9;
            7: mul_in1_search[2] = 8;
            8: mul_in1_search[2] = 7;
            9: mul_in1_search[2] = 6;
            10:mul_in1_search[2] = 5;
            11:mul_in1_search[2] = 4;
            12:mul_in1_search[2] = 3;
            13:mul_in1_search[2] = 2;
            14:mul_in1_search[2] = 1;
            default: mul_in1_search[2] = 15;
        endcase
    end
    else begin
        mul_in1_search[2] = 15;
    end
end
assign mul_in2_search[0] = sigma_arr_1[15:12];
assign mul_in2_search[1] = sigma_arr_1[11:8];
assign mul_in2_search[2] = sigma_arr_1[7:4];
assign error_cal = (alpha_to_decimal[mul_out_search[0]] ^ alpha_to_decimal[mul_out_search[1]]) ^ (alpha_to_decimal[mul_out_search[2]] ^ alpha_to_decimal[sigma_arr_1[3:0]]);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        error_count <= 0;
    else if (c_state == Search) begin
        if (error_cal == 0) 
            error_count <= error_count + 1;
        else 
            error_count <= error_count; 
    end
    else
        error_count <= 0; 
end

integer j;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (j = 0; j < 3; j = j + 1) begin
            out_temp[j] <= 'd15;
        end
    end
    else if (c_state == IDLE) begin
        for (j = 0; j < 3; j = j + 1) begin
            out_temp[j] <= 'd15;
        end
    end
    else if ((c_state == Search) && (error_cal == 0))
        out_temp[error_count] <= search_count;
    else begin
        for (j = 0; j < 3; j = j + 1) begin
            out_temp[j] <= out_temp[j];
        end
    end 
end
// ===============================================================
// OUTPUT
// ===============================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        out_valid <= 1'b0;
    else if (c_state == OUT)
        out_valid <= 1'b1;
    else 
        out_valid <= 1'b0;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        out_location <= 4'b0;
    else if (c_state == OUT)
        out_location <= out_temp[out_count];
    else
        out_location <= 4'b0;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        out_count <= 0;
    else if (c_state == OUT)
        out_count <= out_count + 1;
    else
        out_count <= 0;
end
endmodule

// ===============================================================
// sub module
// ===============================================================

module GF_MUL_TOP(
    mul_in1,
    mul_in2,
    mul_out
);
input      [3:0] mul_in1;
input      [3:0] mul_in2;
output reg [3:0] mul_out; 

reg [4:0] mul_add;

assign mul_add = mul_in1 + mul_in2;
always @(*) begin
    if (mul_in1 == 'd15)
        mul_out = 'd15;
    else if (mul_in2 == 'd15)
        mul_out = 'd15;
    else begin
        mul_out = (mul_add >= 'd15)? mul_add - 'd15 : mul_add;
    end
    
end
endmodule  