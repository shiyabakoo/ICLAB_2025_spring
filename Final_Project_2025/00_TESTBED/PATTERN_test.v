//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   2021 ICLAB Spring Course
//   Final Project: Customized ISA Processor (CPU)
//   Author       : Shiuan-Yun Ding (mirkat.ding@gmail.com)
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   File Name   : PATTERN.v
//   Module Name : PATTERN
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
`ifdef RTL
    `define CYCLE_TIME 4.6
    `define RTL_GATE
`elsif GATE
    `define CYCLE_TIME 4.6
    `define RTL_GATE
`elsif CHIP
    `define CYCLE_TIME 4.6
    `define CHIP_POST 
`elsif POST
    `define CYCLE_TIME 4.6
    `define CHIP_POST 
`endif


`ifdef FUNC
`define MAX_WAIT_READY_CYCLE 2000
`endif
`ifdef PERF
`define MAX_WAIT_READY_CYCLE 100000
`endif


`include "../00_TESTBED/MEM_MAP_define.v"
`include "../00_TESTBED/pseudo_DRAM_data.v"
`include "../00_TESTBED/pseudo_DRAM_inst.v"

module PATTERN(
// global signals 
                clk,
              rst_n,
           IO_stall,
// axi write address channel 
         awid_s_inf,
       awaddr_s_inf,
       awsize_s_inf,
      awburst_s_inf,
        awlen_s_inf,
      awvalid_s_inf,
      awready_s_inf,
// axi write data channel 
        wdata_s_inf,
        wlast_s_inf,
       wvalid_s_inf,
       wready_s_inf,
// axi write response channel
          bid_s_inf,
        bresp_s_inf,
       bvalid_s_inf,
       bready_s_inf,
// axi read address channel 
         arid_s_inf,
       araddr_s_inf,
        arlen_s_inf,
       arsize_s_inf,
      arburst_s_inf,
      arvalid_s_inf,
      arready_s_inf, 
// axi read data channel
          rid_s_inf,
        rdata_s_inf,
        rresp_s_inf,
        rlast_s_inf,
       rvalid_s_inf,
       rready_s_inf 
);
//================================================================
//  PORT DECLARATION
//================================================================
parameter ID_WIDTH=4, DATA_WIDTH=16, ADDR_WIDTH=32, DRAM_NUMBER=2, WRIT_NUMBER=1;
// ---------------------------------------------------------------
// global signals 
output reg  clk, rst_n;
input IO_stall;
// ---------------------------------------------------------------
// axi write address channel 
input wire [WRIT_NUMBER * ID_WIDTH-1:0]        awid_s_inf;
input wire [WRIT_NUMBER * ADDR_WIDTH-1:0]    awaddr_s_inf;
input wire [WRIT_NUMBER * 3 -1:0]            awsize_s_inf;
input wire [WRIT_NUMBER * 2 -1:0]           awburst_s_inf;
input wire [WRIT_NUMBER * 7 -1:0]             awlen_s_inf;
input wire [WRIT_NUMBER-1:0]                awvalid_s_inf;
output wire [WRIT_NUMBER-1:0]               awready_s_inf;
// ---------------------------------------------------------------
// axi write data channel 
input wire [WRIT_NUMBER * DATA_WIDTH-1:0]     wdata_s_inf;
input wire [WRIT_NUMBER-1:0]                  wlast_s_inf;
input wire [WRIT_NUMBER-1:0]                 wvalid_s_inf;
output wire [WRIT_NUMBER-1:0]                wready_s_inf;
// ---------------------------------------------------------------
// axi write response channel
output wire [WRIT_NUMBER * ID_WIDTH-1:0]         bid_s_inf;
output wire [WRIT_NUMBER * 2 -1:0]             bresp_s_inf;
output wire [WRIT_NUMBER-1:0]                 bvalid_s_inf;
input wire [WRIT_NUMBER-1:0]                  bready_s_inf;
// ---------------------------------------------------------------
// axi read address channel 
input wire [DRAM_NUMBER * ID_WIDTH-1:0]       arid_s_inf;
input wire [DRAM_NUMBER * ADDR_WIDTH-1:0]   araddr_s_inf;
input wire [DRAM_NUMBER * 7 -1:0]            arlen_s_inf;
input wire [DRAM_NUMBER * 3 -1:0]           arsize_s_inf;
input wire [DRAM_NUMBER * 2 -1:0]          arburst_s_inf;
input wire [DRAM_NUMBER-1:0]               arvalid_s_inf;
output wire [DRAM_NUMBER-1:0]              arready_s_inf;
// ---------------------------------------------------------------
// axi read data channel
output wire [DRAM_NUMBER * ID_WIDTH-1:0]         rid_s_inf;
output wire [DRAM_NUMBER * DATA_WIDTH-1:0]     rdata_s_inf;
output wire [DRAM_NUMBER * 2 -1:0]             rresp_s_inf;
output wire [DRAM_NUMBER-1:0]                  rlast_s_inf;
output wire [DRAM_NUMBER-1:0]                 rvalid_s_inf;
input wire [DRAM_NUMBER-1:0]                  rready_s_inf;
// ---------------------------------------------------------------
//================================================================
//  integer
//================================================================
integer color_stage = 0, color, r = 5, g = 0, b = 0;
integer patcount, golden_pc, golden_curr_pc, cycles, total_cycles, offset=16'h1000;
integer i, j, temp_address_int;
//================================================================
//   Wires & Registers 
//================================================================
reg signed [15:0] golden_reg[0:15];
reg signed [15:0] golden_DRAM_data[0:2047];
// 
reg [15:0] golden_inst;
reg [2:0] golden_opcode;
reg [3:0] golden_rs, golden_rt, golden_rd;
reg golden_func;
reg signed [4:0] golden_immediate;
reg [15:0] golden_address;
reg [15:0] temp_address;
//================================================================
//  clock
//================================================================
always  #(`CYCLE_TIME/2.0)  clk = ~clk ;
initial clk = 0 ;
//================================================================
//   DRAM 
//================================================================
pseudo_DRAM_data u_DRAM_data(
// global signals 
      .clk(clk),
      .rst_n(rst_n),
// axi write address channel 
      .awid_s_inf(   awid_s_inf[3:0]  ),
    .awaddr_s_inf( awaddr_s_inf[31:0] ),
    .awsize_s_inf( awsize_s_inf[2:0]  ),
   .awburst_s_inf(awburst_s_inf[1:0]  ),
     .awlen_s_inf(  awlen_s_inf[6:0]  ),
   .awvalid_s_inf(awvalid_s_inf[0]    ),
   .awready_s_inf(awready_s_inf[0]    ),
// axi write data channel 
     .wdata_s_inf(  wdata_s_inf[15:0] ),
     .wlast_s_inf(  wlast_s_inf[0]    ),
    .wvalid_s_inf( wvalid_s_inf[0]    ),
    .wready_s_inf( wready_s_inf[0]    ),
// axi write response channel
       .bid_s_inf(    bid_s_inf[3:0]  ),
     .bresp_s_inf(  bresp_s_inf[1:0]  ),
    .bvalid_s_inf( bvalid_s_inf[0]    ),
    .bready_s_inf( bready_s_inf[0]    ),
// axi read address channel 
      .arid_s_inf(   arid_s_inf[3:0]  ),
    .araddr_s_inf( araddr_s_inf[31:0] ),
     .arlen_s_inf(  arlen_s_inf[6:0]  ),
    .arsize_s_inf( arsize_s_inf[2:0]  ),
   .arburst_s_inf(arburst_s_inf[1:0]  ),
   .arvalid_s_inf(arvalid_s_inf[0]    ),
   .arready_s_inf(arready_s_inf[0]    ), 
// axi read data channel 
       .rid_s_inf(    rid_s_inf[3:0]  ),
     .rdata_s_inf(  rdata_s_inf[15:0] ),
     .rresp_s_inf(  rresp_s_inf[1:0]  ),
     .rlast_s_inf(  rlast_s_inf[0]    ),
    .rvalid_s_inf( rvalid_s_inf[0]    ),
    .rready_s_inf( rready_s_inf[0]    ) 
);

pseudo_DRAM_inst u_DRAM_inst(
// global signals 
      .clk(clk),
      .rst_n(rst_n),
// axi read address channel 
      .arid_s_inf(   arid_s_inf[7:4]   ),
    .araddr_s_inf( araddr_s_inf[63:32] ),
    .arlen_s_inf(  arlen_s_inf[13:7]   ),
    .arsize_s_inf( arsize_s_inf[5:3]   ),
   .arburst_s_inf(arburst_s_inf[3:2]   ),
   .arvalid_s_inf(arvalid_s_inf[1]     ),
   .arready_s_inf(arready_s_inf[1]     ), 
// axi read data channel 
       .rid_s_inf(    rid_s_inf[7:4]   ),
     .rdata_s_inf(  rdata_s_inf[31:16] ),
     .rresp_s_inf(  rresp_s_inf[3:2]   ),
     .rlast_s_inf(  rlast_s_inf[1]     ),
    .rvalid_s_inf( rvalid_s_inf[1]     ),
    .rready_s_inf( rready_s_inf[1]     ) 
);
//================================================================
//  initial
//================================================================
initial begin
    rst_n = 1 ;
    // reset
    force clk = 0 ;
    // SPEC: There is only 1 reset before the first pattern, thus, your design must be able to reset automatically. 
    reset_task;
    read_DRAM_data_task;
    total_cycles = 0 ;
    //
    @(negedge clk);
    golden_pc = 16'h1000 - 2 ;
    for( patcount=1 ; patcount<=1000 ; patcount=patcount+1 ) begin
        // 
        golden_pc = golden_pc + 2 ;
        golden_curr_pc = golden_pc ;
        golden_inst = { u_DRAM_inst.DRAM_r[golden_curr_pc+1] , u_DRAM_inst.DRAM_r[golden_curr_pc] } ;
        // $display("DRAM_inst @%2x : %4x", golden_curr_pc, golden_inst);
        golden_opcode  = golden_inst[15:13] ;
        golden_rs      = golden_inst[12:9] ;
        golden_rt      = golden_inst[8:5] ;
        golden_rd      = golden_inst[4:1] ;
        golden_func    = golden_inst[0] ;
        golden_immediate = golden_inst[4:0] ;
        golden_address = golden_inst[12:0];     // automatically pad '000' in front
        // 
        // $display("golden_opcode   = %3b", golden_opcode  );
        // $display("golden_rs       = %d", golden_rs      );
        // $display("golden_rt       = %d", golden_rt      );
        // $display("golden_rd       = %d", golden_rd      );
        // $display("golden_func     = %b", golden_func    );
        // $display("golden_immediate = %d", golden_immediate);
        // $display("golden_address  = %4x", golden_address );
        // 
        temp_address = (golden_reg[golden_rs]+golden_immediate)*2 + offset ;
        temp_address_int = (temp_address - 16'h1000 )/2 ;
        // 
        if (golden_opcode===3'b000 && golden_func===1'b0)
            Add_task;
        else if (golden_opcode===3'b000 && golden_func===1'b1)
            Sub_task;
        else if (golden_opcode===3'b001 && golden_func===1'b0)
            SetLessThan_task;
        else if (golden_opcode===3'b001 && golden_func===1'b1)
            Mult_task;
        else if (golden_opcode===3'b010)
            Load_task;
        else if (golden_opcode===3'b011)
            Store_task;
        else if (golden_opcode===3'b100)
            BranchOnEqual_task;
        else if (golden_opcode===3'b101)
            Jump_task;
        else begin
            $display("Error: Wrong instruection format in PATTERN NO.%4d\t\tgolden_pc NO.%4x", patcount+1, golden_curr_pc);
            $display("%16b", golden_inst);
        end
        // SPEC: The test pattern will check the value in all registers at clock negative edge if stall is low. 
        wait_IO_stall_task;
        // 
        case(color_stage)
            0: begin
                r = r - 1;
                g = g + 1;
                if(r == 0) color_stage = 1;
            end
            1: begin
                g = g - 1;
                b = b + 1;
                if(g == 0) color_stage = 2;
            end
            2: begin
                b = b - 1;
                r = r + 1;
                if(b == 0) color_stage = 0;
            end
        endcase
        color = 16 + r*36 + g*6 + b;
        if(color < 100) $display("\033[38;5;%2dmPASS\tPATTERN NO.%4d\t\tgolden_pc NO.%4x\033[00m\n", color, patcount, golden_curr_pc);
        else $display("\033[38;5;%3dmPASS\tPATTERN NO.%4d\t\tgolden_pc NO.%4x\033[00m\n", color, patcount, golden_curr_pc);
        // print_reg_task;
    end
    YOU_PASS_task;
    $finish;
end
//================================================================
//  check task
//================================================================
task wait_IO_stall_task ; begin
    cycles = 0 ;
    while(IO_stall===1) begin
        cycles = cycles + 1 ;
        if (cycles==`MAX_WAIT_READY_CYCLE) begin
            fail;
            // Spec. 6.  
            // IO_stall signal cannot be continuous high for 2000 cycles during functionality check, 
            // cannot be continuous high for 100000 during performance check. 
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            $display ("                                                                SPEC 6 FAIL!                                                                ");
            $display ("                                          The execution latency is limited in %d cycles.                                                    ", `MAX_WAIT_READY_CYCLE);
            $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
            #(100);
            $finish;
        end
        @(negedge clk);        
    end
    total_cycles = total_cycles + cycles ;
    // 
    check_reg_task;
    // SPEC: The test pattern will check the value in data DRAM every 10 instruction at clock negative edge if IO_stall is low. 
    if (patcount%10==0)
        check_DRAM_data_task;
    // SPEC: Pull high when core is busy. It should be low for one cycle whenever  you  finished  an  instruction.
    @(negedge clk);
    if (IO_stall===0) begin
        fail;
        $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        $display ("                                                                SPEC ? FAIL!                                                                ");
        $display ("                                 IO_stall should be low for ONE cycle whenever you finished an instruction.                                 ");
        $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
        #(100);
        $finish;
    end
end endtask

task check_reg_task ; begin
    print_reg_task;
    if( My_CPU.core_r0!==golden_reg[0] || My_CPU.core_r4!==golden_reg[4] || My_CPU.core_r8 !==golden_reg[ 8] || My_CPU.core_r12!==golden_reg[12] ||
        My_CPU.core_r1!==golden_reg[1] || My_CPU.core_r5!==golden_reg[5] || My_CPU.core_r9 !==golden_reg[ 9] || My_CPU.core_r13!==golden_reg[13] ||
        My_CPU.core_r2!==golden_reg[2] || My_CPU.core_r6!==golden_reg[6] || My_CPU.core_r10!==golden_reg[10] || My_CPU.core_r14!==golden_reg[14] ||
        My_CPU.core_r3!==golden_reg[3] || My_CPU.core_r7!==golden_reg[7] || My_CPU.core_r11!==golden_reg[11] || My_CPU.core_r15!==golden_reg[15]) begin
        fail;
        $display ("--------------------------------------------------------------------------------------------");
        $display ("                                           FAIL!                                            ");
        $display ("                                 core_reg is/are not equal.                                 ");        
        print_reg_task;
        $display ("--------------------------------------------------------------------------------------------");
        #(100);
        $finish; 
    end
end endtask

task check_DRAM_data_task ; begin
    j = 0 ;
    for( i=16'h1000 ; i<16'h2000 ; i=i+2 ) begin
        if (golden_DRAM_data[j]!=={ u_DRAM_data.DRAM_r[i+1] , u_DRAM_data.DRAM_r[i] }) begin
            fail;
            $display ("--------------------------------------------------------------------------------------------");
            $display ("                                           FAIL!                                            ");
            $display ("                                 DRAM_data is/are not equal.                                ");        
            $display ("      golden_DRAM_data[%4h(%4d)]: %4x(%8d) , your_DRAM_data[%4h(%4d)]: %4x(%8d)               ", i, j, golden_DRAM_data[j], golden_DRAM_data[j], i, j, { u_DRAM_data.DRAM_r[i+1] , u_DRAM_data.DRAM_r[i] }, { u_DRAM_data.DRAM_r[i+1] , u_DRAM_data.DRAM_r[i] });        
            $display ("--------------------------------------------------------------------------------------------");
            #(100);
            // $finish; 
        end
        j = j + 1 ;
    end
end endtask

task print_reg_task ; begin
    $display ("      core_r0 = %4d  golden_reg[0] = %4d  ,  core_r8  = %4d  golden_reg[8 ] = %4d    ", My_CPU.core_r0,  golden_reg[0], My_CPU.core_r8 , golden_reg[8 ]);
    $display ("      core_r1 = %4d  golden_reg[1] = %4d  ,  core_r9  = %4d  golden_reg[9 ] = %4d    ", My_CPU.core_r1,  golden_reg[1], My_CPU.core_r9 , golden_reg[9 ]);
    $display ("      core_r2 = %4d  golden_reg[2] = %4d  ,  core_r10 = %4d  golden_reg[10] = %4d    ", My_CPU.core_r2,  golden_reg[2], My_CPU.core_r10, golden_reg[10]);
    $display ("      core_r3 = %4d  golden_reg[3] = %4d  ,  core_r11 = %4d  golden_reg[11] = %4d    ", My_CPU.core_r3,  golden_reg[3], My_CPU.core_r11, golden_reg[11]);
    $display ("      core_r4 = %4d  golden_reg[4] = %4d  ,  core_r12 = %4d  golden_reg[12] = %4d    ", My_CPU.core_r4,  golden_reg[4], My_CPU.core_r12, golden_reg[12]);
    $display ("      core_r5 = %4d  golden_reg[5] = %4d  ,  core_r13 = %4d  golden_reg[13] = %4d    ", My_CPU.core_r5,  golden_reg[5], My_CPU.core_r13, golden_reg[13]);
    $display ("      core_r6 = %4d  golden_reg[6] = %4d  ,  core_r14 = %4d  golden_reg[14] = %4d    ", My_CPU.core_r6,  golden_reg[6], My_CPU.core_r14, golden_reg[14]);
    $display ("      core_r7 = %4d  golden_reg[7] = %4d  ,  core_r15 = %4d  golden_reg[15] = %4d    ", My_CPU.core_r7,  golden_reg[7], My_CPU.core_r15, golden_reg[15]);
end endtask
//================================================================
//  CPU task
//================================================================
task Add_task ; begin
    $display("Add_task");
    golden_reg[golden_rd] = golden_reg[golden_rs] + golden_reg[golden_rt] ;
end endtask

task Sub_task ; begin
    $display("Sub_task");
    golden_reg[golden_rd] = golden_reg[golden_rs] - golden_reg[golden_rt] ;
end endtask

task SetLessThan_task ; begin
    $display("SetLessThan_task");
    if (golden_reg[golden_rs]<golden_reg[golden_rt])
        golden_reg[golden_rd] = 1 ;
    else 
        golden_reg[golden_rd] = 0 ;
end endtask

task Mult_task ; begin
    $display("Mult_task");
    golden_reg[golden_rd] = golden_reg[golden_rs] * golden_reg[golden_rt] ;
end endtask

task Load_task ; begin
    $display("Load_task");
    golden_reg[golden_rt] = golden_DRAM_data[temp_address_int];
end endtask

task Store_task ; begin
    $display("Store_task");
    golden_DRAM_data[temp_address_int] = golden_reg[golden_rt] ;
end endtask

task BranchOnEqual_task ; begin
    $display("BranchOnEqual_task");
    if (golden_reg[golden_rs]===golden_reg[golden_rt])
        golden_pc = golden_curr_pc + golden_immediate*2 ;        
end endtask

task Jump_task ; begin
    $display("Jump_task");
    golden_pc = golden_address - 2 ;
end endtask
//================================================================
//  env task
//================================================================
task read_DRAM_data_task ; begin
    j = 0 ;
    for( i=16'h1000 ; i<16'h2000 ; i=i+2 ) begin
        golden_DRAM_data[j] = { u_DRAM_data.DRAM_r[i+1] , u_DRAM_data.DRAM_r[i] } ;
        // $display("%x(%4d): %4x", i, j, golden_DRAM_data[j]);
        j = j + 1 ;
    end
end endtask

task reset_task ; begin
    #(10); rst_n = 0 ;
    // SPEC: All the registers should be zero after the reset signal is asserted. 
    #(10);
    for( i=0 ; i<16 ; i=i+1 )
        golden_reg[i] = 0 ;
    check_reg_task;
    // 
    #(10); rst_n = 1 ; 
    #(100); release clk;
end endtask

//================================================================
//  pass/fail task0
//================================================================
task YOU_PASS_task ; begin
$display ("----------------------------------------------------------------------------------------------------------------------");
$display ("                                                  Congratulations!                                                    ");
$display ("                                           You have passed all patterns!                                              ");
$display ("                                                                                                                      ");
$display ("                                        Your execution cycles   = %5d cycles                                          ", total_cycles);
$display ("                                        Your clock period       = %.1f ns                                             ", `CYCLE_TIME);
$display ("                                        Total latency           = %.1f ns                                             ", total_cycles*`CYCLE_TIME );
$display ("----------------------------------------------------------------------------------------------------------------------");
$finish;    
end endtask

task fail ; begin
$display(":( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( FAIL :( ");
end endtask

endmodule

// `ifdef RTL
//     `define CYCLE_TIME 4.6
// 	`define RTL_GATE
// `elsif GATE
//     `define CYCLE_TIME 4.6
// 	`define RTL_GATE
// `elsif CHIP
//     `define CYCLE_TIME 4.6
//     `define CHIP_POST 
// `elsif POST
//     `define CYCLE_TIME 4.6
//     `define CHIP_POST 
// `endif

//     `define CYCLE_TIME 4.6

// `ifdef FUNC 
// `define PAT_NUM 828
// `define MAX_WAIT_READY_CYCLE 2000
// `endif
// `ifdef PERF
// `define PAT_NUM 828
// `define MAX_WAIT_READY_CYCLE 100000
// `endif


// `include "../00_TESTBED/MEM_MAP_define.v"
// `include "../00_TESTBED/pseudo_DRAM_data.v"
// `include "../00_TESTBED/pseudo_DRAM_inst.v"

// module PATTERN(
//     			clk,
// 			  rst_n,
// 		   IO_stall,


//          awid_s_inf,   
//        awaddr_s_inf,
//        awsize_s_inf,
//       awburst_s_inf,
//         awlen_s_inf,
//       awvalid_s_inf,
//       awready_s_inf,
                    
//         wdata_s_inf,
//         wlast_s_inf,
//        wvalid_s_inf,
//        wready_s_inf,
                    
//           bid_s_inf,
//         bresp_s_inf,
//        bvalid_s_inf,
//        bready_s_inf,
                    
//          arid_s_inf,
//        araddr_s_inf,
//         arlen_s_inf,
//        arsize_s_inf,
//       arburst_s_inf,
//       arvalid_s_inf,
                    
//       arready_s_inf, 
//           rid_s_inf,
//         rdata_s_inf,
//         rresp_s_inf,
//         rlast_s_inf,
//        rvalid_s_inf,
//        rready_s_inf 
//     );

// //---------------------------------------------------------------------
// //   PORT DECLARATION          
// //---------------------------------------------------------------------
// parameter ID_WIDTH=4, DATA_WIDTH=32, ADDR_WIDTH=32, DRAM_NUMBER=2, WRIT_NUMBER=1;

// output reg			  clk,rst_n;
// input				IO_stall;

// // axi write address channel 
// input wire [WRIT_NUMBER * ID_WIDTH-1:0]        awid_s_inf;
// input wire [WRIT_NUMBER * ADDR_WIDTH-1:0]    awaddr_s_inf;
// input wire [WRIT_NUMBER * 3 -1:0]            awsize_s_inf;
// input wire [WRIT_NUMBER * 2 -1:0]           awburst_s_inf;
// input wire [WRIT_NUMBER * 7 -1:0]             awlen_s_inf;
// input wire [WRIT_NUMBER-1:0]                awvalid_s_inf;
// output wire [WRIT_NUMBER-1:0]               awready_s_inf;
// // axi write data channel 
// input wire [WRIT_NUMBER * DATA_WIDTH-1:0]     wdata_s_inf;
// input wire [WRIT_NUMBER-1:0]                  wlast_s_inf;
// input wire [WRIT_NUMBER-1:0]                 wvalid_s_inf;
// output wire [WRIT_NUMBER-1:0]                wready_s_inf;
// // axi write response channel
// output wire [WRIT_NUMBER * ID_WIDTH-1:0]         bid_s_inf;
// output wire [WRIT_NUMBER * 2 -1:0]             bresp_s_inf;
// output wire [WRIT_NUMBER-1:0]             	  bvalid_s_inf;
// input wire [WRIT_NUMBER-1:0]                  bready_s_inf;
// // -----------------------------
// // axi read address channel 
// input wire [DRAM_NUMBER * ID_WIDTH-1:0]       arid_s_inf;
// input wire [DRAM_NUMBER * ADDR_WIDTH-1:0]   araddr_s_inf;
// input wire [DRAM_NUMBER * 7 -1:0]            arlen_s_inf;
// input wire [DRAM_NUMBER * 3 -1:0]           arsize_s_inf;
// input wire [DRAM_NUMBER * 2 -1:0]          arburst_s_inf;
// input wire [DRAM_NUMBER-1:0]               arvalid_s_inf;
// output wire [DRAM_NUMBER-1:0]              arready_s_inf;
// // -----------------------------
// // axi read data channel 
// output wire [DRAM_NUMBER * ID_WIDTH-1:0]         rid_s_inf;
// output wire [DRAM_NUMBER * DATA_WIDTH-1:0]     rdata_s_inf;
// output wire [DRAM_NUMBER * 2 -1:0]             rresp_s_inf;
// output wire [DRAM_NUMBER-1:0]                  rlast_s_inf;
// output wire [DRAM_NUMBER-1:0]                 rvalid_s_inf;
// input wire [DRAM_NUMBER-1:0]                  rready_s_inf;
// // -----------------------------


// `protected
// 7&U9_5]OWZ/&dJ)fWb?/FJCLPTMHLV6ZY=.CbQb1DF>=>4N4NC/4.)RG[4L]K;.9
// gb(@I.(J8-WfZPc7++,>;JXJB_/GY.+<=WW6S@eWBAGE-_YEBM?[Ye[>UJ[e48IO
// W4AT-F:N8O[H7@/^a9,U&0bAM6ca&7c/\gG7-:U9E&/O&RB0YfC?U+ZJAF)/@WP(
// cYK#K;R&,??JOC&D8&+DKW<ZabCACW>)LPF.Za#S6>H<ZJWUFQPR/9W[NE,ac)^]
// Cee4_X9e:Bge<\e[;VBN1GC94fIWZO:K3^C1^1=SCD8.+TWT:N\/V_>=bJ4WDS,]
// AaPXI4-TQc.GA&5?J0SbBbSNU,I.S:YgC+YdR2TG1WS]bI@2T2eV.N;cE4]^,757
// ()QA[=gD#+USW1;f5V?:,+fU\RC0YdLOTIBIX+(9I:Dg=.^:BT,8VWF#NK0HHS1<
// YJE7:3b)-H<S?X\RV<K/E(Qf[.36dQ_GPP#_]1?)5cbE-HGV:fUJ7G)cF/0J4Q/9
// 6]KC9G./#KH_KHb/[C;1P2\O.<6Z@D;7E_b5H&EKAPYXGS=aaPOaKKMc^W\Wg/Ke
// 2/9Q6U]C@H9+F(OJWRK[eV@g2C/70AGb:4E(L4=dg=C_]II<^][S9NS)QT)<dULb
// B5?c\X#1@=0DD4W>5&[2>I/gE<P\KcL):QWa#efQ+]PJ4RA+?KME/R/V22]VETTR
// RX5W?FBDJ??e)6PNb6MB/BU;.H2f0:96#YAg>f_0+6TOYP^X)DSMX@N>99T@A3cQ
// NbRcb,<W.D3/C3D2IL+gIAEC6CcS@/(6/VI,4d1XLLD[c^caLWGGLWEGeG?TNK.=
// OHg@VZOJ;0ZEBY]8f+A8;6JCGO>fCZINYRPKf]I=P]\4VH3a1ZUV)d^T3LB,M@C0
// ^^/=#ba8FfXS-U-1WV/cc_Pg64aF5f+N7c0P\#\0W-YH^\/Ld7+Odg/;RbW\b6@#
// V6eFY9B[(2:G799UN>,Dd3d.=e+16G;\5?S2Ff-@OHd5MgBJT93)GOg#BV(1ZBE9
// JP286Z[<DX/A0;7aBRK-1MK>]V2C((]0WE[+8?c=C0fb0UMYW=?d9\6CGD@QM5(c
// 3/((TH(7SI#PK.[f3cMKH0[-=P?f3\dX^Z/UGU:_\;-MAW6KfM_IMgQMUTU[P8_d
// ge+U#7.?Oe:3V@^&&ZbZF\=5LFU@C5=\cOJ?H><@F^&A+P;E5Z4G25D@8G;2WL]X
// a5@R9?]_=X@4\2/=6N4PK0I(NL.?1L>Ya9P0]03M1JK-C=Pa-=Z?WT/?K<<?(0<f
// b])Q=:UHT77NANN(?WJ2?TK5L_.AD?@]1OG#bVUcHfb&N)99:L4QYOOaT:V4XD/C
// Re@ZBL2cI_LbT\F,EL9OYb^-]eT>b]+7QYL[?01<b:=(5HbKS./6f.Q(F^g0c[7U
// 49cTP#ZJE\L:BAT9]&1LeH2XA8)FW.Q]gIF]BW(4F[(YJS-ZW(-NR+..L28,LOYX
// >KW>g,J(QV+BWO3W\+\4KKBW;bZ:NRZXMG(:(I-_VT7#XQ?]Z]ASR9g1GM>?YbT]
// /Zd<6\8>Z3VQUD35GFI>,NgG#PbX>a-/W^d@D-DF>MQ^729,IF]W?EcW/C-PHMYb
// 22<XKGSGQSJe@1(\W,(22H&5W555-:1E9>CHbO9bE/cQ7+SJ5_:I_L_\Q&1)96ZE
// URZQD&?>a41>J8e[Jd_^@M8FL]?UO,?3YTT+PBO<dI]4]d8NKQ:A/SB3BfF\FaZ6
// \?d<@T:FTL[A[LX:12c_eO?S1SgIOaZDJ.2HP(Qd+8^#(FTOXL;>e5,CP&d46&Z;
// LHYER6JEVV)P+dcRZ,dY[H4)b16bA5JdE?fQRdLTCQ^FO,U;X18;R?I-@0CJfdR5
// ^5=b>/EfZ4A\Oc\HASNOF/7AbW-.\H+=2c2_fBdB[8;->19D.\?&U\^3]D\_S?bB
// 6@cKB:b58J)K5c:@HE/[AfUYOa(C24JCG-8P=@#[dBGTSae4[O2ROb1^\X0L7Y<R
// ,Y<12L7H3-@?bH<\1_@eLWgYT->YH/XCG03OFN/#bVDWISDI(RN+X_8LeG/4=f6?
// 0X\Y+Q,0&89[e@3JAJ&f_A<QdVD]fI;V.&EO&5;N>F.cSdd&IX;Y(57I\b<^=V5.
// C39.f-D]@Q/^TK;bCV(g(aJ<R[F.)RS]PQOe+F5O=YeTJH-D4e3/F+F3VDd]Z?e9
// ,0Ja;PI^NT7R.DE87F7gKRbJ>Da>Dc)CEf,F_cNZJ#2:4U=/^,EEb)5<&:S)dFf(
// XQc##;)YcCB,[HeU0>&V-D._5,XO-YQfc:6)H4BWg,K8;RbO?eb99H8fN1g5/W03
// 8V9Of>,1?4E&PbOMPQ47a\8P8Xg(MEe.FcOF-a)a2+3<cV+?d+P49;ICg3O6CZG)
// _V9,\fGGgNcR/3+3[H4dGMFQ?@/Q@)e?[IRP-DS7EIJV:BQ=GGEgDZ<Q0\+.2Q.B
// 0JF3/S8H^EfRX);NcHd]/+@c8a.B1O:FF/a5H;F?ddGMQ(9H4e[=[<@3E:5\.(5)
// ]XM+FVY^2.[b17+Q:SG]N]65>6\e2AF5R/PM+9cNZ5:Q0X5QUQQFC@\f6Q?fc(3)
// -0ET59NZ037=8HX3&H1<YK,-gU@<C4Rf>#,D3)17De5c84@eG;?;Q(H(HcH12<+L
// OY>QB>ZP#K<5JQ\AFF7HHMaMgg4Pc]&GO,dHcZGS;UBHV,VVO+Nbd3g6VKaNb5.&
// )R&X.<-Pb4782gZQ622BE3^)N1D#?Z)>PbIbS=V:TQ>YL_;(:WFTDSKHWM7\1/&0
// X2+MPY&BIT?=A<M^Y_L0-AgVQT@+=aV+\aF4[8EUJ,+6P79(3^-E-INZIK8EPa70
// a_HN6A3OfB?YUIgKU;B)\CZX=dfbI@?R::N;g@26+LCATc[2X;M^K9U6Qb+cA]Ab
// 4FZCJTU?4-EJ2Ae)94)^?),;J>5UITe4._PXTK)G\bN<e;f:4Z4ZAeM8Na3NO0MQ
// 6.PM_cRcUg978I-1.NM_U?64<b]]fG\&UXX;28]EI_e&_=?:7Jg)Y9#KAN?-Y1>?
// D_,409CT8R#bI.+D4:4ZV6FWIK?,I\DePd,FRNZ/#\&)N8P5M[5Y6aYLF>C+ZF\0
// .\CQP1dMYf?XcU2O+#[?F1,93gE,,6U^81-5^@3LdSO+d-3a^BDXA>0XAT2MM47:
// _T6Ue^8)+A#@fg>#6+N5CZ+A>(&W;H3EM)E2D\;8K>;@JZ0U9)_U6Y-&5W-P3:KM
// A4G^WXK,If>c;C1);e2B@^8SZ(]<H[(,=S@W1]\Kf4B2G[O_YW^:B5Ma.M]>^ZSb
// WV=KVU+57.N^8<^W3I3>/P?]U+1N_\BFd7,@3XG.MD6_.>LE&.M-A(e5:QGJTeA,
// +:=ZeB[DbR1IU_aZg&>G/c[/&.;eZW/W)&FU1W)OB@A&#HTM5F.XRG&EGA<ITU#\
// HVK(#d\V[PK<6fAf)WCAbDMP3G]D\_VJ8>\=c46S:OAP,IDJZ<T&<6[^?VbHS;QP
// _M\\493g]E^PAZ_,/TA]LMULGL[GJ?(g0E[HX7c5//^F283AKF8T&4LT=,QTNR5T
// CdN#BQ.EMAO82TGU02,aCR7\[XWT^c>e36eU#AMR08][=_@ea5Pd_&f9I/+,aU&G
// \Afg-ZTEUWU]f<40DSK1L\M4\&[J)eKde>^R_BbfJDe[a]RTYK&?-DBS-/+HF\Aa
// 4MT\5ZTJ^#]>24Q=N+f(GVEB>F@edBcc>[#<-aLOS\B.GNU&WE&>&CD1TVOE,R-I
// WEL&7^GKAGA0G^H(/I=7B=ba22Qcc)WLOE8-F/(F_Sg_\@Q1\^BWcc;g?O;_Y6^d
// F8JAM@KZ)/?)^Q#GRB7V[<_;cD;75PYdNZd@PT6J[(\IXA@SXJH(<^/\4Z6c@COY
// XI6Mb/V]ZR1D#d3K=X0:=5bGc?[78/=?8QQWB]_JN^757Lg<eRbI@]]=69QJHWb\
// ;U7[]Z,YC5EEIA@XYX\:INAO;eI+@3(.)\gU@D#XLF&?60PQ835AV^:Z@99+CC<V
// I+@.H-2R.8Y:3,.;[0#0bEeDN,\f7g.2(-A-RX]eNHVEN.YLZD9JU^D]>+L.<9S8
// ,#a2FbK<-^+8/g3?JEN],K<-G6S3-T6=2;:P;):W?G5Gbe,W.A,cM3[+&\>b.fT_
// AbFNEFY>J^^[XGgN(fJ/>LFU(R_:FQ_Q[^<#@Odad>?TX6#]15IJB</Xa3-1,g+\
// +V[4f-6>C/PEgP2A(&5<:,,&WP0aLO1K.[d0HN,#/@YZ3M:/HBIdUA7LCN5HHNe[
// aa/\Xc90T9HC&c=LY]2_YKcDF\JIZbKc<U)9;I4C7JWDJ7CZO-c#dSYZK85>612\
// <OGDH.3)CUFaW6><fE@c5#Ac6Y3@Y(J9>B,2DE9c0+[NPC.9PZce3I9:NZ@#X26_
// BE=FE126cRZFabD>95P;QJ+NSXJcAOKJ,RL9>eL.O_/RUA7bEgZ=d>dH]CMT#H?e
// VO(&FE&,\END/9Q[d\B:BZ.R)<;EFK9FQ4G\.1=5&ZV_Aa>6F,^g1HDS)OIHD[39
// DXF;VDI9gE=@3UNPHWY09GKg3Ka@GY2PTGQ@IV85J^N3]AX6Xa_JQgXYZF5U))fC
// g\aPK#K5&(QY.6b-#4;[TJ_d1E_1IXN<GV==IBBGBW;2(<Y5bELDBSG?5M:fc15V
// XH.DJJG/5f-J1(YfW-TaJ>VH:)S#59=TQZ)e@4b^SY59>F&LgeU7FOGQT.X97FPM
// S.bM;eb>;RWV6EW[2BF#XgD1\aW-SES+?ZRS3@[RY/_RA3SN\VV<#\;/0^NLY6Nb
// a4W)LDKaP)/bAS0Q,T3ZS/5c<9d?#HHG\-6M4R??@K_9XX[c2aAc&cT&^cGe0OZG
// <RbDKDGG(I,&;AX9//5L)K0BXUBZ7V=BLgLNX3S;I,AU3+Q8A6S#CbbW,eLW2AM&
// 1JEE<<^GHK-]/1HZ-dg267YZEZ-b/\G4bIQeGSS/G.+1Qa\K>1Y2ERFFF[?:F88/
// \BEACI#:WJA5<>7#@e[UQN@,>.V?7b\E?&cc)T-K<9L]XSe44g@I0J45fRL=?8XC
// ZRLON>)DJI5IKX^8\T81eZ+&IK,]N3^QV+RHD6d)S-=@V0&6?+Dc]4.d2V=DH73B
// T?+<>TZ^)EE=-1YSG^1YW(MGdVUVcCR+TV@^DF;6SMb.>3c&O>8S2A,<5T2KKXJH
// >F3\ZW-EcDWE1;^HF)R/J,6ACa5Z6<J:])?7gH=@<^6/;9D0_0T=_=,HXfZLe_bP
// 22DN4@LfB]W3FDAKKL3H:,1a-)Q7-D</cWQ7M?3Y9,,.PN&b6?0b]04=f+I)AQ(#
// PP-2Q/M964DK)&T\\7HTRM=BbTcf6JHF>38WP)Y90RVD<,c:#;<S<f<XH7+3FI16
// TdIH@c_\X=bB1SeM#.?Q5b:JBeTSR]BT[RQ_)>B\K:JN>PYRggOHK2)0E,UY1I9f
// e;bE11]cBW>I4bNM1b;WXC,X@Y@.MC&<(XB,VgTMHIPFJFCGRCXOP)g,d_6L=/g>
// 0+UU4V9&<=KYM&@#ZeI\^S[]61O3@>A><]^R89Pf0DO&Jg(9=1L+.-C?Y37UQ?L8
// X8V]&]KQA+\AEeYX]^UXEJOAe&[g1-f>71?LWT66Va3J6-HE,(A@bE=BVgC.a4A(
// bc)V-+I4XLPKQK&a0I+4Scc#D5>H-c^656=6DS]\GQ5PEa&a8gV9&?RN<91U9,)-
// =)B>D7b[g.-;[e(RM,3&f8P2U,1[cFdeDe6E_WB0eOE__;DFI@53_<#c_eVdJ-LR
// 926X4Z4\Vc64:EeZIa>F_:c/D^::TF6RRIT6GaN[&<TU7e\X8fUK6gcHZM:[a?#X
// NH:2ODYFF1YE(.T0_M8^I2(2[=+7)7IS?AZ85:I@G4PPJb+.V,T:Z(&M4^YSA+-<
// ?d.AR=?&I_9I69<-:_[W;D0I2=076S2=K0:LZ8@XVP+bgf#bc;Fg;Eb2WALWH9T)
// _a4SNS8&D&G4<RMCg)S)WBJHTI;&Rd#W\<HdBL+-QFfIX;=VJ[.L\Kc0;ZA0\X7d
// a+bP\8,_JD:cCHTT/IIF63S_aMdOe6ULLV_?(W\)=D0H>[Z9Qd@aG3N..Le/.CKI
// &Ae@Tf+/d#0H37M,aUK2C_,/N3F234V37,aI]7=^[b49MWH^G)cE\(bG0RGY5XJ7
// ^>WCZ31K#A?>;HQ5bMbP,\;S?F0c_Hc#+Q(S?2V;XW7<>GKNa9<?K?[3@>3c::(G
// =.^M:B6[6cHI?-R-?QHV;3AW(J4.6Oe)Ie8\93>@=#eCQ@OBCf70>O74K<CMVFT1
// =3#EPEET?NZY5<&<B9)CAf<,[Wg.G7XKY>E+L31B65.3+(W;[GdJ>S94FP/JBV+a
// fgB.7eZBSgIDV.5(-IgO0;@21]0ebU-P=A8?c-^GJVZYDC]J<)g_A.XDZL0^M7^Z
// Db3D1RZgYN:D&d(^&6/YZb4+9[EH3g&QcWT-Zg7b2W[=K>.I-#].aU^/2-UC_(7b
// Ka-^H#IGg.AS=C+DI5O(+OMU3987=K+9>[O6D]L<bBNE,(?XVBSQDXg4-^e7CI8E
// C=B;Q9IaG7;Mcea5&DQND6+92&JDT=g4;B[@V-Q-M?1R]SB05:W6WLbHDQ-AW+.V
// Z&2SA,JV&CIPN(1&DI0+)XL?>HcYX5<MJX?;(O=EG^?JBI\W&&:NS[F&#VU]FBYD
// J6R(P43bKXNCQD\@g,??C0E;f+Ee)A86_1a;U0,YG\J&5LOC950XYDW]M<4&0K&N
// KPG>5BGIH&T;&4Dbf/g0BQg7+@ZNB3G4gN#S41LOV9&_[T2JR=R&RPcd]J<#H<8Z
// <L;fNU&5)D0+Z.[73L+HX@6BAdWQ4Z6T[7[3YHL:S3cVf(R.aE=]=Ia>/a0CIcf0
// 8P[O4>M<>/IcEG@g,E#?V3>Y6I3O2>#7FG:P:d0X-?eb)U7WObd4YS@CIW[DX0BM
// D5b5d[G#V#QMKHB=DYf/9Qa6b-ZXJ;5M0g2(0K&g=Cd,H6G]DX02KZ\/TSZ5-2F>
// 3W\<=@-(R,Uf1GMe8@G[D86GHU2VBD@TgF6C1c\3)b\X8][PbX7gOV^\+\;3gcgE
// &<cYAB(:ffdP7GbS<PCGDOG#<=A\]I2^7IFG+)A[ZB_Xg5U^R[Q\>RKFN2C5eI8.
// 4<d,XY<WcAKP>\QUEN6PQ5370cOJT;^W]1;(36dX7&U\1WdOTB>W2-TXMX?V:@/>
// M[&J3(/&9B313cA6E9&ReKA<5<6=[+#cSHJ@,Z:]7W.4dN:BZBX<[<+1HfGH)K2#
// BE:LIV+,[S,=N6JWVJMXG5:7M&]f7H^b^UT_0YH99>9(\IQg+F8g0g3AbDYHH&[?
// .5JH2[)/#f,0PRdO(MKLB8#fNF&Tf1c=>C,FAb3WHBb(7VVgP2e/3(>R^TG?T=#4
// )eXc[UD7=PE;[+P36eG2@dY>:B/[F:-8Wg9Y>@EIG\e&f?)/M10&R)(\5Z^/9S8I
// 5b;2^7)UK(WaDaAX9]@<HGSeLOM,7JI\fX^Hd[LP,:CAGPc=e6NGBVMY5(+c)T_>
// ^8Y<LD^9_>e4YOa.f=LE4f@P0B<&<<\C_X#WH7d,/Y:2WWa2Bb.U+DPMS\>JNTP:
// )8N<Qa<G>g3L9#bC4d/.=EE??10YQ,Q7@,B(I&Uc8Qc/DQ^<Ge7DNLT=?,X^TBWD
// 7Z&R799=TS?RL,Cf>;PW?.-Z1Sb#_?e]f)Hbg]c[>e<,KF-#N8(+gTU5[aH>#eH^
// >4H^YJVS_MY2#,bHZL/_[-AcP/K6#R00KB>TK^;:P1B.c#+\5Q<L:IM\G8&GW+<@
// Ucc4c[@cBX.-0M5C)25NL>e8,;P]YX(74K1SZE35.Q6F@@a)I/-8>.3OG(?=#S?J
// X@PWeX<2S[DJA0a\>KB]QS)UVJHfC&eU@@:FT7?CeC#c2A2ARYZQJZM+^C5/5ad_
// H]FIQMWU=X8Bf@>CY49_LC9PeHBB/OV@H:3_ODI.Z>fNS<HL]4SZ+QX6;?HSQFBB
// Wf#=-Y2Fa-.M.\D^:=3[HY:I@bO+IFgdBXJF##694#O#Y07ZYVB?Mgf/bGa[V6C^
// KJW-2;FW79^/OUP@H^H\@+E_7c0X454QJ/d6Y>\J?#GA)&=]Paa+T@V(F[20f#X7
// b&7B9YM8J=:_eeL<E?FIHE3&LL4-c??LAd[]:2/_&Dc///YXKAYgaMQdZR;>_D3>
// #RYU/;e,93#QTQJZ+FN-ABM)\OGI-W,_TZ1#)SURIV[?2;a9BGQ:&,R8>Ua@OQFG
// =UGe]d4FOfQS+@,)+.]-IPH2V3NR,]BH^J@UG(Z=c\:(3EeV&54<[[?:+cI.ILZ/
// (aF)Ed[,Y@a2daATF;KX:8\16]c7_:&a3]#&&=HYT>?ZGULHQO++)5WY+OX?41((
// aXW1dE:012EPR:@KC=20_>)VLg[O=&NV-<_^d:\MNRLT@Qg;Lbf/(;,#,E9d\J^A
// L(eA]fXF<.,8J3Q#Yc&:9TA,RA7QF-=NeAGR-a6W-ZQJ5]46.I^X5M\-8;>AAK-1
// b<[2^53IJ#@J]U=I+R5NB>f6(MT\,Ne5B_MDeLPF9Cc445]8\J3&.HQ3eaH[)RR(
// (8U[V+?Bd^;N_&1E>EbH81UH<>MHMP\bP28d;3ff]NF^1g.VQZZQacZ^@f(<&MV1
// >W^&Eff][MJ.JU(]8JQ=NA?KGW;aRT-3ZHb/KRAT.UeH(&aVKb8U,IHa@(S3AAUX
// 34@ObfMHSHPTfg\9<WIXY3)&ga78>IQ6Xe:4#,<V_g+eb3Q-[3;:g@YNf2d_3-Jg
// <A259cR]8X&[#SV2___I,J@@N.U^KQ@R]/9/G0[I(;[gHF#_aL@f&/N0_MR_,]4W
// JWHB0<FPDKU:Ce.X]O]gaL#A+S\<V+P&PJ9]G-=d)Z<N(2,:ALWN).SVT&N>EVL.
// N-WA:7NYH,-C;Q.8+ZENJ^^ZTAHAPHbMY]Y<eTDaZTQ4TRE&8\O=/C>&EUgHFX-7
// fK8)61_]^EZ)[H_b;Sb[bMQ1GD4PBM^faGQ[LU;BDSBf3J5#TZe7WTVX5OgOfU<Z
// IHE6.+WBdVf<LH:PfEGc?5bHPbH@fK^T;c7TY4Cd8TL?Xgg?5\a0MX,PVMW10G#P
// ZW.Xe&?TY5a:\;f+Z09R4bbU54#BeIMA#HC/G;27NUDW6=^+=W\./@(Y18-&D]aP
// <(&;50_1,Y<;:(-T>B^_45J&V1U^TR]/W#U:-(O,F@LR&ES1>&6290,5L296)U9F
// L[6)23KW)851=\YaT]>M\O:^W30fTM(^9_0ESG-UPL1\--T0;#5<8>Acg03(H@LF
// a(Q-T[H=V?#;eV+>,ZXIMX/?0+[)\:GIJE.XF>Ka<7@54Z<FW7R2Y/D9XV#G@a?R
// 9\W,N(=FYFQc6G#Z\Lg=\&QA0IHe/[gA,O4Z4&9<#HJaY5SY,R54+e,W71;ZDKG:
// 05.DcXVQ,/05A6R]J;,+&D/bH.b_6a6S,c9L=?PeD#&b->3LLY,DWC3JYHcV,/_O
// )]Q]6^K55C+#SAY/FCRZ86eP1:PS-;ZNe,7>;:]]EM]@D]/Z[@E_H^J=f0]U9,&X
// c\e-1<H/O76HBCN-7(BI<<4^)A=KTG_)9ZI]\1M+WIcS)d7/FZ<VIcX&;1XET?O9
// &D5?)0/UG7SEGMcGedeKP9A6/Q-Y@2&LAE<fM]-RRd5d.&X2&U/@Yd^B6G2UcI8;
// 7B#4A65Ja^]GB5?9H<HX5&;02S0ag\_V;JQK-RQ>f[/8:;?_^Gc(?#HP7N-3UTT@
// g=)[ABM7<FH\GMLPA3(D2F@HXDA4TScY#)L-4<H3)Sfg1Dd:\NH4-P1#=6)J#ZDT
// QK/F7--&^6@\<E#NH7L\eBdY+2UPSRWaaY3?TW#\F:SG5A]EXC]3=GXZ>YQfBG3^
// 4O3K8\gfWH22W=f[^Z(7R+&V+8D)#P+P&O9_BC0LD72ZSMB,HA=RY+XJ-S>/Q-+E
// 814)f7>gR[DC+eR;B9J=g9?1MFC)=7#N?eDEJccf<fKF9Hg/a]KB-IMC]_MS;GUL
// IKc_EgSUA2FM;/66AbBW0T??KfXaH#59E-eDK<(d&d2#<9RCO(LX/BDJ#W6_^1=I
// WXVUQCX>@e>/6KNADg#C&B4PK&GcSc]9K7M6\5H;\6+M3B5fGKO_BB8YM:M.&X54
// /_DZD?>b9^=eIg\L5P0Q/;gVBbO;@M1207A6aL2NKF]N6<=Q32UG)XYcXQW@B0Ib
// JGa.T&OV+?2F0@^&XV)(GOKJJ+&eS6;WV9J,@+G[C+0:)QCF\<PU6@QD[B\aWHIa
// P>>P.W=HEfR+fe[:GI(OKU8RDSS6T1V?9YJN/BABDM]0]5b.^&MEb@;^e[-WGX>R
// aO76g\DK-g;M)QPY[JfA&Y[[3(dOE;C5NX19]fE(M.5F[g:Z&b.C@;8296//[]S?
// 9fegGSFRTOXRg3;0M^4>DeWbK#eb7YRZKJBc+_HBf-8#_#S,7T)TV+Zg#U/K20ZX
// UX9fZ//4#FJ5M4?dK>.,=+,8VEbMe>7:??[/AeK6^O[\K,]8:DJ?A1I+f-1fPg8)
// T>2_M,^.C#.HXY^b@Q3+eP>3A/T.NN@0<FN/5#X>L>/]aHC4.Z7MdYP4b>FHKYDZ
// D4>0R_MRSf&03B;I+GGVPHYcg[gO2AVGM30(DNd8_D-3(Y\L:a[<RUHERa.#1-6&
// ^;LZF2>IN=IYUeDGO99D(5=I9\[D_#f0U6?37@+DcI3_-@>,/\V[BJa],6/&eVGF
// DeNVSgTeI@\d)34<809YF:-#QUQbA3OBNc.,G^)&_1(?[^UBbYfA<?MP[Z@eeI7S
// )d)AP9-GELPc8NI,(P9=:\A(93+;)M-UJCD?ZDQ4S<MJCc63.([NZ@/9>CSW>X@3
// [:Q;>eK?>U=5;+d5;/DW\<(?B&Uc?/+dODb-7QD2D;V9:c14YBJ6_[K^_BV1bMgR
// 3O5ND^E+)<T_R/+7#;aaS+MP0,>WLD>Wa0HVRMRcUE,(<-?U#B6M366]8ND\dCOT
// /,P:&QEM72CF1?&egA2:EPB+,@=#P_Y_./;IKJ^\>1fN]bA\6bC/@R#;P.6P@]-H
// >8M@G5]<QU@>5ZL9VSB)S]dAMZIZ.MA8Md@DdM>e+B(8ZFc&)E7(XL>5L5U_GR&/
// aHQF3-9/)aa09RY+NNgKH7B5[N[F,f56f;EN&Z;4-;2b,>3fg@L;R4eI4S2dD3#A
// Q8GbWT2ZHFNfRVfIG,&J+_K_YLDQ.,f0)2f-?]ba5X<6[X?I\YDS1N89&-fE^)8D
// gAgaJMfK7Q7HR\-L)fbU)gea/Mf;HFPdG<N3&AGD@2g9.TUNKE(#,7W55EBXe)R.
// ]baSI:=0V[YQ=:YVd1f5/FFeV]^GeG^5ZB3(g?2J+Z\c:5g1[]6>I9R\;8eTHU4K
// (g)AS,6TagO][-c]Qc1A-=[6?_>CdY>HN48ZZL4^fO@+OPA0UYN3RGgeY7Z6/T9L
// X3&>aD<Yg\1.@a#F\]B\UP5YM9O8ZEdFC6Z\M]c<Z5f&VeD>]#I_L<K[QS8W=d&:
// :-=Q9O[3FK#\7M1E^;-,d0<32C5Ua[37ZdaG5TgT>>IVE11YLAa67NNWRY&4N/0E
// aEf@/ZEe?E.a^[?/P2ZN)L<PRdWI.Id]^fGLUSC&,21.4?0-MV-45&T)2&X:)_P-
// (A;ZA:g^<._JO3P]175@7;#WBKIR-U-U^IC:MXW7f:.U0eZ-g>JSPV2Q\LL2QNe8
// Kg+FJF8X&KBeZ7),UB+C&LMUMI^R86:I1J?=EA8VV#NVeN0+YW62NgO\+6RV74,4
// HRBQK;6KX]@P?DVHU9XG[YM<S@Me51eX/49Q\K<fWXcW823R/]bY#_&W&a-UTfAY
// #-(FSXX6,)=+,bb.U1KT<a>0[AJKNP,_\<D?2IS4I7;G;]8AFILg4^TR^YE:7Cbc
// ?L.P2ODB,@I^D\Mf(VV.3eK?)c+LeSB<K9S[fbeZ<=c&B<cdXd-/<)L\\0^&JVN>
// UKX]4;d90@@S<ca5Mbff@]#4>H1Af1QBLR]VE@5\>&^T4;::.0H>\82<cWF4ZbeS
// 3<Vd91XF-83/H)[/eNBg3=T7AKUbA(,E<Z@cYDFDeZA]SQ#Pf5c5a]K::TV]V^=g
// Y#]>QIf?KRA]8SS?gF/0UC7HNZHgZf_T@K#0G[0T/EX?>+N/4U=:X+RF4VgBQS+d
// ;dMS>+Qd21;RPf,WcI.,CF4b=,.DZFX48U>&(>-.6V9B(ZE:IDgP3[E(+KIL\XYf
// \>^TU8Dc5N]VTSUH--(W2N)aZEB)(8Q/<<3c<:P@e>N\V:Q)F5dN@+WBWgP4;A:a
// =4B<23K384D-O>;G:Ebd^dEFE]b?Q3/IDGTS:./W3.ANRR\E2=>R_^#JcXa-eY\/
// &2[9YN#MZbMd2L4Y.5-T)@-54+O^I^,EC\D3&C+>+^gd=EF/0<,PfQ=d1UO>QeS7
// W=Ce4V)g,Ze(d+K&FFW@K=V_K,ZE4HL#B?8/0g<BE=G7a\6G,W<fM>TI@95/R44Q
// _1#T3D]8)M+\CG]gD\0J1YbdQ<]Tf:5I&-3\(B\TWa.Tc6-8,gGHH>\;WJ=BL(A)
// -C:8,\FRB8SRA=O2U,KMM5gD^-LM,W7]dSg]H>/79a<0.C:4e;LGAI);8]57IG+4
// 8BcJ)d6A,=25VdI_@/LA69.@]_#4+f;I5TQ,E:T59CLfd3g;5_@gI>4/(@Gc1BQ(
// 7MR1-^H^Q=(VQVU?VO[N1=S<]d.50O+R2M+S#eK4ZOY=\a,4LF93U7BDFEXHL@]W
// M@QaP^I(M5S6^B(HMJMAXZ0<V.0HL5(ETc2XRdR2+T=/U2XCX(-4VBS9+<ZX1@&c
// >\YJ=X_+;2H&MX^GC-JK.P,:0+]M;+013FS\H60Bg:+7=G52d==<?4&I;c#HG6E]
// d4XPK_bGT4]&+4Q33HTUA;g.]Yd9U@2a5Wc761JCO8c,LULTf-=+d@L7;2B_?9&-
// ]Rf39:^],X&G;DX:YN=W.c?<3e#R,RT<?N]@2M+]JE;<GUV6XIEa2=<(@GI7931-
// fL/_E7S9b5U4Y^.O[L4Q3Da2d?X;9^UR+I)/?He[P4EOJ\OO&5ZE@c0Xd@g#F14O
// ,f81(Fa/f\QUO/;BM.bc<bOT,gL,M)8=a;BBEC?,5(80AT\[(&&MU1C-Ee3W._>T
// >g:3L<#+/?C6^?a--5()449&F3#NZM<_[?;;IK1egA/V#QWg=;:3a21SW&9K3NH1
// 5O@;cOUAY/eU>Y9HXK#BCUdQ/0HAaC08_f4FNb1Z/WFW4f=[@._I30Z28EM\71.M
// JC?HU_fJX3aX1?0F^&,XgAN;S,RKDfX3_\/5\M.Ba5NZYcS4W)=7;L5=@6P5>08>
// bgMA870M,#\YC?#V=Q1e1VE>eeHK&c4GWEU5D:\LEETYZ/#5M@T2f?6\;FG90ZK7
// U0J9@I-P#Sc7K],f[/>YSI2T>HXK(KIBXPW\:d0-+>?>DE9FE7[77\OY,EOe#=@3
// \d)NIW];c2QAA7IF25Da(QT0\H-Eb^-/4IA#R3[f/S5,DJ#USMSAC78g=)F\D+d]
// #B80L\;ed33EMQb[E-@@;]5KLSUc<T)OX<PBAbZ)5J#R^=]L&=fD&cH;.7U6L]_g
// B\:P:U,/X>I^Md5Z><MJRFfAA#gD?)R)HEHERKKe]<&A[5LQ_K,9+6YO7UPVa\6S
// )^5^O#1PX&4.agH=M<I]afcOBR^e@TRea/_L,2+2UU6MLMQ,cM24I.::2f+(,=?-
// O3[6>c72QV_g&_:09MH+2fV7<<=bDEf\#62G)gF\RWg^>eKee,_:KMOD@Y9b1Kg)
// g7P)=JRLZ>8[8GK2Z/SCDbG=QXc1;:9>:]SCa(cgQe>.&3RfTS[Z^S_;^K1F4^S6
// 0JTGYCYfQd6(dba5CAC^MZHb6;f7+a+;9W&WHO)4+e&gf:bDQ<2PV+XK@VAY+=5)
// 3OfZ0c?]9)73aDJb3M.[10_7J6)d,K.JN&:2KZe0RYg,E1)/[CDc56gMP.^T8Q3_
// CWUK8X+,_.,6PA:6g>3SfB0H6T(0QQEH][:gSB7HP.6;CQHUN57]fG,0042PO/11
// 0Y^Y0-4c/E4FG+0PA-;+.e<0B+-IWcJJ&/=H5SE,D]P<,YXX1e=NVeUG+_S(2G(<
// K)1TM17[VfZRRaCS\dVBfa[bH5aX=TGTR?:\RfYL(X/H2e,>6QE^b0&]>#[D:Lb5
// ^LHMU+R;R;X]=I;.BFNP+W?O[g7-SXIS_J=aQJ\NQMg^5Pf0cNV[MVGJ9R1W9d_.
// +XY(9@GBLFL4f9LWW2G3Bg@#gLGHP/V/HLC7)7X+S&0V/N97UAIL1A>A;#)0WaJ)
// :+MdI3/=4]ZE-9YJ1\)@5=R[#,+=G]Q@Ab7GT@VNDR-8CQeYCcF-OK8/I_&;XR4A
// bfNHM9A[8gW1)eCKRE+R(/cFeZTR7<G4<N]/7#>74QKB1fTUN2I)?NYT=2EAVcPV
// XD/4F-:[\^>:&gJ<bg.#:.A^SHP-W6U1UVE1N@\ZX^&@.A3fT<f.2C8DNea3Ba(g
// TcL9Z:@J=V.H&E=f=:&HV7Rfd8&]L^S4bc(V+2M/9>H)fQ.Tedb6/e^K,KV]bJXW
// #E1G0#LeDL)AUE;9@/SY3-M(ZVDC2aG:X2).ZIK:-BBeD?;26@F.2\=/[+KVgSR]
// b-4>F9DX\T:#_-<-FIP?]0Q85E98W(\NM;C^bK8WL2>2f06>?D;4(d4H;49Fa+#M
// NAW&?+8)5QRU-&P0JfCP\YBPSW-D6Cc\<^WP)KFWR\Bb3.2+?Y^?O0.;?17LU1BS
// ]]DO61+TV#(.J;YZ>V@3O@6#WZ\fb_+g9TQ_S8<PA:<SLb5Q99Rg#/Cg-YY^BHaP
// 3]E+QIKQe9f8e@82eRdb]3KLB=H>J?;A1?KSUN/,Eg>TAb/e=U&)F1?XA@R?N(L=
// 6R(0]<Q?:^;)RA&M=<KeOR,SP1KIM7a)O04.)1f779BX]d-\DC+W]I\,>Xb]E7=Q
// :F[g7>0>Jd,\9,JMC-bK24-V9)<8FV&a3dB4+_Q=EWYX-dT@46CgFC5OSD[_.+AM
// M3&,[-X4^,+)L&9=g[D]+9T>YAO1J:IK_#&Je515gPa]C(6gW_?<S\Q=#gB&O<bH
// JRYF-P7F8g^:WO;Of&Y8?\M97g0cAC]F3:MKNDEN8/R.b=_-^gM&^Xf.9JCIQQ@9
// 99ZId1@1/LTFF=TdN>)1:@6KIc^L:/;cA).5Sg#1T7Vb+ZKSDNN_Gf;c^[8U5JP#
// AARSK:^0OF3?@2NVAV=QIR];1-SVE0f?PEHW&5a4LY<BE4K,?N#9aMT:WE,H2)[F
// Y3Q4YHTTI_)c\;Y#<^VC>==7cdWY&ac@gTQ+#Q0];fMdC\8(OGJH;0D&52V.JCU-
// Y.@T^CGU9[)?P<Q&N7EHFafbBX^[B#9Z3A?\1G/D]ZV)1,1(\JB&#.2NZ@UQ>LCc
// ?A:LNbT45Q-ge^[(JGMK@V4G.:[;)11E8fTYA#eU:FAJQ5(aD=?U8D+[QRd5<PZG
// 9aXFH-.JAe\JC\B?-Xe;MZ(>b>?Bd@69T4V/4O467D[)aHPLO7Z5#G2&S,a/#g,?
// +<+-Y+K4MFRBQPg&RETJd_?;G6H7#?g\\ED:a9ZS:/\UPe#IC8TM(7??J76A#f-b
// 7UWB/6CQHUf;L(2d3R??Q1<3Q0:6S[Z\(I>.^f/b+^P\fQ6(6bE&_8_<BcYCJX__
// X_Q@M=\JdI2]4#HS@R.?6_RA&<F[3a<-IW<I,2<USeL25PVaPE:f5J?/V;Q4,GC@
// 6B9?=JRQXO[L=+XeK9OX5Z4N5/fAH7W=^J3_32>0_g.Cd(IFa[\J9E45W+:=[.WJ
// 3,0cR,)gS8&3@&.[IgB2#3<YA=a(:G_[^^L&6NP1W17(Q:AV7eebe3-4G1+^bEe3
// HX,\=J1f:L\GZVI_QN:c^]7>H1WPI2IaY-.8_,YK]XTE\4TF24]9Ddf=V_^^J;8+
// .)]35M&_IK-N-66K@.?XPW7J3@0D#0(\e2N^2I&IZDS_C#2cPg@PSF>M=UQB-FE+
// /(QfZZJbBMd=()BSf&F(7WNT<:eEOF-68#Od1&&J7L4:VT/@)#D8<GI=O@@K8f\U
// ;R(Q/RA63_\60A2H7((EG_K8e[.?0C6e>Q,KA)#?4H?FbJ=9;;AZ(NaTJ#,,ZG9<
// BE>))3(,d?fQ0cTK#dfe.aW>?DT[^E&EZfQ<N.EOeI&<V\)eTeJ-6;IY_^MAg@+d
// &\T=fAP:cYS/N=DAL\83<c[d63#LU9FW]5;COB;(09U1[5Cad<X<QFSG,Zfe)_HM
// bQ.4O3OF3EC<,(a63N/H,8(Z:FeYAaCEOdW/P+Y[QQ.N]IYLWE=^;Ng3,A2c=77+
// Q<?_25a.-7g-AQ,8T,V;1,]&+8KV257)QgMKPDXD1&bUE>f:BM30LVf^DFSD2e,\
// H[-C4V\MWMMS5HR:T?b.]X]a>&C.[76gR,@P4g+7^91V94cXa_Ba[.eKQ+/O?E6V
// Y:QE)A4O,),Ub>UNb7[AY[CG\+YY9^Ndf/N:YW^KdXA@gd.f<KN8He+&&_\R#Sc.
// 6&L6+<VDC/@c1W<#:a.R7H>=_fF=+0\G,PI6eH-C0L2f39cZ2[<=Z9]KE0?27e^D
// 8EY2E0e<ZA2Kg.<X8SWdO,dfW4=PET/52&I>dGD@^@H5ZH_8#+cZ6P71&:NP0.RO
// U,fR1KI:PCTc+Q+U],J-=5W.SQ7:5,+WUB:Q=gDR6@R)IW<X8;bS[F4/M81J4.@M
// EO7(J1,WUQUV_-CP_1.XZ0KW,8+62W1?502UXdCCI58,/^e;,VNb8158Daa7aN):
// 4,[C85)&_a4#;2F_35(1+Kf84B-,#_c-Z;_,@FP\f[EbU=7Q=H.f=U(O.LWYMZ;c
// ??3]VH?XR]ZY1RG_62^9T&/7=EZQ5.H-(7PJ:<;3T@Me1Oc[P;f.4G[4R@]F+\cS
// 9-RK)D?e&?K9724c26AP3P8WfYKa@Z<OB/6)G@5#B]/(<>BLQT^Ta:+_,WG)9XS[
// 9L/<SL)N(7U.&+/U#:YYd^;FL,_9JJE91XWZ]5-1Ygba;).Q6<L28V4A^(e;,&ZN
// _H6[<_TT,6T=L7^Y>,)Z\7Q4M)=XKfD?OYLDL?Q_8ELO>5^K_;KP(,M4WZBHW0@&
// ,GJOAE4^RUBgWD=&O,fH1_4>cgS>/cO:aFKCab.DZZXSHSN()d@CM+M<+a5X@T<2
// ;+G0I5b3\[9Y2dG7,O._<3eB;E@8Q(?<_Y35>=/\#48Gab/=2.A/QLQ#+<gSgAD.
// =<WF2\D[1,@V=@KQfR52b3540f\36RQA;A#T.NdS6K:C:<)/UE@334[#I/6R7O4G
// S^:f3BQeWd5PbC^6G;^;@aCTO5\NBL,\XO_TA]XCNd9=<:5b/_JRU?UNF^[VSZ5W
// cQ7;/T2>W5A\JdSEdI:a)fY#LDD:2U7HcEX4g9G,KY\(bWFZ7[YgJ-9aDXW(bg\[
// YTW6,94gM([^/_,<BQ5GN;W=P3+ge(3DH3Z8+4&+PPO))K=Qf6+P3LKFSEc]FTYY
// VTbK,1&^&K2@,#G&Vf./5&?7aC9:P0I^efE7(+)7Ba1a(,_fO[cIY<Z.<JFK>cXV
// TT(P(#ZAaHgH>@aVGfUV_YWc:LM0IVaf.+9V<B=)IE+OdS/U//e8@H]__K#?MIH9
// eXagN68;;QEE2eg\AcQ+6FQ^PJ]:?f_&V0FHPX--A?E]#]#W68<>UFg>.(19G[@V
// F26\T\:N55#,\SN#?NM5]KI74f^9T9[.NgFU<#6_TZ6LJ38[\]b)^&-eK0Q@7TM6
// B;d]\/Y2+O.(BY:+f(@<6&X;JVY8d7CXT[0DNZfN=V[ZM=G/#@TS,A-gaYdFc=IL
// aSYDC8Og_,@6E4Q4b<^d>O#cT,E4CG0_c[)JIO97DYFa1+ebN0[/#@,f(\+A11b,
// ]:f/AOTCB)B9IBX2FdC:g-f+\Nb;DD>]T8+O63_O:/_0H4)D]a2.[T<Ugf&RIGa^
// UeWSVQON560D>TdP()&48,d2+WcG8V<e2F6Ke/SCd\&DN=Y1e@MSLT>BU1=G(KLT
// gF;VR7Ca6@5D==EF.CA?D;(I=d(:F0+4LB9T#ZZ-<7[Q2E<@gD]LV5I(_WW+02_R
// a+Hff;EFX[(bF^5^BLRRM-ZgGE\H7@AR?I[H<30dU<]L3IGT2JX1U=QOZ]_0cJ+E
// fbS[>fS<egTVcUf#E,#)cdd-]DI<@JE9=/AP35^_8ZIVM:TL<>SQI#FRBf@(FPHN
// H#dTZDEOK(K?>LCM.?IdM/+NW-ed^6+(<70-LcU[52B:;A[gMX>(?(<+fH?7=W,=
// =g@bPMU^eEICAH,8.(G(;=/ace9\)fLA0&\-902DN-N?6&4EDVFP/JU8Q]J[WBKU
// DdA@9FU-a-UR.KLfVV#e[0Q;<MQFGE_[]_VFeJDF]B[+>[cXdWU0;^\_-RdGAaQd
// 4g:.7UO7U5:SE=73aW@JMNXLC&QUgMZXMH8E+)S?a&FgI1\@&-.aXIPC2,b@FV6X
// 36,0]J#9_LeGHYa/_TJFD;_g3DH)-5PI>f>6GI[B^2e3<^S.BRaGN)6&4&=X6Z?)
// E?UV+VQ/)-Df&HDSN.IeSH4bAZa<?aN[15^;.T_KR?_4e3Y[+[R^]9[cLfJH.g&F
// @I@E8gWaM9OedDIF03=KM.=fT8(]T-6TDM=+TcZK]7g7QC/(0=a8+\?FZcAVT,P&
// Y>/Zcd:4M(7V5HEE?.b<[c:_U(c6]c<g^__]66&0]>4+6-OT=44?<>I?#e_Nb+G:
// Y<]BZ]BHeE+0R.TFF=W+TA9Ug=</9\BBe.R.<E+5aT]A41@\VdN?SNT369TEF=U5
// B2O]K/K/dLR,M]U&H[:81?>G>Q<U_N+RQ-#WfJ^_3_ad-.C+B=I1[(=1aRE<>2Oe
// 78IXO0?[1d<QP@H9DYaMcDfI9?W0S3&\9)#F69PWQ/D/(:D:UfCNCd7Vg8:+6]Q&
// /NNW#547M1=[0LO(T67K^fM0gHgdT(\B<8N)2JWc+_YDe3YcF#_MX5;N84@EII_M
// ?#f1.W>BMCURRPddJ7I+T,#N\2MT<FCIO#G;6(F@94AMbBNX(VYG/Z#)PZV?_WC9
// F5e?4=3ARa_)#P[VK6cgLf\Pc:][SPP9+[1:1gC.9gM6gP1T8>C_R@=TF]TX58C-
// E:(K+I#CfD&C9TH8A6KLe=UWNATcEGAL\QBI;;XG_a]8+\;5Y0@gHV+QJ]<V?MQC
// [LHKMME#[[]9JD>+aWgK2\/_&(6EPf7M)>B,:Z5#=@E:_CR&E.):8CL?>H?&L?J0
// (OSMDUH752&AX9=/K[e;/MGA[g(QH,GL4.0&fKN77;41JJ7T(5KBY00C77Y/TMYJ
// MN+7#OKfMBZTY-aaF@E>/ZYPd\60::I7,>B_<T4ec6A^JF;<.9?.W&39M5G0bb,C
// XXH-&-872F7FGIeJM.>Ddf21H\@5a7d[.150;[;IVbZ4F+AIHdT,d\JegLeN8b]e
// 9+6EfQMBF7/J6Q3T[@J\KU9:0QF4O3&ZAMY-bK8WQ;,<>,0>35V^A?AQEf#/Q3-Y
// =I5:(>NJ:T+;ZJANdU;]4Y32ZSOYZ/QGd(+&&2;^>Z^+0[U&&UN99M38GE/PJ&\C
// YG>MJXcDH+M?A@</)=ZAdAPG;ANA\cf;5<LD=;7eK:)JU/D-E.RROSON9RGGQ_ZV
// ,>4a3\D#F=MQ0HUR&4&I4GPG2$
// `endprotected

// // `ifdef RTL
// // 	`define CYCLE_TIME 20.0 
// // 	`define RTL_GATE
// // `elsif GATE
// // 	`define CYCLE_TIME 20.0
// // 	`define RTL_GATE
// // `elsif CHIP
// //     `define CYCLE_TIME 20.0
// //     `define CHIP_POST 
// // `elsif POST
// //     `define CYCLE_TIME 20.0
// //     `define CHIP_POST 
// // `endif

// // // `define CYCLE_TIME_DATA 31.7

// // `ifdef FUNC
// // `define PAT_NUM 828
// // `define MAX_WAIT_READY_CYCLE 2000
// // `endif
// // `ifdef PERF
// // `define PAT_NUM 828
// // `define MAX_WAIT_READY_CYCLE 100000
// // `endif


// // `include "../00_TESTBED/MEM_MAP_define.v"
// // `include "../00_TESTBED/pseudo_DRAM_data.v"
// // `include "../00_TESTBED/pseudo_DRAM_inst.v"

// // module PATTERN(
// //     			clk,
// // 			  rst_n,
// // 		   IO_stall,


// //          awid_s_inf,
// //        awaddr_s_inf,
// //        awsize_s_inf,
// //       awburst_s_inf,
// //         awlen_s_inf,
// //       awvalid_s_inf,
// //       awready_s_inf,
                    
// //         wdata_s_inf,
// //         wlast_s_inf,
// //        wvalid_s_inf,
// //        wready_s_inf,
                    
// //           bid_s_inf,
// //         bresp_s_inf,
// //        bvalid_s_inf,
// //        bready_s_inf,
                    
// //          arid_s_inf,
// //        araddr_s_inf,
// //         arlen_s_inf,
// //        arsize_s_inf,
// //       arburst_s_inf,
// //       arvalid_s_inf,
                    
// //       arready_s_inf, 
// //           rid_s_inf,
// //         rdata_s_inf,
// //         rresp_s_inf,
// //         rlast_s_inf,
// //        rvalid_s_inf,
// //        rready_s_inf 
// //     );

// // //---------------------------------------------------------------------
// // //   PORT DECLARATION          
// // //---------------------------------------------------------------------
// // parameter ID_WIDTH=4, DATA_WIDTH=32, ADDR_WIDTH=32, DRAM_NUMBER=2, WRIT_NUMBER=1;

// // output reg			  clk,rst_n;
// // input				IO_stall;

// // // axi write address channel 
// // input wire [WRIT_NUMBER * ID_WIDTH-1:0]        awid_s_inf;
// // input wire [WRIT_NUMBER * ADDR_WIDTH-1:0]    awaddr_s_inf;
// // input wire [WRIT_NUMBER * 3 -1:0]            awsize_s_inf;
// // input wire [WRIT_NUMBER * 2 -1:0]           awburst_s_inf;
// // input wire [WRIT_NUMBER * 7 -1:0]             awlen_s_inf;
// // input wire [WRIT_NUMBER-1:0]                awvalid_s_inf;
// // output wire [WRIT_NUMBER-1:0]               awready_s_inf;
// // // axi write data channel 
// // input wire [WRIT_NUMBER * DATA_WIDTH-1:0]     wdata_s_inf;
// // input wire [WRIT_NUMBER-1:0]                  wlast_s_inf;
// // input wire [WRIT_NUMBER-1:0]                 wvalid_s_inf;
// // output wire [WRIT_NUMBER-1:0]                wready_s_inf;
// // // axi write response channel
// // output wire [WRIT_NUMBER * ID_WIDTH-1:0]         bid_s_inf;
// // output wire [WRIT_NUMBER * 2 -1:0]             bresp_s_inf;
// // output wire [WRIT_NUMBER-1:0]             	  bvalid_s_inf;
// // input wire [WRIT_NUMBER-1:0]                  bready_s_inf;
// // // -----------------------------
// // // axi read address channel 
// // input wire [DRAM_NUMBER * ID_WIDTH-1:0]       arid_s_inf;
// // input wire [DRAM_NUMBER * ADDR_WIDTH-1:0]   araddr_s_inf;
// // input wire [DRAM_NUMBER * 7 -1:0]            arlen_s_inf;
// // input wire [DRAM_NUMBER * 3 -1:0]           arsize_s_inf;
// // input wire [DRAM_NUMBER * 2 -1:0]          arburst_s_inf;
// // input wire [DRAM_NUMBER-1:0]               arvalid_s_inf;
// // output wire [DRAM_NUMBER-1:0]              arready_s_inf;
// // // -----------------------------
// // // axi read data channel 
// // output wire [DRAM_NUMBER * ID_WIDTH-1:0]         rid_s_inf;
// // output wire [DRAM_NUMBER * DATA_WIDTH-1:0]     rdata_s_inf;
// // output wire [DRAM_NUMBER * 2 -1:0]             rresp_s_inf;
// // output wire [DRAM_NUMBER-1:0]                  rlast_s_inf;
// // output wire [DRAM_NUMBER-1:0]                 rvalid_s_inf;
// // input wire [DRAM_NUMBER-1:0]                  rready_s_inf;
// // // -----------------------------

// // endmodule