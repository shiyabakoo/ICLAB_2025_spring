//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Si2 LAB @NYCU ED430
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2023 Fall
//   Midterm Proejct            : MRA  
//   Author                     : Lin-Hung, Lai
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : MRA.v
//   Module Name : MRA
//   Release version : V2.0 (Release Date: 2023-10)
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
//  					Input / Output 
// ===============================================================

// << CHIP io port with system >>
input 			  	clk,rst_n;
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
parameter ID_WIDTH=4, DATA_WIDTH=128, ADDR_WIDTH=32;

// ------------------------
// <<<<< AXI READ >>>>>
// ------------------------
// (1)	axi read address channel 
output wire [ID_WIDTH-1:0]      arid_m_inf;
output wire [1:0]            arburst_m_inf;
output wire [2:0]             arsize_m_inf;
output wire [7:0]              arlen_m_inf;
output wire                  arvalid_m_inf;
input  wire                  arready_m_inf;
output wire [ADDR_WIDTH-1:0]  araddr_m_inf;
// ------------------------
// (2)	axi read data channel 
input  wire [ID_WIDTH-1:0]       rid_m_inf; 
input  wire                   rvalid_m_inf;
output wire                    rready_m_inf;
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
output wire                  awvalid_m_inf;
input  wire                  awready_m_inf;
output wire [ADDR_WIDTH-1:0]  awaddr_m_inf;
// -------------------------
// (2)	axi write data channel 
output wire                   wvalid_m_inf;
input  wire                   wready_m_inf;
output wire [DATA_WIDTH-1:0]   wdata_m_inf;
output wire                    wlast_m_inf;
// -------------------------
// (3)	axi write response channel 
input  wire  [ID_WIDTH-1:0]      bid_m_inf;
input  wire                   bvalid_m_inf;
output wire                   bready_m_inf;
input  wire  [1:0]             bresp_m_inf;
// -----------------------------

// ------------------------------------------------
//                 reg & wire 
// ------------------------------------------------
//axi interface---------------------------------
// (1)	axi read address channel 
reg                   arvalid;
reg [ADDR_WIDTH-1:0]  araddr;
// ------------------------
// (2)	axi read data channel 
reg                   rready;
reg					  rvalid_ff;
reg	[DATA_WIDTH-1:0]  rdata_ff;
reg 			      rlast_ff;
// ------------------------
// <<<<< AXI WRITE >>>>>
// ------------------------
// (1) 	axi write address channel 
reg                   awvalid;
reg [ADDR_WIDTH-1:0]  awaddr;
// -------------------------
// (2)	axi write data channel 
reg                    wvalid;
reg [DATA_WIDTH-1:0]   wdata;
reg                    wlast;
// -------------------------
// (3)	axi write response channel 
reg                   bready;
//------------------------------------------
// instance 
reg  [127:0] DI_W;
reg  [6:0]   A_W;
reg  		 WEB_W;
wire [127:0] DO_W;

reg  [127:0] DI_L;
reg  [6:0]   A_L;
reg  		 WEB_L;
wire [127:0] DO_L;
// input
reg		   in_valid_ff;
reg  [4:0] frame_id_ff;
reg  [3:0] net_id_ff;     
reg  [5:0] loc_x_ff; 
reg  [5:0] loc_y_ff; 
reg  [6:0] addr_cnt;
// fsm
reg [3:0] c_state;
reg [3:0] n_state;
// save target
wire [3:0] cur_net_id;
reg [3:0] net_id_count;
reg 	  loc_count;
reg [3:0] target_array [0:14]; // for save net_id
reg [5:0] source_x_arry [0:14];
reg [5:0] source_y_arry [0:14];
reg [5:0] sink_x_arry [0:14];
reg [5:0] sink_y_arry [0:14];
// reg map
reg	[5:0] map_count;
reg [1:0] location_converter[0:31];
reg [1:0] location_map_reg [0:63][0:63];
// propagation
reg [1:0] current_sequence;
reg [1:0] propagate_count;
reg		  propagate_done;
// retrace
// reg 	  start_retrace;
reg [5:0] path_x;
reg [5:0] path_y;
reg [5:0] next_path_x;
reg [5:0] next_path_y;
reg [1:0] retrace_state;
reg [1:0] retrace_target;
reg       down, up, right, left;
reg       read_cnt;
reg       write_cnt;
reg		  index;
// iteration
reg		  first_iteration_done;
integer j, k;
// ------------------------------------------------
//                 SRAM instance
// ------------------------------------------------

SRAM W_SRAM (
    .DI0(DI_W[0]), .DI1(DI_W[1]), .DI2(DI_W[2]), .DI3(DI_W[3]), .DI4(DI_W[4]), .DI5(DI_W[5]), .DI6(DI_W[6]), .DI7(DI_W[7]), .DI8(DI_W[8]), .DI9(DI_W[9]), .DI10(DI_W[10]), .DI11(DI_W[11]), .DI12(DI_W[12]), .DI13(DI_W[13]), .DI14(DI_W[14]), .DI15(DI_W[15]), .DI16(DI_W[16]), .DI17(DI_W[17]), .DI18(DI_W[18]), .DI19(DI_W[19]), .DI20(DI_W[20]), .DI21(DI_W[21]), .DI22(DI_W[22]), .DI23(DI_W[23]), .DI24(DI_W[24]), .DI25(DI_W[25]), .DI26(DI_W[26]), .DI27(DI_W[27]), .DI28(DI_W[28]), .DI29(DI_W[29]), .DI30(DI_W[30]), .DI31(DI_W[31]),
    .DI32(DI_W[32]), .DI33(DI_W[33]), .DI34(DI_W[34]), .DI35(DI_W[35]), .DI36(DI_W[36]), .DI37(DI_W[37]), .DI38(DI_W[38]), .DI39(DI_W[39]), .DI40(DI_W[40]), .DI41(DI_W[41]), .DI42(DI_W[42]), .DI43(DI_W[43]), .DI44(DI_W[44]), .DI45(DI_W[45]), .DI46(DI_W[46]), .DI47(DI_W[47]), .DI48(DI_W[48]), .DI49(DI_W[49]), .DI50(DI_W[50]), .DI51(DI_W[51]), .DI52(DI_W[52]), .DI53(DI_W[53]), .DI54(DI_W[54]), .DI55(DI_W[55]), .DI56(DI_W[56]), .DI57(DI_W[57]), .DI58(DI_W[58]), .DI59(DI_W[59]), .DI60(DI_W[60]), .DI61(DI_W[61]), .DI62(DI_W[62]), .DI63(DI_W[63]),
    .DI64(DI_W[64]), .DI65(DI_W[65]), .DI66(DI_W[66]), .DI67(DI_W[67]), .DI68(DI_W[68]), .DI69(DI_W[69]), .DI70(DI_W[70]), .DI71(DI_W[71]), .DI72(DI_W[72]), .DI73(DI_W[73]), .DI74(DI_W[74]), .DI75(DI_W[75]), .DI76(DI_W[76]), .DI77(DI_W[77]), .DI78(DI_W[78]), .DI79(DI_W[79]), .DI80(DI_W[80]), .DI81(DI_W[81]), .DI82(DI_W[82]), .DI83(DI_W[83]), .DI84(DI_W[84]), .DI85(DI_W[85]), .DI86(DI_W[86]), .DI87(DI_W[87]), .DI88(DI_W[88]), .DI89(DI_W[89]), .DI90(DI_W[90]), .DI91(DI_W[91]), .DI92(DI_W[92]), .DI93(DI_W[93]), .DI94(DI_W[94]), .DI95(DI_W[95]),
    .DI96(DI_W[96]), .DI97(DI_W[97]), .DI98(DI_W[98]), .DI99(DI_W[99]), .DI100(DI_W[100]), .DI101(DI_W[101]), .DI102(DI_W[102]), .DI103(DI_W[103]), .DI104(DI_W[104]), .DI105(DI_W[105]), .DI106(DI_W[106]), .DI107(DI_W[107]), .DI108(DI_W[108]), .DI109(DI_W[109]), .DI110(DI_W[110]), .DI111(DI_W[111]), .DI112(DI_W[112]), .DI113(DI_W[113]), .DI114(DI_W[114]), .DI115(DI_W[115]), .DI116(DI_W[116]), .DI117(DI_W[117]), .DI118(DI_W[118]), .DI119(DI_W[119]), .DI120(DI_W[120]), .DI121(DI_W[121]), .DI122(DI_W[122]), .DI123(DI_W[123]), .DI124(DI_W[124]), .DI125(DI_W[125]), .DI126(DI_W[126]), .DI127(DI_W[127]),
   .DO0(DO_W[0]), .DO1(DO_W[1]), .DO2(DO_W[2]), .DO3(DO_W[3]), .DO4(DO_W[4]), .DO5(DO_W[5]), .DO6(DO_W[6]), .DO7(DO_W[7]), .DO8(DO_W[8]), .DO9(DO_W[9]), .DO10(DO_W[10]), .DO11(DO_W[11]), .DO12(DO_W[12]), .DO13(DO_W[13]), .DO14(DO_W[14]), .DO15(DO_W[15]), .DO16(DO_W[16]), .DO17(DO_W[17]), .DO18(DO_W[18]), .DO19(DO_W[19]), .DO20(DO_W[20]), .DO21(DO_W[21]), .DO22(DO_W[22]), .DO23(DO_W[23]), .DO24(DO_W[24]), .DO25(DO_W[25]), .DO26(DO_W[26]), .DO27(DO_W[27]), .DO28(DO_W[28]), .DO29(DO_W[29]), .DO30(DO_W[30]), .DO31(DO_W[31]),     
    .DO32(DO_W[32]), .DO33(DO_W[33]), .DO34(DO_W[34]), .DO35(DO_W[35]), .DO36(DO_W[36]), .DO37(DO_W[37]), .DO38(DO_W[38]), .DO39(DO_W[39]), .DO40(DO_W[40]), .DO41(DO_W[41]), .DO42(DO_W[42]), .DO43(DO_W[43]), .DO44(DO_W[44]), .DO45(DO_W[45]), .DO46(DO_W[46]), .DO47(DO_W[47]), .DO48(DO_W[48]), .DO49(DO_W[49]), .DO50(DO_W[50]), .DO51(DO_W[51]), .DO52(DO_W[52]), .DO53(DO_W[53]), .DO54(DO_W[54]), .DO55(DO_W[55]), .DO56(DO_W[56]), .DO57(DO_W[57]), .DO58(DO_W[58]), .DO59(DO_W[59]), .DO60(DO_W[60]), .DO61(DO_W[61]), .DO62(DO_W[62]), .DO63(DO_W[63]),
    .DO64(DO_W[64]), .DO65(DO_W[65]), .DO66(DO_W[66]), .DO67(DO_W[67]), .DO68(DO_W[68]), .DO69(DO_W[69]), .DO70(DO_W[70]), .DO71(DO_W[71]), .DO72(DO_W[72]), .DO73(DO_W[73]), .DO74(DO_W[74]), .DO75(DO_W[75]), .DO76(DO_W[76]), .DO77(DO_W[77]), .DO78(DO_W[78]), .DO79(DO_W[79]), .DO80(DO_W[80]), .DO81(DO_W[81]), .DO82(DO_W[82]), .DO83(DO_W[83]), .DO84(DO_W[84]), .DO85(DO_W[85]), .DO86(DO_W[86]), .DO87(DO_W[87]), .DO88(DO_W[88]), .DO89(DO_W[89]), .DO90(DO_W[90]), .DO91(DO_W[91]), .DO92(DO_W[92]), .DO93(DO_W[93]), .DO94(DO_W[94]), .DO95(DO_W[95]),
    .DO96(DO_W[96]), .DO97(DO_W[97]), .DO98(DO_W[98]), .DO99(DO_W[99]), .DO100(DO_W[100]), .DO101(DO_W[101]), .DO102(DO_W[102]), .DO103(DO_W[103]), .DO104(DO_W[104]), .DO105(DO_W[105]), .DO106(DO_W[106]), .DO107(DO_W[107]), .DO108(DO_W[108]), .DO109(DO_W[109]), .DO110(DO_W[110]), .DO111(DO_W[111]), .DO112(DO_W[112]), .DO113(DO_W[113]), .DO114(DO_W[114]), .DO115(DO_W[115]), .DO116(DO_W[116]), .DO117(DO_W[117]), .DO118(DO_W[118]), .DO119(DO_W[119]), .DO120(DO_W[120]), .DO121(DO_W[121]), .DO122(DO_W[122]), .DO123(DO_W[123]), .DO124(DO_W[124]), .DO125(DO_W[125]), .DO126(DO_W[126]), .DO127(DO_W[127]),
    .A0(A_W[0]), .A1(A_W[1]), .A2(A_W[2]), .A3(A_W[3]), .A4(A_W[4]), .A5(A_W[5]), .A6(A_W[6]), .OE(1'b1), .CS(1'b1), .WEB(WEB_W), .CK(clk)
);

SRAM L_SRAM (
    .DI0(DI_L[0]), .DI1(DI_L[1]), .DI2(DI_L[2]), .DI3(DI_L[3]), .DI4(DI_L[4]), .DI5(DI_L[5]), .DI6(DI_L[6]), .DI7(DI_L[7]), .DI8(DI_L[8]), .DI9(DI_L[9]), .DI10(DI_L[10]), .DI11(DI_L[11]), .DI12(DI_L[12]), .DI13(DI_L[13]), .DI14(DI_L[14]), .DI15(DI_L[15]), .DI16(DI_L[16]), .DI17(DI_L[17]), .DI18(DI_L[18]), .DI19(DI_L[19]), .DI20(DI_L[20]), .DI21(DI_L[21]), .DI22(DI_L[22]), .DI23(DI_L[23]), .DI24(DI_L[24]), .DI25(DI_L[25]), .DI26(DI_L[26]), .DI27(DI_L[27]), .DI28(DI_L[28]), .DI29(DI_L[29]), .DI30(DI_L[30]), .DI31(DI_L[31]),     
    .DI32(DI_L[32]), .DI33(DI_L[33]), .DI34(DI_L[34]), .DI35(DI_L[35]), .DI36(DI_L[36]), .DI37(DI_L[37]), .DI38(DI_L[38]), .DI39(DI_L[39]), .DI40(DI_L[40]), .DI41(DI_L[41]), .DI42(DI_L[42]), .DI43(DI_L[43]), .DI44(DI_L[44]), .DI45(DI_L[45]), .DI46(DI_L[46]), .DI47(DI_L[47]), .DI48(DI_L[48]), .DI49(DI_L[49]), .DI50(DI_L[50]), .DI51(DI_L[51]), .DI52(DI_L[52]), .DI53(DI_L[53]), .DI54(DI_L[54]), .DI55(DI_L[55]), .DI56(DI_L[56]), .DI57(DI_L[57]), .DI58(DI_L[58]), .DI59(DI_L[59]), .DI60(DI_L[60]), .DI61(DI_L[61]), .DI62(DI_L[62]), .DI63(DI_L[63]),
    .DI64(DI_L[64]), .DI65(DI_L[65]), .DI66(DI_L[66]), .DI67(DI_L[67]), .DI68(DI_L[68]), .DI69(DI_L[69]), .DI70(DI_L[70]), .DI71(DI_L[71]), .DI72(DI_L[72]), .DI73(DI_L[73]), .DI74(DI_L[74]), .DI75(DI_L[75]), .DI76(DI_L[76]), .DI77(DI_L[77]), .DI78(DI_L[78]), .DI79(DI_L[79]), .DI80(DI_L[80]), .DI81(DI_L[81]), .DI82(DI_L[82]), .DI83(DI_L[83]), .DI84(DI_L[84]), .DI85(DI_L[85]), .DI86(DI_L[86]), .DI87(DI_L[87]), .DI88(DI_L[88]), .DI89(DI_L[89]), .DI90(DI_L[90]), .DI91(DI_L[91]), .DI92(DI_L[92]), .DI93(DI_L[93]), .DI94(DI_L[94]), .DI95(DI_L[95]),
    .DI96(DI_L[96]), .DI97(DI_L[97]), .DI98(DI_L[98]), .DI99(DI_L[99]), .DI100(DI_L[100]), .DI101(DI_L[101]), .DI102(DI_L[102]), .DI103(DI_L[103]), .DI104(DI_L[104]), .DI105(DI_L[105]), .DI106(DI_L[106]), .DI107(DI_L[107]), .DI108(DI_L[108]), .DI109(DI_L[109]), .DI110(DI_L[110]), .DI111(DI_L[111]), .DI112(DI_L[112]), .DI113(DI_L[113]), .DI114(DI_L[114]), .DI115(DI_L[115]), .DI116(DI_L[116]), .DI117(DI_L[117]), .DI118(DI_L[118]), .DI119(DI_L[119]), .DI120(DI_L[120]), .DI121(DI_L[121]), .DI122(DI_L[122]), .DI123(DI_L[123]), .DI124(DI_L[124]), .DI125(DI_L[125]), .DI126(DI_L[126]), .DI127(DI_L[127]),
    .DO0(DO_L[0]), .DO1(DO_L[1]), .DO2(DO_L[2]), .DO3(DO_L[3]), .DO4(DO_L[4]), .DO5(DO_L[5]), .DO6(DO_L[6]), .DO7(DO_L[7]), .DO8(DO_L[8]), .DO9(DO_L[9]), .DO10(DO_L[10]), .DO11(DO_L[11]), .DO12(DO_L[12]), .DO13(DO_L[13]), .DO14(DO_L[14]), .DO15(DO_L[15]), .DO16(DO_L[16]), .DO17(DO_L[17]), .DO18(DO_L[18]), .DO19(DO_L[19]), .DO20(DO_L[20]), .DO21(DO_L[21]), .DO22(DO_L[22]), .DO23(DO_L[23]), .DO24(DO_L[24]), .DO25(DO_L[25]), .DO26(DO_L[26]), .DO27(DO_L[27]), .DO28(DO_L[28]), .DO29(DO_L[29]), .DO30(DO_L[30]), .DO31(DO_L[31]),     
    .DO32(DO_L[32]), .DO33(DO_L[33]), .DO34(DO_L[34]), .DO35(DO_L[35]), .DO36(DO_L[36]), .DO37(DO_L[37]), .DO38(DO_L[38]), .DO39(DO_L[39]), .DO40(DO_L[40]), .DO41(DO_L[41]), .DO42(DO_L[42]), .DO43(DO_L[43]), .DO44(DO_L[44]), .DO45(DO_L[45]), .DO46(DO_L[46]), .DO47(DO_L[47]), .DO48(DO_L[48]), .DO49(DO_L[49]), .DO50(DO_L[50]), .DO51(DO_L[51]), .DO52(DO_L[52]), .DO53(DO_L[53]), .DO54(DO_L[54]), .DO55(DO_L[55]), .DO56(DO_L[56]), .DO57(DO_L[57]), .DO58(DO_L[58]), .DO59(DO_L[59]), .DO60(DO_L[60]), .DO61(DO_L[61]), .DO62(DO_L[62]), .DO63(DO_L[63]),
    .DO64(DO_L[64]), .DO65(DO_L[65]), .DO66(DO_L[66]), .DO67(DO_L[67]), .DO68(DO_L[68]), .DO69(DO_L[69]), .DO70(DO_L[70]), .DO71(DO_L[71]), .DO72(DO_L[72]), .DO73(DO_L[73]), .DO74(DO_L[74]), .DO75(DO_L[75]), .DO76(DO_L[76]), .DO77(DO_L[77]), .DO78(DO_L[78]), .DO79(DO_L[79]), .DO80(DO_L[80]), .DO81(DO_L[81]), .DO82(DO_L[82]), .DO83(DO_L[83]), .DO84(DO_L[84]), .DO85(DO_L[85]), .DO86(DO_L[86]), .DO87(DO_L[87]), .DO88(DO_L[88]), .DO89(DO_L[89]), .DO90(DO_L[90]), .DO91(DO_L[91]), .DO92(DO_L[92]), .DO93(DO_L[93]), .DO94(DO_L[94]), .DO95(DO_L[95]),
    .DO96(DO_L[96]), .DO97(DO_L[97]), .DO98(DO_L[98]), .DO99(DO_L[99]), .DO100(DO_L[100]), .DO101(DO_L[101]), .DO102(DO_L[102]), .DO103(DO_L[103]), .DO104(DO_L[104]), .DO105(DO_L[105]), .DO106(DO_L[106]), .DO107(DO_L[107]), .DO108(DO_L[108]), .DO109(DO_L[109]), .DO110(DO_L[110]), .DO111(DO_L[111]), .DO112(DO_L[112]), .DO113(DO_L[113]), .DO114(DO_L[114]), .DO115(DO_L[115]), .DO116(DO_L[116]), .DO117(DO_L[117]), .DO118(DO_L[118]), .DO119(DO_L[119]), .DO120(DO_L[120]), .DO121(DO_L[121]), .DO122(DO_L[122]), .DO123(DO_L[123]), .DO124(DO_L[124]), .DO125(DO_L[125]), .DO126(DO_L[126]), .DO127(DO_L[127]),
    .A0(A_L[0]), .A1(A_L[1]), .A2(A_L[2]), .A3(A_L[3]), .A4(A_L[4]), .A5(A_L[5]), .A6(A_L[6]), .OE(1'b1), .CS(1'b1), .WEB(WEB_L), .CK(clk)
);

// ------------------------------------------------
//                       FSM
// ------------------------------------------------
localparam IDLE = 4'd0, // IDLE state
		   S1   = 4'd1, // send araddr & arvalid
		   S2   = 4'd2, // save location to L_SRAM 
		   S3   = 4'd3, // initialize reg map & send addr fot weight & initialize path
		   S4   = 4'd4, // propagation & save wieght
		   S5   = 4'd5, // if propagate done, wait save wieght
		   S6   = 4'd6, // if save wieght done, wait propagate
		   S7   = 4'd7, // retrace & read SRAM
		   S8   = 4'd8, // retrace & write SRAM
		   S9   = 4'd9, // clean map
		   S10  = 4'd10, // initialize reg map
		   S11  = 4'd11, // send write valid
		   S12  = 4'd12, // write dram
		   S13  = 4'd13; // last
always @(posedge clk or negedge rst_n) begin
	if (!rst_n)
		c_state <= IDLE;
	else 
	 	c_state <= n_state;
end

always @(*) begin
	case (c_state)
		IDLE: begin
			if (in_valid)
				n_state = S1;
			else 
				n_state = IDLE;
		end
		S1: begin
			if (arready_m_inf)
				n_state = S2;
			else
				n_state = S1;
		end
		S2: begin
			if (rlast_m_inf)
				n_state = S3;
			else 
				n_state = S2;
		end 
		S3: begin
			n_state = S4;
		end
		S4: begin
			if (rlast_m_inf && propagate_done)
				n_state = S7;
			else if (rlast_m_inf)
				n_state = S6;
			else if (propagate_done)
				n_state = S5;
			else
				n_state = S4;
		end
		S5: begin
			if (rlast_m_inf || (first_iteration_done))
				n_state = S7;
			else
				n_state = S5;
		end
		S6: begin
			if (propagate_done)
				n_state = S7;
			else 
				n_state = S6;
		end
		S7: begin
			n_state = S8;
		end
		S8: begin
			if ((path_x == source_x_arry[cur_net_id]) && (path_y == source_y_arry[cur_net_id]))
				n_state = S9;
			else
				n_state = S7;
		end
		S9: begin
			if ((net_id_count == 1))
				n_state = S11;
			else
				n_state = S10;
		end
		S10: begin
			n_state = S4;
		end
		S11: begin
			if (awready_m_inf)
				n_state = S12;
			else
				n_state = S11;
		end
		S12: begin
			if (wlast_m_inf)
				n_state = S13;
			else
				n_state = S12;
		end
		S13: begin
			if (bvalid_m_inf)
				n_state =IDLE;
			else
				n_state = S13;
		end
		default: n_state = IDLE;
	endcase
end
// ------------------------------------------------
//                      INPUT
// ------------------------------------------------
genvar i;

always @(posedge clk) begin
	in_valid_ff <= in_valid;

end

always @(posedge clk) begin
	if (in_valid)
		frame_id_ff <= frame_id;
	else 
		frame_id_ff <= frame_id_ff;
end

always @(posedge clk) begin
	if (in_valid) begin
		loc_x_ff <= loc_x;
		loc_y_ff <= loc_y;
	end 
	else begin
		loc_x_ff <= 0;
		loc_y_ff <= 0;
	end
end

always @(posedge clk) begin
	if (in_valid)
		net_id_ff <= net_id;
	else
		net_id_ff <= 0;
end 


always @(posedge clk or negedge rst_n) begin
	if (!rst_n)
		loc_count <= 0;
	else if (in_valid_ff)
		loc_count <= loc_count + 1;
	else
		loc_count <= 0;
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n)
		net_id_count <= 0;
	else if (n_state == IDLE)
		net_id_count <= 0;
	else if (in_valid_ff && loc_count == 1)
		net_id_count <= net_id_count + 1;
	else if (c_state == S9) begin
		if (net_id_count == 0) 
			net_id_count <= 0;
		else 
			net_id_count <= net_id_count - 1;
	end
	else
		net_id_count <= net_id_count;
end

assign cur_net_id = net_id_count - 1;

always @(posedge clk) begin
	if (c_state == IDLE) begin
		source_x_arry[0] <= 6'd0;
		source_y_arry[0] <= 6'd0;
	end
	else if (in_valid_ff && (loc_count == 0)) begin
		source_x_arry[0] <= loc_x_ff;
		source_y_arry[0] <= loc_y_ff;
	end
	else begin
		source_x_arry[0] <= source_x_arry[0];
		source_y_arry[0] <= source_y_arry[0];
	end
end

always @(posedge clk) begin
	if (c_state == IDLE) begin
		sink_x_arry[0] <= 6'd0;
		sink_y_arry[0] <= 6'd0;
	end
	else if (in_valid_ff && (loc_count == 1)) begin
		sink_x_arry[0] <= loc_x_ff;
		sink_y_arry[0] <= loc_y_ff;
	end
	else begin
		sink_x_arry[0] <= sink_x_arry[0];
		sink_y_arry[0] <= sink_y_arry[0];
	end
end

always @(posedge clk) begin
	if (c_state == IDLE)
		target_array[0] <= 4'd0;
	else if (in_valid_ff && (loc_count == 1))
		target_array[0] <= net_id_ff;
	else 
		target_array[0] <= target_array[0];
end

generate
	for (i = 1; i < 15; i = i + 1) begin
		always @(posedge clk) begin
			if (c_state == IDLE) begin
				source_x_arry[i] <= 6'd0;
				source_y_arry[i] <= 6'd0;
			end
			else if (in_valid_ff && (loc_count == 0)) begin
				source_x_arry[i] <= source_x_arry[i - 1];
				source_y_arry[i] <= source_y_arry[i - 1];
			end
			else begin
				source_x_arry[i] <= source_x_arry[i];
				source_y_arry[i] <= source_y_arry[i];
			end
		end

		always @(posedge clk) begin
			if (c_state == IDLE) begin
				sink_x_arry[i] <= 6'd0;
				sink_y_arry[i] <= 6'd0;
			end
			else if (in_valid_ff && (loc_count == 1)) begin
				sink_x_arry[i] <= sink_x_arry[i - 1];
				sink_y_arry[i] <= sink_y_arry[i - 1];
			end
			else begin
				sink_x_arry[i] <= sink_x_arry[i];
				sink_y_arry[i] <= sink_y_arry[i];
			end
		end

		always @(posedge clk) begin
			if (c_state == IDLE)
				target_array[i] <= 4'd0;
			else if (in_valid_ff && (loc_count == 1))
				target_array[i] <= target_array[i - 1];
			else 
				target_array[i] <= target_array[i];
		end
	end
endgenerate


// ------------------------------------------------
//                 AXI-4 interface
// ------------------------------------------------
// (1)	axi read address channel 
assign arid_m_inf = 4'd0;
assign arlen_m_inf = 8'd127;
assign arsize_m_inf = 3'b100;
assign arburst_m_inf = 2'b01; 
assign arvalid_m_inf = arvalid;
assign araddr_m_inf = araddr;
// ------------------------
// (2)	axi read data channel 
assign rready_m_inf = rready;
// ------------------------
// <<<<< AXI WRITE >>>>>
// ------------------------
// (1) 	axi write address channel 
assign awid_m_inf = 4'd0;
assign awlen_m_inf = 8'd127;
assign awsize_m_inf = 3'b100;
assign awburst_m_inf = 2'b01;
assign awvalid_m_inf = awvalid;
assign awaddr_m_inf = awaddr;
// -------------------------
// (2)	axi write data channel 
assign wvalid_m_inf = wvalid;
assign wdata_m_inf = wdata;
assign wlast_m_inf = wlast;
// -------------------------
// (3)	axi write response channel 
assign bready_m_inf = bready;
//------------------------------------------

// ------------------------------------------------
//                 AXI-4 read
// ------------------------------------------------

always @(posedge clk) begin
	if (c_state == S1)
		araddr <= 32'h0001_0000 + (frame_id_ff << 11);
	else if (c_state == S3) begin
		araddr <= 32'h0002_0000 + (frame_id_ff << 11);
	end
	else 
		araddr <= araddr;
end

always @(posedge clk) begin
	if (arready_m_inf)
		arvalid <= 0;
	else if ((c_state == S1) || (c_state == S3))
		arvalid <= 1;
	else
		arvalid <= 0;
end

always @(posedge clk) begin
	if (rlast_m_inf)
		rready <= 0;
	else if ((c_state == S1) || (c_state == S3))
		rready <= 1;
	else
		rready <= rready;
end

// ------------------------------------------------
//                 AXI-4 write
// ------------------------------------------------
always @(posedge clk) begin
	if (c_state == S11)
		awaddr <= 32'h0001_0000 + (frame_id_ff << 11);
	else 
		awaddr <= awaddr;
end

always @(posedge clk) begin
	if (awready_m_inf)
		awvalid <= 0;
	else if ((c_state == S11))
		awvalid <= 1;
	else
		awvalid <= 0;
end

always @(*) begin
	if (c_state == S12)
		wdata <= DO_L;
	else
		wdata <= 0;
end
always @(*) begin
	if (!rst_n)
		wvalid <= 0;
	else if (c_state == S12)
		wvalid <= 1;
	else
		wvalid <= 0;
end

always @(*) begin
	if ((c_state == S12) && (addr_cnt == 'd127))
		wlast <= 1;
	else
		wlast <= 0;
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n)
		bready <= 0;
	else if (bvalid_m_inf)
		bready <= 0;
	else if (awready_m_inf)
		bready <= 1;
	else
		bready <= bready;
end

// ------------------------------------------------
//               read & write location map
// ------------------------------------------------
always @(posedge clk or negedge rst_n) begin
	if (!rst_n)
		addr_cnt <= 0;
	else if (c_state == IDLE)
		addr_cnt <= 0;
	else if (rvalid_m_inf)
		addr_cnt <= addr_cnt + 1;
	else if ((c_state == S12)) begin
		if (wready_m_inf)
			addr_cnt <= addr_cnt + 1;
		else
			addr_cnt <= addr_cnt;
	end
	else
		addr_cnt <= 0;
end

always @(*) begin
	if (c_state == S2)
		A_L = addr_cnt;
	else if ((c_state == S7) || (c_state == S8))
		A_L = (path_y << 1) + path_x[5];
	else if (wready_m_inf) begin
		A_L = addr_cnt + 1;
	end
	else
		A_L = 0;
end

always @(*) begin
	if ((c_state == S2) || (c_state == S8))
		WEB_L = 'd0;
	else
		WEB_L = 'd1;
end

// assign index = path_x[4:0];
always @(*) begin
	if (c_state == S2)
		DI_L = rdata_m_inf;
	else if (c_state == S8) begin
		case (path_x[4:0])
			0 : DI_L = {DO_L[127:4], target_array[cur_net_id]};
			1 : DI_L = {DO_L[127:8], target_array[cur_net_id], DO_L[3:0]}; 
			2 : DI_L = {DO_L[127:12], target_array[cur_net_id], DO_L[7:0]};
			3 : DI_L = {DO_L[127:16], target_array[cur_net_id], DO_L[11:0]};
			4 : DI_L = {DO_L[127:20], target_array[cur_net_id], DO_L[15:0]};
			5 : DI_L = {DO_L[127:24], target_array[cur_net_id], DO_L[19:0]};
			6 : DI_L = {DO_L[127:28], target_array[cur_net_id], DO_L[23:0]};
			7 : DI_L = {DO_L[127:32], target_array[cur_net_id], DO_L[27:0]};
			8 : DI_L = {DO_L[127:36], target_array[cur_net_id], DO_L[31:0]};
			9 : DI_L = {DO_L[127:40], target_array[cur_net_id], DO_L[35:0]};
			10: DI_L = {DO_L[127:44], target_array[cur_net_id], DO_L[39:0]};
			11: DI_L = {DO_L[127:48], target_array[cur_net_id], DO_L[43:0]};
			12: DI_L = {DO_L[127:52], target_array[cur_net_id], DO_L[47:0]};
			13: DI_L = {DO_L[127:56], target_array[cur_net_id], DO_L[51:0]};
			14: DI_L = {DO_L[127:60], target_array[cur_net_id], DO_L[55:0]};
			15: DI_L = {DO_L[127:64], target_array[cur_net_id], DO_L[59:0]};
			16: DI_L = {DO_L[127:68], target_array[cur_net_id], DO_L[63:0]};
			17: DI_L = {DO_L[127:72], target_array[cur_net_id], DO_L[67:0]};
			18: DI_L = {DO_L[127:76], target_array[cur_net_id], DO_L[71:0]};
			19: DI_L = {DO_L[127:80], target_array[cur_net_id], DO_L[75:0]};
			20: DI_L = {DO_L[127:84], target_array[cur_net_id], DO_L[79:0]};
			21: DI_L = {DO_L[127:88], target_array[cur_net_id], DO_L[83:0]};
			22: DI_L = {DO_L[127:92], target_array[cur_net_id], DO_L[87:0]};
			23: DI_L = {DO_L[127:96], target_array[cur_net_id], DO_L[91:0]};
			24: DI_L = {DO_L[127:100], target_array[cur_net_id], DO_L[95:0]};
			25: DI_L = {DO_L[127:104], target_array[cur_net_id], DO_L[99:0]};
			26: DI_L = {DO_L[127:108], target_array[cur_net_id], DO_L[103:0]};
			27: DI_L = {DO_L[127:112], target_array[cur_net_id], DO_L[107:0]};
			28: DI_L = {DO_L[127:116], target_array[cur_net_id], DO_L[111:0]};
			29: DI_L = {DO_L[127:120], target_array[cur_net_id], DO_L[115:0]};
			30: DI_L = {DO_L[127:124], target_array[cur_net_id], DO_L[119:0]};
			31: DI_L = {target_array[cur_net_id], DO_L[123:0]};
			default: DI_L = 0;
		endcase
	end
	else
		DI_L = 0;
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n)
		map_count <= 0; 
	else if (c_state == IDLE)
		map_count <= 0;
	else if (A_L[0] == 1)
		map_count <= map_count + 1;
	else 
		map_count <= map_count;
end

// ------------------------------------------------
//               read & write weight map
// ------------------------------------------------
always @(*) begin
	// if ((c_state == S4) || (c_state == S5))
	// 	A_W = addr_cnt;
	// else 
	if ((c_state == S7))
		A_W = (path_y << 1) + path_x[5];
	else
		A_W = addr_cnt;
end

always @(*) begin
	if (((c_state == S4) || (c_state == S5)) && !first_iteration_done)
		WEB_W = 'd0;
	else
		WEB_W = 'd1; 
end
  
always @(*) begin
	if (((c_state == S4) || (c_state == S5)))
		DI_W = rdata_m_inf;
	else
		DI_W = 0;
end
// ------------------------------------------------
//                 reg location map
// ------------------------------------------------
generate
	for (i = 0; i < 32; i = i + 1) begin
		always @(*) begin
			if (rdata_m_inf[i*4 +: 4] != 0)
				location_converter[i] = 1;
			else
				location_converter[i] = 0;
		end
	end
endgenerate


always @(posedge clk) begin 
	case (c_state)
		S2: begin
			for (j = 0; j < 32; j = j + 1) begin
				if (!A_L[0]) location_map_reg[map_count][j] <= location_converter[j];
			end
			for (j = 0; j < 32; j = j + 1) begin
				if (A_L[0]) location_map_reg[map_count][32 + j] <= location_converter[j]; 
			end
		end 
		S3: begin
			location_map_reg[source_y_arry[cur_net_id]][source_x_arry[cur_net_id]] <= 'd3;
			location_map_reg[sink_y_arry[cur_net_id]][sink_x_arry[cur_net_id]] <= 'd0;
		end
		S4, S6: begin
			// macro area-----------------------
			for (j = 1; j < 63; j = j + 1) begin
				for (k = 1; k < 63; k = k + 1) begin
					if ((location_map_reg[j-1][k][1]) || (location_map_reg[j+1][k][1]) || (location_map_reg[j][k+1][1]) || (location_map_reg[j][k-1][1])) begin
						if (location_map_reg[j][k] == 0) location_map_reg[j][k] <= current_sequence;
					end
				end
			end
			// margin area-----------------------
			// first_col
			for (j = 1; j < 63; j = j + 1) begin
				if ((location_map_reg[j-1][0][1]) || (location_map_reg[j+1][0][1]) || (location_map_reg[j][1][1])) begin
					if (location_map_reg[j][0] == 0) location_map_reg[j][0] <= current_sequence;
				end
			end
			// last col
			for (j = 1; j < 63; j = j + 1) begin
				if ((location_map_reg[j-1][63][1]) || (location_map_reg[j+1][63][1]) || (location_map_reg[j][62][1])) begin
					if (location_map_reg[j][63] == 0) location_map_reg[j][63] <= current_sequence;
				end
			end
			// first row
			for (j = 1; j < 63; j = j + 1) begin
				if ((location_map_reg[1][j][1]) || (location_map_reg[0][j+1][1]) || (location_map_reg[0][j-1][1])) begin
					if (location_map_reg[0][j] == 0) location_map_reg[0][j] <= current_sequence;
				end
			end
			// last row
			for (j = 1; j < 63; j = j + 1) begin
				if ((location_map_reg[62][j][1]) || (location_map_reg[63][j+1][1]) || (location_map_reg[63][j-1][1])) begin
					if (location_map_reg[63][j] == 0) location_map_reg[63][j] <= current_sequence;
				end
			end
			//(0.0)
			if ((location_map_reg[1][0][1]) || (location_map_reg[0][1][1])) begin
				if (location_map_reg[0][0] == 0) location_map_reg[0][0] <= current_sequence;
			end
			// (0,63)
			if ((location_map_reg[1][63][1]) || (location_map_reg[0][62][1])) begin
				if (location_map_reg[0][63] == 0) location_map_reg[0][63] <= current_sequence;
			end
			// (63,0)
			if ((location_map_reg[62][0][1]) || (location_map_reg[63][1][1])) begin
				if (location_map_reg[63][0] == 0) location_map_reg[63][0] <= current_sequence;
			end
			// (63,63)
			if ((location_map_reg[62][63][1]) || (location_map_reg[63][62][1])) begin
				if (location_map_reg[63][63] == 0) location_map_reg[63][63] <= current_sequence;
			end
		end
		
		S8: begin
			location_map_reg[path_y][path_x] <= 'd1; 
		end
		S9: begin
			for (j = 0; j < 64; j = j + 1) begin
				for (k = 0; k < 64; k = k + 1) begin
					if (location_map_reg[j][k] != 1) location_map_reg[j][k] <= 0;
				end
			end
		end
		S10: begin
			location_map_reg[source_y_arry[cur_net_id]][source_x_arry[cur_net_id]] <= 'd3;
			location_map_reg[sink_y_arry[cur_net_id]][sink_x_arry[cur_net_id]] <= 'd0;
		end 
		default: begin
			for (j = 0; j < 64; j = j + 1) begin
				for (k = 0; k < 64; k = k + 1) begin
					location_map_reg[j][k] <= location_map_reg[j][k];
				end
			end
		end
	endcase
end
// ------------------------------------------------
//                  propagation
// ------------------------------------------------
assign propagate_done = (location_map_reg[sink_y_arry[cur_net_id]][sink_x_arry[cur_net_id]] != 0);

always @(*) begin
	if ((propagate_count == 0) || (propagate_count == 1)) 
		current_sequence = 'd2;
	else if ((propagate_count == 2) || (propagate_count == 3)) 
		current_sequence = 'd3;
	else
		current_sequence = 'd0;
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		propagate_count <= 0;
	end
	else if (c_state == IDLE)
		propagate_count <= 0;	
	else if (c_state == S9)
		propagate_count <= 0;	
	else if ((c_state == S4) || (c_state == S6))
		propagate_count <= propagate_count + 1;
	else 
		propagate_count <= propagate_count;
end
// ------------------------------------------------
//                     retrace
// ------------------------------------------------

assign down  = ((location_map_reg[path_y + 1][path_x] == retrace_target) && (path_y != 'd63));
assign up    = ((location_map_reg[path_y - 1][path_x] == retrace_target) && (path_y != 'd0));
assign right = ((location_map_reg[path_y][path_x + 1] == retrace_target) && (path_x != 'd63));
assign left  = ((location_map_reg[path_y][path_x - 1] == retrace_target) && (path_x != 'd0));

always @(posedge clk or negedge rst_n) begin
	if (!rst_n)
		path_x <= 'd0;
	else begin
		case (c_state)
			S4: begin
				path_x <= sink_x_arry[cur_net_id];
			end 
			S8: begin
				path_x <= next_path_x;
			end
		endcase
	end
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n)
		path_y <= 'd0;
	else begin
		case (c_state)
			S4: begin
				path_y <= sink_y_arry[cur_net_id]; 
			end 
			S8: begin
				path_y <= next_path_y;
			end
		endcase
	end
end

always @(*) begin
	if (down || up)
		next_path_x = path_x;
	else if (right)
		next_path_x = path_x + 1;
	else if (left) 
		next_path_x = path_x - 1;
	else
		next_path_x = path_x;
end


always @(*) begin
		if (down)
			next_path_y = path_y + 1;
		else if (up)
			next_path_y = path_y - 1;
		else if (right || left)
			next_path_y = path_y;
		else
			next_path_y = path_y;
end


always @(posedge clk) begin
	if ((c_state == S4) || (c_state == S6)) begin
		case (propagate_count)
			0: retrace_state <= 3;
			1: retrace_state <= 0;
			2: retrace_state <= 1;
			3: retrace_state <= 2;
			default: retrace_state <= 0;
		endcase
	end
	else if ((c_state == S8)) begin
		case (retrace_state)
			0: retrace_state <= 3;
			1: retrace_state <= 0;
			2: retrace_state <= 1;
			3: retrace_state <= 2;
			default: retrace_state <= 0;
		endcase
	end
	else
		retrace_state <= retrace_state;
end

always @(*) begin
	case (retrace_state)
		0: retrace_target = 3;
		1: retrace_target = 2;
		2: retrace_target = 2;
		3: retrace_target = 3;
		default: retrace_target = 0;
	endcase
end

// ------------------------------------------------
//                      OUTPUT
// ------------------------------------------------
always @(posedge clk or negedge rst_n) begin
	if (!rst_n)
		cost <= 'd0;
	else if (c_state == S1)
		cost <= 'd0;
	else if (c_state == S8) begin
		if ((path_x == source_x_arry[cur_net_id]) && (path_y == source_y_arry[cur_net_id]))
			cost <= cost;
		else if ((path_x == sink_x_arry[cur_net_id]) && (path_y == sink_y_arry[cur_net_id]))
			cost <= cost;
		else begin
			cost <= cost + DO_W[(path_x[4:0] * 4) +: 4];
		end
	end
	else 
		cost <= cost;
end

// ------------------------------------------------
//                     iteration
// ------------------------------------------------
always @(posedge clk) begin
	if (c_state == IDLE)
		first_iteration_done <= 0;
	else if (c_state == S9)
		first_iteration_done <= 1;
	else
		first_iteration_done <= first_iteration_done;
end
// ------------------------------------------------
//                      OUTPUT
// ------------------------------------------------


always @(posedge clk or negedge rst_n) begin
	if (!rst_n)
		busy <= 0;
	else if (c_state == IDLE)
		busy <= 0;
	else if (!in_valid)
		busy <= 1;
	else 
		busy <= 0;
end

endmodule




