`ifdef RTL
    `define CYCLE_TIME 20.0
`endif
`ifdef GATE
    `define CYCLE_TIME 20.0
`endif
`ifdef POST
    `define CYCLE_TIME 20.0
`endif

module PATTERN(
    output reg clk,             
    output reg rst_n,             
    output reg in_valid, in_valid2,
    output reg [11:0] in_data,     
    input out_valid, out_sad  
);



//======================================
//      PARAMETERS & VARIABLES
//======================================
//vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
// Can be modified by user
integer   TOTAL_PATNUM = 5;
integer   SIMPLE_PATNUM = 0;
integer   SEED = 54871;
parameter DEBUG = 1; 
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
integer   SETNUM = 64;
parameter CYCLE = `CYCLE_TIME;
parameter DELAY = 1000;
parameter OUTBIT = 28;
integer   OUTNUM = -1;

// PATTERN CONTROL
integer set;
integer pat;
integer exe_lat;
integer out_lat;
integer tot_lat;


// file_out CONTROL
integer file_out;

// String control
// Should use %0s
reg[9*8:1]  reset_color       = "\033[1;0m";
reg[10*8:1] txt_black_prefix  = "\033[1;30m";
reg[10*8:1] txt_red_prefix    = "\033[1;31m";
reg[10*8:1] txt_green_prefix  = "\033[1;32m";
reg[10*8:1] txt_yellow_prefix = "\033[1;33m";
reg[10*8:1] txt_blue_prefix   = "\033[1;34m";

reg[10*8:1] bkg_black_prefix  = "\033[40;1m";
reg[10*8:1] bkg_red_prefix    = "\033[41;1m";
reg[10*8:1] bkg_green_prefix  = "\033[42;1m";
reg[10*8:1] bkg_yellow_prefix = "\033[43;1m";
reg[10*8:1] bkg_blue_prefix   = "\033[44;1m";
reg[10*8:1] bkg_white_prefix  = "\033[47;1m";



//extreme value
real REAL_MAX = 1.7976931348623157e+308;
real REAL_MIN = 2.2250738585072014e-308;

//======================================
//      DATA MODEL
//======================================
// Image
parameter NUM_OF_POINT = 2;
parameter SIZE_OF_IMAGE = 128;
// Motion vector
parameter NUM_OF_MOTION = 2; // L0, L1
parameter SIZE_OF_MOTION = 8;
parameter NUM_OF_SEARCH = 9;
parameter SIZE_OF_SEARCH = 9;
// Input
real _image[NUM_OF_MOTION-1:0][SIZE_OF_IMAGE-1:0][SIZE_OF_IMAGE-1:0];
reg [11:0] _motion[NUM_OF_POINT-1:0][NUM_OF_MOTION-1:0][2]; //motionX, motionY


// Intermediate output
real _BI[NUM_OF_POINT-1:0][NUM_OF_SEARCH-1:0][NUM_OF_MOTION-1:0][SIZE_OF_MOTION-1:0][SIZE_OF_MOTION-1:0];
real _SAD[NUM_OF_POINT-1:0][NUM_OF_SEARCH-1:0];


// Design output
parameter SIZE_OF_POINT = 4;    //search point
integer _smallest_SAD_point[NUM_OF_POINT-1:0];
real _smallest_SAD[NUM_OF_POINT-1:0];
reg[OUTBIT-1:0] _your[NUM_OF_POINT-1:0];
integer _your_point[NUM_OF_POINT-1:0];
real _your_sad[NUM_OF_POINT-1:0];


//
// Clear
//
task clear_input;
    integer _mo;
    integer _row;
    integer _col;
begin
    for(_mo=0 ; _mo<NUM_OF_MOTION ; _mo=_mo+1) begin
        for(_row=0 ; _row<SIZE_OF_IMAGE ; _row=_row+1) begin
            for(_col=0 ; _col<SIZE_OF_IMAGE ; _col=_col+1) begin
                _image[_mo][_row][_col] = 'x;
            end
        end
    end
end endtask

task clear_intermediate;
    integer _pointIdx;
    integer _searchIdx;
    integer _motionIdx;
    integer _row;
    integer _col;
begin
    for(_pointIdx=0; _pointIdx<NUM_OF_POINT; _pointIdx++) begin
        for(_searchIdx=0; _searchIdx<NUM_OF_SEARCH; _searchIdx++) begin
            for(_motionIdx=0; _motionIdx<NUM_OF_MOTION; _motionIdx++) begin
                for(_row=0 ; _row<SIZE_OF_IMAGE ; _row=_row+1) begin
                    for(_col=0 ; _col<SIZE_OF_IMAGE ; _col=_col+1) begin
                        _BI[_pointIdx][_searchIdx][_motionIdx][_row][_col] = 'x;
                    end
                end
            end
        end
    end

    for(_pointIdx=0; _pointIdx<NUM_OF_POINT; _pointIdx++) begin
        for(_searchIdx=0; _searchIdx<NUM_OF_SEARCH; _searchIdx++) begin
            _SAD[_pointIdx][_searchIdx] = 'x;
        end
    end

    for(_searchIdx=0; _searchIdx<NUM_OF_SEARCH; _searchIdx++) begin
        _smallest_SAD[_pointIdx] = 'x;
        _smallest_SAD_point[_pointIdx] = 'x;
    end
end endtask

task clear_your_answer;
    integer _pointIdx;
begin
    for(_pointIdx=0 ; _pointIdx<NUM_OF_POINT ; _pointIdx=_pointIdx+1) begin
        _your[_pointIdx] = 'x;
        _your_point[_pointIdx] = 'x;
        _your_sad[_pointIdx] = 'x;
    end
end endtask


//
// Generate input
//
task randomize_figure;
    integer _mo;
    integer _row;
    integer _col;
begin
    for(_mo=0 ; _mo<NUM_OF_MOTION ; _mo=_mo+1) begin
        for(_row=0 ; _row<SIZE_OF_IMAGE ; _row=_row+1) begin
            for(_col=0 ; _col<SIZE_OF_IMAGE ; _col=_col+1) begin
                _image[_mo][_row][_col] = (pat<SIMPLE_PATNUM)
                    ? {$random(SEED)} % 10
                    : {$random(SEED)} % 256;
            end
        end
    end
end endtask

task randomize_MV;
    integer _pointIdx;
    integer _motionIdx;
    integer _coordinateIdx;
    integer temp;
begin
    for(_pointIdx=0 ; _pointIdx<NUM_OF_POINT ; _pointIdx=_pointIdx+1)begin
        for(_motionIdx=0 ; _motionIdx<NUM_OF_MOTION ; _motionIdx=_motionIdx+1)begin
            for(_coordinateIdx=0 ; _coordinateIdx<2 ; _coordinateIdx=_coordinateIdx+1)begin
                temp = _motion[0][_motionIdx][_coordinateIdx][11:4] + ({$random(SEED)}%11-5);
                temp = (temp < 0) ? 0 : temp;  
                _motion[_pointIdx][_motionIdx][_coordinateIdx][11:4] = (_pointIdx == 1) ? temp : {$random(SEED)}%118; //{} can not be ignored
                _motion[_pointIdx][_motionIdx][_coordinateIdx][3:0] = $random(SEED);
            end
        end
    end
end endtask

//
// Operation
//
parameter FRACTION_SIZE_IN = 4;
parameter FRACTION_SIZE_OUT = 8;
fraction #(.FRACTION_SIZE(FRACTION_SIZE_IN)) inFraction();
fraction #(.FRACTION_SIZE(FRACTION_SIZE_OUT)) outFraction();


//
// Dump
//
reg[4*8:1] _lineSize4  = "____";
reg[4*8:1] _spaceSize4 = "    ";
reg[9*8:1] _lineSize9  = "_________";
reg[9*8:1] _spaceSize9 = "         ";
parameter DUMP_OPT_PIXEL = 4;
parameter DUMP_SIZE_PIXEL = 14;
dumper #(.DUMP_ELEMENT_SIZE(DUMP_OPT_PIXEL)) optDumper();
dumper #(.DUMP_ELEMENT_SIZE(DUMP_SIZE_PIXEL)) pixelDumper();


task clear_file; begin
    file_out = $fopen("input.txt", "w");
    $fclose(file_out);
    file_out = $fopen("output.txt", "w");
    $fclose(file_out);
end endtask


task dump_input;
    integer _motionIdx;
    integer _row;
    integer _col;
begin
    file_out = $fopen("input.txt", "w");

    optDumper.addSeperator(file_out, 2);
    optDumper.addCell(file_out, "Pat No.", "s", 1);
    optDumper.addCell(file_out,    pat, "d", 0);
    optDumper.addLine(file_out);

    optDumper.addSeperator(file_out, 2);
    optDumper.addLine(file_out);

    // Image
    for(_motionIdx=0 ; _motionIdx<NUM_OF_MOTION ; _motionIdx=_motionIdx+1) begin
        pixelDumper.addSeperator(file_out, SIZE_OF_IMAGE+1);
        case(_motionIdx)
            'd0:pixelDumper.addCell(file_out, "L0", "s", 1);
            'd1:pixelDumper.addCell(file_out, "L1", "s", 1);
        endcase
        // Column index
        for(_col=0 ; _col<SIZE_OF_IMAGE ; _col=_col+1) begin
            pixelDumper.addCell(file_out, _col, "d", 0);
        end
        optDumper.addLine(file_out);
        pixelDumper.addSeperator(file_out, SIZE_OF_IMAGE+1);
        // Row index & pixel
        for(_row=0 ; _row<SIZE_OF_IMAGE ; _row=_row+1) begin
            // Row index
            pixelDumper.addCell(file_out, _row, "d", 1);
            // Pixel
            for(_col=0 ; _col<SIZE_OF_IMAGE ; _col=_col+1) begin
                pixelDumper.addCell(file_out, _image[_motionIdx][_row][_col], "d", 0);
            end
            optDumper.addLine(file_out);
        end
        pixelDumper.addSeperator(file_out, SIZE_OF_IMAGE+1);
        optDumper.addLine(file_out);
    end
    $fwrite(file_out, "\n");


    $fclose(file_out);
end endtask


task dump_output;
    integer _pointIdx;
    integer _motionIdx;
    integer _searchIdx;
    integer _motionX;
    integer _motionY;
    integer _offsetX0, _offsetY0;
    integer _offsetX1, _offsetY1;
    integer _row;
    integer _col;
    real temp;
begin
    file_out = $fopen("output.txt", "w");
    

    for(_pointIdx=0; _pointIdx<NUM_OF_POINT; _pointIdx=_pointIdx+1) begin
        _offsetX0 = 0;
        _offsetY0 = 0;
        _offsetX1 = 2;
        _offsetY1 = 2;
        $fwrite(file_out, "[==============]\n");
        $fwrite(file_out, "[    Point %1d   ]\n", _pointIdx+1);
        $fwrite(file_out, "[==============]\n\n");
        $fwrite(file_out, "\n");

        for(_searchIdx=0; _searchIdx<NUM_OF_SEARCH; _searchIdx=_searchIdx+1) begin
            $fwrite(file_out, "[======================================]\n");
            $fwrite(file_out, "[            Search Point %1d:           ]\n", _searchIdx);
            $fwrite(file_out, "[======================================]\n\n");

            for(_motionIdx=0; _motionIdx<NUM_OF_MOTION; _motionIdx=_motionIdx+1) begin

                _motionX = _motion[_pointIdx][_motionIdx][0][11:4] + (_motionIdx == 0 ? _offsetX0 : _offsetX1);
                _motionY = _motion[_pointIdx][_motionIdx][1][11:4] + (_motionIdx == 0 ? _offsetY0 : _offsetY1);

                pixelDumper.addSeperator(file_out, SIZE_OF_SEARCH+1);
                case(_motionIdx)
                    'd0:pixelDumper.addCell(file_out, "L0", "s", 1);
                    'd1:pixelDumper.addCell(file_out, "L1", "s", 1);
                endcase
                // Column index
                for(_col=_motionX ; _col<_motionX+SIZE_OF_SEARCH ; _col=_col+1) begin
                    pixelDumper.addCell(file_out, _col, "d", 0);
                end
                optDumper.addLine(file_out);
                pixelDumper.addSeperator(file_out, SIZE_OF_SEARCH+1);
                // Row index & pixel
                for(_row=_motionY ; _row<_motionY+SIZE_OF_SEARCH ; _row=_row+1) begin
                    // Row index
                    pixelDumper.addCell(file_out, _row, "d", 1);
                    // Pixel
                    for(_col=_motionX ; _col<_motionX+SIZE_OF_SEARCH ; _col=_col+1) begin
                        pixelDumper.addCell(file_out, _image[_motionIdx][_row][_col], "d", 0);
                    end
                    optDumper.addLine(file_out);
                end
                pixelDumper.addSeperator(file_out, SIZE_OF_SEARCH+1);
                optDumper.addLine(file_out);


                $fwrite(file_out, "\n\n[    Fraction1: %f    ; Fraction2: %f    ]\n\n", inFraction.Fractioner(_motion[_pointIdx][_motionIdx][0][3:0]), inFraction.Fractioner(_motion[_pointIdx][_motionIdx][1][3:0]));


                pixelDumper.addSeperator(file_out, SIZE_OF_SEARCH);
                case(_motionIdx)
                    'd0:pixelDumper.addCell(file_out, "BI_L0", "s", 1);
                    'd1:pixelDumper.addCell(file_out, "BI_L1", "s", 1);
                endcase
                // Column index
                for(_col=0 ; _col<SIZE_OF_MOTION ; _col=_col+1) begin
                    pixelDumper.addCell(file_out, _col, "d", 0);
                end
                optDumper.addLine(file_out);
                pixelDumper.addSeperator(file_out, SIZE_OF_MOTION+1);
                // Row index & pixel
                for(_row=0 ; _row<SIZE_OF_MOTION ; _row=_row+1) begin
                    // Row index
                    pixelDumper.addCell(file_out, _row, "d", 1);
                    // Pixel
                    for(_col=0 ; _col<SIZE_OF_MOTION ; _col=_col+1) begin
                        pixelDumper.addCell(file_out, _BI[_pointIdx][_searchIdx][_motionIdx][_row][_col], "f", 0);
                    end
                    optDumper.addLine(file_out);
                end
                pixelDumper.addSeperator(file_out, SIZE_OF_MOTION+1);
                optDumper.addLine(file_out);
                optDumper.addLine(file_out);
                optDumper.addLine(file_out);
                optDumper.addLine(file_out);
            end

            if(_offsetY0 == 2) _offsetX0 = _offsetX0 + 1;
            if(_offsetY0 == 2) _offsetY0 = 0; else _offsetY0 = _offsetY0 + 1;
            if(_offsetY1 == 0) _offsetX1 = _offsetX1 - 1;
            if(_offsetY1 == 0) _offsetY1 = 2; else _offsetY1 = _offsetY1 - 1;

            
            $fwrite(file_out, "[=========================]\n");
            $fwrite(file_out, "[           SAD           ]\n");
            $fwrite(file_out, "[=========================]\n\n");
            pixelDumper.addSeperator(file_out, SIZE_OF_SEARCH);
            pixelDumper.addCell(file_out, "SAD", "s", 1);
            // Column index
            for(_col=0 ; _col<SIZE_OF_MOTION ; _col=_col+1) begin
                pixelDumper.addCell(file_out, _col, "d", 0);
            end
            optDumper.addLine(file_out);
            pixelDumper.addSeperator(file_out, SIZE_OF_MOTION+1);
            // Row index & pixel
            for(_row=0 ; _row<SIZE_OF_MOTION ; _row=_row+1) begin
                // Row index
                pixelDumper.addCell(file_out, _row, "d", 1);
                // Pixel
                for(_col=0 ; _col<SIZE_OF_MOTION ; _col=_col+1) begin
                    temp = (_BI[_pointIdx][_searchIdx][0][_row][_col]>_BI[_pointIdx][_searchIdx][1][_row][_col])?(_BI[_pointIdx][_searchIdx][0][_row][_col]-_BI[_pointIdx][_searchIdx][1][_row][_col]):(_BI[_pointIdx][_searchIdx][1][_row][_col]-_BI[_pointIdx][_searchIdx][0][_row][_col]);
                    pixelDumper.addCell(file_out, temp, "f", 0);
                end
                optDumper.addLine(file_out);
            end
            pixelDumper.addSeperator(file_out, SIZE_OF_MOTION+1);
            $fwrite(file_out, "\n[           SAD = %.10f           ]\n", _SAD[_pointIdx][_searchIdx]);
            optDumper.addLine(file_out);
            optDumper.addLine(file_out);
            optDumper.addLine(file_out);
            optDumper.addLine(file_out);
            optDumper.addLine(file_out);
            optDumper.addLine(file_out);
        end
        $fwrite(file_out, "[========================================]\n");
        $fwrite(file_out, "[       Smallest point = %0d               ]\n",_smallest_SAD_point[_pointIdx]);
        $fwrite(file_out, "[       Smallest SAD = %.10f   ]\n",_smallest_SAD[_pointIdx]);
        $fwrite(file_out, "[========================================]\n\n\n\n");

        $fwrite(file_out, "[========================================]\n");
        $fwrite(file_out, "[       Your point = %0d                   ]\n",_your_point[_pointIdx]);
        $fwrite(file_out, "[       Your SAD = %.10f          ]\n",_your_sad[_pointIdx]);
        $fwrite(file_out, "[========================================]\n\n\n\n\n\n\n\n\n\n\n\n");
    end

    $fclose(file_out);
end endtask



//======================================
//              MAIN
//======================================
initial exe_task;

//======================================
//              CLOCK
//======================================
initial clk = 1'b0;
always #(CYCLE/2.0) clk = ~clk;

//======================================
//              TASKS
//======================================
task exe_task; begin
    reset_task;
    for(pat=0 ; pat<TOTAL_PATNUM ; pat=pat+1) begin
        reset_figure_task;
        input_figure_task;
        for(set=0 ; set<SETNUM ; set=set+1) begin
            reset_intermediate_task;
            input_MV_task;
            cal_task;
            wait_task;
            check_task;
            // Print Pass Info and accumulate the total latency
            $display("%0sPASS PATTERN NO.%4d / Set #%1d %0sCycles: %3d%0s",txt_blue_prefix, pat, set, txt_green_prefix, exe_lat, reset_color);
        end
    end
    pass_task;
end endtask

//do not overlap out_valid with in_valid
always @(*) begin
    if (in_valid && out_valid) begin
		fail_task;
        $display("************************************************************");  
        $display("*                         FAIL!                            *");    
        $display("*    The out_valid signal cannot overlap with in_valid.    *");
        $display("************************************************************");
		repeat(2) #(CYCLE);
        $finish;            
    end
    if (in_valid2 && out_valid) begin
		fail_task;
        $display("************************************************************");  
        $display("*                         FAIL!                            *");    
        $display("*    The out_valid signal cannot overlap with in_valid2.   *");
        $display("************************************************************");
		repeat(2) #(CYCLE);
        $finish;            
    end 
end

task reset_task; begin
    force clk = 0;
    rst_n = 1;
    in_valid = 0;
    in_valid2 = 0;
    in_data = 'x;

    tot_lat = 0;

    #(CYCLE/2.0) rst_n = 0;
    #(CYCLE/2.0) rst_n = 1;
    if(out_valid !== 0 || out_sad !== 0) begin
        $display("[ERROR] [Reset] Output signal should be 0 at %-12d ps  ", $time*1000);
        repeat(5) #(CYCLE);
        $finish;
    end
    #(CYCLE/2.0) rst_n = 1;
    #(CYCLE/2.0) release clk;
end endtask

task reset_figure_task; begin
    clear_input;
end endtask

task reset_intermediate_task; begin
    clear_intermediate;
    clear_your_answer;
    clear_file;
end endtask

task input_figure_task;
    integer _cnt;
begin
    randomize_figure;
    repeat(({$random(SEED)} % 4 + 3)) @(negedge clk);
    for(_cnt=0 ; _cnt<NUM_OF_MOTION*SIZE_OF_IMAGE*SIZE_OF_IMAGE ; _cnt=_cnt+1)begin
        in_valid = 1;

        in_data[11:4] = _image[_cnt/(SIZE_OF_IMAGE*SIZE_OF_IMAGE)][(_cnt/SIZE_OF_IMAGE)%SIZE_OF_IMAGE][_cnt%SIZE_OF_IMAGE];


        @(negedge clk);
    end
    in_valid = 0;
    in_data = 'x;
end endtask

task input_MV_task;
    integer _cntPoint;
    integer _cntMotion;
    integer _cntCoordinate;
begin
    randomize_MV;
    repeat(({$random(SEED)} % 4 + 3)) @(negedge clk);
    for(_cntPoint=0 ; _cntPoint<NUM_OF_POINT ; _cntPoint=_cntPoint+1)begin
        for(_cntMotion=0 ; _cntMotion<NUM_OF_MOTION ; _cntMotion=_cntMotion+1)begin
            for(_cntCoordinate=0 ; _cntCoordinate<2 ; _cntCoordinate=_cntCoordinate+1)begin
                in_valid2 = 1;
                in_data = _motion[_cntPoint][_cntMotion][_cntCoordinate];
                @(negedge clk);
            end
        end
    end
    in_valid2 = 0;
    in_data = 'x;
end endtask

task cal_task;
    integer _pointIdx;
    integer _motionIdx;
    integer _searchIdx;
    integer _motionX;
    integer _motionY;
    integer _offsetX0, _offsetY0;
    integer _offsetX1, _offsetY1;

    real A1, A2;
    real temp;
    integer _row;
    integer _row_image;
    integer _col;
    integer _col_image;
begin
    
    


    //BI
    for(_pointIdx=0; _pointIdx<NUM_OF_POINT; _pointIdx=_pointIdx+1) begin
        _offsetX0 = 0;
        _offsetY0 = 0;
        _offsetX1 = 2;
        _offsetY1 = 2;
        for(_searchIdx=0; _searchIdx<NUM_OF_SEARCH; _searchIdx=_searchIdx+1) begin
            for(_motionIdx=0; _motionIdx<NUM_OF_MOTION; _motionIdx=_motionIdx+1) begin

                _motionX = _motion[_pointIdx][_motionIdx][0][11:4] + (_motionIdx == 0 ? _offsetX0 : _offsetX1);
                _motionY = _motion[_pointIdx][_motionIdx][1][11:4] + (_motionIdx == 0 ? _offsetY0 : _offsetY1);


                // Row index & pixel
                for(_row=0 ; _row<SIZE_OF_MOTION ; _row=_row+1) begin
                    // Row index
                    // Pixel
                    for(_col=0; _col<SIZE_OF_MOTION ; _col=_col+1) begin
                        _row_image = _row + _motionY;
                        _col_image = _col + _motionX;
                        A1 = _image[_motionIdx][_row_image][_col_image] + inFraction.Fractioner(_motion[_pointIdx][_motionIdx][0][3:0])*(_image[_motionIdx][_row_image][_col_image+1]-_image[_motionIdx][_row_image][_col_image]);
                        A2 = _image[_motionIdx][_row_image+1][_col_image] + inFraction.Fractioner(_motion[_pointIdx][_motionIdx][0][3:0])*(_image[_motionIdx][_row_image+1][_col_image+1]-_image[_motionIdx][_row_image+1][_col_image]);
                        
                        _BI[_pointIdx][_searchIdx][_motionIdx][_row][_col] = A1 + inFraction.Fractioner(_motion[_pointIdx][_motionIdx][1][3:0])*(A2-A1);
                        //$display("row: %d    col: %d     A1:  %f  A2:   %f  temp: %f  _BI: %f\n",_row,_col,A1,A2,inFraction.Fractioner(_motion[_pointIdx][_motionIdx][1][3:0])*(A2-A1),_BI[_pointIdx][_searchIdx][_motionIdx][_row][_col]);
                    end
                end  
            end
            if(_offsetY0 == 2) _offsetX0 = _offsetX0 + 1;
            if(_offsetY0 == 2) _offsetY0 = 0; else _offsetY0 = _offsetY0 + 1;
            if(_offsetY1 == 0) _offsetX1 = _offsetX1 - 1;
            if(_offsetY1 == 0) _offsetY1 = 2; else _offsetY1 = _offsetY1 - 1;
        end
    end

    //SAD
    for(_pointIdx=0; _pointIdx<NUM_OF_POINT; _pointIdx=_pointIdx+1) begin
        _smallest_SAD[_pointIdx] = REAL_MAX;
        _smallest_SAD_point[_pointIdx] = 0;
        for(_searchIdx=0; _searchIdx<NUM_OF_SEARCH; _searchIdx=_searchIdx+1) begin
            temp = 0;
            for(_row=0 ; _row<SIZE_OF_MOTION ; _row=_row+1) begin
                for(_col=0; _col<SIZE_OF_MOTION ; _col=_col+1) begin
                    temp += (_BI[_pointIdx][_searchIdx][0][_row][_col]>_BI[_pointIdx][_searchIdx][1][_row][_col])?(_BI[_pointIdx][_searchIdx][0][_row][_col]-_BI[_pointIdx][_searchIdx][1][_row][_col]):(_BI[_pointIdx][_searchIdx][1][_row][_col]-_BI[_pointIdx][_searchIdx][0][_row][_col]);
                end
            end
            _SAD[_pointIdx][_searchIdx] = temp;
            if(_smallest_SAD[_pointIdx] > temp) begin
                _smallest_SAD[_pointIdx] = temp;
                _smallest_SAD_point[_pointIdx] = _searchIdx;
            end
        end
    end

    if(DEBUG) begin
        dump_input;
        dump_output;
    end
end endtask

task wait_task; begin
    exe_lat = -1;
    while(out_valid !== 1) begin
        if(out_sad !== 0) begin
            fail_task;
            $display("[ERROR] [WAIT] Output signal should be 0 at %-12d ps  ", $time*1000);
            repeat(5) @(negedge clk);
            $finish;
        end
        if(exe_lat == DELAY) begin
            fail_task;
            $display("[ERROR] [WAIT] The execution latency at %-12d ps is over %5d cycles  ", $time*1000, DELAY);
            repeat(5) @(negedge clk);
            $finish; 
        end
        exe_lat = exe_lat + 1;
        @(negedge clk);
    end
end endtask

task check_task;
    integer _pointIdx;
begin
    out_lat = 0;
    OUTNUM = OUTBIT * NUM_OF_POINT;
    while(out_valid===1) begin
        if(out_lat==OUTNUM) begin
            fail_task;
            $display("[ERROR] [OUTPUT] Out cycles is more than %3d at %-12d ps", OUTNUM, $time*1000);
            repeat(5) @(negedge clk);
            $finish;
        end
        
        _your[out_lat/OUTBIT][out_lat%OUTBIT] = out_sad;

        out_lat = out_lat + 1;
        @(negedge clk);
    end
    if(out_lat<OUTNUM) begin
        fail_task;
        $display("[ERROR] [OUTPUT] Out cycles is less than %3d at %-12d ps", OUTNUM, $time*1000);
        repeat(5) @(negedge clk);
        $finish;
    end

    //
    // Check
    //
    for(_pointIdx=0; _pointIdx<NUM_OF_POINT; _pointIdx++) begin
        _your_point[_pointIdx] = _your[_pointIdx][OUTBIT-1:OUTBIT-SIZE_OF_POINT];
        _your_sad[_pointIdx] = outFraction.Fractioner(_your[_pointIdx][FRACTION_SIZE_OUT-1:0]) + _your[_pointIdx][OUTBIT-SIZE_OF_POINT-1:FRACTION_SIZE_OUT];
        if((_your_point[_pointIdx] !== _smallest_SAD_point[_pointIdx]) || (_your_sad[_pointIdx] !== _smallest_SAD[_pointIdx])) begin
            fail_task;
            $display("[ERROR] [OUTPUT] Output is not correct...\n");
            $display("[ERROR] [OUTPUT] Dump debugging file_out...");
            $display("[ERROR] [OUTPUT]      input.tx contains image");
            $display("[ERROR] [OUTPUT]      output.tx contains intermediate results\n");
            $display("[ERROR] [OUTPUT] Your point is not correct at %d\n", _pointIdx+1);
            dump_input;
            dump_output;
            repeat(5) @(negedge clk);
            $finish;
        end
    end

    tot_lat = tot_lat + exe_lat;
end endtask

task pass_task; begin
    $display("\033[1;33m                `oo+oy+`                            \033[1;35m Congratulation!!! \033[1;0m                                   ");
    $display("\033[1;33m               /h/----+y        `+++++:             \033[1;35m PASS This Lab........Maybe \033[1;0m                          ");
    $display("\033[1;33m             .y------:m/+ydoo+:y:---:+o             \033[1;35m Total Latency : %-10d\033[1;0m                                ", tot_lat);
    $display("\033[1;33m              o+------/y--::::::+oso+:/y                                                                                     ");
    $display("\033[1;33m              s/-----:/:----------:+ooy+-                                                                                    ");
    $display("\033[1;33m             /o----------------/yhyo/::/o+/:-.`                                                                              ");
    $display("\033[1;33m            `ys----------------:::--------:::+yyo+                                                                           ");
    $display("\033[1;33m            .d/:-------------------:--------/--/hos/                                                                         ");
    $display("\033[1;33m            y/-------------------::ds------:s:/-:sy-                                                                         ");
    $display("\033[1;33m           +y--------------------::os:-----:ssm/o+`                                                                          ");
    $display("\033[1;33m          `d:-----------------------:-----/+o++yNNmms                                                                        ");
    $display("\033[1;33m           /y-----------------------------------hMMMMN.                                                                      ");
    $display("\033[1;33m           o+---------------------://:----------:odmdy/+.                                                                    ");
    $display("\033[1;33m           o+---------------------::y:------------::+o-/h                                                                    ");
    $display("\033[1;33m           :y-----------------------+s:------------/h:-:d                                                                    ");
    $display("\033[1;33m           `m/-----------------------+y/---------:oy:--/y                                                                    ");
    $display("\033[1;33m            /h------------------------:os++/:::/+o/:--:h-                                                                    ");
    $display("\033[1;33m         `:+ym--------------------------://++++o/:---:h/                                                                     ");
    $display("\033[1;31m        `hhhhhoooo++oo+/:\033[1;33m--------------------:oo----\033[1;31m+dd+                                                 ");
    $display("\033[1;31m         shyyyhhhhhhhhhhhso/:\033[1;33m---------------:+/---\033[1;31m/ydyyhs:`                                              ");
    $display("\033[1;31m         .mhyyyyyyhhhdddhhhhhs+:\033[1;33m----------------\033[1;31m:sdmhyyyyyyo:                                            ");
    $display("\033[1;31m        `hhdhhyyyyhhhhhddddhyyyyyo++/:\033[1;33m--------\033[1;31m:odmyhmhhyyyyhy                                            ");
    $display("\033[1;31m        -dyyhhyyyyyyhdhyhhddhhyyyyyhhhs+/::\033[1;33m-\033[1;31m:ohdmhdhhhdmdhdmy:                                           ");
    $display("\033[1;31m         hhdhyyyyyyyyyddyyyyhdddhhyyyyyhhhyyhdhdyyhyys+ossyhssy:-`                                                           ");
    $display("\033[1;31m         `Ndyyyyyyyyyyymdyyyyyyyhddddhhhyhhhhhhhhy+/:\033[1;33m-------::/+o++++-`                                            ");
    $display("\033[1;31m          dyyyyyyyyyyyyhNyydyyyyyyyyyyhhhhyyhhy+/\033[1;33m------------------:/ooo:`                                         ");
    $display("\033[1;31m         :myyyyyyyyyyyyyNyhmhhhyyyyyhdhyyyhho/\033[1;33m-------------------------:+o/`                                       ");
    $display("\033[1;31m        /dyyyyyyyyyyyyyyddmmhyyyyyyhhyyyhh+:\033[1;33m-----------------------------:+s-                                      ");
    $display("\033[1;31m      +dyyyyyyyyyyyyyyydmyyyyyyyyyyyyyds:\033[1;33m---------------------------------:s+                                      ");
    $display("\033[1;31m      -ddhhyyyyyyyyyyyyyddyyyyyyyyyyyhd+\033[1;33m------------------------------------:oo              `-++o+:.`             ");
    $display("\033[1;31m       `/dhshdhyyyyyyyyyhdyyyyyyyyyydh:\033[1;33m---------------------------------------s/            -o/://:/+s             ");
    $display("\033[1;31m         os-:/oyhhhhyyyydhyyyyyyyyyds:\033[1;33m----------------------------------------:h:--.`      `y:------+os            ");
    $display("\033[1;33m         h+-----\033[1;31m:/+oosshdyyyyyyyyhds\033[1;33m-------------------------------------------+h//o+s+-.` :o-------s/y  ");
    $display("\033[1;33m         m:------------\033[1;31mdyyyyyyyyymo\033[1;33m--------------------------------------------oh----:://++oo------:s/d  ");
    $display("\033[1;33m        `N/-----------+\033[1;31mmyyyyyyyydo\033[1;33m---------------------------------------------sy---------:/s------+o/d  ");
    $display("\033[1;33m        .m-----------:d\033[1;31mhhyyyyyyd+\033[1;33m----------------------------------------------y+-----------+:-----oo/h  ");
    $display("\033[1;33m        +s-----------+N\033[1;31mhmyyyyhd/\033[1;33m----------------------------------------------:h:-----------::-----+o/m  ");
    $display("\033[1;33m        h/----------:d/\033[1;31mmmhyyhh:\033[1;33m-----------------------------------------------oo-------------------+o/h  ");
    $display("\033[1;33m       `y-----------so /\033[1;31mNhydh:\033[1;33m-----------------------------------------------/h:-------------------:soo  ");
    $display("\033[1;33m    `.:+o:---------+h   \033[1;31mmddhhh/:\033[1;33m---------------:/osssssoo+/::---------------+d+//++///::+++//::::::/y+`  ");
    $display("\033[1;33m   -s+/::/--------+d.   \033[1;31mohso+/+y/:\033[1;33m-----------:yo+/:-----:/oooo/:----------:+s//::-.....--:://////+/:`    ");
    $display("\033[1;33m   s/------------/y`           `/oo:--------:y/-------------:/oo+:------:/s:                                                 ");
    $display("\033[1;33m   o+:--------::++`              `:so/:-----s+-----------------:oy+:--:+s/``````                                             ");
    $display("\033[1;33m    :+o++///+oo/.                   .+o+::--os-------------------:oy+oo:`/o+++++o-                                           ");
    $display("\033[1;33m       .---.`                          -+oo/:yo:-------------------:oy-:h/:---:+oyo                                          ");
    $display("\033[1;33m                                          `:+omy/---------------------+h:----:y+//so                                         ");
    $display("\033[1;33m                                              `-ys:-------------------+s-----+s///om                                         ");
    $display("\033[1;33m                                                 -os+::---------------/y-----ho///om                                         ");
    $display("\033[1;33m                                                    -+oo//:-----------:h-----h+///+d                                         ");
    $display("\033[1;33m                                                       `-oyy+:---------s:----s/////y                                         ");
    $display("\033[1;33m                                                           `-/o+::-----:+----oo///+s                                         ");
    $display("\033[1;33m                                                               ./+o+::-------:y///s:                                         ");
    $display("\033[1;33m                                                                   ./+oo/-----oo/+h                                          ");
    $display("\033[1;33m                                                                       `://++++syo`                                          ");
    $display("\033[1;0m"); 
    repeat(5) @(negedge clk);
    $finish;
end endtask


task fail_task; begin
$display("\033[38;2;252;238;238m                                                                                                                                           ");      
$display("\033[38;2;252;238;238m                                                                                                :L777777v7.                                ");
$display("\033[31m  i:..::::::i.      :::::         ::::    .:::.       \033[38;2;252;238;238m                                       .vYr::::::::i7Lvi                             ");
$display("\033[31m  BBBBBBBBBBBi     iBBBBBL       .BBBB    7BBB7       \033[38;2;252;238;238m                                      JL..\033[38;2;252;172;172m:r777v777i::\033[38;2;252;238;238m.ijL                           ");
$display("\033[31m  BBBB.::::ir.     BBB:BBB.      .BBBv    iBBB:       \033[38;2;252;238;238m                                    :K: \033[38;2;252;172;172miv777rrrrr777v7:.\033[38;2;252;238;238m:J7                         ");
$display("\033[31m  BBBQ            :BBY iBB7       BBB7    :BBB:       \033[38;2;252;238;238m                                   :d \033[38;2;252;172;172m.L7rrrrrrrrrrrrr77v: \033[38;2;252;238;238miI.                       ");
$display("\033[31m  BBBB            BBB. .BBB.      BBB7    :BBB:       \033[38;2;252;238;238m                                  .B \033[38;2;252;172;172m.L7rrrrrrrrrrrrrrrrr7v..\033[38;2;252;238;238mBr                      ");
$display("\033[31m  BBBB:r7vvj:    :BBB   gBBs      BBB7    :BBB:       \033[38;2;252;238;238m                                  S:\033[38;2;252;172;172m v7rrrrrrrrrrrrrrrrrrr7v. \033[38;2;252;238;238mB:                     ");
$display("\033[31m  BBBBBBBBBB7    BBB:   .BBB.     BBB7    :BBB:       \033[38;2;252;238;238m                                 .D \033[38;2;252;172;172mi7rrrrrrr777rrrrrrrrrrr7v. \033[38;2;252;238;238mB.                    ");
$display("\033[31m  BBBB    ..    iBBBBBBBBBBBP     BBB7    :BBB:       \033[38;2;252;238;238m                                 rv\033[38;2;252;172;172m v7rrrrrr7rirv7rrrrrrrrrr7v \033[38;2;252;238;238m:I                    ");
$display("\033[31m  BBBB          BBBBi7vviQBBB.    BBB7    :BBB.       \033[38;2;252;238;238m                                 2i\033[38;2;252;172;172m.v7rrrrrr7i  :v7rrrrrrrrrrvi \033[38;2;252;238;238mB:                   ");
$display("\033[31m  BBBB         rBBB.      BBBQ   .BBBv    iBBB2ir777L7\033[38;2;252;238;238m                                 2i.\033[38;2;252;172;172mv7rrrrrr7v \033[38;2;252;238;238m:..\033[38;2;252;172;172mv7rrrrrrrrr77 \033[38;2;252;238;238mrX                   ");
$display("\033[31m .BBBB        :BBBB       BBBB7  .BBBB    7BBBBBBBBBBB\033[38;2;252;238;238m                                 Yv \033[38;2;252;172;172mv7rrrrrrrv.\033[38;2;252;238;238m.B \033[38;2;252;172;172m.vrrrrrrrrrrL.\033[38;2;252;238;238m:5                   ");
$display("\033[31m  . ..        ....         ...:   ....    ..   .......\033[38;2;252;238;238m                                 .q \033[38;2;252;172;172mr7rrrrrrr7i \033[38;2;252;238;238mPv \033[38;2;252;172;172mi7rrrrrrrrrv.\033[38;2;252;238;238m:S                   ");
$display("\033[38;2;252;238;238m                                                                                        Lr \033[38;2;252;172;172m77rrrrrr77 \033[38;2;252;238;238m:B. \033[38;2;252;172;172mv7rrrrrrrrv.\033[38;2;252;238;238m:S                   ");
$display("\033[38;2;252;238;238m                                                                                         B: \033[38;2;252;172;172m7v7rrrrrv. \033[38;2;252;238;238mBY \033[38;2;252;172;172mi7rrrrrrr7v \033[38;2;252;238;238miK                   ");
$display("\033[38;2;252;238;238m                                                                              .::rriii7rir7. \033[38;2;252;172;172m.r77777vi \033[38;2;252;238;238m7B  \033[38;2;252;172;172mvrrrrrrr7r \033[38;2;252;238;238m2r                   ");
$display("\033[38;2;252;238;238m                                                                       .:rr7rri::......    .     \033[38;2;252;172;172m.:i7s \033[38;2;252;238;238m.B. \033[38;2;252;172;172mv7rrrrr7L..\033[38;2;252;238;238mB                    ");
$display("\033[38;2;252;238;238m                                                        .::7L7rriiiirr77rrrrrrrr72BBBBBBBBBBBBvi:..  \033[38;2;252;172;172m.  \033[38;2;252;238;238mBr \033[38;2;252;172;172m77rrrrrvi \033[38;2;252;238;238mKi                    ");
$display("\033[38;2;252;238;238m                                                    :rv7i::...........    .:i7BBBBQbPPPqPPPdEZQBBBBBr:.\033[38;2;252;238;238m ii \033[38;2;252;172;172mvvrrrrvr \033[38;2;252;238;238mvs                     ");
$display("\033[38;2;252;238;238m                    .S77L.                      .rvi:. ..:r7QBBBBBBBBBBBgri.    .:BBBPqqKKqqqqPPPPPEQBBBZi  \033[38;2;252;172;172m:777vi \033[38;2;252;238;238mvI                      ");
$display("\033[38;2;252;238;238m                    B: ..Jv                   isi. .:rBBBBBQZPPPPqqqPPdERBBBBBi.    :BBRKqqqqqqqqqqqqPKDDBB:  \033[38;2;252;172;172m:7. \033[38;2;252;238;238mJr                       ");
$display("\033[38;2;252;238;238m                   vv SB: iu                rL: .iBBBQEPqqPPqqqqqqqqqqqqqPPPPbQBBB:   .EBQKqqqqqqPPPqqKqPPgBB:  .B:                        ");
$display("\033[38;2;252;238;238m                  :R  BgBL..s7            rU: .qBBEKPqqqqqqqqqqqqqqqqqqqqqqqqqPPPEBBB:   EBEPPPEgQBBQEPqqqqKEBB: .s                        ");
$display("\033[38;2;252;238;238m               .U7.  iBZBBBi :ji         5r .MBQqPqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqPKgBB:  .BBBBBdJrrSBBQKqqqqKZB7  I:                      ");
$display("\033[38;2;252;238;238m              v2. :rBBBB: .BB:.ru7:    :5. rBQqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqPPBB:  :.        .5BKqqqqqqBB. Kr                     ");
$display("\033[38;2;252;238;238m             .B .BBQBB.   .RBBr  :L77ri2  BBqPqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqPbBB   \033[38;2;252;172;172m.irrrrri  \033[38;2;252;238;238mQQqqqqqqKRB. 2i                    ");
$display("\033[38;2;252;238;238m              27 :BBU  rBBBdB \033[38;2;252;172;172m iri::::: \033[38;2;252;238;238m.BQKqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqKRBs\033[38;2;252;172;172mirrr7777L: \033[38;2;252;238;238m7BqqqqqqqXZB. BLv772i              ");
$display("\033[38;2;252;238;238m               rY  PK  .:dPMB \033[38;2;252;172;172m.Y77777r.\033[38;2;252;238;238m:BEqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqPPBqi\033[38;2;252;172;172mirrrrrv: \033[38;2;252;238;238muBqqqqqqqqqgB  :.:. B:             ");
$display("\033[38;2;252;238;238m                iu 7BBi  rMgB \033[38;2;252;172;172m.vrrrrri\033[38;2;252;238;238mrBEqKqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqPQgi\033[38;2;252;172;172mirrrrv. \033[38;2;252;238;238mQQqqqqqqqqqXBb .BBB .s:.           ");
$display("\033[38;2;252;238;238m                i7 BBdBBBPqbB \033[38;2;252;172;172m.vrrrri\033[38;2;252;238;238miDgPPbPqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqPQDi\033[38;2;252;172;172mirr77 \033[38;2;252;238;238m:BdqqqqqqqqqqPB. rBB. .:iu7         ");
$display("\033[38;2;252;238;238m                iX.:iBRKPqKXB.\033[38;2;252;172;172m 77rrr\033[38;2;252;238;238mi7QPBBBBPqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqPB7i\033[38;2;252;172;172mrr7r \033[38;2;252;238;238m.vBBPPqqqqqqKqBZ  BPBgri: 1B        ");
$display("\033[38;2;252;238;238m                 ivr .BBqqKXBi \033[38;2;252;172;172mr7rri\033[38;2;252;238;238miQgQi   QZKqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqPEQi\033[38;2;252;172;172mirr7r.  \033[38;2;252;238;238miBBqPqqqqqqPB:.QPPRBBB LK        ");
$display("\033[38;2;252;238;238m                   :I. iBgqgBZ \033[38;2;252;172;172m:7rr\033[38;2;252;238;238miJQPB.   gRqqqqqqqqPPPPPPPPqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqPQ7\033[38;2;252;172;172mirrr7vr.  \033[38;2;252;238;238mUBqqPPgBBQPBBKqqqKB  B         ");
$display("\033[38;2;252;238;238m                     v7 .BBR: \033[38;2;252;172;172m.r7ri\033[38;2;252;238;238miggqPBrrBBBBBBBBBBBBBBBBBBQEPPqqPPPqqqqqqqqqqqqqqqqqqqqqqqqqPgPi\033[38;2;252;172;172mirrrr7v7  \033[38;2;252;238;238mrBPBBP:.LBbPqqqqqB. u.        ");
$display("\033[38;2;252;238;238m                      .j. . \033[38;2;252;172;172m :77rr\033[38;2;252;238;238miiBPqPbBB::::::.....:::iirrSBBBBBBBQZPPPPPqqqqqqqqqqqqqqqqqqqqEQi\033[38;2;252;172;172mirrrrrr7v \033[38;2;252;238;238m.BB:     :BPqqqqqDB .B        ");
$display("\033[38;2;252;238;238m                       YL \033[38;2;252;172;172m.i77rrrr\033[38;2;252;238;238miLQPqqKQJ. \033[38;2;252;172;172m ............       \033[38;2;252;238;238m..:irBBBBBBZPPPqqqqqqqPPBBEPqqqdRr\033[38;2;252;172;172mirrrrrr7v \033[38;2;252;238;238m.B  .iBB  dQPqqqqPBi Y:       ");
$display("\033[38;2;252;238;238m                     :U:.\033[38;2;252;172;172mrv7rrrrri\033[38;2;252;238;238miPgqqqqKZB.\033[38;2;252;172;172m.v77777777777777ri::..   \033[38;2;252;238;238m  ..:rBBBBQPPqqqqPBUvBEqqqPRr\033[38;2;252;172;172mirrrrrrvi\033[38;2;252;238;238m iB:RBBbB7 :BQqPqKqBR r7       ");
$display("\033[38;2;252;238;238m                    iI.\033[38;2;252;172;172m.v7rrrrrrri\033[38;2;252;238;238midgqqqqqKB:\033[38;2;252;172;172m 77rrrrrrrrrrrrr77777777ri:..   \033[38;2;252;238;238m .:1BBBEPPB:   BbqqPQr\033[38;2;252;172;172mirrrr7vr\033[38;2;252;238;238m .BBBZPqqDB  .JBbqKPBi vi       ");
$display("\033[38;2;252;238;238m                   :B \033[38;2;252;172;172miL7rrrrrrrri\033[38;2;252;238;238mibgqqqqqqBr\033[38;2;252;172;172m r7rrrrrrrrrrrrrrrrrrrrr777777ri:.  \033[38;2;252;238;238m .iBBBBi  .BbqqdRr\033[38;2;252;172;172mirr7v7: \033[38;2;252;238;238m.Bi.dBBPqqgB:  :BPqgB  B        ");
$display("\033[38;2;252;238;238m                   .K.i\033[38;2;252;172;172mv7rrrrrrrri\033[38;2;252;238;238miZgqqqqqqEB \033[38;2;252;172;172m.vrrrrrrrrrrrrrrrrrrrrrrrrrrr777vv7i.  \033[38;2;252;238;238m :PBBBBPqqqEQ\033[38;2;252;172;172miir77:  \033[38;2;252;238;238m:BB:  .rBPqqEBB. iBZB. Rr        ");
$display("\033[38;2;252;238;238m                    iM.:\033[38;2;252;172;172mv7rrrrrrrri\033[38;2;252;238;238mUQPqqqqqPBi\033[38;2;252;172;172m i7rrrrrrrrrrrrrrrrrrrrrrrrr77777i.   \033[38;2;252;238;238m.  :BddPqqqqEg\033[38;2;252;172;172miir7. \033[38;2;252;238;238mrBBPqBBP. :BXKqgB  BBB. 2r         ");
$display("\033[38;2;252;238;238m                     :U:.\033[38;2;252;172;172miv77rrrrri\033[38;2;252;238;238mrBPqqqqqqPB: \033[38;2;252;172;172m:7777rrrrrrrrrrrrrrr777777ri.   \033[38;2;252;238;238m.:uBBBBZPqqqqqqPQL\033[38;2;252;172;172mirr77 \033[38;2;252;238;238m.BZqqPB:  qMqqPB. Yv:  Ur          ");
$display("\033[38;2;252;238;238m                       1L:.\033[38;2;252;172;172m:77v77rii\033[38;2;252;238;238mqQPqqqqqPbBi \033[38;2;252;172;172m .ir777777777777777ri:..   \033[38;2;252;238;238m.:rBBBRPPPPPqqqqqqqgQ\033[38;2;252;172;172miirr7vr \033[38;2;252;238;238m:BqXQ: .BQPZBBq ...:vv.           ");
$display("\033[38;2;252;238;238m                         LJi..\033[38;2;252;172;172m::r7rii\033[38;2;252;238;238mRgKPPPPqPqBB:.  \033[38;2;252;172;172m ............     \033[38;2;252;238;238m..:rBBBBPPqqKKKKqqqPPqPbB1\033[38;2;252;172;172mrvvvvvr  \033[38;2;252;238;238mBEEDQBBBBBRri. 7JLi              ");
$display("\033[38;2;252;238;238m                           .jL\033[38;2;252;172;172m  777rrr\033[38;2;252;238;238mBBBBBBgEPPEBBBvri:::::::::irrrbBBBBBBDPPPPqqqqqqXPPZQBBBBr\033[38;2;252;172;172m.......\033[38;2;252;238;238m.:BBBBg1ri:....:rIr                 ");
$display("\033[38;2;252;238;238m                            vI \033[38;2;252;172;172m:irrr:....\033[38;2;252;238;238m:rrEBBBBBBBBBBBBBBBBBBBBBBBBBBBBBQQBBBBBBBBBBBBBQr\033[38;2;252;172;172mi:...:.   \033[38;2;252;238;238m.:ii:.. .:.:irri::                    ");
$display("\033[38;2;252;238;238m                             71vi\033[38;2;252;172;172m:::irrr::....\033[38;2;252;238;238m    ...:..::::irrr7777777777777rrii::....  ..::irvrr7sUJYv7777v7ii..                         ");
$display("\033[38;2;252;238;238m                               .i777i. ..:rrri77rriiiiiii:::::::...............:::iiirr7vrrr:.                                             ");
$display("\033[38;2;252;238;238m                                                      .::::::::::::::::::::::::::::::                                                      \033[m");

end endtask

endmodule

module fraction #(
    parameter FRACTION_SIZE = 4
);

    function real Fractioner;
        input [FRACTION_SIZE-1:0] fraction_in;
        integer i;
        real temp;
    begin
        temp = 1;
        Fractioner = 0;
        for(i=FRACTION_SIZE-1; i>=0; i--) begin
            temp /= 2;
            Fractioner += fraction_in[i] * temp;
        end
    end endfunction

endmodule


module dumper #(
    parameter DUMP_ELEMENT_SIZE = 4
);

    // Dump
    parameter DUMP_NUM_OF_SPACE = 2;
    parameter DUMP_NUM_OF_SEP = 2;
    parameter SIZE_OF_BUFFER = 256;

    task addLine;
        input integer file_out;
    begin
        $fwrite(file_out, "\n");
    end endtask

    task addSeperator;
        input integer file_out;
        input integer _num;
        integer _idx;
        reg[(DUMP_ELEMENT_SIZE+DUMP_NUM_OF_SPACE+DUMP_NUM_OF_SEP)*8:1] _line; // 4 = 2 spaces with 2 "+"
    begin
        _line = "";
        for(_idx=1 ; _idx<=DUMP_ELEMENT_SIZE+2 ; _idx=_idx+1) begin
            _line = {_line, "-"};
        end
        _line = {_line, "+"};
        $fwrite(file_out, "+");
        for(_idx=0 ; _idx<_num ; _idx=_idx+1) $fwrite(file_out, "%0s", _line);
        $fwrite(file_out, "\n");
    end endtask

    // TODO
    // Only support %d %s
    // Should consider the %f ex : %8.3f, %12.1f
    task addCell;
        input integer file_out;
        input real _in;
        input reg[8:1] _type;
        input reg _isStart;
        reg[SIZE_OF_BUFFER*8:1] _format;
        reg[DUMP_ELEMENT_SIZE*8:1] _inFormat;
        reg[(DUMP_ELEMENT_SIZE+DUMP_NUM_OF_SPACE+DUMP_NUM_OF_SEP)*8:1] _line;
    begin
        // Format
        $sformat(_format, "%%%-d", DUMP_ELEMENT_SIZE);
        if(_type == "f")
            _format = {_format[(SIZE_OF_BUFFER-1)*8:1], ".10", _type};
        else
            _format = {_format[(SIZE_OF_BUFFER-1)*8:1], _type};
        $sformat(_inFormat, _format, _in);
        // Output
        _line = _isStart ? "| " : " ";
        _line = {_line, _inFormat};
        _line = {_line, " |"};
        $fwrite(file_out, "%0s", _line);
    end endtask

    // task addCellUnformat;
    //     input integer file_out;
    //     input reg[DUMP_ELEMENT_SIZE*8:1] _in;
    //     input reg _isStart;
    //     reg[SIZE_OF_BUFFER*8:1] _format;
    //     reg[DUMP_ELEMENT_SIZE*8:1] _inFormat;
    //     reg[(DUMP_ELEMENT_SIZE+DUMP_NUM_OF_SPACE+DUMP_NUM_OF_SEP)*8:1] _line;
    // begin
    //     _line = _isStart ? "| " : " ";
    //     _line = {_line, _in};
    //     _line = {_line, " |"};
    //     $fwrite(file_out, "%0s", _line);
    // end endtask

endmodule