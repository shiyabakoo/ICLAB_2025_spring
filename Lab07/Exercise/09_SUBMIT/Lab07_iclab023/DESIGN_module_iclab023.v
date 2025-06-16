module CLK_1_MODULE ( // get input
    clk,
    rst_n,
    in_valid,
    seed_in,
    out_idle,
    out_valid,
    seed_out,

    clk1_handshake_flag1,
    clk1_handshake_flag2,
    clk1_handshake_flag3,
    clk1_handshake_flag4
);

input clk;
input rst_n;
input in_valid;
input [31:0] seed_in;
input out_idle;
output reg out_valid;
output reg [31:0] seed_out;

// You can change the input / output of the custom flag ports
input clk1_handshake_flag1;
input clk1_handshake_flag2;
output clk1_handshake_flag3;
output clk1_handshake_flag4; 

// always @(posedge clk or negedge rst_n) begin
//     if (!rst_n)
//         out_valid <= 0;
//     else if (in_valid)
//         out_valid <= 1;
//     else
//         out_valid <= 0;
// end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        seed_out <= 0;
        out_valid <= 0;
    end
    else if (in_valid && out_idle) begin // only when handshake idle, the value can be transferred
        seed_out <= seed_in;
        out_valid <= 1;
    end
    else begin
        seed_out <= seed_out;
        out_valid <= 0;
    end
end

endmodule

module CLK_2_MODULE (
    clk,
    rst_n,
    in_valid,
    fifo_full,
    seed,
    out_valid,
    rand_num,
    busy,

    handshake_clk2_flag1,
    handshake_clk2_flag2,
    handshake_clk2_flag3,
    handshake_clk2_flag4,

    clk2_fifo_flag1,
    clk2_fifo_flag2,
    clk2_fifo_flag3,
    clk2_fifo_flag4
);

input clk;
input rst_n;
input in_valid;
input fifo_full;
input [31:0] seed;
output out_valid;
output [31:0] rand_num;
output  busy;

// You can change the input / output of the custom flag ports
input handshake_clk2_flag1;
input handshake_clk2_flag2;
output handshake_clk2_flag3;
output handshake_clk2_flag4;

input clk2_fifo_flag1;
input clk2_fifo_flag2;
output clk2_fifo_flag3;
output clk2_fifo_flag4;

reg [31:0] xorshift_1;
reg [31:0] xorshift_2;
reg [31:0] x_n_next;
reg [31:0] x_n;
reg [7:0]  cnt;
reg        cal_start;
// Xorshift
assign xorshift_1 = x_n ^ (x_n << 13);
assign xorshift_2 = xorshift_1 ^ (xorshift_1 >> 17);
assign x_n_next = xorshift_2 ^ (xorshift_2 << 5);

assign rand_num = x_n_next;
assign busy = cal_start;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        cal_start <= 0;
    else if (cnt == 255 && !fifo_full)
        cal_start <= 0;
    else if (in_valid)
        cal_start <= 1;
    else
        cal_start <= cal_start;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        cnt <= 0;
    else if (cal_start)
        if (fifo_full)
            cnt <= cnt;
        else
            cnt <= cnt + 1;
    else
        cnt <= cnt;
end

assign out_valid = cal_start && (!fifo_full);

always @(posedge clk) begin
    if (in_valid)
        x_n <= seed;
    else if (cal_start && !fifo_full)
        x_n <= x_n_next;
    else
        x_n <= x_n;
end


endmodule

module CLK_3_MODULE (
    clk,
    rst_n,
    fifo_empty,
    fifo_rdata,
    fifo_rinc,
    out_valid,
    rand_num,

    fifo_clk3_flag1,
    fifo_clk3_flag2,
    fifo_clk3_flag3,
    fifo_clk3_flag4
);

input clk;
input rst_n;
input fifo_empty;
input [31:0] fifo_rdata;
output fifo_rinc;
output reg out_valid;
output reg [31:0] rand_num;

// You can change the input / output of the custom flag ports
input fifo_clk3_flag1;
input fifo_clk3_flag2;
output fifo_clk3_flag3;
output fifo_clk3_flag4;

reg [8:0] out_cnt;
reg       empty_ff;

assign fifo_rinc = !fifo_empty;

always @(*) begin
    if (out_valid)
        rand_num = fifo_rdata;
    else
        rand_num = 0;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        out_valid <= 0;
    else
        out_valid <= !empty_ff;
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        empty_ff <= 1;
    else
        empty_ff <= fifo_empty;
end
// always @(posedge clk or negedge rst_n) begin
//     if (!rst_n)
//         out_cnt <= 0;
//     else if (!fifo_empty)
//         out_cnt <= out_cnt + 1;
//     else
//         out_cnt <= out_cnt;
// end


endmodule


