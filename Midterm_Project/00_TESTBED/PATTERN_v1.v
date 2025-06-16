`ifdef RTL
`define CYCLE_TIME 15.0
`endif
`ifdef GATE
`define CYCLE_TIME 15.0
`endif

`ifdef SAMPLE
// write your configuration here
`define GOLD_INPUT  "../00_TESTBED/For_student/TEST_CASE/input_2.txt"
`define GOLD_WEIGHT  "../00_TESTBED/For_student/TEST_CASE/weight_2.txt"
`define GOLD_MAP  "../00_TESTBED/For_student/TEST_CASE/map_2.txt"
`define GOLD_OUTPUT  "../00_TESTBED/For_student/TEST_CASE/output_2.txt"
`endif
`ifdef FUNC
// write your configuration here

`endif


// `include "../00_TESTBED/MEM_MAP_define.v"
// `include "../00_TESTBED/pseudo_DRAM.vp"


// module PATTERN #(parameter ID_WIDTH=4, DATA_WIDTH=128, ADDR_WIDTH=32)(
// 	// CHIP IO 
// 	clk            	,	
// 	rst_n          	,	
// 	in_valid       	,	
// 	frame_id        ,	
// 	net_id         	,	  
// 	loc_x          	,	  
//     loc_y         	,
// 	cost			,
// 	busy         	,

// 	// AXI4 IO
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
//              );

// // ===============================================================
// //  					Input / Output 
// // ===============================================================

// // << CHIP io port with system >>
// output reg			  	clk,rst_n;
// output reg			   	in_valid;
// output reg [4:0] 		frame_id;
// output reg [3:0]       	net_id;     
// output reg [5:0]       	loc_x; 
// output reg [5:0]       	loc_y; 
// input [13:0]			cost;
// input                   busy;       
 
// // << AXI Interface wire connecttion for pseudo DRAM read/write >>
// // (1) 	axi write address channel 
// // 		src master
// input wire [ID_WIDTH-1:0]      awid_s_inf;
// input wire [ADDR_WIDTH-1:0]  awaddr_s_inf;
// input wire [2:0]             awsize_s_inf;
// input wire [1:0]            awburst_s_inf;
// input wire [7:0]              awlen_s_inf;
// input wire                  awvalid_s_inf;
// // 		src slave
// output wire                 awready_s_inf;
// // -----------------------------

// // (2)	axi write data channel 
// // 		src master
// input wire [DATA_WIDTH-1:0]   wdata_s_inf;
// input wire                    wlast_s_inf;
// input wire                   wvalid_s_inf;
// // 		src slave
// output wire                  wready_s_inf;

// // (3)	axi write response channel 
// // 		src slave
// output wire  [ID_WIDTH-1:0]     bid_s_inf;
// output wire  [1:0]            bresp_s_inf;
// output wire                  bvalid_s_inf;
// // 		src master 
// input wire                   bready_s_inf;
// // -----------------------------

// // (4)	axi read address channel 
// // 		src master
// input wire [ID_WIDTH-1:0]      arid_s_inf;
// input wire [ADDR_WIDTH-1:0]  araddr_s_inf;
// input wire [7:0]              arlen_s_inf;
// input wire [2:0]             arsize_s_inf;
// input wire [1:0]            arburst_s_inf;
// input wire                  arvalid_s_inf;
// // 		src slave
// output wire                 arready_s_inf;
// // -----------------------------

// // (5)	axi read data channel 
// // 		src slave
// output wire [ID_WIDTH-1:0]      rid_s_inf;
// output wire [DATA_WIDTH-1:0]  rdata_s_inf;
// output wire [1:0]             rresp_s_inf;
// output wire                   rlast_s_inf;
// output wire                  rvalid_s_inf;
// // 		src master
// input wire                   rready_s_inf;

// // ===============================================================
// //  					Your code start here
// // ===============================================================




// endmodule





`include "../00_TESTBED/MEM_MAP_define.v"
`include "../00_TESTBED/pseudo_DRAM.vp"


module PATTERN #(parameter ID_WIDTH=4, DATA_WIDTH=128, ADDR_WIDTH=32)(
	// CHIP IO 
	clk            	,	
	rst_n          	,	
	in_valid       	,	
	frame_id        ,	
	net_id         	,	  
	loc_x          	,	  
    loc_y         	,
	cost			,
	busy         	,

	// AXI4 IO
         awid_s_inf,
       awaddr_s_inf,
       awsize_s_inf,
      awburst_s_inf,
        awlen_s_inf,
      awvalid_s_inf,
      awready_s_inf,
                    
        wdata_s_inf,
        wlast_s_inf,
       wvalid_s_inf,
       wready_s_inf,
                    
          bid_s_inf,
        bresp_s_inf,
       bvalid_s_inf,
       bready_s_inf,
                    
         arid_s_inf,
       araddr_s_inf,
        arlen_s_inf,
       arsize_s_inf,
      arburst_s_inf,
      arvalid_s_inf,
                    
      arready_s_inf, 
          rid_s_inf,
        rdata_s_inf,
        rresp_s_inf,
        rlast_s_inf,
       rvalid_s_inf,
       rready_s_inf 
             );

// ===============================================================
//  					Input / Output 
// ===============================================================

// << CHIP io port with system >>
output reg			  	clk,rst_n;
output reg			   	in_valid;
output reg [4:0] 		frame_id;
output reg [3:0]       	net_id;     
output reg [5:0]       	loc_x; 
output reg [5:0]       	loc_y; 
input [13:0]			cost;
input                   busy;       
 
// << AXI Interface wire connecttion for pseudo DRAM read/write >>
// (1) 	axi write address channel 
// 		src master
input wire [ID_WIDTH-1:0]      awid_s_inf;
input wire [ADDR_WIDTH-1:0]  awaddr_s_inf;
input wire [2:0]             awsize_s_inf;
input wire [1:0]            awburst_s_inf;
input wire [7:0]              awlen_s_inf;
input wire                  awvalid_s_inf;
// 		src slave
output wire                 awready_s_inf;
// -----------------------------

// (2)	axi write data channel 
// 		src master
input wire [DATA_WIDTH-1:0]   wdata_s_inf;
input wire                    wlast_s_inf;
input wire                   wvalid_s_inf;
// 		src slave
output wire                  wready_s_inf;

// (3)	axi write response channel 
// 		src slave
output wire  [ID_WIDTH-1:0]     bid_s_inf;
output wire  [1:0]            bresp_s_inf;
output wire                  bvalid_s_inf;
// 		src master 
input wire                   bready_s_inf;
// -----------------------------

// (4)	axi read address channel 
// 		src master
input wire [ID_WIDTH-1:0]      arid_s_inf;
input wire [ADDR_WIDTH-1:0]  araddr_s_inf;
input wire [7:0]              arlen_s_inf;
input wire [2:0]             arsize_s_inf;
input wire [1:0]            arburst_s_inf;
input wire                  arvalid_s_inf;
// 		src slave
output wire                 arready_s_inf;
// -----------------------------

// (5)	axi read data channel 
// 		src slave
output wire [ID_WIDTH-1:0]      rid_s_inf;
output wire [DATA_WIDTH-1:0]  rdata_s_inf;
output wire [1:0]             rresp_s_inf;
output wire                   rlast_s_inf;
output wire                  rvalid_s_inf;
// 		src master
input wire                   rready_s_inf;

// ===============================================================
//  					Parameter Declaration 
// ===============================================================

// -------------------------//
//     DRAM Connection      //
//--------------------------//

pseudo_DRAM u_DRAM(

  	  .clk(clk),
  	  .rst_n(rst_n),

   .   awid_s_inf(   awid_s_inf),
   . awaddr_s_inf( awaddr_s_inf),
   . awsize_s_inf( awsize_s_inf),
   .awburst_s_inf(awburst_s_inf),
   .  awlen_s_inf(  awlen_s_inf),
   .awvalid_s_inf(awvalid_s_inf),
   .awready_s_inf(awready_s_inf),

   .  wdata_s_inf(  wdata_s_inf),
   .  wlast_s_inf(  wlast_s_inf),
   . wvalid_s_inf( wvalid_s_inf),
   . wready_s_inf( wready_s_inf),

   .    bid_s_inf(    bid_s_inf),
   .  bresp_s_inf(  bresp_s_inf),
   . bvalid_s_inf( bvalid_s_inf),
   . bready_s_inf( bready_s_inf),

   .   arid_s_inf(   arid_s_inf),
   . araddr_s_inf( araddr_s_inf),
   .  arlen_s_inf(  arlen_s_inf),
   . arsize_s_inf( arsize_s_inf),
   .arburst_s_inf(arburst_s_inf),
   .arvalid_s_inf(arvalid_s_inf),
   .arready_s_inf(arready_s_inf), 

   .    rid_s_inf(    rid_s_inf),
   .  rdata_s_inf(  rdata_s_inf),
   .  rresp_s_inf(  rresp_s_inf),
   .  rlast_s_inf(  rlast_s_inf),
   . rvalid_s_inf( rvalid_s_inf),
   . rready_s_inf( rready_s_inf) 
);


//================================================================
// parameters & integer
//================================================================
real	CYCLE = `CYCLE_TIME;
integer PATNUM; //300
integer seed = 333;
integer i,j,k,l,y,lat,total_latency,k1,k2,k3,k4,m,n;
integer target_num;
integer patcount;
integer pat_delay;
integer input_file,map_file,output_file,weight_file;
integer busy_num;
integer valid_num;

//================================================================
// wire & registers 
//================================================================
reg after_reset;
reg	[3:0] input_data [11:1];
reg	[7:0] temp;
reg [9:0] ALU_mode;
reg [17:0] sqr2,sqr4,sqr6,sqr8,SUM; 
wire [8:0] ROOT_RESULT;
reg [4:0] frame_id_r;
reg [31:0] frame_start_address;
reg [7:0] gold_mem[0:2047];
reg [13:0] weight_r;
reg [3:0] rout_mem[0:4095];
reg [3:0] weight_mem;
reg [3:0] map_mem;
reg [13:0] gold_cost;

reg [3:0] gold;
//================================================================
// clock
//================================================================
always	#(CYCLE/2.0) clk = ~clk;
initial	clk = 0;
//================================================================
// initial
//================================================================
initial begin
    rst_n = 1;    
    in_valid = 1'b0; 
    frame_id = 5'bx;
    net_id = 4'bx;
    loc_x = 6'bx;
    loc_y = 6'bx; 
    
    busy_num = 0;
	
	force clk = 0;
	
        total_latency = 0; 
	reset_signal_task;

	input_file=$fopen(`GOLD_INPUT,"r");
        map_file = $fopen(`GOLD_MAP,"r");
  	output_file=$fopen(`GOLD_OUTPUT,"r");
        weight_file= $fopen(`GOLD_WEIGHT,"r");
        busy_num = 0;
        
        k=$fscanf(input_file,"%d",PATNUM);	
	//PATNUM ;
	for(patcount=0;patcount<PATNUM;patcount=patcount+1)
	begin		
		input_task;
		wait_OUT;
		check_ans;
		$display("\033[0;34mPASS PATTERN NO.%4d,\033[m \033[0;32m Latency: %3d\033[m",
				patcount ,lat);
                $display(" cost : %d ; gold_cost : %d ", weight_r , gold_cost);
	end

	YOU_PASS_task;
	$finish;
end

//===============================================================
// always
//===============================================================

always@(negedge clk)
begin
    if(in_valid===1)
    begin
    //TODO: check out_valid = 0 when in_valid is high
      if(busy !== 0)
      begin
				$display ("---------------------------------------------------------------------------------------------------------------------------------");
                                $display("\n");
				$display ("                                       FAIL!  busy should be low when in_valid is high                    ");
                                $display("\n");
				$display ("---------------------------------------------------------------------------------------------------------------------------------");
				repeat(10) @(negedge clk);
				$finish;
      end
    end  
end




always@(negedge busy)
begin
  busy_num = 1;

end


//================================================================
// task
//================================================================
task reset_signal_task; begin 
    #(0.5);   rst_n=0;
	
	#(8.0);
	if((cost !== 'd0)||(busy !== 1'b0)) begin
		$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		$display ("                                                                        FAIL!                                                               ");
		$display ("                                                  Output signal should be 0 after initial RESET at %8t                                 ",$time);
		$display ("--------------------------------------------------------------------------------------------------------------------------------------------");

		// repeat(2) @(negedge clk);
		$finish;
	end
	#(7);   rst_n=1;
	#(3);   release clk;
end endtask

integer gap;
task input_task; begin
	//gap = $urandom_range(2,4);
        gap = 3;
	repeat(gap)@(negedge clk);
	in_valid = 1;
        k=$fscanf(input_file,"%d",frame_id);
        frame_id_r = frame_id;
        k1=$fscanf(input_file,"%d",target_num);
        valid_num = 2 * target_num;
	for(i=0;i<valid_num;i=i+1) 
	begin	
                if ((i%2)==0)begin
                  k2=$fscanf(input_file,"%d",net_id);
                end		

                k3=$fscanf(input_file,"%d",loc_x);
                k4=$fscanf(input_file,"%d",loc_y);		
		@(negedge clk);	
	end   
	in_valid = 0;
	frame_id = 'dx;
        net_id = 'dx;
        loc_x = 'dx;
        loc_y = 'dx;
end endtask

task wait_OUT; begin
  lat = 0;
  while(busy_num===0) begin
	lat = lat + 1;
//	$display("lat = %d",lat);
	// if(lat == 1000000) begin
  	if(lat == 11000) begin
		$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		$display ("                                                                        FAIL!                                                               ");
		$display ("                                                     The execution latency are over 1M  cycles                                            ");
		$display ("--------------------------------------------------------------------------------------------------------------------------------------------");

		repeat(2)@(negedge clk);
		$finish;
	end
	@(negedge clk);
  end
  total_latency = total_latency + lat;
end endtask 

task check_ans; begin
        gold_cost = 0;
        frame_start_address = {16'd1,frame_id_r[4:1],((frame_id_r[0]==1'd1)?(4'd8):(4'd0)),8'd0};
        k1=$fscanf(output_file,"%d",y); // garbage
        for (m=0;m<2048;m=m+1)begin
           k2=$fscanf(output_file,"%d",gold_mem[m][3:0]); //each 8 bits not 4 bits
           k3=$fscanf(output_file,"%d",gold_mem[m][7:4]); //each 8 bits not 4 bits
           rout_mem[2*m] = gold_mem[m][3:0];
           rout_mem[2*m+1] = gold_mem[m][7:4];
           $write ("%d",gold_mem[m][3:0]);
           $write ("%d",gold_mem[m][7:4]);
           if((m%32)==31)
            $write ("\n");
        end
        $write ("\n");
        $write ("\n");
        $write ("================================================================================ \n");
        weight_r = cost;

        //cal gold_cost
        k1=$fscanf(weight_file,"%d",y); // garbage  
        k1=$fscanf(map_file,"%d",y); // garbage 
        for (n=0;n<4096;n=n+1)begin
           k1=$fscanf(weight_file,"%d",weight_mem); 
           k3=$fscanf(map_file,"%d",map_mem);
           if (map_mem!=rout_mem[n])
             gold_cost = gold_cost + weight_mem;
        end

	if (busy_num===1)
	begin
            for (l=0;l<2048;l=l+1)begin
              $write ("%d",u_DRAM.DRAM_r[frame_start_address+l][3:0]);
              $write ("%d",u_DRAM.DRAM_r[frame_start_address+l][7:4]);
              if((l%32)==31)
              $write ("\n");
            end
            for (j=0;j<2048;j=j+1)begin
		 if (u_DRAM.DRAM_r[frame_start_address+j]!==gold_mem[j])
                                begin
					$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
					$display ("                                                                        FAIL!                                                               ");
					$display ("                                                                   PATTERN NO.%4d                                                           ",patcount);
					$display ("                                                     Ans(out): %h(hex),  Your output : %h(hex)   address: %h(in DRAM) / %d(in map)   at %8t      ",gold_mem[j],u_DRAM.DRAM_r[frame_start_address+j],(frame_start_address+j),j,$time);
					$display ("--------------------------------------------------------------------------------------------------------------------------------------------");
					repeat(10) @(negedge clk);
					$finish;
				end
            end
            if (weight_r!==gold_cost)           
	    begin

		  $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		  $display ("                                                                        FAIL!                                                               ");
		  $display ("                                                                   PATTERN NO.%4d                                                           ",patcount);
		  $display ("                                                 Golden ans(cost): %d(decimal),  Your cost : %d(decimal)    at %8t       ",gold_cost,weight_r,$time);
		  $display ("--------------------------------------------------------------------------------------------------------------------------------------------");
		  repeat(10) @(negedge clk);
		  $finish;
            end 	
        @(negedge clk);	
	
	end		
	busy_num = 0;
		
end endtask


task YOU_PASS_task;begin

$display ("----------------------------------------------------------------------------------------------------------------------");
$display ("                                                  Congratulations!                						            ");
$display ("                                           You have passed all patterns!          						            ");
$display ("                                           Your execution cycles = %5d cycles   						            ", total_latency);
$display ("                                           Your clock period = %.1f ns        					                ", CYCLE);
$display ("                                           Your total latency = %.1f ns         						            ", total_latency*CYCLE);
$display ("----------------------------------------------------------------------------------------------------------------------");



$finish;	
end endtask

task fail;begin
$display("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@");
$display("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@8Oo::::ooOOO8@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@");
$display("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@o:   ..::..       .:o88@@@@@@@@@@@8OOoo:::..::oooOO8@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@");
$display("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@8.   :8@@@@@@@@@@@@Oo..                   ..:.:..      .:O8@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@");
$display("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@8.  .8@@@@@@@@@@@@@@@@@@@@@@88888888888@@@@@@@@@@@@@@@@@8.    :O@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@");
$display("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@:. .@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@8.   :8@@@@@@@@@@@@@@@@@@@@@@@@@@@@@");
$display("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@O  O@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@8.   :o@@@@@@@@@@@@@@@@@@@@@@@@@@");
$display("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@o  8@@@@@@@@@@@@@8@@@@@@@@8o::o8@@@@@8ooO88@@@@@@@@@@@@@@@@@@@@@@@@8:.  .:ooO8@@@@@@@@@@@@@@@@@@@@");
$display("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@o  :@@@@@@@@@@O      :@@@O   ..  :O@@@:       :@@@@OoO8@@@@@@@@@@@@@@@@Oo...     ..:o@@@@@@@@@@@@@@");
$display("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  :8@@@@@@@@@:  .@@88@@@8:  o@@o  :@@@. 0@@@.  O@@@      .O8@@@@@@@@@@@@@@@@@@8OOo.    O8@@@@@@@@@@");
$display("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  o@@@@@@@@@@O.      :8@8:  o@@O. .@@8  000o  .8@@O  O8O:  .@@o .O@@@@@@@@@@@@@@@@@@@o.  .o@@@@@@@@");
$display("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@. :8@@@@@@@@@@@@@@@:  .o8:  o@@o. .@@O  ::  .O@@@O.  o0o.  :@@O. :8@8::8@@@@@@@@@@@@@@@8O  .:8@@@@@");
$display("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  o8@@@@@@@@@@@OO@@8.  o@8   ''  .O@@o  O@:  :O@@:  ::   .8@@@O. .:   .8@@@@@@@@@@@@@@@@@@O   8@@@@");
$display("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@. .O@@@@@@@@@@O      .8@@@@Oo::oO@@@@O  8@8:  :@8  :@O. :O@@@@8:   .o@@@@@@@@@@@@@@@@@@@@@@o  :8@@@");
$display("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@8:  8@@@@@@@@@@@@8@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@o:8@8:  :@@@@:  .O@@@@@@@@@@@@@@@@@@@@@@@@8:  o@@@");
$display("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@:  .8@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@OoO@@@O  :8@@@@@@@@@@@@@@@@@@@@@@@@@@8o  8@@");
$display("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@8.   o8@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@88@@@@@@@@@@@@@@@@@@@8::@@@@@88@@@@@@@@@@@@@@@@@@@@@@@  :8@");
$display("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@O.  .:8@@@@@@@@@@@@@@@@@@@88OOoo::....:O88@@@@@@@@@@@@@@@@@@@@8o .8@@@@@@@@@@@@@@@@@@@@@@:  o@");
$display("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@o.   ..:o8888888OO::.      ....:o:..     oO@@@@@@@@@@@@@@@@8O..@@ooO@@@@@@@@@@@@@@@@@@O. :@");
$display("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Oo::.          ..:OO@@@@@@@@@@@@@@@@O:  .o@@@@@@@@@@@@@@@@@@@O   8@@@@@@@@@@@@@@@@@. .O@");
$display("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@8O   .8@@@@@@@@@@@@@@@@@@@@@O  O@@@@@@@@@@@@@. o8@");
$display("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@O    .O@@@@@@@@@@@@@@@@@@8..8@@@@@@@@@@@@@. .O@");
$display("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@O:           ..:O88@888@@@@@@@@@@@@@@@@@@@@@@@O  O@@");
$display("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@o.                          ..:oO@@@@@@@@@@@@@@@o  @@@");
$display("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.                      .o@@8O::.    o8@@@@@@@@@@@O  8@@");
$display("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@o                         :O@@@@@@@o.  :O8@@@@@@@@8  o8@");
$display("@@@@@@@@@@@@@@@@@@@@@@@@@88OO888@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@8888OOOOO8@@8888@@@@@O.                          .@@@@@@@@@:.  :@@@@@@@@@. .O@");
$display("@@@@@@@@@@@@@@@@@@@@8o:           O8@@@@@@@@@@@@@@@@@@@8OO:.                     .::                            :8@@@@@@@@@.  .O@@@@@@@o. o@");
$display("@@@@@@@@@@@@@@@@@@.                 o8@@@@@@@@@@@O:.         .::oOOO8Oo:..::::..                                 o@@@@@@@@@@8:  8@@@@@@o. o@");
$display("@@@@@@@@@@@@@@@@:                    .@@@@@Oo.        .:OO@@@@@@@@@@@@@@@@@@@@@@@@@o.                            O@@@@@@@@@@@@  o8@@@@@O. o@");
$display("@@@@@@@@@@@@@@:                       o88.     ..O88@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@888O.                     .8@@@@@@@@@@@@  o8@@@@@: .O@");
$display("@@@@@@@@@@@@O:                             :o8@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@:                  .8@@@@@@@@@@@8o  8@@@@@O  O@@");
$display("@@@@@@@@@@@O.                            :8@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@o.              :8@@@@@@@@@@8.  .O@@@@o.  :@@@");
$display("@@@@@@@@@@@:                          :O8@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@O:          .o@@@@@@@@@8o   .o@@@8:.  .@@@@@");
$display("@@@@@@@@@@@.                        O8@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@O.    .o8@@@@@@@@@@O  :O@@8o:   .O@@@@@@@");
$display("@@@@@@@@@@@.                      :O@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@O:   o8@@@@@@@@8           oO@@@@@@@@@@");
$display("@@@@@@@@@@@:                     o@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.   .@@@@@@@O.      .:o8@@@@@@@@@@@@@");
$display("@@@@@@@@@@@8o                   8@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@o   :@@@@O     o8@@@@@@@@@@@@@@@@@@@");
$display("@@@@@@@@@@@@@8.               .O@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@:   .@@@8..:8@@@@@@@@@@@@@@@@@@@@@@");
$display("@@@@@@@@@@@@@@@8:            .o@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@O.  :8@@@@@@@@@@@@@@@@@@@@@@@@@@@@");
$display("@@@@@@@@@@@@@@@@@@8O.        8@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@   :@@@@@@@@@@@@@@@@@@@@@@@@@@@@");
$display("@@@@@@@@@@@@@@@@@@@@@@@8o   o@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@o   O@@@@@@@@@@@@@@@@@@@@@@@@@@@");
$display("@@@@@@@@@@@@@@@@@@@@@@@O   O@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@O   :@@@@@@@@@@@@@@@@@@@@@@@@@@");
$display("@@@@@@@@@@@@@@@@@@@@@@8   :@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@:   8@@@@@@@@@@@@@@@@@@@@@@@@@");
$display("@@@@@@@@@@@@@@@@@@@@@8o  :8@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@:..   .:o@@@@@@@@@@@@@@@@@@8.  O@@@@@@@@@@@@@@@@@@@@@@@@@");
$display("@@@@@@@@@@@@@@@@@@@@@8o  :8@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@O.         .:@@@@@@@@@@@@@@@@@:  :O@@@@@@@@@@@@@@@@@@@@@@@@");
$display("@@@@@@@@@@@@@@@@@@@@@O.  o@@@@@@@@@@@@@@@@@@@@@@8OOO8@@@@@@@@@@@@@@@@@@@@@@@@@@@8.             .@@@@@@@@@@@@@@@@.  .O@@@@@@@@@@@@@@@@@@@@@@@");
$display("@@@@@@@@@@@@@@@@@@@@o.  .@@@@@@@@@@@@@@@@@@@8:.       :8@@@@@@@@@@@@@@@@@@@@@@@@8.               o8@@@@@@@@@@@@@o. .:@@@@@@@@@@@@@@@@@@@@@@@");
$display("@@@@@@@@@@@@@@@@@@@@o.  :@@@@@@@@@@@@@@@@@O            .@@@@@@@@@@@@@@@@@@@@@@@@@:                .8@@@@@@@@@@@@O.  :@@@@@@@@@@@@@@@@@@@@@@@");
$display("@@@@@@@@@@@@@@@@@@@@O.  .@@@@@@@@@@@@@@@@:             .8@@@@@@@@@@@@@@@@@@@@@@@@O:                o@@@@@@@@@@@@O:  .@@@@@@@@@@@@@@@@@@@@@@@");
$display("@@@@@@@@@@@@@@@@@@@@O.  .@@@@@@@@@@@@@@8:               8@@@@@@@@@@@@@@@@@@@@@@@@@@.               o@@@@@@@@@@@@O:  .@@@@@@@@@@@@@@@@@@@@@@@");
$display("@@@@@@@@@@@@@@@@@@@@O.  .@@@@@@@@@@@@@o.                8@@@@@@@@@@@@@@@@@@@@@@@@@@8o             .8@@@@@@@@@@@@O.  .@@@@@@@@@@@@@@@@@@@@@@@");
$display("@@@@@@@@@@@@@@@@@@@@8:  .@@@@@@@@@@@@@                 :@@@@@@@@@@@@@@@@@@@@@@@@@@@@@8:.        O8@@@@@@@@@@@@@@o.  :@@@@@@@@@@@@@@@@@@@@@@@");
$display("@@@@@@@@@@@@@@@@@@@@@o   8@@@@@@@@@@@@.               :8@@@@@@@@@          :8@@@@@@@@@@@8OoooO@@@@@@@@@@@@@@@@@@.  .o@@@@@@@@@@@@@@@@@@@@@@@");
$display("@@@@@@@@@@@@@@@@@@88O:   O@@@@@@@@@@@@O:             .@@@@@@@@O             .8@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@8   :8@@@@@@@@@@@@@@@@@@@@@@@");
$display("@@@@@@@@@@@@@@@@O:.       :O8@@@@@@@@@@8o           :O@@@@@@@8:             :@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@8:       :o@@@@@@@@@@@@@@@@@@@");
$display("@@@@@@@@@@@@@@o              ..:8@@@@@@@@@8o:::.:O8@@@@@@@@@@@8.           :@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@O:.             o@@@@@@@@@@@@@@@@@");
$display("@@@@@@@@@@@@8o                   :@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@:.     .o@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@8                  o8@@@@@@@@@@@@@@@");
$display("8OOOooooOOoo:.                    :OOOOOOOOOO8888OOOOOOOOOOOoo:ooOOOo: .OOOOOOOOOO888OOooOO888OOOOOooO8:                   .:OOOOOOOOOOO88@@");
$display("            .                                                                                                                               ");
$display("@@@@@@@@@@@@@@8o                 .8@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@8                    :8@@@@@@@@@@@@@@@");
$display("@@@@@@@@@@@@@@@@8O.             o8@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@8o                 .@@@@@@@@@@@@@@@@@");
$display("@@@@@@@@@@@@@@@@@@@@::.       :O@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@O..         .:8@@@@@@@@@@@@@@@@@@");
$display("@@@@@@@@@@@@@@@@@@@@@@@@@88O8@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@88@@@@@@@@@@@@@@@@@@@@@@@@@@");
end
endtask


endmodule


