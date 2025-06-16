//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright System Integration and Silicon Implementation Laboratory
//    All Right Reserved
//		Date		: 2025/4
//		Version		: v1.0
//   	File Name   : AFS.sv
//   	Module Name : AFS
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
module AFS(input clk, INF.AFS_inf inf);
import usertype::*;
//==============================================//
//              logic declaration               //
// ============================================ //
logic [16:0] adddr;
// logic [16:0] write_adddr;
Dram_data read_data;
Dram_data write_data;

logic [1:0]  restock_cnt;
logic        get_rose, get_lily, get_carnation, get_baby_breath;
logic        warn_date_flag, warn_stock_flag, warn_restock_flag;
logic        rose_exceed, lily_exceed, carnation_exceed, baby_breath_exceed;
Action   action;
Warn_Msg warn_msg_temp;
Warn_Msg warn_msg;
Stock flower_count;
Stock Rose_count;
Stock Lily_count;
Stock Carnation_count;
Stock Baby_Breath_count;

Data_Dir data_temp;

Strategy_Type strategy;
state_t c_state;
state_t n_state;
//==============================================//
//                     FSM                      //
// ============================================ //
always_ff @( posedge clk or negedge inf.rst_n ) begin
    if (!inf.rst_n)
        c_state <= IDLE;
    else
        c_state <= n_state;
end

always_comb begin
    case (c_state)
        IDLE: begin
            if (inf.sel_action_valid)
                n_state = INPUT;
            else
                n_state = IDLE;
        end         
        INPUT: begin
            if (inf.R_VALID) begin
                if (action == Restock)
                    n_state = wait_restock;
                else
                    n_state = check_date;
            end
            else
                n_state = INPUT;
        end
        check_date: begin
            if (action == Check_Valid_Date)
                n_state = OUT;
            else begin
                if (warn_date_flag)
                    n_state = OUT;
                else
                    n_state = check_stock;
            end
        end   
        check_stock: begin
            if (warn_stock_flag)
                n_state = OUT;
            else
                n_state = send_awaddr;
        end
        wait_restock: begin
            if (get_baby_breath)    
                n_state = send_awaddr;
            else
                n_state = wait_restock;
        end
        send_awaddr: begin
            if (inf.AW_READY)
                n_state = write_dram;
            else
                n_state = send_awaddr;
        end
        write_dram: begin
            if (inf.W_READY)
                n_state = wait_response;
            else
                n_state = write_dram;
        end
        wait_response: begin
            if (inf.B_VALID)
                n_state = OUT;
            else
                n_state = wait_response;
        end
        OUT: begin
            n_state = IDLE;
        end       
        default: n_state = IDLE;
    endcase 
end
//==============================================//
//                    Action                    //
// ============================================ //
// action
always_ff @( posedge clk ) begin
    if (inf.sel_action_valid)
        action <= inf.D.d_act;
    else
        action <= action;
end
//----------------------------------------------------
always_ff @( posedge clk or negedge inf.rst_n ) begin
    if (!inf.rst_n)
        restock_cnt <= 0;
    else if (inf.restock_valid)
        restock_cnt <= restock_cnt + 'd1;
    else
        restock_cnt <= restock_cnt;
end

always_ff @( posedge clk ) begin
    if (inf.strategy_valid)
        strategy <= inf.D.d_strategy[0];
    else
        strategy <= strategy;
end

always_ff @( posedge clk ) begin 
    if (inf.mode_valid) begin
        case (inf.D.d_mode[0])
            Single: begin
                case (strategy)
                    'd0: Rose_count <= 120;
                    'd4,'d6: Rose_count <= 60;
                    'd7: Rose_count <= 30;
                    default: Rose_count <= 0;
                endcase
            end
            Group_Order: begin
                case (strategy)
                    'd0: Rose_count <= 480;
                    'd4,'d6: Rose_count <= 240;
                    'd7: Rose_count <= 120;
                    default: Rose_count <= 0;
                endcase
            end
            Event: begin
                case (strategy)
                    'd0: Rose_count <= 960;
                    'd4,'d6: Rose_count <= 480;
                    'd7: Rose_count <= 240;
                    default: Rose_count <= 0;
                endcase
            end  
        endcase
    end
    else if (inf.restock_valid && (restock_cnt == 0))
        Rose_count <= inf.D.d_stock;
    else
        Rose_count <= Rose_count;
end

always_ff @( posedge clk ) begin 
    if (inf.mode_valid) begin
        case (inf.D.d_mode[0])
            Single: begin
                case (strategy)
                    'd1: Lily_count <= 120;
                    'd4: Lily_count <= 60;
                    'd7: Lily_count <= 30;
                    default: Lily_count <= 0;
                endcase
            end
            Group_Order: begin
                case (strategy)
                    'd1: Lily_count <= 480;
                    'd4: Lily_count <= 240;
                    'd7: Lily_count <= 120;
                    default: Lily_count <= 0;
                endcase
            end
            Event: begin
                case (strategy)
                    'd1: Lily_count <= 960;
                    'd4: Lily_count <= 480;
                    'd7: Lily_count <= 240;
                    default: Lily_count <= 0;
                endcase
            end  
        endcase
    end
    else if (inf.restock_valid && (restock_cnt == 1))
        Lily_count <= inf.D.d_stock;
    else
        Lily_count <= Lily_count;
end

always_ff @( posedge clk ) begin 
    if (inf.mode_valid) begin
        case (inf.D.d_mode[0])
            Single: begin
                case (strategy)
                    'd2: Carnation_count <= 120;
                    'd5,'d6: Carnation_count <= 60;
                    'd7: Carnation_count <= 30;
                    default: Carnation_count <= 0;
                endcase
            end
            Group_Order: begin
                case (strategy)
                    'd2: Carnation_count <= 480;
                    'd5,'d6: Carnation_count <= 240;
                    'd7: Carnation_count <= 120;
                    default: Carnation_count <= 0;
                endcase
            end
            Event: begin
                case (strategy)
                    'd2: Carnation_count <= 960;
                    'd5,'d6: Carnation_count <= 480;
                    'd7: Carnation_count <= 240;
                    default: Carnation_count <= 0;
                endcase
            end  
        endcase
    end
    else if (inf.restock_valid && (restock_cnt == 2))
        Carnation_count <= inf.D.d_stock;
    else
        Carnation_count <= Carnation_count;
end

always_ff @( posedge clk ) begin 
    if (inf.mode_valid) begin
        case (inf.D.d_mode[0])
            Single: begin
                case (strategy)
                    'd3: Baby_Breath_count <= 120;
                    'd5: Baby_Breath_count <= 60;
                    'd7: Baby_Breath_count <= 30;
                    default: Baby_Breath_count <= 0;
                endcase
            end
            Group_Order: begin
                case (strategy)
                    'd3: Baby_Breath_count <= 480;
                    'd5: Baby_Breath_count <= 240;
                    'd7: Baby_Breath_count <= 120;
                    default: Baby_Breath_count <= 0;
                endcase
            end
            Event: begin
                case (strategy)
                    'd3: Baby_Breath_count <= 960;
                    'd5: Baby_Breath_count <= 480;
                    'd7: Baby_Breath_count <= 240;
                    default: Baby_Breath_count <= 0;
                endcase
            end  
        endcase
    end
    else if (inf.restock_valid && (restock_cnt == 3))
        Baby_Breath_count <= inf.D.d_stock;
    else
        Baby_Breath_count <= Baby_Breath_count;
end
//----------------------------------------------
// date
always_ff @( posedge clk ) begin
    if (c_state == IDLE) begin
        data_temp.M <= 12;
        data_temp.D <= 31;
    end
    else if (inf.date_valid) begin
        data_temp.M <= inf.D.d_date[0][8:5];
        data_temp.D <= inf.D.d_date[0][4:0];
    end
    else begin
        data_temp.M <= data_temp.M;
        data_temp.D <= data_temp.D;
    end
end
// no.data
always_ff @( posedge clk ) begin 
    if (inf.data_no_valid)
        adddr <= 'h10000 + (inf.D.d_data_no[0] << 3);
    else
        adddr <= adddr;
end
// Rose stock
always_ff @( posedge clk ) begin 
    if (c_state == check_stock) begin
        if (warn_stock_flag)
            data_temp.Rose <= 0;
        else
            data_temp.Rose <= read_data.rose - Rose_count;
    end
    else if (c_state == wait_restock) begin
        if (get_rose) begin
            if (rose_exceed)
                data_temp.Rose <= 4095;
            else
                data_temp.Rose <= read_data.rose + Rose_count; 
        end
    end
    else    
        data_temp.Rose <= data_temp.Rose;
end
// Lily stock
always_ff @( posedge clk ) begin 
    if (c_state == check_stock) begin
        if (warn_stock_flag)
            data_temp.Lily <= 0;
        else
            data_temp.Lily <= read_data.lily - Lily_count;
    end
    else if (c_state == wait_restock) begin
        if (get_lily) begin
            if (lily_exceed)
                data_temp.Lily <= 4095;
            else
                data_temp.Lily <= read_data.lily + Lily_count; 
        end
    end
    else
        data_temp.Lily <= data_temp.Lily;
end
// Carnation_stock
always_ff @( posedge clk ) begin 
    if (c_state == check_stock) begin
        if (warn_stock_flag)
            data_temp.Carnation <= 0;
        else
            data_temp.Carnation <= read_data.carnation - Carnation_count;
    end
    else if (c_state == wait_restock) begin
        if (get_carnation) begin
            if (carnation_exceed)
                data_temp.Carnation <= 4095;
            else
                data_temp.Carnation <= read_data.carnation + Carnation_count; 
        end
    end
    else
        data_temp.Carnation <= data_temp.Carnation;
end
// Baby_Breath stock
always_ff @( posedge clk ) begin 
    if (c_state == check_stock) begin
        if (warn_stock_flag)
            data_temp.Baby_Breath <= 0;
        else
            data_temp.Baby_Breath <= read_data.baby_breath - Baby_Breath_count;
    end
    else if (c_state == wait_restock) begin
        if (get_baby_breath) begin
            if (baby_breath_exceed)
                data_temp.Baby_Breath <= 4095;
            else
                data_temp.Baby_Breath <= read_data.baby_breath + Baby_Breath_count; 
        end
    end
    else
        data_temp.Baby_Breath <= data_temp.Baby_Breath;
end
//==============================================//
//                     Warn                     //
// ============================================ //
always_comb begin 
    rose_exceed = ((Rose_count + read_data.rose) > 4095);
    lily_exceed = ((Lily_count + read_data.lily) > 4095);
    carnation_exceed = ((Carnation_count + read_data.carnation) > 4095);
    baby_breath_exceed = ((Baby_Breath_count + read_data.baby_breath) > 4095);
end
always_ff @( posedge clk ) begin
    if (c_state == IDLE)
        get_rose <= 0;
    else if (inf.restock_valid && (restock_cnt == 0))
        get_rose <= 1;
    else
        get_rose <= get_rose;
end

always_ff @( posedge clk ) begin
    if (c_state == IDLE)
        get_lily <= 0;
    else if (inf.restock_valid && (restock_cnt == 1))
        get_lily <= 1;
    else
        get_lily <= get_lily;
end

always_ff @( posedge clk ) begin
    if (c_state == IDLE)
        get_carnation <= 0;
    else if (inf.restock_valid && (restock_cnt == 2))
        get_carnation <= 1;
    else
        get_carnation <= get_carnation;
end

always_ff @( posedge clk ) begin
    if (c_state == IDLE)
        get_baby_breath <= 0;
    else if (inf.restock_valid && (restock_cnt == 3))
        get_baby_breath <= 1;
    else
        get_baby_breath <= get_baby_breath;
end

always_comb begin 
    if ((read_data.rose < Rose_count) || (read_data.lily < Lily_count) || (read_data.carnation < Carnation_count) || (read_data.baby_breath < Baby_Breath_count))
        warn_stock_flag = 1;
    else
        warn_stock_flag = 0;
end

always_comb begin 
    if ({data_temp.M, data_temp.D} < {read_data.month[3:0], read_data.day[4:0]})
        warn_date_flag = 1;
    else
        warn_date_flag = 0; 
end

always_comb begin 
    if (c_state == wait_restock) begin
        if (rose_exceed && get_rose)
            warn_restock_flag = 1; 
        else if (lily_exceed && get_lily)
            warn_restock_flag = 1;
        else if (carnation_exceed && get_carnation)
            warn_restock_flag = 1; 
        else if (baby_breath_exceed && get_baby_breath)
            warn_restock_flag = 1; 
        else
            warn_restock_flag = 0;
    end
    else
        warn_restock_flag = 0;
end 

always_ff @( posedge clk ) begin 
    if (c_state == IDLE)
        warn_msg_temp <= No_Warn;
    else if (c_state == check_date) begin
        if (warn_date_flag)
            warn_msg_temp <= Date_Warn;
    end
    else if (c_state == check_stock) begin
        if (warn_stock_flag)
            warn_msg_temp <= Stock_Warn;
    end
    else if (c_state == wait_restock) 
        if (warn_restock_flag)
            warn_msg_temp <= Restock_Warn;
    else
        warn_msg_temp <= warn_msg_temp;
end
//==============================================//
//                  axi4_read                   //
// ============================================ //
always_ff @( posedge clk or negedge inf.rst_n ) begin
    if (!inf.rst_n)
        inf.AR_VALID <= 0;
    else if (inf.AR_READY)
        inf.AR_VALID <= 0;
    else if (inf.data_no_valid)
        inf.AR_VALID <= 1; 
    else
        inf.AR_VALID <= inf.AR_VALID;
end

always_comb begin
    if (inf.AR_VALID)
        inf.AR_ADDR = adddr;
    else
        inf.AR_ADDR = 0;
end

always_ff @( posedge clk or negedge inf.rst_n ) begin
    if (!inf.rst_n)  
        inf.R_READY <= 0;
    else if (inf.R_VALID)
        inf.R_READY <= 0;
    else if (inf.AR_READY)
        inf.R_READY <= 1;
    else
        inf.R_READY <= inf.R_READY;
end

always_ff @( posedge clk ) begin
    if (inf.R_VALID)
        read_data <= inf.R_DATA;
end
//==============================================//
//                 axi4_write                   //
// ============================================ //
always_comb begin
    if (c_state == send_awaddr) begin
        inf.AW_VALID = 1;
        inf.AW_ADDR  = adddr;
    end
    else begin 
        inf.AW_ADDR  = 0;
        inf.AW_VALID = 0;
    end
end

always_comb begin
    if (c_state == write_dram) begin
        inf.W_VALID = 1;
    end
    else begin
        inf.W_VALID = 0;
    end
end

always_comb begin
    if (c_state == write_dram) begin
        if (action == Restock)
            inf.W_DATA  = {data_temp.Rose, data_temp.Lily, 4'b0, data_temp.M, data_temp.Carnation, data_temp.Baby_Breath, 3'b0, data_temp.D};
        else
            inf.W_DATA  = {data_temp.Rose, data_temp.Lily, read_data.month, data_temp.Carnation, data_temp.Baby_Breath, read_data.day};
    end
    else begin
        inf.W_DATA  = 0;
    end
end

always_comb begin 
    if ((c_state == wait_response))
        inf.B_READY = 1;
    else
        inf.B_READY = 0;

end

// always_ff @( posedge clk or negedge inf.rst_n ) begin : blockName
//     if (!inf.rst_n)
//         inf.B_READY <= 0;
//     else if (inf.B_VALID)
//         inf.B_READY <= 0;
//     else if (inf.AW_READY)
//         inf.B_READY <= 1;
//     else
//         inf.B_READY <= inf.B_READY;
// end
//==============================================//
//                    OUTPUT                    //
// ============================================ //
always_comb begin 
    if (c_state == OUT)
        inf.out_valid = 1;
    else
        inf.out_valid = 0;
end

always_comb begin 
    if (c_state == OUT)
        inf.warn_msg = warn_msg_temp;
    else   
        inf.warn_msg = No_Warn;
end

always_comb begin 
    if (c_state == OUT) begin
        if (warn_msg_temp == No_Warn)
            inf.complete = 1;
        else
            inf.complete = 0; 
    end
    else
        inf.complete = 0;
end
endmodule



