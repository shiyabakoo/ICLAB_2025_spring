module HF(
    // Input signals
    input [24:0] symbol_freq,
    // Output signals
    output reg [19:0] out_encoded
);

//================================================================
//    Wire & Registers 
//================================================================
// Declare the wire/reg you would use in your circuit
// remember 
// wire for port connection and cont. assignment
// reg for proc. assignment
wire [11:0] a_freq, b_freq, c_freq, d_freq, e_freq; // [7:5] is index, a is 000, b is 001, c is 010, d is 011, e is 100
//================================================================
//    DESIGN
//================================================================
assign a_freq = {7'b0000001, symbol_freq[24:20]};
assign b_freq = {7'b0000010, symbol_freq[19:15]};
assign c_freq = {7'b0000100, symbol_freq[14:10]};
assign d_freq = {7'b0001000, symbol_freq[9:5]};
assign e_freq = {7'b0010000, symbol_freq[4:0]};

//================================================================
//    SORTING STAGE 1
//================================================================
wire [11:0] stage_1_out1, stage_1_out2, stage_1_out3 ,stage_1_out4 ,stage_1_out5;
// stage 1-1
wire [11:0] big_out_1_1, small_out_1_1;
comparator_stage_1 u1(.in_1(b_freq), .in_2(c_freq), .small_out(small_out_1_1), .big_out(big_out_1_1));
wire [11:0] big_out_1_2, small_out_1_2;
comparator_stage_1 u2(.in_1(d_freq), .in_2(e_freq), .small_out(small_out_1_2), .big_out(big_out_1_2));
// stage 1-2
wire [11:0] big_out_2_1, small_out_2_1;
comparator_stage_1 u3(.in_1(a_freq), .in_2(big_out_1_1), .small_out(small_out_2_1), .big_out(big_out_2_1));
wire [11:0] big_out_2_2, small_out_2_2;
comparator_stage_1 u4(.in_1(small_out_1_1), .in_2(small_out_1_2), .small_out(small_out_2_2), .big_out(big_out_2_2));
// stage 1-3
wire [11:0] big_out_3_1, small_out_3_1;
comparator_stage_1 u5(.in_1(small_out_2_1), .in_2(big_out_2_2), .small_out(small_out_3_1), .big_out(big_out_3_1));
wire [11:0] big_out_3_2, small_out_3_2;
comparator_stage_1 u6(.in_1(big_out_2_1), .in_2(big_out_1_2), .small_out(small_out_3_2), .big_out(stage_1_out5));
// stage 1-4
wire [11:0] big_out_4_1, small_out_4_1;
comparator_stage_1 u7(.in_1(small_out_3_1), .in_2(small_out_2_2), .small_out(stage_1_out1), .big_out(big_out_4_1));
wire [11:0] big_out_4_2, small_out_4_2;
comparator_stage_1 u8(.in_1(small_out_3_2), .in_2(big_out_3_1), .small_out(small_out_4_2), .big_out(stage_1_out4));
// stage 1-5
wire [11:0] big_out_5_1, small_out_5_1;
comparator_stage_1 u9(.in_1(big_out_4_1), .in_2(small_out_4_2), .small_out(stage_1_out2), .big_out(stage_1_out3));


// stage 1 to stage 2
wire [5:0] adder_1;
wire [12:0] stage_2_in1, stage_2_in2, stage_2_in3, stage_2_in4;
assign adder_1 = stage_1_out1[4:0] + stage_1_out2[4:0];
assign stage_2_in1 = {2'b01, {stage_1_out1[9:5] + stage_1_out2[9:5]}, adder_1};
assign stage_2_in2 = {stage_1_out3[11:5], 1'b0, stage_1_out3[4:0]};
assign stage_2_in3 = {stage_1_out4[11:5], 1'b0, stage_1_out4[4:0]};
assign stage_2_in4 = {stage_1_out5[11:5], 1'b0, stage_1_out5[4:0]};
//================================================================
//    SORTING STAGE 2
//================================================================
// satge 2-1
wire [12:0] stage_2_out1, stage_2_out2, stage_2_out3, stage_2_out4;
wire [12:0] stage2_net_1, stage2_net_2, stage2_net_3, stage2_net_4, stage2_net_5, stage2_net_6;
comparator_stage_2 u10(.in_1(stage_2_in3), .in_2(stage_2_in4), .small_out(stage2_net_1), .big_out(stage2_net_2));
// stage 2-2
comparator_stage_2 u11(.in_1(stage_2_in1), .in_2(stage_2_in2), .small_out(stage2_net_3), .big_out(stage2_net_4));
// stage 2-3 
comparator_stage_2 u12(.in_1(stage2_net_4), .in_2(stage2_net_2), .small_out(stage2_net_5), .big_out(stage_2_out4));
// stage 2-4
comparator_stage_2 u13(.in_1(stage2_net_3), .in_2(stage2_net_1), .small_out(stage_2_out1), .big_out(stage2_net_6));
// stage 2-5
comparator_stage_2 u14(.in_1(stage2_net_5), .in_2(stage2_net_6), .small_out(stage_2_out2), .big_out(stage_2_out3));

// stage 2 to stage 3
wire [6:0] adder_2;
wire [13:0] stage_3_in1, stage_3_in2, stage_3_in3;
assign adder_2 = stage_2_out1[5:0] + stage_2_out2[5:0];
assign stage_3_in1 = {2'b10, {stage_2_out1[10:6] + stage_2_out2[10:6]}, adder_2};
assign stage_3_in2 = {stage_2_out3[12:6], 1'b0, stage_2_out3[5:0]};
assign stage_3_in3 = {stage_2_out4[12:6], 1'b0, stage_2_out4[5:0]};

//================================================================
//    SORTING STAGE 3
//================================================================
// stage 3-1
wire [13:0] stage_3_out1, stage_3_out2, stage_3_out3;
wire [13:0] stage_3_net_1, stage_3_net_2, stage_3_net_3;
comparator_stage_3 u15(.in_1(stage_3_in1), .in_2(stage_3_in2), .small_out(stage_3_net_1), .big_out(stage_3_net_2));
// stage 3-2
comparator_stage_3 u16(.in_1(stage_3_net_2), .in_2(stage_3_in3), .small_out(stage_3_net_3), .big_out(stage_3_out3));
// stage 3-3
comparator_stage_3 u17(.in_1(stage_3_net_1), .in_2(stage_3_net_3), .small_out(stage_3_out1), .big_out(stage_3_out2));

// stage 3 to stage 4
wire [7:0] adder_3;
wire [14:0] stage_4_in1, stage_4_in2;
assign adder_3 = stage_3_out1[6:0] + stage_3_out2[6:0];
assign stage_4_in1 = {2'b11, {stage_3_out1[11:7] + stage_3_out2[11:7]},adder_3};
assign stage_4_in2 = {stage_3_out3[13:7], 1'b0, stage_3_out3[6:0]};

//================================================================
//    SORTING STAGE 4
//================================================================
// stage 4
wire [14:0] stage_4_out1, stage_4_out2;
comparator_stage_4 u18 (.in_1(stage_4_in1), .in_2(stage_4_in2), .small_out(stage_4_out1), .big_out(stage_4_out2));

//================================================================
//    Construct the Huffman Tree
//================================================================
wire [1:0] a_at_adder1;
wire [1:0] a_at_adder2;
wire [1:0] a_at_adder3;
wire [1:0] a_at_last;
wire [1:0] b_at_adder1;
wire [1:0] b_at_adder2;
wire [1:0] b_at_adder3;
wire [1:0] b_at_last;
wire [1:0] c_at_adder1;
wire [1:0] c_at_adder2;
wire [1:0] c_at_adder3;
wire [1:0] c_at_last;
wire [1:0] d_at_adder1;
wire [1:0] d_at_adder2;
wire [1:0] d_at_adder3;
wire [1:0] d_at_last;
wire [1:0] e_at_adder1;
wire [1:0] e_at_adder2;
wire [1:0] e_at_adder3;
wire [1:0] e_at_last;


assign a_at_adder1[0] = (stage_1_out1[5])? 1 : 0;
assign a_at_adder1[1] = (stage_1_out2[5])? 1 : 0;
assign a_at_adder2[0] = (stage_2_out1[6])? 1 : 0;
assign a_at_adder2[1] = (stage_2_out2[6])? 1 : 0;
assign a_at_adder3[0] = (stage_3_out1[7])? 1 : 0;
assign a_at_adder3[1] = (stage_3_out2[7])? 1 : 0;
assign a_at_last[0]   = (stage_4_out1[8])? 1 : 0;
assign a_at_last[1]   = (stage_4_out2[8])? 1 : 0;

assign b_at_adder1[0] = (stage_1_out1[6])? 1 : 0;
assign b_at_adder1[1] = (stage_1_out2[6])? 1 : 0;
assign b_at_adder2[0] = (stage_2_out1[7])? 1 : 0;
assign b_at_adder2[1] = (stage_2_out2[7])? 1 : 0;
assign b_at_adder3[0] = (stage_3_out1[8])? 1 : 0;
assign b_at_adder3[1] = (stage_3_out2[8])? 1 : 0;
assign b_at_last[0]   = (stage_4_out1[9])? 1 : 0;
assign b_at_last[1]   = (stage_4_out2[9])? 1 : 0;

assign c_at_adder1[0] = (stage_1_out1[7])? 1 : 0;
assign c_at_adder1[1] = (stage_1_out2[7])? 1 : 0;
assign c_at_adder2[0] = (stage_2_out1[8])? 1 : 0;
assign c_at_adder2[1] = (stage_2_out2[8])? 1 : 0;
assign c_at_adder3[0] = (stage_3_out1[9])? 1 : 0;
assign c_at_adder3[1] = (stage_3_out2[9])? 1 : 0;
assign c_at_last[0]   = (stage_4_out1[10])? 1 : 0;
assign c_at_last[1]   = (stage_4_out2[10])? 1 : 0;

assign d_at_adder1[0] = (stage_1_out1[8])? 1 : 0;
assign d_at_adder1[1] = (stage_1_out2[8])? 1 : 0;
assign d_at_adder2[0] = (stage_2_out1[9])? 1 : 0;
assign d_at_adder2[1] = (stage_2_out2[9])? 1 : 0;
assign d_at_adder3[0] = (stage_3_out1[10])? 1 : 0;
assign d_at_adder3[1] = (stage_3_out2[10])? 1 : 0;
assign d_at_last[0]   = (stage_4_out1[11])? 1 : 0;
assign d_at_last[1]   = (stage_4_out2[11])? 1 : 0;

assign e_at_adder1[0] = (stage_1_out1[9])? 1 : 0;
assign e_at_adder1[1] = (stage_1_out2[9])? 1 : 0;
assign e_at_adder2[0] = (stage_2_out1[10])? 1 : 0;
assign e_at_adder2[1] = (stage_2_out2[10])? 1 : 0;
assign e_at_adder3[0] = (stage_3_out1[11])? 1 : 0;
assign e_at_adder3[1] = (stage_3_out2[11])? 1 : 0;
assign e_at_last[0]   = (stage_4_out1[12])? 1 : 0;
assign e_at_last[1]   = (stage_4_out2[12])? 1 : 0;


// output, a is [19:16], b is [15:12], c is [11:8], d is [7:4], e is [3:0]

// // output a case
// wire a1_case1, a1_case2, a1_case3;
// wire a2_case1, a2_case2, a2_case3;
// assign a1_case1 = (a_at_adder1 !== 2'b00) && (a_at_adder2[1] || a_at_adder3[1] || a_at_last[1]);
// assign a1_case2 = (a_at_adder2 !== 2'b00) && (a_at_adder3[1] || a_at_last[1]);
// assign a1_case3 = (a_at_adder3 !== 2'b00) && (a_at_last[1]);

// assign a2_case1 = (a_at_adder1 !== 2'b00) && (a_at_adder2 !== 2'b00) && (a_at_adder3[1] || a_at_last[1]);
// assign a2_case2 = (a_at_adder2 !== 2'b00) && (a_at_adder3 !== 2'b00) && (a_at_last[1]);
// assign a2_case3 = (a_at_adder1 !== 2'b00) && (a_at_adder3 !== 2'b00) && (a_at_last[1]);
// // a encoded
// assign out_encoded[16] = (stage_1_out2[9:5] == 5'b00001) || (stage_2_out2[10:6] == 5'b00001) || (stage_3_out2[11:7] == 5'b00001) || (stage_4_out2[12:8] == 5'b00001);
// assign out_encoded[17] = (a1_case1 || a1_case2 || a1_case3);
// assign out_encoded[18] = (a2_case1 || a2_case2 || a2_case3);
// assign out_encoded[19] = (a_at_adder1 !== 2'b00) && (a_at_adder2 !== 2'b00) && (a_at_adder3 !== 2'b00) && (a_at_last[1]);

// // output b case
// wire b1_case1, b1_case2, b1_case3;
// wire b2_case1, b2_case2, b2_case3;
// assign b1_case1 = (b_at_adder1 !== 2'b00) && (b_at_adder2[1] || b_at_adder3[1] || b_at_last[1]);
// assign b1_case2 = (b_at_adder2 !== 2'b00) && (b_at_adder3[1] || b_at_last[1]);
// assign b1_case3 = (b_at_adder3 !== 2'b00) && (b_at_last[1]);

// assign b2_case1 = (b_at_adder1 !== 2'b00) && (b_at_adder2 !== 2'b00) && (b_at_adder3[1] || b_at_last[1]);
// assign b2_case2 = (b_at_adder2 !== 2'b00) && (b_at_adder3 !== 2'b00) && (b_at_last[1]);
// assign b2_case3 = (b_at_adder1 !== 2'b00) && (b_at_adder3 !== 2'b00) && (b_at_last[1]);
// // b encoded
// assign out_encoded[12] = (stage_1_out2[9:5] == 5'b00010) || (stage_2_out2[10:6] == 5'b00010) || (stage_3_out2[11:7] == 5'b00010) || (stage_4_out2[12:8] == 5'b00010);
// assign out_encoded[13] = (b1_case1 || b1_case2 || b1_case3);
// assign out_encoded[14] = (b2_case1 || b2_case2 || b2_case3);
// assign out_encoded[15] = (b_at_adder1 !== 2'b00) && (b_at_adder2 !== 2'b00) && (b_at_adder3 !== 2'b00) && (b_at_last[1]);

// // output c case
// wire c1_case1, c1_case2, c1_case3;
// wire c2_case1, c2_case2, c2_case3;
// assign c1_case1 = (c_at_adder1 !== 2'b00) && (c_at_adder2[1] || c_at_adder3[1] || c_at_last[1]);
// assign c1_case2 = (c_at_adder2 !== 2'b00) && (c_at_adder3[1] || c_at_last[1]);
// assign c1_case3 = (c_at_adder3 !== 2'b00) && (c_at_last[1]);

// assign c2_case1 = (c_at_adder1 !== 2'b00) && (c_at_adder2 !== 2'b00) && (c_at_adder3[1] || c_at_last[1]);
// assign c2_case2 = (c_at_adder2 !== 2'b00) && (c_at_adder3 !== 2'b00) && (c_at_last[1]);
// assign c2_case3 = (c_at_adder1 !== 2'b00) && (c_at_adder3 !== 2'b00) && (c_at_last[1]);
// // c encoded
// assign out_encoded[8] = (stage_1_out2[9:5] == 5'b00100) || (stage_2_out2[10:6] == 5'b00100) || (stage_3_out2[11:7] == 5'b00100) || (stage_4_out2[12:8] == 5'b00100);
// assign out_encoded[9] = (c1_case1 || c1_case2 || c1_case3);
// assign out_encoded[10] = (c2_case1 || c2_case2 || c2_case3);
// assign out_encoded[11] = (c_at_adder1 !== 2'b00) && (c_at_adder2 !== 2'b00) && (c_at_adder3 !== 2'b00) && (c_at_last[1]);

// // output d case
// wire d1_case1, d1_case2, d1_case3;
// wire d2_case1, d2_case2, d2_case3;
// assign d1_case1 = (d_at_adder1 !== 2'b00) && (d_at_adder2[1] || d_at_adder3[1] || d_at_last[1]);
// assign d1_case2 = (d_at_adder2 !== 2'b00) && (d_at_adder3[1] || d_at_last[1]);
// assign d1_case3 = (d_at_adder3 !== 2'b00) && (d_at_last[1]);

// assign d2_case1 = (d_at_adder1 !== 2'b00) && (d_at_adder2 !== 2'b00) && (d_at_adder3[1] || d_at_last[1]);
// assign d2_case2 = (d_at_adder2 !== 2'b00) && (d_at_adder3 !== 2'b00) && (d_at_last[1]);
// assign d2_case3 = (d_at_adder1 !== 2'b00) && (d_at_adder3 !== 2'b00) && (d_at_last[1]);
// // d encoded
// assign out_encoded[4] = (stage_1_out2[9:5] == 5'b01000) || (stage_2_out2[10:6] == 5'b01000) || (stage_3_out2[11:7] == 5'b01000) || (stage_4_out2[12:8] == 5'b01000);
// assign out_encoded[5] = (d1_case1 || d1_case2 || d1_case3);
// assign out_encoded[6] = (d2_case1 || d2_case2 || d2_case3);
// assign out_encoded[7] = (d_at_adder1 !== 2'b00) && (d_at_adder2 !== 2'b00) && (d_at_adder3 !== 2'b00) && (d_at_last[1]);

// // output e case
// wire e1_case1, e1_case2, e1_case3;
// wire e2_case1, e2_case2, e2_case3;
// assign e1_case1 = (e_at_adder1 !== 2'b00) && (e_at_adder2[1] || e_at_adder3[1] || e_at_last[1]);
// assign e1_case2 = (e_at_adder2 !== 2'b00) && (e_at_adder3[1] || e_at_last[1]);
// assign e1_case3 = (e_at_adder3 !== 2'b00) && (e_at_last[1]);

// assign e2_case1 = (e_at_adder1 !== 2'b00) && (e_at_adder2 !== 2'b00) && (e_at_adder3[1] || e_at_last[1]);
// assign e2_case2 = (e_at_adder2 !== 2'b00) && (e_at_adder3 !== 2'b00) && (e_at_last[1]);
// assign e2_case3 = (e_at_adder1 !== 2'b00) && (e_at_adder3 !== 2'b00) && (e_at_last[1]);
// // e encoded
// // assign out_encoded[0] = (e_at_adder1[1] || e_at_adder2[1] || e_at_adder3[1] || e_at_last[1]);
// assign out_encoded[0] = (stage_1_out2[9:5] == 5'b10000) || (stage_2_out2[10:6] == 5'b10000) || (stage_3_out2[11:7] == 5'b10000) || (stage_4_out2[12:8] == 5'b10000);
// assign out_encoded[1] = (e1_case1 || e1_case2 || e1_case3);
// assign out_encoded[2] = (e2_case1 || e2_case2 || e2_case3);
// assign out_encoded[3] = (e_at_adder1 !== 2'b00) && (e_at_adder2 !== 2'b00) && (e_at_adder3 !== 2'b00) && (e_at_last[1]);

wire [7:0] a_tmp, b_tmp, c_tmp, d_tmp, e_tmp;
wire [3:0] a_encode, b_encode, c_encode, d_encode, e_encode;
assign a_tmp = {a_at_last, a_at_adder3, a_at_adder2, a_at_adder1};
assign b_tmp = {b_at_last, b_at_adder3, b_at_adder2, b_at_adder1};
assign c_tmp = {c_at_last, c_at_adder3, c_at_adder2, c_at_adder1};
assign d_tmp = {d_at_last, d_at_adder3, d_at_adder2, d_at_adder1};
assign e_tmp = {e_at_last, e_at_adder3, e_at_adder2, e_at_adder1};

compress_2bit A(
    .in_data     (a_tmp),
    .out_data    (a_encode)
);

compress_2bit B(
    .in_data     (b_tmp),
    .out_data    (b_encode)
);

compress_2bit C(
    .in_data     (c_tmp),
    .out_data    (c_encode)
);
compress_2bit D(
    .in_data     (d_tmp),
    .out_data    (d_encode)
);

compress_2bit E(
    .in_data     (e_tmp),
    .out_data    (e_encode)
);

assign out_encoded = {a_encode, b_encode, c_encode, d_encode, e_encode};

endmodule


//================================================================
//    SUB MODULE
//================================================================
module comparator_stage_1 (
    input [11:0] in_1, // [5:0] is value, [8:6] is index
    input [11:0] in_2,
    output reg [11:0] small_out,
    output reg [11:0] big_out
);
reg compare;
// assign compare = (in_1[4:0] > in_2[4:0])? 1 : 0;  // if in_1 is bigger => compare = 1
always @(*) begin
    if (in_1[4:0] == in_2[4:0]) begin
        if (in_1[9:5] < in_2[9:5]) begin
            big_out  = in_2;
            small_out = in_1;
        end
        else begin
            big_out = in_1;
            small_out = in_2;
        end
    end
    else begin
        if (in_1[4:0] > in_2[4:0]) begin
            big_out = in_1;
            small_out = in_2;
        end
        else begin
            big_out = in_2;
            small_out = in_1;
        end
    end
end

endmodule

module comparator_stage_2 (
    input [12:0] in_1, // [5:0] is value, [8:6] is index
    input [12:0] in_2,
    output [12:0] small_out,
    output [12:0] big_out
);
reg compare;
// assign compare = (in_1[5:0] > in_2[5:0])? 1 : 0;  // if in_1 is bigger => compare = 1
always @(*) begin
    if (in_1[5:0] == in_2[5:0]) begin
        if (in_1[12:11] > in_2[12:11]) compare = 1'b0;
        else if (in_1[12:11] !== 2'b00) compare = 1'b0;
        else if (in_1[10:6] < in_2[10:6]) compare = 1'b0;
        else compare = 1'b1; 
    end
    else begin
        compare = (in_1[5:0] > in_2[5:0])? 1 : 0;
    end
end

assign big_out = (compare)? in_1 : in_2;
assign small_out = (compare)? in_2 : in_1;

endmodule

module comparator_stage_3 (
    input [13:0] in_1, // [5:0] is value, [8:6] is index
    input [13:0] in_2,
    output [13:0] small_out,
    output [13:0] big_out
);
reg compare;
// assign compare = (in_1[6:0] > in_2[6:0])? 1 : 0;  // if in_1 is bigger => compare = 1
always @(*) begin
    if (in_1[6:0] == in_2[6:0]) begin
        if (in_1[13:12] > in_2[13:12]) compare = 1'b0;
        else if (in_1[13:12] !== 2'b00) compare = 1'b0;
        else if (in_1[11:7] < in_2[11:7]) compare = 1'b0;
        else compare = 1'b1;   
    end
    else begin
        compare = (in_1[6:0] > in_2[6:0])? 1 : 0;
    end
end

assign big_out = (compare)? in_1 : in_2;
assign small_out = (compare)? in_2 : in_1;

endmodule

module comparator_stage_4 (
    input [14:0] in_1, // [5:0] is value, [8:6] is index
    input [14:0] in_2,
    output [14:0] small_out,
    output [14:0] big_out
);
reg compare;
// assign compare = (in_1[7:0] > in_2[7:0])? 1 : 0;  // if in_1 is bigger => compare = 1
always @(*) begin
    if (in_1[7:0] == in_2[7:0]) begin
        if (in_1[14:13] > in_2[14:13]) compare = 1'b0;
        else if (in_1[14:13] !== 2'b00) compare = 1'b0;
        else if (in_1[12:8] < in_2[12:8]) compare = 1'b0;
        else compare = 1'b1;    
    end
    else begin
        compare = (in_1[7:0] > in_2[7:0])? 1 : 0;
    end
end
assign big_out = (compare)? in_1 : in_2;
assign small_out = (compare)? in_2 : in_1;

endmodule

module compress_2bit (
    input       [7:0] in_data,  
    output reg  [3:0] out_data
);

wire [1:0] s0 = in_data[7:6];
wire [1:0] s1 = in_data[5:4];
wire [1:0] s2 = in_data[3:2];
wire [1:0] s3 = in_data[1:0];

wire v0 = (s0 != 2'b00);
wire v1 = (s1 != 2'b00);
wire v2 = (s2 != 2'b00);
wire v3 = (s3 != 2'b00);

wire b0 = (s0 == 2'b10) ? 1 : 0;
wire b1 = (s1 == 2'b10) ? 1 : 0;
wire b2 = (s2 == 2'b10) ? 1 : 0;
wire b3 = (s3 == 2'b10) ? 1 : 0;

wire [3:0] valid_mask = {v0, v1, v2, v3};

always @(*) begin
    case (valid_mask)
        4'b0000: out_data = 4'b0000;
        4'b0001: out_data = {3'b000, b3};                  
        4'b0010: out_data = {3'b000, b2};                  
        4'b0011: out_data = {2'b00, b2, b3};               
        4'b0100: out_data = {3'b000, b1};                  
        4'b0101: out_data = {2'b00, b1, b3};               
        4'b0110: out_data = {2'b00, b1, b2};               
        4'b0111: out_data = {1'b0, b1, b2, b3};            
        4'b1000: out_data = {3'b000, b0};                  
        4'b1001: out_data = {2'b00, b0, b3};               
        4'b1010: out_data = {2'b00, b0, b2};               
        4'b1011: out_data = {1'b0, b0, b2, b3};            
        4'b1100: out_data = {2'b00, b0, b1};               
        4'b1101: out_data = {1'b0, b0, b1, b3};            
        4'b1110: out_data = {1'b0, b0, b1, b2};            
        4'b1111: out_data = {b0, b1, b2, b3};              
        default: out_data = 4'b0000;
    endcase
end

endmodule




// module HF(
//     // Input signals
//     input [24:0] symbol_freq,
//     // Output signals
//     output reg [19:0] out_encoded
// );

// reg [19:0] out_encoded_1 ;
// reg [24:0] sym_reg ;
// reg [19:0] out_reg ;
// reg [14:0] select_reg  ;
// wire[14:0] select_reg1,select_reg2,select_reg3,select_reg4,select_reg5 ;
// reg [4:0] a,b,c,d,e ;
// wire [4:0] a1,b1,c1,d1,e1;
// wire [4:0] a2,b2,c2,d2,e2;
// wire [4:0] a3,b3,c3,d3,e3;
// wire [4:0] a4,b4,c4,d4,e4;
// wire [4:0] a5,b5,c5,d5,e5;

// //----------------------------------------------------------------------------
// wire[14:0] select2_reg1,select2_reg2,select2_reg3,select2_reg4,select2_reg5 ;
// wire [3:0] a1_2,b1_2,c1_2,d1_2,e1_2;
// wire [3:0] a2_2,b2_2,c2_2,d2_2,e2_2;
// wire [3:0] a3_2,b3_2,c3_2,d3_2,e3_2;
// wire [3:0] a4_2,b4_2,c4_2,d4_2,e4_2;
// wire [3:0] a5_2,b5_2,c5_2,d5_2,e5_2;

// //----------------------------------------------------------------------------




// 	reg [5:0] aa,bb,cc ;
// 	reg [6:0] aaa,bbb,ddd ;
// 	reg [6:0] ccc ;
// 	//reg [14:0] select2_reg1 ;
// 	reg [19:0] out_1 ;
// 	reg [8:0] test,test2,test3 ;
	
// 	always@(*)begin
// 		aa = a5 + b5 ;
// 		bb = c5 + d5 ;
// 		cc = d5 + e5 ;
// 		aaa = c5 + d5 + e5 ;
// 		bbb = e5 + a5 + b5 ;
// 		ddd = a5 + b5 +c5 ;
// 		ccc = c5 + d5 + a5 + b5 ;
// 	end

// 	always@(*)begin
		
		
// 		if( aa > e5 ) begin 
// 			if( bb <= e5 )begin
// 				if( aaa <= aa)begin
				
// 				out_encoded_1 =  20'b 0010_0011_0000_0001_0001 ;
				
// 				end
// 				else begin
				
// 				out_encoded_1 =  20'b 0000_0001_0100_0101_0011 ;
				
// 				end
			
// 			end
// 			else if ( bb <= aa )begin
			
// 				if( aaa <= aa)begin
				
// 				out_encoded_1 =  20'b 0010_0011_0010_0011_0000 ;
				
// 				end
// 				else begin
				
// 				out_encoded_1 =  20'b 0000_0001_0110_0111_0010 ;
				
// 				end
			
// 			end
// 			else begin
			
// 				if( bbb <= bb )begin
				
// 				out_encoded_1 =  20'b 0010_0011_0010_0011_0000 ;
				
// 				end
// 				else begin
				
// 				out_encoded_1 =  20'b 0110_0111_0000_0001_0010 ;
				
// 				end
			
// 			end
			
// 		end
		
// 		else if( aa > d5 )begin
// 			if( bb <= aa )begin
// 				if( ccc <= e5)begin
				
// 				out_encoded_1 = 20'b0010_0011_0000_0001_0001  ;
				
// 				end
// 				else begin
				
// 				out_encoded_1 = 20'b0110_0111_0100_0101_0000  ;
				
// 				end
			
// 			end
// 			else if ( bb <= e5 )begin
			
// 				if( ccc <= e5 )begin
				
// 				out_encoded_1 =  20'b0000_0001_0010_0011_0001 ;
				
// 				end
// 				else begin
				
// 				out_encoded_1 =  20'b0100_0101_0110_0111_0000  ;
				
// 				end
			
// 			end
// 			else begin
			
// 				if( bbb <= bb )begin
				
// 				out_encoded_1 = 20'b0000_0001_0010_0011_0001  ;
				
// 				end
// 				else begin
				
// 				out_encoded_1 = 20'b0100_0101_0000_0001_0011   ;
				
// 				end
			
// 			end
			
		
// 		end
		
// 		else if( aa > c5 )begin
// 			if( ddd <= d5 )begin
// 				if( ccc <= e5)begin
				
// 				out_encoded_1 =  20'b0010_0011_0000_0001_0001 ;
				
// 				end
// 				else begin
				
// 				out_encoded_1 =  20'b1010_1011_0100_0011_0000 ;
				
// 				end
			
// 			end
// 			else if ( ddd <= e5 )begin
			
// 				if( ccc <= e5 )begin
				
// 				out_encoded_1 = 20'b0110_0111_0010_0000_0001  ;
				
// 				end
// 				else begin
				
// 				out_encoded_1 = 20'b1110_1111_0110_0010_0000  ;
				
// 				end
			
// 			end
// 			else begin
			
// 				if( cc <= ddd )begin
				
// 				out_encoded_1 = 20'b0110_0111_0010_0000_0001  ;
				
// 				end
// 				else begin
				
// 				out_encoded_1 = 20'b0010_0011_0000_0010_0011   ;
				
// 				end
			
// 			end
		
		
// 		end
		
		
// 		else begin
// 			if( ddd <= d5 )begin
// 				if( ccc <= e5)begin
				
// 				out_encoded_1 = 20'b0000_0001_0001_0001_0001 ;
				
// 				end
// 				else begin
				
// 				out_encoded_1 = 20'b1000_1001_0101_0011_0000 ;
				
// 				end
			
// 			end
// 			else if ( ddd <= e5 )begin
			
// 				if( ccc <= e5 )begin
				
// 				out_encoded_1 =  20'b0100_0101_0011_0000_0001 ;
				
// 				end
// 				else begin
				
// 				out_encoded_1 =  20'b1100_1101_0111_0010_0000 ;
				
// 				end
			
// 			end
// 			else begin
			
// 				if( cc <= ddd )begin
				
// 				out_encoded_1 = 20'b0100_0101_0011_0000_0001  ;
				
// 				end
// 				else begin
				
// 				out_encoded_1 = 20'b0000_0001_0001_0010_0011 ;
				
// 				end
			
// 			end
		
// 		end
	
// 	end


// //-----------------------------------------------------------------------------

// always@(*)begin
	
// 	//out_encoded = [a5_2,b5_2,c5_2,d5_2,e5_2] ;
// 	out_encoded[19:16] = a5_2 ;
// 	out_encoded[15:12] = b5_2 ;
// 	out_encoded[11:8] = c5_2 ;
// 	out_encoded[7:4] = d5_2 ;
// 	out_encoded[3:0] = e5_2 ;
	
// 	select_reg = 15'b000_001_010_011_100 ;
// 	a = symbol_freq[24:20] ;
// 	b = symbol_freq[19:15] ;
// 	c = symbol_freq[14:10] ;
// 	d = symbol_freq[9:5] ;
// 	e = symbol_freq[4:0] ;
	
// end

// //-----------------------------------------------------------------------------//
// //								one											   //																				
// //-----------------------------------------------------------------------------//
// ///////////////////////////////////////////////////////////////
// //                      select1                              //
// ///////////////////////////////////////////////////////////////

// select select11(.a(a) , .b(b) , .c(select_reg[14:12]) , .d(select_reg[11:9]) , .a1(a1) , .a2(b1) , .a3(select_reg1[14:12]) , .a4(select_reg1[11:9]) );
// select select12(.a(c) , .b(d) , .c(select_reg[8:6]) , .d(select_reg[5:3]) , .a1(c1) , .a2(d1) , .a3(select_reg1[8:6]) , .a4(select_reg1[5:3]) );
// assign select_reg1[2:0] = select_reg[2:0] ; 
// assign e1 = e ;

// ///////////////////////////////////////////////////////////////
// //                      select2                              //
// ///////////////////////////////////////////////////////////////


// select select21(.a(b1) , .b(d1) , .c(select_reg1[11:9]) , .d(select_reg1[5:3]) , .a1(b2) , .a2(d2) , .a3(select_reg2[11:9]) , .a4(select_reg2[5:3]) );
// select select22(.a(c1) , .b(e1) , .c(select_reg1[8:6]) , .d(select_reg1[2:0]) , .a1(c2) , .a2(e2) , .a3(select_reg2[8:6]) , .a4(select_reg2[2:0]) );
// assign select_reg2[14:12] = select_reg1[14:12] ; 
// assign a2 = a1 ;

// ///////////////////////////////////////////////////////////////
// //                      select3                              //
// ///////////////////////////////////////////////////////////////

// select select31(.a(a2) , .b(c2) , .c(select_reg2[14:12]) , .d(select_reg2[8:6]) , .a1(a3) , .a2(c3) , .a3(select_reg3[14:12]) , .a4(select_reg3[8:6]) );
// select select32(.a(b2) , .b(e2) , .c(select_reg2[11:9]) , .d(select_reg2[2:0]) , .a1(b3) , .a2(e3) , .a3(select_reg3[11:9]) , .a4(select_reg3[2:0]) );
// assign select_reg3[5:3] = select_reg2[5:3] ; 
// assign d3 = d2 ;

// ///////////////////////////////////////////////////////////////
// //                      select4                              //
// ///////////////////////////////////////////////////////////////

// select select41(.a(b3) , .b(c3) , .c(select_reg3[11:9]) , .d(select_reg3[8:6]) , .a1(b4) , .a2(c4) , .a3(select_reg4[11:9]) , .a4(select_reg4[8:6]) );
// select select42(.a(d3) , .b(e3) , .c(select_reg3[5:3]) , .d(select_reg3[2:0]) , .a1(d4) , .a2(e4) , .a3(select_reg4[5:3]) , .a4(select_reg4[2:0]) );
// assign select_reg4[14:12] = select_reg3[14:12] ; 
// assign a4 = a3 ;

// ///////////////////////////////////////////////////////////////
// //                      select5                              //
// ///////////////////////////////////////////////////////////////

// select select51(.a(c4) , .b(d4) , .c(select_reg4[8:6]) , .d(select_reg4[5:3]) , .a1(c5) , .a2(d5) , .a3(select_reg5[8:6]) , .a4(select_reg5[5:3]) );
// assign select_reg5[14:9] = select_reg4[14:9] ; 
// assign select_reg5[2:0] = select_reg4[2:0] ; 
// assign a5 = a4 ;
// assign b5 = b4 ;
// assign e5 = e4 ;

// //-----------------------------------------------------------------------------//
// //								two   						     			   //																				
// //-----------------------------------------------------------------------------//
// ///////////////////////////////////////////////////////////////
// //                      select1                              //
// ///////////////////////////////////////////////////////////////

// select2 select2_11(.a(select_reg5[14:12]) , .b(select_reg5[11:9]) , .c(out_encoded_1[19:16]) , .d(out_encoded_1[15:12]) , .a1(select2_reg1[14:12]) , .a2(select2_reg1[11:9]) , .a3(a1_2) , .a4(b1_2) );
// select2 select2_12(.a(select_reg5[8:6]) , .b(select_reg5[5:3]) , .c(out_encoded_1[11:8]) , .d(out_encoded_1[7:4]) , .a1(select2_reg1[8:6]) , .a2(select2_reg1[5:3]) , .a3(c1_2) , .a4(d1_2) );
// assign select2_reg1[2:0] = select_reg5[2:0] ; 
// assign e1_2 = out_encoded_1[3:0] ;


// ///////////////////////////////////////////////////////////////
// //                      select2                              //
// ///////////////////////////////////////////////////////////////

// select2 select2_21(.a(select2_reg1[11:9]) , .b(select2_reg1[5:3]) , .c(b1_2) , .d(d1_2) , .a1(select2_reg2[11:9]) , .a2(select2_reg2[5:3]) , .a3(b2_2) , .a4(d2_2) );
// select2 select2_22(.a(select2_reg1[8:6]) , .b(select2_reg1[2:0]) , .c(c1_2) , .d(e1_2) , .a1(select2_reg2[8:6]) , .a2(select2_reg2[2:0]) , .a3(c2_2) , .a4(e2_2) );
// assign select2_reg2[14:12] = select2_reg1[14:12] ; 
// assign a2_2 = a1_2  ;

// ///////////////////////////////////////////////////////////////
// //                      select3                              //
// ///////////////////////////////////////////////////////////////

// select2 select2_31(.a(select2_reg2[14:12]) , .b(select2_reg2[8:6]) , .c(a2_2) , .d(c2_2) , .a1(select2_reg3[14:12]) , .a2(select2_reg3[8:6]) , .a3(a3_2) , .a4(c3_2) );
// select2 select2_32(.a(select2_reg2[11:9]) , .b(select2_reg2[2:0]) , .c(b2_2) , .d(e2_2) , .a1(select2_reg3[11:9]) , .a2(select2_reg3[2:0]) , .a3(b3_2) , .a4(e3_2) );
// assign select2_reg3[5:3] = select2_reg2[5:3] ; 
// assign d3_2 = d2_2  ;


// ///////////////////////////////////////////////////////////////
// //                      select4                              //
// ///////////////////////////////////////////////////////////////

// select2 select2_41(.a(select2_reg3[11:9]) , .b(select2_reg3[8:6]) , .c(b3_2) , .d(c3_2) , .a1(select2_reg4[11:9]) , .a2(select2_reg4[8:6]) , .a3(b4_2) , .a4(c4_2) );
// select2 select2_42(.a(select2_reg3[5:3]) , .b(select2_reg3[2:0]) , .c(d3_2) , .d(e3_2) , .a1(select2_reg4[5:3]) , .a2(select2_reg4[2:0]) , .a3(d4_2) , .a4(e4_2) );
// assign select2_reg4[14:12] = select2_reg3[14:12] ; 
// assign a4_2 = a3_2  ;


// ///////////////////////////////////////////////////////////////
// //                      select5                              //
// ///////////////////////////////////////////////////////////////

// select2 select2_51(.a(select2_reg4[8:6]) , .b(select2_reg4[5:3]) , .c(c4_2) , .d(d4_2) , .a1(select2_reg5[8:6]) , .a2(select2_reg5[5:3]) , .a3(c5_2) , .a4(d5_2) );
// assign select2_reg5[14:9] = select2_reg4[14:9] ; 
// assign select2_reg5[2:0] = select2_reg4[2:0] ; 
// assign a5_2 = a4_2  ;
// assign b5_2 = b4_2  ;
// assign e5_2 = e4_2  ;

 

// endmodule 


// module select(
// 	input [4:0] a ,
// 	input [4:0] b ,
// 	input [2:0] c ,
// 	input [2:0] d ,
// 	output reg [4:0] a1,
// 	output reg [4:0] a2,
// 	output reg [2:0] a3,
// 	output reg [2:0] a4
	
// );

// always@(*)begin

// 	if( a < b ) begin 
// 		a1 = a ;
// 		a2 = b ;
// 		a3 = c ;
// 		a4 = d ;
// 	end
// 	else if ( b < a)begin 
// 		a1 = b ;
// 		a2 = a ;
// 		a3 = d ;
// 		a4 = c ;
// 	end
// 	else begin 
// 		if( c <= d )begin
// 			a1 = a ;
// 			a2 = b ;
// 			a3 = c ;
// 			a4 = d ;
// 		end
// 		else begin
// 			a1 = b ;
// 			a2 = a ;
// 			a3 = d ;
// 			a4 = c ;
// 		end
// 	end
// end

// endmodule 


// module select2(
// 	input [2:0] a ,
// 	input [2:0] b ,
// 	input [3:0] c ,
// 	input [3:0] d ,
// 	output reg [2:0] a1,
// 	output reg [2:0] a2,
// 	output reg [3:0] a3,
// 	output reg [3:0] a4
	
// );

// always@(*)begin

// 	if( a < b ) begin 
// 		a1 = a ;
// 		a2 = b ;
// 		a3 = c ;
// 		a4 = d ;
// 	end
// 	else if ( b < a)begin 
// 		a1 = b ;
// 		a2 = a ;
// 		a3 = d ;
// 		a4 = c ;
// 	end
// 	else begin 
// 		if( c <= d )begin
// 			a1 = a ;
// 			a2 = b ;
// 			a3 = c ;
// 			a4 = d ;
// 		end
// 		else begin
// 			a1 = b ;
// 			a2 = a ;
// 			a3 = d ;
// 			a4 = c ;
// 		end
// 	end
// end

// endmodule 