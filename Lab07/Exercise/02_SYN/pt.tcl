# specify parameters
set DESIGN "PRGN_TOP"

#Step 1 Read in the design data, which includes a gate-level netlist and associated logic libraries.
set search_path         " ./ \
			../02_SYN/Netlist                     \
            ../04_MEM/                            \
                        ~iclabTA01/UMC018_CBDK/CIC/SynopsysDC/db/    \
                        ~iclabTA01/UMC018_CBDK/CIC/Sdb/          \
                        /usr/cad/synopsys/synthesis/cur/libraries/syn/ \
                        /usr/cad/synopsys/synthesis/cur/dw "
set target_library      " fsa0m_a_generic_core_ss1p62v125c.db DUAL_64X32X1BM1_WC.db "
set link_library        " * $target_library dw_foundation.sldb standard.sldb DUAL_64X32X1BM1_WC.db "
read_verilog Netlist/$DESIGN\_SYN.v
current_design $DESIGN
link_design -keep_sub_designs $DESIGN

#create_clock -period $CLK_period CLK
read_sdc Netlist/$DESIGN\_SYN.sdc

#Step 6 Specify case and mode analysis settings.
#Step 7 Back-annotate delay and parasitics.
read_sdf Netlist/$DESIGN\_SYN.sdf

# set_annotated_check 
# modify here 
# set all_dffs [get_cells -hierarchical -filter "ref_name =~ *DFF*"]

foreach_in_collection x [get_cell */A1_reg] {
  set_annotated_check -0 -setup -from [get_object_name $x]/CK -to [get_object_name $x]/D -clock rise
  set_annotated_check -0 -hold  -from [get_object_name $x]/CK -to [get_object_name $x]/D -clock rise
}

# foreach_in_collection src_ff $all_dffs {
#     set src_ff_name [get_object_name $src_ff]
#     set src_clk_pin [get_pins ${src_ff_name}/CK]
#     set src_clk_net [get_nets -of $src_clk_pin]
# 	set src_clk [get_object_name $src_clk_net]

#     foreach_in_collection dst_ff $all_dffs {
#         set dst_ff_name [get_object_name $dst_ff]
#         set dst_clk_pin [get_pins ${dst_ff_name}/CK]
#         set dst_clk_net [get_nets -of $dst_clk_pin]
#         set dst_clk [get_object_name $dst_clk_net]

#         if { $src_clk != $dst_clk } {
#             set_annotated_check -0 -setup -from $dst_ff_name/CK -to $dst_ff_name/D -clock rise
#             set_annotated_check -0 -hold  -from $dst_ff_name/CK -to $dst_ff_name/D -clock rise
#         }
#     }
# }


write_sdf Netlist/$DESIGN\_SYN_pt.sdf

#Step 8 (Optional) Apply variation.
#Step 9 Specify power information
#Step 10 (Optional) Specify options and data for signal integrity analysis.
#Step 11 (Optional) Apply options for specific design techniques.
#Step 12 Check the design data and analysis setup.
check_timing

#Step 13 Perform a full timing analysis and examine the results.
report_timing > Report/$DESIGN\_pt.timing
report_timing

#Step 14 (Optional) Perform ECO to fix timing violations and recover power.
#Step 15 Save the PrimeTime session.
#save_session
exit

