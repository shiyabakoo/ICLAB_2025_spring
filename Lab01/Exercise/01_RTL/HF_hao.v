module HF (
    input   [24:0]    symbol_freq,
    output  [19:0]    out_encoded
);
    
    wire [7:0] in1, in2, in3, in4, in5;

    assign in5 = {3'b000, symbol_freq[24:20]};
    assign in4 = {3'b001, symbol_freq[19:15]};
    assign in3 = {3'b010, symbol_freq[14:10]};
    assign in2 = {3'b011, symbol_freq[ 9: 5]};
    assign in1 = {3'b100, symbol_freq[ 4: 0]};

    ///////////////////////////////////////////////////////
    ///                    level 1                      ///
    ///////////////////////////////////////////////////////
    wire [7:0] u1_out1, u2_out1, u3_out1, u4_out1, u5_out1, u6_out1, u7_out1, u8_out1, u9_out1;
    wire [7:0] u1_out2, u2_out2, u3_out2, u4_out2, u5_out2, u6_out2, u7_out2, u8_out2, u9_out2;
    wire [4:0] a, b, c, d, e;
    wire [5:0] ab, cd, de;
    wire [6:0] abe, abc;
    wire [7:0] abcd;

    comparator_5bit  com_u1 (.in1(    in5), .in2(    in4), .out1( u1_out1), .out2( u1_out2));
    comparator_5bit  com_u2 (.in1(    in3), .in2(    in2), .out1( u2_out1), .out2( u2_out2));
    comparator_5bit  com_u3 (.in1(u1_out2), .in2(u2_out2), .out1( u3_out1), .out2( u3_out2));
    comparator_5bit  com_u4 (.in1(u2_out1), .in2(    in1), .out1( u4_out1), .out2( u4_out2));
    comparator_5bit  com_u5 (.in1(u1_out1), .in2(u4_out1), .out1( u5_out1), .out2( u5_out2));
    comparator_5bit  com_u6 (.in1(u3_out1), .in2(u4_out2), .out1( u6_out1), .out2( u6_out2));
    comparator_5bit  com_u7 (.in1(u5_out2), .in2(u6_out1), .out1( u7_out1), .out2( u7_out2));
    comparator_5bit  com_u8 (.in1(u3_out2), .in2(u6_out2), .out1( u8_out1), .out2( u8_out2));
    comparator_5bit  com_u9 (.in1(u7_out2), .in2(u8_out1), .out1( u9_out1), .out2( u9_out2));

    assign a = u5_out1[4:0];
    assign b = u7_out1[4:0];
    assign c = u9_out1[4:0];
    assign d = u9_out2[4:0];
    assign e = u8_out2[4:0];


    assign ab   =         a + b; 
    assign cd   =         c + d;
    assign de   =         d + e;

    assign abe  =     a + b + e;
    assign abc  =     a + b + c;
    assign abcd = a + b + c + d;

    ///////////////////////////////////////////////////////
    ///                   all cases                     ///
    ///////////////////////////////////////////////////////
    reg [3:0] out_a, out_b, out_c, out_d, out_e;

    always @(*) begin
        if (ab > d) begin
            if (e < ab) begin
                if(abe <= cd) begin        //1-1-1
                    out_a = 4'b0010;
                    out_b = 4'b0011;
                    out_c = 4'b0010;
                    out_d = 4'b0011;
                    out_e = 4'b0000;
                end else begin             //1-1-2
                    out_a = 4'b0110;
                    out_b = 4'b0111;
                    out_c = 4'b0000;
                    out_d = 4'b0001;
                    out_e = 4'b0010;
                end
            end else if (e >= cd)begin
                if(abcd <= e) begin        //1-3-1
                    out_a = 4'b0000;
                    out_b = 4'b0001;
                    out_c = 4'b0010;
                    out_d = 4'b0011;
                    out_e = 4'b0001;
                end else begin             //1-3-2
                    out_a = 4'b0100;
                    out_b = 4'b0101;
                    out_c = 4'b0110;
                    out_d = 4'b0111;
                    out_e = 4'b0000;
                end                
            end else begin
                if(abe <= cd) begin        //1-2-1
                    out_a = 4'b0000;
                    out_b = 4'b0001;
                    out_c = 4'b0010;
                    out_d = 4'b0011;
                    out_e = 4'b0001;
                end else begin             //1-2-2
                    out_a = 4'b0100;
                    out_b = 4'b0101;
                    out_c = 4'b0000;
                    out_d = 4'b0001;
                    out_e = 4'b0011;
                end                 
            end
        end else begin
            if (ab <= c) begin
                if (abc <= d) begin
                    if (abcd <= e) begin      //2-4-1
                        out_a = 4'b0000;
                        out_b = 4'b0001;
                        out_c = 4'b0001;
                        out_d = 4'b0001;
                        out_e = 4'b0001;                        
                    end else begin            //2-4-2
                        out_a = 4'b1000;
                        out_b = 4'b1001;
                        out_c = 4'b0101;
                        out_d = 4'b0011;
                        out_e = 4'b0000;                         
                    end
                end else if (abc > e) begin
                    if (abc < de) begin      //2-5-5
                        out_a = 4'b0000;
                        out_b = 4'b0001;
                        out_c = 4'b0001;
                        out_d = 4'b0010;
                        out_e = 4'b0011;                        
                    end else begin            //2-5-6
                        out_a = 4'b0100;
                        out_b = 4'b0101;
                        out_c = 4'b0011;
                        out_d = 4'b0000;
                        out_e = 4'b0001;                         
                    end
                end else begin
                    if (abcd <= e) begin      //2-4-3
                        out_a = 4'b0100;
                        out_b = 4'b0101;
                        out_c = 4'b0011;
                        out_d = 4'b0000;
                        out_e = 4'b0001;                        
                    end else begin            //2-4-4
                        out_a = 4'b1100;
                        out_b = 4'b1101;
                        out_c = 4'b0111;
                        out_d = 4'b0010;
                        out_e = 4'b0000;                         
                    end              
                end     
            end else begin
                if (abc <= d) begin
                    if (abcd <= e) begin      //2-5-1
                        out_a = 4'b0010;
                        out_b = 4'b0011;
                        out_c = 4'b0000;
                        out_d = 4'b0001;
                        out_e = 4'b0001;                        
                    end else begin            //2-5-2
                        out_a = 4'b1010;
                        out_b = 4'b1011;
                        out_c = 4'b0100;
                        out_d = 4'b0011;
                        out_e = 4'b0000;                         
                    end
                end else if (abc > e) begin
                    if (abc < de) begin      //2-5-5
                        out_a = 4'b0010;
                        out_b = 4'b0011;
                        out_c = 4'b0000;
                        out_d = 4'b0010;
                        out_e = 4'b0011;                        
                    end else begin            //2-5-6
                        out_a = 4'b0110;
                        out_b = 4'b0111;
                        out_c = 4'b0010;
                        out_d = 4'b0000;
                        out_e = 4'b0001;                         
                    end              
                end else begin
                    if (abcd <= e) begin      //2-5-3
                        out_a = 4'b0110;
                        out_b = 4'b0111;
                        out_c = 4'b0010;
                        out_d = 4'b0000;
                        out_e = 4'b0001;                        
                    end else begin            //2-5-4
                        out_a = 4'b1110;
                        out_b = 4'b1111;
                        out_c = 4'b0110;
                        out_d = 4'b0010;
                        out_e = 4'b0000;                         
                    end              
                end                  
            end
        end
    end

    ///////////////////////////////////////////////////////
    ///                restore index                    ///
    ///////////////////////////////////////////////////////
    // assign a = u5_out1[4:0];
    // assign b = u7_out1[4:0];
    // assign c = u9_out1[4:0];
    // assign d = u9_out2[4:0];
    // assign e = u8_out2[4:0];
    reg [3:0] out1, out2, out3, out4, out5;

    always @(*) begin
        if (u5_out1[7:5] == 3'b000) begin
            out1 = out_a;
        end else if (u7_out1[7:5] == 3'b000) begin
            out1 = out_b;
        end else if (u9_out1[7:5] == 3'b000) begin
            out1 = out_c;
        end else if (u9_out2[7:5] == 3'b000) begin
            out1 = out_d;
        end else begin
            out1 = out_e;
        end
    end

    always @(*) begin
        if (u5_out1[7:5] == 3'b001) begin
            out2 = out_a;
        end else if (u7_out1[7:5] == 3'b001) begin
            out2 = out_b;
        end else if (u9_out1[7:5] == 3'b001) begin
            out2 = out_c;
        end else if (u9_out2[7:5] == 3'b001) begin
            out2 = out_d;
        end else begin
            out2 = out_e;
        end 
    end

    always @(*) begin
        if (u5_out1[7:5] == 3'b010) begin
            out3 = out_a;
        end else if (u7_out1[7:5] == 3'b010) begin
            out3 = out_b;
        end else if (u9_out1[7:5] == 3'b010) begin
            out3 = out_c;
        end else if (u9_out2[7:5] == 3'b010) begin
            out3 = out_d;
        end else begin
            out3 = out_e;
        end
    end

    always @(*) begin
        if (u5_out1[7:5] == 3'b011) begin
            out4 = out_a;
        end else if (u7_out1[7:5] == 3'b011) begin
            out4 = out_b;
        end else if (u9_out1[7:5] == 3'b011) begin
            out4 = out_c;
        end else if (u9_out2[7:5] == 3'b011) begin
            out4 = out_d;
        end else begin
            out4 = out_e;
        end
    end

    always @(*) begin
        if (u5_out1[7:5] == 3'b100) begin
            out5 = out_a;
        end else if (u7_out1[7:5] == 3'b100) begin
            out5 = out_b;
        end else if (u9_out1[7:5] == 3'b100) begin
            out5 = out_c;
        end else if (u9_out2[7:5] == 3'b100) begin
            out5 = out_d;
        end else begin
            out5 = out_e;
        end
    end
    ///////////////////////////////////////////////////////
    ///                    output                       ///
    ///////////////////////////////////////////////////////

    assign out_encoded = {out1, out2, out3, out4, out5};

endmodule





module comparator_5bit (
    input      [7:0]  in1,
    input      [7:0]  in2,
    output reg [7:0] out1,
    output reg [7:0] out2
);
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

// module comparator_6bit (
//     input      [8:0]  in1,
//     input      [8:0]  in2,
//     output reg [8:0] out1,
//     output reg [8:0] out2
// );
//     always @(*) begin
//         if (in1[5:0] > in2[5:0]) begin
//             out1 = in2;
//             out2 = in1;
//         end else if (in1[5:0] < in2[5:0]) begin
//             out1 = in1;
//             out2 = in2;
//         end else if (in1[5:0] == in2[5:0]) begin
//             if (in1[8:6] > in2[8:6]) begin
//                 out1 = in2;
//                 out2 = in1;
//             end else begin
//                 out1 = in1;
//                 out2 = in2;
//             end
//         end else begin
//             out1 = in1;
//             out2 = in2;
//         end
//     end
// endmodule

// module comparator_7bit (
//     input       [9:0]  in1,
//     input       [9:0]  in2,
//     output  reg [9:0] out1,
//     output  reg [9:0] out2
// );
//     always @(*) begin
//         if (in1[6:0] > in2[6:0]) begin
//             out1 = in2;
//             out2 = in1;
//         end else if (in1[6:0] < in2[6:0]) begin
//             out1 = in1;
//             out2 = in2;
//         end else if (in1[6:0] == in2[6:0]) begin
//             if (in1[9:7] > in2[9:7]) begin
//                 out1 = in2;
//                 out2 = in1;
//             end else begin
//                 out1 = in1;
//                 out2 = in2;
//             end
//         end else begin
//             out1 = in1;
//             out2 = in2;
//         end
//     end
// endmodule

// module comparator_8bit (
//     input       [10:0]  in1,
//     input       [10:0]  in2,
//     output  reg [10:0] out1,
//     output  reg [10:0] out2
// );
//     always @(*) begin
//         if (in1[7:0] > in2[7:0]) begin
//             out1 = in2;
//             out2 = in1;
//         end else if (in1[7:0] < in2[7:0]) begin
//             out1 = in1;
//             out2 = in2;
//         end else if (in1[7:0] == in2[7:0]) begin
//             if (in1[10:8] > in2[10:8]) begin
//                 out1 = in2;
//                 out2 = in1;
//             end else begin
//                 out1 = in1;
//                 out2 = in2;
//             end
//         end else begin
//             out1 = in1;
//             out2 = in2;
//         end
//     end
// endmodule

// module adder_5bit (
//     input  [7:0] in1,
//     input  [7:0] in2,
//     output [5:0] out
// );
//     assign out = in1[4:0] + in2[4:0];
// endmodule

// module adder_6bit (
//     input  [8:0] in1,
//     input  [8:0] in2,
//     output [6:0] out
// );
//     assign out = in1[5:0] + in2[5:0];
// endmodule

// module adder_7bit (
//     input  [9:0] in1,
//     input  [9:0] in2,
//     output [7:0] out
// );
//     assign out = in1[6:0] + in2[6:0];
// endmodule