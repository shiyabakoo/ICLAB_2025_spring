/*
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
NYCU Institute of Electronic
2025 Spring IC Design Laboratory 
Lab10: SystemVerilog Coverage & Assertion
File Name   : CHECKER.sv
Module Name : CHECKER
Release version : v1.0 (Release Date: May-2025)
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*/

`include "Usertype.sv"
module Checker(input clk, INF.CHECKER inf);
import usertype::*;

// integer fp_w;

// initial begin
// fp_w = $fopen("out_valid.txt", "w");
// end

/**
 * This section contains the definition of the class and the instantiation of the object.
 *  * 
 * The always_ff blocks update the object based on the values of valid signals.
 * When valid signal is true, the corresponding property is updated with the value of inf.D
 */

// class Strategy_and_mode;
//     Strategy_Type f_type;
//     Mode f_mode;
// endclass

// Strategy_and_mode fm_info = new();
typedef struct packed {
    Strategy_Type f_type;
    Mode f_mode;
} Strategy_and_mode;

Strategy_and_mode fm_info;

logic mode_valid_ff;

always_ff @( posedge clk ) begin 
    if (inf.strategy_valid)
        fm_info.f_type <= inf.D.d_strategy[0];
end

always_ff @( posedge clk ) begin 
    if (inf.mode_valid) begin
        fm_info.f_mode <= inf.D.d_mode[0];
    end
end

always_ff @( posedge clk ) begin 
    mode_valid_ff <= inf.mode_valid;
end
//===========================
// coverage
//===========================
// 1. Each case of Strategy_Type should be select at least 100 times.
covergroup cg_spec1 @(posedge clk iff (inf.strategy_valid));
    option.per_instance = 1;
    cov_strategy: coverpoint inf.D.d_strategy[0]{
        option.at_least = 100;
        bins bstrategy [] = {[Strategy_A:Strategy_H]}; 
    }
endgroup
// 2. Each case of Mode should be select at least 100 times.
covergroup cg_spec2 @(posedge clk iff(inf.mode_valid));
    option.per_instance = 1;
    cov_mode: coverpoint inf.D.d_mode[0]{
        option.at_least = 100;
        bins bmode1 = {Single}; 
        bins bmode2 = {Group_Order}; 
        bins bmode3 = {Event}; 
    }
endgroup
// 3. Create a cross bin for the SPEC1 and SPEC2. Each combination should be selected at least 100 times.
covergroup cg_spec3 @(negedge clk iff (mode_valid_ff));
    option.per_instance = 1;
    // coverpoint fm_info.f_type;
    // coverpoint fm_info.f_mode;
    cov_cross: cross fm_info.f_type, fm_info.f_mode{
        option.at_least = 100;
    }
endgroup
// 4. Output signal inf.err_msg should be“No_Warn”,“Date_Warn”,“Stock_Warn“,”Restock_Warn”, each at least 10 times.
covergroup cg_spec4 @(negedge clk iff (inf.out_valid));
    option.per_instance = 1;
    cov_warn_msg: coverpoint inf.warn_msg{
        option.at_least = 10;
        bins bout [] = {[No_Warn:Restock_Warn]}; 
    }
endgroup
//5. Create the transitions bin for the inf.D.act[0] signal from [Purchase:Check_Valid_Date] to [Purchase:Check_Valid_Date]. Each transition should be hit at least 300 times
covergroup cg_spec5 @(posedge clk iff (inf.sel_action_valid));
    option.per_instance = 1;
    cov_action_trans: coverpoint inf.D.d_act[0]{
        option.at_least = 300;
        bins btrans [] = ([Purchase:Check_Valid_Date] => [Purchase:Check_Valid_Date]); 
    }
endgroup
// 6. Create a covergroup for material of supply action with auto_bin_max = 32, and each bin have to hit at least one time.
covergroup cg_spec6 @(posedge clk iff (inf.restock_valid));
    option.per_instance = 1;
    cov_flower: coverpoint inf.D.d_stock[0]{
        option.auto_bin_max = 32;
    }
endgroup

cg_spec1 cg_spec1_inst = new();
cg_spec2 cg_spec2_inst = new();
cg_spec3 cg_spec3_inst = new();
cg_spec4 cg_spec4_inst = new(); 
cg_spec5 cg_spec5_inst = new();
cg_spec6 cg_spec6_inst = new();

//===========================
// Assertion
//===========================
// 1.  All outputs signals (including AFS.sv) should be zero after reset
always @(negedge inf.rst_n) begin
    #(4.0);
    assert_spec_1: assert ((inf.out_valid == 0) && (inf.warn_msg == No_Warn) && (inf.complete == 0) && 
                          (inf.AR_VALID == 0) && (inf.AR_ADDR == 0) && (inf.R_READY == 0) && (inf.AW_VALID == 0) &&
                          (inf.AW_ADDR == 0) && (inf.W_VALID == 0) && (inf.W_DATA == 0) && (inf.B_READY == 0)) 
    else begin
        $display("--------------------------------------------------");
        $display("\033[31m            Assertion 1 is violated               \033[0m");
        $display("--------------------------------------------------");
        $fatal;
    end
end
// 2. Latency should be less than 1000 cycles for each operation
Action action;
logic[1:0] restock_cnt;
always_ff @( posedge clk ) begin
    if (inf.sel_action_valid)
        action <= inf.D.d_act;
    else
        action <= action;
end

always_ff @( posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n)
        restock_cnt <= 0;
    else if (inf.restock_valid)
        restock_cnt <= restock_cnt + 1;
    else
        restock_cnt <= restock_cnt;
end

property check_latency_Purchase;
    @(posedge clk) ((inf.data_no_valid) && (action == Purchase)) |-> ##[1:999] (inf.out_valid);
endproperty

property check_latency_Check_Valid_Date;
    @(posedge clk) ((inf.data_no_valid) && (action == Check_Valid_Date)) |-> ##[1:999] (inf.out_valid);
endproperty

property check_latency_Restock;
    @(posedge clk) (inf.restock_valid && (restock_cnt == 3)) |-> ##[1:999] (inf.out_valid);
endproperty

assert_spec_2_1: assert property (check_latency_Purchase) 
                    else begin 
                        $display("--------------------------------------------------");
                        $display("\033[31m            Assertion 2 is violated               \033[0m");
                        $display("--------------------------------------------------");
                        $fatal;
                    end
assert_spec_2_2: assert property (check_latency_Check_Valid_Date) 
                    else begin 
                        $display("--------------------------------------------------");
                        $display("\033[31m            Assertion 2 is violated               \033[0m");
                        $display("--------------------------------------------------");
                        $fatal;
                    end
assert_spec_2_3: assert property (check_latency_Restock) 
                    else begin 
                        $display("--------------------------------------------------");
                        $display("\033[31m            Assertion 2 is violated               \033[0m");
                        $display("--------------------------------------------------");
                        $fatal; 
                    end


// 3. If action is completed (complete=1), warn_msg should be 2’b0 (No_Warn).
property check_warn_msg;
    @(negedge clk) inf.complete |-> (inf.warn_msg == No_Warn);
endproperty

assert_spec_3: assert property (check_warn_msg)
                else begin
                    $display("--------------------------------------------------");
                    $display("\033[31m            Assertion 3 is violated               \033[0m");
                    $display("--------------------------------------------------");
                    $fatal;
                end
// 4. Next input valid will be valid 1-4 cycles after previous input valid fall.
// purchase valid check
property Purcahse_action_to_strategy;
    @(posedge clk) ((inf.D.d_act[0] == Purchase) && inf.sel_action_valid) |-> ##[1:4] inf.strategy_valid;
endproperty

property strategy_to_mode;
    @(posedge clk) inf.strategy_valid |-> ##[1:4] inf.mode_valid;
endproperty

property mode_to_date;
    @(posedge clk) inf.mode_valid |-> ##[1:4] inf.date_valid;
endproperty

property date_to_data_no;
    @(posedge clk) inf.date_valid |-> ##[1:4] inf.data_no_valid;
endproperty

// property Purchase_valid_check; 
//     @(posedge clk) ((inf.D.d_act[0] == Purchase) && inf.sel_action_valid) |-> ##[1:4] inf.strategy_valid ##[1:4] inf.mode_valid ##[1:4] inf.date_valid ##[1:4] inf.data_no_valid;
// endproperty

// assert_spec_4: assert property (Purchase_valid_check)
//     else begin
//         $display("--------------------------------------------------");
//         $display("\033[31m            Assertion 4 is violated               \033[0m");
//         $display("--------------------------------------------------");
//         $fatal;
//     end
assert_spec_4_1: assert property(Purcahse_action_to_strategy) 
    else begin
        $display("--------------------------------------------------");
        $display("\033[31m            Assertion 4 is violated               \033[0m");
        $display("--------------------------------------------------");
        $fatal;
    end
assert_spec_4_2: assert property(strategy_to_mode) 
    else begin
        $display("--------------------------------------------------");
        $display("\033[31m            Assertion 4 is violated               \033[0m");
        $display("--------------------------------------------------");
        $fatal;
    end
assert_spec_4_3: assert property(mode_to_date) 
    else begin
        $display("--------------------------------------------------");
        $display("\033[31m            Assertion 4 is violated               \033[0m");
        $display("--------------------------------------------------");
        $fatal;
    end
assert_spec_4_4: assert property(date_to_data_no) 
    else begin
        $display("--------------------------------------------------");
        $display("\033[31m            Assertion 4 is violated               \033[0m");
        $display("--------------------------------------------------");
        $fatal;
    end


// Restock valid check
property Restock_action_to_date;
    @(posedge clk) ((inf.D.d_act[0] == Restock) && inf.sel_action_valid) |-> ##[1:4] inf.date_valid;
endproperty

property restock_check_1;
    @(posedge clk) ((restock_cnt == 0) && inf.restock_valid) |-> ##[1:4] inf.restock_valid;
endproperty

property restock_check_2;
    @(posedge clk) ((restock_cnt == 1) && inf.restock_valid) |-> ##[1:4] inf.restock_valid;
endproperty

property restock_check_3;
    @(posedge clk) ((restock_cnt == 2) && inf.restock_valid) |-> ##[1:4] inf.restock_valid;
endproperty

assert_spec_4_5: assert property(Restock_action_to_date) 
    else begin
        $display("--------------------------------------------------");
        $display("\033[31m            Assertion 4 is violated               \033[0m");
        $display("--------------------------------------------------");
        $fatal;
    end
assert_spec_4_6: assert property(restock_check_1) 
    else begin
        $display("--------------------------------------------------");
        $display("\033[31m            Assertion 4 is violated               \033[0m");
        $display("--------------------------------------------------");
        $fatal;
    end
assert_spec_4_7: assert property(restock_check_1) 
    else begin
        $display("--------------------------------------------------");
        $display("\033[31m            Assertion 4 is violated               \033[0m");
        $display("--------------------------------------------------");
        $fatal;
    end
assert_spec_4_8: assert property(restock_check_1) 
    else begin
        $display("--------------------------------------------------");
        $display("\033[31m            Assertion 4 is violated               \033[0m");
        $display("--------------------------------------------------");
        $fatal;
    end

// check valid date
property Check_Valid_Date_action_to_strategy;
    @(posedge clk) ((inf.D.d_act[0] == Check_Valid_Date) && inf.sel_action_valid) |-> ##[1:4] inf.date_valid;
endproperty
assert_spec_4_9: assert property(Check_Valid_Date_action_to_strategy) 
    else begin
        $display("--------------------------------------------------");
        $display("\033[31m            Assertion 4 is violated               \033[0m");
        $display("--------------------------------------------------");
        $fatal;
    end

// 5. All input valid signals won’t overlap with each other.
always_ff @( posedge clk ) begin
    spec_5: assert ($onehot0({inf.sel_action_valid, inf.strategy_valid, inf.mode_valid, inf.date_valid, inf.data_no_valid, inf.restock_valid}))
        else begin
            $display("--------------------------------------------------");
            $display("\033[31m            Assertion 5 is violated               \033[0m");
            $display("--------------------------------------------------");
            $fatal;
        end
end
// 6. Out_valid can only be high for exactly one cycle
property check_out_valid; 
    @(posedge clk) inf.out_valid |=> !inf.out_valid;
endproperty

assert_spec_6: assert property (check_out_valid)
    else begin
        $display("--------------------------------------------------");
        $display("\033[31m            Assertion 6 is violated               \033[0m");
        $display("--------------------------------------------------");
        $fatal;
    end
// 7. Next operation will be valid 1-4 cycles after out_valid fall.
property check_out_valid_to_in_valid; 
    @(posedge clk) inf.out_valid |-> ##[1:4] inf.sel_action_valid;
endproperty

assert_spec_7: assert property (check_out_valid_to_in_valid)
    else begin
        $display("--------------------------------------------------");
        $display("\033[31m            Assertion 7 is violated               \033[0m");
        $display("--------------------------------------------------");
        $fatal;
    end
// 8. The input date from pattern should adhere to the real calendar. (ex: 2/29, 3/0, 4/31, 13/1 are illegal cases)
property date_check;
    @(posedge clk) inf.date_valid |-> ( ((inf.D.d_date[0].M <= 12)) && (inf.D.d_date[0].M >= 1) && 
                                        (((inf.D.d_date[0].M inside{4, 6, 9, 11}) && (inf.D.d_date[0].D inside{[1:30]}))|| 
                                        ((inf.D.d_date[0].M == 2) && (inf.D.d_date[0].D inside{[1:28]}))|| 
                                        (!(inf.D.d_date[0].M inside{2, 4, 6, 9, 11}) && (inf.D.d_date[0].D inside{[1:31]})))
                                       );
endproperty
assert_spec_8: assert property (date_check)
    else begin
        $display("--------------------------------------------------");
        $display("\033[31m            Assertion 8 is violated               \033[0m");
        $display("--------------------------------------------------");
        $fatal; 
    end
//9. The AR_VALID signal should not overlap with the AW_VALID signal
property check_axi;
    @(negedge clk) inf.AR_VALID |-> !inf.AW_VALID;
endproperty

assert_spec_9: assert property (check_axi)
    else begin
        $display("--------------------------------------------------");
        $display("\033[31m            Assertion 9 is violated               \033[0m");
        $display("--------------------------------------------------");
        $fatal; 
    end
endmodule  



