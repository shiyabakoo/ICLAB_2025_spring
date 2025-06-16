`ifdef RTL
    `define CYCLE_TIME 50.0
`endif
`ifdef GATE
    `define CYCLE_TIME 50.0
`endif

module PATTERN #(parameter IP_WIDTH = 7)(
    //Output Port
    IN_Dividend,
	IN_Divisor,
    //Input Port
	OUT_Quotient
);
// ========================================
// Input & Output
// ========================================
output reg [IP_WIDTH*4-1:0] IN_Dividend;
output reg [IP_WIDTH*4-1:0] IN_Divisor;

input [IP_WIDTH*4-1:0] OUT_Quotient;

// ========================================
// Parameter
// ========================================
parameter pat_total = 1000;
integer SEED = 1234;
integer i_pat;


//---------------------------------------------------------------------
//   REG & WIRE DECLARATION
//---------------------------------------------------------------------
reg clk;
reg [IP_WIDTH*4-1:0] golden_quotient, golden_dividend, golden_divisor;
wire [3:0] log_table[0:15];
wire [3:0] decimal_table[0:15];
reg [3:0] dividend   [0:IP_WIDTH-1];
reg [3:0] divisor    [0:IP_WIDTH-1];
reg [3:0] quotient   [0:IP_WIDTH-1];
reg [3:0] temp_dividend  [0:IP_WIDTH-1];
reg [3:0] temp_divisor    [0:IP_WIDTH-1];
reg [IP_WIDTH - 1 : 0] non_zero_divisor;
reg [3:0] x_power;
reg [3:0] quotient_power;
reg [3:0] count;
reg [3:0] dividend_degree, divisor_degree;


//================================================================
// clock
//================================================================
real CYCLE = `CYCLE_TIME;
always #(CYCLE/2.0) clk = ~clk;

//---------------------------------------------------------------------
//  SIMULATION
//---------------------------------------------------------------------


assign log_table[0] = 'd1;
assign log_table[1] = 'd2;
assign log_table[2] = 'd4;
assign log_table[3] = 'd8;
assign log_table[4] = 'd3;
assign log_table[5] = 'd6;
assign log_table[6] = 'd12;
assign log_table[7] = 'd11;
assign log_table[8] = 'd5;
assign log_table[9] = 'd10;
assign log_table[10] = 'd7;
assign log_table[11] = 'd14;
assign log_table[12] = 'd15;
assign log_table[13] = 'd13;
assign log_table[14] = 'd9;
assign log_table[15] = 'd0;


assign decimal_table[0] = 'd15;
assign decimal_table[1] = 'd0;
assign decimal_table[2] = 'd1;
assign decimal_table[3] = 'd4;
assign decimal_table[4] = 'd2;
assign decimal_table[5] = 'd8;
assign decimal_table[6] = 'd5;
assign decimal_table[7] = 'd10;
assign decimal_table[8] = 'd3;
assign decimal_table[9] = 'd14;
assign decimal_table[10] = 'd9;
assign decimal_table[11] = 'd7;
assign decimal_table[12] = 'd6;
assign decimal_table[13] = 'd13;
assign decimal_table[14] = 'd11;
assign decimal_table[15] = 'd12;


initial begin
    clk = 0;
    IN_Dividend = 'dx;
    IN_Divisor = 'dx;

    repeat(2) @(negedge clk);

	for (i_pat = 0; i_pat < pat_total; i_pat = i_pat + 1) begin
        input_task;
        @(negedge clk);
        check_ans_task;
        repeat(1) @(negedge clk);
        $display("\033[1;34mPASS PATTERN \033[1;32mNO.%4d\033[m", i_pat);
    end

	YOU_PASS_task;
end

task input_task; begin
    random_input;

    IN_Dividend = golden_dividend;
    IN_Divisor = golden_divisor;

	cal_data;
end
endtask

task random_input; 
    integer idx;
    reg [3:0] rand_val;
    
begin
    golden_dividend = 0;
    golden_divisor = 0;

    dividend_degree = {$random(SEED)} % (IP_WIDTH + 1);
    divisor_degree = {$random(SEED)} % IP_WIDTH + 1;

    for(idx = 0; idx < IP_WIDTH; idx = idx + 1)begin

        if(idx == (dividend_degree - 1)) begin
            rand_val = {$random(SEED)} % 15; // Avoid zerod dividend
        end 
        else if(idx >= dividend_degree) begin
            rand_val = 'd15;
        end
        else begin
            rand_val = {$random(SEED)} % 16;
        end
        
        golden_dividend = golden_dividend | (rand_val << (idx * 4));
    end

    // non_zero_divisor = {$random(SEED)} % ((2 << IP_WIDTH)-1) + 1;

    for(idx = 0; idx < IP_WIDTH; idx = idx + 1)begin
        // if(non_zero_divisor[idx] == 1) begin
        //     rand_val = {$random(SEED)} % 16; // Avoid zero divisor
        // end else begin
        //     rand_val = 'd15;
        // end
        if(idx == divisor_degree - 1) begin
            rand_val = {$random(SEED)} % 15; // Avoid zero divisor
        end 
        else if(idx >= divisor_degree) begin
            rand_val = 'd15;
        end
        else begin
            rand_val = {$random(SEED)} % 16;
        end

        golden_divisor = golden_divisor | (rand_val << (idx * 4));
    end

end
endtask


task check_ans_task; begin 
	if (OUT_Quotient !== golden_quotient) begin
        $display("************************************************************");  
        $display("                         FAIL                               ");
        $display(" Expected: data = %h", golden_quotient);
        $display(" Received: data = %h", OUT_Quotient);
        $display("************************************************************");
        repeat (2) @(negedge clk);
        $finish;
    end
end endtask

task cal_data; 
    integer idx, idy,i,j,k;
    reg [3:0] prod;
    reg [3:0] temp;
begin
    for (i = 0; i < IP_WIDTH; i++) begin
        dividend[i] = golden_dividend[4*(IP_WIDTH-1-i) +: 4];
        divisor[i]  = golden_divisor[4*(IP_WIDTH-1-i) +: 4];
        quotient[i] = 4'd15;
    end

    for (i = 0; i < IP_WIDTH; i++) begin
        temp_dividend[i] = dividend[i];
        temp_divisor[i]  = divisor[i];
    end

    for (i = 0; i < IP_WIDTH; i++) begin
        if(divisor[i] != 4'd15) begin
            quotient_power = i;
            break;
        end
    end

    count = 0;

    for (i = 0; i <= IP_WIDTH - 1; i++) begin
            if (temp_dividend[i] != 4'd15) begin
                quotient[IP_WIDTH - 1 - (quotient_power - i)] = gf_div(temp_dividend[i], divisor[quotient_power]);

                x_power = (quotient_power - i);

                for (k = 0; k < IP_WIDTH; k++) begin
                    temp_divisor[k]  = divisor[k];
                end

                for(idx = 0; idx < x_power; idx = idx + 1) begin
                    for(k = 0; k < IP_WIDTH; k++) begin
                        if(k == (IP_WIDTH - 1)) begin
                            temp_divisor[k] = 4'd15;
                        end
                        else begin
                            temp_divisor[k] = temp_divisor[k + 1];
                        end
                    end
                end

                // 減去 q(x) * divisor
                for (k = 0; k < IP_WIDTH; k++) begin
                    prod = gf_mul(quotient[IP_WIDTH - 1 - (quotient_power - i)], temp_divisor[k]);
                    temp = gf_add_sub(temp_dividend[k], prod);
                    temp_dividend[k] = temp;
                    // $display(" prod = %h, temp_dividend = %h, Q = %h, divisor = %h", prod, temp_dividend[k], quotient[IP_WIDTH - 1 - (quotient_power - i)], divisor[k]);
                end
                count = count + 1;
            end
            if(count > quotient_power) begin
                break;
            end
    end

    golden_quotient = 0;

    for(i = 0; i < IP_WIDTH; i = i + 1) begin
        golden_quotient = golden_quotient | (quotient[IP_WIDTH - 1 -i] << (i * 4));
    end

end endtask

function automatic [3:0] gf_add_sub;
    input [3:0] a;
    input [3:0] b;
    reg [3:0] temp;
    begin
        temp = log_table[a] ^ log_table[b];
        gf_add_sub =decimal_table[temp];
    end
endfunction


function automatic [3:0] gf_mul;
    input [3:0] a;
    input [3:0] b;
    reg [4:0] sum;
    begin
        if (a == 4'd15 || b == 4'd15)
            gf_mul = 4'd15;  // 0 × anything = 0
        else begin
            sum = (a + b);
            gf_mul = (sum >= 15) ? sum - 15 : sum;
        end
    end
endfunction

function automatic [3:0] gf_div;
    input [3:0] a;
    input [3:0] b;
    reg signed [5:0] diff;
    begin
        if (a == 4'd15)
            gf_div = 4'd15;
        else if (b == 4'd15)
            gf_div = 4'd15; // avoid divide by zero
        else begin
            diff = (a - b);
            gf_div = (diff < 0) ? diff + 'd15 : diff;
        end
    end
endfunction



task YOU_PASS_task; begin
    $display("----------------------------------------------------------------------------------------------------------------------");
    $display("                                                  \033[0;32mCongratulations!\033[m                                                     ");
    $display("                                           You have passed all patterns!                                               ");
    $display("                                           Your clock period = %.1f ns                                                 ", CYCLE);
    $display("----------------------------------------------------------------------------------------------------------------------");
    repeat (2) @(negedge clk);
    $finish;
end endtask


endmodule