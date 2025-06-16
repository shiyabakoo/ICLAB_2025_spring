//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright System Integration and Silicon Implementation Laboratory
//    All Right Reserved
//		Date		: 2023/10
//		Version		: v1.0
//   	File Name   : Division_IP.v
//   	Module Name : Division_IP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
module Division_IP #(parameter IP_WIDTH = 6) ( 
    // Input signals
    IN_Dividend, IN_Divisor,
    // Output signals
    OUT_Quotient
);

// ===============================================================
// Input & Output
// ===============================================================
input [IP_WIDTH*4-1:0]  IN_Dividend;
input [IP_WIDTH*4-1:0]  IN_Divisor;

output logic [IP_WIDTH*4-1:0] OUT_Quotient;

// ===============================================================
// Design
// ===============================================================


// ===============================================================
//                     POLY DIVIDER
// ===============================================================
generate
    case (IP_WIDTH)
        1: begin: IP_WIDTH_1
            WIDTH_1_DIV u1(.IN_Dividend(IN_Dividend), .IN_Divisor(IN_Divisor), .OUT_Quotient(OUT_Quotient));
        end
        2: begin: IP_WIDTH_2
            WIDTH_2_DIV u1(.IN_Dividend(IN_Dividend), .IN_Divisor(IN_Divisor), .OUT_Quotient(OUT_Quotient));
        end
        3: begin: IP_WIDTH_3
            WIDTH_3_DIV u1(.IN_Dividend(IN_Dividend), .IN_Divisor(IN_Divisor), .OUT_Quotient(OUT_Quotient));
        end
        4: begin: IP_WIDTH_4
            WIDTH_4_DIV u1(.IN_Dividend(IN_Dividend), .IN_Divisor(IN_Divisor), .OUT_Quotient(OUT_Quotient));
        end
        5: begin: IP_WIDTH_5
            WIDTH_5_DIV u1(.IN_Dividend(IN_Dividend), .IN_Divisor(IN_Divisor), .OUT_Quotient(OUT_Quotient));
        end
        6: begin: IP_WIDTH_6
            WIDTH_6_DIV u1(.IN_Dividend(IN_Dividend), .IN_Divisor(IN_Divisor), .OUT_Quotient(OUT_Quotient));
        end
        7: begin: IP_WIDTH_7
            WIDTH_7_DIV u1(.IN_Dividend(IN_Dividend), .IN_Divisor(IN_Divisor), .OUT_Quotient(OUT_Quotient));
        end
    endcase
endgenerate

endmodule
// ===============================================================
//                     SUBMODULE(POLY DIV)
// ===============================================================
module WIDTH_1_DIV (
    IN_Dividend,
    IN_Divisor,
    OUT_Quotient
);
input      [3:0]  IN_Dividend;
input      [3:0]  IN_Divisor;
output reg [3:0] OUT_Quotient;

wire       [3:0] Quotient_temp;
GF_DIV u1_width1(.div_in1(IN_Dividend), .div_in2(IN_Divisor), .div_out(Quotient_temp));

always @(*) begin
    OUT_Quotient = Quotient_temp;
end
endmodule

module WIDTH_2_DIV (
    IN_Dividend,
    IN_Divisor,
    OUT_Quotient
);
input      [7:0]  IN_Dividend;
input      [7:0]  IN_Divisor;
output reg [7:0]  OUT_Quotient;

wire       [7:0] Quotient_temp;
reg        [3:0] Quotient_0;
reg        [3:0] Quotient_1;
wire       [3:0] mul_out_1;

reg [3:0] dividend_1;
reg [3:0] divisor;
reg [3:0] dividend_2;

GF_DIV u1_width2(.div_in1(dividend_1), .div_in2(divisor), .div_out(Quotient_temp[3:0]));
GF_DIV u2_width2(.div_in1(dividend_2), .div_in2(divisor), .div_out(Quotient_temp[7:4]));

assign OUT_Quotient = {Quotient_1, Quotient_0};
always @(*) begin
    dividend_1 = IN_Dividend[3:0];
    dividend_2 = IN_Dividend[7:4];
end
always @(*) begin
    if (IN_Divisor[7:4] != 'd15)
        divisor = IN_Divisor[7:4];
    else
        divisor = IN_Divisor[3:0];
end

always @(*) begin
    if (IN_Dividend[7:4] != 'd15) begin
        if (IN_Divisor[7:4] != 'd15)
            Quotient_0 = Quotient_temp[7:4];
        else 
            Quotient_0 = Quotient_temp[3:0];
    end
    else begin
        if (IN_Divisor[7:4] != 'd15)
            Quotient_0 = 'd15;
        else
            Quotient_0 = Quotient_temp[3:0];
    end

end

always @(*) begin
    if (IN_Divisor[7:4] == 'd15) begin
        Quotient_1 = Quotient_temp[7:4];
    end
    else begin
        Quotient_1 = 'd15;
    end
end
endmodule

module WIDTH_3_DIV (
    IN_Dividend,
    IN_Divisor,
    OUT_Quotient
);
input      [11:0]  IN_Dividend;
input      [11:0]  IN_Divisor;
output reg [11:0]  OUT_Quotient;

wire       [11:0] Quotient_temp;
reg        [3:0] Quotient_0;
reg        [3:0] Quotient_1;
reg        [3:0] Quotient_2;

reg        [3:0] mul_in1_1, mul_in2_1;
wire       [3:0] mul_out_1;

reg        [3:0] add_sub_in1_1, add_sub_in2_1;
wire       [3:0] add_sub_out_1;


reg [3:0] divisor;
reg [3:0] dividend_1;
reg [3:0] dividend_2;
reg [3:0] dividend_3;

GF_DIV u1_width3(.div_in1(dividend_1), .div_in2(divisor), .div_out(Quotient_temp[3:0]));
GF_DIV u2_width3(.div_in1(dividend_2), .div_in2(divisor), .div_out(Quotient_temp[7:4]));
GF_DIV u3_width3(.div_in1(dividend_3), .div_in2(divisor), .div_out(Quotient_temp[11:8]));

GF_MUL u4_width3(.mul_in1(mul_in1_1), .mul_in2(mul_in2_1), .mul_out(mul_out_1));
GF_ADD_SUB u5_width3(.add_sub_in1(add_sub_in1_1), .add_sub_in2(add_sub_in2_1), .add_sub_out(add_sub_out_1));

assign OUT_Quotient = {Quotient_2, Quotient_1, Quotient_0};

assign mul_in1_1 = Quotient_temp[11:8];    
assign mul_in2_1 = IN_Divisor[3:0];
assign add_sub_in1_1 = IN_Dividend[7:4];
assign add_sub_in2_1 = mul_out_1;

always @(*) begin
    dividend_1 = IN_Dividend[3:0];
    dividend_3 = IN_Dividend[11:8];
end
always @(*) begin
    if (IN_Dividend[11:8] != 'd15) begin
        if ((IN_Divisor[11:8] == 'd15) && (IN_Divisor[7:4] != 'd15))
            dividend_2 = add_sub_out_1;
        else
            dividend_2 = IN_Dividend[7:4];
    end
    else
        dividend_2 = IN_Dividend[7:4];
end

always @(*) begin
    if (IN_Divisor[11:8] != 'd15)
        divisor = IN_Divisor[11:8];
    else if (IN_Divisor[7:4] != 'd15)
        divisor = IN_Divisor[7:4];
    else
        divisor = IN_Divisor[3:0];
end

always @(*) begin
    if (IN_Dividend[11:8] != 'd15) begin
        if (IN_Divisor[11:8] != 'd15)
            Quotient_0 = Quotient_temp[11:8];
        else if (IN_Divisor[7:4] != 'd15)
            Quotient_0 = Quotient_temp[7:4];
        else
            Quotient_0 = Quotient_temp[3:0];
    end
    else begin
        if (IN_Divisor[11:8] != 'd15) begin
            Quotient_0 = 'd15;
        end
        else begin
            if (IN_Dividend[7:4] != 'd15) begin
                if (IN_Divisor[7:4] != 'd15)
                    Quotient_0 = Quotient_temp[7:4];
                else 
                    Quotient_0 = Quotient_temp[3:0];
            end
            else begin
                if (IN_Divisor[7:4] != 'd15)
                    Quotient_0 = 'd15;
                else begin
                    Quotient_0 = Quotient_temp[3:0];
                end
            end
        end
    end
end


always @(*) begin
    if (IN_Dividend[11:8] != 'd15) begin
        if (IN_Divisor[11:8] == 'd15) begin
            if (IN_Divisor[7:4] != 'd15)
                Quotient_1 = Quotient_temp[11:8];
            else
                Quotient_1 = Quotient_temp[7:4];
        end
        else
            Quotient_1 = 'd15;
    end
    else begin
        if (IN_Divisor[11:8] != 'd15) begin
            Quotient_1 = 'd15;
        end
        else begin
            if (IN_Dividend[7:4] != 'd15) begin
                if (IN_Divisor[7:4] != 'd15)
                    Quotient_1 = 'd15;
                else
                    Quotient_1 = Quotient_temp[7:4];
            end
            else begin
                Quotient_1 = 'd15;
            end
        end
    end
end

always @(*) begin
    if ((IN_Divisor[11:8] == 'd15) && (IN_Divisor[7:4] == 'd15)) begin
        Quotient_2 = Quotient_temp[11:8];
    end
    else
        Quotient_2 = 'd15;
end
endmodule

module WIDTH_4_DIV (
    IN_Dividend,
    IN_Divisor,
    OUT_Quotient
);
input      [15:0]  IN_Dividend;
input      [15:0]  IN_Divisor;
output reg [15:0]  OUT_Quotient;

wire       [15:0] Quotient_temp;
reg        [3:0] Quotient_0;
reg        [3:0] Quotient_1;
reg        [3:0] Quotient_2;
reg        [3:0] Quotient_3;

reg        [3:0] mul_in1_1, mul_in2_1;
wire       [3:0] mul_out_1;

reg        [3:0] mul_in1_2, mul_in2_2;
wire       [3:0] mul_out_2;

reg        [3:0] add_sub_in1_1, add_sub_in2_1;
wire       [3:0] add_sub_out_1;

reg        [3:0] add_sub_in1_2, add_sub_in2_2;
wire       [3:0] add_sub_out_2;

reg [1:0] divisor_degree;
reg [1:0] dividend_degree;
wire      dividend_power_small;

reg [3:0] divisor;
reg [3:0] dividend_1;
reg [3:0] dividend_2;
reg [3:0] dividend_3;
reg [3:0] dividend_4;

GF_DIV u1_width4(.div_in1(dividend_1), .div_in2(divisor), .div_out(Quotient_temp[3:0]));
GF_DIV u2_width4(.div_in1(dividend_2), .div_in2(divisor), .div_out(Quotient_temp[7:4]));
GF_DIV u3_width4(.div_in1(dividend_3), .div_in2(divisor), .div_out(Quotient_temp[11:8]));
GF_DIV u4_width4(.div_in1(dividend_4), .div_in2(divisor), .div_out(Quotient_temp[15:12]));

GF_MUL u5_width4(.mul_in1(mul_in1_1), .mul_in2(mul_in2_1), .mul_out(mul_out_1));
GF_MUL u6_width4(.mul_in1(mul_in1_2), .mul_in2(mul_in2_2), .mul_out(mul_out_2));
GF_ADD_SUB u7_width4(.add_sub_in1(add_sub_in1_1), .add_sub_in2(add_sub_in2_1), .add_sub_out(add_sub_out_1));
GF_ADD_SUB u8_width4(.add_sub_in1(add_sub_in1_2), .add_sub_in2(add_sub_in2_2), .add_sub_out(add_sub_out_2));

always @(*) begin
    if (IN_Divisor[15:12] != 'd15)
        divisor_degree = 'd3;
    else if (IN_Divisor[11:8] != 'd15)
        divisor_degree = 'd2;
    else if (IN_Divisor[7:4] != 'd15)
        divisor_degree = 'd1;
    else if (IN_Divisor[3:0] != 'd15)
        divisor_degree = 'd0; 
    else
        divisor_degree = 'd0;
end

always @(*) begin
    if (IN_Dividend[15:12] != 'd15)
        dividend_degree = 'd3;
    else if (IN_Dividend[11:8] != 'd15)
        dividend_degree = 'd2;
    else if (IN_Dividend[7:4] != 'd15)
        dividend_degree = 'd1;
    else if (IN_Dividend[3:0] != 'd15)
        dividend_degree = 'd0; 
    else
        dividend_degree = 'd0;
end

assign dividend_power_small = (dividend_degree < divisor_degree)? 1 : 0;

assign OUT_Quotient = (dividend_power_small)? {4{4'd15}} : {Quotient_3, Quotient_2, Quotient_1, Quotient_0};

always @(*) begin
    mul_in1_1 = Quotient_temp[15:12];
end

always @(*) begin
    if (IN_Divisor[11:8] != 'd15)
        mul_in2_1 = IN_Divisor[7:4];
    else
        mul_in2_1 = IN_Divisor[3:0]; 
end

assign mul_in1_2 = Quotient_temp[11:8];
assign mul_in2_2 = IN_Divisor[3:0];

always @(*) begin
    add_sub_in1_1 = IN_Dividend[11:8];

end

assign add_sub_in2_1 = mul_out_1;

assign add_sub_in1_2 = IN_Dividend[7:4];
assign add_sub_in2_2 = mul_out_2;

always @(*) begin
    dividend_1 = IN_Dividend[3:0];
    dividend_4 = IN_Dividend[15:12];
end

always @(*) begin
    if ((IN_Divisor[15:12]) != 'd15)
        dividend_3 = IN_Dividend[11:8];
    else if (IN_Divisor[11:8] != 'd15)
        dividend_3 = add_sub_out_1;
    else if (IN_Divisor[7:4] != 'd15)
        dividend_3 = add_sub_out_1;
    else
        dividend_3 = IN_Dividend[11:8]; 
end

always @(*) begin
    if ((IN_Divisor[15:12] == 'd15) && (IN_Divisor[11:8] == 'd15) && (IN_Divisor[7:4] != 'd15))
        dividend_2 = add_sub_out_2;
    else
        dividend_2 = IN_Dividend[7:4];
end

always @(*) begin
    if (IN_Divisor[15:12] != 'd15)
        divisor = IN_Divisor[15:12];
    else if (IN_Divisor[11:8] != 'd15)
        divisor = IN_Divisor[11:8];
    else if (IN_Divisor[7:4] != 'd15)
        divisor = IN_Divisor[7:4];
    else
        divisor = IN_Divisor[3:0];
end

always @(*) begin
    if (IN_Divisor[15:12] != 'd15)
        Quotient_0 = Quotient_temp[15:12]; 
    else if (IN_Divisor[11:8] != 'd15)
        Quotient_0 = Quotient_temp[11:8];
    else if (IN_Divisor[7:4] != 'd15)
        Quotient_0 = Quotient_temp[7:4];
    else 
        Quotient_0 = Quotient_temp[3:0];
end

always @(*) begin
    if (IN_Divisor[15:12] == 'd15) begin
        if (IN_Divisor[11:8] != 'd15)
            Quotient_1 = Quotient_temp[15:12];
        else if (IN_Divisor[7:4] != 'd15)
            Quotient_1 = Quotient_temp[11:8];
        else
            Quotient_1 = Quotient_temp[7:4]; 
    end
    else
        Quotient_1 = 'd15;
end

always @(*) begin
    if ((IN_Divisor[15:12] == 'd15) && (IN_Divisor[11:8] == 'd15)) begin
        if (IN_Divisor[7:4] != 'd15)
            Quotient_2 = Quotient_temp[15:12];
        else
            Quotient_2 = Quotient_temp[11:8];
    end
    else
        Quotient_2 = 'd15;
end 

always @(*) begin
    if ((IN_Divisor[15:12] == 'd15) && (IN_Divisor[11:8] == 'd15) && (IN_Divisor[7:4] == 'd15) && (IN_Divisor[3:0] != 'd15))
        Quotient_3 = Quotient_temp[15:12];
    else
        Quotient_3 = 'd15;
end
endmodule 

module WIDTH_5_DIV (
    IN_Dividend,
    IN_Divisor,
    OUT_Quotient
);
input      [19:0]  IN_Dividend;
input      [19:0]  IN_Divisor;
output reg [19:0]  OUT_Quotient;

wire       [19:0] Quotient_temp;
reg        [3:0] Quotient_0;
reg        [3:0] Quotient_1;
reg        [3:0] Quotient_2;
reg        [3:0] Quotient_3;
reg        [3:0] Quotient_4;
 
reg        [3:0] mul_in1_1, mul_in2_1;
wire       [3:0] mul_out_1;

reg        [3:0] mul_in1_2, mul_in2_2;
wire       [3:0] mul_out_2;

reg        [3:0] mul_in1_3, mul_in2_3;
wire       [3:0] mul_out_3;

reg        [3:0] add_sub_in1_1, add_sub_in2_1;
wire       [3:0] add_sub_out_1;

reg        [3:0] add_sub_in1_2, add_sub_in2_2;
wire       [3:0] add_sub_out_2;

reg        [3:0] add_sub_in1_3, add_sub_in2_3;
wire       [3:0] add_sub_out_3;

reg [2:0] divisor_degree;
reg [2:0] dividend_degree;
reg       dividend_power_small;

reg [3:0] divisor;
reg [3:0] dividend_1;
reg [3:0] dividend_2;
reg [3:0] dividend_3;
reg [3:0] dividend_4;
reg [3:0] dividend_5;

GF_DIV u1_width5(.div_in1(dividend_1), .div_in2(divisor), .div_out(Quotient_temp[3:0]));
GF_DIV u2_width5(.div_in1(dividend_2), .div_in2(divisor), .div_out(Quotient_temp[7:4]));
GF_DIV u3_width5(.div_in1(dividend_3), .div_in2(divisor), .div_out(Quotient_temp[11:8]));
GF_DIV u4_width5(.div_in1(dividend_4), .div_in2(divisor), .div_out(Quotient_temp[15:12]));
GF_DIV u5_width5(.div_in1(dividend_5), .div_in2(divisor), .div_out(Quotient_temp[19:16]));

GF_MUL u6_width5(.mul_in1(mul_in1_1), .mul_in2(mul_in2_1), .mul_out(mul_out_1));
GF_MUL u7_width5(.mul_in1(mul_in1_2), .mul_in2(mul_in2_2), .mul_out(mul_out_2));
GF_MUL u8_width5(.mul_in1(mul_in1_3), .mul_in2(mul_in2_3), .mul_out(mul_out_3));
GF_ADD_SUB u9_width5(.add_sub_in1(add_sub_in1_1), .add_sub_in2(add_sub_in2_1), .add_sub_out(add_sub_out_1));
GF_ADD_SUB u10_width5(.add_sub_in1(add_sub_in1_2), .add_sub_in2(add_sub_in2_2), .add_sub_out(add_sub_out_2));
GF_ADD_SUB u11_width5(.add_sub_in1(add_sub_in1_3), .add_sub_in2(add_sub_in2_3), .add_sub_out(add_sub_out_3));

always @(*) begin
    if (IN_Divisor[19:16] != 'd15)
        divisor_degree = 'd4;
    else if (IN_Divisor[15:12] != 'd15)
        divisor_degree = 'd3;
    else if (IN_Divisor[11:8] != 'd15)
        divisor_degree = 'd2;
    else if (IN_Divisor[7:4] != 'd15)
        divisor_degree = 'd1;
    else if (IN_Divisor[3:0] != 'd15)
        divisor_degree = 'd0; 
    else
        divisor_degree = 'd7;
end

always @(*) begin
    if (IN_Dividend[19:16] != 'd15)
        dividend_degree = 'd4;
    else if (IN_Dividend[15:12] != 'd15)
        dividend_degree = 'd3;
    else if (IN_Dividend[11:8] != 'd15)
        dividend_degree = 'd2;
    else if (IN_Dividend[7:4] != 'd15)
        dividend_degree = 'd1;
    else if (IN_Dividend[3:0] != 'd15)
        dividend_degree = 'd0; 
    else
        dividend_degree = 'd7;
end

assign dividend_power_small = (dividend_degree < divisor_degree)? 1 : 0;


assign OUT_Quotient = (dividend_power_small)? {5{4'd15}} : {Quotient_4, Quotient_3, Quotient_2, Quotient_1, Quotient_0};

always @(*) begin
        mul_in1_1 = Quotient_temp[19:16];
end

always @(*) begin

    if (IN_Divisor[15:12] != 'd15)
        mul_in2_1 = IN_Divisor[11:8];
    else if (IN_Divisor[11:8] != 'd15)
        mul_in2_1 = IN_Divisor[7:4];
    else
        mul_in2_1 = IN_Divisor[3:0];
end

always @(*) begin
    mul_in1_2 = Quotient_temp[15:12];
end

always @(*) begin
    if (IN_Divisor[11:8] != 'd15)
        mul_in2_2 = IN_Divisor[7:4];
    else
        mul_in2_2 = IN_Divisor[3:0]; 
end

always @(*) begin
    if (IN_Divisor[11:8] != 'd15)
        mul_in1_3 = Quotient_temp[19:16];
    else
        mul_in1_3 = Quotient_temp[11:8];
end

always @(*) begin
    mul_in2_3 = IN_Divisor[3:0];
end

always @(*) begin
    add_sub_in1_1 = IN_Dividend[15:12];
end

always @(*) begin
    add_sub_in2_1 = mul_out_1;
end

always @(*) begin
    add_sub_in1_2 = IN_Dividend[11:8];
end

always @(*) begin
    if (IN_Divisor[11:8] != 'd15) 
        add_sub_in2_2 = mul_out_3;
    else 
        add_sub_in2_2 = mul_out_2;
end

always @(*) begin
    if (IN_Divisor[11:8] != 'd15) 
        add_sub_in1_3 = add_sub_out_2; 
    else
        add_sub_in1_3 = IN_Dividend[7:4];
end

always @(*) begin
    if (IN_Divisor[11:8] != 'd15)
        add_sub_in2_3 = mul_out_2;
    else
        add_sub_in2_3 = mul_out_3;
end

always @(*) begin
    dividend_1 = IN_Dividend[3:0];
    dividend_5 = IN_Dividend[19:16];
end

always @(*) begin
    if (IN_Divisor[19:16] != 'd15)
        dividend_4 = IN_Dividend[15:12];
    else if ((IN_Divisor[15:12] != 'd15) || (IN_Divisor[11:8] != 'd15) || (IN_Divisor[7:4] != 'd15))
        dividend_4 = add_sub_out_1;
    else
        dividend_4 = IN_Dividend[15:12];
end

always @(*) begin
    if (IN_Divisor[19:16] != 'd15)
        dividend_3 = IN_Dividend[11:8];
    else if (IN_Divisor[15:12] != 'd15)
        dividend_3 = IN_Dividend[11:8];
    else if (IN_Divisor[11:8] != 'd15)
        dividend_3 = add_sub_out_3;
    else if (IN_Divisor[7:4] != 'd15)
        dividend_3 = add_sub_out_2;
    else
        dividend_3 = IN_Dividend[11:8];
end

always @(*) begin
    if ((IN_Divisor[19:16] == 'd15) && (IN_Divisor[15:12] == 'd15) && (IN_Divisor[11:8] == 'd15) && (IN_Divisor[7:4] != 'd15)) 
        dividend_2 = add_sub_out_3;
    else
        dividend_2 = IN_Dividend[7:4];
end

always @(*) begin
    if (IN_Divisor[19:16] != 'd15)
        divisor = IN_Divisor[19:16];
    else if (IN_Divisor[15:12] != 'd15)
        divisor = IN_Divisor[15:12];
    else if (IN_Divisor[11:8] != 'd15)
        divisor = IN_Divisor[11:8];
    else if (IN_Divisor[7:4] != 'd15)
        divisor = IN_Divisor[7:4];
    else
        divisor = IN_Divisor[3:0];
end

always @(*) begin
    if (IN_Divisor[19:16] != 'd15)
        Quotient_0 = Quotient_temp[19:16];
    else if (IN_Divisor[15:12] != 'd15)
        Quotient_0 = Quotient_temp[15:12];
    else if (IN_Divisor[11:8] != 'd15) 
        Quotient_0 = Quotient_temp[11:8];
    else if (IN_Divisor[7:4] != 'd15)
        Quotient_0 = Quotient_temp[7:4];
    else
        Quotient_0 = Quotient_temp[3:0];
end

always @(*) begin
    if (IN_Divisor[19:16] == 'd15) begin
        if (IN_Divisor[15:12] != 'd15)
            Quotient_1 = Quotient_temp[19:16];
        else if (IN_Divisor[11:8] != 'd15)
            Quotient_1 = Quotient_temp[15:12];
        else if (IN_Divisor[7:4] != 'd15)
            Quotient_1 = Quotient_temp[11:8];
        else 
            Quotient_1 = Quotient_temp[7:4];
    end
    else
        Quotient_1 = 'd15;
end 


always @(*) begin
    if ((IN_Divisor[19:16] == 'd15) && (IN_Divisor[15:12] == 'd15)) begin
        if (IN_Divisor[11:8] != 'd15)
            Quotient_2 = Quotient_temp[19:16];
        else if (IN_Divisor[7:4] != 'd15)
            Quotient_2 = Quotient_temp[15:12];
        else 
            Quotient_2 = Quotient_temp[11:8];
    end
    else
        Quotient_2 = 'd15;
end

always @(*) begin
    if ((IN_Divisor[19:16] == 'd15) && (IN_Divisor[15:12] == 'd15) && (IN_Divisor[11:8] == 'd15)) begin
        if (IN_Divisor[7:4] != 'd15)
            Quotient_3 = Quotient_temp[19:16];
        else
            Quotient_3 = Quotient_temp[15:12];
    end
    else
        Quotient_3 = 'd15;
end
    

always @(*) begin
    if ((IN_Divisor[19:16] == 'd15) && (IN_Divisor[15:12] == 'd15) && (IN_Divisor[11:8] == 'd15) && (IN_Divisor[7:4] == 'd15) && (IN_Divisor[3:0] != 'd15))
        Quotient_4 = Quotient_temp[19:16];
    else
        Quotient_4 = 'd15;
end
endmodule
  


module WIDTH_6_DIV (
    IN_Dividend,
    IN_Divisor,
    OUT_Quotient
);
input      [23:0]  IN_Dividend;
input      [23:0]  IN_Divisor;
output reg [23:0]  OUT_Quotient;

wire       [23:0] Quotient_temp;
reg        [23:0] Quotient_out;
 
reg        [3:0] mul_in1_1, mul_in2_1;
wire       [3:0] mul_out_1;

reg        [3:0] mul_in1_2, mul_in2_2;
wire       [3:0] mul_out_2;

reg        [3:0] mul_in1_3, mul_in2_3;
wire       [3:0] mul_out_3;

reg        [3:0] mul_in1_4, mul_in2_4;
wire       [3:0] mul_out_4;

reg        [3:0] mul_in1_5, mul_in2_5;
wire       [3:0] mul_out_5;

reg        [3:0] add_sub_in1_1, add_sub_in2_1;
wire       [3:0] add_sub_out_1;

reg        [3:0] add_sub_in1_2, add_sub_in2_2;
wire       [3:0] add_sub_out_2;

reg        [3:0] add_sub_in1_3, add_sub_in2_3;
wire       [3:0] add_sub_out_3;

reg        [3:0] add_sub_in1_4, add_sub_in2_4;
wire       [3:0] add_sub_out_4;

reg        [3:0] add_sub_in1_5, add_sub_in2_5;
wire       [3:0] add_sub_out_5;

reg  [2:0] divisor_degree;
reg  [2:0] dividend_degree;
wire       dividend_power_small;

reg [3:0] divisor;
reg [3:0] dividend_1, dividend_2, dividend_3, dividend_4, dividend_5, dividend_6;

GF_DIV u1_width5(.div_in1(dividend_1), .div_in2(divisor), .div_out(Quotient_temp[3:0]));
GF_DIV u2_width5(.div_in1(dividend_2), .div_in2(divisor), .div_out(Quotient_temp[7:4]));
GF_DIV u3_width5(.div_in1(dividend_3), .div_in2(divisor), .div_out(Quotient_temp[11:8]));
GF_DIV u4_width5(.div_in1(dividend_4), .div_in2(divisor), .div_out(Quotient_temp[15:12]));
GF_DIV u5_width5(.div_in1(dividend_5), .div_in2(divisor), .div_out(Quotient_temp[19:16]));
GF_DIV u6_width5(.div_in1(dividend_6), .div_in2(divisor), .div_out(Quotient_temp[23:20]));

GF_MUL u7_width5(.mul_in1(mul_in1_1), .mul_in2(mul_in2_1), .mul_out(mul_out_1));
GF_MUL u8_width5(.mul_in1(mul_in1_2), .mul_in2(mul_in2_2), .mul_out(mul_out_2));
GF_MUL u9_width5(.mul_in1(mul_in1_3), .mul_in2(mul_in2_3), .mul_out(mul_out_3));
GF_MUL u10_width5(.mul_in1(mul_in1_4), .mul_in2(mul_in2_4), .mul_out(mul_out_4));
GF_MUL u11_width5(.mul_in1(mul_in1_5), .mul_in2(mul_in2_5), .mul_out(mul_out_5));

GF_ADD_SUB u12_width5(.add_sub_in1(add_sub_in1_1), .add_sub_in2(add_sub_in2_1), .add_sub_out(add_sub_out_1));
GF_ADD_SUB u13_width5(.add_sub_in1(add_sub_in1_2), .add_sub_in2(add_sub_in2_2), .add_sub_out(add_sub_out_2));
GF_ADD_SUB u14_width5(.add_sub_in1(add_sub_in1_3), .add_sub_in2(add_sub_in2_3), .add_sub_out(add_sub_out_3));
GF_ADD_SUB u15_width5(.add_sub_in1(add_sub_in1_4), .add_sub_in2(add_sub_in2_4), .add_sub_out(add_sub_out_4));
GF_ADD_SUB u16_width5(.add_sub_in1(add_sub_in1_5), .add_sub_in2(add_sub_in2_5), .add_sub_out(add_sub_out_5));



assign OUT_Quotient = Quotient_out;

always @(*) begin
    if (IN_Divisor[23:20] != 'd15)
        divisor_degree = 'd5;
    else if (IN_Divisor[19:16] != 'd15)
        divisor_degree = 'd4;
    else if (IN_Divisor[15:12] != 'd15)
        divisor_degree = 'd3;
    else if (IN_Divisor[11:8] != 'd15)
        divisor_degree = 'd2;
    else if (IN_Divisor[7:4] != 'd15)
        divisor_degree = 'd1;
    else
        divisor_degree = 'd0;
end

always @(*) begin
    if (IN_Dividend[23:20] != 'd15)
        dividend_degree = 'd5;
    else if (IN_Dividend[19:16] != 'd15)
        dividend_degree = 'd4;
    else if (IN_Dividend[15:12] != 'd15)
        dividend_degree = 'd3;
    else if (IN_Dividend[11:8] != 'd15)
        dividend_degree = 'd2;
    else if (IN_Dividend[7:4] != 'd15)
        dividend_degree = 'd1;
    else
        dividend_degree = 'd0;
end

assign dividend_power_small = (dividend_degree < divisor_degree)? 1 : 0;



always @(*) begin
    mul_in1_1 = Quotient_temp[23:20];
end

always @(*) begin
    case (divisor_degree)
        4: mul_in2_1 = IN_Divisor[15:12];
        3: mul_in2_1 = IN_Divisor[11:8];
        2: mul_in2_1 = IN_Divisor[7:4];
        1: mul_in2_1 = IN_Divisor[3:0];
        default: mul_in2_1 = 'd15;
    endcase
end

always @(*) begin
    case (divisor_degree)
        3: mul_in1_2 = Quotient_temp[23:20];
        2: mul_in1_2 = Quotient_temp[23:20];
        1: mul_in1_2 = Quotient_temp[19:16];
        default: mul_in1_2 = 'd15;
    endcase
end

always @(*) begin
    if (IN_Divisor[15:12] != 'd15)
        mul_in2_2 = IN_Divisor[7:4];
    else
        mul_in2_2 = IN_Divisor[3:0];
end

always @(*) begin
    case (divisor_degree)
        3: mul_in1_3 = Quotient_temp[19:16];
        2: mul_in1_3 = Quotient_temp[19:16];
        1: mul_in1_3 = Quotient_temp[15:12];
        default: mul_in1_3 = 'd15;
    endcase
end

always @(*) begin
    case (divisor_degree)
        3: mul_in2_3 = IN_Divisor[11:8];
        2: mul_in2_3 = IN_Divisor[7:4];
        1: mul_in2_3 = IN_Divisor[3:0];
        default: mul_in2_3 = 'd15;
    endcase
end

always @(*) begin
    if (IN_Divisor[11:8] != 'd15)
        mul_in1_4 = Quotient_temp[19:16];
    else
        mul_in1_4 = Quotient_temp[11:8];
end

always @(*) begin
    mul_in2_4 = IN_Divisor[3:0];
end

always @(*) begin
    mul_in1_5 = Quotient_temp[15:12];
end

always @(*) begin
    mul_in2_5 = IN_Divisor[7:4];
end



always @(*) begin
    add_sub_in1_1 = mul_out_1;
end

always @(*) begin
    add_sub_in2_1 = IN_Dividend[19:16];
end

always @(*) begin
    add_sub_in1_2 = mul_out_2;
end

always @(*) begin
    add_sub_in2_2 = IN_Dividend[15:12];
end

always @(*) begin
    add_sub_in1_3 = mul_out_3;
end

always @(*) begin
    case (divisor_degree)
        3: add_sub_in2_3 = add_sub_out_2;
        2: add_sub_in2_3 = add_sub_out_2;
        1: add_sub_in2_3 = IN_Dividend[11:8];
        default: add_sub_in2_3 = 'd15;
    endcase
end

always @(*) begin
    add_sub_in1_4 = mul_out_4;
end

always @(*) begin
    if (IN_Divisor[11:8] != 'd15)
        add_sub_in2_4 = IN_Dividend[11:8];
    else
        add_sub_in2_4 = IN_Dividend[7:4];
end

always @(*) begin
    add_sub_in1_5 = mul_out_5;
end
always @(*) begin
    add_sub_in2_5 = add_sub_out_4;
end

always @(*) begin
    dividend_6 = IN_Dividend[23:20];
    dividend_1 = IN_Dividend[3:0];
end

always @(*) begin
    if (divisor_degree == 0)
        dividend_5 = IN_Dividend[19:16];
    else   
        dividend_5 = add_sub_out_1;
end

always @(*) begin
    case (divisor_degree)
        3: dividend_4 = add_sub_out_3;
        2: dividend_4 = add_sub_out_3;
        1: dividend_4 = add_sub_out_2;
        default: dividend_4 = IN_Dividend[15:12];
    endcase
end

always @(*) begin
    case (divisor_degree)
        2: dividend_3 = add_sub_out_5;
        1: dividend_3 = add_sub_out_3;
        default: dividend_3 = IN_Dividend[11:8];
    endcase
end

always @(*) begin
    if (divisor_degree == 1)
        dividend_2 = add_sub_out_4;
    else
        dividend_2 = IN_Dividend[7:4];
end

always @(*) begin
    case (divisor_degree)
        5: divisor = IN_Divisor[23:20];
        4: divisor = IN_Divisor[19:16];
        3: divisor = IN_Divisor[15:12];
        2: divisor = IN_Divisor[11:8];
        1: divisor = IN_Divisor[7:4];
        0: divisor = IN_Divisor[3:0];
        default: divisor = 'd15;
    endcase
end

always @(*) begin
    if (dividend_power_small)
        Quotient_out = {4'd15, 4'd15, 4'd15, 4'd15, 4'd15, 4'd15};
    else begin
        case (divisor_degree)
            5: Quotient_out = {4'd15, 4'd15, 4'd15, 4'd15, 4'd15, Quotient_temp[23:20]};
            4: Quotient_out = {4'd15, 4'd15, 4'd15, 4'd15, Quotient_temp[23:20], Quotient_temp[19:16]};
            3: Quotient_out = {4'd15, 4'd15, 4'd15, Quotient_temp[23:20], Quotient_temp[19:16], Quotient_temp[15:12]};
            2: Quotient_out = {4'd15, 4'd15, Quotient_temp[23:20], Quotient_temp[19:16], Quotient_temp[15:12], Quotient_temp[11:8]};
            1: Quotient_out = {4'd15, Quotient_temp[23:20], Quotient_temp[19:16], Quotient_temp[15:12], Quotient_temp[11:8], Quotient_temp[7:4]};
            0: Quotient_out = {Quotient_temp[23:20], Quotient_temp[19:16], Quotient_temp[15:12], Quotient_temp[11:8], Quotient_temp[7:4], Quotient_temp[3:0]};
            default: Quotient_out = {4'd15, 4'd15, 4'd15, 4'd15, 4'd15, 4'd15, 4'd15};
        endcase
    end
end
endmodule


module WIDTH_7_DIV (
    IN_Dividend,
    IN_Divisor,
    OUT_Quotient
);
input      [27:0]  IN_Dividend;
input      [27:0]  IN_Divisor;
output reg [27:0]  OUT_Quotient;

// wire       [27:0] Quotient_temp;
reg        [27:0] Quotient_out;
// case 0
wire       [3:0] div_out_case0;
// case 1
wire       [3:0] div_out_case1_1, div_out_case1_2;
wire       [3:0] mul_out_case1;
wire       [3:0] add_sub_out_case1;

// case 2
wire       [3:0] div_out_case2_1, div_out_case2_2, div_out_case2_3;
wire       [3:0] mul_out_case2_1;
wire       [3:0] mul_out_case2_2;
wire       [3:0] mul_out_case2_3;
wire       [3:0] add_sub_out_case2_1;
wire       [3:0] add_sub_out_case2_2;
wire       [3:0] add_sub_out_case2_3;

// case 3
wire       [3:0] div_out_case3_1, div_out_case3_2, div_out_case3_3, div_out_case3_4;
wire       [3:0] mul_out_case3_1;
wire       [3:0] mul_out_case3_2;
wire       [3:0] mul_out_case3_3;
wire       [3:0] mul_out_case3_4;
wire       [3:0] mul_out_case3_5;
wire       [3:0] mul_out_case3_6;
wire       [3:0] add_sub_out_case3_1;
wire       [3:0] add_sub_out_case3_2;
wire       [3:0] add_sub_out_case3_3;
wire       [3:0] add_sub_out_case3_4;
wire       [3:0] add_sub_out_case3_5;
wire       [3:0] add_sub_out_case3_6;

// case 4
wire       [3:0] div_out_case4_1, div_out_case4_2, div_out_case4_3, div_out_case4_4, div_out_case4_5;
wire       [3:0] mul_out_case4_1;
wire       [3:0] mul_out_case4_2; 
wire       [3:0] mul_out_case4_3;
wire       [3:0] mul_out_case4_4;
wire       [3:0] mul_out_case4_5;
wire       [3:0] mul_out_case4_6;
wire       [3:0] mul_out_case4_7;
wire       [3:0] add_sub_out_case4_1;
wire       [3:0] add_sub_out_case4_2;
wire       [3:0] add_sub_out_case4_3;
wire       [3:0] add_sub_out_case4_4;
wire       [3:0] add_sub_out_case4_5;
wire       [3:0] add_sub_out_case4_6;
wire       [3:0] add_sub_out_case4_7;

// case 5
wire       [3:0] div_out_case5_1, div_out_case5_2, div_out_case5_3, div_out_case5_4, div_out_case5_5, div_out_case5_6;
wire       [3:0] mul_out_case5_1;
wire       [3:0] mul_out_case5_2;
wire       [3:0] mul_out_case5_3;
wire       [3:0] mul_out_case5_4;
wire       [3:0] mul_out_case5_5;
wire       [3:0] add_sub_out_case5_1;
wire       [3:0] add_sub_out_case5_2;
wire       [3:0] add_sub_out_case5_3;
wire       [3:0] add_sub_out_case5_4;
wire       [3:0] add_sub_out_case5_5;

//case 6
wire       [3:0] div_out_case6_1, div_out_case6_2, div_out_case6_3, div_out_case6_4, div_out_case6_5, div_out_case6_6, div_out_case6_7;


reg  [2:0] divisor_degree;
reg  [2:0] dividend_degree;
wire       dividend_power_small;
reg [3:0] divisor;
reg [3:0] dividend_1, dividend_2, dividend_3, dividend_4, dividend_5, dividend_6, dividend_7;

// case 0
GF_DIV u1_width7(.div_in1(IN_Dividend[27:24]), .div_in2(divisor), .div_out(div_out_case0));

// case1
GF_DIV u2_width7(.div_in1(IN_Dividend[27:24]), .div_in2(divisor), .div_out(div_out_case1_1));
GF_MUL u3_width7(.mul_in1(div_out_case1_1), .mul_in2(IN_Divisor[19:16]), .mul_out(mul_out_case1));
GF_ADD_SUB u4_width7(.add_sub_in1(IN_Dividend[23:20]), .add_sub_in2(mul_out_case1), .add_sub_out(add_sub_out_case1));
GF_DIV u5_width7(.div_in1(add_sub_out_case1), .div_in2(divisor), .div_out(div_out_case1_2));

// case2
GF_DIV u6_width7(.div_in1(IN_Dividend[27:24]), .div_in2(divisor), .div_out(div_out_case2_1));
GF_MUL u7_width7(.mul_in1(div_out_case2_1), .mul_in2(IN_Divisor[15:12]), .mul_out(mul_out_case2_1));
GF_MUL u8_width7(.mul_in1(div_out_case2_1), .mul_in2(IN_Divisor[11:8]), .mul_out(mul_out_case2_2));
GF_ADD_SUB u9_width7(.add_sub_in1(IN_Dividend[23:20]), .add_sub_in2(mul_out_case2_1), .add_sub_out(add_sub_out_case2_1));
GF_ADD_SUB u10_width7(.add_sub_in1(IN_Dividend[19:16]), .add_sub_in2(mul_out_case2_2), .add_sub_out(add_sub_out_case2_2));
GF_DIV u11_width7(.div_in1(add_sub_out_case2_1), .div_in2(divisor), .div_out(div_out_case2_2));
GF_MUL u12_width7(.mul_in1(div_out_case2_2), .mul_in2(IN_Divisor[15:12]), .mul_out(mul_out_case2_3));
GF_ADD_SUB u13_width7(.add_sub_in1(add_sub_out_case2_2), .add_sub_in2(mul_out_case2_3), .add_sub_out(add_sub_out_case2_3));
GF_DIV u14_width7(.div_in1(add_sub_out_case2_3), .div_in2(divisor), .div_out(div_out_case2_3));

//case3
GF_DIV u15_width7(.div_in1(IN_Dividend[27:24]), .div_in2(divisor), .div_out(div_out_case3_1));
GF_MUL u16_width7(.mul_in1(div_out_case3_1), .mul_in2(IN_Divisor[11:8]), .mul_out(mul_out_case3_1));
GF_MUL u17_width7(.mul_in1(div_out_case3_1), .mul_in2(IN_Divisor[7:4]), .mul_out(mul_out_case3_2));
GF_MUL u18_width7(.mul_in1(div_out_case3_1), .mul_in2(IN_Divisor[3:0]), .mul_out(mul_out_case3_3));
GF_ADD_SUB u19_width7(.add_sub_in1(mul_out_case3_1), .add_sub_in2(IN_Dividend[23:20]), .add_sub_out(add_sub_out_case3_1));
GF_ADD_SUB u20_width7(.add_sub_in1(mul_out_case3_2), .add_sub_in2(IN_Dividend[19:16]), .add_sub_out(add_sub_out_case3_2));
GF_ADD_SUB u21_width7(.add_sub_in1(mul_out_case3_3), .add_sub_in2(IN_Dividend[15:12]), .add_sub_out(add_sub_out_case3_3));
GF_DIV u22_width7(.div_in1(add_sub_out_case3_1), .div_in2(divisor), .div_out(div_out_case3_2));
GF_MUL u23_width7(.mul_in1(div_out_case3_2), .mul_in2(IN_Divisor[11:8]), .mul_out(mul_out_case3_4));
GF_MUL u24_width7(.mul_in1(div_out_case3_2), .mul_in2(IN_Divisor[7:4]), .mul_out(mul_out_case3_5));
GF_ADD_SUB u25_width7(.add_sub_in1(add_sub_out_case3_2), .add_sub_in2(mul_out_case3_4), .add_sub_out(add_sub_out_case3_4));
GF_ADD_SUB u26_width7(.add_sub_in1(add_sub_out_case3_3), .add_sub_in2(mul_out_case3_5), .add_sub_out(add_sub_out_case3_5));
GF_DIV u27_width7(.div_in1(add_sub_out_case3_4), .div_in2(divisor), .div_out(div_out_case3_3));
GF_MUL u28_width7(.mul_in1(div_out_case3_3), .mul_in2(IN_Divisor[11:8]), .mul_out(mul_out_case3_6));
GF_ADD_SUB u29_width7(.add_sub_in1(add_sub_out_case3_5), .add_sub_in2(mul_out_case3_6), .add_sub_out(add_sub_out_case3_6));
GF_DIV u30_width7(.div_in1(add_sub_out_case3_6), .div_in2(divisor), .div_out(div_out_case3_4));

//case4
GF_DIV u31_width7(.div_in1(IN_Dividend[27:24]), .div_in2(divisor), .div_out(div_out_case4_1));
GF_MUL u32_width7(.mul_in1(div_out_case4_1), .mul_in2(IN_Divisor[7:4]), .mul_out(mul_out_case4_1));
GF_MUL u33_width7(.mul_in1(div_out_case4_1), .mul_in2(IN_Divisor[3:0]), .mul_out(mul_out_case4_2));
GF_ADD_SUB u34_width7(.add_sub_in1(mul_out_case4_1), .add_sub_in2(IN_Dividend[23:20]), .add_sub_out(add_sub_out_case4_1));
GF_ADD_SUB u35_width7(.add_sub_in1(mul_out_case4_2), .add_sub_in2(IN_Dividend[19:16]), .add_sub_out(add_sub_out_case4_2));
GF_DIV u36_width7(.div_in1(add_sub_out_case4_1), .div_in2(divisor), .div_out(div_out_case4_2));
GF_MUL u37_width7(.mul_in1(div_out_case4_2), .mul_in2(IN_Divisor[7:4]), .mul_out(mul_out_case4_3));
GF_MUL u38_width7(.mul_in1(div_out_case4_2), .mul_in2(IN_Divisor[3:0]), .mul_out(mul_out_case4_4));
GF_ADD_SUB u39_width7(.add_sub_in1(mul_out_case4_3), .add_sub_in2(add_sub_out_case4_2), .add_sub_out(add_sub_out_case4_3));
GF_ADD_SUB u40_width7(.add_sub_in1(mul_out_case4_4), .add_sub_in2(IN_Dividend[15:12]), .add_sub_out(add_sub_out_case4_4));
GF_DIV u41_width7(.div_in1(add_sub_out_case4_3), .div_in2(divisor), .div_out(div_out_case4_3));
GF_MUL u42_width7(.mul_in1(div_out_case4_3), .mul_in2(IN_Divisor[7:4]), .mul_out(mul_out_case4_5));
GF_MUL u43_width7(.mul_in1(div_out_case4_3), .mul_in2(IN_Divisor[3:0]), .mul_out(mul_out_case4_6));
GF_ADD_SUB u44_width7(.add_sub_in1(mul_out_case4_5), .add_sub_in2(add_sub_out_case4_4), .add_sub_out(add_sub_out_case4_5));
GF_ADD_SUB u45_width7(.add_sub_in1(mul_out_case4_6), .add_sub_in2(IN_Dividend[11:8]), .add_sub_out(add_sub_out_case4_6));
GF_DIV u46_width7(.div_in1(add_sub_out_case4_5), .div_in2(divisor), .div_out(div_out_case4_4));
GF_MUL u47_width7(.mul_in1(div_out_case4_4), .mul_in2(IN_Divisor[7:4]), .mul_out(mul_out_case4_7));
GF_ADD_SUB u48_width7(.add_sub_in1(mul_out_case4_7), .add_sub_in2(add_sub_out_case4_6), .add_sub_out(add_sub_out_case4_7));
GF_DIV u49_width7(.div_in1(add_sub_out_case4_7), .div_in2(divisor), .div_out(div_out_case4_5));

//case5
GF_DIV u50_width7(.div_in1(IN_Dividend[27:24]), .div_in2(divisor), .div_out(div_out_case5_1));
GF_MUL u51_width7(.mul_in1(div_out_case5_1), .mul_in2(IN_Divisor[3:0]), .mul_out(mul_out_case5_1));
GF_ADD_SUB u52_width7(.add_sub_in1(mul_out_case5_1), .add_sub_in2(IN_Dividend[23:20]), .add_sub_out(add_sub_out_case5_1));
GF_MUL u53_width7(.mul_in1(div_out_case5_2), .mul_in2(IN_Divisor[3:0]), .mul_out(mul_out_case5_2));
GF_ADD_SUB u54_width7(.add_sub_in1(mul_out_case5_2), .add_sub_in2(IN_Dividend[19:16]), .add_sub_out(add_sub_out_case5_2));
GF_MUL u55_width7(.mul_in1(div_out_case5_3), .mul_in2(IN_Divisor[3:0]), .mul_out(mul_out_case5_3));
GF_ADD_SUB u56_width7(.add_sub_in1(mul_out_case5_3), .add_sub_in2(IN_Dividend[15:12]), .add_sub_out(add_sub_out_case5_3));
GF_MUL u57_width7(.mul_in1(div_out_case5_4), .mul_in2(IN_Divisor[3:0]), .mul_out(mul_out_case5_4));
GF_ADD_SUB u58_width7(.add_sub_in1(mul_out_case5_4), .add_sub_in2(IN_Dividend[11:8]), .add_sub_out(add_sub_out_case5_4));
GF_MUL u59_width7(.mul_in1(div_out_case5_5), .mul_in2(IN_Divisor[3:0]), .mul_out(mul_out_case5_5));
GF_ADD_SUB u60_width7(.add_sub_in1(mul_out_case5_5), .add_sub_in2(IN_Dividend[7:4]), .add_sub_out(add_sub_out_case5_5));
GF_DIV u61_width7(.div_in1(add_sub_out_case5_1), .div_in2(divisor), .div_out(div_out_case5_2));
GF_DIV u62_width7(.div_in1(add_sub_out_case5_2), .div_in2(divisor), .div_out(div_out_case5_3));
GF_DIV u63_width7(.div_in1(add_sub_out_case5_3), .div_in2(divisor), .div_out(div_out_case5_4));
GF_DIV u64_width7(.div_in1(add_sub_out_case5_4), .div_in2(divisor), .div_out(div_out_case5_5));
GF_DIV u65_width7(.div_in1(add_sub_out_case5_5), .div_in2(divisor), .div_out(div_out_case5_6));

//case6
GF_DIV u66_width7(.div_in1(IN_Dividend[27:24]), .div_in2(divisor), .div_out(div_out_case6_1));
GF_DIV u67_width7(.div_in1(IN_Dividend[23:20]), .div_in2(divisor), .div_out(div_out_case6_2));
GF_DIV u68_width7(.div_in1(IN_Dividend[19:16]), .div_in2(divisor), .div_out(div_out_case6_3));
GF_DIV u69_width7(.div_in1(IN_Dividend[15:12]), .div_in2(divisor), .div_out(div_out_case6_4));
GF_DIV u70_width7(.div_in1(IN_Dividend[11:8]), .div_in2(divisor), .div_out(div_out_case6_5));
GF_DIV u71_width7(.div_in1(IN_Dividend[7:4]), .div_in2(divisor), .div_out(div_out_case6_6));
GF_DIV u72_width7(.div_in1(IN_Dividend[3:0]), .div_in2(divisor), .div_out(div_out_case6_7));

always @(*) begin
    if (IN_Divisor[27:24] != 'd15)
        divisor_degree = 'd6;
    else if (IN_Divisor[23:20] != 'd15)
        divisor_degree = 'd5;
    else if (IN_Divisor[19:16] != 'd15)
        divisor_degree = 'd4;
    else if (IN_Divisor[15:12] != 'd15)
        divisor_degree = 'd3;
    else if (IN_Divisor[11:8] != 'd15)
        divisor_degree = 'd2;
    else if (IN_Divisor[7:4] != 'd15)
        divisor_degree = 'd1;
    else if (IN_Divisor[3:0] != 'd15)
        divisor_degree = 'd0; 
    else
        divisor_degree = 'd7;
end

always @(*) begin
    if (IN_Dividend[27:24] != 'd15)
        dividend_degree = 'd6;
    else if (IN_Dividend[23:20] != 'd15)
        dividend_degree = 'd5;
    else if (IN_Dividend[19:16] != 'd15)
        dividend_degree = 'd4;
    else if (IN_Dividend[15:12] != 'd15)
        dividend_degree = 'd3;
    else if (IN_Dividend[11:8] != 'd15)
        dividend_degree = 'd2;
    else if (IN_Dividend[7:4] != 'd15)
        dividend_degree = 'd1;
    else if (IN_Dividend[3:0] != 'd15)
        dividend_degree = 'd0; 
    else
        dividend_degree = 'd7;
end

assign dividend_power_small = (dividend_degree < divisor_degree)? 1 : 0;

assign OUT_Quotient = (dividend_power_small)? {4'd15, 4'd15, 4'd15, 4'd15, 4'd15, 4'd15, 4'd15} : Quotient_out;

always @(*) begin
    case (divisor_degree)
        6: divisor = IN_Divisor[27:24];
        5: divisor = IN_Divisor[23:20];
        4: divisor = IN_Divisor[19:16];
        3: divisor = IN_Divisor[15:12];
        2: divisor = IN_Divisor[11:8];
        1: divisor = IN_Divisor[7:4];
        0: divisor = IN_Divisor[3:0];
        default: divisor = 'd15;
    endcase    
end

always @(*) begin
    case (divisor_degree)
        6: Quotient_out[27:24] = 4'd15;
        5: Quotient_out[27:24] = 4'd15;
        4: Quotient_out[27:24] = 4'd15;
        3: Quotient_out[27:24] = 4'd15;
        2: Quotient_out[27:24] = 4'd15;
        1: Quotient_out[27:24] = 4'd15;
        0: Quotient_out[27:24] = div_out_case6_1;
        default: Quotient_out[27:24] = {7{4'd15}};
    endcase
end



always @(*) begin
    case (divisor_degree)
        6: Quotient_out[23:20] = 4'd15;
        5: Quotient_out[23:20] = 4'd15;
        4: Quotient_out[23:20] = 4'd15;
        3: Quotient_out[23:20] = 4'd15;
        2: Quotient_out[23:20] = 4'd15;
        1: Quotient_out[23:20] = div_out_case5_1;
        0: Quotient_out[23:20] = div_out_case6_2;
        default: Quotient_out[23:20] = {7{4'd15}};
    endcase
end

always @(*) begin
    case (divisor_degree)
        6: Quotient_out[19:16] = 4'd15;
        5: Quotient_out[19:16] = 4'd15;
        4: Quotient_out[19:16] = 4'd15;
        3: Quotient_out[19:16] = 4'd15;
        2: Quotient_out[19:16] = div_out_case4_1;
        1: Quotient_out[19:16] = div_out_case5_2;
        0: Quotient_out[19:16] = div_out_case6_3;
        default: Quotient_out[19:16] = {7{4'd15}};
    endcase
end

always @(*) begin
    case (divisor_degree)
        6: Quotient_out[15:12] = 4'd15;
        5: Quotient_out[15:12] = 4'd15;
        4: Quotient_out[15:12] = 4'd15;
        3: Quotient_out[15:12] = div_out_case3_1;
        2: Quotient_out[15:12] = div_out_case4_2;
        1: Quotient_out[15:12] = div_out_case5_3;
        0: Quotient_out[15:12] = div_out_case6_4;
        default: Quotient_out[15:12] = {7{4'd15}};
    endcase
end

always @(*) begin
    case (divisor_degree)
        6: Quotient_out[11:8] = 4'd15;
        5: Quotient_out[11:8] = 4'd15;
        4: Quotient_out[11:8] = div_out_case2_1;
        3: Quotient_out[11:8] = div_out_case3_2;
        2: Quotient_out[11:8] = div_out_case4_3;
        1: Quotient_out[11:8] = div_out_case5_4;
        0: Quotient_out[11:8] = div_out_case6_5;
        default: Quotient_out[11:8] = {7{4'd15}};
    endcase
end

always @(*) begin
    case (divisor_degree)
        6: Quotient_out[7:4] = 4'd15;
        5: Quotient_out[7:4] = div_out_case1_1;
        4: Quotient_out[7:4] = div_out_case2_2;
        3: Quotient_out[7:4] = div_out_case3_3;
        2: Quotient_out[7:4] = div_out_case4_4;
        1: Quotient_out[7:4] = div_out_case5_5;
        0: Quotient_out[7:4] = div_out_case6_6;
        default: Quotient_out[7:4] = {7{4'd15}};
    endcase
end

always @(*) begin
    case (divisor_degree)
        6: Quotient_out[3:0] = div_out_case0;
        5: Quotient_out[3:0] = div_out_case1_2;
        4: Quotient_out[3:0] = div_out_case2_3;
        3: Quotient_out[3:0] = div_out_case3_4;
        2: Quotient_out[3:0] = div_out_case4_5;
        1: Quotient_out[3:0] = div_out_case5_6;
        0: Quotient_out[3:0] = div_out_case6_7;
        default: Quotient_out[3:0] = {7{4'd15}};
    endcase
end

endmodule

// ===============================================================
//                     SUBMODULE(GF OP)
// ===============================================================
// add & sub
module GF_ADD_SUB (
    add_sub_in1,
    add_sub_in2,
    add_sub_out
);
input      [3:0] add_sub_in1;
input      [3:0] add_sub_in2;
output reg [3:0] add_sub_out;

wire [3:0] add_sub_temp;

wire [3:0] alpha_to_decimal [0:15];
wire [3:0] deciaml_to_alpha [0:15];
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

assign add_sub_temp = alpha_to_decimal[add_sub_in1] ^ alpha_to_decimal[add_sub_in2];
always @(*) begin
    add_sub_out = deciaml_to_alpha[add_sub_temp];
end
endmodule

// module GF_MUL(
//     mul_in1,
//     mul_in2,
//     mul_out
// );
// input      [3:0] mul_in1;
// input      [3:0] mul_in2;
// output reg [3:0] mul_out; 

// always @(*) begin
//     if (mul_in1 == 'd15 || mul_in2 == 'd15)
//         mul_out = 'd15;
//     else begin
//         if (mul_in1 + mul_in2 >= 'd15)
//             mul_out = mul_in1 + mul_in2 - 'd15;
//         else
//             mul_out = mul_in1 + mul_in2;
//     end
    
// end
// endmodule

module GF_MUL(
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

module GF_DIV (
    div_in1,
    div_in2,
    div_out
);
input       [3:0] div_in1;
input       [3:0] div_in2;
output reg  [3:0] div_out;

wire signed [4:0] diff;
assign diff = div_in1 - div_in2;
always @(*) begin
    if ((div_in1 == 'd15) || (div_in2 == 'd15))
        div_out = 'd15;
    // else if (div_in2 == 'd15)
    //     div_out = 'd15;
    else begin
        div_out = (diff < 0)? diff + 15 : diff; 
    end
end 
endmodule