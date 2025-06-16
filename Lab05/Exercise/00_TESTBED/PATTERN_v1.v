`define CYCLE_TIME 8.0

module PATTERN(
    clk,
    rst_n,
    in_valid,
    in_valid2,
    in_data,
    out_valid,
    out_sad
);
output reg clk, rst_n, in_valid, in_valid2;
output reg [11:0] in_data;
input out_valid;
input out_sad;

//======================================
//      PARAMETERS & VARIABLES
//======================================
integer pat_read, ans_read, file;
integer i,j,k, i_pat, i_dx;
integer idx_count;
integer total_latency, latency;
integer total_pattern;
integer SEED = 9527;
integer out_num;
integer t;

//======================================
//            REGISTERS
//======================================
reg [7:0] img[0:1][0:127][0:127];
reg [7:0] mv_integer[0:7];
reg [3:0] mv_fraction[0:7];
reg [3:0] golden_point[0:1];
reg [23:0] golden_sad[0:1];
reg [55:0] goledn_answer;


//======================================
//              Clock
//======================================
real CYCLE = `CYCLE_TIME;
always #(CYCLE/2.0) clk = ~clk;

//======================================
//              MAIN
//======================================
initial begin
    pat_read = $fopen("../00_TESTBED/input.txt", "r");
    ans_read = $fopen("../00_TESTBED/output_int.txt", "r");
	//reset signal
	reset_task; 
    repeat (4) @(negedge clk);

	i_pat = 0;
	total_latency = 0;
    file = $fscanf(pat_read, "%d\n", total_pattern);

	for (i_pat = 0; i_pat < total_pattern; i_pat = i_pat + 1) begin
        input_task_1;
        for(idx_count = 0; idx_count < 64; idx_count = idx_count + 1)begin
            input_task_2;
            wait_out_valid_task;
            check_ans_task;
		    total_latency = total_latency + latency;
            $display("\033[1;34mPASS PATTERN \033[1;32mNO.%4d   \033[1;34mSET \033[1;32mNO.%4d   Cycles = %4d\033[m", i_pat, idx_count, latency);
        end
    end

	YOU_PASS_task;

end
//======================================
//              TASKS
//======================================

always @(negedge clk) begin
	if(out_valid === 0 && out_sad !== 'd0) begin
		$display("*************************************************************************");
		$display("*                              \033[1;31mFAIL!\033[1;0m                                    *");
		$display("*       The out_data should be reset when your out_valid is low.        *");
		$display("*************************************************************************");
		repeat(1) #(CYCLE);
		$finish;
	end
end

task reset_task; begin
	rst_n = 1'b1;
	in_valid = 1'b0;
    in_valid2 = 1'b0;
    in_data = 'dx;


	force clk = 0;

	// Apply reset
    #CYCLE; rst_n = 1'b0; 
    repeat(1) #(CYCLE); rst_n = 1'b1;

	// Check initial conditions
    if (out_valid !== 'd0 || out_sad !== 'd0) begin
        $display("************************************************************");  
        $display("                           \033[1;31mFAIL!\033[1;0m                             ");    
        $display("*  Output signals should be 0 after initial RESET at %8t *", $time);
        $display("************************************************************");
        repeat (1) #CYCLE;
        $finish;
    end

	#CYCLE; release clk;
end endtask

task input_task_1; begin

    for(i = 0; i < 2; i = i + 1)begin
        for(j = 0; j < 128; j = j + 1)begin
            for(k = 0; k < 128; k = k + 1)begin
                file = $fscanf(pat_read, "%d", img[i][j][k]);
            end
        end
    end

    in_valid = 1;

    for(i = 0; i < 2; i = i + 1)begin
        for(j = 0; j < 128; j = j + 1)begin
            for(k = 0; k < 128; k = k + 1)begin
                in_data = {img[i][j][k],4'bxxxx};
                @(negedge clk);
            end
        end
    end
    in_valid = 0;
	in_data = 'dx;

    t = $urandom_range(3,6);
    repeat(t) @(negedge clk);
end
endtask

task input_task_2; begin
    
    for(i = 0; i < 8; i = i + 1)begin
        file = $fscanf(pat_read, "%d", mv_integer[i]);
        file = $fscanf(pat_read, "%d", mv_fraction[i]);
    end

    in_valid2 = 1;


    for(i = 0; i < 8; i = i + 1)begin
        in_data = {mv_integer[i],mv_fraction[i]};
        @(negedge clk);
    end

    in_valid2 = 0;
	in_data = 'dx;

end
endtask

task wait_out_valid_task; begin
    for(i = 0; i < 2; i = i + 1)begin
        file = $fscanf(ans_read, "%d", golden_point[i]);
        file = $fscanf(ans_read, "%d", golden_sad[i]);
    end
    goledn_answer = {golden_point[1], golden_sad[1], golden_point[0], golden_sad[0]};
    
	latency = 0;

	while (out_valid !== 1'b1) begin
		latency = latency + 1;
		if(latency == 1000)begin
            $display("*************************************************************************");
		    $display("*                              \033[1;31mFAIL!\033[1;0m                                    *");
		    $display("*         The execution latency is limited in 1000 cycles.              *");
		    $display("*************************************************************************");
		    repeat(1) @(negedge clk);
		    $finish;
        end

		@(negedge clk);
	end
	
end
endtask

task check_ans_task; begin 

    out_num = 0;

    while(out_valid === 1) begin
	    if (out_sad !== goledn_answer[out_num]) begin
            $display("************************************************************");  
            $display("                          \033[1;31mFAIL!\033[1;0m                              ");
            $display(" At out NO.%4d    golden answer = %b", out_num, goledn_answer);
            $display(" Expected: data = %b", goledn_answer[out_num]);
            $display(" Received: data = %b", out_sad);
            $display("************************************************************");
            repeat (1) @(negedge clk);
            $finish;
        end
        else begin
            @(negedge clk);
            out_num = out_num + 1;
        end
    end

    if(out_num !== 56) begin
            $display("************************************************************");  
            $display("                            \033[1;31mFAIL!\033[1;0m                            ");
            $display(" Expected 56 out_valid, but found %d", out_num);
            $display("************************************************************");
            repeat(2) @(negedge clk);
            $finish;
    end

    t = $urandom_range(2,5);
    repeat(t) @(negedge clk);
end endtask



task YOU_PASS_task; begin
    $display("----------------------------------------------------------------------------------------------------------------------");
    $display("                                                  \033[0;32mCongratulations!\033[m                                                     ");
    $display("                                           You have passed all patterns!                                               ");
    $display("                                           Your execution cycles = %7d cycles                                          ", total_latency);
    $display("                                           Your clock period = %.1f ns                                                 ", CYCLE);
    $display("                                           Total Latency = %.1f ns                                                    ", total_latency * CYCLE);
    $display("----------------------------------------------------------------------------------------------------------------------");
    repeat (2) @(negedge clk);
    $finish;
end endtask






endmodule