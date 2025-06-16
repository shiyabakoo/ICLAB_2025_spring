// synopsys translate_off
`ifdef RTL
	`include "GATED_OR.v"
`else
	`include "Netlist/GATED_OR_SYN.v"
`endif
// synopsys translate_on

module SNN(
	// Input signals
	clk,
	rst_n,
	cg_en,
	in_valid,
	img,
	ker,
	weight,

	// Output signals
	out_valid,
	out_data
);

input clk;
input rst_n;
input in_valid;
input cg_en;
input [7:0] img;
input [7:0] ker;
input [7:0] weight;

output reg out_valid;
output reg [9:0] out_data;

//==============================================//
//       parameter & integer declaration        //
//==============================================//
localparam IDLE = 'd0,
		   CNN_1 = 'd1,
		   CNN_2 = 'd2,
		   OUT   = 'd3;

//==============================================//
//           reg & wire declaration             //
//==============================================//
reg			[5:0] 	in_cnt;
reg 		[4:0] 	state_cnt;
reg 		[7:0] 	ker_matrix 		[0:8];
reg 		[7:0] 	weight_matrix 	[0:3];
reg 		[7:0] 	img_matrix 		[0:35]; 
reg       			save_img2;
reg 		[1:0] 	c_state;
reg 		[1:0] 	n_state;
integer i;
genvar  j;
//==============================================//
//                    FSM                       //
//==============================================//
always @(posedge clk or negedge rst_n) begin
	if (!rst_n)
		c_state <= IDLE;
	else
		c_state <= n_state;
end

always @(*) begin
	case (c_state)
		IDLE: begin
			if ((in_cnt == 'd20) && save_img2)
				n_state = CNN_2;
			else if (in_cnt == 'd20)
				n_state = CNN_1;
			else
				n_state = IDLE;
		end 
		CNN_1: begin
			if (state_cnt == 'd18)
				n_state = IDLE;
			else
				n_state = CNN_1;
		end
		CNN_2: begin
			if (state_cnt == 'd17)
				n_state = OUT;
			else
				n_state = CNN_2;
		end
		OUT: begin
			n_state = IDLE;
		end
		default: n_state = IDLE;
	endcase
end
//==============================================//
//                  CLOCK GATE                  //
//==============================================//
wire g_clk_input[0:35];
generate
	for(j = 0;j < 36;j = j + 1) begin
		GATED_OR GATED_INPUT(.CLOCK(clk), .SLEEP_CTRL(cg_en && !(in_cnt == j)), .RST_N(rst_n), .CLOCK_GATED(g_clk_input[j]));
	end
endgenerate
//==============================================//
//                   INPUT                      //
//==============================================//
always @(posedge clk or negedge rst_n) begin
	if (!rst_n)
		in_cnt <= 0;
	else if (in_valid) begin
		if (in_cnt == 'd35)
			in_cnt <= 0;
		else
			in_cnt <= in_cnt + 'd1;
	end
	else
		in_cnt <= 0;
end


always @(posedge clk) begin
	if (in_valid) begin
		if (in_cnt == 'd35)
			save_img2 <= 1;
	end
	else
		save_img2 <= 0;
end

generate
	for (j = 0; j < 36; j = j + 1) begin
		always @(posedge g_clk_input[j]) begin
			if ((in_cnt == j) && in_valid)
				img_matrix[j] <= img;
		end
	end
endgenerate

generate
	for (j = 0; j < 9; j = j + 1) begin
		always @(posedge g_clk_input[j]) begin
			if (in_valid && !save_img2) begin
				if (in_cnt == j)
					ker_matrix[j] <= ker;
			end
		end
	end
endgenerate

generate
	for (j = 0; j < 4; j = j + 1) begin
		always @(posedge g_clk_input[j]) begin
			if (in_valid && !save_img2) begin
				if (in_cnt == j)
					weight_matrix[j] <= weight;
			end
		end
	end
endgenerate
//==============================================//
//                CNN SUB NETWORK               //
//==============================================//
reg  [19:0] convolution_res;
reg  [4:0]  index;
//--------------------------------------------------
// convolution
always @(*) begin
	case(state_cnt)
		0:	index = 7;
		1:	index = 8;
		2:	index = 9;
		3:	index = 10;
		4:	index = 13;
		5:	index = 14;
		6:	index = 15;
		7:	index = 16;
		8:	index = 19;
		9:	index = 20;
		10:	index = 21;
		11:	index = 22;
		12:	index = 25;
		13:	index = 26;
		14:	index = 27;
		15:	index = 28;
		default: index = 0;
	endcase
end
always @(posedge clk or negedge rst_n) begin
	if (!rst_n)
		state_cnt <= 0;
	else if ((c_state == CNN_1) || (c_state == CNN_2))
		state_cnt <= state_cnt + 1;  
	else
		state_cnt <= 0;
end
always @(posedge clk) begin
	if ((c_state == CNN_1) || (c_state == CNN_2)) begin
		if (state_cnt <= 15) begin
			convolution_res <= (img_matrix[index - 7] * ker_matrix[0]) + (img_matrix[index - 6] * ker_matrix[1]) + (img_matrix[index - 5] * ker_matrix[2])
	               			 + (img_matrix[index - 1] * ker_matrix[3]) + (img_matrix[index]     * ker_matrix[4]) + (img_matrix[index + 1] * ker_matrix[5])
				   		     + (img_matrix[index + 5] * ker_matrix[6]) + (img_matrix[index + 6] * ker_matrix[7]) + (img_matrix[index + 7] * ker_matrix[8]);
		end
	end
	else
		convolution_res <= 'd0;
end
//--------------------------------------------------
// quantization
reg [7:0] feature_matrix [0:7];
reg	[7:0] quantized_feature;
reg	[7:0] temp;

always @(posedge clk) begin
	if ((c_state == CNN_1) || (c_state == CNN_2)) begin
		if (state_cnt >= 'd1) begin
			for (i = 0; i < 7; i = i + 1) begin
				feature_matrix[i] <= feature_matrix[i + 1];
			end
			feature_matrix[7] <= (convolution_res / 'd2295);
		end
	end
	else begin
		for (i = 0; i < 7; i = i + 1) begin
			feature_matrix[i] <= 0;
		end
		feature_matrix[7] <= 0;
	end
end


//--------------------------------------------------
// Max-pooling && fully connected
reg  [16:0] encode_value_1;
reg  [16:0] encode_value_2;
reg  [7:0]  max_pool_window_1 [0:3];
reg  [7:0]  max_pool_window_2 [0:3];
wire [7:0]  max_pool_1;
wire [7:0]  max_pool_2;
always @(*) begin
	max_pool_window_1[0] = feature_matrix[0];
	max_pool_window_1[1] = feature_matrix[1];
	max_pool_window_1[2] = feature_matrix[4];
	max_pool_window_1[3] = feature_matrix[5];
end
always @(*) begin
	max_pool_window_2[0] = feature_matrix[2];
	max_pool_window_2[1] = feature_matrix[3];
	max_pool_window_2[2] = feature_matrix[6];
	max_pool_window_2[3] = feature_matrix[7];
end
max_pool u1(.max_pool_window(max_pool_window_1), .max_pool_res(max_pool_1));
max_pool u2(.max_pool_window(max_pool_window_2), .max_pool_res(max_pool_2));

wire	g_clk_fully;
GATED_OR GATED_fully(.CLOCK(clk), .SLEEP_CTRL(cg_en && !((state_cnt == 9) | (state_cnt == 17))), .RST_N(rst_n), .CLOCK_GATED(g_clk_fully));

always @(posedge g_clk_fully) begin
	if ((state_cnt == 9) | (state_cnt == 17)) begin
		encode_value_1 <= (max_pool_1 * weight_matrix[0]) + (max_pool_2 * weight_matrix[2]);
		encode_value_2 <= (max_pool_1 * weight_matrix[1]) + (max_pool_2 * weight_matrix[3]);
	end
	else begin
		encode_value_1 <= ~encode_value_1;
		encode_value_2 <= ~encode_value_2;
	end
end
//--------------------------------------------------
// quantization encode
reg [7:0] quantized_encode_1;
reg [7:0] quantized_encode_2;
reg [7:0] encode_vector [0:3];
always @(*) begin
	quantized_encode_1 = encode_value_1 / 'd510;
	quantized_encode_2 = encode_value_2 / 'd510;
end
always @(posedge clk) begin
	if ((c_state == CNN_1)) begin
		if (state_cnt == 'd10) begin
			encode_vector[0] <= quantized_encode_1;
			encode_vector[1] <= quantized_encode_2;
		end
	end
	else begin
		encode_vector[0] <= encode_vector[0];
		encode_vector[1] <= encode_vector[1];
	end
end
always @(posedge clk) begin
	if ((c_state == CNN_1)) begin
		if (state_cnt == 'd18) begin
			encode_vector[2] <= quantized_encode_1;
			encode_vector[3] <= quantized_encode_2;
		end
	end
	else begin
		encode_vector[2] <= encode_vector[2];
		encode_vector[3] <= encode_vector[3];
	end
end
//--------------------------------------------------
// L1 distance
reg [9:0] L1_distance_temp;
reg [9:0] L1_distance;
reg [7:0] abs_in1, abs_in2;
reg [7:0] abs_out1, abs_out2;
abs abs_u1(.value_1(abs_in1), .value_2(quantized_encode_1), .abs_value(abs_out1));
abs abs_u2(.value_1(abs_in2), .value_2(quantized_encode_2), .abs_value(abs_out2));
always @(*) begin
	if (state_cnt == 'd10) begin
		abs_in1 = encode_vector[0];
		abs_in2 = encode_vector[1];
	end
	else if (state_cnt == 'd18) begin
		abs_in1 = encode_vector[2];
		abs_in2 = encode_vector[3];
	end
	else begin
		abs_in1 = 0;
		abs_in2 = 0;
	end
end
always @(posedge clk) begin
	if (c_state == IDLE)
		L1_distance_temp <= 0;
	else if ((c_state == CNN_2)) begin
		if (state_cnt == 'd10)
			L1_distance_temp <= abs_out1 + abs_out2;
	end
end
assign L1_distance = L1_distance_temp + abs_out1 + abs_out2;
//==============================================//
//                  OUTPUT                      //
//==============================================//
always @(*) begin
	if (c_state == OUT)
		out_valid = 1;
	else
		out_valid = 0;
end

always @(*) begin
	if (c_state == OUT) begin
		if (L1_distance >= 'd16)
			out_data = L1_distance;
		else
			out_data = 0;
	end
	else 
		out_data = 0;
end
endmodule


//==============================================//
//                 SUBMODULE                    //
//==============================================//
module comparator (
    input [7:0] in_1, 
    input [7:0] in_2,
    output reg [7:0] small_out,
    output reg [7:0] big_out
);

always @(*) begin
    if (in_1 > in_2) begin
        small_out = in_2;
        big_out = in_1;
    end 
    else begin
        small_out = in_1;
        big_out = in_2;
    end 
end
endmodule

module max_pool (
	input [7:0] max_pool_window [0:3],
	output reg	[7:0] max_pool_res
);

reg [7:0] compare_0 [0:1];
reg [7:0] compare_1 [0:1];
reg [7:0] compare_2 [0:1];

comparator u0(.in_1(max_pool_window[0]), .in_2(max_pool_window[1]), .small_out(compare_0[0]), .big_out(compare_0[1]));
comparator u1(.in_1(max_pool_window[2]), .in_2(max_pool_window[3]), .small_out(compare_1[0]), .big_out(compare_1[1]));
comparator u3(.in_1(compare_0[1]), .in_2(compare_1[1]), .small_out(compare_2[0]), .big_out(compare_2[1]));

assign max_pool_res = compare_2[1];

endmodule

module abs (
	input [7:0] value_1,
	input [7:0] value_2,
	output reg [7:0] abs_value
);

	always @(*) begin
			if (value_1 > value_2)
				abs_value = value_1 - value_2;
			else
				abs_value = value_2 - value_1;
		end
endmodule

