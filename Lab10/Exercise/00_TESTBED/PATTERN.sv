
// // `include "../00_TESTBED/pseudo_DRAM.sv"
// `include "Usertype.sv"

// program automatic PATTERN(input clk, INF.PATTERN inf);
// import usertype::*;
// //================================================================
// // parameters & integer
// //================================================================
// parameter DRAM_p_r = "../00_TESTBED/DRAM/dram.dat";
// parameter MAX_CYCLE=1000;

// //================================================================
// // wire & registers 
// //================================================================
// logic [7:0] golden_DRAM [((65536+8*256)-1):(65536+0)];  // 256 box

// //================================================================
// // class random
// //================================================================

// /**
//  * Class representing a random action.
//  */
// class random_act;
//     randc Action act_id;
//     constraint range{
//         act_id inside{Purchase, Restock, Check_Valid_Date};
//     }
// endclass

// endprogram

// `include "../00_TESTBED/pseudo_DRAM.sv"
`include "Usertype.sv"
`define PATNUM 4530
`define SEED 4095
program automatic PATTERN(input clk, INF.PATTERN inf);
import usertype::*;
//================================================================
// parameters & integer
//================================================================
parameter DRAM_p_r = "../00_TESTBED/DRAM/dram.dat";  
parameter MAX_CYCLE=1000;
parameter seed = `SEED;
parameter total_patnum = `PATNUM;
integer pat_id, purchase_cnt;;
int BASE_ADDR;
int wait_val_time, out_val_time;
int total_latency;
int delay;
int flower_count, Rose_count, Lily_count, Carnation_count, Baby_Breath_count;
//================================================================
// wire & registers 
//================================================================
logic [7:0] golden_DRAM [((65536+8*256)-1):(65536+0)];  // 32 box
logic golden_complete;
Dram_data dram_data;

Action golden_action;
Strategy_Type golden_strategy;
Data_No golden_data_no;
Mode golden_mode;
Mode mode_table [0:2];
Warn_Msg golden_warn_msg;
Date golden_date;
Stock golden_stock_rose, golden_stock_lily, golden_stock_carnation, golden_stock_baby_breath;
Data_Dir old_dram_data;
Data_Dir new_dram_data;
//================================================================
// class random
//================================================================

/**
 * Class representing a random action.
 */
class random_act;
    rand Action act_id;
    constraint range{
        act_id inside{Purchase, Restock, Check_Valid_Date};
    }
    function new(int seed);
        this.srandom(seed);
    endfunction
endclass

class random_strategy;
    randc Strategy_Type strategy;
    constraint range{
        strategy inside{Strategy_A, Strategy_B, Strategy_C, Strategy_D, Strategy_E, Strategy_F, Strategy_G, Strategy_H};
    }
    function new(int seed);
        this.srandom(seed);
    endfunction //new()
endclass //random_purchase

class random_mode;
    randc Mode mode;
    constraint range {
        mode inside{Single, Group_Order, Event};
    }
    function new(int seed);
        this.srandom(seed);
    endfunction //new()
endclass //random_restock

class random_date;
    randc Date date;
    constraint month_range{
        date.M inside{[1:12]}; // set legel month
    }
    constraint day_range{ // set legel day
        if (date.M == 2)  date.D inside{[1:28]};
        else if (date.M inside{4, 6, 9, 11})  date.D inside{[1:30]};
        else  date.D inside{[1:31]};
    }
    function new(int seed);
        this.srandom(seed);
    endfunction //new()
endclass //random_check_valid_date

class random_data_no;
    randc Data_No data_no;
    function new(int seed);
        this.srandom(seed);
    endfunction //new()
endclass //random_data_no

class random_restock;
    randc Stock restock_num;
    function new(int seed);
        this.srandom(seed);
    endfunction //new()
endclass //random_restock

class random_delay; 
    randc int cycle_delay;
    constraint range{
        cycle_delay inside{[0:3]};
    }
    function new(int seed);
        this.srandom(seed);
    endfunction //new()
endclass //random_delay

// Randomization
random_act rand_action = new(seed);
random_strategy rand_strategy = new(seed);
random_mode rand_mode = new(seed);
random_date rand_date = new(seed);
random_data_no rand_data_no = new(seed);
random_restock rand_restock = new(seed);
random_delay rand_delay = new(seed);
//================================================================
// initial
//================================================================

initial begin
    $readmemh(DRAM_p_r, golden_DRAM);
    reset_signal_task;
    mode_table = {Single, Group_Order, Event};
    purchase_cnt = 0;
    for (pat_id = 0; pat_id < total_patnum; pat_id = pat_id + 1) begin
        golden_warn_msg = No_Warn;
        golden_complete = 1'b0;
        rand_value_generator;
        delay_task;
        input_task;
        get_dram_data;
        cal_answer_task;
        write_back_dram;
        wait_out_valid;
        check_ans;
        $display("\033[1;34mPASS PATTERN \033[1;32mNO.%4d  Cycles = %4d\033[m", pat_id, wait_val_time);
    end
    display_pass;
end
//================================================================
// task
//================================================================
task reset_signal_task;
begin
    inf.sel_action_valid = 1'b0;
    inf.strategy_valid = 1'b0;
    inf.mode_valid = 1'b0;
    inf.date_valid = 1'b0;
    inf.data_no_valid = 1'b0;
    inf.restock_valid = 1'b0;
    inf.D = 72'bx;
    total_latency = 0;
	inf.rst_n = 1'b1;
	#(0.5) inf.rst_n = 1'b0;
	#(5.0);
	if ((inf.out_valid !== 0) || (inf.warn_msg !== 0) || (inf.complete !== 0)) begin
        $display("========================================================================");
		$display("             all output signal should be zero after reset               ");
        $display("========================================================================");
        repeat(3)@(negedge clk);
		$finish;
	end
	#(5.0) inf.rst_n = 1'b1;
end
endtask

task input_task;
begin
    case (golden_action)
        Purchase: begin
            purchase_task;
        end
        Restock: begin
            restock_task;
        end
        Check_Valid_Date: begin
            check_valid_date_task;
        end
    endcase
end
endtask

task delay_task;
begin
    rand_delay.randomize();
    delay = rand_delay.cycle_delay;
    if (delay != 0) repeat(delay)@(negedge clk);
end
endtask

task rand_value_generator;
begin
    if (pat_id < 1400)
        golden_action = Purchase;
    else begin
        rand_action.randomize();
        golden_action = rand_action.act_id;
    end

    rand_date.randomize();
    golden_date = rand_date.date;

    rand_data_no.randomize();
    golden_data_no = rand_data_no.data_no;
end 
endtask
task purchase_task;
begin
    if (purchase_cnt < 2400) begin
        golden_strategy = (purchase_cnt % 8);
        golden_mode     = mode_table[(purchase_cnt / 8) % 3];
    end 
    else begin
        rand_strategy.randomize();
        golden_strategy = rand_strategy.strategy;
        rand_mode.randomize();
        golden_mode = rand_mode.mode;   
    end
    purchase_cnt = purchase_cnt + 1;
    // rand_strategy.randomize();
    // golden_strategy = rand_strategy.strategy; 

    // rand_mode.randomize();
    // golden_mode = rand_mode.mode;

    inf.sel_action_valid = 1'b1;
    inf.D.d_act[0] = golden_action;
    // delay_task;
    @(negedge clk);
    inf.sel_action_valid = 1'b0;

    delay_task;

    inf.strategy_valid = 1'b1;
    inf.D.d_strategy[0] = golden_strategy;
    // delay_task;
    @(negedge clk);
    inf.strategy_valid = 1'b0;

    delay_task;

    inf.mode_valid = 1'b1;
    inf.D.d_mode[0] = golden_mode;
    // delay_task;
    @(negedge clk);
    inf.mode_valid = 1'b0;

    delay_task;

    inf.date_valid = 1'b1;
    inf.D.d_date[0] = golden_date;
    // delay_task;
    @(negedge clk);
    inf.date_valid = 1'b0;

    delay_task;

    inf.data_no_valid = 1'b1;
    inf.D.d_data_no[0] = golden_data_no;
    // delay_task;
    @(negedge clk);
    inf.data_no_valid = 1'b0;
end
endtask 

task restock_task;
begin    
    rand_restock.randomize();
    golden_stock_rose = rand_restock.restock_num;    

    rand_restock.randomize();
    golden_stock_lily = rand_restock.restock_num;    

    rand_restock.randomize();
    golden_stock_carnation = rand_restock.restock_num;    

    rand_restock.randomize();
    golden_stock_baby_breath = rand_restock.restock_num;    

    inf.sel_action_valid = 1'b1;
    inf.D.d_act[0] = golden_action;
    // delay_task;
    @(negedge clk);
    inf.sel_action_valid = 1'b0;

    delay_task;

    inf.date_valid = 1'b1;
    inf.D.d_date[0] = golden_date;
    // delay_task;
    @(negedge clk);
    inf.date_valid = 1'b0;

    delay_task;

    inf.data_no_valid = 1'b1;
    inf.D.d_data_no[0] = golden_data_no;
    // delay_task;
    @(negedge clk);
    inf.data_no_valid = 1'b0;

    delay_task;

    inf.restock_valid = 1'b1;
    inf.D.d_stock[0] = golden_stock_rose;
    // delay_task;
    @(negedge clk);
    inf.restock_valid = 1'b0;

    delay_task;

    inf.restock_valid = 1'b1;
    inf.D.d_stock[0] = golden_stock_lily;
    // delay_task;
    @(negedge clk);
    inf.restock_valid = 1'b0;

    delay_task;

    inf.restock_valid = 1'b1;
    inf.D.d_stock[0] = golden_stock_carnation;
    // delay_task;
    @(negedge clk);
    inf.restock_valid = 1'b0;

    delay_task;

    inf.restock_valid = 1'b1;
    inf.D.d_stock[0] = golden_stock_baby_breath;
    // delay_task;
    @(negedge clk);
    inf.restock_valid = 1'b0;
end
endtask 

task check_valid_date_task;
begin
    inf.sel_action_valid = 1'b1;
    inf.D.d_act[0] = golden_action;
    // delay_task;
    @(negedge clk);
    inf.sel_action_valid = 1'b0;

    delay_task;

    inf.date_valid = 1'b1;
    inf.D.d_date[0] = golden_date;
    // delay_task;
    @(negedge clk);
    inf.date_valid = 1'b0;

    delay_task;

    inf.data_no_valid = 1'b1;
    inf.D.d_data_no[0] = golden_data_no;
    // delay_task;
    @(negedge clk);
    inf.data_no_valid = 1'b0;
end
endtask 

task cal_answer_task;
begin
    case (golden_action)
        Purchase: begin
            purchase_cal_task;
        end
        Restock: begin
            restock_cal_task;
        end
        Check_Valid_Date: begin
            check_valid_date_cal_task;
        end
    endcase
end
endtask

task purchase_cal_task;
begin
    case (golden_mode)
        Single: flower_count = 120;
        Group_Order: flower_count = 480;
        Event: flower_count = 960;
    endcase
    case (golden_strategy)
        'd0: Rose_count = flower_count;
        'd4,'d6: Rose_count = flower_count / 2;
        'd7: Rose_count = flower_count / 4;
        default: Rose_count = 0;
    endcase
    case (golden_strategy)
        'd1: Lily_count = flower_count;
        'd4: Lily_count = flower_count / 2;
        'd7: Lily_count = flower_count / 4;
        default: Lily_count = 0;
    endcase
    case (golden_strategy)
        'd2: Carnation_count = flower_count;
        'd5,'d6: Carnation_count = flower_count / 2;
        'd7: Carnation_count = flower_count / 4;
        default: Carnation_count = 0;
    endcase
    case (golden_strategy)
        'd3: Baby_Breath_count = flower_count;
        'd5: Baby_Breath_count = flower_count / 2;
        'd7: Baby_Breath_count = flower_count / 4;
        default: Baby_Breath_count = 0;
    endcase

    
    if (golden_date < {old_dram_data.M, old_dram_data.D})
        golden_warn_msg = Date_Warn;
    else if ((old_dram_data.Rose < Rose_count) || (old_dram_data.Lily < Lily_count) || (old_dram_data.Carnation < Carnation_count) || (old_dram_data.Baby_Breath < Baby_Breath_count))
        golden_warn_msg = Stock_Warn;
    else begin
        new_dram_data.Rose = old_dram_data.Rose - Rose_count;
        new_dram_data.Lily = old_dram_data.Lily - Lily_count;           
        new_dram_data.Carnation = old_dram_data.Carnation - Carnation_count;  
        new_dram_data.Baby_Breath = old_dram_data.Baby_Breath - Baby_Breath_count;
    end    
end
endtask 

task restock_cal_task;
begin
    new_dram_data.M = golden_date.M;
    new_dram_data.D = golden_date.D;

    if (golden_stock_rose + old_dram_data.Rose > 4095) begin
        new_dram_data.Rose = 4095;
        golden_warn_msg = Restock_Warn;
    end
    else
        new_dram_data.Rose = golden_stock_rose + old_dram_data.Rose;

     if (golden_stock_lily + old_dram_data.Lily > 4095) begin
        new_dram_data.Lily = 4095;
        golden_warn_msg = Restock_Warn;
    end
    else
        new_dram_data.Lily = golden_stock_lily + old_dram_data.Lily;

     if (golden_stock_carnation + old_dram_data.Carnation > 4095) begin
        new_dram_data.Carnation = 4095;
        golden_warn_msg = Restock_Warn;
    end
    else
        new_dram_data.Carnation = golden_stock_carnation + old_dram_data.Carnation;

     if (golden_stock_baby_breath + old_dram_data.Baby_Breath > 4095) begin
        new_dram_data.Baby_Breath = 4095;
        golden_warn_msg = Restock_Warn;
    end
    else
        new_dram_data.Baby_Breath = golden_stock_baby_breath + old_dram_data.Baby_Breath;

end
endtask 

task check_valid_date_cal_task;
begin
    if (golden_date < {old_dram_data.M, old_dram_data.D})
        golden_warn_msg = Date_Warn;
end
endtask 

task get_dram_data;
begin
    BASE_ADDR = 65536 + (golden_data_no * 8);
    old_dram_data.Rose[11:4] = golden_DRAM[BASE_ADDR + 7];
    old_dram_data.Rose[3:0] = golden_DRAM[BASE_ADDR + 6][7:4];
    old_dram_data.Lily[11:8] = golden_DRAM[BASE_ADDR + 6][3:0];
    old_dram_data.Lily[7:0] = golden_DRAM[BASE_ADDR + 5];
    old_dram_data.M = golden_DRAM[BASE_ADDR + 4][3:0];
    old_dram_data.Carnation[11:4] = golden_DRAM[BASE_ADDR + 3];
    old_dram_data.Carnation[3:0] = golden_DRAM[BASE_ADDR + 2][7:4];
    old_dram_data.Baby_Breath[11:8] = golden_DRAM[BASE_ADDR + 2][3:0];
    old_dram_data.Baby_Breath[7:0] = golden_DRAM[BASE_ADDR + 1];
    old_dram_data.D = golden_DRAM[BASE_ADDR][4:0];

    new_dram_data.Rose = old_dram_data.Rose;
    new_dram_data.Lily = old_dram_data.Lily;      
    new_dram_data.M = old_dram_data.M;      
    new_dram_data.Carnation = old_dram_data.Carnation;  
    new_dram_data.Baby_Breath = old_dram_data.Baby_Breath;
    new_dram_data.D = old_dram_data.D;         
end
endtask

task write_back_dram;
begin
    golden_DRAM[BASE_ADDR + 7] = new_dram_data.Rose[11:4];
    golden_DRAM[BASE_ADDR + 6][7:4] = new_dram_data.Rose[3:0];
    golden_DRAM[BASE_ADDR + 6][3:0] = new_dram_data.Lily[11:8];
    golden_DRAM[BASE_ADDR + 5] = new_dram_data.Lily[7:0];
    golden_DRAM[BASE_ADDR + 4] = {4'b0, new_dram_data.M};
    golden_DRAM[BASE_ADDR + 3] = new_dram_data.Carnation[11:4];
    golden_DRAM[BASE_ADDR + 2][7:4] = new_dram_data.Carnation[3:0];
    golden_DRAM[BASE_ADDR + 2][3:0] = new_dram_data.Baby_Breath[11:8];
    golden_DRAM[BASE_ADDR + 1] = new_dram_data.Baby_Breath[7:0];
    golden_DRAM[BASE_ADDR][4:0] = {3'b0, new_dram_data.D};
end
endtask

task wait_out_valid;
begin
    wait_val_time = -1;
    while (!inf.out_valid) begin
        wait_val_time = wait_val_time + 1;

        if (wait_val_time == 1000) begin
            $display("              latency over 1000 cycle                 ");
            repeat(3)@(negedge clk);
		    $finish;
        end
        @(negedge clk);
    end
    total_latency = total_latency + wait_val_time;
end
endtask

task check_ans;
begin
    if (golden_warn_msg != No_Warn)
        golden_complete = 1'b0;
    else
        golden_complete = 1'b1;
        
    out_val_time = 0;
    while (inf.out_valid) begin
        if ((inf.complete !== golden_complete) || (inf.warn_msg !== golden_warn_msg)) begin
            $display("\033[37m----------------------------------------------------------------------------------------------------------------------\033[0m"); 
            $display("\033[31m                                                  Wrong Answer                                                        \033[0m");
            $display("\033[31m                                              You fail no.%0d pattern                                                    \033[0m", pat_id);
            $display("\033[37m----------------------------------------------------------------------------------------------------------------------\033[0m");
            $finish;
        end
        if (out_val_time !== 0) begin
            $display("====================================================================");
            $display("         Out_valid should be high for exactly one cycle"             );
            $display("====================================================================");
            repeat(3)@(negedge clk);
            $finish;
        end
         out_val_time = out_val_time + 1;
         @(negedge clk);
    end
end
endtask

task display_pass;
begin
    $display("----------------------------------------------------------------------------------------------------------------------"); 
    $display("                                                  \033[0;32mCongratulations\033[m                                                     ");
    $display("                                           You have passed all patterns!                                               ");
    $display("                                           Your execution cycles = %7d cycles                                          ", total_latency);
    $display("----------------------------------------------------------------------------------------------------------------------");
    $finish;
end
endtask
endprogram


