//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2021 Final Project: Customized ISA Processor 
//   Author              : Hsi-Hao Huang
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : CPU.v
//   Module Name : CPU.v
//   Release version : V1.0 (Release Date: 2021-May)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
module CPU(

				clk,
			  rst_n,
  
		   IO_stall,

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
       bready_m_inf,
                    
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
       rready_m_inf 

);
// Input port
input  wire clk, rst_n;
// Output port
output reg  IO_stall;

parameter ID_WIDTH = 4 , ADDR_WIDTH = 32, DATA_WIDTH = 16, DRAM_NUMBER=2, WRIT_NUMBER=1;

// AXI Interface wire connecttion for pseudo DRAM read/write
/* Hint:
  your AXI-4 interface could be designed as convertor in submodule(which used reg for output signal),
  therefore I declared output of AXI as wire in CPU
*/



// axi write address channel 
output  wire [WRIT_NUMBER * ID_WIDTH-1:0]        awid_m_inf;
output  wire [WRIT_NUMBER * ADDR_WIDTH-1:0]    awaddr_m_inf;
output  wire [WRIT_NUMBER * 3 -1:0]            awsize_m_inf;
output  wire [WRIT_NUMBER * 2 -1:0]           awburst_m_inf;
output  wire [WRIT_NUMBER * 7 -1:0]             awlen_m_inf;
output  wire [WRIT_NUMBER-1:0]                awvalid_m_inf;
input   wire [WRIT_NUMBER-1:0]                awready_m_inf;
// axi write data channel 
output  wire [WRIT_NUMBER * DATA_WIDTH-1:0]     wdata_m_inf;
output  wire [WRIT_NUMBER-1:0]                  wlast_m_inf;
output  wire [WRIT_NUMBER-1:0]                 wvalid_m_inf;
input   wire [WRIT_NUMBER-1:0]                 wready_m_inf;
// axi write response channel
input   wire [WRIT_NUMBER * ID_WIDTH-1:0]         bid_m_inf;
input   wire [WRIT_NUMBER * 2 -1:0]             bresp_m_inf;
input   wire [WRIT_NUMBER-1:0]             	   bvalid_m_inf;
output  wire [WRIT_NUMBER-1:0]                 bready_m_inf;
// -----------------------------
// axi read address channel 
output  wire [DRAM_NUMBER * ID_WIDTH-1:0]       arid_m_inf;
output  wire [DRAM_NUMBER * ADDR_WIDTH-1:0]   araddr_m_inf;
output  wire [DRAM_NUMBER * 7 -1:0]            arlen_m_inf;
output  wire [DRAM_NUMBER * 3 -1:0]           arsize_m_inf;
output  wire [DRAM_NUMBER * 2 -1:0]          arburst_m_inf;
output  wire [DRAM_NUMBER-1:0]               arvalid_m_inf;
input   wire [DRAM_NUMBER-1:0]               arready_m_inf;
// -----------------------------
// axi read data channel 
input   wire [DRAM_NUMBER * ID_WIDTH-1:0]         rid_m_inf;
input   wire [DRAM_NUMBER * DATA_WIDTH-1:0]     rdata_m_inf;
input   wire [DRAM_NUMBER * 2 -1:0]             rresp_m_inf;
input   wire [DRAM_NUMBER-1:0]                  rlast_m_inf;
input   wire [DRAM_NUMBER-1:0]                 rvalid_m_inf;
output  wire [DRAM_NUMBER-1:0]                 rready_m_inf;
// -----------------------------


//
//
// 
/* Register in each core:
  There are sixteen registers in your CPU. You should not change the name of those registers.
  TA will check the value in each register when your core is not busy.
  If you change the name of registers below, you must get the fail in this lab.
*/

reg signed [15:0] core_r0 , core_r1 , core_r2 , core_r3 ;
reg signed [15:0] core_r4 , core_r5 , core_r6 , core_r7 ;
reg signed [15:0] core_r8 , core_r9 , core_r10, core_r11;
reg signed [15:0] core_r12, core_r13, core_r14, core_r15;


//###########################################
//
// Wrtie down your design below
//
//###########################################

//####################################################
//               reg & wire
//####################################################
reg          [3:0]     c_state, n_state;
reg                    init_inst_done, init_data_done, inst_hit, branch_jump, data_hit, dirty;
reg          [3:0]     IO_stall_cnt;
wire                   next_inst;

reg          [7:0]     cache_addr;
reg  signed  [15:0]    cache_data_out, cache_data_in, cache_data_out_ff;
reg                    cache_WEB;
wire                   wen_inst, wen_data;
wire signed  [15:0]    cache_data_in_inst, cache_data_in_data;
wire         [6:0]     cache_addr_inst, cache_addr_data;

reg  signed  [10:0]   pc;
reg                   fetch_dram_inst, fetch_dram_data, write_data;
reg          [3:0]    fetch_tag_inst, fetch_tag_data, cache_tag_inst,  cache_tag_data;

reg          [15:0]   instruction;
wire         [2:0]    opcode;
wire         [3:0]    rs, rt, rd;
wire signed  [4:0]    imm;
wire         [12:0]   Address;
wire                  func, branch, jump, branch_taken;
reg  signed  [15:0]   rs_data, rt_data;
reg  signed  [15:0]   rs_data_ff, rt_data_ff;
reg  signed  [15:0]   alu_out, add_res, sub_res, slt_res, mult_res, i_type_res;
reg          [11:0]   load_store_addr;
// FSM
localparam IF_STAGE        = 4'd0,
           WAIT_INST       = 4'd1,
           ID_STAGE        = 4'd2,
           EXE_STAGE       = 4'd3,
           LOAD_STAGE      = 4'd4,
           STORE_STAGE     = 4'd5,
           WAIT_DATA       = 4'd6,
           WAIT_MUL        = 4'd7,
           WB_STAGE        = 4'd8;
//===================================
//            CACHE(256 x 16)
//===================================
always @(*) begin
  if (c_state == IF_STAGE) begin
    if (inst_hit)
      cache_addr = pc[6:0];
    else
      cache_addr = cache_addr_inst;
  end
  else if ((c_state == LOAD_STAGE) ) begin
    if (data_hit)
      cache_addr = {1'b1, load_store_addr[7:1]};
    else
      cache_addr = {1'b1, cache_addr_data};
  end
  else
    cache_addr = {1'b1, cache_addr_data};
end

always @(*) begin
  if (c_state == IF_STAGE) begin
    cache_WEB = wen_inst;
  end
  else if (c_state == ID_STAGE)
    cache_WEB = 1;
  else if (c_state == EXE_STAGE)
    cache_WEB = 1;
  else begin
    cache_WEB = wen_data;
  end
end 


always @(*) begin
  if (c_state == IF_STAGE) begin 
    cache_data_in = cache_data_in_inst; 
  end
  else if (c_state == ID_STAGE)
    cache_data_in = 0; 
  else if (c_state == EXE_STAGE)
    cache_data_in = 0;
  else begin
    cache_data_in = cache_data_in_data;
  end
end

always @(posedge clk) begin
  cache_data_out_ff <= cache_data_out;
end

SUMA180_256X16 L1_cache(
    .A0(cache_addr[0]), .A1(cache_addr[1]), .A2(cache_addr[2]), .A3(cache_addr[3]), .A4(cache_addr[4]), .A5(cache_addr[5]),
    .A6(cache_addr[6]), .A7(cache_addr[7]),
    .DO0(cache_data_out[0]), .DO1(cache_data_out[1]), .DO2(cache_data_out[2]), .DO3(cache_data_out[3]), .DO4(cache_data_out[4]), .DO5(cache_data_out[5]),
    .DO6(cache_data_out[6]), .DO7(cache_data_out[7]), .DO8(cache_data_out[8]), .DO9(cache_data_out[9]), .DO10(cache_data_out[10]), .DO11(cache_data_out[11]),
    .DO12(cache_data_out[12]), .DO13(cache_data_out[13]), .DO14(cache_data_out[14]), .DO15(cache_data_out[15]),
    .DI0(cache_data_in[0]), .DI1(cache_data_in[1]), .DI2(cache_data_in[2]), .DI3(cache_data_in[3]), .DI4(cache_data_in[4]), .DI5(cache_data_in[5]),
    .DI6(cache_data_in[6]), .DI7(cache_data_in[7]), .DI8(cache_data_in[8]), .DI9(cache_data_in[9]), .DI10(cache_data_in[10]), .DI11(cache_data_in[11]),
    .DI12(cache_data_in[12]), .DI13(cache_data_in[13]), .DI14(cache_data_in[14]), .DI15(cache_data_in[15]),
    .CK(clk), .WEB(cache_WEB), .OE(1'b1), .CS(1'b1));
//===================================
//           DRAM interface
//===================================
always @(*) begin
  if ((c_state == IF_STAGE) && !inst_hit)
    fetch_dram_inst = 1;
  else
    fetch_dram_inst = 0; 
end
always @(*) begin
  if ((c_state == LOAD_STAGE) && !data_hit)
    fetch_dram_data = 1;
  else
    fetch_dram_data = 0;
end

assign fetch_tag_inst = pc[10:7];


always @(*) begin
  if (c_state == STORE_STAGE)
    write_data = 1;
  else
    write_data = 0;
end
DATA_DRAM_CONTROLLER DATA_INF(.clk(clk), .rst_n(rst_n), .fetch_data(fetch_dram_data), .write_data(write_data), .cache_tag(cache_tag_data), .store_addr(load_store_addr), .data_hit(data_hit), .rt_data(rt_data_ff),
                              .awid_m_inf(awid_m_inf), .awaddr_m_inf(awaddr_m_inf), .awsize_m_inf(awsize_m_inf), .awburst_m_inf(awburst_m_inf), .awlen_m_inf(awlen_m_inf), .awvalid_m_inf(awvalid_m_inf), .awready_m_inf(awready_m_inf),
                              .wdata_m_inf(wdata_m_inf), .wlast_m_inf(wlast_m_inf), .wvalid_m_inf(wvalid_m_inf), .wready_m_inf(wready_m_inf),
                              .bresp_m_inf(bresp_m_inf), .bvalid_m_inf(bvalid_m_inf), .bready_m_inf(bready_m_inf),
                              .arid_m_inf(arid_m_inf[3:0]), .araddr_m_inf(araddr_m_inf[31:0]), .arlen_m_inf(arlen_m_inf[6:0]), .arsize_m_inf(arsize_m_inf[2:0]), .arburst_m_inf(arburst_m_inf[1:0]), .arvalid_m_inf(arvalid_m_inf[0]),
                              .arready_m_inf(arready_m_inf[0]), .rid_m_inf(rid_m_inf[3:0]), .rdata_m_inf(rdata_m_inf[15:0]), .rresp_m_inf(rresp_m_inf[1:0]), .rlast_m_inf(rlast_m_inf[0]), .rvalid_m_inf(rvalid_m_inf[0]), .rready_m_inf(rready_m_inf[0]),
                              .wen(wen_data), .cache_data_in(cache_data_in_data), .cache_addr(cache_addr_data));

INST_DRAM_CONTROLLER INST_INF(.clk(clk), .rst_n(rst_n), .fetch_dram(fetch_dram_inst), .fetch_tag(fetch_tag_inst), .cache_tag(cache_tag_inst), 
                              .arid_m_inf(arid_m_inf[7:4]), .araddr_m_inf(araddr_m_inf[63:32]), .arlen_m_inf(arlen_m_inf[13:7]), .arsize_m_inf(arsize_m_inf[5:3]), .arburst_m_inf(arburst_m_inf[3:2]), .arvalid_m_inf(arvalid_m_inf[1]),
                              .arready_m_inf(arready_m_inf[1]), .rid_m_inf(rid_m_inf[7:4]), .rdata_m_inf(rdata_m_inf[31:16]), .rresp_m_inf(rresp_m_inf[3:2]), .rlast_m_inf(rlast_m_inf[1]), .rvalid_m_inf(rvalid_m_inf[1]), .rready_m_inf(rready_m_inf[1]),
                              .wen(wen_inst), .cache_data_in(cache_data_in_inst), .cache_addr(cache_addr_inst));

//===================================
//             MAIN FSM
//===================================

always @(posedge clk or negedge rst_n) begin
  if (!rst_n) 
    c_state <= IF_STAGE;
  else
    c_state <= n_state;
end

always @(*) begin
  case (c_state)
    IF_STAGE: begin
      if (inst_hit)
          n_state = WAIT_INST;
      else
          n_state = IF_STAGE;
    end
    WAIT_INST: begin
      n_state = ID_STAGE;
    end
    ID_STAGE: begin
      if (branch_jump)
        n_state = IF_STAGE;
      else
        n_state = EXE_STAGE;
    end
    EXE_STAGE: begin
      if (opcode[1]) begin
        if (opcode[0])
          n_state = STORE_STAGE;
        else
          n_state = LOAD_STAGE;
      end
      else begin
        if (opcode[0] && instruction[0])
          n_state = WAIT_MUL;
        else
          n_state = IF_STAGE;
      end
       
    end
    LOAD_STAGE: begin
      if (data_hit)
          n_state = WAIT_DATA;
      else 
          n_state = LOAD_STAGE;
    end
    STORE_STAGE: begin
      if (bvalid_m_inf)
          n_state = IF_STAGE;
      else  
          n_state = STORE_STAGE;  
    end
    WAIT_DATA: begin
      n_state = WB_STAGE;
    end
    WB_STAGE: begin
      n_state = IF_STAGE;
    end
    WAIT_MUL: begin
      n_state = IF_STAGE;
    end
    default: n_state = IF_STAGE;
  endcase
end

//----------------------------------------------------
//               IF STAGE
//----------------------------------------------------
assign next_inst = (c_state != IF_STAGE) && (n_state == IF_STAGE);
// assign inst_hit = (pc[10:7] == cache_tag_inst);
assign inst_hit = !(pc[10:7] ^ cache_tag_inst);
always @(posedge clk or negedge rst_n) begin
  if (!rst_n)
    pc <= 0;
  else if ((c_state == ID_STAGE) && (branch_jump)) begin
    if (branch_taken)
      pc <= pc + 1 + imm;
    else if (jump)
      pc <= Address[11:1];
    else
      pc <= pc + 1;
  end
  else if (next_inst)
    pc <= pc + 1;
  else
    pc <= pc;
end


// save intruction-----------------------------------------------------
always @(posedge clk or negedge rst_n) begin
  if (!rst_n)
    instruction <= 0;
  else if (c_state == WAIT_INST)
    instruction <= cache_data_out;
  else 
    instruction <= instruction;
end
//----------------------------------------------------
//               ID STAGE
//----------------------------------------------------
assign opcode = instruction[15:13];
assign rs = instruction[12:9];
assign rt = instruction[8:5];
assign rd = instruction[4:1];
assign func = instruction[0];
assign imm = instruction[4:0];
assign Address = instruction[12:0];
assign branch = (opcode == 3'b100);
assign jump = (opcode[2] & opcode[0]);
assign branch_jump = branch | jump;
assign branch_taken = !(rs_data ^ rt_data) && branch;

always @(*) begin
    case (rs)
      0:  rs_data <= core_r0;
      1:  rs_data <= core_r1;
      2:  rs_data <= core_r2;
      3:  rs_data <= core_r3;
      4:  rs_data <= core_r4;
      5:  rs_data <= core_r5;
      6:  rs_data <= core_r6;
      7:  rs_data <= core_r7;
      8:  rs_data <= core_r8;
      9:  rs_data <= core_r9;
      10: rs_data <= core_r10;
      11: rs_data <= core_r11;
      12: rs_data <= core_r12;
      13: rs_data <= core_r13;
      14: rs_data <= core_r14;
      15: rs_data <= core_r15;
      default: rs_data <= rs_data;
    endcase
end

always @(*) begin
    case (rt)
      0:  rt_data <= core_r0;
      1:  rt_data <= core_r1;
      2:  rt_data <= core_r2;
      3:  rt_data <= core_r3;
      4:  rt_data <= core_r4;
      5:  rt_data <= core_r5;
      6:  rt_data <= core_r6;
      7:  rt_data <= core_r7;
      8:  rt_data <= core_r8;
      9:  rt_data <= core_r9;
      10: rt_data <= core_r10;
      11: rt_data <= core_r11;
      12: rt_data <= core_r12;
      13: rt_data <= core_r13;
      14: rt_data <= core_r14;
      15: rt_data <= core_r15;
      default: rt_data <= rt_data;
    endcase
end
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    rs_data_ff <= 0;
    rt_data_ff <= 0;
  end
  else begin
    rs_data_ff <= rs_data;
    rt_data_ff <= rt_data;
  end
end
//----------------------------------------------------
//                 EXE STAGE
//----------------------------------------------------

// ALU------------------------------------------------
assign add_res = rs_data_ff + rt_data_ff;
assign sub_res = rs_data_ff - rt_data_ff;
assign slt_res = sub_res[15];
assign mult_res = rs_data_ff * rt_data_ff;
assign i_type_res = (rs_data_ff + imm) << 1;

wire signed [31:0] mul_res;
DW02_mult_2_stage #(16, 16)
U1 ( .A(rs_data_ff), .B(rt_data_ff), .TC(1'd1), .CLK(clk), .PRODUCT(mul_res) );

always @(*) begin
  if (opcode[1]) begin // I type
    alu_out = i_type_res;
  end
  else if (opcode[0]) begin // slt & mult
    alu_out = slt_res; 
    // if (func)
    //   alu_out = mult_res;
    // else
    //   alu_out = slt_res;
  end
  else begin // add & sub
    if (func)
      alu_out = sub_res;
    else
      alu_out = add_res;
  end
end

//----------------------------------------------------
//                 MEM STAGE
//----------------------------------------------------
// assign data_hit = (load_store_addr[11:8] == cache_tag_data); 
assign data_hit = !(load_store_addr[11:8] ^ cache_tag_data); 
always @(posedge clk or negedge rst_n) begin
  if (!rst_n)
    load_store_addr <= 0;
  else if (c_state == EXE_STAGE)
    load_store_addr <= alu_out[11:0];
  else
    load_store_addr <= load_store_addr; 
end

//----------------------------------------------------
//                 IO STALL
//----------------------------------------------------
always @(posedge clk or negedge rst_n) begin
  if (!rst_n)
    IO_stall <= 1;
  else if (next_inst) 
    IO_stall <= 0;
  else 
    IO_stall <= 1; 
end
//----------------------------------------------------
//               Register File
//----------------------------------------------------
// core_r0
always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		core_r0 <= 0;
  else if (c_state == WAIT_MUL && (rd == 0))
    core_r0 <= mul_res[15:0];
  else if ((c_state == EXE_STAGE) && (rd == 0) && (!opcode[1]))
    core_r0 <= alu_out;
  // else if (c_state == WAIT_DATA && (rt == 0))
  //   core_r0 <= cache_data_out;
  else if (c_state == WB_STAGE && (rt == 0))
    core_r0 <= cache_data_out_ff;
  else
		core_r0 <= core_r0;
end

// core_r1
always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		core_r1 <= 0;
  else if (c_state == WAIT_MUL && (rd == 1))
    core_r1 <= mul_res[15:0];
  else if ((c_state == EXE_STAGE) && (rd == 1) && (!opcode[1]))
    core_r1 <= alu_out;
  // else if (c_state == WAIT_DATA && (rt == 1))
  //   core_r1 <= cache_data_out;
  else if (c_state == WB_STAGE && (rt == 1))
    core_r1 <= cache_data_out_ff;
  else
		core_r1 <= core_r1;
end

// core_r2
always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		core_r2 <= 0;
  else if (c_state == WAIT_MUL && (rd == 2))
    core_r2 <= mul_res[15:0];
  else if ((c_state == EXE_STAGE) && (rd == 2) && (!opcode[1]))
    core_r2 <= alu_out;
  else if (c_state == WAIT_DATA && (rt == 2))
    core_r2 <= cache_data_out;
  else if (c_state == WB_STAGE && (rt == 2))
    core_r2 <= cache_data_out_ff;
  else
		core_r2 <= core_r2;
end

// core_r3
always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		core_r3 <= 0;
  else if (c_state == WAIT_MUL && (rd == 3))
    core_r3 <= mul_res[15:0];
  else if ((c_state == EXE_STAGE) && (rd == 3) && (!opcode[1]))
    core_r3 <= alu_out;
  // else if (c_state == WAIT_DATA && (rt == 3))
  //   core_r3 <= cache_data_out;
  else if (c_state == WB_STAGE && (rt == 3))
    core_r3 <= cache_data_out_ff;
  else
		core_r3 <= core_r3;
end

// core_r4
always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		core_r4 <= 0;
  else if (c_state == WAIT_MUL && (rd == 4))
    core_r4 <= mul_res[15:0];
  else if ((c_state == EXE_STAGE) && (rd == 4) && (!opcode[1]))
    core_r4 <= alu_out;
  // else if (c_state == WAIT_DATA && (rt == 4))
  //   core_r4 <= cache_data_out;
  else if (c_state == WB_STAGE && (rt == 4))
    core_r4 <= cache_data_out_ff;
  else
		core_r4 <= core_r4;
end

// core_r5
always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		core_r5 <= 0;
  else if (c_state == WAIT_MUL && (rd == 5) )
    core_r5 <= mul_res[15:0];
  else if ((c_state == EXE_STAGE) && (rd == 5) && (!opcode[1]))
    core_r5 <= alu_out;
  // else if (c_state == WAIT_DATA && (rt == 5))
  //   core_r5 <= cache_data_out;
  else if (c_state == WB_STAGE && (rt == 5))
    core_r5 <= cache_data_out_ff;
  else
		core_r5 <= core_r5;
end

// core_r6
always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		core_r6 <= 0;
  else if (c_state == WAIT_MUL && (rd == 6))
    core_r6 <= mul_res[15:0];
  else if ((c_state == EXE_STAGE) && (rd == 6) && (!opcode[1]))
    core_r6 <= alu_out;
  // else if (c_state == WAIT_DATA && (rt == 6))
  //   core_r6 <= cache_data_out;
  else if (c_state == WB_STAGE && (rt == 6))
    core_r6 <= cache_data_out_ff;
  else
		core_r6 <= core_r6;
end

// core_r7
always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		core_r7 <= 0;
  else if (c_state == WAIT_MUL && (rd == 7))
    core_r7 <= mul_res[15:0];
  else if ((c_state == EXE_STAGE) && (rd == 7) && (!opcode[1]))
    core_r7 <= alu_out;
  // else if (c_state == WAIT_DATA && (rt == 7))
  //   core_r7 <= cache_data_out;
  else if (c_state == WB_STAGE && (rt == 7))
    core_r7 <= cache_data_out_ff;
  else
		core_r7 <= core_r7;
end

// core_r8
always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		core_r8 <= 0;
  else if (c_state == WAIT_MUL && (rd == 8))
    core_r8 <= mul_res[15:0];
  else if ((c_state == EXE_STAGE) && (rd == 8) && (!opcode[1]))
    core_r8 <= alu_out;
  // else if (c_state == WAIT_DATA && (rt == 8))
  //   core_r8 <= cache_data_out;
  else if (c_state == WB_STAGE && (rt == 8))
    core_r8 <= cache_data_out_ff;
  else
		core_r8 <= core_r8;
end

// core_r9
always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		core_r9 <= 0;
  else if (c_state == WAIT_MUL && (rd == 9))
    core_r9 <= mul_res[15:0];
  else if ((c_state == EXE_STAGE) && (rd == 9) && (!opcode[1]))
    core_r9 <= alu_out;
  // else if (c_state == WAIT_DATA && (rt == 9))
  //   core_r9 <= cache_data_out;
  else if (c_state == WB_STAGE && (rt == 9))
    core_r9 <= cache_data_out_ff;
  else
		core_r9 <= core_r9;
end

// core_r10
always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		core_r10 <= 0;
  else if (c_state == WAIT_MUL && (rd == 10))
    core_r10 <= mul_res[15:0];
  else if ((c_state == EXE_STAGE) && (rd == 10) && (!opcode[1]))
    core_r10 <= alu_out;
  // else if (c_state == WAIT_DATA && (rt == 10))
  //   core_r10 <= cache_data_out;
  else if (c_state == WB_STAGE && (rt == 10))
    core_r10 <= cache_data_out_ff;
  else
		core_r10 <= core_r10;
end

// core_r11
always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		core_r11 <= 0;
  else if (c_state == WAIT_MUL && (rd == 11))
    core_r11 <= mul_res[15:0];
  else if ((c_state == EXE_STAGE) && (rd == 11) && (!opcode[1]))
    core_r11 <= alu_out;
  // else if (c_state == WAIT_DATA && (rt == 11))
  //   core_r11 <= cache_data_out;
  else if (c_state == WB_STAGE && (rt == 11))
    core_r11 <= cache_data_out_ff;
  else
		core_r11 <= core_r11;
end

// core_r12
always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		core_r12 <= 0;
  else if (c_state == WAIT_MUL && (rd == 12))
    core_r12 <= mul_res[15:0];
  else if ((c_state == EXE_STAGE) && (rd == 12) && (!opcode[1]))
    core_r12 <= alu_out;
  // else if (c_state == WAIT_DATA && (rt == 12))
  //   core_r12 <= cache_data_out;
  else if (c_state == WB_STAGE && (rt == 12))
    core_r12 <= cache_data_out_ff;
  else
		core_r12 <= core_r12;
end

// core_r13
always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		core_r13 <= 0;
  else if (c_state == WAIT_MUL && (rd == 13))
    core_r13 <= mul_res[15:0];
  else if ((c_state == EXE_STAGE) && (rd == 13) && (!opcode[1]))
    core_r13 <= alu_out;
  // else if (c_state == WAIT_DATA && (rt == 13))
  //   core_r13 <= cache_data_out;
  else if (c_state == WB_STAGE && (rt == 13))
    core_r13 <= cache_data_out_ff;
  else
		core_r13 <= core_r13;
end

// core_r14
always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		core_r14 <= 0;
  else if (c_state == WAIT_MUL && (rd == 14))
    core_r14 <= mul_res[15:0];
  else if ((c_state == EXE_STAGE) && (rd == 14) && (!opcode[1]))
    core_r14 <= alu_out;
  // else if (c_state == WAIT_DATA && (rt == 14))
  //   core_r14 <= cache_data_out;
  else if (c_state == WB_STAGE && (rt == 14))
    core_r14 <= cache_data_out_ff;
  else
		core_r14 <= core_r14;
end

// core_r15
always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		core_r15 <= 0;
  else if (c_state == WAIT_MUL && (rd == 15))
    core_r15 <= mul_res[15:0];
  else if ((c_state == EXE_STAGE) && (rd == 15) && (!opcode[1]))
    core_r15 <= alu_out;
  // else if (c_state == WAIT_DATA && (rt == 15))
  //   core_r15 <= cache_data_out;
   else if (c_state == WB_STAGE && (rt == 15))
    core_r15 <= cache_data_out_ff;
  else
		core_r15 <= core_r15;
end


endmodule



//===================================
//           INST DRAM FSM
//===================================
module INST_DRAM_CONTROLLER(
    input               clk,
    input               rst_n,
    input               fetch_dram,
    input       [3:0]   fetch_tag, // fetch address -> {1, tag_addr, 8'b0}
    output  reg [3:0]   cache_tag,

    output  reg [3:0]   arid_m_inf,
    output  reg [31:0]  araddr_m_inf,
    output  reg [6:0]   arlen_m_inf,
    output  reg [2:0]   arsize_m_inf,
    output  reg [1:0]   arburst_m_inf,
    output  reg         arvalid_m_inf,
                
    input               arready_m_inf, 
    output  reg [3:0]   rid_m_inf,
    input       [15:0]  rdata_m_inf,
    input       [1:0]   rresp_m_inf,
    input               rlast_m_inf, 
    input               rvalid_m_inf,
    output  reg         rready_m_inf, 

    // sram part
    output reg         wen,
    output reg  [15:0] cache_data_in,
    output reg  [6:0]  cache_addr
);

localparam IDLE       = 2'd0,
           SEND_ADDR  = 2'd1,
           SAVE_DATA  = 2'd2,
           UPDATE_TAG = 2'd3;
reg [1:0] c_state, n_state;

assign arid_m_inf = 0;
assign arlen_m_inf = 'd127;
assign arsize_m_inf = 3'b001;
assign arburst_m_inf = 2'b01;
assign rid_m_inf = 0;

always @(posedge clk or negedge rst_n) begin
  if (!rst_n)
    c_state <= IDLE;
  else 
    c_state <= n_state;
end

always @(*) begin
  case (c_state)
    IDLE: begin
      if (fetch_dram)
        n_state = SEND_ADDR;
      else
        n_state = IDLE;
    end  
    SEND_ADDR: begin
      if (arready_m_inf)
        n_state = SAVE_DATA;
      else
        n_state = SEND_ADDR;
    end
    SAVE_DATA: begin
      if (rlast_m_inf)
        n_state = IDLE;
      else 
        n_state = SAVE_DATA;
    end
    default: n_state = IDLE;
  endcase
end

always @(*) begin
  if (c_state == SEND_ADDR)
    arvalid_m_inf = 1;
  else
    arvalid_m_inf = 0;
end

always @(*) begin
  if (c_state == SEND_ADDR)
    araddr_m_inf = {19'b0, 1'b1, fetch_tag, 8'b0};
  else  
    araddr_m_inf = 0;
end

always @(*) begin
  if (c_state == SAVE_DATA)
    rready_m_inf = 1;
  else
    rready_m_inf = 0;
end

always @(posedge clk or negedge rst_n) begin
  if (!rst_n)
    cache_addr <= 0;
  else if (rvalid_m_inf)
    cache_addr <= cache_addr + 1;
  else
    cache_addr <= cache_addr; 
end

always @(*) begin
  wen = !rvalid_m_inf;
end

always @(*) begin
  if (rvalid_m_inf)
    cache_data_in = rdata_m_inf;
  else
    cache_data_in = 0;  
end

always @(posedge clk or negedge rst_n) begin
  if (!rst_n)
    cache_tag <= 1;
  else if (rlast_m_inf)
    cache_tag <= fetch_tag;
  else
    cache_tag <= cache_tag;
end

endmodule
            
//===================================
//           DATA DRAM FSM
//===================================

module DATA_DRAM_CONTROLLER(
    input               clk,
    input               rst_n,
    input               data_hit,
    input               fetch_data,
    input               write_data,
    input       [11:0]  store_addr, // fetch address -> {1, tag_addr, 8'b0}
    output  reg [3:0]   cache_tag,
    input       [15:0]  rt_data,

    output  reg [3:0]   awid_m_inf,
    output  reg [31:0]  awaddr_m_inf,
    output  reg [2:0]   awsize_m_inf,
    output  reg [1:0]   awburst_m_inf,
    output  reg [6:0]   awlen_m_inf,
    output  reg         awvalid_m_inf,
    input               awready_m_inf,
                    
    output  reg [15:0]  wdata_m_inf,
    output  reg         wlast_m_inf,
    output  reg         wvalid_m_inf,
    input               wready_m_inf,
                    
    input   [1:0]       bresp_m_inf,
    input               bvalid_m_inf,
    output reg          bready_m_inf,

    output  reg [3:0]   arid_m_inf,
    output  reg [31:0]  araddr_m_inf,
    output  reg [6:0]   arlen_m_inf,
    output  reg [2:0]   arsize_m_inf,
    output  reg [1:0]   arburst_m_inf,
    output  reg         arvalid_m_inf,
                
    input               arready_m_inf, 
    output  reg [3:0]   rid_m_inf,
    input       [15:0]  rdata_m_inf,
    input       [1:0]   rresp_m_inf,
    input               rlast_m_inf, 
    input               rvalid_m_inf,
    output reg          rready_m_inf, 

    // sram part
    output reg           wen,
    output reg  [15:0]   cache_data_in,
    output reg  [6:0]    cache_addr
);

localparam IDLE        = 3'd0,
           SEND_ARADDR = 3'd1,
           SAVE_DATA   = 3'd2,
           SEND_AWADDR = 3'd3,
           WRITE_DATA  = 3'd4,
           WAIT_RESP   = 3'd5;

reg [3:0] c_state, n_state;
reg [6:0] addr_cnt;
reg       wready_ff;
assign arid_m_inf = 0;
assign arlen_m_inf = 'd127;
assign arsize_m_inf = 3'b001;
assign arburst_m_inf = 2'b01;
assign rid_m_inf = 0;

assign awid_m_inf = 0;
assign awlen_m_inf = 'd0;
assign awsize_m_inf = 3'b001;
assign awburst_m_inf = 2'b01;

always @(posedge clk or negedge rst_n) begin
  if (!rst_n)
    c_state <= IDLE;
  else 
    c_state <= n_state;
end

always @(*) begin
  case (c_state)
    IDLE: begin
      if (write_data) 
        n_state = SEND_AWADDR;
      else if (fetch_data)
        n_state = SEND_ARADDR;
      else
        n_state = IDLE;
    end  
    SEND_ARADDR: begin
      if (arready_m_inf)
        n_state = SAVE_DATA;
      else
        n_state = SEND_ARADDR;
    end
    SAVE_DATA: begin
      if (rlast_m_inf)
        n_state = IDLE;
      else 
        n_state = SAVE_DATA;
    end
    SEND_AWADDR: begin
      if (awready_m_inf)
        n_state = WRITE_DATA;
      else
        n_state = SEND_AWADDR;
    end
    WRITE_DATA: begin
      if (wready_m_inf)
        n_state = WAIT_RESP;
      else
        n_state = WRITE_DATA;
    end
    WAIT_RESP: begin
      if (bvalid_m_inf)
          n_state = IDLE;
      else
        n_state = WAIT_RESP;
    end
    default: n_state = IDLE;
  endcase
end

//read part------------------------------------------------
always @(*) begin
  if (c_state == SEND_ARADDR)
    arvalid_m_inf = 1;
  else
    arvalid_m_inf = 0;
end

always @(*) begin
  if (c_state == SEND_ARADDR)
    araddr_m_inf = {19'b0, 1'b1, store_addr[11:8], 8'b0};
  else  
    araddr_m_inf = 0;
end

always @(*) begin
  if (c_state == SAVE_DATA)
    rready_m_inf = 1;
  else
    rready_m_inf = 0;
end

always @(*) begin
  if (c_state == SAVE_DATA)
    wen = 0;
  else if (c_state == WRITE_DATA) begin
    if (data_hit)
      wen = 0;
    else
     wen = 1;
  end
  else
    wen = 1;

end

always @(*) begin
  if (rvalid_m_inf)
    cache_data_in = rdata_m_inf;
  else if (c_state == WRITE_DATA)
    cache_data_in = rt_data;
  else
    cache_data_in = 0;  
end

always @(posedge clk or negedge rst_n) begin
  if (!rst_n)
    cache_tag <= 1;
  else if (rlast_m_inf)
    cache_tag <= store_addr[11:8];
  else
    cache_tag <= cache_tag;
end
// write part--------------------------------------------
always @(*) begin
  if (c_state == SEND_AWADDR) begin
    awvalid_m_inf = 1;
    awaddr_m_inf = {19'b0, 1'b1, store_addr};
  end
  else begin
    awvalid_m_inf = 0;
    awaddr_m_inf = 0;
  end
end
always @(*) begin
  if (c_state == WRITE_DATA)
    wvalid_m_inf = 1;
  else
    wvalid_m_inf = 0;
end
always @(*) begin 
    wdata_m_inf = rt_data;
end
always @(*) begin
  if (c_state == WRITE_DATA)
    wlast_m_inf = 1;
  else
    wlast_m_inf = 0;
end
always @(*) begin
  if (c_state == WAIT_RESP)
    bready_m_inf = 1;
  else
    bready_m_inf = 0;
end
// cache addr count-------------------------------------
always @(*) begin
  if (c_state == SAVE_DATA)
    cache_addr = addr_cnt;
  else
    cache_addr = {1'b1, store_addr[7:1]};
end

always @(posedge clk or negedge rst_n) begin
  if (!rst_n)
    addr_cnt <= 0;
  else if (rvalid_m_inf)
    addr_cnt <= addr_cnt + 1;
  else
    addr_cnt <= addr_cnt;
end
endmodule











// //############################################################################
// //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// //   (C) Copyright Laboratory System Integration and Silicon Implementation
// //   All Right Reserved
// //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// //
// //   ICLAB 2021 Final Project: Customized ISA Processor 
// //   Author              : Hsi-Hao Huang
// //
// //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// //
// //   File Name   : CPU.v
// //   Module Name : CPU.v
// //   Release version : V1.0 (Release Date: 2021-May)
// //
// //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// //############################################################################

// module CPU(

// 				clk,
// 			  rst_n,
  
// 		   IO_stall,

//          awid_m_inf,
//        awaddr_m_inf,
//        awsize_m_inf,
//       awburst_m_inf,
//         awlen_m_inf,
//       awvalid_m_inf,
//       awready_m_inf,
                    
//         wdata_m_inf,
//         wlast_m_inf,
//        wvalid_m_inf,
//        wready_m_inf,
                    
//           bid_m_inf,
//         bresp_m_inf,
//        bvalid_m_inf,
//        bready_m_inf,
                    
//          arid_m_inf,
//        araddr_m_inf,
//         arlen_m_inf,
//        arsize_m_inf,
//       arburst_m_inf,
//       arvalid_m_inf,
                    
//       arready_m_inf, 
//           rid_m_inf,
//         rdata_m_inf,
//         rresp_m_inf,
//         rlast_m_inf, 
//        rvalid_m_inf,
//        rready_m_inf 

// );
// // Input port
// input  wire clk, rst_n;
// // Output port
// output reg  IO_stall;

// parameter ID_WIDTH = 4 , ADDR_WIDTH = 32, DATA_WIDTH = 16, DRAM_NUMBER=2, WRIT_NUMBER=1;

// // AXI Interface wire connecttion for pseudo DRAM read/write
// /* Hint:
//   your AXI-4 interface could be designed as convertor in submodule(which used reg for output signal),
//   therefore I declared output of AXI as wire in CPU
// */



// // axi write address channel 
// output  wire [WRIT_NUMBER * ID_WIDTH-1:0]        awid_m_inf;
// output  wire [WRIT_NUMBER * ADDR_WIDTH-1:0]    awaddr_m_inf;
// output  wire [WRIT_NUMBER * 3 -1:0]            awsize_m_inf;
// output  wire [WRIT_NUMBER * 2 -1:0]           awburst_m_inf;
// output  wire [WRIT_NUMBER * 7 -1:0]             awlen_m_inf;
// output  wire [WRIT_NUMBER-1:0]                awvalid_m_inf;
// input   wire [WRIT_NUMBER-1:0]                awready_m_inf;
// // axi write data channel 
// output  wire [WRIT_NUMBER * DATA_WIDTH-1:0]     wdata_m_inf;
// output  wire [WRIT_NUMBER-1:0]                  wlast_m_inf;
// output  wire [WRIT_NUMBER-1:0]                 wvalid_m_inf;
// input   wire [WRIT_NUMBER-1:0]                 wready_m_inf;
// // axi write response channel
// input   wire [WRIT_NUMBER * ID_WIDTH-1:0]         bid_m_inf;
// input   wire [WRIT_NUMBER * 2 -1:0]             bresp_m_inf;
// input   wire [WRIT_NUMBER-1:0]             	   bvalid_m_inf;
// output  wire [WRIT_NUMBER-1:0]                 bready_m_inf;
// // -----------------------------
// // axi read address channel 
// output  wire [DRAM_NUMBER * ID_WIDTH-1:0]       arid_m_inf;
// output  wire [DRAM_NUMBER * ADDR_WIDTH-1:0]   araddr_m_inf;
// output  wire [DRAM_NUMBER * 7 -1:0]            arlen_m_inf;
// output  wire [DRAM_NUMBER * 3 -1:0]           arsize_m_inf;
// output  wire [DRAM_NUMBER * 2 -1:0]          arburst_m_inf;
// output  wire [DRAM_NUMBER-1:0]               arvalid_m_inf;
// input   wire [DRAM_NUMBER-1:0]               arready_m_inf;
// // -----------------------------
// // axi read data channel 
// input   wire [DRAM_NUMBER * ID_WIDTH-1:0]         rid_m_inf;
// input   wire [DRAM_NUMBER * DATA_WIDTH-1:0]     rdata_m_inf;
// input   wire [DRAM_NUMBER * 2 -1:0]             rresp_m_inf;
// input   wire [DRAM_NUMBER-1:0]                  rlast_m_inf;
// input   wire [DRAM_NUMBER-1:0]                 rvalid_m_inf;
// output  wire [DRAM_NUMBER-1:0]                 rready_m_inf;
// // -----------------------------


// //
// //
// // 
// /* Register in each core:
//   There are sixteen registers in your CPU. You should not change the name of those registers.
//   TA will check the value in each register when your core is not busy.
//   If you change the name of registers below, you must get the fail in this lab.
// */

// reg signed [15:0] core_r0 , core_r1 , core_r2 , core_r3 ;
// reg signed [15:0] core_r4 , core_r5 , core_r6 , core_r7 ;
// reg signed [15:0] core_r8 , core_r9 , core_r10, core_r11;
// reg signed [15:0] core_r12, core_r13, core_r14, core_r15;


// //###########################################
// //
// // Wrtie down your design below
// //
// //###########################################

// //####################################################
// //               reg & wire
// //####################################################
// reg          [2:0]     c_state, n_state;
// wire                   inst_hit, branch_jump, data_hit;
// reg          [3:0]     IO_stall_cnt;

// reg          [7:0]     cache_addr;
// reg          [15:0]    cache_data_in;
// wire         [15:0]    cache_data_out;
// reg                    cache_WEB;
// wire                   wen_inst, wen_data;
// wire         [15:0]    cache_data_in_inst, cache_data_in_data;
// wire         [6:0]     cache_addr_inst, cache_addr_data;

// reg  signed  [10:0]   pc;
// reg                   fetch_dram_inst, fetch_dram_data, write_data;
// reg          [3:0]    cache_tag_data;
// reg          [3:0]    cache_tag_inst;
// reg          [15:0]   instruction;
// wire         [2:0]    opcode;
// wire         [3:0]    rs, rt, rd;
// wire signed  [4:0]    imm;
// wire         [12:0]   Address;
// wire                  func, branch, jump, branch_taken;
// reg  signed  [15:0]   rs_data, rt_data;
// reg  signed  [15:0]   rs_data_ff, rt_data_ff;
// reg  signed  [15:0]   alu_out, add_res, sub_res, slt_res, mult_res, i_type_res;
// reg          [11:0]   load_store_addr;
// // FSM
// localparam IF_STAGE        = 3'd0,
//            WAIT_INST       = 3'd1,
//            ID_STAGE        = 3'd2,
//            EXE_STAGE       = 3'd3,
//            LOAD_STAGE      = 3'd4,
//            STORE_STAGE     = 3'd5,
//            WAIT_DATA       = 3'd6,
//            WB_STAGE        = 3'd7;
// //===================================
// //            CACHE(256 x 16)
// //===================================
// always @(*) begin
//   if (c_state == IF_STAGE) begin
//     if (inst_hit)
//       cache_addr = pc[6:0];
//     else
//       cache_addr = cache_addr_inst;
//   end
//   else if ((c_state == LOAD_STAGE) ) begin
//     if (data_hit)
//       cache_addr = {1'b1, load_store_addr[7:1]};
//     else
//       cache_addr = {1'b1, cache_addr_data};
//   end
//   else
//     cache_addr = {1'b1, cache_addr_data};
// end

// always @(*) begin
//   if (c_state == IF_STAGE) begin
//     cache_WEB = wen_inst;
//   end
//   else begin
//     cache_WEB = wen_data;
//   end
// end


// always @(*) begin
//   if (c_state == IF_STAGE) begin 
//     cache_data_in = cache_data_in_inst;
//   end
//   else begin
//     cache_data_in = cache_data_in_data;
//   end
// end

// SUMA180_256X16 L1_cache(
//     .A0(cache_addr[0]), .A1(cache_addr[1]), .A2(cache_addr[2]), .A3(cache_addr[3]), .A4(cache_addr[4]), .A5(cache_addr[5]),
//     .A6(cache_addr[6]), .A7(cache_addr[7]),
//     .DO0(cache_data_out[0]), .DO1(cache_data_out[1]), .DO2(cache_data_out[2]), .DO3(cache_data_out[3]), .DO4(cache_data_out[4]), .DO5(cache_data_out[5]),
//     .DO6(cache_data_out[6]), .DO7(cache_data_out[7]), .DO8(cache_data_out[8]), .DO9(cache_data_out[9]), .DO10(cache_data_out[10]), .DO11(cache_data_out[11]),
//     .DO12(cache_data_out[12]), .DO13(cache_data_out[13]), .DO14(cache_data_out[14]), .DO15(cache_data_out[15]),
//     .DI0(cache_data_in[0]), .DI1(cache_data_in[1]), .DI2(cache_data_in[2]), .DI3(cache_data_in[3]), .DI4(cache_data_in[4]), .DI5(cache_data_in[5]),
//     .DI6(cache_data_in[6]), .DI7(cache_data_in[7]), .DI8(cache_data_in[8]), .DI9(cache_data_in[9]), .DI10(cache_data_in[10]), .DI11(cache_data_in[11]),
//     .DI12(cache_data_in[12]), .DI13(cache_data_in[13]), .DI14(cache_data_in[14]), .DI15(cache_data_in[15]),
//     .CK(clk), .WEB(cache_WEB), .OE(1'b1), .CS(1'b1));
// //===================================
// //           DRAM interface
// //===================================
// always @(*) begin
//   if ((c_state == IF_STAGE) && !inst_hit)
//     fetch_dram_inst = 1;
//   else
//     fetch_dram_inst = 0; 
// end
// always @(*) begin
//   if ((c_state == LOAD_STAGE) && !data_hit)
//     fetch_dram_data = 1;
//   else
//     fetch_dram_data = 0;
// end



// always @(*) begin
//   if (c_state == STORE_STAGE)
//     write_data = 1;
//   else
//     write_data = 0;
// end
// DATA_DRAM_CONTROLLER DATA_INF(.clk(clk), .rst_n(rst_n), .fetch_data(fetch_dram_data), .write_data(write_data), .cache_tag(cache_tag_data), .store_addr(load_store_addr), .data_hit(data_hit), .rt_data(rt_data_ff),
//                               .awid_m_inf(awid_m_inf), .awaddr_m_inf(awaddr_m_inf), .awsize_m_inf(awsize_m_inf), .awburst_m_inf(awburst_m_inf), .awlen_m_inf(awlen_m_inf), .awvalid_m_inf(awvalid_m_inf), .awready_m_inf(awready_m_inf),
//                               .wdata_m_inf(wdata_m_inf), .wlast_m_inf(wlast_m_inf), .wvalid_m_inf(wvalid_m_inf), .wready_m_inf(wready_m_inf),
//                               .bresp_m_inf(bresp_m_inf), .bvalid_m_inf(bvalid_m_inf), .bready_m_inf(bready_m_inf),
//                               .arid_m_inf(arid_m_inf[3:0]), .araddr_m_inf(araddr_m_inf[31:0]), .arlen_m_inf(arlen_m_inf[6:0]), .arsize_m_inf(arsize_m_inf[2:0]), .arburst_m_inf(arburst_m_inf[1:0]), .arvalid_m_inf(arvalid_m_inf[0]),
//                               .arready_m_inf(arready_m_inf[0]), .rid_m_inf(rid_m_inf[3:0]), .rdata_m_inf(rdata_m_inf[15:0]), .rresp_m_inf(rresp_m_inf[1:0]), .rlast_m_inf(rlast_m_inf[0]), .rvalid_m_inf(rvalid_m_inf[0]), .rready_m_inf(rready_m_inf[0]),
//                               .wen(wen_data), .cache_data_in(cache_data_in_data), .cache_addr(cache_addr_data));

// INST_DRAM_CONTROLLER INST_INF(.clk(clk), .rst_n(rst_n), .fetch_dram(fetch_dram_inst), .pc(pc), .cache_tag(cache_tag_inst), 
//                               .arid_m_inf(arid_m_inf[7:4]), .araddr_m_inf(araddr_m_inf[63:32]), .arlen_m_inf(arlen_m_inf[13:7]), .arsize_m_inf(arsize_m_inf[5:3]), .arburst_m_inf(arburst_m_inf[3:2]), .arvalid_m_inf(arvalid_m_inf[1]),
//                               .arready_m_inf(arready_m_inf[1]), .rid_m_inf(rid_m_inf[7:4]), .rdata_m_inf(rdata_m_inf[31:16]), .rresp_m_inf(rresp_m_inf[3:2]), .rlast_m_inf(rlast_m_inf[1]), .rvalid_m_inf(rvalid_m_inf[1]), .rready_m_inf(rready_m_inf[1]),
//                               .wen(wen_inst), .cache_data_in(cache_data_in_inst), .cache_addr(cache_addr_inst));

// //===================================
// //             MAIN FSM
// //===================================

// always @(posedge clk or negedge rst_n) begin
//   if (!rst_n) 
//     c_state <= IF_STAGE;
//   else
//     c_state <= n_state;
// end

// always @(*) begin
//   case (c_state)
//     IF_STAGE: begin
//       if (inst_hit)
//           n_state = WAIT_INST;
//       else
//           n_state = IF_STAGE;
//     end
//     WAIT_INST: begin
//       n_state = ID_STAGE;
//     end
//     ID_STAGE: begin
//       if (branch_jump)
//         n_state = IF_STAGE;
//       else
//         n_state = EXE_STAGE;
//     end
//     EXE_STAGE: begin
//       if (opcode[1]) begin
//         if (opcode[0])
//           n_state = STORE_STAGE;
//         else
//           n_state = LOAD_STAGE;
//       end
//       else
//         n_state = WB_STAGE;
//     end
//     LOAD_STAGE: begin
//       if (data_hit)
//           n_state = WAIT_DATA;
//       else 
//           n_state = LOAD_STAGE;
//     end
//     STORE_STAGE: begin
//       if (bvalid_m_inf)
//           n_state = WB_STAGE;
//       else  
//           n_state = STORE_STAGE;  
//     end
//     WAIT_DATA: begin
//       n_state = WB_STAGE;
//     end
//     WB_STAGE: begin
//       n_state = IF_STAGE;
//     end
//     default: n_state = IF_STAGE;
//   endcase
// end


// // Initialize Cache--------------------------------------------------
// // always @(*) begin
// //   if (c_state == INIT_INST_CACHE)
// //     fetch_dram_inst = 1;
// //   else
// //     fetch_dram_inst = 0;
// // end

// // always @(*) begin
// //   if (c_state == INIT_DATA_CACHE)
// //     fetch_dram_data = 1;
// //   else
// //     fetch_dram_data = 0;
// // end
// // Send fetch dram request-------------------------------------------

// //----------------------------------------------------
// //               IF STAGE
// //----------------------------------------------------
// assign inst_hit = !(pc[10:7] ^ cache_tag_inst);

// always @(posedge clk or negedge rst_n) begin
//   if (!rst_n)
//     pc <= 0;
//   else if ((c_state == ID_STAGE) && (branch_jump)) begin
//     if (branch_taken)
//       pc <= pc + 1 + imm;
//     else if (jump)
//       pc <= Address[11:1];
//     else
//       pc <= pc + 1;
//   end
//   else if ((c_state == WB_STAGE))
//     pc <= pc + 1;
//   else
//     pc <= pc;
// end


// // always @(*) begin
// //   if ((c_state == IF_STAGE))
// //     fetch_tag <= pc[10:7];
// //   else if ((c_state == LOAD_STAGE) || (c_state == STORE_STAGE))
// //     fetch_tag <= load_store_addr[10:7];
// //   else
// //     fetch_tag <= 0
  
// // end
// // save intruction-----------------------------------------------------
// always @(posedge clk or negedge rst_n) begin
//   if (!rst_n)
//     instruction <= 0;
//   else if (c_state == WAIT_INST)
//     instruction <= cache_data_out;
//   else 
//     instruction <= instruction;
// end
// //----------------------------------------------------
// //               ID STAGE
// //----------------------------------------------------
// assign opcode = instruction[15:13];
// assign rs = instruction[12:9];
// assign rt = instruction[8:5];
// assign rd = instruction[4:1];
// assign func = instruction[0];
// assign imm = instruction[4:0];
// assign Address = instruction[12:0];
// assign branch = (opcode == 3'b100);
// assign jump = (opcode[2] & opcode[0]);
// assign branch_jump = branch | jump;
// assign branch_taken = !(rs_data ^ rt_data) && branch;

// always @(*) begin
//     case (rs)
//       0:  rs_data <= core_r0;
//       1:  rs_data <= core_r1;
//       2:  rs_data <= core_r2;
//       3:  rs_data <= core_r3;
//       4:  rs_data <= core_r4;
//       5:  rs_data <= core_r5;
//       6:  rs_data <= core_r6;
//       7:  rs_data <= core_r7;
//       8:  rs_data <= core_r8;
//       9:  rs_data <= core_r9;
//       10: rs_data <= core_r10;
//       11: rs_data <= core_r11;
//       12: rs_data <= core_r12;
//       13: rs_data <= core_r13;
//       14: rs_data <= core_r14;
//       15: rs_data <= core_r15;
//       default: rs_data <= rs_data;
//     endcase
// end

// always @(*) begin
//     case (rt)
//       0:  rt_data <= core_r0;
//       1:  rt_data <= core_r1;
//       2:  rt_data <= core_r2;
//       3:  rt_data <= core_r3;
//       4:  rt_data <= core_r4;
//       5:  rt_data <= core_r5;
//       6:  rt_data <= core_r6;
//       7:  rt_data <= core_r7;
//       8:  rt_data <= core_r8;
//       9:  rt_data <= core_r9;
//       10: rt_data <= core_r10;
//       11: rt_data <= core_r11;
//       12: rt_data <= core_r12;
//       13: rt_data <= core_r13;
//       14: rt_data <= core_r14;
//       15: rt_data <= core_r15;
//       default: rt_data <= rt_data;
//     endcase
// end
// always @(posedge clk or negedge rst_n) begin
//   if (!rst_n) begin
//     rs_data_ff <= 0;
//     rt_data_ff <= 0;
//   end
//   else begin
//     rs_data_ff <= rs_data;
//     rt_data_ff <= rt_data;
//   end
// end
// //----------------------------------------------------
// //                 EXE STAGE
// //----------------------------------------------------

// // ALU------------------------------------------------
// assign add_res = rs_data_ff + rt_data_ff;
// assign sub_res = rs_data_ff - rt_data_ff;
// assign slt_res = {15'b0, sub_res[15]};
// assign mult_res = rs_data_ff * rt_data_ff;
// assign i_type_res = (rs_data_ff + imm) << 1;

// always @(*) begin
//   if (opcode[1]) begin // I type
//     alu_out = i_type_res;
//   end
//   else if (opcode[0]) begin // slt & mult
//     if (func)
//       alu_out = mult_res;
//     else
//       alu_out = slt_res;
//   end
//   else begin // add & sub
//     if (func)
//       alu_out = sub_res;
//     else
//       alu_out = add_res;
//   end
// end

// //----------------------------------------------------
// //                 MEM STAGE
// //----------------------------------------------------
// assign data_hit = (load_store_addr[11:8] == cache_tag_data); 
// always @(posedge clk or negedge rst_n) begin
//   if (!rst_n)
//     load_store_addr <= 0;
//   else if (c_state == EXE_STAGE)
//     load_store_addr <= alu_out[11:0];
//   else
//     load_store_addr <= load_store_addr; 
// end

// //----------------------------------------------------
// //                 IO STALL
// //----------------------------------------------------
// always @(*) begin
//   if ((c_state == WB_STAGE) || ((c_state == ID_STAGE) && branch_jump)) 
//     IO_stall = 0;
//   else 
//     IO_stall = 1; 
// end
// //----------------------------------------------------
// //               Register File
// //----------------------------------------------------
// // core_r0
// always@(posedge clk or negedge rst_n) begin
// 	if(!rst_n)
// 		core_r0 <= 0;
//   else if ((c_state == EXE_STAGE) && (rd == 0) && (!opcode[1]))
//     core_r0 <= alu_out;
//   else if (c_state == WAIT_DATA && (rt == 0))
//     core_r0 <= cache_data_out;
//   else
// 		core_r0 <= core_r0;
// end

// // core_r1
// always@(posedge clk or negedge rst_n) begin
// 	if(!rst_n)
// 		core_r1 <= 0;
//   else if ((c_state == EXE_STAGE) && (rd == 1) && (!opcode[1]))
//     core_r1 <= alu_out;
//   else if (c_state == WAIT_DATA && (rt == 1))
//     core_r1 <= cache_data_out;
//   else
// 		core_r1 <= core_r1;
// end

// // core_r2
// always@(posedge clk or negedge rst_n) begin
// 	if(!rst_n)
// 		core_r2 <= 0;
//   else if ((c_state == EXE_STAGE) && (rd == 2) && (!opcode[1]))
//     core_r2 <= alu_out;
//   else if (c_state == WAIT_DATA && (rt == 2))
//     core_r2 <= cache_data_out;
//   else
// 		core_r2 <= core_r2;
// end

// // core_r3
// always@(posedge clk or negedge rst_n) begin
// 	if(!rst_n)
// 		core_r3 <= 0;
//   else if ((c_state == EXE_STAGE) && (rd == 3) && (!opcode[1]))
//     core_r3 <= alu_out;
//   else if (c_state == WAIT_DATA && (rt == 3))
//     core_r3 <= cache_data_out;
//   else
// 		core_r3 <= core_r3;
// end

// // core_r4
// always@(posedge clk or negedge rst_n) begin
// 	if(!rst_n)
// 		core_r4 <= 0;
//   else if ((c_state == EXE_STAGE) && (rd == 4) && (!opcode[1]))
//     core_r4 <= alu_out;
//   else if (c_state == WAIT_DATA && (rt == 4))
//     core_r4 <= cache_data_out;
//   else
// 		core_r4 <= core_r4;
// end

// // core_r5
// always@(posedge clk or negedge rst_n) begin
// 	if(!rst_n)
// 		core_r5 <= 0;
//   else if ((c_state == EXE_STAGE) && (rd == 5) && (!opcode[1]))
//     core_r5 <= alu_out;
//   else if (c_state == WAIT_DATA && (rt == 5))
//     core_r5 <= cache_data_out;
//   else
// 		core_r5 <= core_r5;
// end

// // core_r6
// always@(posedge clk or negedge rst_n) begin
// 	if(!rst_n)
// 		core_r6 <= 0;
//   else if ((c_state == EXE_STAGE) && (rd == 6) && (!opcode[1]))
//     core_r6 <= alu_out;
//   else if (c_state == WAIT_DATA && (rt == 6))
//     core_r6 <= cache_data_out;
//   else
// 		core_r6 <= core_r6;
// end

// // core_r7
// always@(posedge clk or negedge rst_n) begin
// 	if(!rst_n)
// 		core_r7 <= 0;
//   else if ((c_state == EXE_STAGE) && (rd == 7) && (!opcode[1]))
//     core_r7 <= alu_out;
//   else if (c_state == WAIT_DATA && (rt == 7))
//     core_r7 <= cache_data_out;
//   else
// 		core_r7 <= core_r7;
// end

// // core_r8
// always@(posedge clk or negedge rst_n) begin
// 	if(!rst_n)
// 		core_r8 <= 0;
//   else if ((c_state == EXE_STAGE) && (rd == 8) && (!opcode[1]))
//     core_r8 <= alu_out;
//   else if (c_state == WAIT_DATA && (rt == 8))
//     core_r8 <= cache_data_out;
//   else
// 		core_r8 <= core_r8;
// end

// // core_r9
// always@(posedge clk or negedge rst_n) begin
// 	if(!rst_n)
// 		core_r9 <= 0;
//   else if ((c_state == EXE_STAGE) && (rd == 9) && (!opcode[1]))
//     core_r9 <= alu_out;
//   else if (c_state == WAIT_DATA && (rt == 9))
//     core_r9 <= cache_data_out;
//   else
// 		core_r9 <= core_r9;
// end

// // core_r10
// always@(posedge clk or negedge rst_n) begin
// 	if(!rst_n)
// 		core_r10 <= 0;
//   else if ((c_state == EXE_STAGE) && (rd == 10) && (!opcode[1]))
//     core_r10 <= alu_out;
//   else if (c_state == WAIT_DATA && (rt == 10))
//     core_r10 <= cache_data_out;
//   else
// 		core_r10 <= core_r10;
// end

// // core_r11
// always@(posedge clk or negedge rst_n) begin
// 	if(!rst_n)
// 		core_r11 <= 0;
//   else if ((c_state == EXE_STAGE) && (rd == 11) && (!opcode[1]))
//     core_r11 <= alu_out;
//   else if (c_state == WAIT_DATA && (rt == 11))
//     core_r11 <= cache_data_out;
//   else
// 		core_r11 <= core_r11;
// end

// // core_r12
// always@(posedge clk or negedge rst_n) begin
// 	if(!rst_n)
// 		core_r12 <= 0;
//   else if ((c_state == EXE_STAGE) && (rd == 12) && (!opcode[1]))
//     core_r12 <= alu_out;
//   else if (c_state == WAIT_DATA && (rt == 12))
//     core_r12 <= cache_data_out;
//   else
// 		core_r12 <= core_r12;
// end

// // core_r13
// always@(posedge clk or negedge rst_n) begin
// 	if(!rst_n)
// 		core_r13 <= 0;
//   else if ((c_state == EXE_STAGE) && (rd == 13) && (!opcode[1]))
//     core_r13 <= alu_out;
//   else if (c_state == WAIT_DATA && (rt == 13))
//     core_r13 <= cache_data_out;
//   else
// 		core_r13 <= core_r13;
// end

// // core_r14
// always@(posedge clk or negedge rst_n) begin
// 	if(!rst_n)
// 		core_r14 <= 0;
//   else if ((c_state == EXE_STAGE) && (rd == 14) && (!opcode[1]))
//     core_r14 <= alu_out;
//   else if (c_state == WAIT_DATA && (rt == 14))
//     core_r14 <= cache_data_out;
//   else
// 		core_r14 <= core_r14;
// end

// // core_r15
// always@(posedge clk or negedge rst_n) begin
// 	if(!rst_n)
// 		core_r15 <= 0;
//   else if ((c_state == EXE_STAGE) && (rd == 15) && (!opcode[1]))
//     core_r15 <= alu_out;
//   else if (c_state == WAIT_DATA && (rt == 15))
//     core_r15 <= cache_data_out;
//   else
// 		core_r15 <= core_r15;
// end

// endmodule



// //===================================
// //           INST DRAM FSM
// //===================================
// module INST_DRAM_CONTROLLER(
//     input               clk,
//     input               rst_n,
//     input               fetch_dram,
//     input       [10:0]  pc, // fetch address -> {1, tag_addr, 8'b0}
//     output  reg [3:0]   cache_tag,

//     output  reg [3:0]   arid_m_inf,
//     output  reg [31:0]  araddr_m_inf,
//     output  reg [6:0]   arlen_m_inf,
//     output  reg [2:0]   arsize_m_inf,
//     output  reg [1:0]   arburst_m_inf,
//     output  reg         arvalid_m_inf,
                
//     input               arready_m_inf, 
//     output  reg [3:0]   rid_m_inf,
//     input       [15:0]  rdata_m_inf,
//     input       [1:0]   rresp_m_inf,
//     input               rlast_m_inf, 
//     input               rvalid_m_inf,
//     output  reg         rready_m_inf, 

//     // sram part
//     output reg         wen,
//     output reg  [15:0] cache_data_in,
//     output reg  [6:0]  cache_addr
// );

// localparam IDLE       = 2'd0,
//            SEND_ADDR  = 2'd1,
//            SAVE_DATA  = 2'd2,
//            UPDATE_TAG = 2'd3;
// reg [1:0] c_state, n_state;

// assign arid_m_inf = 0;
// assign arlen_m_inf = 'd127;
// assign arsize_m_inf = 3'b001;
// assign arburst_m_inf = 2'b01;
// assign rid_m_inf = 0;

// always @(posedge clk or negedge rst_n) begin
//   if (!rst_n)
//     c_state <= IDLE;
//   else 
//     c_state <= n_state;
// end

// always @(*) begin
//   case (c_state)
//     IDLE: begin
//       if (fetch_dram)
//         n_state = SEND_ADDR;
//       else
//         n_state = IDLE;
//     end  
//     SEND_ADDR: begin
//       if (arready_m_inf)
//         n_state = SAVE_DATA;
//       else
//         n_state = SEND_ADDR;
//     end
//     SAVE_DATA: begin
//       if (rlast_m_inf)
//         n_state = IDLE;
//       else 
//         n_state = SAVE_DATA;
//     end
//     default: n_state = IDLE;
//   endcase
// end

// always @(*) begin
//   if (c_state == SEND_ADDR)
//     arvalid_m_inf = 1;
//   else
//     arvalid_m_inf = 0;
// end

// always @(*) begin
//   if (c_state == SEND_ADDR)
//     araddr_m_inf = {19'b0, 1'b1, pc[10:7], 8'b0};
//   else  
//     araddr_m_inf = 0;
// end

// always @(*) begin
//   if (c_state == SAVE_DATA)
//     rready_m_inf = 1;
//   else
//     rready_m_inf = 0;
// end

// always @(posedge clk or negedge rst_n) begin
//   if (!rst_n)
//     cache_addr <= 0;
//   else if (rvalid_m_inf)
//     cache_addr <= cache_addr + 1;
//   else
//     cache_addr <= cache_addr; 
// end

// always @(*) begin
//   wen = !rvalid_m_inf;
// end

// always @(*) begin
//   if (rvalid_m_inf)
//     cache_data_in = rdata_m_inf;
//   else
//     cache_data_in = 0;  
// end

// always @(posedge clk or negedge rst_n) begin
//   if (!rst_n)
//     cache_tag <= 1;
//   else if (rlast_m_inf)
//     cache_tag <= pc[10:7];
//   else
//     cache_tag <= cache_tag;
// end

// endmodule
            
// //===================================
// //           DATA DRAM FSM
// //===================================

// module DATA_DRAM_CONTROLLER(
//     input               clk,
//     input               rst_n,
//     input               data_hit,
//     input               fetch_data,
//     input               write_data,
//     input       [11:0]  store_addr, // fetch address -> {1, tag_addr, 8'b0}
//     output  reg [3:0]   cache_tag,
//     input       [15:0]  rt_data,

//     output  reg [3:0]   awid_m_inf,
//     output  reg [31:0]  awaddr_m_inf,
//     output  reg [2:0]   awsize_m_inf,
//     output  reg [1:0]   awburst_m_inf,
//     output  reg [6:0]   awlen_m_inf,
//     output  reg         awvalid_m_inf,
//     input               awready_m_inf,
                    
//     output  reg [15:0]  wdata_m_inf,
//     output  reg         wlast_m_inf,
//     output  reg         wvalid_m_inf,
//     input               wready_m_inf,
                    
//     input   [1:0]       bresp_m_inf,
//     input               bvalid_m_inf,
//     output reg          bready_m_inf,

//     output  reg [3:0]   arid_m_inf,
//     output  reg [31:0]  araddr_m_inf,
//     output  reg [6:0]   arlen_m_inf,
//     output  reg [2:0]   arsize_m_inf,
//     output  reg [1:0]   arburst_m_inf,
//     output  reg         arvalid_m_inf,
                
//     input               arready_m_inf, 
//     output  reg [3:0]   rid_m_inf,
//     input       [15:0]  rdata_m_inf,
//     input       [1:0]   rresp_m_inf,
//     input               rlast_m_inf, 
//     input               rvalid_m_inf,
//     output reg          rready_m_inf, 

//     // sram part
//     output reg           wen,
//     output reg  [15:0]   cache_data_in,
//     output reg  [6:0]    cache_addr
// );

// localparam IDLE        = 3'd0,
//            SEND_ARADDR = 3'd1,
//            SAVE_DATA   = 3'd2,
//            SEND_AWADDR = 3'd3,
//            WRITE_DATA  = 3'd4,
//            WAIT_RESP   = 3'd5;

// reg [3:0] c_state, n_state;
// reg [6:0] addr_cnt;
// reg       wready_ff;
// assign arid_m_inf = 0;
// assign arlen_m_inf = 'd127;
// assign arsize_m_inf = 3'b001;
// assign arburst_m_inf = 2'b01;
// assign rid_m_inf = 0;

// assign awid_m_inf = 0;
// assign awlen_m_inf = 'd0;
// assign awsize_m_inf = 3'b001;
// assign awburst_m_inf = 2'b01;

// always @(posedge clk or negedge rst_n) begin
//   if (!rst_n)
//     c_state <= IDLE;
//   else 
//     c_state <= n_state;
// end

// always @(*) begin
//   case (c_state)
//     IDLE: begin
//       if (write_data) 
//         n_state = SEND_AWADDR;
//       else if (fetch_data)
//         n_state = SEND_ARADDR;
//       else
//         n_state = IDLE;
//     end  
//     SEND_ARADDR: begin
//       if (arready_m_inf)
//         n_state = SAVE_DATA;
//       else
//         n_state = SEND_ARADDR;
//     end
//     SAVE_DATA: begin
//       if (rlast_m_inf)
//         n_state = IDLE;
//       else 
//         n_state = SAVE_DATA;
//     end
//     SEND_AWADDR: begin
//       if (awready_m_inf)
//         n_state = WRITE_DATA;
//       else
//         n_state = SEND_AWADDR;
//     end
//     WRITE_DATA: begin
//       if (wready_m_inf)
//         n_state = WAIT_RESP;
//       else
//         n_state = WRITE_DATA;
//     end
//     WAIT_RESP: begin
//       if (bvalid_m_inf)
//           n_state = IDLE;
//       else
//         n_state = WAIT_RESP;
//     end
//     default: n_state = IDLE;
//   endcase
// end

// //read part------------------------------------------------
// always @(*) begin
//   if (c_state == SEND_ARADDR)
//     arvalid_m_inf = 1;
//   else
//     arvalid_m_inf = 0;
// end

// always @(*) begin
//   if (c_state == SEND_ARADDR)
//     araddr_m_inf = {19'b0, 1'b1, store_addr[11:8], 8'b0};
//   else  
//     araddr_m_inf = 0;
// end

// always @(*) begin
//   if (c_state == SAVE_DATA)
//     rready_m_inf = 1;
//   else
//     rready_m_inf = 0;
// end

// always @(*) begin
//   if (c_state == SAVE_DATA)
//     wen = 0;
//   else if (c_state == WRITE_DATA) begin
//     if (data_hit)
//       wen = 0;
//     else
//      wen = 1;
//   end
//   else
//     wen = 1;

// end

// always @(*) begin
//   if (rvalid_m_inf)
//     cache_data_in = rdata_m_inf;
//   else if (c_state == WRITE_DATA)
//     cache_data_in = rt_data;
//   else
//     cache_data_in = 0;  
// end

// always @(posedge clk or negedge rst_n) begin
//   if (!rst_n)
//     cache_tag <= 1;
//   else if (rlast_m_inf)
//     cache_tag <= store_addr[11:8];
//   else
//     cache_tag <= cache_tag;
// end
// // write part--------------------------------------------
// always @(*) begin
//   if (c_state == SEND_AWADDR) begin
//     awvalid_m_inf = 1;
//     awaddr_m_inf = {19'b0, 1'b1, store_addr};
//   end
//   else begin
//     awvalid_m_inf = 0;
//     awaddr_m_inf = 0;
//   end
// end
// always @(*) begin
//   if (c_state == WRITE_DATA)
//     wvalid_m_inf = 1;
//   else
//     wvalid_m_inf = 0;
// end
// always @(*) begin 
//     wdata_m_inf = rt_data;
// end
// always @(*) begin
//   if (c_state == WRITE_DATA)
//     wlast_m_inf = 1;
//   else
//     wlast_m_inf = 0;
// end

// always @(*) begin
//   if (c_state == WAIT_RESP)
//     bready_m_inf = 1;
//   else
//     bready_m_inf = 0;
// end
// // cache addr count-------------------------------------
// always @(*) begin
//   if (c_state == SAVE_DATA)
//     cache_addr = addr_cnt;
//   else
//     cache_addr = {1'b1, store_addr[7:1]};
// end

// always @(posedge clk or negedge rst_n) begin
//   if (!rst_n)
//     addr_cnt <= 0;
//   else if (rvalid_m_inf)
//     addr_cnt <= addr_cnt + 1;
//   else
//     addr_cnt <= addr_cnt;
// end
// endmodule



















