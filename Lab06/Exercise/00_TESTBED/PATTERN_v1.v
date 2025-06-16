// `ifdef RTL
//     `define CYCLE_TIME 17.5
// `endif
// `ifdef GATE
//     `define CYCLE_TIME 17.5
// `endif

// `define SEED_NUMBER    10
// `define PATTERN_NUMBER 1000

// module PATTERN(
//     // Output signals
//     clk,
// 	rst_n,
// 	in_valid,
//     in_syndrome, 
//     // Input signals
//     out_valid, 
// 	out_location
// );

// // ========================================
// // Input & Output
// // ========================================
// output reg clk, rst_n, in_valid;
// output reg [3:0] in_syndrome;

// input out_valid;
// input [3:0] out_location;

// // ========================================
// // Parameter
// // ========================================
// integer i,j,k, i_pat;
// integer total_latency, latency;
// integer SEED = `SEED_NUMBER;
// integer out_num;
// integer t;

// //======================================
// //            REGISTERS
// //======================================
// reg [3:0] golden_syndrome[0:5];
// reg [14:0] golden_error_pattern;
// reg [3:0] golden_error_location [0:2];
// reg [1:0] random_error_number;

// wire [3:0] log_table[0:15];
// wire [3:0] decimal_table[0:15];

// //================================================================
// // clock
// //================================================================
// real CYCLE = `CYCLE_TIME;
// always #(CYCLE/2.0) clk = ~clk;

// //======================================
// //              MAIN
// //======================================
// initial begin

// 	//reset signal
// 	reset_task; 
//     repeat (4) @(negedge clk);

// 	i_pat = 0;
// 	total_latency = 0;


// 	for (i_pat = 0; i_pat < `PATTERN_NUMBER; i_pat = i_pat + 1) begin
//         input_task;
//         wait_out_valid_task;
//         check_ans_task;
// 		total_latency = total_latency + latency;
//         $display("\033[1;34mPASS PATTERN \033[1;32mNO.%4d   Cycles = %4d\033[m", i_pat, latency);
//     end

// 	YOU_PASS_task;

// end

// //======================================
// //              TASKS
// //======================================

// assign log_table[0] = 'd1;
// assign log_table[1] = 'd2;
// assign log_table[2] = 'd4;
// assign log_table[3] = 'd8;
// assign log_table[4] = 'd3;
// assign log_table[5] = 'd6;
// assign log_table[6] = 'd12;
// assign log_table[7] = 'd11;
// assign log_table[8] = 'd5;
// assign log_table[9] = 'd10;
// assign log_table[10] = 'd7;
// assign log_table[11] = 'd14;
// assign log_table[12] = 'd15;
// assign log_table[13] = 'd13;
// assign log_table[14] = 'd9;
// assign log_table[15] = 'd0;

// assign decimal_table[0] = 'd15;
// assign decimal_table[1] = 'd0;
// assign decimal_table[2] = 'd1;
// assign decimal_table[3] = 'd4;
// assign decimal_table[4] = 'd2;
// assign decimal_table[5] = 'd8;
// assign decimal_table[6] = 'd5;
// assign decimal_table[7] = 'd10;
// assign decimal_table[8] = 'd3;
// assign decimal_table[9] = 'd14;
// assign decimal_table[10] = 'd9;
// assign decimal_table[11] = 'd7;
// assign decimal_table[12] = 'd6;
// assign decimal_table[13] = 'd13;
// assign decimal_table[14] = 'd11;
// assign decimal_table[15] = 'd12;

// always @(negedge clk) begin
// 	if(out_valid === 0 && out_location !== 'd0) begin
// 		$display("*************************************************************************");
// 		$display("*                              \033[1;31mFAIL!\033[1;0m                                    *");
// 		$display("*       The out_data should be reset when your out_valid is low.        *");
// 		$display("*************************************************************************");
// 		repeat(1) #(CYCLE);
// 		$finish;
// 	end
// end

// task reset_task; begin
// 	rst_n = 1'b1;
// 	in_valid = 1'b0;
//     in_syndrome = 'dx;


// 	force clk = 0;

// 	// Apply reset
//     #CYCLE; rst_n = 1'b0; 
//     repeat(2) #(CYCLE); rst_n = 1'b1;

// 	// Check initial conditions
//     if (out_valid !== 'd0 || out_location !== 'd0) begin
//         $display("************************************************************");  
//         $display("                           \033[1;31mFAIL!\033[1;0m                             ");    
//         $display("*  Output signals should be 0 after initial RESET at %8t *", $time);
//         $display("************************************************************");
//         repeat (1) #CYCLE;
//         $finish;
//     end

// 	#CYCLE; release clk;
// end endtask

// task input_task; begin
    
//     random_input;

//     in_valid = 1;

//     for(i = 0; i < 6; i = i + 1)begin

//         in_syndrome = golden_syndrome[i];
//         @(negedge clk);

//     end
//     in_valid = 0;
// 	in_syndrome = 'dx;

// end
// endtask

// task random_input; 
//     reg [1:0] count;
//     reg [3:0] random_idx;
// begin
//     random_error_number = {$random(SEED)} % 3 + 1;
//     golden_error_pattern = 'd0;
//     count = random_error_number;

//     while(count > 0) begin
//         random_idx = {$random(SEED)} % 15;

//         if(golden_error_pattern[random_idx] == 0) begin
//             golden_error_pattern[random_idx] = 1;
//             count = count - 1;
//         end
//     end

//     count = 0;

//     for(i = 0; i < 3; i = i + 1) begin
//         golden_error_location[i] = 'd15;
//     end

//     for(i = 0; i < 15; i = i + 1) begin
//         if(golden_error_pattern[i] == 1) begin
//             golden_error_location[count] = i;
//             count = count + 1;
//         end
//     end

//     for(i = 0; i < 6; i = i + 1) begin
//         golden_syndrome[i] = 'd0;
//         for(j = 0; j < 15; j = j + 1) begin
//             if(golden_error_pattern[j] == 1) begin
//                 golden_syndrome[i] = golden_syndrome[i] ^ log_table[(j * (i + 1)) % 15];
//                 //$display(" Received: data = %d", golden_syndrome[i]);
//             end
//         end
//         golden_syndrome[i] = decimal_table[golden_syndrome[i]];
//     end

// end 
// endtask


// task wait_out_valid_task; begin
    
// 	latency = 0;

// 	while (out_valid !== 1'b1) begin
// 		latency = latency + 1;
// 		if(latency == 2000)begin
//             $display("*************************************************************************");
// 		    $display("*                              \033[1;31mFAIL!\033[1;0m                                    *");
// 		    $display("*         The execution latency is limited in 2000 cycles.              *");
// 		    $display("*************************************************************************");
// 		    repeat(1) @(negedge clk);
// 		    $finish;
//         end

// 		@(negedge clk);
// 	end
	
// end
// endtask

// task check_ans_task; begin 

//     out_num = 0;

//     while(out_valid === 1) begin
// 	    if (out_location !== golden_error_location[out_num]) begin
//             $display("************************************************************");  
//             $display("                          \033[1;31mFAIL!\033[1;0m                              ");
//             $display(" At out NO.%4d ", out_num);
//             $display(" Expected: data = %b", golden_error_location[out_num]);
//             $display(" Received: data = %b", out_location);
//             $display("************************************************************");
//             repeat (1) @(negedge clk);
//             $finish;
//         end
//         else begin
//             @(negedge clk);
//             out_num = out_num + 1;
//         end
//     end

//     if(out_num !== 3) begin
//             $display("************************************************************");  
//             $display("                            \033[1;31mFAIL!\033[1;0m                            ");
//             $display(" Expected 3 out_valid, but found %d", out_num);
//             $display("************************************************************");
//             repeat(2) @(negedge clk);
//             $finish;
//     end

//     t = $urandom_range(1,3);
//     repeat(t) @(negedge clk);
// end endtask



// task YOU_PASS_task; begin
//     $display("----------------------------------------------------------------------------------------------------------------------");
//     $display("                                                  \033[0;32mCongratulations!\033[m                                                     ");
//     $display("                                           You have passed all patterns!                                               ");
//     $display("                                           Your execution cycles = %7d cycles                                          ", total_latency);
//     $display("                                           Your clock period = %.1f ns                                                 ", CYCLE);
//     $display("                                           Total Latency = %.1f ns                                                    ", total_latency * CYCLE);
//     $display("----------------------------------------------------------------------------------------------------------------------");
//     repeat (2) @(negedge clk);
//     $finish;
// end endtask


// endmodule 


`define CYCLE_TIME 17.5

module PATTERN(
    // Output signals
    clk,
	rst_n,
	in_valid,
    in_syndrome, 
    // Input signals
    out_valid, 
	out_location
);

// ========================================
// Input & Output
// ========================================
output reg clk, rst_n, in_valid;
output reg [3:0] in_syndrome;

input out_valid;
input [3:0] out_location;

// ========================================
// Parameter
// ========================================
real CYCLE = `CYCLE_TIME;

integer i, j, k;
integer i0, j0;
integer i1, j1;
integer latency, latency2, total_latency;
integer patcount, set_count;
integer input_file, output_file;

reg reset_check;
reg [1:0] ans_pass;
reg check_ans;

reg [3:0] golden_in_syndrome [5:0];

reg [3:0] your_ans [2:0];
reg [3:0] golden_ans [2:0];

//======================================
//              MAIN
//======================================
initial begin
    reset_signal_task;
	total_latency = 0;

    input_file=$fopen("../00_TESTBED/input.txt","r");
	output_file=$fopen("../00_TESTBED/output.txt","r");

	for(i = 0; i < 3; i = i +1 )begin
		if (out_valid == 1) 
			overlap_check_fail;
		@(negedge clk);
	end

    for (patcount = 0; patcount < 575; patcount = patcount + 1) begin	
        input_task;
        wait_out_vaild_task;
        check_ans_task;
        $display("\033[1;34mPASS PATTERN \033[1;32mNO.%4d\033[m", patcount);
        total_latency = total_latency + latency; 
    end
	display_pass;
    repeat(3) @(negedge clk);
    $finish;
end

//======================================
//              Clock
//======================================
always #(CYCLE/2.0) clk = ~clk;
initial	clk = 0;

//======================================
//              TASKS
//======================================
task reset_signal_task; begin
    reset_check = 0;
    in_valid = 0;
    rst_n = 1;
    force clk = 0;
    #40;
    rst_n = 0;
    #100;
    if ((out_valid == 0) && (out_location == 0)) begin
        reset_check = 1;
    end
    if (reset_check == 0) begin
        reset_check_fail;
    end  
    rst_n = 1;
    reset_check = 0;
    #40;
    rst_n = 1;
    if ((out_valid == 0) && (out_location == 0)) begin
        reset_check = 1;
    end
    if (reset_check == 0) begin
        reset_check_fail;
    end 
    #40;
    release clk;
    if (out_valid == 1) begin
        overlap_check_fail;
    end
end endtask


task input_task; begin
    for (i = 0; i < 6; i = i + 1) begin
        k = $fscanf(input_file, "%d", golden_in_syndrome[i]); 
    end
    for (i = 0; i < 3; i = i + 1) begin
        k = $fscanf(output_file, "%d", golden_ans[i]); 
    end

	if (out_valid == 1) begin
		overlap_check_fail;
	end	
    repeat($urandom_range(1, 3)) @(negedge clk);
    in_valid = 1;
    // L0
    for(i = 0; i < 6; i++) begin	
        if (out_valid == 1) begin
            overlap_check_fail;
        end	
        else begin
            in_syndrome = golden_in_syndrome[i];
        end
        @(negedge clk);
    end

    in_syndrome = 'bx;
    in_valid = 0;

    //repeat($urandom_range(2, 5)) @(negedge clk);
end endtask


task wait_out_vaild_task; begin
    latency = 0;
	while(out_valid == 0)begin
		reset_check = 0;
		if((out_location ==0))begin
			reset_check = 1;
		end

		if(reset_check == 0)begin
			out_reset_fail;
		end

        if(latency == 2000)begin
            //YOU_FAIL__task;
            execution_latency_fail;
        end

        latency = latency + 1;
        @(negedge clk);
    end
end endtask

task check_ans_task; begin
	ans_pass = 0;
    i = 0;
    j = 0;
    latency2 = 0;
    while(out_valid == 1)begin
        check_ans = 0;
        your_ans[i] = out_location;
        i = i + 1;
        if(latency2 >= 3)begin
            out_over_cycles_fail;
        end

        latency2 = latency2 + 1;
        @(negedge clk);
    end

    if(latency2 < 3)
		out_end_early_fail;

    for (i = 0; i < 3; i++) begin
        if (golden_ans[i] == your_ans[i]) begin
            ans_pass = ans_pass + 1;
        end
    end

    if (ans_pass != 3) begin
        out_location_fail;
    end

end endtask

task display_pass; begin
    $display("**************************************************");
	$display("                  \033[0;32mCongratulations!\033[m                ");
	$display("              execution cycles = %7d", total_latency);
	$display("              clock period = %4fns", CYCLE);
	$display("**************************************************");
    $finish;
end endtask


task out_location_fail; begin
    $display("        Out_location is wrong !!!!!!        ");
    $display("        Your answer is   : %1d %1d %1d      ", your_ans[0], your_ans[1], your_ans[2]);
    $display("        Gloden answer is : %1d %1d %1d      ", golden_ans[0], golden_ans[1], golden_ans[2]);
    $finish;
end endtask

task reset_check_fail; begin
    $display("        All output signals should be reset !!!!!!        ");
    //$finish;
end endtask

task overlap_check_fail; begin
    $display("        Out_valid cannot overlap with in_valid !!!!!!        ");
    $finish;
end endtask

task out_reset_fail; begin
    $display("        The out should be reset after your out_valid is pulled down !!!!!!        ");
    $finish;
end endtask

task out_over_cycles_fail; begin
    $display("        Your output exceeds 3 cycles !!!!!!        ");
    $finish;
end endtask

task out_end_early_fail; begin
    $display("        Your output cannot end early !!!!!!        ");
    $finish;
end endtask

task execution_latency_fail; begin
    $display("        The execution latency is limited in 2000 cycles !!!!!!        ");
    $finish;
end endtask


endmodule