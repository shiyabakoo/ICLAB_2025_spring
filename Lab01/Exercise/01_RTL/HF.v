// module HF(
//     // Input signals
//     input [24:0] symbol_freq,
//     // Output signals
//     output reg [19:0] out_encoded
// );

// //================================================================
// //    Wire & Registers 
// //================================================================
// // Declare the wire/reg you would use in your circuit
// // remember 
// // wire for port connection and cont. assignment
// // reg for proc. assignment
// wire [7:0] a_freq, b_freq, c_freq, d_freq, e_freq; // [7:5] is index, a is 000, b is 001, c is 010, d is 011, e is 100
// //================================================================
// //    DESIGN
// //================================================================
// localparam index_1 = 3'b000;
// localparam index_2 = 3'b001;
// localparam index_3 = 3'b010;
// localparam index_4 = 3'b011;
// localparam index_5 = 3'b100;
// assign a_freq = {index_1, symbol_freq[24:20]};
// assign b_freq = {index_2, symbol_freq[19:15]};
// assign c_freq = {index_3, symbol_freq[14:10]};
// assign d_freq = {index_4, symbol_freq[9:5]};
// assign e_freq = {index_5, symbol_freq[4:0]};

// //================================================================
// //    SORTING 
// //================================================================
// wire [7:0] a, b, c, d, e;
// wire [7:0] net1, net2, net3, net4, net5, net6, net7, net8, net9, net10, net11, net12, net13;
// // stage 1-1
// comparator_stage_1 u1(.in_1(b_freq), .in_2(c_freq), .small_out(net1), .big_out(net2));
// comparator_stage_1 u2(.in_1(d_freq), .in_2(e_freq), .small_out(net3), .big_out(net4));
// // stage 1-2
// comparator_stage_1 u3(.in_1(a_freq), .in_2(net2), .small_out(net5), .big_out(net7));
// comparator_stage_1 u4(.in_1(net1), .in_2(net3), .small_out(net6), .big_out(net8));
// // stage 1-3
// comparator_stage_1 u5(.in_1(net5), .in_2(net8), .small_out(net9), .big_out(net11));
// comparator_stage_1 u6(.in_1(net7), .in_2(net4), .small_out(net10), .big_out(e));
// // stage 1-4
// comparator_stage_1 u7(.in_1(net9), .in_2(net6), .small_out(a), .big_out(net12));
// comparator_stage_1 u8(.in_1(net10), .in_2(net11), .small_out(net13), .big_out(d));
// // stage 1-5
// comparator_stage_1 u9(.in_1(net12), .in_2(net13), .small_out(b), .big_out(c));

// //================================================================
// //    Create Node
// //================================================================
// reg [5:0] node_0;
// reg [6:0] node_1_1, node_1_2;
// reg [7:0] node_2_1, node_2_2, node_2_3, node_2_4;
// assign node_0   = a[4:0] + b[4:0];
// assign node_1_1 = a[4:0] + b[4:0] + c[4:0];
// assign node_1_2 = c[4:0] + d[4:0];
// assign node_2_1 = a[4:0] + b[4:0] + c[4:0] + d[4:0];
// assign node_2_2 = d[4:0] + e[4:0];
// assign node_2_3 = c[4:0] + d[4:0] + a[4:0] + b[4:0];
// assign node_2_4 = a[4:0] + b[4:0] + e[4:0];
// //================================================================
// //    Construct the Huffman Tree
// //================================================================
// reg [19:0] huffman_output;
// always @(*) begin
//     if (node_0 > d[4:0]) begin
//         if (node_1_2 > e[4:0]) begin
//             if (node_0 <= e[4:0]) begin
//                 huffman_output = 20'b0100_0101_0000_0001_0011;
//             end
//             else begin
//                 huffman_output = 20'b0110_0111_0000_0001_0010;
//             end
//         end
//         else begin
//             if (node_2_3 > e[4:0])
//                 huffman_output = 20'b0100_0101_0110_0111_0000;
//             else
//                 huffman_output = 20'b0000_0001_0010_0011_0001;
//         end 
//     end 
//     else begin
//         if (node_1_1 > e[4:0]) begin
//             if (node_0 > c[4:0])
//                 huffman_output = 20'b0010_0011_0000_0010_0011;
//             else
//                 huffman_output = 20'b0000_0001_0001_0010_0011;
//         end
//         else begin
//             if (node_2_1 > e[4:0]) begin
//                 if (node_1_1 > d[4:0]) begin
//                     if (node_0 > c[4:0])
//                         huffman_output = 20'b1110_1111_0110_0010_0000;
//                     else
//                         huffman_output = 20'b1100_1101_0111_0010_0000;
//                 end
//                 else begin
//                     if (node_0 > c[4:0])
//                         huffman_output = 20'b1010_1011_0100_0011_0000;
//                     else
//                         huffman_output = 20'b1000_1001_0101_0011_0000;
//                 end
//             end
//             else begin
//                 if (node_1_1 > d[4:0]) begin
//                     if (node_0 > c[4:0]) 
//                         huffman_output = 20'b0110_0111_0010_0000_0001;
//                     else 
//                         huffman_output = 20'b0100_0101_0011_0000_0001;
//                 end
//                 else begin
//                     if (node_0 > c[4:0]) 
//                         huffman_output = 20'b0010_0011_0000_0001_0001;
//                     else 
//                         huffman_output = 20'b0000_0001_0001_0001_0001;
//                 end
//             end
//         end
//     end
    
// end


// //================================================================
// //    Output encoded
// //================================================================
// always @(*) begin
//     if (a[7:5] == index_1)
//         out_encoded[19:16] = huffman_output[19:16];
//     else if (b[7:5] == index_1)
//         out_encoded[19:16] = huffman_output[15:12];
//     else if (c[7:5] == index_1)
//         out_encoded[19:16] = huffman_output[11:8];
//     else if (d[7:5] == index_1)
//         out_encoded[19:16] = huffman_output[7:4];
//     else if (e[7:5] == index_1)
//         out_encoded[19:16] = huffman_output[3:0];
//     else
//         out_encoded[19:16] = 4'b0000;
// end

// always @(*) begin
//     if (a[7:5] == index_2)
//         out_encoded[15:12] = huffman_output[19:16];
//     else if (b[7:5] == index_2)
//         out_encoded[15:12] = huffman_output[15:12];
//     else if (c[7:5] == index_2)
//         out_encoded[15:12] = huffman_output[11:8];
//     else if (d[7:5] == index_2)
//         out_encoded[15:12] = huffman_output[7:4];
//     else if (e[7:5] == index_2)
//         out_encoded[15:12] = huffman_output[3:0];
//     else
//         out_encoded[15:12] = 4'b0000;
// end

// always @(*) begin
//     if (a[7:5] == index_3)
//         out_encoded[11:8] = huffman_output[19:16];
//     else if (b[7:5] == index_3)
//         out_encoded[11:8] = huffman_output[15:12];
//     else if (c[7:5] == index_3)
//         out_encoded[11:8] = huffman_output[11:8];
//     else if (d[7:5] == index_3)
//         out_encoded[11:8] = huffman_output[7:4];
//     else if (e[7:5] == index_3)
//         out_encoded[11:8] = huffman_output[3:0];
//     else
//         out_encoded[11:8] = 4'b0000;
// end

// always @(*) begin
//     if (a[7:5] == index_4)
//         out_encoded[7:4] = huffman_output[19:16];
//     else if (b[7:5] == index_4)
//         out_encoded[7:4] = huffman_output[15:12];
//     else if (c[7:5] == index_4)
//         out_encoded[7:4] = huffman_output[11:8];
//     else if (d[7:5] == index_4)
//         out_encoded[7:4] = huffman_output[7:4];
//     else if (e[7:5] == index_4)
//         out_encoded[7:4] = huffman_output[3:0];
//     else
//         out_encoded[7:4] = 4'b0000;
// end

// always @(*) begin
//     if (a[7:5] == index_5)
//         out_encoded[3:0] = huffman_output[19:16];
//     else if (b[7:5] == index_5)
//         out_encoded[3:0] = huffman_output[15:12];
//     else if (c[7:5] == index_5)
//         out_encoded[3:0] = huffman_output[11:8];
//     else if (d[7:5] == index_5)
//         out_encoded[3:0] = huffman_output[7:4];
//     else if (e[7:5] == index_5)
//         out_encoded[3:0] = huffman_output[3:0];
//     else
//         out_encoded[3:0] = 4'b0000;
// end

// endmodule


// //================================================================
// //    SUB MODULE
// //================================================================
// module comparator_stage_1 (
//     input [7:0] in_1, 
//     input [7:0] in_2,
//     output reg [7:0] small_out,
//     output reg [7:0] big_out
// );

// always @(*) begin
//     if (in_1[4:0] > in_2[4:0]) begin
//         small_out = in_2;
//         big_out = in_1;
//     end 
//     else if (in_1[4:0] < in_2[4:0]) begin
//         small_out = in_1;
//         big_out = in_2;
//     end 
//     else if (in_1[4:0] == in_2[4:0]) begin
//         if (in_1[7:5] > in_2[7:5]) begin
//             small_out = in_2;
//             big_out = in_1;
//         end else begin
//             small_out = in_1;
//             big_out = in_2;
//         end
//     end 
//     else begin
//         small_out = in_1;
//         big_out = in_2;
//     end
// end
// endmodule



module HF(
    // Input signals
    input [24:0] symbol_freq,
    // Output signals
    output reg [19:0] out_encoded
);

//================================================================
//    Wire & Registers 
//================================================================
wire    [7:0]   a_freq, b_freq, c_freq, d_freq, e_freq;

wire    [7:0]   layer1_out_1, layer1_out_2, layer1_out_3, layer1_out_4;
wire    [7:0]   layer2_out_1, layer2_out_2, layer2_out_3, layer2_out_4;
wire    [7:0]   layer3_out_1, layer3_out_2, layer3_out_3, layer3_out_4;
wire    [7:0]   layer4_out_1, layer4_out_2, layer4_out_3, layer4_out_4;
wire    [7:0]   layer5_out_1, layer5_out_2;
wire    [39:0]  sorted_result;

wire    [4:0]   rank0_freq, rank1_freq, rank2_freq, rank3_freq, rank4_freq;
wire    [2:0]   rank0_id, rank1_id, rank2_id, rank3_id, rank4_id;

wire    [7:0]   add_r0_1_2_3, add_r0_1_2, add_r0_1_4, add_r2_3_4;
wire    [6:0]   add_r3_4, add_r2_3, add_r0_1;

reg     [19:0]  huffman_code;


//================================================================
//    DESIGN
//================================================================
localparam ID_1 = 3'b000;
localparam ID_2 = 3'b001;
localparam ID_3 = 3'b010;
localparam ID_4 = 3'b011;
localparam ID_5 = 3'b100;

assign a_freq = {ID_1, symbol_freq[24:20]};
assign b_freq = {ID_2, symbol_freq[19:15]};
assign c_freq = {ID_3, symbol_freq[14:10]};
assign d_freq = {ID_4, symbol_freq[9:5]};
assign e_freq = {ID_5, symbol_freq[4:0]};


// Sort the symbol_freq
//sort layer 1
sort sort1_1(.in1(a_freq), .in2(b_freq), .out1(layer1_out_1), .out2(layer1_out_2));
sort sort1_2(.in1(c_freq), .in2(d_freq), .out1(layer1_out_3), .out2(layer1_out_4));

//sort layer 2
sort sort2_1(.in1(layer1_out_2), .in2(layer1_out_4), .out1(layer2_out_1), .out2(layer2_out_2));  
sort sort2_2(.in1(layer1_out_3), .in2(e_freq), .out1(layer2_out_3), .out2(layer2_out_4));

//sort layer 3
sort sort3_1(.in1(layer1_out_1), .in2(layer2_out_3), .out1(layer3_out_1), .out2(layer3_out_2));
sort sort3_2(.in1(layer2_out_1), .in2(layer2_out_4), .out1(layer3_out_3), .out2(layer3_out_4));

//sort layer 4
sort sort4_1(.in1(layer3_out_3), .in2(layer3_out_2), .out1(layer4_out_1), .out2(layer4_out_2));
sort sort4_2(.in1(layer2_out_2), .in2(layer3_out_4), .out1(layer4_out_3), .out2(layer4_out_4));

//sort layer 5
sort sort5_1(.in1(layer4_out_2), .in2(layer4_out_3), .out1(layer5_out_1), .out2(layer5_out_2));


assign sorted_result = {layer3_out_1, layer4_out_1, layer5_out_1, layer5_out_2, layer4_out_4};


assign rank0_freq = sorted_result[36:32];
assign rank1_freq = sorted_result[28:24];                
assign rank2_freq = sorted_result[20:16];
assign rank3_freq = sorted_result[12:8];
assign rank4_freq = sorted_result[4:0];

assign rank0_id = layer3_out_1[7:5];
assign rank1_id = layer4_out_1[7:5];
assign rank2_id = layer5_out_1[7:5];
assign rank3_id = layer5_out_2[7:5];
assign rank4_id = layer4_out_4[7:5];



// ALGO
assign add_r0_1_2_3 = rank0_freq + rank1_freq + rank2_freq + rank3_freq;

assign add_r0_1_2 = rank0_freq + rank1_freq + rank2_freq;
assign add_r0_1_4 = rank0_freq + rank1_freq + rank4_freq;

assign add_r0_1 = rank0_freq + rank1_freq;
assign add_r2_3 = rank2_freq + rank3_freq;
assign add_r3_4 = rank3_freq + rank4_freq;

reg [3:0]   huffman_code_a;
reg [3:0]   huffman_code_b;
reg [3:0]   huffman_code_c;
reg [3:0]   huffman_code_d;
reg [3:0]   huffman_code_e;


always @(*) begin
    //  STAGE1 case1
    if(add_r0_1 <= rank2_freq)begin
        if(add_r0_1_2 <= rank3_freq) begin
            if(add_r0_1_2_3 <= rank4_freq) begin
                huffman_code_a = 4'b0000;
                huffman_code_b = 4'b0001;
                huffman_code_c = 4'b0001;
                huffman_code_d = 4'b0001;
                huffman_code_e = 4'b0001;
            end
            else begin
                huffman_code_a = 4'b1000;
                huffman_code_b = 4'b1001;
                huffman_code_c = 4'b0101;
                huffman_code_d = 4'b0011;
                huffman_code_e = 4'b0000;
            end
        end
        else if(add_r0_1_2 <= rank4_freq) begin
            if(add_r0_1_2_3 <= rank4_freq) begin
                huffman_code_a = 4'b0100;
                huffman_code_b = 4'b0101;
                huffman_code_c = 4'b0011;
                huffman_code_d = 4'b0000;
                huffman_code_e = 4'b0001;
            end
            else begin
                huffman_code_a = 4'b1100;
                huffman_code_b = 4'b1101;
                huffman_code_c = 4'b0111;
                huffman_code_d = 4'b0010;
                huffman_code_e = 4'b0000;
            end
        end
        else begin
            huffman_code_a = 4'b0000;
            huffman_code_b = 4'b0001;
            huffman_code_c = 4'b0001;
            huffman_code_d = 4'b0010;
            huffman_code_e = 4'b0011;
        end
    end


    //  STAGE1 case2
    else if(add_r0_1 <= rank3_freq) begin
        if(add_r0_1_2 <= rank3_freq) begin
            if(add_r0_1_2_3 <= rank4_freq) begin
                huffman_code_a = 4'b0010;
                huffman_code_b = 4'b0011;
                huffman_code_c = 4'b0000;
                huffman_code_d = 4'b0001;
                huffman_code_e = 4'b0001;
            end
            else begin
                huffman_code_a = 4'b1010;
                huffman_code_b = 4'b1011;
                huffman_code_c = 4'b0100;
                huffman_code_d = 4'b0011;
                huffman_code_e = 4'b0000;
            end
        end

        else if(add_r0_1_2 <= rank4_freq) begin
            if(add_r0_1_2_3 <= rank4_freq) begin
                huffman_code_a = 4'b0110;
                huffman_code_b = 4'b0111;
                huffman_code_c = 4'b0010;
                huffman_code_d = 4'b0000;
                huffman_code_e = 4'b0001;
            end
            else begin
                huffman_code_a = 4'b1110;
                huffman_code_b = 4'b1111;
                huffman_code_c = 4'b0110;
                huffman_code_d = 4'b0010;
                huffman_code_e = 4'b0000;
            end
        end

        else begin
            huffman_code_a = 4'b0010;
            huffman_code_b = 4'b0011;
            huffman_code_c = 4'b0000;
            huffman_code_d = 4'b0010;
            huffman_code_e = 4'b0011;
        end
    end


    //  STAGE1 case3
    else if(add_r0_1 <= rank4_freq) begin
        if(add_r2_3 <= rank4_freq) begin
            if(add_r0_1_2_3 <= rank4_freq) begin
                huffman_code_a = 4'b0000;
                huffman_code_b = 4'b0001;
                huffman_code_c = 4'b0010;
                huffman_code_d = 4'b0011;
                huffman_code_e = 4'b0001;
            end
            else begin
                huffman_code_a = 4'b0100;
                huffman_code_b = 4'b0101;
                huffman_code_c = 4'b0110;
                huffman_code_d = 4'b0111;
                huffman_code_e = 4'b0000;
            end
        end
        else begin
            huffman_code_a = 4'b0100;
            huffman_code_b = 4'b0101;
            huffman_code_c = 4'b0000;
            huffman_code_d = 4'b0001;
            huffman_code_e = 4'b0011;
        end
    end

    //  STAGE1 case4
    else begin
        huffman_code_a = 4'b0110; 
        huffman_code_b = 4'b0111; 
        huffman_code_c = 4'b0000; 
        huffman_code_d = 4'b0001;
        huffman_code_e = 4'b0010;
    end
end

always @(*) begin
    if (layer3_out_1[7:5] == ID_1)
        out_encoded[19:16] = huffman_code_a;
    else if (layer4_out_1[7:5] == ID_1)
        out_encoded[19:16] = huffman_code_b;
    else if (layer5_out_1[7:5] == ID_1)
        out_encoded[19:16] = huffman_code_c;
    else if (layer5_out_2[7:5] == ID_1)
        out_encoded[19:16] = huffman_code_d;
    else 
        out_encoded[19:16] = huffman_code_e;
end

always @(*) begin
    if (layer3_out_1[7:5] == ID_2)
        out_encoded[15:12] = huffman_code_a;
    else if (layer4_out_1[7:5] == ID_2)
        out_encoded[15:12] = huffman_code_b;
    else if (layer5_out_1[7:5] == ID_2)
        out_encoded[15:12] = huffman_code_c;
    else if (layer5_out_2[7:5] == ID_2)
        out_encoded[15:12] = huffman_code_d;
    else 
        out_encoded[15:12] = huffman_code_e;
end

always @(*) begin
    if (layer3_out_1[7:5] == ID_3)
        out_encoded[11:8] = huffman_code_a;
    else if (layer4_out_1[7:5] == ID_3)
        out_encoded[11:8] = huffman_code_b;
    else if (layer5_out_1[7:5] == ID_3)
        out_encoded[11:8] = huffman_code_c;
    else if (layer5_out_2[7:5] == ID_3)
        out_encoded[11:8] = huffman_code_d;
    else 
        out_encoded[11:8] = huffman_code_e;
end

always @(*) begin
    if (layer3_out_1[7:5] == ID_4)
        out_encoded[7:4] = huffman_code_a;
    else if (layer4_out_1[7:5] == ID_4)
        out_encoded[7:4] = huffman_code_b;
    else if (layer5_out_1[7:5] == ID_4)
        out_encoded[7:4] = huffman_code_c;
    else if (layer5_out_2[7:5] == ID_4)
        out_encoded[7:4] = huffman_code_d;
    else 
        out_encoded[7:4] = huffman_code_e;
end

always @(*) begin
    if (layer3_out_1[7:5] ==ID_5)
        out_encoded[3:0] = huffman_code_a;
    else if (layer4_out_1[7:5] == ID_5)
        out_encoded[3:0] = huffman_code_b;
    else if (layer5_out_1[7:5] == ID_5)
        out_encoded[3:0] = huffman_code_c;
    else if (layer5_out_2[7:5] == ID_5)
        out_encoded[3:0] = huffman_code_d;
    else 
        out_encoded[3:0] = huffman_code_e;
end




endmodule


module sort(
    input      [7:0]  in1,
    input      [7:0]  in2,
    output reg [7:0] out1,
    output reg [7:0] out2
);

    // always @(*) begin
    //     if((in1[4:0]) < (in2[4:0])) begin
    //         out1 = in1;
    //         out2 = in2;
    //     end
    //     else if ((in1[4:0]) > (in2[4:0]))begin
    //         out1 = in2;
    //         out2 = in1;
    //     end 
    //     else begin
    //         if((in1[7:5]) < (in2[7:5])) begin
    //             out1 = in1;
    //             out2 = in2;
    //         end
    //         else begin
    //             out1 = in2;
    //             out2 = in1;
    //         end
    //     end
    // end

    //==============================================

    //  SMALLER!!!
    //  ���P�_�u�j��v�M�u�p��v��A�A���T�Ρu==�v�ӳB�z�۵������p�C
    //  �o�ϱo��X�u�㪾�D���e��ӱ��󥢱ѮɡA�C 5 �쥲�w�۵��A
    //  �i�ӥu�ݭn�B�~��{�@�� 3 �쪺����ӨM�w���G�C

    //  First, the code checks for "greater than" and "less than" conditions,
    //  then explicitly uses "==" to handle the equality case.
    //  This allows the synthesis tool to deduce that if the first two conditions fail,
    //  the lower 5 bits must be equal, and therefore only an additional 3-bit comparison is needed to determine the result.
    always @(*) begin
        if (in1[4:0] > in2[4:0]) begin
            out1 = in2;
            out2 = in1;
        end else if (in1[4:0] < in2[4:0]) begin
            out1 = in1;
            out2 = in2;
        end else if (in1[4:0] == in2[4:0]) begin
            if (in1[7:5] > in2[7:5]) begin
                out1 = in2;
                out2 = in1;
            end else begin
                out1 = in1;
                out2 = in2;
            end
        end else begin
            out1 = in1;
            out2 = in2;
        end
    end

endmodule



















