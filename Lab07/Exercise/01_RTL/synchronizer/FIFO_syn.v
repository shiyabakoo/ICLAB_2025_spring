module FIFO_syn #(parameter WIDTH=32, parameter WORDS=64) (
    wclk,
    rclk,
    rst_n,
    winc,
    wdata,
    wfull,
    rinc,
    rdata,
    rempty,

    clk2_fifo_flag1,
    clk2_fifo_flag2,
    clk2_fifo_flag3,
    clk2_fifo_flag4,

    fifo_clk3_flag1,
    fifo_clk3_flag2,
    fifo_clk3_flag3,
    fifo_clk3_flag4
);

input wclk, rclk;
input rst_n;
input winc;
input [WIDTH-1:0] wdata;
output reg wfull;
input rinc;
output reg [WIDTH-1:0] rdata;
output reg rempty;

// You can change the input / output of the custom flag ports
input clk2_fifo_flag1;
input clk2_fifo_flag2;
output clk2_fifo_flag3;
output clk2_fifo_flag4;

input fifo_clk3_flag1;
input fifo_clk3_flag2;
output fifo_clk3_flag3;
output fifo_clk3_flag4;

wire [WIDTH-1:0] rdata_q;
wire [6:0]       wptr_syn, rptr_syn;
wire [5:0]       waddr, raddr;
reg              WEN_A, rinc_temp;
// Remember: 
//   wptr and rptr should be gray coded
//   Don't modify the signal name
reg [$clog2(WORDS):0] wptr;
reg [$clog2(WORDS):0] rptr;

reg [$clog2(WORDS):0] wptr_ff;
reg [$clog2(WORDS):0] rptr_ff;
// wire [$clog2(WORDS):0] wptr;
// wire [$clog2(WORDS):0] rptr;

//  Add one more register stage to rdata
always @(posedge rclk) begin
    rinc_temp <= rinc;
end
always @(posedge rclk) begin
    if (rinc_temp)
        rdata <= rdata_q;
    else
        rdata <= rdata;
end

assign WEN_A = !winc;
DUAL_64X32X1BM1 u_dual_sram (
    .CKA(wclk),
    .CKB(rclk),
    .WEAN(WEN_A),
    .WEBN(1'b1),
    .CSA(1'b1),
    .CSB(1'b1),
    .OEA(1'b1),
    .OEB(1'b1),
    .A0(waddr[0]),
    .A1(waddr[1]),
    .A2(waddr[2]),
    .A3(waddr[3]),
    .A4(waddr[4]),
    .A5(waddr[5]),
    .B0(raddr[0]),
    .B1(raddr[1]),
    .B2(raddr[2]),
    .B3(raddr[3]),
    .B4(raddr[4]),
    .B5(raddr[5]),
    .DIA0(wdata[0]),
    .DIA1(wdata[1]),
    .DIA2(wdata[2]),
    .DIA3(wdata[3]),
    .DIA4(wdata[4]),
    .DIA5(wdata[5]),
    .DIA6(wdata[6]),
    .DIA7(wdata[7]),
    .DIA8(wdata[8]),
    .DIA9(wdata[9]),
    .DIA10(wdata[10]),
    .DIA11(wdata[11]),
    .DIA12(wdata[12]),
    .DIA13(wdata[13]),
    .DIA14(wdata[14]),
    .DIA15(wdata[15]),
    .DIA16(wdata[16]),
    .DIA17(wdata[17]),
    .DIA18(wdata[18]),
    .DIA19(wdata[19]),
    .DIA20(wdata[20]),
    .DIA21(wdata[21]),
    .DIA22(wdata[22]),
    .DIA23(wdata[23]),
    .DIA24(wdata[24]),
    .DIA25(wdata[25]),
    .DIA26(wdata[26]),
    .DIA27(wdata[27]),
    .DIA28(wdata[28]),
    .DIA29(wdata[29]),
    .DIA30(wdata[30]),
    .DIA31(wdata[31]),
    .DIB0(),
    .DIB1(),
    .DIB2(),
    .DIB3(),
    .DIB4(),
    .DIB5(),
    .DIB6(),
    .DIB7(),
    .DIB8(),
    .DIB9(),
    .DIB10(),
    .DIB11(),
    .DIB12(),
    .DIB13(),
    .DIB14(),
    .DIB15(),
    .DIB16(),
    .DIB17(),
    .DIB18(),
    .DIB19(),
    .DIB20(),
    .DIB21(),
    .DIB22(),
    .DIB23(),
    .DIB24(),
    .DIB25(),
    .DIB26(),
    .DIB27(),
    .DIB28(),
    .DIB29(),
    .DIB30(),
    .DIB31(),
    .DOB0(rdata_q[0]),
    .DOB1(rdata_q[1]),
    .DOB2(rdata_q[2]),
    .DOB3(rdata_q[3]),
    .DOB4(rdata_q[4]),
    .DOB5(rdata_q[5]),
    .DOB6(rdata_q[6]),
    .DOB7(rdata_q[7]),
    .DOB8(rdata_q[8]),
    .DOB9(rdata_q[9]),
    .DOB10(rdata_q[10]),
    .DOB11(rdata_q[11]),
    .DOB12(rdata_q[12]),
    .DOB13(rdata_q[13]),
    .DOB14(rdata_q[14]),
    .DOB15(rdata_q[15]),
    .DOB16(rdata_q[16]),
    .DOB17(rdata_q[17]),
    .DOB18(rdata_q[18]),
    .DOB19(rdata_q[19]),
    .DOB20(rdata_q[20]),
    .DOB21(rdata_q[21]),
    .DOB22(rdata_q[22]),
    .DOB23(rdata_q[23]),
    .DOB24(rdata_q[24]),
    .DOB25(rdata_q[25]),
    .DOB26(rdata_q[26]),
    .DOB27(rdata_q[27]),
    .DOB28(rdata_q[28]),
    .DOB29(rdata_q[29]),
    .DOB30(rdata_q[30]),
    .DOB31(rdata_q[31])
);

// read side
NDFF_BUS_syn #(7) r_to_w(.D(rptr_ff), .Q(rptr_syn), .clk(wclk), .rst_n(rst_n));
r_ctrl r_ctrl(.rclk(rclk), .rst_n(rst_n), .rinc(rinc), .wptr_syn(wptr_syn), .rempty(rempty), .rptr(rptr), .raddr(raddr));
// must register out 
always @(posedge rclk or negedge rst_n) begin
    if (!rst_n)
        rptr_ff <= 0;
    else
        rptr_ff <= rptr;
end
// write side
NDFF_BUS_syn #(7) w_to_r(.D(wptr_ff), .Q(wptr_syn), .clk(rclk), .rst_n(rst_n));
w_ctrl w_ctrl(.wclk(wclk), .rst_n(rst_n), .winc(winc), .rptr_syn(rptr_syn), .wfull(wfull), .wptr(wptr), .waddr(waddr));
// must register out 
always @(posedge wclk or negedge rst_n) begin
    if (!rst_n)
        wptr_ff <= 0;
    else
        wptr_ff <= wptr;
end
endmodule

module w_ctrl (
    // input port
    input        wclk,
    input        winc,
    input        rst_n,
    input  [6:0] rptr_syn,
    // output port
    output       wfull,
    output [6:0] wptr,
    output [5:0] waddr
);

reg [6:0] ptr_temp;

always @(posedge wclk or negedge rst_n) begin 
    if (!rst_n)
        ptr_temp <= 0;
    else if (winc && !wfull)
        ptr_temp <= ptr_temp + 'd1;
    else
        ptr_temp <= ptr_temp;
end

assign wptr  = ptr_temp ^ (ptr_temp >> 1); // gray code transformation
assign waddr = ptr_temp[5:0];
assign wfull = ((wptr[6:5]) == (~rptr_syn[6:5])) && ((wptr[4:0]) == (rptr_syn[4:0])); // check full
endmodule

module r_ctrl (
    // input port
    input        rclk,
    input        rst_n,
    input        rinc,
    input  [6:0] wptr_syn,
    // output port
    output       rempty,
    output [6:0] rptr,
    output [5:0] raddr
);

reg [6:0] ptr_temp;

always @(posedge rclk or negedge rst_n) begin
    if (!rst_n)
        ptr_temp <= 0;
    else if (rinc && !rempty)
        ptr_temp <= ptr_temp + 'd1;
    else
        ptr_temp <= ptr_temp;
end

assign rptr  = ptr_temp ^ (ptr_temp >> 1); // gray code transformation
assign raddr = ptr_temp[5:0];
assign rempty = (rptr == wptr_syn);
endmodule


