module Handshake_syn #(parameter WIDTH=32) (
    sclk,
    dclk,
    rst_n,
    sready,
    din,
    dbusy,
    sidle,
    dvalid,
    dout,

    clk1_handshake_flag1,
    clk1_handshake_flag2,
    clk1_handshake_flag3,
    clk1_handshake_flag4,

    handshake_clk2_flag1,
    handshake_clk2_flag2,
    handshake_clk2_flag3,
    handshake_clk2_flag4
);

input sclk, dclk;
input rst_n;
input sready;
input [WIDTH-1:0] din;
input dbusy;
output sidle;
output reg dvalid;
output reg [WIDTH-1:0] dout;

// You can change the input / output of the custom flag ports
input clk1_handshake_flag1;
input clk1_handshake_flag2;
output clk1_handshake_flag3;
output clk1_handshake_flag4;

input handshake_clk2_flag1;
input handshake_clk2_flag2;
output handshake_clk2_flag3;
output handshake_clk2_flag4;

// Remember:
//   Don't modify the signal name
reg sreq;
wire dreq;
reg dack;
wire sack;

reg [WIDTH-1:0] data;


// source-----------------------------------------
assign sidle = !(sreq | sack | sready); // if sready high mean that handshake start, so idle must be low until sack be low

NDFF_syn s_to_d(.D(sreq), .clk(dclk), .rst_n(rst_n), .Q(dreq));
always @(posedge sclk or negedge rst_n) begin
    if (!rst_n)
        sreq <= 0;
    else if (sack) // if sack high, must be low next cycle 
        sreq <= 0;
    else if (sready) // when input valid, send sreq to destination 
        sreq <= 1;
    else // if sreq is high, must be stable untill sack high
        sreq <= sreq;
end

// destination--------------------------------------
NDFF_syn d_to_s(.D(dack), .clk(sclk), .rst_n(rst_n), .Q(sack));

always @(posedge dclk or negedge rst_n) begin
    if (!rst_n)
        dack <= 0;
    else if (!dreq) // if dreq low, dack must be low
        dack <= 0;
    else if (dreq && !dbusy) // if dreq high and busy low, mean that can get data (dack high)
        dack <= 1;
    else
        dack <= dack;
end


always @(posedge dclk or negedge rst_n) begin
    if (!rst_n) begin
        dout <= 0;
        dvalid <= 0;
    end
    else if (dreq && !dbusy && !dack) begin
        dout <= din;
        dvalid <= 1; 
    end
    else begin
        dout <= dout;
        dvalid <= 0;
    end
end

endmodule


