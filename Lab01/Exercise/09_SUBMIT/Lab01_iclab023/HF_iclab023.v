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
localparam index_1 = 3'b000;
localparam index_2 = 3'b001;
localparam index_3 = 3'b010;
localparam index_4 = 3'b011;
localparam index_5 = 3'b100;
assign a_freq = {index_1, symbol_freq[24:20]};
assign b_freq = {index_2, symbol_freq[19:15]};
assign c_freq = {index_3, symbol_freq[14:10]};
assign d_freq = {index_4, symbol_freq[9:5]};
assign e_freq = {index_5, symbol_freq[4:0]};

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
reg [6:0] node_1_1, node_1_2;
reg [7:0] node_2_1, node_2_2, node_2_3, node_2_4;
assign node_0   = a[4:0] + b[4:0];
assign node_1_1 = a[4:0] + b[4:0] + c[4:0];
assign node_1_2 = c[4:0] + d[4:0];
assign node_2_1 = a[4:0] + b[4:0] + c[4:0] + d[4:0];
assign node_2_2 = d[4:0] + e[4:0];
assign node_2_3 = c[4:0] + d[4:0] + a[4:0] + b[4:0];
assign node_2_4 = a[4:0] + b[4:0] + e[4:0];
//================================================================
//    Construct the Huffman Tree
//================================================================
reg [19:0] huffman_output;
always @(*) begin
    if (node_0 > d[4:0]) begin
        if (node_1_2 > e[4:0]) begin
            if (node_0 <= e[4:0]) begin
                huffman_output = 20'b0100_0101_0000_0001_0011;
            end
            else begin
                huffman_output = 20'b0110_0111_0000_0001_0010;
            end
        end
        else begin
            if (node_2_3 > e[4:0])
                huffman_output = 20'b0100_0101_0110_0111_0000;
            else
                huffman_output = 20'b0000_0001_0010_0011_0001;
        end 
    end 
    else begin
        if (node_1_1 > e[4:0]) begin
            if (node_0 > c[4:0])
                huffman_output = 20'b0010_0011_0000_0010_0011;
            else
                huffman_output = 20'b0000_0001_0001_0010_0011;
        end
        else begin
            if (node_2_1 > e[4:0]) begin
                if (node_1_1 > d[4:0]) begin
                    if (node_0 > c[4:0])
                        huffman_output = 20'b1110_1111_0110_0010_0000;
                    else
                        huffman_output = 20'b1100_1101_0111_0010_0000;
                end
                else begin
                    if (node_0 > c[4:0])
                        huffman_output = 20'b1010_1011_0100_0011_0000;
                    else
                        huffman_output = 20'b1000_1001_0101_0011_0000;
                end
            end
            else begin
                if (node_1_1 > d[4:0]) begin
                    if (node_0 > c[4:0]) 
                        huffman_output = 20'b0110_0111_0010_0000_0001;
                    else 
                        huffman_output = 20'b0100_0101_0011_0000_0001;
                end
                else begin
                    if (node_0 > c[4:0]) 
                        huffman_output = 20'b0010_0011_0000_0001_0001;
                    else 
                        huffman_output = 20'b0000_0001_0001_0001_0001;
                end
            end
        end
    end
    
end


//================================================================
//    Output encoded
//================================================================
always @(*) begin
    if (a[7:5] == index_1)
        out_encoded[19:16] = huffman_output[19:16];
    else if (b[7:5] == index_1)
        out_encoded[19:16] = huffman_output[15:12];
    else if (c[7:5] == index_1)
        out_encoded[19:16] = huffman_output[11:8];
    else if (d[7:5] == index_1)
        out_encoded[19:16] = huffman_output[7:4];
    else if (e[7:5] == index_1)
        out_encoded[19:16] = huffman_output[3:0];
    else
        out_encoded[19:16] = 4'b0000;
end

always @(*) begin
    if (a[7:5] == index_2)
        out_encoded[15:12] = huffman_output[19:16];
    else if (b[7:5] == index_2)
        out_encoded[15:12] = huffman_output[15:12];
    else if (c[7:5] == index_2)
        out_encoded[15:12] = huffman_output[11:8];
    else if (d[7:5] == index_2)
        out_encoded[15:12] = huffman_output[7:4];
    else if (e[7:5] == index_2)
        out_encoded[15:12] = huffman_output[3:0];
    else
        out_encoded[15:12] = 4'b0000;
end

always @(*) begin
    if (a[7:5] == index_3)
        out_encoded[11:8] = huffman_output[19:16];
    else if (b[7:5] == index_3)
        out_encoded[11:8] = huffman_output[15:12];
    else if (c[7:5] == index_3)
        out_encoded[11:8] = huffman_output[11:8];
    else if (d[7:5] == index_3)
        out_encoded[11:8] = huffman_output[7:4];
    else if (e[7:5] == index_3)
        out_encoded[11:8] = huffman_output[3:0];
    else
        out_encoded[11:8] = 4'b0000;
end

always @(*) begin
    if (a[7:5] == index_4)
        out_encoded[7:4] = huffman_output[19:16];
    else if (b[7:5] == index_4)
        out_encoded[7:4] = huffman_output[15:12];
    else if (c[7:5] == index_4)
        out_encoded[7:4] = huffman_output[11:8];
    else if (d[7:5] == index_4)
        out_encoded[7:4] = huffman_output[7:4];
    else if (e[7:5] == index_4)
        out_encoded[7:4] = huffman_output[3:0];
    else
        out_encoded[7:4] = 4'b0000;
end

always @(*) begin
    if (a[7:5] == index_5)
        out_encoded[3:0] = huffman_output[19:16];
    else if (b[7:5] == index_5)
        out_encoded[3:0] = huffman_output[15:12];
    else if (c[7:5] == index_5)
        out_encoded[3:0] = huffman_output[11:8];
    else if (d[7:5] == index_5)
        out_encoded[3:0] = huffman_output[7:4];
    else if (e[7:5] == index_5)
        out_encoded[3:0] = huffman_output[3:0];
    else
        out_encoded[3:0] = 4'b0000;
end

endmodule


//================================================================
//    SUB MODULE
//================================================================
module comparator_stage_1 (
    input [7:0] in_1, 
    input [7:0] in_2,
    output reg [7:0] small_out,
    output reg [7:0] big_out
);

always @(*) begin
    if (in_1[4:0] > in_2[4:0]) begin
        small_out = in_2;
        big_out = in_1;
    end 
    else if (in_1[4:0] < in_2[4:0]) begin
        small_out = in_1;
        big_out = in_2;
    end 
    else if (in_1[4:0] == in_2[4:0]) begin
        if (in_1[7:5] > in_2[7:5]) begin
            small_out = in_2;
            big_out = in_1;
        end else begin
            small_out = in_1;
            big_out = in_2;
        end
    end 
    else begin
        small_out = in_1;
        big_out = in_2;
    end
end
endmodule


















































