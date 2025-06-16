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
// assign a_freq = {3'b000, symbol_freq[24:20]};
// assign b_freq = {3'b001, symbol_freq[19:15]};
// assign c_freq = {3'b010, symbol_freq[14:10]};
// assign d_freq = {3'b011, symbol_freq[9:5]};
// assign e_freq = {3'b100, symbol_freq[4:0]};

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
// reg [6:0] node_1;
// reg [7:0] node_2;
// reg       branch;
// reg [1:0] second_branch;
// wire case_1; // node_1 > e[4:0]
// wire case_2; // node_2 > e[4:0]
// wire case_3; // node_1 <= d[4:0]
// wire case_4; // node_0 <= c[4:0]
// wire case_5; //
// assign node_0 = a[4:0] + b[4:0];
// assign branch = (node_0 > d[4:0])? 1 : 0;

// always @(*) begin
//     if (branch)
//         node_1 = c[4:0] + d[4:0];
//     else
//         node_1 = node_0 + c[4:0];
// end

// always @(*) begin
//     if (branch) begin
//         if (node_1 > e[4:0]) begin
//             node_2 = node_0 + e[4:0];
//             second_branch = 2'b11;
//         end
//         else begin
//             node_2 = node_0 + node_1; 
//             second_branch = 2'b10;
//         end
//     end
//     else begin
//         if (node_1 > e[4:0]) begin
//             node_2 = e[4:0] + d[4:0];
//             second_branch = 2'b01;
//         end
//         else begin
//             node_2 = node_1 + d[4:0]; 
//             second_branch = 2'b00;
//         end
        
//     end
// end
// //================================================================
// //    Construct the Huffman Tree
// //================================================================
// reg [19:0] Huffman_output;
// always @(*) begin
//     if (second_branch == 2'b00) begin
//        if (node_2 > e[4:0]) begin
//             if (node_1 <= d[4:0]) begin
//                 if (node_0 <= c[4:0])
//                     Huffman_output = 20'b1000_1001_0101_0011_0000;
//                 else
//                     Huffman_output = 20'b1010_1011_0100_0011_0000;
//             end
//             else begin
//                 if (node_0 <= c[4:0])
//                     Huffman_output = 20'b1100_1101_0111_0010_0000;
//                 else
//                     Huffman_output = 20'b1110_1111_0110_0010_0000;
//             end
//        end 
//        else begin
//             if (node_1 <= d[4:0]) begin
//                 if (node_0 <= c[4:0])
//                     Huffman_output = 20'b0000_0001_0001_0001_0001;
//                 else
//                     Huffman_output = 20'b0010_0011_0000_0001_0001;
//             end
//             else begin
//                 if (node_0 <= c[4:0])
//                     Huffman_output = 20'b0100_0101_0011_0000_0001;
//                 else
//                     Huffman_output = 20'b0110_0111_0010_0000_0001;
//             end
//        end
//     end
//     else if (second_branch == 2'b01) begin
//         if (node_1 >= node_2) begin
//             if (node_0 <= c[4:0]) 
//                 Huffman_output = 20'b0100_0101_0011_0000_0001;
//             else
//                 Huffman_output = 20'b0110_0111_0010_0000_0001;
//         end
//         else begin
//             if (node_0 <= c[4:0]) 
//                 Huffman_output = 20'b0000_0001_0001_0010_0011;
//             else
//                 Huffman_output = 20'b0010_0011_0000_0010_0011;
//         end
//     end
//     else if (second_branch == 2'b10) begin
//         if (node_2 <= e[4:0])
//             Huffman_output = 20'b0000_0001_0010_0011_0001;
//         else
//             Huffman_output = 20'b0100_0101_0110_0111_0000; 
//     end
//     else begin
//         if (node_1 >= node_2) begin
//             if (node_0 <= e[4:0])
//                 Huffman_output = 20'b0000_0001_0010_0011_0001;
//             else
//                 Huffman_output = 20'b0010_0011_0010_0011_0000;
            
//         end
//         else begin
//             if (node_0 <= e[4:0])
//                 Huffman_output = 20'b0100_0101_0000_0001_0011;
//             else
//                 Huffman_output = 20'b0110_0111_0000_0001_0010;
//         end
//     end
// end

// //================================================================
// //    Output encoded
// //================================================================
// wire [2:0] index_1;
// wire [2:0] index_2;
// wire [2:0] index_3;
// wire [2:0] index_4;
// wire [2:0] index_5;
// reg [3:0] output_to_encoded [0:4];
// assign index_1 = a[7:5];
// assign index_2 = b[7:5];
// assign index_3 = c[7:5];
// assign index_4 = d[7:5];
// assign index_5 = e[7:5];

// always @(*) begin
//     out_encoded[19:16] = output_to_encoded[0];
//     out_encoded[15:12] = output_to_encoded[1];
//     out_encoded[11:8]  = output_to_encoded[2];
//     out_encoded[7:4]   = output_to_encoded[3];
//     out_encoded[3:0]   = output_to_encoded[4]; 
// end

// integer i;
// always @(*) begin
//     for (i = 0; i < 5; i = i + 1) begin
//         if (i == index_1)
//             output_to_encoded[i] = Huffman_output[19:16];
//         else if (i == index_2)
//             output_to_encoded[i] = Huffman_output[15:12];
//         else if (i == index_3)
//             output_to_encoded[i] = Huffman_output[11:8];
//         else if (i == index_4)
//             output_to_encoded[i] = Huffman_output[7:4];
//         else if (i == index_5)
//             output_to_encoded[i] = Huffman_output[3:0];
//         else
//             output_to_encoded[i] = 4'b0; // 其他位置給預設值
//     end
// end

// endmodule


// //================================================================
// //    SUB MODULE
// //================================================================
// module comparator_stage_1 (
//     input [7:0] in_1, // [5:0] is value, [8:6] is index
//     input [7:0] in_2,
//     output reg [7:0] small_out,
//     output reg [7:0] big_out
// );
// // assign compare = (in_1[4:0] > in_2[4:0])? 1 : 0;  // if in_1 is bigger => compare = 1
// always @(*) begin
//     if (in_1[4:0] == in_2[4:0]) begin
//         if (in_1[7:5] < in_2[7:5]) begin
//             big_out  = in_2;
//             small_out = in_1;
//         end
//         else begin
//             big_out = in_1;
//             small_out = in_2;
//         end
//     end
//     else begin
//         if (in_1[4:0] > in_2[4:0]) begin
//             big_out = in_1;
//             small_out = in_2;
//         end
//         else begin
//             big_out = in_2;
//             small_out = in_1;
//         end
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
// Declare the wire/reg you would use in your circuit
// remember 
// wire for port connection and cont. assignment
// reg for proc. assignment
wire [7:0] a_freq, b_freq, c_freq, d_freq, e_freq; // [7:5] is index, a is 000, b is 001, c is 010, d is 011, e is 100
//================================================================
//    DESIGN
//================================================================
assign a_freq = {3'b000, symbol_freq[24:20]};
assign b_freq = {3'b001, symbol_freq[19:15]};
assign c_freq = {3'b010, symbol_freq[14:10]};
assign d_freq = {3'b011, symbol_freq[9:5]};
assign e_freq = {3'b100, symbol_freq[4:0]};

//================================================================
//    SORTING 
//================================================================
wire [7:0] a, b, c, d, e;
wire [7:0] net1, net2, net3, net4, net5, net6, net7, net8, net9, net10, net11, net12, net13;
// stage 1-1
comparator_stage_1 u1(.in_1(b_freq), .in_2(c_freq), .small_out(net1), .big_out(net2));
comparator_stage_1 u2(.in_1(d_freq), .in_2(e_freq), .small_out(net3), .big_out(net4));
// stage 1-2
comparator_stage_1 u3(.in_1(a_freq), .in_2(net2), .small_out(net5), .big_out(net7));
comparator_stage_1 u4(.in_1(net1), .in_2(net3), .small_out(net6), .big_out(net8));
// stage 1-3
comparator_stage_1 u5(.in_1(net5), .in_2(net8), .small_out(net9), .big_out(net11));
comparator_stage_1 u6(.in_1(net7), .in_2(net4), .small_out(net10), .big_out(e));
// stage 1-4
comparator_stage_1 u7(.in_1(net9), .in_2(net6), .small_out(a), .big_out(net12));
comparator_stage_1 u8(.in_1(net10), .in_2(net11), .small_out(net13), .big_out(d));
// stage 1-5
comparator_stage_1 u9(.in_1(net12), .in_2(net13), .small_out(b), .big_out(c));

//================================================================
//    Create Node
//================================================================
reg [5:0] node_0;
reg [6:0] node_1;
reg [7:0] node_2;
reg       branch;
reg [1:0] second_branch;
wire case_1; // node_1 > e[4:0]
wire case_2; // node_2 > e[4:0]
wire case_3; // node_1 > d[4:0]
wire case_4; // node_0 > c[4:0]
wire case_5; // node_0 > e[4:0]
assign node_0 = a[4:0] + b[4:0];
assign branch = (node_0 > d[4:0])? 1 : 0;
assign case_1 = (node_1 > e[4:0])? 1 : 0;
assign case_2 = (node_2 > e[4:0])? 1 : 0;
assign case_3 = (node_1 > d[4:0])? 1 : 0;
assign case_4 = (node_0 > c[4:0])? 1 : 0;
assign case_5 = (node_0 > e[4:0])? 1 : 0;

always @(*) begin
    if (branch)
        node_1 = c[4:0] + d[4:0];
    else
        node_1 = node_0 + c[4:0];
end
always @(*) begin
    if (branch) begin
        if (case_1) begin
            node_2 = node_0 + e[4:0];
        end
        else begin
            node_2 = node_0 + node_1; 
        end
    end
    else begin
        if (case_1) begin
            node_2 = e[4:0] + d[4:0];
        end
        else begin
            node_2 = node_1 + d[4:0]; 
        end
        
    end
end

always @(*) begin
    if (branch) begin
        if (case_1) begin
            second_branch = 2'b11;
        end
        else begin
            second_branch = 2'b10;
        end
    end
    else begin
        if (case_1) begin
            second_branch = 2'b01;
        end
        else begin
            second_branch = 2'b00;
        end
        
    end
end
//================================================================
//    Construct the Huffman Tree
//================================================================
reg [19:0] Huffman_output;
always @(*) begin
    if (second_branch == 2'b00) begin
       if (case_2) begin
            if (case_3) begin
                if (case_4)
                    Huffman_output = 20'b1110_1111_0110_0010_0000;
                else
                    Huffman_output = 20'b1100_1101_0111_0010_0000;
            end
            else begin
                if (case_4)
                    Huffman_output = 20'b1010_1011_0100_0011_0000;
                else
                    Huffman_output = 20'b1000_1001_0101_0011_0000;
            end
       end 
       else begin
            if (case_3) begin
                if (case_4)
                    Huffman_output = 20'b0110_0111_0010_0000_0001;   
                else
                    Huffman_output = 20'b0100_0101_0011_0000_0001;
            end
            else begin
                if (case_4)
                    Huffman_output = 20'b0010_0011_0000_0001_0001;
                else
                    Huffman_output = 20'b0000_0001_0001_0001_0001;
            end
       end
    end
    else if (second_branch == 2'b01) begin
        if (node_1 < node_2) begin
            if (case_4) 
                Huffman_output = 20'b0010_0011_0000_0010_0011;
            else
                Huffman_output = 20'b0000_0001_0001_0010_0011;
        end
        else begin
            if (case_4) 
                Huffman_output = 20'b0110_0111_0010_0000_0001;
            else
                Huffman_output = 20'b0100_0101_0011_0000_0001;
            
        end
    end
    else if (second_branch == 2'b10) begin
        if (case_2)
            Huffman_output = 20'b0100_0101_0110_0111_0000; 
        else
            Huffman_output = 20'b0000_0001_0010_0011_0001;
    end
    else begin
        if (node_1 < node_2) begin
            if (case_5)
                Huffman_output = 20'b0110_0111_0000_0001_0010;
            else
                Huffman_output = 20'b0100_0101_0000_0001_0011;
        end
        else begin
            if (case_5)
                Huffman_output = 20'b0010_0011_0010_0011_0000;
            else
                Huffman_output = 20'b0000_0001_0010_0011_0001;
        end
    end
end

//================================================================
//    Output encoded
//================================================================
wire [2:0] index_1;
wire [2:0] index_2;
wire [2:0] index_3;
wire [2:0] index_4;
wire [2:0] index_5;
reg [3:0] output_to_encoded [0:4];
assign index_1 = a[7:5];
assign index_2 = b[7:5];
assign index_3 = c[7:5];
assign index_4 = d[7:5];
assign index_5 = e[7:5];


genvar i;
generate 
for (i = 0; i < 5; i = i + 1) begin : output_loop
    always @(*) begin
        if (i == index_1)
            output_to_encoded[i] = Huffman_output[19:16];
        else if (i == index_2)
            output_to_encoded[i] = Huffman_output[15:12];
        else if (i == index_3)
            output_to_encoded[i] = Huffman_output[11:8];
        else if (i == index_4)
            output_to_encoded[i] = Huffman_output[7:4];
        else if (i == index_5)
            output_to_encoded[i] = Huffman_output[3:0];
        else
            output_to_encoded[i] = 4'b0; 
    end
end
    
endgenerate
always @(*) begin
    out_encoded[19:16] = output_to_encoded[0];
    out_encoded[15:12] = output_to_encoded[1];
    out_encoded[11:8]  = output_to_encoded[2];
    out_encoded[7:4]   = output_to_encoded[3];
    out_encoded[3:0]   = output_to_encoded[4]; 
end

endmodule


//================================================================
//    SUB MODULE
//================================================================
// module comparator_stage_1 (
//     input [7:0] in_1, // [5:0] is value, [8:6] is index
//     input [7:0] in_2,
//     output reg [7:0] small_out,
//     output reg [7:0] big_out
// );
// assign compare = (in_1[4:0] > in_2[4:0])? 1 : 0;  // if in_1 is bigger => compare = 1
// always @(*) begin
//     if (in_1[4:0] == in_2[4:0]) begin
//         if (in_1[7:5] < in_2[7:5]) begin
//             big_out  = in_2;
//             small_out = in_1;
//         end
//         else begin
//             big_out = in_1;
//             small_out = in_2;
//         end
//     end
//     else begin
//         if (in_1[4:0] > in_2[4:0]) begin
//             big_out = in_1;
//             small_out = in_2;
//         end
//         else begin
//             big_out = in_2;
//             small_out = in_1;
//         end
//     end
// end
// endmodule
module comparator_stage_1 (
    input [7:0] in_1, // [5:0] is value, [8:6] is index
    input [7:0] in_2,
    output [7:0] small_out,
    output [7:0] big_out
);
reg compare;
// assign compare = (in_1[4:0] > in_2[4:0])? 1 : 0;  // if in_1 is bigger => compare = 1
always @(*) begin
    if (in_1[4:0] == in_2[4:0]) begin
        if (in_1[7:5] < in_2[7:5]) compare = 1'b0;
        else compare = 1'b1; 
    end
    else begin
        compare = (in_1[4:0] > in_2[4:0])? 1 : 0;
    end
end

assign big_out = (compare)? in_1 : in_2;
assign small_out = (compare)? in_2 : in_1;

endmodule


