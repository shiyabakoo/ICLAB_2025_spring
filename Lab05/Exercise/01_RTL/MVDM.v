module MVDM(
    // input signals
    clk,
    rst_n,
    in_valid, 
    in_valid2,
    in_data,
    // output signals
    out_valid,
    out_sad
    );

input clk;
input rst_n;
input in_valid;
input in_valid2;
input [11:0] in_data;

output reg out_valid;
output reg out_sad;

//=======================================================
//                   Reg/Wire
//=======================================================
integer i, j;
wire             DO0_L0, DO1_L0, DO2_L0, DO3_L0, DO4_L0, DO5_L0, DO6_L0, DO7_L0;
wire             DO0_L1, DO1_L1, DO2_L1, DO3_L1, DO4_L1, DO5_L1, DO6_L1, DO7_L1;
reg              DI0_L0, DI1_L0, DI2_L0, DI3_L0, DI4_L0, DI5_L0, DI6_L0, DI7_L0;
reg              DI0_L1, DI1_L1, DI2_L1, DI3_L1, DI4_L1, DI5_L1, DI6_L1, DI7_L1;
reg              A0_L0, A1_L0, A2_L0, A3_L0, A4_L0, A5_L0, A6_L0, A7_L0, A8_L0, A9_L0, A10_L0, A11_L0, A12_L0, A13_L0;
reg              A0_L1, A1_L1, A2_L1, A3_L1, A4_L1, A5_L1, A6_L1, A7_L1, A8_L1, A9_L1, A10_L1, A11_L1, A12_L1, A13_L1;
reg        [7:0] DO_L0, DO_L1;
reg        [7:0] DI_L0, DI_L1;
reg        [13:0] A_L0, A_L1;
reg        [1:0] chip_enable;
reg              WEB_L0, WEB_L1;

// fsm
reg [2:0] c_state, n_state;
localparam IDLE = 3'd0,
           INPUT_1 = 3'd1,
           INPUT_2 = 3'd2,
           CAL_1   = 3'd3,
           COMPARE_1 = 3'd4,
           WAIT      = 3'd5,
           OUT       = 3'd6;
reg [5:0]  counter;
reg [11:0] M_vector [0:7];
reg [11:0] in_data_ff;
reg [11:4] int_l0_x_p1;
reg [11:4] int_l0_y_p1;
reg [11:4] int_l1_x_p1;
reg [11:4] int_l1_y_p1;
reg [3:0]  fraction_l0_x;
reg [3:0]  fraction_l0_y;
reg [3:0]  fraction_l1_x;
reg [3:0]  fraction_l1_y;
// CAL
reg [15:0] bl_matrix_l0 [0:9][0:9];
reg [15:0] bl_matrix_l1 [0:9][0:9];
reg [7:0]  l0_shift  [0:10];
reg [7:0]  l1_shift  [0:10];
reg [15:0] bl_second_l1;
reg [15:0] bl_second_l0;
reg [11:0] bl_first_l0;
reg [11:0] bl_first_ff_l0;
reg [11:0] bl_first_l1;
reg [11:0] bl_first_ff_l1;
reg [3:0]  bl_cnt;
reg [3:0]  shift_cnt;
reg [3:0]  bl_row_cnt;
reg [3:0]  bl_col_cnt;
reg        bl_second_cnt_en;
reg        shift_en;
reg        bl_en;
//SAD
reg [23:0] SAD_0_value;
reg [23:0] SAD_1_value;
reg [23:0] SAD_2_value;
reg [23:0] SAD_3_value;
reg [23:0] SAD_4_value;
reg [23:0] SAD_5_value;
reg [23:0] SAD_6_value;
reg [23:0] SAD_7_value;
reg [23:0] SAD_8_value;
reg [27:0] SAD_0, SAD_1, SAD_2, SAD_3, SAD_4, SAD_5, SAD_6, SAD_7, SAD_8;
// COMPARE
reg [27:0] smallest_SAD_temp;
reg [27:0] smallest_SAD_1;
reg [27:0] smallest_SAD_2;
reg [55:0] smallest_SAD;
reg        point2_start;
// test
reg [7:0] a,b;
reg [3:0] c;
reg [11:0] d;

assign a = 255;
assign b = 0;
assign c = 15;
assign d = (b<<4) + c * (a - b);
//======================================================= 
//                   MEM
//=======================================================
SRAM_L0 L0( .DI0(DI0_L0), .DI1(DI1_L0), .DI2(DI2_L0), .DI3(DI3_L0), .DI4(DI4_L0), .DI5(DI5_L0), .DI6(DI6_L0), .DI7(DI7_L0),
            .DO0(DO0_L0), .DO1(DO1_L0), .DO2(DO2_L0), .DO3(DO3_L0), .DO4(DO4_L0), .DO5(DO5_L0), .DO6(DO6_L0), .DO7(DO7_L0),
            .A0(A0_L0), .A1(A1_L0), .A2(A2_L0), .A3(A3_L0), .A4(A4_L0), .A5(A5_L0), .A6(A6_L0), .A7(A7_L0), .A8(A8_L0), .A9(A9_L0), .A10(A10_L0), .A11(A11_L0), .A12(A12_L0), .A13(A13_L0),
            .OE(1'b1), .CS(1'b1), .WEB(WEB_L0), .CK(clk)
            );
SRAM_L1 L1( .DI0(DI0_L1), .DI1(DI1_L1), .DI2(DI2_L1), .DI3(DI3_L1), .DI4(DI4_L1), .DI5(DI5_L1), .DI6(DI6_L1), .DI7(DI7_L1),
            .DO0(DO0_L1), .DO1(DO1_L1), .DO2(DO2_L1), .DO3(DO3_L1), .DO4(DO4_L1), .DO5(DO5_L1), .DO6(DO6_L1), .DO7(DO7_L1),
            .A0(A0_L1), .A1(A1_L1), .A2(A2_L1), .A3(A3_L1), .A4(A4_L1), .A5(A5_L1), .A6(A6_L1), .A7(A7_L1), .A8(A8_L1), .A9(A9_L1), .A10(A10_L1), .A11(A11_L1), .A12(A12_L1), .A13(A13_L1),
            .OE(1'b1), .CS(1'b1), .WEB(WEB_L1), .CK(clk)
            );
assign {DI0_L0, DI1_L0, DI2_L0, DI3_L0, DI4_L0, DI5_L0, DI6_L0, DI7_L0} = DI_L0;
assign DO_L0 = {DO0_L0, DO1_L0, DO2_L0, DO3_L0, DO4_L0, DO5_L0, DO6_L0, DO7_L0};
assign {DI0_L1, DI1_L1, DI2_L1, DI3_L1, DI4_L1, DI5_L1, DI6_L1, DI7_L1} = DI_L1;
assign DO_L1 = {DO0_L1, DO1_L1, DO2_L1, DO3_L1, DO4_L1, DO5_L1, DO6_L1, DO7_L1};
assign {A0_L0, A1_L0, A2_L0, A3_L0, A4_L0, A5_L0, A6_L0, A7_L0, A8_L0, A9_L0, A10_L0, A11_L0, A12_L0, A13_L0} = A_L0;
assign {A0_L1, A1_L1, A2_L1, A3_L1, A4_L1, A5_L1, A6_L1, A7_L1, A8_L1, A9_L1, A10_L1, A11_L1, A12_L1, A13_L1} = A_L1;
//=======================================================
//                         FSM
//=======================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        c_state <= IDLE;
    else
        c_state <= n_state;
end

always @(*) begin
    case (c_state)
        IDLE : begin
            if (in_valid)
                n_state = INPUT_1;
            else if (in_valid2)
                n_state = INPUT_2;
            else
                n_state = IDLE; 
        end  
        INPUT_1 : begin
            if (!in_valid)
                n_state = IDLE;
            else
                n_state = INPUT_1; 
        end
        INPUT_2 : begin
            if (!in_valid2)
                n_state = CAL_1;
            else
                n_state = INPUT_2; 
        end
        CAL_1 : begin
            if (bl_col_cnt == 9 && bl_row_cnt == 9)
                n_state = COMPARE_1;
            else
                n_state = CAL_1;
        end
        // COMPARE_1 : begin
        //     if (counter == 3) begin
        //         if (point2_start)
        //             n_state = OUT;
        //         else 
        //             n_state = WAIT;
        //     end
        //     else
        //         n_state = COMPARE_1;
        // end
        COMPARE_1 : begin
            if (counter == 3) begin
                n_state = WAIT;
            end
            else
                n_state = COMPARE_1;
        end
        WAIT : begin
            if (point2_start)
                n_state = OUT;
            else
                n_state = CAL_1;
        end
        OUT : begin
            if (counter == 55)
                n_state = IDLE;
            else
                n_state = OUT;
        end
        default: n_state = IDLE;
    endcase
end


//=======================================================
//                   INPUT_1
//=======================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        in_data_ff <= 0;
    else if (in_valid || in_valid2)
        in_data_ff <= in_data;
    else
        in_data_ff <= 0;
end
// always @(posedge clk or negedge rst_n) begin
//     if (!rst_n)
//         WEB_L0 <= 1;
//     else if (in_valid)
//         WEB_L0 <= 0;
//     else
//         WEB_L0 <= 1;

// end
always @(*) begin
    if (c_state == INPUT_1)
        WEB_L0 = !WEB_L1;
    else
        WEB_L0 = 1;
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        WEB_L1 <= 1;
    else if (!in_valid)
        WEB_L1 <= 1;
    else if (c_state == INPUT_1) begin
        if (A_L0 == 16383)
            WEB_L1 <= 0;
        else
            WEB_L1 <= WEB_L1;
    end
    else
        WEB_L1 <= WEB_L1;

end

always @(*) begin
    DI_L0 = in_data_ff[11:4];
    DI_L1 = in_data_ff[11:4];
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        A_L0 <= 0;
    else if (c_state == IDLE)
        A_L0 <= 0;
    else if (c_state == INPUT_1) begin
        if (A_L0 == 16383)
            A_L0 <= 0;
        else
            A_L0 <= A_L0 + 1;
    end
    else if (c_state == INPUT_2)
        A_L0 <= int_l0_x_p1 + (int_l0_y_p1 <<< 7);
    else if (c_state == COMPARE_1) 
        A_L0 <= M_vector[4][11:4] + (M_vector[5][11:4] << 7); 
    else if (c_state == CAL_1) begin
        if (bl_cnt == 10)
            A_L0 <= A_L0 - 1279;
        else
            A_L0 <= A_L0 + 128;
    end
    else
        A_L0 <= A_L0;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        A_L1 <= 0;
    else if (c_state == IDLE)
        A_L1 <= 0;
    else if (c_state == INPUT_1) begin
        if (A_L1 == 16383)
            A_L1 <= 0;
        else
            A_L1 <= A_L1 + 1;
    end
    else if (c_state == INPUT_2) 
        A_L1 <= (int_l1_x_p1) + (int_l1_y_p1 << 7);
    else if (c_state == COMPARE_1)
        A_L1 <= M_vector[6][11:4] + (M_vector[7][11:4] << 7); 
    else if (c_state == CAL_1) begin
        if (bl_cnt == 10)
            A_L1 <= A_L1 - 1279;
        else
            A_L1 <= A_L1 + 128;
    end
    else
        A_L1 <= A_L1;
end

//=======================================================
//                   INPUT_2
//=======================================================
assign int_l0_x_p1 = M_vector[0][11:4];
assign int_l0_y_p1 = M_vector[1][11:4];
assign int_l1_x_p1 = M_vector[2][11:4];
assign int_l1_y_p1 = M_vector[3][11:4];

assign fraction_l0_x = (point2_start)? M_vector[4][3:0] : M_vector[0][3:0];
assign fraction_l0_y = (point2_start)? M_vector[5][3:0] : M_vector[1][3:0];
assign fraction_l1_x = (point2_start)? M_vector[6][3:0] : M_vector[2][3:0];
assign fraction_l1_y = (point2_start)? M_vector[7][3:0] : M_vector[3][3:0];


always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < 8; i = i + 1) begin
            M_vector[i] <= 'd0;
        end
    end
    else if (c_state == INPUT_2) begin
        M_vector[counter] <= in_data_ff;
    end
    else begin
        for (i = 0; i < 8; i = i + 1) begin
            M_vector[i] <= M_vector[i];
        end
    end
end


always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        counter <= 0;
    else if (c_state == IDLE)
        counter <= 0;
    else if (c_state == INPUT_2)
        counter <= counter + 1;
    else if (c_state == COMPARE_1) begin
        if (counter == 3)
            counter <= 0;
        else
            counter <= counter + 1;
    end
    else if (c_state == OUT) begin
        if (counter == 55)
            counter <= 0;
        else
            counter <= counter + 1; 
    end
    else
        counter <= 0;
end

//=======================================================
//                   CAL
//=======================================================  
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        bl_cnt <= 0;
    else if (c_state == CAL_1) begin
        if (bl_cnt == 10)
            bl_cnt <= 0;
        else
            bl_cnt <= bl_cnt + 1; 
    end
    else
        bl_cnt <= 0;
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        shift_cnt <= 0;
    else if (shift_en) begin
        if (shift_cnt == 10)
            shift_cnt <= 0;
        else
            shift_cnt <= shift_cnt + 1; 
    end
    else
        shift_cnt <= 0;
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        bl_row_cnt <= 0;
    else if (bl_second_cnt_en) begin
        if (bl_row_cnt == 10)
            bl_row_cnt <= 0;
        else
            bl_row_cnt <= bl_row_cnt + 1; 
    end
    else
        bl_row_cnt <= 0;
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        bl_col_cnt <= 0;
    else if (bl_row_cnt == 10) begin
        if (bl_col_cnt == 9)
            bl_col_cnt <= 0;
        else
            bl_col_cnt <= bl_col_cnt + 1;
    end
    else
        bl_col_cnt <= bl_col_cnt;
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        shift_en <= 0;
    else if (c_state == CAL_1)
        shift_en <= 1;
    else
        shift_en <= 0;
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        bl_en <= 0;
    else if (c_state !== CAL_1)
        bl_en <= 0;
    else if (shift_cnt == 10)
        bl_en <= 1;
    else
        bl_en <= bl_en;
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        bl_second_cnt_en <= 0;
    else if (c_state !== CAL_1)
        bl_second_cnt_en <= 0;
    else if (shift_cnt == 2 && bl_en)
        bl_second_cnt_en <= 1;
    else
        bl_second_cnt_en <= bl_second_cnt_en;
end
// L0
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        l0_shift[10] <= 0;
    else if (shift_en)
        l0_shift[10] <= DO_L0;
    else
        l0_shift[10] <= l0_shift[10];
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < 10; i = i + 1) begin
            l0_shift[i] <= 0;
        end
    end
    else if (shift_en) begin
        for (i = 0; i < 10; i = i + 1) begin
            l0_shift[i] <= l0_shift[i + 1];
        end
    end
    else begin
        for (i = 0; i < 10; i = i + 1) begin
            l0_shift[i] <= l0_shift[i];
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        bl_first_l0 <= 0;
    else if (bl_en)
        bl_first_l0 <= (l0_shift[0] << 4) + fraction_l0_x * (DO_L0 - l0_shift[0]);
    else
        bl_first_l0 <= bl_first_l0;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        bl_first_ff_l0 <= 0;
    else
        bl_first_ff_l0 <= bl_first_l0;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        bl_second_l0 <= 0;
    else if (bl_en)
        bl_second_l0 <= (bl_first_ff_l0 << 4) + fraction_l0_y * (bl_first_l0 - bl_first_ff_l0);
    else
        bl_second_l0 <= bl_second_l0;
end



// L1
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        l1_shift[10] <= 0;
    else if (shift_en)
        l1_shift[10] <= DO_L1;
    else
        l1_shift[10] <= l1_shift[10];
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < 10; i = i + 1) begin
            l1_shift[i] <= 0;
        end
    end
    else if (shift_en) begin
        for (i = 0; i < 10; i = i + 1) begin
            l1_shift[i] <= l1_shift[i + 1];
        end
    end
    else begin
        for (i = 0; i < 10; i = i + 1) begin
            l1_shift[i] <= l1_shift[i];
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        bl_first_l1 <= 0;
    else if (bl_en)
        bl_first_l1 <= (l1_shift[0] << 4) + fraction_l1_x * (DO_L1 - l1_shift[0]);
    else
        bl_first_l1 <= bl_first_l1;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        bl_first_ff_l1 <= 0;
    else
        bl_first_ff_l1 <= bl_first_l1;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        bl_second_l1 <= 0;
    else if (bl_en)
        bl_second_l1 <= (bl_first_ff_l1 << 4) + fraction_l1_y * (bl_first_l1 - bl_first_ff_l1);
    else
        bl_second_l1 <= bl_second_l1;
end

// save bilinear_value
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < 10; i = i + 1) begin
            for (j = 0; j < 10; j = j + 1) begin
                bl_matrix_l0[i][j] <= 'd0;
            end
        end
    end
    else if (c_state == CAL_1 && bl_row_cnt !== 10)
        bl_matrix_l0[bl_row_cnt][bl_col_cnt] <= bl_second_l0;
    else begin
        for (i = 0; i < 10; i = i + 1) begin
            for (j = 0; j < 10; j = j + 1) begin
                bl_matrix_l0[i][j] <= bl_matrix_l0[i][j];
            end
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < 10; i = i + 1) begin
            for (j = 0; j < 10; j = j + 1) begin
                bl_matrix_l1[i][j] <= 'd0;
            end
        end
    end
    else if (c_state == CAL_1 && bl_row_cnt !== 10)
        bl_matrix_l1[bl_row_cnt][bl_col_cnt] <= bl_second_l1;
    else begin
        for (i = 0; i < 10; i = i + 1) begin
            for (j = 0; j < 10; j = j + 1) begin
                bl_matrix_l1[i][j] <= bl_matrix_l1[i][j];
            end
        end
    end
end
//=======================================================
//                   SAD
//=======================================================
always @(*) begin
        SAD_0 = {4'd0, SAD_0_value};
        SAD_1 = {4'd1, SAD_1_value};
        SAD_2 = {4'd2, SAD_2_value};
        SAD_3 = {4'd3, SAD_3_value};
        SAD_4 = {4'd4, SAD_4_value};
        SAD_5 = {4'd5, SAD_5_value};
        SAD_6 = {4'd6, SAD_6_value};
        SAD_7 = {4'd7, SAD_7_value};
        SAD_8 = {4'd8, SAD_8_value};
end
// SAD0
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        SAD_0_value <= 0;
    else if (c_state == IDLE)
        SAD_0_value <= 0;
    else if (c_state == WAIT)
        SAD_0_value <= 0;
    else if (c_state == CAL_1) begin
        if (bl_col_cnt <= 9 && bl_col_cnt >= 2 && bl_row_cnt >= 2 && bl_row_cnt <= 9) begin
            if (bl_matrix_l0[bl_row_cnt - 2][bl_col_cnt -2] > bl_second_l1) begin
                SAD_0_value <= SAD_0_value + (bl_matrix_l0[bl_row_cnt - 2][bl_col_cnt -2] - bl_second_l1);
            end
            else
                SAD_0_value <= SAD_0_value + (bl_second_l1 - bl_matrix_l0[bl_row_cnt - 2][bl_col_cnt -2]);
        end
        else
            SAD_0_value <= SAD_0_value;
    end
    else
        SAD_0_value <= SAD_0_value;
end
// SAD1
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        SAD_1_value <= 0;
    else if (c_state == IDLE)
        SAD_1_value <= 0;
    else if (c_state == WAIT)
        SAD_1_value <= 0;
    else if (c_state == CAL_1) begin
        if (bl_col_cnt <= 9 && bl_col_cnt >= 2 && bl_row_cnt >= 1 && bl_row_cnt <= 8) begin
            if (bl_matrix_l0[bl_row_cnt][bl_col_cnt -2] > bl_second_l1) begin
                SAD_1_value <= SAD_1_value + (bl_matrix_l0[bl_row_cnt][bl_col_cnt -2] - bl_second_l1);
            end
            else
                SAD_1_value <= SAD_1_value + (bl_second_l1 - bl_matrix_l0[bl_row_cnt][bl_col_cnt -2]);
        end
        else
            SAD_1_value <= SAD_1_value;
    end
    else
        SAD_1_value <= SAD_1_value;
end
// SAD2
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        SAD_2_value <= 0;
    else if (c_state == IDLE)
        SAD_2_value <= 0;
    else if (c_state == WAIT)
        SAD_2_value <= 0;
    else if (c_state == CAL_1) begin
        if (bl_col_cnt <= 9 && bl_col_cnt >= 2 && bl_row_cnt >= 0 && bl_row_cnt <= 7) begin
            if (bl_matrix_l0[bl_row_cnt + 2][bl_col_cnt -2] > bl_second_l1) begin
                SAD_2_value <= SAD_2_value + (bl_matrix_l0[bl_row_cnt + 2][bl_col_cnt -2] - bl_second_l1);
            end
            else
                SAD_2_value <= SAD_2_value + (bl_second_l1 - bl_matrix_l0[bl_row_cnt + 2][bl_col_cnt -2]);
        end
        else
            SAD_2_value <= SAD_2_value;
    end
    else
        SAD_2_value <= SAD_2_value;
end

// SAD3
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        SAD_3_value <= 0;
    else if (c_state == IDLE)
        SAD_3_value <= 0;
    else if (c_state == WAIT)
        SAD_3_value <= 0;
    else if (c_state == CAL_1) begin
        if (bl_col_cnt <= 8 && bl_col_cnt >= 1 && bl_row_cnt >= 2 && bl_row_cnt <= 9) begin
            if (bl_matrix_l0[bl_row_cnt - 2][bl_col_cnt] > bl_second_l1) begin
                SAD_3_value <= SAD_3_value + (bl_matrix_l0[bl_row_cnt - 2][bl_col_cnt] - bl_second_l1);
            end
            else
                SAD_3_value <= SAD_3_value + (bl_second_l1 - bl_matrix_l0[bl_row_cnt - 2][bl_col_cnt]);
        end
        else
            SAD_3_value <= SAD_3_value;
    end
    else
        SAD_3_value <= SAD_3_value;
end
// SAD4
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        SAD_4_value <= 0;
    else if (c_state == IDLE)
        SAD_4_value <= 0;
    else if (c_state == WAIT)
        SAD_4_value <= 0;
    else if (c_state == CAL_1) begin
        if (bl_col_cnt <= 8 && bl_col_cnt >= 1 && bl_row_cnt >= 1 && bl_row_cnt <= 8) begin
            if (bl_second_l0 > bl_second_l1) begin
                SAD_4_value <= SAD_4_value + (bl_second_l0 - bl_second_l1);
            end
            else
                SAD_4_value <= SAD_4_value + (bl_second_l1 - bl_second_l0);
        end
        else
            SAD_4_value <= SAD_4_value;
    end
    else
        SAD_4_value <= SAD_4_value;
end
// SAD5
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        SAD_5_value <= 0;
    else if (c_state == IDLE)
        SAD_5_value <= 0;
    else if (c_state == WAIT)
        SAD_5_value <= 0;
    else if (c_state == CAL_1) begin
        if (bl_col_cnt <= 8 && bl_col_cnt >= 1 && bl_row_cnt >= 2 && bl_row_cnt <= 9) begin
            if (bl_matrix_l1[bl_row_cnt - 2][bl_col_cnt] > bl_second_l0) begin
                SAD_5_value <= SAD_5_value + (bl_matrix_l1[bl_row_cnt - 2][bl_col_cnt] - bl_second_l0);
            end
            else
                SAD_5_value <= SAD_5_value + (bl_second_l0 - bl_matrix_l1[bl_row_cnt - 2][bl_col_cnt]);
        end
        else
            SAD_5_value <= SAD_5_value;
    end
    else
        SAD_5_value <= SAD_5_value;
end

// SAD6
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        SAD_6_value <= 0;
    else if (c_state == IDLE)
        SAD_6_value <= 0;
    else if (c_state == WAIT)
        SAD_6_value <= 0;
    else if (c_state == CAL_1) begin
        if (bl_col_cnt <= 9 && bl_col_cnt >= 2 && bl_row_cnt >= 0 && bl_row_cnt <= 7) begin
            if (bl_matrix_l1[bl_row_cnt + 2][bl_col_cnt -2] > bl_second_l0) begin
                SAD_6_value <= SAD_6_value + (bl_matrix_l1[bl_row_cnt + 2][bl_col_cnt -2] - bl_second_l0);
            end
            else
                SAD_6_value <= SAD_6_value + (bl_second_l0 - bl_matrix_l1[bl_row_cnt + 2][bl_col_cnt -2]);
        end
        else
            SAD_6_value <= SAD_6_value;
    end
    else
        SAD_6_value <= SAD_6_value;
end
// SAD7
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        SAD_7_value <= 0;
    else if (c_state == IDLE)
        SAD_7_value <= 0;
    else if (c_state == WAIT)
        SAD_7_value <= 0;
    else if (c_state == CAL_1) begin
        if (bl_col_cnt <= 9 && bl_col_cnt >= 2 && bl_row_cnt >= 1 && bl_row_cnt <= 8) begin
            if (bl_matrix_l1[bl_row_cnt][bl_col_cnt -2] > bl_second_l0) begin
                SAD_7_value <= SAD_7_value + (bl_matrix_l1[bl_row_cnt][bl_col_cnt -2] - bl_second_l0);
            end
            else
                SAD_7_value <= SAD_7_value + (bl_second_l0 - bl_matrix_l1[bl_row_cnt][bl_col_cnt -2]);
        end
        else
            SAD_7_value <= SAD_7_value;
    end
    else
        SAD_7_value <= SAD_7_value;
end
// SAD8
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        SAD_8_value <= 0;
    else if (c_state == IDLE)
        SAD_8_value <= 0;
    else if (c_state == WAIT)
        SAD_8_value <= 0;
    else if (c_state == CAL_1) begin
        if (bl_col_cnt <= 9 && bl_col_cnt >= 2 && bl_row_cnt >= 2 && bl_row_cnt <= 9) begin
            if (bl_matrix_l1[bl_row_cnt - 2][bl_col_cnt -2] > bl_second_l0) begin
                SAD_8_value <= SAD_8_value + (bl_matrix_l1[bl_row_cnt - 2][bl_col_cnt -2] - bl_second_l0);
            end
            else
                SAD_8_value <= SAD_8_value + (bl_second_l0 - bl_matrix_l1[bl_row_cnt - 2][bl_col_cnt -2]);
        end
        else
            SAD_8_value <= SAD_8_value;
    end
    else
        SAD_8_value <= SAD_8_value;
end
//=======================================================
//                   COMPARE
//=======================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        smallest_SAD_temp <= 'd0;
    else if (c_state == CAL_1) begin
        if (bl_col_cnt == 8 && bl_row_cnt == 9)
            smallest_SAD_temp <= SAD_4;
        else if (bl_col_cnt == 8 && bl_row_cnt == 10) begin
            if (smallest_SAD_temp[23:0] > SAD_3_value)
                smallest_SAD_temp <=  SAD_3;
            else
                smallest_SAD_temp <= smallest_SAD_temp;
        end 
        else if (bl_col_cnt == 9 && bl_row_cnt == 0) begin
            if (smallest_SAD_temp[23:0] > SAD_5_value)
                smallest_SAD_temp <=  SAD_5;
            else
                smallest_SAD_temp <= smallest_SAD_temp;
        end
        else if (bl_col_cnt == 9 && bl_row_cnt == 8) begin
            if (smallest_SAD_temp[23:0] > SAD_2_value)
                smallest_SAD_temp <= SAD_2;
            else
                smallest_SAD_temp <= smallest_SAD_temp; 
        end
        else if (bl_col_cnt == 9 && bl_row_cnt == 9) begin
            if (smallest_SAD_temp[23:0] > SAD_1_value)
                smallest_SAD_temp <= SAD_1;
            else
                smallest_SAD_temp <= smallest_SAD_temp; 
        end
        else
            smallest_SAD_temp <= smallest_SAD_temp;
    end
    else if (c_state == COMPARE_1) begin
        if (counter == 0) begin
            if (smallest_SAD_temp[23:0] > SAD_0_value)
                smallest_SAD_temp <= SAD_0;
            else
                smallest_SAD_temp <= smallest_SAD_temp; 
        end
        else if (counter == 1) begin
            if (smallest_SAD_temp[23:0] > SAD_6_value)
                smallest_SAD_temp <= SAD_6;
            else
                smallest_SAD_temp <= smallest_SAD_temp;
        end
        else if (counter == 2) begin
            if (smallest_SAD_temp[23:0] > SAD_7_value)
                smallest_SAD_temp <= SAD_7;
            else
                smallest_SAD_temp <= smallest_SAD_temp;
        end
        else if (counter == 3) begin
            if (smallest_SAD_temp[23:0] > SAD_8_value)
                smallest_SAD_temp <= SAD_8;
            else
                smallest_SAD_temp <= smallest_SAD_temp;
        end
        else
            smallest_SAD_temp <= smallest_SAD_temp;
    end
    else
        smallest_SAD_temp <= smallest_SAD_temp;
end

//=======================================================
//                   COMPARE
//=======================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        point2_start <= 0;
    else if (c_state == IDLE)
        point2_start <= 0;
    else if (c_state == WAIT)
        point2_start <= 1;
    else
        point2_start <= point2_start;
end

// always @(posedge clk or negedge rst_n) begin
//     if (!rst_n)
//         smallest_SAD_1 <= 0;
//     else if (c_state == COMPARE_1 && !point2_start)
//         smallest_SAD_1 <= smallest_SAD_temp;
//     else
//         smallest_SAD_1 <= smallest_SAD_1;
// end

// always @(posedge clk or negedge rst_n) begin
//     if (!rst_n)
//         smallest_SAD_2 <= 0;
//     else if (c_state == COMPARE_1 && point2_start)
//         smallest_SAD_2 <= smallest_SAD_temp;
//     else
//         smallest_SAD_2 <= smallest_SAD_2;
// end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        smallest_SAD_1 <= 0;
    else if (c_state == WAIT && !point2_start)
        smallest_SAD_1 <= smallest_SAD_temp;
    else
        smallest_SAD_1 <= smallest_SAD_1;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        smallest_SAD_2 <= 0;
    else if (c_state == WAIT && point2_start)
        smallest_SAD_2 <= smallest_SAD_temp;
    else
        smallest_SAD_2 <= smallest_SAD_2;
end

always @(*) begin
    smallest_SAD = {smallest_SAD_2, smallest_SAD_1};
end

//=======================================================
//                   OUTPUT
//=======================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        out_valid <= 0;
    else if (c_state == IDLE)
        out_valid <= 0;
    else if (c_state == OUT)
        out_valid <= 1;
    else
        out_valid <= 0;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        out_sad <= 0;
    else if (c_state == IDLE)
        out_sad <= 0;
    else if (c_state == OUT)
        out_sad <= smallest_SAD[counter];
    else
        out_sad <= 0;
    
end
endmodule
