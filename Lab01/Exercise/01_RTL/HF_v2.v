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
wire [9:0] a_freq, b_freq, c_freq, d_freq, e_freq; // [7:5] is index, a is 000, b is 001, c is 010, d is 011, e is 100
//================================================================
//    DESIGN
//================================================================
assign a_freq = {5'b00001, symbol_freq[24:20]};
assign b_freq = {5'b00010, symbol_freq[19:15]};
assign c_freq = {5'b00100, symbol_freq[14:10]};
assign d_freq = {5'b01000, symbol_freq[9:5]};
assign e_freq = {5'b10000, symbol_freq[4:0]};

//================================================================
//    SORTING STAGE 1
//================================================================
wire [9:0] stage_1_out1, stage_1_out2, stage_1_out3 ,stage_1_out4 ,stage_1_out5;
// stage 1-1
wire [9:0] big_out_1_1, small_out_1_1;
comparator_stage_1 u1(.in_1(b_freq), .in_2(c_freq), .small_out(small_out_1_1), .big_out(big_out_1_1));
wire [9:0] big_out_1_2, small_out_1_2;
comparator_stage_1 u2(.in_1(d_freq), .in_2(e_freq), .small_out(small_out_1_2), .big_out(big_out_1_2));
// stage 1-2
wire [9:0] big_out_2_1, small_out_2_1;
comparator_stage_1 u3(.in_1(a_freq), .in_2(big_out_1_1), .small_out(small_out_2_1), .big_out(big_out_2_1));
wire [9:0] big_out_2_2, small_out_2_2;
comparator_stage_1 u4(.in_1(small_out_1_1), .in_2(small_out_1_2), .small_out(small_out_2_2), .big_out(big_out_2_2));
// stage 1-3
wire [9:0] big_out_3_1, small_out_3_1;
comparator_stage_1 u5(.in_1(small_out_2_1), .in_2(big_out_2_2), .small_out(small_out_3_1), .big_out(big_out_3_1));
wire [9:0] big_out_3_2, small_out_3_2;
comparator_stage_1 u6(.in_1(big_out_2_1), .in_2(big_out_1_2), .small_out(small_out_3_2), .big_out(stage_1_out5));
// stage 1-4
wire [9:0] big_out_4_1, small_out_4_1;
comparator_stage_1 u7(.in_1(small_out_3_1), .in_2(small_out_2_2), .small_out(stage_1_out1), .big_out(big_out_4_1));
wire [9:0] big_out_4_2, small_out_4_2;
comparator_stage_1 u8(.in_1(small_out_3_2), .in_2(big_out_3_1), .small_out(small_out_4_2), .big_out(stage_1_out4));
// stage 1-5
wire [9:0] big_out_5_1, small_out_5_1;
comparator_stage_1 u9(.in_1(big_out_4_1), .in_2(small_out_4_2), .small_out(stage_1_out2), .big_out(stage_1_out3));


// stage 1 to stage 2
wire [5:0] adder_1;
wire [10:0] stage_2_in1, stage_2_in2, stage_2_in3, stage_2_in4;
assign adder_1 = stage_1_out1[4:0] + stage_1_out2[4:0];
assign stage_2_in1 = {2'b01, {stage_1_out1[9:5] + stage_1_out2[9:5]}, adder_1};
assign stage_2_in2 = {stage_1_out3[9:5], 1'b0, stage_1_out3[4:0]};
assign stage_2_in3 = {stage_1_out4[9:5], 1'b0, stage_1_out4[4:0]};
assign stage_2_in4 = {stage_1_out5[9:5], 1'b0, stage_1_out5[4:0]};
//================================================================
//    SORTING STAGE 2
//================================================================
// satge 2-1
wire [10:0] stage_2_out1, stage_2_out2, stage_2_out3, stage_2_out4;
wire [10:0] stage2_net_1, stage2_net_2, stage2_net_3, stage2_net_4, stage2_net_5, stage2_net_6;
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
wire [11:0] stage_3_in1, stage_3_in2, stage_3_in3;
assign adder_2 = stage_2_out1[5:0] + stage_2_out2[5:0];
assign stage_3_in1 = {2'b10, {stage_2_out1[10:6] + stage_2_out2[10:6]}, adder_2};
assign stage_3_in2 = {stage_2_out3[10:6], 1'b0, stage_2_out3[5:0]};
assign stage_3_in3 = {stage_2_out4[10:6], 1'b0, stage_2_out4[5:0]};

//================================================================
//    SORTING STAGE 3
//================================================================
// stage 3-1
wire [11:0] stage_3_out1, stage_3_out2, stage_3_out3;
wire [11:0] stage_3_net_1, stage_3_net_2, stage_3_net_3;
comparator_stage_3 u15(.in_1(stage_3_in1), .in_2(stage_3_in2), .small_out(stage_3_net_1), .big_out(stage_3_net_2));
// stage 3-2
comparator_stage_3 u16(.in_1(stage_3_net_2), .in_2(stage_3_in3), .small_out(stage_3_net_3), .big_out(stage_3_out3));
// stage 3-3
comparator_stage_3 u17(.in_1(stage_3_net_1), .in_2(stage_3_net_3), .small_out(stage_3_out1), .big_out(stage_3_out2));

// stage 3 to stage 4
wire [7:0] adder_3;
wire [12:0] stage_4_in1, stage_4_in2;
assign adder_3 = stage_3_out1[6:0] + stage_3_out2[6:0];
assign stage_4_in1 = {2'b11, {stage_3_out1[11:7] + stage_3_out2[11:7]},adder_3};
assign stage_4_in2 = {stage_3_out3[11:7], 1'b0, stage_3_out3[6:0]};

//================================================================
//    SORTING STAGE 4
//================================================================
// stage 4
wire [12:0] stage_4_out1, stage_4_out2;
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

// wire [7:0] a_temp, b_temp, c_temp, d_temp, e_temp;
// wire [3:0] a_encode, b_encode, c_encode, d_encode, e_encode;

// assign a_temp[0] = (stage_1_out1[5])? 1 : 0; // a_temp[0]
// assign a_temp[1] = (stage_1_out2[5])? 1 : 0; // a_temp[1]
// assign a_temp[2] = (stage_2_out1[6])? 1 : 0; // a_temp[2]
// assign a_temp[3] = (stage_2_out2[6])? 1 : 0; // a_temp[3]
// assign a_temp[4] = (stage_3_out1[7])? 1 : 0; // a_temp[4]
// assign a_temp[5] = (stage_3_out2[7])? 1 : 0; // a_temp[5]
// assign a_temp[6] = (stage_4_out1[8])? 1 : 0; // a_temp[6]  
// assign a_temp[7] = (stage_4_out2[8])? 1 : 0; // a_temp[7]

// assign b_temp[0] = (stage_1_out1[6])? 1 : 0;
// assign b_temp[1] = (stage_1_out2[6])? 1 : 0;
// assign b_temp[2] = (stage_2_out1[7])? 1 : 0;
// assign b_temp[3] = (stage_2_out2[7])? 1 : 0;
// assign b_temp[4] = (stage_3_out1[8])? 1 : 0;
// assign b_temp[5] = (stage_3_out2[8])? 1 : 0;
// assign b_temp[6] = (stage_4_out1[9])? 1 : 0;
// assign b_temp[7] = (stage_4_out2[9])? 1 : 0;

// assign c_temp[0] = (stage_1_out1[7])? 1 : 0;
// assign c_temp[1] = (stage_1_out2[7])? 1 : 0;
// assign c_temp[2] = (stage_2_out1[8])? 1 : 0;
// assign c_temp[3] = (stage_2_out2[8])? 1 : 0;
// assign c_temp[4] = (stage_3_out1[9])? 1 : 0;
// assign c_temp[5] = (stage_3_out2[9])? 1 : 0;
// assign c_temp[6] = (stage_4_out1[10])? 1 : 0;
// assign c_temp[7] = (stage_4_out2[10])? 1 : 0;

// assign d_temp[0] = (stage_1_out1[8])? 1 : 0;
// assign d_temp[1] = (stage_1_out2[8])? 1 : 0;
// assign d_temp[2] = (stage_2_out1[9])? 1 : 0;
// assign d_temp[3] = (stage_2_out2[9])? 1 : 0;
// assign d_temp[4] = (stage_3_out1[10])? 1 : 0;
// assign d_temp[5] = (stage_3_out2[10])? 1 : 0;
// assign d_temp[6] = (stage_4_out1[11])? 1 : 0;
// assign d_temp[7] = (stage_4_out2[11])? 1 : 0;

// assign e_temp[0] = (stage_1_out1[9])? 1 : 0;
// assign e_temp[1] = (stage_1_out2[9])? 1 : 0;
// assign e_temp[2] = (stage_2_out1[10])? 1 : 0;
// assign e_temp[3] = (stage_2_out2[10])? 1 : 0;
// assign e_temp[4] = (stage_3_out1[11])? 1 : 0;
// assign e_temp[5] = (stage_3_out2[11])? 1 : 0;
// assign e_temp[6] = (stage_4_out1[12])? 1 : 0;
// assign e_temp[7] = (stage_4_out2[12])? 1 : 0;

// compress_2bit A(
//     .in_data     (a_temp),
//     .out_data    (a_encode)
// );

// compress_2bit B(
//     .in_data     (b_temp),
//     .out_data    (b_encode)
// );

// compress_2bit C(
//     .in_data     (c_temp),
//     .out_data    (c_encode)
// );
// compress_2bit D(
//     .in_data     (d_temp),
//     .out_data    (d_encode)
// );

// compress_2bit E(
//     .in_data     (e_temp),
//     .out_data    (e_encode)
// );

// assign out_encoded = {a_encode, b_encode, c_encode, d_encode, e_encode};

endmodule


//================================================================
//    SUB MODULE
//================================================================
module comparator_stage_1 (
    input [9:0] in_1, // [5:0] is value, [8:6] is index
    input [9:0] in_2,
    output [9:0] small_out,
    output [9:0] big_out
);
reg compare;
// assign compare = (in_1[4:0] > in_2[4:0])? 1 : 0;  // if in_1 is bigger => compare = 1
always @(*) begin
    if (in_1[4:0] == in_2[4:0]) begin
        if ((in_1[9:5] !== 5'b00001) && (in_1[9:5] !== 5'b00010) && (in_1[9:5] !== 5'b00100) && (in_1[9:5] !== 5'b01000) && (in_1[9:5] !== 5'b10000)) compare = 1'b0;
        else if (in_1[9:5] < in_2[9:5]) compare = 1'b0;
        else compare = 1'b1; 
    end
    else begin
        compare = (in_1[4:0] > in_2[4:0])? 1 : 0;
    end
end

assign big_out = (compare)? in_1 : in_2;
assign small_out = (compare)? in_2 : in_1;

endmodule

module comparator_stage_2 (
    input [10:0] in_1, // [5:0] is value, [8:6] is index
    input [10:0] in_2,
    output [10:0] small_out,
    output [10:0] big_out
);
reg compare;
// assign compare = (in_1[5:0] > in_2[5:0])? 1 : 0;  // if in_1 is bigger => compare = 1
always @(*) begin
    if (in_1[5:0] == in_2[5:0]) begin
        if ((in_1[10:6] !== 5'b00001) && (in_1[10:6] !== 5'b00010) && (in_1[10:6] !== 5'b00100) && (in_1[10:6] !== 5'b01000) && (in_1[10:6] !== 5'b10000)) compare = 1'b0;
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
    input [11:0] in_1, // [5:0] is value, [8:6] is index
    input [11:0] in_2,
    output [11:0] small_out,
    output [11:0] big_out
);
reg compare;
// assign compare = (in_1[6:0] > in_2[6:0])? 1 : 0;  // if in_1 is bigger => compare = 1
always @(*) begin
    if (in_1[6:0] == in_2[6:0]) begin
        if ((in_1[11:7] !== 5'b00001) && (in_1[11:7] !== 5'b00010) && (in_1[11:7] !== 5'b00100) && (in_1[11:7] !== 5'b01000) && (in_1[11:7] !== 5'b10000)) compare = 1'b0;
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
    input [12:0] in_1, // [5:0] is value, [8:6] is index
    input [12:0] in_2,
    output [12:0] small_out,
    output [12:0] big_out
);
reg compare;
// assign compare = (in_1[7:0] > in_2[7:0])? 1 : 0;  // if in_1 is bigger => compare = 1
always @(*) begin
    if (in_1[7:0] == in_2[7:0]) begin
        if ((in_1[12:8] !== 5'b00001) && (in_1[12:8] !== 5'b00010) && (in_1[12:8] !== 5'b00100) && (in_1[12:8] !== 5'b01000) && (in_1[12:8] !== 5'b10000)) compare = 1'b0;
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