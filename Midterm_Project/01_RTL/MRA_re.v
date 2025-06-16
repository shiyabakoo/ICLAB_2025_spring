//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Si2 LAB @NYCU ED430
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2021 Fall
//   Midterm Proejct            : MRA  
//   Author                     : Lin-Hung, Lai
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : MRA.v
//   Module Name : MRA
//   Release version : V1.0 (Release Date: 2021-10)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module MRA(
	// CHIP IO
	clk            	,	
	rst_n          	,	
	in_valid       	,	
	frame_id        ,	
	net_id         	,	  
	loc_x          	,	  
    loc_y         	,
	cost	 		,		
	busy         	,

    // AXI4 IO
	     arid_m_inf,
	   araddr_m_inf,
	    arlen_m_inf,
	   arsize_m_inf,
	  arburst_m_inf,
	  arvalid_m_inf,
	  arready_m_inf,
	
	      rid_m_inf,
	    rdata_m_inf,
	    rresp_m_inf,
	    rlast_m_inf,
	   rvalid_m_inf,
	   rready_m_inf,
	
	     awid_m_inf,
	   awaddr_m_inf,
	   awsize_m_inf,
	  awburst_m_inf,
	    awlen_m_inf,
	  awvalid_m_inf,
	  awready_m_inf,
	
	    wdata_m_inf,
	    wlast_m_inf,
	   wvalid_m_inf,
	   wready_m_inf,
	
	      bid_m_inf,
	    bresp_m_inf,
	   bvalid_m_inf,
	   bready_m_inf 
);
// ===============================================================
//  					Parameter Declaration 
// ===============================================================
parameter ID_WIDTH=4, DATA_WIDTH=128, ADDR_WIDTH=32;    // DO NOT modify AXI4 Parameter
parameter NUM_ROW = 64, NUM_COLUMN = 64; 				
parameter MAX_NUM_MACRO = 15;


// ===============================================================
//  					Input / Output 
// ===============================================================

// << CHIP io port with system >>
input 			  	clk, rst_n;
input 			   	in_valid;
input  [4:0] 		frame_id;
input  [3:0]       	net_id;     
input  [5:0]       	loc_x; 
input  [5:0]       	loc_y; 
output reg [13:0] 	cost;
output reg          busy;       
  
// AXI Interface wire connecttion for pseudo DRAM read/write
/* Hint:
       Your AXI-4 interface could be designed as a bridge in submodule,
	   therefore I declared output of AXI as wire.  
	   Ex: AXI4_interface AXI4_INF(...);
*/

// ------------------------
// <<<<< AXI READ >>>>>
// ------------------------
// (1)	axi read address channel 
output wire [ID_WIDTH-1:0]      arid_m_inf;  //all wire
output wire [1:0]            arburst_m_inf;
output wire [2:0]             arsize_m_inf;
output wire [7:0]              arlen_m_inf; //128
output reg                   arvalid_m_inf; //
input  wire                  arready_m_inf; //
output wire [ADDR_WIDTH-1:0]  araddr_m_inf; //32'h00010000 + (frame_id_reg * 12'h800)
// ------------------------
// (2)	axi read data channel 
input  wire [ID_WIDTH-1:0]       rid_m_inf;
input  wire                   rvalid_m_inf; //
output reg                   rready_m_inf; //
input  wire [DATA_WIDTH-1:0]   rdata_m_inf;
input  wire                    rlast_m_inf;
input  wire [1:0]              rresp_m_inf;
// ------------------------
// <<<<< AXI WRITE >>>>>
// ------------------------
// (1) 	axi write address channel 
output wire [ID_WIDTH-1:0]      awid_m_inf;
output wire [1:0]            awburst_m_inf;
output wire [2:0]             awsize_m_inf;
output wire [7:0]              awlen_m_inf;
output reg                  awvalid_m_inf;
input  wire                  awready_m_inf;
output wire [ADDR_WIDTH-1:0]  awaddr_m_inf;
// -------------------------
// (2)	axi write data channel 
output reg                   wvalid_m_inf;
input  wire                   wready_m_inf;
output reg [DATA_WIDTH-1:0]   wdata_m_inf;
output reg                    wlast_m_inf;
// -------------------------
// (3)	axi write response channel 
input  wire  [ID_WIDTH-1:0]      bid_m_inf;
input  wire                   bvalid_m_inf;
output reg                    bready_m_inf;
input  wire  [1:0]             bresp_m_inf;
// -----------------------------

// << Burst & ID >>
assign arid_m_inf = 4'd0; 			// fixed id to 0 
assign arburst_m_inf = 2'd1;		// fixed mode to INCR mode 
assign arsize_m_inf = 3'b100;		// fixed size to 2^4 = 16 Bytes 
assign awid_m_inf = 4'd0;
assign awburst_m_inf = 2'd1;
assign awsize_m_inf = 3'b100;
assign arlen_m_inf = 8'd127;
assign awlen_m_inf = 8'd127;

// ===============================================================
//  					Variable Declare
// ===============================================================
/* MAIN STATE */
reg [3:0] state, next_state;
localparam IDLE = 4'd0;
localparam AXI_SEND_R = 4'd1;
localparam CATCH_WEIGHT = 4'd2;
localparam CATCH_DATA = 4'd3;
localparam OPERATION_INITIALIZATION = 4'd4;
localparam OPERATION_PROPAGATION = 4'd5;
localparam OPERATION_RETRACE_READ = 4'd6;
localparam OPERATION_RETRACE_WRITE = 4'd7;
localparam OPERATION_TMP = 4'd8;
localparam WRITE_BACK_DRAM = 4'd9;
localparam WRITE_BACK_DRAM2 = 4'd10;
localparam WRITE_BACK_END = 4'd11;
localparam OPERATION_CLEAR = 4'd12;

/* INPUT */
reg [4:0] cnt;
wire [3:0] index = cnt[4:1];
reg [3:0] net_id_buf[0:14];
reg [5:0] source_x_buf[0:14];
reg [5:0] source_y_buf[0:14];
reg [5:0] sink_x_buf[0:14];
reg [5:0] sink_y_buf[0:14];
reg [4:0] frame_id_buf;

/* OPERATION */
reg [1:0] Location_Map[0:63][0:63];
reg [6:0] cur_addr;
reg [5:0] cur_x, cur_y, nxt_x, nxt_y;
reg [3:0] weight, weight_tmp;
reg [3:0] cur_net_index;
reg weight_ready;
reg [1:0] cur_flag_counter, cur_flag;

wire [5:0] map_y = cur_addr[6:1];
wire [5:0] offset = (!cur_addr[0]) ? 6'd0 : 6'd32;
wire [5:0] cur_source_x = source_x_buf[cur_net_index];
wire [5:0] cur_source_y = source_y_buf[cur_net_index];
wire [5:0] cur_sink_x = sink_x_buf[cur_net_index];
wire [5:0] cur_sink_y = sink_y_buf[cur_net_index];
wire [5:0] cur_net_id = net_id_buf[cur_net_index];
wire [5:0] cur_y_add1 = cur_y + 6'd1;
wire [5:0] cur_y_sub1 = cur_y - 6'd1;
wire [5:0] cur_x_add1 = cur_x + 6'd1;
wire [5:0] cur_x_sub1 = cur_x - 6'd1;
wire sram_seq_x_add1 = (cur_x_add1[5]) ? 1 : 0;
wire sram_seq_x_sub1 = (cur_x_sub1[5]) ? 1 : 0;
wire sram_seq_x = (cur_x[5]) ? 1 : 0;
wire [3:0] weight_or_data = (!weight_ready) ? 4'b0010 : 4'b0001;
reg [7:0] frame_id_offset;

always@(*) begin
	case(frame_id_buf)
		5'd0: frame_id_offset = 8'h00;
		5'd1: frame_id_offset = 8'h08;
		5'd2: frame_id_offset = 8'h10;
		5'd3: frame_id_offset = 8'h18;
		5'd4: frame_id_offset = 8'h20;
		5'd5: frame_id_offset = 8'h28;
		5'd6: frame_id_offset = 8'h30;
		5'd7: frame_id_offset = 8'h38;
		5'd8: frame_id_offset = 8'h40;
		5'd9: frame_id_offset = 8'h48;
		5'd10: frame_id_offset = 8'h50;
		5'd11: frame_id_offset = 8'h58;
		5'd12: frame_id_offset = 8'h60;
		5'd13: frame_id_offset = 8'h68;
		5'd14: frame_id_offset = 8'h70;
		5'd15: frame_id_offset = 8'h78;
		5'd16: frame_id_offset = 8'h80;
		5'd17: frame_id_offset = 8'h88;
		5'd18: frame_id_offset = 8'h90;
		5'd19: frame_id_offset = 8'h98;
		5'd20: frame_id_offset = 8'hA0;
		5'd21: frame_id_offset = 8'hA8;
		5'd22: frame_id_offset = 8'hB0;
		5'd23: frame_id_offset = 8'hB8;
		5'd24: frame_id_offset = 8'hC0;
		5'd25: frame_id_offset = 8'hC8;
		5'd26: frame_id_offset = 8'hD0;
		5'd27: frame_id_offset = 8'hD8;
		5'd28: frame_id_offset = 8'hE0;
		5'd29: frame_id_offset = 8'hE8;
		5'd30: frame_id_offset = 8'hF0;
		5'd31: frame_id_offset = 8'hF8;
	endcase
end

assign araddr_m_inf = {12'd0, weight_or_data, frame_id_offset, 8'd0};
assign awaddr_m_inf = {12'd0, 4'b0001, frame_id_offset, 8'd0};

reg [127:0] data_reg;

reg [5:0] replace_point;
reg [6:0] rp;
reg [127:0] dataline;

/* SRAM */
reg [DATA_WIDTH-1:0] data_in;
wire [DATA_WIDTH-1:0] data_in_w;
wire [DATA_WIDTH-1:0] data_out, data_out_w;
reg [6:0] addr, addr_w;
reg wen, wen_w;
RA1SH128 U_SRAM(.Q(data_out),.CLK(clk),.CEN(1'b0),.WEN(wen),.A(addr),.D(data_in),.OEN(1'b0));
RA1SH128 W_SRAM(.Q(data_out_w),.CLK(clk),.CEN(1'b0),.WEN(wen_w),.A(addr_w),.D(data_in_w),.OEN(1'b0));

integer i, j, n, k, l;
// ===============================================================
//  					Finite State Machine
// ===============================================================

/* AXI4 Read transaction */
always@(*) begin
	case(state)
		AXI_SEND_R: begin
			arvalid_m_inf = 1;
			rready_m_inf = 1;
		end
		CATCH_DATA, CATCH_WEIGHT: begin
			arvalid_m_inf = 0;
			rready_m_inf = 1;
		end
		default: begin
			arvalid_m_inf = 0;
			rready_m_inf = 0;
		end
	endcase
end

/* AXI4 WRITE transaction */
always@(*) begin
	case(state)
		WRITE_BACK_DRAM: begin
			awvalid_m_inf = 1;
			wvalid_m_inf = 0;
			wdata_m_inf = 128'd0;
			bready_m_inf = 0;
			wlast_m_inf = 0;
		end
		WRITE_BACK_DRAM2: begin
			awvalid_m_inf = 0;
			wvalid_m_inf = 1;
			bready_m_inf = 1;
			wdata_m_inf = data_out;
			if(cur_addr==7'd127) wlast_m_inf = 1;
			else wlast_m_inf = 0;
		end
		WRITE_BACK_END: begin
			wvalid_m_inf = 0;
			awvalid_m_inf = 0;
			bready_m_inf = 1;
			wdata_m_inf = 128'd0;
			wlast_m_inf = 0;
		end
		default: begin
			wlast_m_inf = 0;
			awvalid_m_inf = 0;
			wvalid_m_inf = 0;
			wdata_m_inf = 128'd0;
			bready_m_inf = 0;
		end
	endcase
end

/* INPUT */
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		cnt <= 5'd0;
		frame_id_buf <= 0;
		for(n=0;n<15;n=n+1) net_id_buf[n] <= 'd0;
	end
	else begin
		if(in_valid) begin
			frame_id_buf <= frame_id;
			if(cnt[0]==0) begin
				net_id_buf[index] <= net_id;
				source_x_buf[index] <= loc_x;
				source_y_buf[index] <= loc_y;
			end
			else begin
				sink_x_buf[index] <= loc_x;
				sink_y_buf[index] <= loc_y;
			end
		end
		
		if(in_valid) cnt <= cnt + 5'd1;
		else if(state == WRITE_BACK_END) cnt <= 5'd0; 
	end
end

/* Busy Signal */
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) busy <= 0;
	else begin
		if(in_valid || (state == IDLE && !weight_ready))  busy <= 0;
		else busy <= 1;
	end
end

/* propagation controller */
always@(*) begin
	case(cur_flag_counter)
		2'd0: cur_flag = 2'd2;
		2'd1: cur_flag = 2'd2;
		2'd2: cur_flag = 2'd3;
		2'd3: cur_flag = 2'd3;
	endcase
end

/* data SRAM addr controller */
always@(*) begin
	addr = cur_addr;
	case(state) 
		OPERATION_RETRACE_READ, OPERATION_RETRACE_WRITE: begin
			if(Location_Map[cur_y+6'd1][cur_x] == cur_flag && cur_y != 6'd63) addr = {cur_y_add1, sram_seq_x};
			else if(Location_Map[cur_y-6'd1][cur_x] == cur_flag && cur_y != 6'd0) addr = {cur_y_sub1, sram_seq_x};
			else if(Location_Map[cur_y][cur_x+6'd1] == cur_flag && cur_x != 6'd63) addr = {cur_y, sram_seq_x_add1};
			else addr = {cur_y, sram_seq_x_sub1};
		end
		WRITE_BACK_DRAM2: if(wready_m_inf) addr = cur_addr + 7'd1;
	endcase
end

/* data SRAM wen controller */
always@(*) begin
	wen = 1;
	case(state)
		CATCH_DATA: if(rvalid_m_inf) wen = 0; 
		OPERATION_RETRACE_WRITE: wen = 0;
	endcase	
end

/* data SRAM writing data controller */
always@(*) begin
	case(state)
		OPERATION_RETRACE_WRITE: begin
			data_in = data_out;
			data_in[rp+7'd3] = cur_net_id[3];
			data_in[rp+7'd2] = cur_net_id[2];
			data_in[rp+7'd1] = cur_net_id[1];
			data_in[rp] = cur_net_id[0];
		end
		default: data_in = rdata_m_inf;
	endcase	
end

/* weight SRAM data_in_w controller */
assign data_in_w = rdata_m_inf;

/* weight SRAM addr controller */
always@(*) begin
	case(state) 
		OPERATION_RETRACE_READ: begin
			if(Location_Map[cur_y+6'd1][cur_x] == cur_flag && cur_y != 6'd63) addr_w = {cur_y_add1, sram_seq_x};
			else if(Location_Map[cur_y-6'd1][cur_x] == cur_flag && cur_y != 6'd0) addr_w = {cur_y_sub1, sram_seq_x};
			else if(Location_Map[cur_y][cur_x+6'd1] == cur_flag && cur_x != 6'd63) addr_w = {cur_y, sram_seq_x_add1};
			else addr_w = {cur_y, sram_seq_x_sub1};
		end
		default: addr_w = cur_addr; //CATCH_WEIGHT
	endcase
end

/* weight SRAM wen_w controller */
always@(*) begin
	wen_w = 1;
	case(state)
		CATCH_WEIGHT: if(rvalid_m_inf) wen_w = 0; 
	endcase	
end

/* weight SRAM output data controller */
always@(*) begin
	weight[3] = data_out_w[rp+7'd3];
	weight[2] = data_out_w[rp+7'd2];
	weight[1] = data_out_w[rp+7'd1];
	weight[0] = data_out_w[rp];
end

/* data replacement */
always@(*) begin
	case(state) 
		OPERATION_RETRACE_WRITE: begin
			if(Location_Map[cur_y+6'd1][cur_x] == cur_flag && cur_y != 6'd63) replace_point = cur_x;
			else if(Location_Map[cur_y-6'd1][cur_x] == cur_flag && cur_y != 6'd0) replace_point = cur_x;
			else if(Location_Map[cur_y][cur_x+6'd1] == cur_flag && cur_x != 6'd63) replace_point = cur_x + 6'd1;
			else replace_point = cur_x - 6'd1;
		end
		default: replace_point = cur_x;
	endcase
	rp = {replace_point[4:0], 2'd0};
end


/* next retrace step */
always@(*) begin
	nxt_x = cur_x;
	nxt_y = cur_y;
	if(Location_Map[cur_y+6'd1][cur_x] == cur_flag && cur_y != 6'd63) nxt_y = cur_y + 6'd1;
	else if(Location_Map[cur_y-6'd1][cur_x] == cur_flag && cur_y != 6'd0) nxt_y = cur_y - 6'd1;
	else if(Location_Map[cur_y][cur_x+6'd1] == cur_flag && cur_x != 6'd63) nxt_x = cur_x + 6'd1;
	else nxt_x = cur_x - 6'd1;
end

/* State Controller */
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) state <= IDLE;
	else state <= next_state;
end

/* state combinational */
always@(*) begin
	next_state = state;
	case(state)
		IDLE: if(in_valid || weight_ready) next_state = AXI_SEND_R;
		AXI_SEND_R: begin
			if(arready_m_inf) begin
				if(weight_ready) next_state = CATCH_DATA;
				else next_state = CATCH_WEIGHT;
			end
		end
		CATCH_WEIGHT: if(rvalid_m_inf && cur_addr == 7'd127) next_state = IDLE;
		CATCH_DATA: if(rvalid_m_inf && cur_addr == 7'd127) next_state = OPERATION_INITIALIZATION;
		OPERATION_INITIALIZATION: next_state = OPERATION_PROPAGATION;
		OPERATION_PROPAGATION: if(Location_Map[cur_sink_y][cur_sink_x] != 0) next_state = OPERATION_RETRACE_READ;
		OPERATION_RETRACE_READ: next_state = OPERATION_RETRACE_WRITE;
		OPERATION_RETRACE_WRITE: begin
			if(nxt_x == cur_source_x && nxt_y == cur_source_y) next_state = OPERATION_TMP;
			else next_state = OPERATION_RETRACE_READ;
		end
		OPERATION_TMP: begin
			if((cur_net_index+4'd1)==index) next_state = WRITE_BACK_DRAM; //index
			else next_state = OPERATION_CLEAR;
		end
		OPERATION_CLEAR: next_state = OPERATION_INITIALIZATION;
		WRITE_BACK_DRAM: if(awready_m_inf) next_state = WRITE_BACK_DRAM2;
		WRITE_BACK_DRAM2: if(wready_m_inf && cur_addr==7'd127) next_state = WRITE_BACK_END;
		WRITE_BACK_END: if(bvalid_m_inf) next_state = IDLE;	
	endcase
end

/* Propagation */
always@(posedge clk) begin
	case(state)
		CATCH_DATA: begin
			if(rvalid_m_inf) begin
				Location_Map[map_y][offset] <= (rdata_m_inf[3:0] != 4'd0) ? 2'd1 : 2'd0;
				Location_Map[map_y][offset+6'd1] <= (rdata_m_inf[7:4] != 4'd0) ? 2'd1 : 2'd0;    
				Location_Map[map_y][offset+6'd2] <= (rdata_m_inf[11:8] != 4'd0) ? 2'd1 : 2'd0;  
				Location_Map[map_y][offset+6'd3] <= (rdata_m_inf[15:12] != 4'd0) ? 2'd1 : 2'd0;
				Location_Map[map_y][offset+6'd4] <= (rdata_m_inf[19:16] != 4'd0) ? 2'd1 : 2'd0;
				Location_Map[map_y][offset+6'd5] <= (rdata_m_inf[23:20] != 4'd0) ? 2'd1 : 2'd0;
				Location_Map[map_y][offset+6'd6] <= (rdata_m_inf[27:24] != 4'd0) ? 2'd1 : 2'd0;
				Location_Map[map_y][offset+6'd7] <= (rdata_m_inf[31:28] != 4'd0) ? 2'd1 : 2'd0;
				Location_Map[map_y][offset+6'd8] <= (rdata_m_inf[35:32] != 4'd0) ? 2'd1 : 2'd0;
				Location_Map[map_y][offset+6'd9] <= (rdata_m_inf[39:36] != 4'd0) ? 2'd1 : 2'd0;
				Location_Map[map_y][offset+6'd10] <= (rdata_m_inf[43:40] != 4'd0) ? 2'd1 : 2'd0;
				Location_Map[map_y][offset+6'd11] <= (rdata_m_inf[47:44] != 4'd0) ? 2'd1 : 2'd0;
				Location_Map[map_y][offset+6'd12] <= (rdata_m_inf[51:48] != 4'd0) ? 2'd1 : 2'd0;
				Location_Map[map_y][offset+6'd13] <= (rdata_m_inf[55:52] != 4'd0) ? 2'd1 : 2'd0;
				Location_Map[map_y][offset+6'd14] <= (rdata_m_inf[59:56] != 4'd0) ? 2'd1 : 2'd0;
				Location_Map[map_y][offset+6'd15] <= (rdata_m_inf[63:60] != 4'd0) ? 2'd1 : 2'd0;
				Location_Map[map_y][offset+6'd16] <= (rdata_m_inf[67:64] != 4'd0) ? 2'd1 : 2'd0;
				Location_Map[map_y][offset+6'd17] <= (rdata_m_inf[71:68] != 4'd0) ? 2'd1 : 2'd0;
				Location_Map[map_y][offset+6'd18] <= (rdata_m_inf[75:72] != 4'd0) ? 2'd1 : 2'd0;
				Location_Map[map_y][offset+6'd19] <= (rdata_m_inf[79:76] != 4'd0) ? 2'd1 : 2'd0;
				Location_Map[map_y][offset+6'd20] <= (rdata_m_inf[83:80] != 4'd0) ? 2'd1 : 2'd0;
				Location_Map[map_y][offset+6'd21] <= (rdata_m_inf[87:84] != 4'd0) ? 2'd1 : 2'd0;
				Location_Map[map_y][offset+6'd22] <= (rdata_m_inf[91:88] != 4'd0) ? 2'd1 : 2'd0;
				Location_Map[map_y][offset+6'd23] <= (rdata_m_inf[95:92] != 4'd0) ? 2'd1 : 2'd0;
				Location_Map[map_y][offset+6'd24] <= (rdata_m_inf[99:96] != 4'd0) ? 2'd1 : 2'd0;
				Location_Map[map_y][offset+6'd25] <= (rdata_m_inf[103:100] != 4'd0) ? 2'd1 : 2'd0;
				Location_Map[map_y][offset+6'd26] <= (rdata_m_inf[107:104] != 4'd0) ? 2'd1 : 2'd0;
				Location_Map[map_y][offset+6'd27] <= (rdata_m_inf[111:108] != 4'd0) ? 2'd1 : 2'd0;
				Location_Map[map_y][offset+6'd28] <= (rdata_m_inf[115:112] != 4'd0) ? 2'd1 : 2'd0;
				Location_Map[map_y][offset+6'd29] <= (rdata_m_inf[119:116] != 4'd0) ? 2'd1 : 2'd0;
				Location_Map[map_y][offset+6'd30] <= (rdata_m_inf[123:120] != 4'd0) ? 2'd1 : 2'd0;
				Location_Map[map_y][offset+6'd31] <= (rdata_m_inf[127:124] != 4'd0) ? 2'd1 : 2'd0;
			end	
		end
		OPERATION_PROPAGATION, OPERATION_CLEAR: begin
			for(i=0;i<64;i=i+1) begin
				for(j=0;j<64;j=j+1) begin
					if(i==0&&j==0) begin //upper-left corner
						if(Location_Map[0][0][1]) begin
							if(state==OPERATION_PROPAGATION) begin
								if(Location_Map[0][1] == 2'd0) Location_Map[0][1] <= cur_flag; 
								if(Location_Map[1][0] == 2'd0) Location_Map[1][0] <= cur_flag; 
							end
							else Location_Map[0][0] <= 2'd0;
						end
					end
					else if(i==0&&j==63) begin //upper-right corner
						if(Location_Map[0][63][1]) begin
							if(state==OPERATION_PROPAGATION) begin
								if(Location_Map[0][62] == 2'd0) Location_Map[0][62] <= cur_flag; 
								if(Location_Map[1][63] == 2'd0) Location_Map[1][63] <= cur_flag; 
							end
							else Location_Map[i][j] <= 2'd0;
						end
					end
					else if(j==0&&i==63) begin //bottom-left corner
						if(Location_Map[63][0][1]) begin
							if(state==OPERATION_PROPAGATION) begin
								if(Location_Map[62][0] == 2'd0) Location_Map[62][0] <= cur_flag; 
								if(Location_Map[63][1] == 2'd0) Location_Map[63][1] <= cur_flag; 
							end
							else Location_Map[i][j] <= 2'd0;
						end
					end
					else if(i==63&&j==63) begin //bottom-right corner
						if(Location_Map[63][63][1]) begin
							if(state==OPERATION_PROPAGATION) begin
								if(Location_Map[62][63] == 2'd0) Location_Map[62][63] <= cur_flag; 
								if(Location_Map[63][62] == 2'd0) Location_Map[63][62] <= cur_flag; 
							end
							else Location_Map[i][j] <= 2'd0;
						end
					end
					else if(i==0) begin //upper bar
						if(Location_Map[0][j][1]) begin
							if(state==OPERATION_PROPAGATION) begin
								if(Location_Map[0][j+1] == 2'd0) Location_Map[0][j+1] <= cur_flag; 
								if(Location_Map[0][j-1] == 2'd0) Location_Map[0][j-1] <= cur_flag; 
								if(Location_Map[1][j] == 2'd0) Location_Map[1][j] <= cur_flag; 
							end
							else Location_Map[i][j] <= 2'd0;
						end
					end
					else if(i==63) begin //bottom bar
						if(Location_Map[63][j][1]) begin
							if(state==OPERATION_PROPAGATION) begin
								if(Location_Map[63][j+1] == 2'd0) Location_Map[63][j+1] <= cur_flag; 
								if(Location_Map[63][j-1] == 2'd0) Location_Map[63][j-1] <= cur_flag; 
								if(Location_Map[62][j] == 2'd0) Location_Map[62][j] <= cur_flag; 
							end
							else Location_Map[i][j] <= 2'd0;
						end
					end
					else if(j==0) begin //left bar
						if(Location_Map[i][0][1]) begin
							if(state==OPERATION_PROPAGATION) begin
								if(Location_Map[i+1][0] == 2'd0) Location_Map[i+1][0] <= cur_flag;
								if(Location_Map[i-1][0] == 2'd0) Location_Map[i-1][0] <= cur_flag;
								if(Location_Map[i][1] == 2'd0) Location_Map[i][1] <= cur_flag;	
							end
							else Location_Map[i][j] <= 2'd0;
						end
					end
					else if(j==63) begin //right bar
						if(Location_Map[i][63][1]) begin
							if(state==OPERATION_PROPAGATION) begin
								if(Location_Map[i+1][63] == 2'd0) Location_Map[i+1][63] <= cur_flag;
								if(Location_Map[i-1][63] == 2'd0) Location_Map[i-1][63] <= cur_flag;
								if(Location_Map[i][62] == 2'd0) Location_Map[i][62] <= cur_flag;
							end
							else Location_Map[i][j] <= 2'd0;
						end
					end
					else begin	//center
						if(Location_Map[i][j][1]) begin
							if(state==OPERATION_PROPAGATION) begin
								if(Location_Map[i+1][j] == 2'd0) Location_Map[i+1][j] <= cur_flag;
								if(Location_Map[i-1][j] == 2'd0) Location_Map[i-1][j] <= cur_flag;
								if(Location_Map[i][j+1] == 2'd0) Location_Map[i][j+1] <= cur_flag;
								if(Location_Map[i][j-1] == 2'd0) Location_Map[i][j-1] <= cur_flag;
							end
							else Location_Map[i][j] <= 2'd0; //clear map
						end
					end
				end
			end
		end
		OPERATION_INITIALIZATION: begin
			Location_Map[cur_source_y][cur_source_x] <= 2'd2;
			Location_Map[cur_sink_y][cur_sink_x] <= 2'd0;
		end
		OPERATION_RETRACE_WRITE, OPERATION_TMP: Location_Map[cur_y][cur_x] <= 2'd1;
	endcase
end



always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		cost <= 14'd0;
		cur_addr <= 7'd0;
		cur_flag_counter <= 2'd0;
		cur_net_index <= 4'd0;
		weight_ready <= 0;
		cur_x <= 6'd0;
		cur_y <= 6'd0;
	end
	else begin
		case(state)
			CATCH_DATA: if(rvalid_m_inf) cur_addr <= cur_addr + 7'd1;
		
			CATCH_WEIGHT: begin
				cost <= 14'd0;
				if(rvalid_m_inf) begin
					cur_addr <= cur_addr + 7'd1;
					if(cur_addr == 7'd127) weight_ready <= 1;
				end
			end
			
			OPERATION_INITIALIZATION: begin
				weight_tmp <= 4'd0;
				cur_flag_counter <= 2'd1;
				cur_x <= cur_sink_x;
				cur_y <= cur_sink_y;
			end
			
			OPERATION_PROPAGATION: begin	
				if(Location_Map[cur_sink_y][cur_sink_x][1]) cur_flag_counter <= cur_flag_counter - 2'd2; //end retrace
				else cur_flag_counter <= cur_flag_counter + 2'd1;
			end
			
			OPERATION_RETRACE_READ: cost <= cost + weight_tmp;
			
			OPERATION_RETRACE_WRITE: begin
				cur_y <= nxt_y;
				cur_x <= nxt_x;
				cur_flag_counter <= cur_flag_counter - 2'd1;	
				weight_tmp <= weight;
			end
			
			OPERATION_TMP: cur_net_index <= cur_net_index + 4'd1;

			WRITE_BACK_DRAM2: if(wready_m_inf) cur_addr <= cur_addr + 7'd1;
			
			WRITE_BACK_END: begin
				cur_net_index <= 4'd0; 
				weight_ready <= 0;
			end
			
		endcase
	end
end


endmodule
