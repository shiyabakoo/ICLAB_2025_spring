module MAZE( 
// area = 116134.606079  latency = 4812 -> 559015787.5
    // input
    input clk,
    input rst_n,
	input in_valid,
	input [1:0] in,

    // output
    output reg out_valid,
    output reg [1:0] out
);
// --------------------------------------------------------------
// Reg & Wire
// --------------------------------------------------------------
// reg [1:0] maze_in [0:288];
reg [1:0] maze [0:18][0:18];
reg [4:0] row;
reg [4:0] col;
reg [4:0] location_x;
reg [4:0] location_y;
reg       start_move;
reg       get_sword; 
reg       finish;
reg       left_no_wall;
reg       right_no_wall;
reg       up_no_wall;      
reg       down_no_wall;
reg       left_empty;
reg       right_empty;
reg       up_empty; 
reg       down_empty;
reg [1:0] previous_move;
reg [1:0] move;
// reg [8:0] location; 
// --------------------------------------------------------------
// Design
// --------------------------------------------------------------

// out signal
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        out <= 2'b00;
    else
        out <= (start_move)? move : 2'b00;
end
// out_valid
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        out_valid <= 1'b0;
    else
        out_valid <= start_move;
end
// row count for input
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        col <= 0;
    else if (in_valid)
        col <= (col == 16)? 0 : col + 1;
    else
        col <= col;
end
// col count for input
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        row <= 0;
    else if (in_valid && (col == 16))
        row <= (row == 16)? 0 : row + 1;
    else 
        row <= row;
end
// finish
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) 
        finish <= 1'b0;
    // else if (location == 340 && out_valid == 1)
    //     finish <= 1'b1;
    else if (out_valid && !start_move)
        finish <= 1'b1;
    else 
        finish <= 0;
end
// --------------------------------------------------------------
// BUILD MAZE AND FILL DEATH END
// --------------------------------------------------------------
integer k;

genvar i, j;
generate
    for(j = 2; j < 17; j = j + 1 )begin
        for(i = 2; i < 17; i = i + 1) begin
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n)
                    maze[i][j] <= 2'b00;
                else if (finish)
                    maze[i][j] <= 2'b00;
                else if (in_valid && ((row == (i - 1)) && (col == (j - 1))))
                    maze[i][j] <= in;
                else if (((maze[i + 1][j] == 2'b01) && (maze[i][j - 1] == 2'b01) && (maze[i][j + 1] == 2'b01)) ||
                         ((maze[i + 1][j] == 2'b01) && (maze[i - 1][j] == 2'b01) && (maze[i][j + 1] == 2'b01)) ||
                         ((maze[i][j - 1] == 2'b01) && (maze[i - 1][j] == 2'b01) && (maze[i][j + 1] == 2'b01)) ||
                         ((maze[i + 1][j] == 2'b01) && (maze[i - 1][j] == 2'b01) && (maze[i][j - 1] == 2'b01))) begin
                      maze[i][j] <= (maze[i][j] != 2'b10)? 2'b01 : 2'b10;
                         end
                else
                    maze[i][j] <= maze[i][j];
            end
        end
    end
endgenerate 

// --------------------------------------------------------------
// BUILD MAZE AND FILL DEATH END(SPECIAL CASE)
// --------------------------------------------------------------
// (1,1)
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        maze[1][1] <= 2'b00;
    else if (finish)
        maze[1][1] <= 2'b00;
    else if (in_valid && ((row == 0) && (col == 0)))
        maze[1][1] <= in;
    else
        maze[1][1] <= maze[1][1];
end
// (1,17)
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        maze[1][17] <= 2'b00;
    else if (finish)
        maze[1][17] <= 2'b00;
    else if (in_valid && ((row == 0) && (col == 16)))
        maze[1][17] <= in;
    else if ((maze[1][16] == 2'd1) || (maze[2][17] == 2'd1))
        maze[1][17] <= (maze[1][17] != 2'b10)? 2'b01 : 2'b10; 
    else
        maze[1][17] <= maze[1][17];
end
// (17,1)
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        maze[17][1] <= 2'b00;
    else if (finish)
        maze[17][1] <= 2'b00;
    else if (in_valid && ((row == 16) && (col == 0)))
        maze[17][1] <= in;
    else if ((maze[16][1] == 2'd1) || (maze[17][2] == 2'd1))
        maze[17][1] <= (maze[17][1] != 2'd2)? 2'd1 : 2'd2; 
    else
        maze[17][1] <= maze[17][1];
end
// (17,17)
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        maze[17][17] <= 2'b00;
    else if (finish)
        maze[17][17] <= 2'b00;
    else if (in_valid && ((row == 16) && (col == 16)))
        maze[17][17] <= in;
    else
        maze[17][17] <= maze[17][17];
end
// (2,1)
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        maze[2][1] <= 2'b00;
    else if (finish)
        maze[2][1] <= 2'b00;
    else if (in_valid && ((row == 1) && (col == 0)))
        maze[2][1] <= in;
    else if ((maze[3][1] == 2'd1) && (maze[2][2] == 2'd1))
        maze[2][1] <= (maze[2][1] != 2'd2)? 2'd1 : 2'd2; 
    else
        maze[2][1] <= maze[2][1];
end
// (1,2)
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        maze[1][2] <= 2'b00;
    else if (finish)
        maze[1][2] <= 2'b00;
    else if (in_valid && ((row == 0) && (col == 1)))
        maze[1][2] <= in;
    else if ((maze[1][3] == 2'd1) && (maze[2][2] == 2'd1))
        maze[1][2] <= (maze[1][2] != 2'd2)? 2'd1 : 2'd2; 
    else
        maze[1][2] <= maze[1][2];
end
// (16,17)
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        maze[16][17] <= 2'b00;
    else if (finish)
        maze[16][17] <= 2'b00;
    else if (in_valid && ((row == 15) && (col == 16)))
        maze[16][17] <= in;
    else
        maze[16][17] <= maze[16][17];
end  
// (17,16)
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        maze[17][16] <= 2'b00;
    else if (finish)
        maze[17][16] <= 2'b00;
    else if (in_valid && ((row == 16) && (col == 15)))
        maze[17][16] <= in;
    else
        maze[17][16] <= maze[17][16];
end
// first row
generate
    for (i = 3; i < 17; i = i + 1) begin
        always @(posedge clk or negedge rst_n) begin
                if (!rst_n)
                    maze[1][i] <= 2'b00;
                else if (finish)
                    maze[1][i] <= 2'b00;
                else if (in_valid && ((row == 0) && (col == (i - 1))))
                    maze[1][i] <= in;
                else if ( ((maze[2][i] == 2'b01) && (maze[1][i - 1] == 2'b01))   ||
                          ((maze[2][i] == 2'b01) && (maze[1][i + 1] == 2'b01))   ||
                          ((maze[1][i - 1] == 2'b01) && (maze[1][i + 1] == 2'b01))  ) 

                    maze[1][i] <= (maze[1][i] != 2'd2)? 2'd1 : 2'd2;
                else
                    maze[1][i] <= maze[1][i];
            end
    end
endgenerate
// first column
generate
    for (i = 3; i < 17; i = i + 1) begin
        always @(posedge clk or negedge rst_n) begin
                if (!rst_n)
                    maze[i][1] <= 2'b00;
                else if (finish)
                    maze[i][1] <= 2'b00;
                else if (in_valid && ((row == (i - 1)) && (col == 0)))
                    maze[i][1] <= in;
                else if ( ((maze[i][2] == 2'b01) && (maze[i + 1][1] == 2'b01) )   ||
                          ((maze[i][2] == 2'b01) && (maze[i - 1][1] == 2'b01) )   ||
                          ((maze[i - 1][1] == 2'b01) && (maze[i + 1][1] == 2'b01)) ) 

                    maze[i][1] <= (maze[i][1] != 2'd2)? 2'd1 : 2'd2;
                else
                    maze[i][1] <= maze[i][1];
            end
    end
endgenerate

// last column
generate
    for (i = 2; i < 16; i = i + 1) begin
        always @(posedge clk or negedge rst_n) begin
                if (!rst_n)
                    maze[i][17] <= 2'b00;
                else if (finish)
                    maze[i][17] <= 2'b00;
                else if (in_valid && ((row == (i - 1)) && (col == 16)))
                    maze[i][17] <= in;
                else if ( ((maze[i][16] == 2'b01) && (maze[i + 1][17] == 2'b01) )   ||
                          ((maze[i][16] == 2'b01) && (maze[i - 1][17] == 2'b01) )   ||
                          ((maze[i - 1][17] == 2'b01) && (maze[i + 1][17] == 2'b01))  ) 

                    maze[i][17] <= (maze[i][17] != 2'd2)? 2'd1 : 2'd2;
                else
                    maze[i][17] <= maze[i][17];
            end
    end
endgenerate

// last row
generate
    for (i = 2; i < 16; i = i + 1) begin
        always @(posedge clk or negedge rst_n) begin
                if (!rst_n)
                    maze[17][i] <= 2'b00;
                else if (finish)
                    maze[17][i] <= 2'b00;
                else if (in_valid && ((row == 16) && (col == (i-1))))
                    maze[17][i] <= in;
                else if ( (((maze[16][i] == 2'b01) && (maze[17][i - 1] == 2'b01) )      ||
                           ((maze[16][i] == 2'b01) && (maze[17][i + 1] == 2'b01) )      ||
                           ((maze[17][i - 1] == 2'b01) && (maze[17][i + 1] == 2'b01))) && start_move) 
                    maze[17][i] <= (maze[17][i] != 2'd2)? 2'd1 : 2'd2;
                else
                    maze[17][i] <= maze[17][i]; 
            end
    end  
endgenerate
// assign boundary to 2'b01
generate
    for (i = 1; i < 18; i = i + 1) begin
        assign maze[i][0] = 2'b01;
        assign maze[i][18] = 2'b01;
        assign maze[0][i] = 2'b01;
        assign maze[18][i] = 2'b01;
    end
endgenerate
assign maze[0][0] = 2'b01;
assign maze[0][18] = 2'b01;
assign maze[18][0] = 2'b01;
assign maze[18][18] = 2'b01;

// --------------------------------------------------------------
// START MOVE(RIGHT HAND RULE)
// --------------------------------------------------------------
// find sword
always @(posedge clk  or negedge rst_n) begin
    if (!rst_n)
        get_sword <= 0;
    else if (finish)
        get_sword <= 0;
    else if ((maze[location_x][location_y + 1]== 2'd2 && move == 2'd0)  ||
             (maze[location_x + 1][location_y] == 2'd2 && move == 2'd1) ||
             (maze[location_x][location_y - 1]== 2'd2 && move == 2'd2)  ||
             (maze[location_x - 1][location_y] == 2'd2 && move == 2'd3) ||
              maze[location_x][location_y] == 2'd2)
        get_sword <= 1;
    else 
        get_sword <= get_sword;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        start_move <= 1'b0;
    else if (col == 16 && row == 16)
        start_move <= 1'b1;
    else if (((location_x == 16) && (location_y == 17)) || ((location_x == 17) && (location_y == 16)))
        start_move <= 1'b0;
    else
        start_move <= start_move;
end
// current location of x
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        location_x <= 'd1;
    else if (finish)
        location_x <= 'd1;
    else if (start_move) begin
        case (move)
            2'd1: location_x <= location_x + 1;
            2'd3: location_x <= location_x - 1;
            default: location_x <= location_x;
        endcase
    end
    else location_x <= location_x;
end
// current location of y
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        location_y <= 'd1;
    else if (finish)
        location_y <= 'd1;
    else if (start_move) begin
        case (move)
            2'd0: location_y <= location_y + 1;
            2'd2: location_y <= location_y - 1;
            default: location_y <= location_y;
        endcase
    end
    else location_y <= location_y;
end
// right hand rule
assign left_no_wall = (maze[location_x][location_y - 1] != 2'd1);
assign right_no_wall = (maze[location_x][location_y + 1] != 2'd1);
assign up_no_wall = (maze[location_x - 1][location_y] != 2'd1);
assign down_no_wall = (maze[location_x + 1][location_y] != 2'd1);

assign left_empty = (maze[location_x][location_y - 1][0] != 1'b1);
assign right_empty = (maze[location_x][location_y + 1][0] != 1'b1);
assign up_empty = (maze[location_x - 1][location_y][0] != 1'b1);
assign down_empty = (maze[location_x + 1][location_y][0] != 1'b1);

always @(*) begin
    if (get_sword) begin
        case (previous_move)
        2'd0: if (down_no_wall)
                 move = 2'd1;
              else if (right_no_wall)
                move = 2'd0;
              else if (up_no_wall)
                move = 2'd3;
              else if (left_no_wall)
                move = 2'd2;
            else
                move = 2'd0;
        2'd1: if (left_no_wall)
                 move = 2'd2;
              else if (down_no_wall)
                move = 2'd1;
              else if (right_no_wall)
                move = 2'd0;
              else if (up_no_wall)
                move = 2'd3;
              else
                move = 2'd0;
        2'd2: if (up_no_wall)
                 move = 2'd3;
              else if (left_no_wall)
                move = 2'd2;
              else if (down_no_wall)
                move = 2'd1;
              else if (right_no_wall)
                move = 2'd0;
              else
                move = 2'd0;
        2'd3: if (right_no_wall)
                 move = 2'd0;
              else if (up_no_wall)
                move = 2'd3;
              else if (left_no_wall)
                move = 2'd2;
              else if (down_no_wall)
                move = 2'd1;
              else
                move = 2'd0;
        default: move = 2'd0;
        endcase
    end
    else begin
        case (previous_move)
        2'd0: if (down_empty)
                 move = 2'd1;
              else if (right_empty)
                move = 2'd0;
              else if (up_empty)
                move = 2'd3;
              else if (left_empty)
                move = 2'd2;
              else
                move = 2'd0;
        2'd1: if (left_empty)
                 move = 2'd2;
              else if (down_empty)
                move = 2'd1;
              else if (right_empty)
                move = 2'd0;
              else if (up_empty)
                move = 2'd3;
              else
                move = 2'd0;
        2'd2: if (up_empty)
                 move = 2'd3; 
              else if (left_empty)
                move = 2'd2;
              else if (down_empty)
                move = 2'd1;
              else if (right_empty)
                move = 2'd0;
              else
                move = 2'd0;
        2'd3: if (right_empty)
                 move = 2'd0;
              else if (up_empty)
                move = 2'd3;
              else if (left_empty)
                move = 2'd2;
              else if (down_empty)
                move = 2'd1;
              else
                move = 2'd0;
        default: move = 2'd0;
        endcase
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        previous_move <= 2'd0;
    else if (start_move)
        previous_move <= move;
    else
        previous_move <= previous_move;
end

endmodule 
