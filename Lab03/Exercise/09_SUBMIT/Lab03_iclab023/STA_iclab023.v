/**************************************************************************/
// Copyright (c) 2025, OASIS Lab
// MODULE: STA
// FILE NAME: STA.v
// VERSRION: 1.0
// DATE: 2025/02/26
// AUTHOR: Yu-Hao Cheng, NYCU IEE
// DESCRIPTION: ICLAB 2025 Spring / LAB3 / STA
// MODIFICATION HISTORY:
// Date                 Description
// 
/**************************************************************************/
module STA(
	//INPUT
	rst_n,
	clk,
	in_valid,
	delay,
	source,
	destination,
	//OUTPUT
	out_valid,
	worst_delay,
	path
);

//---------------------------------------------------------------------
//   PORT DECLARATION          
//---------------------------------------------------------------------
input				rst_n, clk, in_valid;
input		[3:0]	delay;
input		[3:0]	source;
input		[3:0]	destination;

output reg			out_valid;
output reg	[7:0]	worst_delay;
output reg	[3:0]	path;

//---------------------------------------------------------------------
//   PARAMETER & INTEGER DECLARATION
//---------------------------------------------------------------------
localparam IDLE = 4'd0,
		   INPUT = 4'd1,
		   READ_QUEUE = 4'd2,
		   FIND_ZERO_IN_DEGREE = 4'd3,
		   FIND_WORST_DELAY = 4'd4,
		   FIND_LONGEST_PATH = 4'd5,
		   OUTPUT_STATE = 4'd6;

//---------------------------------------------------------------------
//   REG & WIRE DECLARATION
//---------------------------------------------------------------------
// FSM
reg [3:0] c_state;
reg [3:0] n_state;
reg 	  no_indegree_is_0;
// input state
reg [3:0] node_delay [0:15];
reg [3:0] delay_ff;
reg [3:0] destination_ff;
reg [3:0] source_ff;
reg 	  connection [0:15][0:15];
reg [3:0] input_count;
reg 	  delay_input_done;
//topo sort
reg [3:0] in_degree [1:15];
reg       in_degree_is_0 [1:15];
reg [3:0] scan_count;
// fifio
reg [3:0] topo_fifo [0:15];
reg [3:0] wrt_ptr;
reg [3:0] rd_ptr;
reg [3:0] wr_data;
reg [3:0] rd_data;
reg		  wr_en;
reg		  rd_en;
// find_worst_delay
reg [7:0] node_value [0:15];
// find lonest path
reg [3:0] longest_path [0:15];
reg       path_get;
reg [3:0] depth;
// out
reg [7:0] out_temp;
reg [3:0] path_temp;
reg 	  worst_delay_out_done;

reg go_next_node;
reg [3:0] current_node;
reg can_write_to_fifo[2:15];
reg in_fifo[2:15];

genvar i, j;
integer k;
//---------------------------------------------------------------------
//   DESIGN
//---------------------------------------------------------------------

//=====================================//
//                 FSM                 // 
//=====================================//

always @(posedge clk or negedge rst_n) begin
	if (!rst_n)
		c_state <= IDLE;
	else
		c_state <= n_state;
end

always @(*) begin
	case (c_state)
		IDLE : if (in_valid) 
			   		n_state = INPUT;
			   else
					n_state = IDLE;
		INPUT : if (!in_valid)
					n_state = READ_QUEUE;
				else
					n_state = INPUT;
		READ_QUEUE : n_state = FIND_ZERO_IN_DEGREE;

		FIND_ZERO_IN_DEGREE : if (wrt_ptr == 15)
								  n_state = FIND_WORST_DELAY;
							  else if (go_next_node)
							  	  n_state = READ_QUEUE;
							  else
							  	  n_state = FIND_ZERO_IN_DEGREE;
		
		FIND_WORST_DELAY :  if (input_count == 15)
							   n_state = FIND_LONGEST_PATH;
							else
								n_state = FIND_WORST_DELAY;
		FIND_LONGEST_PATH : if (path_get)
								n_state = OUTPUT_STATE;
							else
								n_state = FIND_LONGEST_PATH;
		OUTPUT_STATE	  : if (depth == 0)
								n_state = IDLE;
							else
								n_state = OUTPUT_STATE;
		default: n_state = IDLE;
	endcase
end
//=====================================//
//              FUNCTION               // 
//=====================================//



always @(posedge clk or negedge rst_n) begin
	if (!rst_n)
		delay_ff <= 'd0;
	else if (in_valid)
		delay_ff <= delay;
	else
		delay_ff <= 0;
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n)
		delay_input_done <= 1'b0;
	else if (c_state == IDLE)
		delay_input_done <= 'd0;
	else if ((c_state == INPUT) && (input_count == 15))
		delay_input_done <= 1'b1;
	else
		delay_input_done <= delay_input_done;
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n)
		destination_ff <= 'd0;
	else if (in_valid)
		destination_ff <= destination;
	else
		destination_ff <= 'd0;
end
always @(posedge clk or negedge rst_n) begin
	if (!rst_n)
		source_ff <= 'd0;
	else if (in_valid)
		source_ff <= source;
	else
		source_ff <= 'd0;
end
// get_delay
always @(posedge clk or negedge rst_n) begin
	if (!rst_n)
		input_count <= 0;
	else if (c_state == IDLE)
		input_count <= 0;
	else if ((c_state == INPUT) || (c_state == FIND_WORST_DELAY) || (c_state == FIND_LONGEST_PATH)) begin
		input_count <= input_count + 1;
	end
	else
		input_count <= input_count;	
end

generate
	for (i = 0; i < 16; i = i + 1) begin:input_loop
		always @(posedge clk or negedge rst_n) begin
			if (!rst_n)
				node_delay[i] <= 'd0;
			else if (c_state == IDLE)
				node_delay[i] <= 'd0;
			else if ((input_count == i) && (c_state == INPUT) && !delay_input_done)
				node_delay[i] <= delay_ff;
			else
				node_delay[i] <= node_delay[i];
		end
	end
endgenerate

generate
	for (i = 0; i < 16; i = i + 1) begin
		for (j = 0; j < 16; j = j + 1) begin
			always @(posedge clk or negedge rst_n) begin
				if (!rst_n)
					connection[i][j] <= 1'b0;
				else if (c_state == IDLE)
					connection[i][j] <= 1'b0;
				else if (c_state == INPUT) begin
					if ((source_ff == i) && (destination_ff == j))
						connection[i][j] <= 1'b1;
					else
						connection[i][j] <= connection[i][j];
				end
				else
					connection[i][j] <= connection[i][j];
			end
		end
	end
endgenerate
//=====================================//
//               UPDATE                // 
//=====================================//

// read state
always @(posedge clk or negedge rst_n) begin
	if (!rst_n)
		rd_ptr <= 0;
	else if (c_state == IDLE)
		rd_ptr <= 0;
	else if (c_state == READ_QUEUE)
		rd_ptr <= rd_ptr + 1;
	else
		rd_ptr <= rd_ptr;
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n)
		current_node <= 0;
	else if (c_state == IDLE)
		current_node <= 0;
	else if (c_state ==READ_QUEUE)
		current_node <= topo_fifo[rd_ptr];
	else 
		current_node <= current_node;
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n)
		go_next_node <= 0;
	else if (c_state == READ_QUEUE)
		go_next_node <= 0;
	else if (c_state == FIND_ZERO_IN_DEGREE) begin
		if (!can_write_to_fifo[2] && !can_write_to_fifo[3] && !can_write_to_fifo[4] && !can_write_to_fifo[5] && !can_write_to_fifo[6] && !can_write_to_fifo[7] && !can_write_to_fifo[8] && !can_write_to_fifo[9] && !can_write_to_fifo[10] && !can_write_to_fifo[11] && !can_write_to_fifo[12] && !can_write_to_fifo[13] && !can_write_to_fifo[14] && !can_write_to_fifo[15])
			go_next_node <= 1;
		else
			go_next_node <= 0;
	end
	else
		go_next_node <= 0;
end
// write state
generate
	for (i = 2; i < 16; i = i + 1) begin
		assign can_write_to_fifo[i] = connection[current_node][i] && (in_degree[i] == 0) && !in_fifo[i];
	end
endgenerate

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		for (k = 0; k < 15; k = k + 1) begin
			topo_fifo[k] <= 0;
		end
		for (k = 2; k < 16; k = k + 1) begin
			in_fifo[k] <= 0;
		end
		topo_fifo[15] <= 1;
		wrt_ptr <= 1;
	end
	else if (c_state == IDLE) begin
		for (k = 0; k < 15; k = k + 1) begin
			topo_fifo[k] <= 0;
		end
		for (k = 2; k < 16; k = k + 1) begin
			in_fifo[k] <= 0;
		end
		topo_fifo[15] <= 1;
		wrt_ptr <= 1;
	end
	else if (c_state == FIND_ZERO_IN_DEGREE) begin
		if (can_write_to_fifo[2]) begin
			topo_fifo[wrt_ptr] <= 2;
			wrt_ptr <= wrt_ptr + 1;
			in_fifo[2] <= 1;
		end
		else if (can_write_to_fifo[3]) begin
			topo_fifo[wrt_ptr] <= 3;
			wrt_ptr <= wrt_ptr + 1;
			in_fifo[3] <= 1;
		end
		else if (can_write_to_fifo[4]) begin
			topo_fifo[wrt_ptr] <= 4;
			wrt_ptr <= wrt_ptr + 1;
			in_fifo[4] <= 1;
		end
		else if (can_write_to_fifo[5]) begin
			topo_fifo[wrt_ptr] <= 5;
			wrt_ptr <= wrt_ptr + 1;
			in_fifo[5] <= 1;
		end
		else if (can_write_to_fifo[6]) begin
			topo_fifo[wrt_ptr] <= 6;
			wrt_ptr <= wrt_ptr + 1;
			in_fifo[6] <= 1;
		end
		else if (can_write_to_fifo[7]) begin
			topo_fifo[wrt_ptr] <= 7;
			wrt_ptr <= wrt_ptr + 1;
			in_fifo[7] <= 1;
		end
		else if (can_write_to_fifo[8]) begin
			topo_fifo[wrt_ptr] <= 8;
			wrt_ptr <= wrt_ptr + 1;
			in_fifo[8] <= 1;
		end
		else if (can_write_to_fifo[9]) begin
			topo_fifo[wrt_ptr] <= 9;
			wrt_ptr <= wrt_ptr + 1;
			in_fifo[9] <= 1;
		end
		else if (can_write_to_fifo[10]) begin
			topo_fifo[wrt_ptr] <= 10;
			wrt_ptr <= wrt_ptr + 1;
			in_fifo[10] <= 1;
		end
		else if (can_write_to_fifo[11]) begin
			topo_fifo[wrt_ptr] <= 11;
			wrt_ptr <= wrt_ptr + 1;
			in_fifo[11] <= 1;
		end
		else if (can_write_to_fifo[12]) begin
			topo_fifo[wrt_ptr] <= 12;
			wrt_ptr <= wrt_ptr + 1;
			in_fifo[12] <= 1;
		end
		else if (can_write_to_fifo[13]) begin
			topo_fifo[wrt_ptr] <= 13;
			wrt_ptr <= wrt_ptr + 1;
			in_fifo[13] <= 1;
		end
		else if (can_write_to_fifo[14]) begin
			topo_fifo[wrt_ptr] <= 14;
			wrt_ptr <= wrt_ptr + 1;
			in_fifo[14] <= 1;
		end
		else if (can_write_to_fifo[15]) begin
			topo_fifo[wrt_ptr] <= 15;
			wrt_ptr <= wrt_ptr + 1;
			in_fifo[15] <= 1;
		end
		else begin
			topo_fifo[wrt_ptr] <= topo_fifo[wrt_ptr];
			wrt_ptr <= wrt_ptr;
			for (k = 0; k < 16; k = k + 1) begin
				in_fifo[k] <= in_fifo[k];
			end
		end
	end
end
//=====================================//
//               UPDATE                // 
//=====================================//
//=====================================//
//            topo sorting             // 
//=====================================//
generate
    for (i = 1; i < 16; i = i + 1) begin
		always @(posedge clk or negedge rst_n) begin
			if (!rst_n)
				in_degree[i] <= 'd0;
			else if (c_state == IDLE)
				in_degree[i] <= 'd0;
			else if ((c_state == INPUT) && (destination_ff == i))
				in_degree[i] <= in_degree[i] + 'd1;
			else if ((c_state == READ_QUEUE)) begin
				if (connection[topo_fifo[rd_ptr]][i]) begin
					if (in_degree[i] == 0)
						in_degree[i] <= in_degree[i];
					else	
						in_degree[i] <= in_degree[i] - 'd1;
				end
				else
					in_degree[i] <= in_degree[i];
			end
			else
				in_degree[i] <= in_degree[i];
		end
	end
endgenerate

//=====================================//
//            worst delay              // 
//=====================================//


generate
	for (i = 0; i < 16; i = i + 1) begin
		always @(posedge clk or negedge rst_n) begin
			if (!rst_n)
				node_value[i] <= 'd0;
			else if (c_state == IDLE)
				node_value[i] <= 'd0;
			else if (c_state == FIND_WORST_DELAY) begin
				if (connection[topo_fifo[input_count]][i]) begin
					if ((node_delay[topo_fifo[input_count]] + node_value[topo_fifo[input_count]]) > node_value[i])
						node_value[i] <= node_delay[topo_fifo[input_count]] + node_value[topo_fifo[input_count]];
					else
						node_value[i] <= node_value[i];
				end
			end 
			else
				node_value[i] <= node_value[i];

		end
	end
endgenerate

//=====================================//
//             longest path            // 
//=====================================//
assign longest_path[0] = 'd1;
generate
	for (i = 2; i < 16; i = i + 1) begin
		always @(posedge clk or negedge rst_n) begin
			if (!rst_n)
				longest_path[i] <= 0;
			else if (c_state == IDLE)
				longest_path[i] <= 0;
			else if ((c_state == FIND_LONGEST_PATH) && (input_count == i - 1)) begin
				if (connection[0][longest_path[i - 1]] && (node_delay[0] == node_value[longest_path[i - 1]]))
					longest_path[i] <= 'd0;
				else if (connection[2][longest_path[i - 1]] && (node_value[2] + node_delay[2] == node_value[longest_path[i - 1]])) 
					longest_path[i] <= 'd2;
				else if (connection[3][longest_path[i - 1]] && (node_value[3] + node_delay[3] == node_value[longest_path[i - 1]]))
					longest_path[i] <= 'd3;
				else if (connection[4][longest_path[i - 1]] && (node_value[4] + node_delay[4] == node_value[longest_path[i - 1]]))
					longest_path[i] <= 'd4;
				else if (connection[5][longest_path[i - 1]] && (node_value[5] + node_delay[5] == node_value[longest_path[i - 1]]))
					longest_path[i] <= 'd5;
				else if (connection[6][longest_path[i - 1]] && (node_value[6] + node_delay[6] == node_value[longest_path[i - 1]]))
					longest_path[i] <= 'd6;
				else if (connection[7][longest_path[i - 1]] && (node_value[7] + node_delay[7] == node_value[longest_path[i - 1]]))
					longest_path[i] <= 'd7;
				else if (connection[8][longest_path[i - 1]] && (node_value[8] + node_delay[8] == node_value[longest_path[i - 1]]))
					longest_path[i] <= 'd8;
				else if (connection[9][longest_path[i - 1]] && (node_value[9] + node_delay[9] == node_value[longest_path[i - 1]]))
					longest_path[i] <= 'd9;
				else if (connection[10][longest_path[i - 1]] && (node_value[10] + node_delay[10] == node_value[longest_path[i - 1]]))
					longest_path[i] <= 'd10;
				else if (connection[11][longest_path[i - 1]] && (node_value[11] + node_delay[11] == node_value[longest_path[i - 1]]))
					longest_path[i] <= 'd11;
				else if (connection[12][longest_path[i - 1]] && (node_value[12] + node_delay[12] == node_value[longest_path[i - 1]]))
					longest_path[i] <= 'd12;
				else if (connection[13][longest_path[i - 1]] && (node_value[13] + node_delay[13] == node_value[longest_path[i - 1]]))
					longest_path[i] <= 'd13;
				else if (connection[14][longest_path[i - 1]] && (node_value[14] + node_delay[14] == node_value[longest_path[i - 1]]))
					longest_path[i] <= 'd14;
				else if (connection[15][longest_path[i - 1]] && (node_value[15] + node_delay[15] == node_value[longest_path[i - 1]]))
					longest_path[i] <= 'd15;
				else
					longest_path[i] <= longest_path[i];
			end
			else
				longest_path[i] <= longest_path[i];
		end
	end
endgenerate


always @(posedge clk or negedge rst_n) begin
	if (!rst_n)
		longest_path[1] <= 0;
	else if (c_state == IDLE)
		longest_path[1] <= 0;
	else if ((c_state == FIND_LONGEST_PATH) && (input_count == 0)) begin
		if (connection[0][1] && (node_delay[0] == node_value[1]))
			longest_path[1] <= 'd0;
		else if (connection[2][1] && (node_value[2] + node_delay[2] == node_value[1])) 
			longest_path[1] <= 'd2;
		else if (connection[3][1] && (node_value[3] + node_delay[3] == node_value[1]))
			longest_path[1] <= 'd3;
		else if (connection[4][1] && (node_value[4] + node_delay[4] == node_value[1]))
			longest_path[1] <= 'd4;
		else if (connection[5][1] && (node_value[5] + node_delay[5] == node_value[1]))
			longest_path[1] <= 'd5;
		else if (connection[6][1] && (node_value[6] + node_delay[6] == node_value[1]))
			longest_path[1] <= 'd6;
		else if (connection[7][1] && (node_value[7] + node_delay[7] == node_value[1]))
			longest_path[1] <= 'd7;
		else if (connection[8][1] && (node_value[8] + node_delay[8] == node_value[1]))
			longest_path[1] <= 'd8;
		else if (connection[9][1] && (node_value[9] + node_delay[9] == node_value[1]))
			longest_path[1] <= 'd9;
		else if (connection[10][1] && (node_value[10] + node_delay[10] == node_value[1]))
			longest_path[1] <= 'd10;
		else if (connection[11][1] && (node_value[11] + node_delay[11] == node_value[1]))
			longest_path[1] <= 'd11;
		else if (connection[12][1] && (node_value[12] + node_delay[12] == node_value[1]))
			longest_path[1] <= 'd12;
		else if (connection[13][1] && (node_value[13] + node_delay[13] == node_value[1]))
			longest_path[1] <= 'd13;
		else if (connection[14][1] && (node_value[14] + node_delay[14] == node_value[1]))
			longest_path[1] <= 'd14;
		else if (connection[15][1] && (node_value[15] + node_delay[15] == node_value[1]))
			longest_path[1] <= 'd15;
		else
			longest_path[1] <= longest_path[1];
	end
	else
		longest_path[1] <= longest_path[1];
end


always @(*) begin
	if ((c_state == FIND_LONGEST_PATH)) begin
		if (((input_count == 1) && (longest_path[1] == 0)) || ((input_count == 2) && (longest_path[2] == 0)) || ((input_count == 3) && (longest_path[3] == 0)) || ((input_count == 4) && (longest_path[4] == 0)) || ((input_count == 5) && (longest_path[5] == 0)) || ((input_count == 6) && (longest_path[6] == 0)) || ((input_count == 7) && (longest_path[7] == 0)) || ((input_count == 8) && (longest_path[8] == 0)) || ((input_count == 9) && (longest_path[9] == 0)) || ((input_count == 10) && (longest_path[10] == 0)) || ((input_count == 11) && (longest_path[11] == 0)) || ((input_count == 12) && (longest_path[12] == 0)) || ((input_count == 13) && (longest_path[13] == 0)) || ((input_count == 14) && (longest_path[14] == 0)) || ((input_count == 15) && (longest_path[15] == 0)))
			path_get <= 1'b1;
		else
			path_get <= 1'b0;
	end
	else
		path_get <= 1'b0;
end
always @(posedge clk or negedge rst_n) begin
	if (!rst_n)
		depth <= 'd0;
	else if (c_state == IDLE)
		depth <= 'd0;
	else if ((c_state == FIND_LONGEST_PATH) && path_get)
			depth <= input_count;
	else if (c_state == OUTPUT_STATE) begin
		if (depth == 0)
			depth <= depth;
		else
			depth <= depth - 1;
	end
	else
		depth <= depth; 
end
// output

always @(posedge clk or negedge rst_n) begin
	if (!rst_n)
		worst_delay_out_done <= 1'b0;
	else if (c_state == IDLE)
		worst_delay_out_done <= 1'b0;
	else if (c_state == OUTPUT_STATE)
		worst_delay_out_done <= 1'b1;
	else
		worst_delay_out_done <= worst_delay_out_done;
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n)
		out_valid <= 1'b0;
	else if (c_state == IDLE)
		out_valid <= 1'b0;
	else if (c_state == OUTPUT_STATE)
		out_valid <= 1'b1;
	else 
		out_valid <= 1'b0; 
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n)
		path <= 'd0;
	else if (c_state == OUTPUT_STATE)
		path <= longest_path[depth];
	else
		path <= 'd0;
end


always @(posedge clk or negedge rst_n) begin
	if (!rst_n)
		worst_delay <= 'd0;
	else if (c_state == OUTPUT_STATE && !worst_delay_out_done)
		worst_delay <= node_value[1] + node_delay[1];
	else
		worst_delay <= 'd0;

end

endmodule