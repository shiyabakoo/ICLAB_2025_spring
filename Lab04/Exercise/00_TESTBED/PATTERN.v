//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2023 Fall
//   Lab04 Exercise		: Two Head Attention
//   Author     		: Yu-Chi Lin (a6121461214.st12@nycu.edu.tw)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : ATTN.v
//   Module Name : ATTN
//   Release version : V1.0 (Release Date: 2025-3)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

`define CYCLE_TIME      31.0
`define SEED_NUMBER     28825252
`define PATTERN_NUMBER 10

module PATTERN(
    //Output Port
    clk,
    rst_n,

    in_valid,
    in_str,
    q_weight,
    k_weight,
    v_weight,
    out_weight,

    //Input Port
    out_valid,
    out
    );

//---------------------------------------------------------------------
//   PORT DECLARATION          
//---------------------------------------------------------------------
output  logic        clk, rst_n, in_valid;
output  logic[31:0]  in_str;
output  logic[31:0]  q_weight;
output  logic[31:0]  k_weight;
output  logic[31:0]  v_weight;
output  logic[31:0]  out_weight;

input           out_valid;
input   [31:0]  out;

//---------------------------------------------------------------------
//   PARAMETER & INTEGER DECLARATION
//---------------------------------------------------------------------
real CYCLE = `CYCLE_TIME;
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch_type = 0;
parameter inst_arch = 0;

integer i, j;
parameter PATTERN_NUM = `PATTERN_NUMBER;

//---------------------------------------------------------------------
//   Reg & Wires
//---------------------------------------------------------------------
real str_fp;
real k_weight_fp;
real q_weight_fp;
real v_weight_fp;
real out_weight_fp;

real str_arr        [0:19];
real k_arr          [0:15];
real q_arr          [0:15];
real v_arr          [0:15];
real out_arr        [0:15];

real product_k      [0:19];
real product_q      [0:19];
real product_v      [0:19];

real score1_matrix  [0:24];
real score2_matrix  [0:24];
real head1_matrix   [0:9];
real head2_matrix   [0:9];

real final_matrix   [0:19];

real error;
bit error_flag;

//================================================================
// clock
//================================================================
always #(CYCLE/2.0) clk = ~clk;
initial	clk = 0;

//---------------------------------------------------------------------
//   Pattern_Design
//---------------------------------------------------------------------
initial begin
    reset_task;

    for(integer p = 0; p < PATTERN_NUM; p = p + 1) begin
        // $display("\n\033[36mPATTERN %0d \033[0m", p);

        input_task;
        KQV_task;
        score1_task;
        score2_task;
        final_output_task;
        check_ans_task(p);
    end


    repeat(5) @(negedge clk);
    $finish;

end

function automatic real fp_to_real(input [31:0] fp);
    integer s, e, f;
    real frac;
    begin
        s = fp[31];
        e = fp[30:23];
        f = fp[22:0];

        // 為了避免整數除法問題，先把 f 轉成 real
        frac = f;

        if (e == 255) begin
            // 指數全1：表示 Infinity 或 NaN
            if (f == 0)
                fp_to_real = (s==0) ? 1.0/0.0 : -1.0/0.0; // +/- Inf
            else
                fp_to_real = 0.0/0.0; // NaN
        end 
        else if (e == 0) begin
            // 次常數數值
            fp_to_real = ((s==0) ? 1.0 : -1.0)
                         * (frac / (1.0 * (1 << 23)))  // 實數除法
                         * $pow(2.0, -126);
        end 
        else begin
            // 常數數值
            fp_to_real = ((s==0) ? 1.0 : -1.0)
                         * (1.0 + frac / (1.0 * (1 << 23))) // 實數除法
                         * $pow(2.0, (e - 127));
        end
    end
endfunction


function automatic [31:0] real_to_ieee754(input real r);
    reg        sign;
    integer    n;
    real       r_abs, temp;
    integer    exponent_field, fraction_field;
    begin
        if (r == 0.0) begin
            real_to_ieee754 = 32'h0;
        end 
        else begin
            // 取符號與絕對值
            sign  = (r < 0.0) ? 1'b1 : 1'b0;
            r_abs = (r < 0.0) ? -r : r;
            
            // 正規化：將 r_abs 調整到 [1,2) 區間
            n = 0;
            temp = r_abs;
            while (temp < 1.0) begin
                temp = temp * 2.0;
                n = n - 1;
            end
            while (temp >= 2.0) begin
                temp = temp / 2.0;
                n = n + 1;
            end
            
            exponent_field = n + 127;
            fraction_field = (temp - 1.0) * (1 << 23);
            
            real_to_ieee754 = {sign, exponent_field[7:0], fraction_field[22:0]};
        end
    end
endfunction

function automatic real softmax1_fn(input integer row, input integer col);
    real sum_exp;
    integer k;
    begin
        sum_exp = 0.0;
        // 計算該列所有元素的 exp 加總
        for(k = 0; k < 5; k = k + 1) begin
            sum_exp = sum_exp + $exp(score1_matrix[row*5 + k]);
        end
        // $display(" sum exp = %6.7f", sum_exp);
        softmax1_fn = $exp(score1_matrix[row*5 + col]) / sum_exp;
    end
endfunction

function automatic real softmax2_fn(input integer row, input integer col);
    real sum_exp;
    integer t;
    begin
        sum_exp = 0.0;
        for(t = 0; t < 5; t = t + 1) begin
            sum_exp = sum_exp + $exp(score2_matrix[row*5 + t]); 
        end
        // $display(" sum exp = %6.7f", sum_exp);
        softmax2_fn = $exp(score2_matrix[row*5 + col]) / sum_exp;
    end
endfunction

//---------------------------------------------------------------------
//   TASKS
//---------------------------------------------------------------------
task reset_task; begin
	rst_n       = 1'b1;
	in_valid    = 1'b0;

    in_str      = 32'bx;
    q_weight    = 32'bx;
    k_weight    = 32'bx;
    v_weight    = 32'bx;
    out_weight  = 32'bx;

	force clk = 0;

	// Apply reset
    #CYCLE; rst_n = 1'b0; 

	// Check initial conditions
    // if (out_valid !== 1'b0 || out !== 32'd0) begin
    //     $display("************************************************************");  
    //     $display("*  Output signals should be 0 after initial RESET at %8t *", $time);
    //     $display("************************************************************");

    //     $finish;
    // end

    #CYCLE; rst_n = 1'b1;
	#CYCLE; release clk;
end endtask


task input_task; begin
    repeat(2) @(negedge clk);
    in_valid = 1'b1;
    for(i = 0; i < 20; i = i + 1) begin
        str_fp = ($urandom() / (2.0**32 - 1)) - 0.5;
        in_str = real_to_ieee754(str_fp);
        // 把 IEEE754 轉換結果存入陣列 in_str[i]
        str_arr[i] = str_fp;
        
        if(i < 16) begin
            k_weight_fp = ($urandom() / (2.0**32 - 1)) - 0.5;
            q_weight_fp = ($urandom() / (2.0**32 - 1)) - 0.5;
            v_weight_fp = ($urandom() / (2.0**32 - 1)) - 0.5;
            out_weight_fp = ($urandom() / (2.0**32 - 1)) - 0.5;
            
            k_weight = real_to_ieee754(k_weight_fp);
            q_weight = real_to_ieee754(q_weight_fp);
            v_weight = real_to_ieee754(v_weight_fp);
            out_weight = real_to_ieee754(out_weight_fp);
            
            k_arr[i] = k_weight_fp;
            q_arr[i] = q_weight_fp;
            v_arr[i] = v_weight_fp;
            out_arr[i] = out_weight_fp;
        end
        else begin
            k_weight = 32'bx;
            q_weight = 32'bx;
            v_weight = 32'bx;
            out_weight = 32'bx;
        end

        @(negedge clk);
    end

    in_valid = 1'b0;
    in_str = 32'bx;

    // 顯示矩陣
    // $display("\n---------------------------------------------------------------------INPUT MATRIXS---------------------------------------------------------------------");
    // $display("STR MATRIX                     K MATRIX                       Q MATRIX                       V MATRIX                       OUT MATRIX");
    // // 顯示前 4 行
    // for(i = 0; i < 4; i = i + 1) begin
    //     for(j = 0; j < 4; j = j + 1)
    //         $write("%6.3f ", str_arr[i*4 + j]);
    //     $write("   ");
    //     for(j = 0; j < 4; j = j + 1)
    //         $write("%6.3f ", k_arr[i*4 + j]);
    //     $write("   ");
    //     for(j = 0; j < 4; j = j + 1)
    //         $write("%6.3f ", q_arr[i*4 + j]);
    //     $write("   ");
    //     for(j = 0; j < 4; j = j + 1)
    //         $write("%6.3f ", v_arr[i*4 + j]);
    //     $write("   ");
    //     for(j = 0; j < 4; j = j + 1)
    //         $write("%6.3f ", out_arr[i*4 + j]);
    //     $display("");
    // end
    // for(j = 0; j < 4; j = j + 1)
    //     $write("%6.3f ", str_arr[4*4 + j]);
    // $display("");
end endtask



task KQV_task; 
    integer i, j, k;
    begin
        // 初始化結果矩陣
        for(i = 0; i < 5; i = i + 1)
            for(j = 0; j < 4; j = j + 1) begin
                product_k[i*4 + j] = 0.0;
                product_q[i*4 + j] = 0.0;
                product_v[i*4 + j] = 0.0;
            end

        // 計算 product_k = in_str * (k_arr)^T
        // 公式： product_k(i,j) = sum_{k=0}^{3} in_str(i,k) * k_arr(j,k)
        for(i = 0; i < 5; i = i + 1) begin
            for(j = 0; j < 4; j = j + 1) begin
                for(k = 0; k < 4; k = k + 1) begin
                    product_k[i*4 + j] = product_k[i*4 + j] + str_arr[i*4 + k] * k_arr[j*4 + k];
                end
            end
        end

        // 計算 product_q = in_str * (q_arr)^T
        for(i = 0; i < 5; i = i + 1) begin
            for(j = 0; j < 4; j = j + 1) begin
                for(k = 0; k < 4; k = k + 1) begin
                    product_q[i*4 + j] = product_q[i*4 + j] + str_arr[i*4 + k] * q_arr[j*4 + k];
                end
            end
        end

        // 計算 product_v = in_str * (v_arr)^T
        for(i = 0; i < 5; i = i + 1) begin
            for(j = 0; j < 4; j = j + 1) begin
                for(k = 0; k < 4; k = k + 1) begin
                    product_v[i*4 + j] = product_v[i*4 + j] + str_arr[i*4 + k] * v_arr[j*4 + k];
                end
            end
        end

        // $display("\n---------------------------------------------------------------------KQV CALCULATE---------------------------------------------------------------------");
        // $display("STR_KT                           STR_QT                           STR_VT");
        // for(i = 0; i < 5; i = i + 1) begin
        //     for(j = 0; j < 4; j = j + 1) begin
        //         $write("%6.3f ", product_k[i*4 + j]);
        //     end
        //     $write("  |  ");
        //     // 顯示 product_q 第 i 行
        //     for(j = 0; j < 4; j = j + 1) begin
        //         $write("%6.3f ", product_q[i*4 + j]);
        //     end
        //     $write("  |  ");
        //     // 顯示 product_v 第 i 行
        //     for(j = 0; j < 4; j = j + 1) begin
        //         $write("%6.3f ", product_v[i*4 + j]);
        //     end
        //     $display("");
        // end
    end
endtask

task score1_task;
    integer i, j, c, k;
    real        softmax_matrix [0:24];
    reg [31:0]  sqrt2_fp;
    real        sqrt2;
    begin

        // 初始化 score1_matrix 為 0
        for(i = 0; i < 5; i = i + 1)
            for(j = 0; j < 5; j = j + 1)
                score1_matrix[i*5 + j] = 0.0;
        
        // 乘法計算：
        // 取 product_q 的前 2 欄，每列為 5x2
        // 取 product_k 的前 2 欄，每列為 5x2
        // 計算 score[i][j] = sum{ c=0 to 1 } product_q(i,c) * product_k(j,c)
        // 注意：因為是乘以 product_k 的轉置，所以內層取值為 product_k[j][c]
        for(i = 0; i < 5; i = i + 1) begin
            for(j = 0; j < 5; j = j + 1) begin
                for(c = 0; c < 2; c = c + 1) begin
                    // product_q 的第 i 行第 c 個元素在 product_q[i*4 + c]
                    // product_k 的第 j 行第 c 個元素在 product_k[j*4 + c]
                    score1_matrix[i*5 + j] = score1_matrix[i*5 + j] + product_q[i*4 + c] * product_k[j*4 + c];
                end
            end
        end
        
        // 3. 將 score1_matrix 除以根號2
        sqrt2_fp = 32'b00111111101101010000010011110011;
        // 使用 fp_to_real 將 32 位 IEEE754 數轉換為 real 值 (假設該函式已定義)
        sqrt2 = fp_to_real(sqrt2_fp);
        for(i = 0; i < 25; i = i + 1) begin
            score1_matrix[i] = score1_matrix[i] / sqrt2;
        end
        
        // 4. 對 score1_matrix 的每一列做 softmax 運算，結果存入 softmax_matrix
        for(i = 0; i < 5; i = i + 1) begin
            for(j = 0; j < 5; j = j + 1) begin
                softmax_matrix[i*5 + j] = softmax1_fn(i, j);
            end
        end

        // 5. 將 softmax_matrix (5x5) 乘以 product_q 前面 5x2 子矩陣
        // product_q 的前 2 欄：每列元素索引為 product_q[k*4+0] 與 product_q[k*4+1] (k = 0 ~ 4)
        // 得到 head1_matrix 為 5x2 矩陣，計算公式：
        // head1[i][j] = sum_{k=0}^{4} softmax_matrix[i][k] * product_q[k][j] , (j=0,1)
        // 初始化 head1_matrix 為 0
        for(i = 0; i < 5; i = i + 1)
            for(j = 0; j < 2; j = j + 1)
                head1_matrix[i*2 + j] = 0.0;
        // 矩陣乘法
        for(i = 0; i < 5; i = i + 1) begin
            for(j = 0; j < 2; j = j + 1) begin
                for(k = 0; k < 5; k = k + 1) begin
                    head1_matrix[i*2 + j] = head1_matrix[i*2 + j] + softmax_matrix[i*5 + k] * product_v[k*4 + j];
                end
            end
        end


        // $display("\n--------------------------------------------------------------------SCORE CALCULATE--------------------------------------------------------------------");
        // $display("SCORE1                                                      SCORE1 AFTER SOFTMAX                                       HEAD1");
        // for(i = 0; i < 5; i = i + 1) begin
        //     for(j = 0; j < 5; j = j + 1) begin
        //         $write("%10.7f ", score1_matrix[i*5 + j]);
        //     end
        //     $write("    ");
        //     for(j = 0; j < 5; j = j + 1) begin
        //         $write("%10.7f ", softmax_matrix[i*5 + j]);
        //     end
        //     $write("    ");
        //     for(j = 0; j < 2; j = j + 1) begin
        //         $write("%10.7f ", head1_matrix[i*2 + j]);
        //     end

        //     $display("");
        // end
    end
endtask

task score2_task;
    integer i, j, c, k;
    real softmax2_matrix[0:24];
    reg [31:0] sqrt2_fp;
    real sqrt2;
    begin
        // 1. 初始化 score2_matrix 為 0
        for(i = 0; i < 5; i = i + 1)
            for(j = 0; j < 5; j = j + 1)
                score2_matrix[i*5 + j] = 0.0;

        // 2. 計算 score2_matrix (5x5)：
        //    score2[i][j] = sum_{c=2}^{3} product_q[i][c] * product_k[j][c]
        //    注意：product_q 為 5x4，product_k 為 5x4，採用轉置運算故 product_k 的取值為 product_k[j*4+c]
        for(i = 0; i < 5; i = i + 1) begin
            for(j = 0; j < 5; j = j + 1) begin
                for(c = 2; c < 4; c = c + 1) begin
                    score2_matrix[i*5 + j] = score2_matrix[i*5 + j] + 
                        product_q[i*4 + c] * product_k[j*4 + c];
                end
            end
        end

        // 3. 將 score2_matrix 每個元素除以根號2
        sqrt2_fp = 32'b00111111101101010000010011110011;
        sqrt2 = fp_to_real(sqrt2_fp);
        for(i = 0; i < 25; i = i + 1) begin
            score2_matrix[i] = score2_matrix[i] / sqrt2;
        end

        // 4. 對 score2_matrix 的每一列做 softmax 運算，結果存入 softmax2_matrix
        for(i = 0; i < 5; i = i + 1) begin
            for(j = 0; j < 5; j = j + 1) begin
                softmax2_matrix[i*5 + j] = softmax2_fn(i, j);
            end
        end

        // 5. 計算 head2_matrix (5x2)：
        //    head2[i][j] = sum_{k=0}^{4} softmax2_matrix[i][k] * product_v[k][j+2]
        //    其中 product_v 的後面 2 欄取自 product_v[k*4 + (j+2)], (j = 0,1)
        for(i = 0; i < 5; i = i + 1)
            for(j = 0; j < 2; j = j + 1)
                head2_matrix[i*2 + j] = 0.0;
        for(i = 0; i < 5; i = i + 1) begin
            for(j = 0; j < 2; j = j + 1) begin
                for(k = 0; k < 5; k = k + 1) begin
                    head2_matrix[i*2 + j] = head2_matrix[i*2 + j] + 
                        softmax2_matrix[i*5 + k] * product_v[k*4 + (j+2)];
                end
            end
        end

        // 6. 顯示結果：
        // $display("\nSCORE2                                                      SCORE2 AFTER SOFTMAX                                       HEAD2");
        // for(i = 0; i < 5; i = i + 1) begin
        //     for(j = 0; j < 5; j = j + 1) begin
        //         $write("%10.7f ", score2_matrix[i*5 + j]);
        //     end
        //     $write("    ");
        //     for(j = 0; j < 5; j = j + 1) begin
        //         $write("%10.7f ", softmax2_matrix[i*5 + j]);
        //     end
        //     $write("    ");
        //     for(j = 0; j < 2; j = j + 1) begin
        //         $write("%10.7f ", head2_matrix[i*2 + j]);
        //     end

        //     $display("");
        // end
    end
endtask

task final_output_task;
    integer i, j, k;
    // 將 head1_matrix (5x2) 與 head2_matrix (5x2) 串接成 5x4 的 head_concat
    real head_concat[0:19];  // 5x4 矩陣，共 20 個元素
    // 最終結果矩陣 (5x4) 
    begin
        // --- 1. 串接 head1_matrix 與 head2_matrix 產生 head_concat (5x4) ---
        for(i = 0; i < 5; i = i + 1) begin
            // 左側兩欄來自 head1_matrix
            head_concat[i*4 + 0] = head1_matrix[i*2 + 0];
            head_concat[i*4 + 1] = head1_matrix[i*2 + 1];
            // 右側兩欄來自 head2_matrix
            head_concat[i*4 + 2] = head2_matrix[i*2 + 0];
            head_concat[i*4 + 3] = head2_matrix[i*2 + 1];
        end

        // --- 2. 將 head_concat (5x4) 乘以 out_weight 的轉置 (4x4) ---
        // out_weight 為 4x4，全域變數 (存取方式: out_weight[j*4 + k] 為轉置後 [k][j])
        // 結果矩陣 final_matrix 為 5x4
        for(i = 0; i < 5; i = i + 1) begin
            for(j = 0; j < 4; j = j + 1) begin
                final_matrix[i*4 + j] = 0.0;
                for(k = 0; k < 4; k = k + 1) begin
                    // (out_weight^T)[k][j] = out_weight[j*4 + k]
                    final_matrix[i*4 + j] = final_matrix[i*4 + j] + head_concat[i*4 + k] * out_arr[j*4 + k];
                end
            end
        end

        // --- 3. 顯示最終結果矩陣 (5x4) ---
        // $display("\nFINAL OUTPUT");
        // for(i = 0; i < 5; i = i + 1) begin
        //     for(j = 0; j < 4; j = j + 1) begin
        //         $write("%10.8f ", final_matrix[i*4 + j]);
        //     end
        //     $display("");
        // end
    end
endtask


task check_ans_task(input integer pattern_index);
    integer i, j;
    real out_array[0:19]; // 用來存 20 個 out 值
    begin
        error_flag = 0;
        // $display("\n-------------------------------------------------YOUR OUTPUT-------------------------------------------------");
        // 等待 out_valid 被拉高
        wait(out_valid == 1'b1);
        
        // 在 out_valid 持續期間，收集 20 個 out 值
        // for(i = 0; i < 20; i = i + 1) begin

        //     out_array[i] = fp_to_real(out);
        // end

        for(i = 0; i < 20; i = i + 1) begin
            // 計算絕對誤差
            @(negedge clk);
            out_array[i] = fp_to_real(out);
            error = (out_array[i] >= final_matrix[i]) ? (out_array[i] - final_matrix[i]) : (final_matrix[i] - out_array[i]);
            if(error > 1e-7) begin
                error_flag = 1;
                $display("ERROR at time %0t: Element %5d, YOUR OUTPUT = %10.7f, Expected = %10.7f, Error = %10.7f", $time, i, out_array[i], final_matrix[i], error);
                $finish;
            end
            else begin
                error_flag = 0;
            end
        end

        if(error_flag == 0) begin
            $write("PATTERN %3d: ", pattern_index);
            $display("\033[32mPASS\033[0m");
        end
    end
endtask

endmodule


// //############################################################################
// //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// //   (C) Copyright Laboratory System Integration and Silicon Implementation
// //   All Right Reserved
// //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// //
// //   ICLAB 2023 Fall
// //   Lab04 Exercise		: Two Head Attention
// //   Author     		: Yu-Chi Lin (a6121461214.st12@nycu.edu.tw)
// //
// //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// //
// //   File Name   : ATTN.v
// //   Module Name : ATTN
// //   Release version : V1.0 (Release Date: 2025-3)
// //
// //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// //############################################################################

// `define CYCLE_TIME      31
// `define SEED_NUMBER     28825252
// `define PATTERN_NUMBER  10

// module PATTERN(
//     //Output Port
//     clk,
//     rst_n,

//     in_valid,
//     in_str,
//     q_weight,
//     k_weight,
//     v_weight,
//     out_weight,

//     //Input Port
//     out_valid,
//     out
//     );

// //---------------------------------------------------------------------
// //   PORT DECLARATION          
// //---------------------------------------------------------------------
// output  logic        clk, rst_n, in_valid;
// output  logic[31:0]  in_str;
// output  logic[31:0]  q_weight;
// output  logic[31:0]  k_weight;
// output  logic[31:0]  v_weight;
// output  logic[31:0]  out_weight;

// input           out_valid;
// input   [31:0]  out;

// //---------------------------------------------------------------------
// //   PARAMETER & INTEGER DECLARATION
// //---------------------------------------------------------------------
// real CYCLE = `CYCLE_TIME;
// parameter inst_sig_width = 23;
// parameter inst_exp_width = 8;
// parameter inst_ieee_compliance = 0;
// parameter inst_arch_type = 0;
// parameter inst_arch = 0;


// parameter IMAG_SIZE = 5;
// parameter WEIGHT_SIZE = 4;

// integer i_pat;
// integer total_latency, latency;
// integer t;
// integer out_num;
// integer SEED = `SEED_NUMBER;

// //---------------------------------------------------------------------
// //   Reg & Wires
// //---------------------------------------------------------------------
// //input
// reg [inst_sig_width + inst_exp_width : 0] _in_str[0:IMAG_SIZE - 1][0:WEIGHT_SIZE - 1 ];
// reg [inst_sig_width + inst_exp_width : 0] _k_weight[0:WEIGHT_SIZE - 1][0:WEIGHT_SIZE - 1];
// reg [inst_sig_width + inst_exp_width : 0] _q_weight[0:WEIGHT_SIZE - 1][0:WEIGHT_SIZE - 1];
// reg [inst_sig_width + inst_exp_width : 0] _v_weight[0:WEIGHT_SIZE - 1][0:WEIGHT_SIZE - 1];
// reg [inst_sig_width + inst_exp_width : 0] _out_weight[0:WEIGHT_SIZE - 1][0:WEIGHT_SIZE - 1];

// // KQV
// wire [inst_sig_width + inst_exp_width : 0] _K[0:IMAG_SIZE - 1][0:WEIGHT_SIZE - 1];
// wire [inst_sig_width + inst_exp_width : 0] _Q[0:IMAG_SIZE - 1][0:WEIGHT_SIZE - 1];
// wire [inst_sig_width + inst_exp_width : 0] _V[0:IMAG_SIZE - 1][0:WEIGHT_SIZE - 1];

// wire [inst_sig_width + inst_exp_width : 0] _score[0:1][0:IMAG_SIZE - 1][0:IMAG_SIZE - 1];
// wire [inst_sig_width + inst_exp_width : 0] _head_scaling[0:1][0:IMAG_SIZE - 1][0:IMAG_SIZE - 1];
// wire [inst_sig_width + inst_exp_width : 0] _softmax[0:1][0:IMAG_SIZE - 1][0:IMAG_SIZE - 1];
// wire [inst_sig_width + inst_exp_width : 0] _head_out[0:IMAG_SIZE - 1][0:WEIGHT_SIZE - 1];
// wire [inst_sig_width + inst_exp_width : 0] _final_res[0:19];
// //output
// reg [inst_sig_width + inst_exp_width : 0] _out[0:19];

// // ERROR CHECK 0.005
// wire [inst_sig_width+inst_exp_width:0] _errAllow = 32'h33D6BF95;
// reg  [inst_sig_width+inst_exp_width:0] _errDiff;
// wire [inst_sig_width+inst_exp_width:0] _errDiff_w;
// reg  [inst_sig_width+inst_exp_width:0] _errBound;
// wire [inst_sig_width+inst_exp_width:0] _errBound_w;

// wire _isErr[0:19];

// reg[10*8:1] txt_blue_prefix   = "\033[1;34m";
// reg[10*8:1] txt_green_prefix  = "\033[1;32m";
// reg[9*8:1]  reset_color       = "\033[1;0m";

// //================================================================
// // clock
// //================================================================

// always #(CYCLE/2.0) clk = ~clk;
// initial	clk = 0;

// //---------------------------------------------------------------------
// //   Pattern_Design
// //---------------------------------------------------------------------
// always @(negedge clk) begin
// 	if(out_valid === 0 && out !== 'd0) begin
// 		$display("*************************************************************************");
// 		$display("*                              FAIL!                                    *");
// 		$display("*       The out_data should be reset when your out_valid is low.        *");
// 		$display("*************************************************************************");
// 		repeat(2) #(CYCLE);
// 		$finish;
// 	end
// end

// initial begin
//     reset_task;

//     total_latency = 0;

//     for(i_pat = 0; i_pat < `PATTERN_NUMBER; i_pat = i_pat + 1) begin
//         input_task;
//         //cal_task;
//         wait_task;
//         total_latency = total_latency + latency;
//         check_task;
//         $display("%0sPASS PATTERN NO.%4d, %0sCycles: %3d%0s",txt_blue_prefix, i_pat, txt_green_prefix, latency, reset_color);
//     end

//     // All patterns passed
//     YOU_PASS_task;
// end

// task reset_task; begin
// 	rst_n = 1'b1;
// 	in_valid = 1'b0;

// 	in_str = 'dx;
// 	q_weight = 'dx;
//     k_weight = 'dx;
//     v_weight = 'dx;
//     out_weight = 'dx;

// 	force clk = 0;

// 	// Apply reset
//     #CYCLE; rst_n = 1'b0; 
//     #CYCLE; rst_n = 1'b1;
// 	#(9 * CYCLE);

// 	// Check initial conditions
//     if (out_valid !== 0 || out !== 0) begin
//         $display("************************************************************");  
//         $display("                           FAIL                             ");    
//         $display("*  Output signals should be 0 after initial RESET at %8t *", $time);
//         $display("************************************************************");
//         repeat (2) #CYCLE;
//         $finish;
//     end

// 	#CYCLE; release clk;
// end endtask

// task input_task;
//     integer i,j,k,m,count;
// begin 
//     random_input;
    
//     t = $urandom_range(1,4);
//     repeat(t) @(negedge clk);

//     count = 0;
//     for(i = 0; i < IMAG_SIZE * (IMAG_SIZE - 1); i = i + 1)begin
//         in_valid = 'b1;
//         in_str = _in_str[(i/(IMAG_SIZE - 1)) % IMAG_SIZE][i % (IMAG_SIZE - 1)];
        

//         if(count < WEIGHT_SIZE * WEIGHT_SIZE) begin
//             k_weight = _k_weight[i/(WEIGHT_SIZE)][i % (WEIGHT_SIZE)];
//             q_weight = _q_weight[i/(WEIGHT_SIZE)][i % (WEIGHT_SIZE)];
//             v_weight = _v_weight[i/(WEIGHT_SIZE)][i % (WEIGHT_SIZE)];
//             out_weight = _out_weight[i/(WEIGHT_SIZE)][i % (WEIGHT_SIZE)];
//         end
//         else begin
//             q_weight = 'dx;
//             k_weight = 'dx;
//             v_weight = 'dx;
//             out_weight = 'dx;
//         end
        
//         @(negedge clk);
//         count = count + 1;
//     end

//     in_valid = 'b0;
//     in_str = 'dx;
// 	q_weight = 'dx;
//     k_weight = 'dx;
//     v_weight = 'dx;
//     out_weight = 'dx;
// end endtask

// function [31:0] _randinput;
//     input integer _i_pat;
//     reg [6:0] rand_fract;
//     integer idx;
//     begin
//         _randinput = 0;
//         if(_i_pat < 50) begin
//             _randinput = 0;
//             _randinput[31] = {$random(SEED)} % 2;
//             _randinput[30:23] = {$random(SEED)} % 3 + 124;
//         end
//         else begin
//             _randinput = 0;
//             _randinput[31] = {$random(SEED)} % 2;
//             _randinput[30:23] = {$random(SEED)} % 9 + 118;
//             rand_fract = {$random(SEED)} % 128;
//             for(idx = 0; idx < 7; idx = idx + 1) begin
//                 _randinput[22 - idx] = rand_fract[6-idx];
//             end
//         end
//     end
// endfunction

// // random input
// task random_input;
//     integer i,j,k,m;
// begin
//     for(i = 0; i < IMAG_SIZE; i = i + 1) begin
//         for(j = 0; j < IMAG_SIZE - 1; j = j + 1) begin
//             _in_str[i][j] = _randinput(i_pat);

//         end
//     end
//     for(i = 0; i < WEIGHT_SIZE; i = i + 1) begin
//         for(j = 0; j < WEIGHT_SIZE; j = j + 1) begin
//             _k_weight[i][j] = _randinput(i_pat);
//             _q_weight[i][j] = _randinput(i_pat);
//             _v_weight[i][j] = _randinput(i_pat);
//             _out_weight[i][j] = _randinput(i_pat);
//         end
//     end
// end endtask



// task wait_task; begin
//     latency = 0;
//     while (out_valid !== 1) begin
//         if(latency == 200) begin
//             $display("*************************************************************************");
// 		    $display("*                              FAIL!                                    *");
// 		    $display("*         The execution latency is limited in 200 cycles.               *");
// 		    $display("*************************************************************************");
// 		    repeat(2) @(negedge clk);
// 		    $finish;
//         end
//         latency = latency + 1;
//         @(negedge clk);
//     end
// end endtask

// task check_task; begin
//     out_num = 0;
//     while (out_valid === 1) begin
//         _out[out_num] = out;
//         if(_isErr[out_num] !== 0) begin
//             $display("************************************************************");  
//             $display("                          FAIL!                           ");
//             $display(" Expected: ans = %8h", _final_res[out_num]);
//             $display(" Received: ans = %8h", out);
//             $display("************************************************************");
//             $finish;
//         end
//         else begin
//             @(negedge clk);
//             out_num = out_num + 1;
//         end
//     end

//     if(out_num !== 20) begin
//             $display("************************************************************");  
//             $display("                          FAIL!                              ");
//             $display(" Expected 20 valid output, but found %d", out_num);
//             $display("************************************************************");
//             repeat(2) @(negedge clk);
//             $finish;
//     end

// end endtask

// genvar i_input, i_imag, i_row, i_col, i_innner;
// //=================
// // KQV
// //=================
// generate
//     for(i_row = 0 ; i_row < IMAG_SIZE; i_row = i_row + 1) begin: gen_kqv
//         for(i_col = 0 ; i_col < WEIGHT_SIZE ; i_col = i_col + 1) begin
//             wire [inst_sig_width+inst_exp_width:0] out0, out1, out2;
//             matrix_mul #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
//             MATR_MUL_0(
//                 _in_str[i_row][0], _in_str[i_row][1], 
//                 _in_str[i_row][2], _in_str[i_row][3],
//                 _k_weight[i_col][0], _k_weight[i_col][1], 
//                 _k_weight[i_col][2], _k_weight[i_col][3],

//                 // Output
//                 out0
//             );

//             matrix_mul #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
//             MATR_MUL_1(
//                 _in_str[i_row][0], _in_str[i_row][1], 
//                 _in_str[i_row][2], _in_str[i_row][3],
//                 _q_weight[i_col][0], _q_weight[i_col][1], 
//                 _q_weight[i_col][2], _q_weight[i_col][3],

//                 // Output
//                 out1
//             );

//             matrix_mul #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
//             MATR_MUL_2(
//                 _in_str[i_row][0], _in_str[i_row][1], 
//                 _in_str[i_row][2], _in_str[i_row][3],
//                 _v_weight[i_col][0], _v_weight[i_col][1], 
//                 _v_weight[i_col][2], _v_weight[i_col][3],

//                 // Output
//                 out2
//             );

//             assign _K[i_row][i_col] = out0;
//             assign _Q[i_row][i_col] = out1;
//             assign _V[i_row][i_col] = out2;
//         end
//     end
// endgenerate

// //=================
// // Score
// //=================
// generate
//     for(i_row = 0 ; i_row < IMAG_SIZE; i_row = i_row + 1) begin: gen_score
//         for(i_col = 0 ; i_col < IMAG_SIZE ; i_col = i_col + 1) begin
//             wire [inst_sig_width+inst_exp_width:0] out0, out1;
//             score #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
//             SCORE_0(
//                 _K[i_col][0], _K[i_col][1],
//                 _Q[i_row][0], _Q[i_row][1],
//                 out0
//             );

//             score #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
//             SCORE_1(
//                 _K[i_col][2], _K[i_col][3],
//                 _Q[i_row][2], _Q[i_row][3],
//                 out1
//             );

//             assign _score[0][i_row][i_col] = out0;
//             assign _score[1][i_row][i_col] = out1;
//         end
//     end
// endgenerate

// //=================
// // head scaling
// //=================
// generate
//     for(i_row = 0 ; i_row < IMAG_SIZE; i_row = i_row + 1) begin: gen_head_scaling
//         for(i_col = 0 ; i_col < IMAG_SIZE ; i_col = i_col + 1) begin
//             wire [inst_sig_width+inst_exp_width:0] out0, out1;
//             head_scaling #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
//             scaling_0(
//                 _score[0][i_row][i_col],
//                 out0
//             );

//             head_scaling #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
//             scaling_1(
//                 _score[1][i_row][i_col],
//                 out1
//             );

//             assign _head_scaling[0][i_row][i_col] = out0;
//             assign _head_scaling[1][i_row][i_col] = out1;
//         end
//     end
// endgenerate

// //=================
// // Soft Max
// //=================
// // TODO : improve generate for
// generate
//     for(i_input = 0; i_input < 2; i_input = i_input + 1) begin:soft
//     for(i_row = 0 ; i_row < 5; i_row = i_row + 1) begin 
//         for(i_col = 0; i_col < 5; i_col = i_col + 1) begin
//             wire [inst_sig_width+inst_exp_width:0] out0;
//             wire [inst_sig_width+inst_exp_width:0] add0, add1, add2, add3;
//             wire [inst_sig_width+inst_exp_width:0] exp[0:4];
    
//             DW_fp_exp 
//             #(inst_sig_width,inst_exp_width,inst_ieee_compliance, inst_arch)
//                 E0 (.a(_head_scaling[i_input][i_row][0]), .z(exp[0]));
//             DW_fp_exp 
//             #(inst_sig_width,inst_exp_width,inst_ieee_compliance, inst_arch)
//                 E1 (.a(_head_scaling[i_input][i_row][1]), .z(exp[1]));
//             DW_fp_exp 
//             #(inst_sig_width,inst_exp_width,inst_ieee_compliance, inst_arch)
//                 E2 (.a(_head_scaling[i_input][i_row][2]), .z(exp[2]));
//             DW_fp_exp 
//             #(inst_sig_width,inst_exp_width,inst_ieee_compliance, inst_arch)
//                 E3 (.a(_head_scaling[i_input][i_row][3]), .z(exp[3]));
//             DW_fp_exp 
//             #(inst_sig_width,inst_exp_width,inst_ieee_compliance, inst_arch)
//                 E4 (.a(_head_scaling[i_input][i_row][4]), .z(exp[4]));
    
//             DW_fp_div // [exp(x)-exp(-x)] / [exp(x)+exp(-x)]
//             #(inst_sig_width,inst_exp_width,inst_ieee_compliance, 0)
//                 D0 (.a(exp[i_col]), .b(add3), .rnd(3'd0), .z(out0));
    
//             DW_fp_addsub#(inst_sig_width,inst_exp_width,inst_ieee_compliance)
//                 A0 (.a(exp[0]), .b(exp[1]), .op(1'd0), .rnd(3'd0), .z(add0));
//             DW_fp_addsub#(inst_sig_width,inst_exp_width,inst_ieee_compliance)
//                 A1 (.a(add0), .b(exp[2]), .op(1'd0), .rnd(3'd0), .z(add1));
//             DW_fp_addsub#(inst_sig_width,inst_exp_width,inst_ieee_compliance)
//                 A2 (.a(add1), .b(exp[3]), .op(1'd0), .rnd(3'd0), .z(add2));
//             DW_fp_addsub#(inst_sig_width,inst_exp_width,inst_ieee_compliance)
//                 A3 (.a(add2), .b(exp[4]), .op(1'd0), .rnd(3'd0), .z(add3));
            
//             assign _softmax[i_input][i_row][i_col] = out0;
//         end
//     end
//     end
// endgenerate

// //=================
// // weight v
// //=================
// generate
//     for(i_row = 0 ; i_row < 5; i_row = i_row + 1) begin: gen_weight_v
//         for(i_col = 0 ; i_col < 2 ; i_col = i_col + 1) begin
//             wire [inst_sig_width+inst_exp_width:0] out0, out1;
//             matrix_mul_v #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
//             MATR_MUL_V_0(
//                 _softmax[0][i_row][0], _softmax[0][i_row][1], 
//                 _softmax[0][i_row][2], _softmax[0][i_row][3], _softmax[0][i_row][4],
//                 _V[0][i_col], _V[1][i_col], 
//                 _V[2][i_col], _V[3][i_col], _V[4][i_col],

//                 // Output
//                 out0
//             );

//             matrix_mul_v #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
//             MATR_MUL_V_1(
//                 _softmax[1][i_row][0], _softmax[1][i_row][1], 
//                 _softmax[1][i_row][2], _softmax[1][i_row][3], _softmax[1][i_row][4],
//                 _V[0][i_col + 2], _V[1][i_col + 2], 
//                 _V[2][i_col + 2], _V[3][i_col + 2], _V[4][i_col + 2],

//                 // Output
//                 out1
//             );

//             assign _head_out[i_row][i_col] = out0;
//             assign _head_out[i_row][i_col + 2] = out1;
//         end
//     end
// endgenerate

// //=================
// // OUT
// //=================
// generate
//     for(i_row = 0 ; i_row < IMAG_SIZE; i_row = i_row + 1) begin: gen_out
//         for(i_col = 0 ; i_col < WEIGHT_SIZE ; i_col = i_col + 1) begin
//             wire [inst_sig_width+inst_exp_width:0] out0;
//             matrix_mul #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
//             MATR_MUL_4(
//                 _head_out[i_row][0], _head_out[i_row][1], 
//                 _head_out[i_row][2], _head_out[i_row][3],
//                 _out_weight[i_col][0], _out_weight[i_col][1], 
//                 _out_weight[i_col][2], _out_weight[i_col][3],

//                 // Output
//                 out0
//             );

//             assign _final_res[i_row * 4 + i_col] = out0;
//         end
//     end
// endgenerate

// //======================================
// //      Error Calculation
// //======================================
// generate
//     for(i_input = 0 ; i_input < 20 ; i_input = i_input + 1) begin : gen_err
//         wire [inst_sig_width+inst_exp_width:0] bound;
//         wire [inst_sig_width+inst_exp_width:0] error_diff;
//         wire [inst_sig_width+inst_exp_width:0] error_diff_pos;
//         DW_fp_sub
//         #(inst_sig_width,inst_exp_width,inst_ieee_compliance) 
//             Err_S0 (.a(_final_res[i_input]), .b(out), .z(error_diff), .rnd(3'd0));

//         // gold * _errAllow
//         //DW_fp_mult
//         //#(inst_sig_width,inst_exp_width,inst_ieee_compliance) 
//         //   Err_M0 (.a(_errAllow), .b(_soft_w[i_input]), .z(bound), .rnd(3'd0));

//         // check |gold - ans| > _errAllow * gold
//         DW_fp_cmp
//         #(inst_sig_width,inst_exp_width,inst_ieee_compliance) 
//             Err_C0 (.a(error_diff_pos), .b(_errAllow), .agtb(_isErr[i_input]), .zctr(1'd0));

//         assign error_diff_pos = error_diff[inst_sig_width+inst_exp_width] ? {1'b0, error_diff[inst_sig_width+inst_exp_width-1:0]} : error_diff;
//         assign _errDiff_w = error_diff_pos;
//         assign _errBound_w = bound;
//     end
// endgenerate

// task YOU_PASS_task; begin
//     $display("----------------------------------------------------------------------------------------------------------------------");
//     $display("                                                  Congratulations!                                                    ");
//     $display("                                           You have passed all patterns!                                               ");
//     $display("                                           Your execution cycles = %5d cycles                                          ", total_latency);
//     $display("                                           Your clock period = %.1f ns                                                 ", CYCLE);
//     $display("                                           Total Latency = %.1f ns                                                    ", total_latency * CYCLE);
//     $display("----------------------------------------------------------------------------------------------------------------------");
//     repeat (2) @(negedge clk);
//     $finish;
// end endtask

// endmodule

// module matrix_mul
// #(  parameter inst_sig_width       = 23,
//     parameter inst_exp_width       = 8,
//     parameter inst_ieee_compliance = 0
// )
// (
//     input  [inst_sig_width+inst_exp_width:0] a0, a1, a2, a3,
//     input  [inst_sig_width+inst_exp_width:0] b0, b1, b2, b3,
//     output [inst_sig_width+inst_exp_width:0] out
// );

//     wire [inst_sig_width+inst_exp_width:0] pixel0, pixel1, pixel2, pixel3;

//     // Multiplication
//     DW_fp_mult#(inst_sig_width, inst_exp_width, inst_ieee_compliance)
//         M0 (.a(a0), .b(b0), .rnd(3'd0), .z(pixel0));
    
//     DW_fp_mult#(inst_sig_width, inst_exp_width, inst_ieee_compliance)
//         M1 (.a(a1), .b(b1), .rnd(3'd0), .z(pixel1));
    
//     DW_fp_mult#(inst_sig_width, inst_exp_width, inst_ieee_compliance)
//         M2 (.a(a2), .b(b2), .rnd(3'd0), .z(pixel2));
    
//     DW_fp_mult#(inst_sig_width, inst_exp_width, inst_ieee_compliance)
//         M3 (.a(a3), .b(b3), .rnd(3'd0), .z(pixel3));
    

//     wire [inst_sig_width+inst_exp_width:0] add0, add1;

//     // Addition
//     DW_fp_addsub#(inst_sig_width,inst_exp_width,inst_ieee_compliance)
//         A0 (.a(pixel0), .b(pixel1), .op(1'd0), .rnd(3'd0), .z(add0));

//     DW_fp_addsub#(inst_sig_width,inst_exp_width,inst_ieee_compliance)
//         A1 (.a(add0), .b(pixel2), .op(1'd0), .rnd(3'd0), .z(add1));

//     DW_fp_addsub#(inst_sig_width,inst_exp_width,inst_ieee_compliance)
//         A2 (.a(add1), .b(pixel3), .op(1'd0), .rnd(3'd0), .z(out));

// endmodule

// module score
// #(  parameter inst_sig_width       = 23,
//     parameter inst_exp_width       = 8,
//     parameter inst_ieee_compliance = 0
// )
// (
//     input  [inst_sig_width+inst_exp_width:0] a0, a1,
//     input  [inst_sig_width+inst_exp_width:0] b0, b1,
//     output [inst_sig_width+inst_exp_width:0] out
// );

//     wire [inst_sig_width+inst_exp_width:0] pixel0, pixel1;

//     // Multiplication
//     DW_fp_mult#(inst_sig_width, inst_exp_width, inst_ieee_compliance)
//         M0 (.a(a0), .b(b0), .rnd(3'd0), .z(pixel0));
    
//     DW_fp_mult#(inst_sig_width, inst_exp_width, inst_ieee_compliance)
//         M1 (.a(a1), .b(b1), .rnd(3'd0), .z(pixel1));
    

//     // Addition
//     DW_fp_addsub#(inst_sig_width,inst_exp_width,inst_ieee_compliance)
//         A0 (.a(pixel0), .b(pixel1), .op(1'd0), .rnd(3'd0), .z(out));

// endmodule

// module head_scaling
// #(  parameter inst_sig_width       = 23,
//     parameter inst_exp_width       = 8,
//     parameter inst_ieee_compliance = 0
// )
// (
//     input  [inst_sig_width+inst_exp_width:0] in,
//     output [inst_sig_width+inst_exp_width:0] out
// );

//     parameter sqar_root_2 = 32'b00111111101101010000010011110011;

//     DW_fp_div#(inst_sig_width,inst_exp_width,inst_ieee_compliance, 0)
//             D0 (.a(in), .b(sqar_root_2), .rnd(3'd0), .z(out));

// endmodule

// module matrix_mul_v
// #(  parameter inst_sig_width       = 23,
//     parameter inst_exp_width       = 8,
//     parameter inst_ieee_compliance = 0
// )
// (
//     input  [inst_sig_width+inst_exp_width:0] a0, a1, a2, a3, a4,
//     input  [inst_sig_width+inst_exp_width:0] b0, b1, b2, b3, b4,
//     output [inst_sig_width+inst_exp_width:0] out
// );

//     wire [inst_sig_width+inst_exp_width:0] pixel0, pixel1, pixel2, pixel3, pixel4;

//     // Multiplication
//     DW_fp_mult#(inst_sig_width, inst_exp_width, inst_ieee_compliance)
//         M0 (.a(a0), .b(b0), .rnd(3'd0), .z(pixel0));
    
//     DW_fp_mult#(inst_sig_width, inst_exp_width, inst_ieee_compliance)
//         M1 (.a(a1), .b(b1), .rnd(3'd0), .z(pixel1));
    
//     DW_fp_mult#(inst_sig_width, inst_exp_width, inst_ieee_compliance)
//         M2 (.a(a2), .b(b2), .rnd(3'd0), .z(pixel2));
    
//     DW_fp_mult#(inst_sig_width, inst_exp_width, inst_ieee_compliance)
//         M3 (.a(a3), .b(b3), .rnd(3'd0), .z(pixel3));

//     DW_fp_mult#(inst_sig_width, inst_exp_width, inst_ieee_compliance)
//         M4 (.a(a4), .b(b4), .rnd(3'd0), .z(pixel4));
    

//     wire [inst_sig_width+inst_exp_width:0] add0, add1, add2;

//     // Addition
//     DW_fp_addsub#(inst_sig_width,inst_exp_width,inst_ieee_compliance)
//         A0 (.a(pixel0), .b(pixel1), .op(1'd0), .rnd(3'd0), .z(add0));

//     DW_fp_addsub#(inst_sig_width,inst_exp_width,inst_ieee_compliance)
//         A1 (.a(add0), .b(pixel2), .op(1'd0), .rnd(3'd0), .z(add1));

//     DW_fp_addsub#(inst_sig_width,inst_exp_width,inst_ieee_compliance)
//         A2 (.a(add1), .b(pixel3), .op(1'd0), .rnd(3'd0), .z(add2));
    
//     DW_fp_addsub#(inst_sig_width,inst_exp_width,inst_ieee_compliance)
//         A3 (.a(add2), .b(pixel4), .op(1'd0), .rnd(3'd0), .z(out));

// endmodule