###################################################################

# Created by write_sdc on Sun May 25 00:04:24 2025

###################################################################
set sdc_version 2.1

set_units -time ns -resistance kOhm -capacitance pF -voltage V -current mA
set_operating_conditions -max WCCOM -max_library                               \
fsa0m_a_generic_core_ss1p62v125c\
                         -min BCCOM -min_library                               \
fsa0m_a_generic_core_ff1p98vm40c
# set_wire_load_mode top
# set_wire_load_model -name G5K -library fsa0m_a_generic_core_ss1p62v125c
set_load -pin_load 0.05 [get_ports out_valid]
set_load -pin_load 0.05 [get_ports out_sad]
set_max_capacitance 0.15 [get_ports clk]
set_max_capacitance 0.15 [get_ports rst_n]
set_max_capacitance 0.15 [get_ports in_valid]
set_max_capacitance 0.15 [get_ports in_valid2]
set_max_capacitance 0.15 [get_ports {in_data[11]}]
set_max_capacitance 0.15 [get_ports {in_data[10]}]
set_max_capacitance 0.15 [get_ports {in_data[9]}]
set_max_capacitance 0.15 [get_ports {in_data[8]}]
set_max_capacitance 0.15 [get_ports {in_data[7]}]
set_max_capacitance 0.15 [get_ports {in_data[6]}]
set_max_capacitance 0.15 [get_ports {in_data[5]}]
set_max_capacitance 0.15 [get_ports {in_data[4]}]
set_max_capacitance 0.15 [get_ports {in_data[3]}]
set_max_capacitance 0.15 [get_ports {in_data[2]}]
set_max_capacitance 0.15 [get_ports {in_data[1]}]
set_max_capacitance 0.15 [get_ports {in_data[0]}]
set_max_fanout 10 [get_ports clk]
set_max_fanout 10 [get_ports rst_n]
set_max_fanout 10 [get_ports in_valid]
set_max_fanout 10 [get_ports in_valid2]
set_max_fanout 10 [get_ports {in_data[11]}]
set_max_fanout 10 [get_ports {in_data[10]}]
set_max_fanout 10 [get_ports {in_data[9]}]
set_max_fanout 10 [get_ports {in_data[8]}]
set_max_fanout 10 [get_ports {in_data[7]}]
set_max_fanout 10 [get_ports {in_data[6]}]
set_max_fanout 10 [get_ports {in_data[5]}]
set_max_fanout 10 [get_ports {in_data[4]}]
set_max_fanout 10 [get_ports {in_data[3]}]
set_max_fanout 10 [get_ports {in_data[2]}]
set_max_fanout 10 [get_ports {in_data[1]}]
set_max_fanout 10 [get_ports {in_data[0]}]
set_max_transition 3 [get_ports clk]
set_max_transition 3 [get_ports rst_n]
set_max_transition 3 [get_ports in_valid]
set_max_transition 3 [get_ports in_valid2]
set_max_transition 3 [get_ports {in_data[11]}]
set_max_transition 3 [get_ports {in_data[10]}]
set_max_transition 3 [get_ports {in_data[9]}]
set_max_transition 3 [get_ports {in_data[8]}]
set_max_transition 3 [get_ports {in_data[7]}]
set_max_transition 3 [get_ports {in_data[6]}]
set_max_transition 3 [get_ports {in_data[5]}]
set_max_transition 3 [get_ports {in_data[4]}]
set_max_transition 3 [get_ports {in_data[3]}]
set_max_transition 3 [get_ports {in_data[2]}]
set_max_transition 3 [get_ports {in_data[1]}]
set_max_transition 3 [get_ports {in_data[0]}]
create_clock [get_ports clk]  -period 11  -waveform {0 5.5}
set_clock_uncertainty 0.1  [get_clocks clk]
set_clock_transition -max -rise 0.1 [get_clocks clk]
set_clock_transition -max -fall 0.1 [get_clocks clk]
set_clock_transition -min -rise 0.1 [get_clocks clk]
set_clock_transition -min -fall 0.1 [get_clocks clk]
set_input_delay -clock clk  0  [get_ports clk]
set_input_delay -clock clk  0  [get_ports rst_n]
set_input_delay -clock clk  -max 5.5  [get_ports in_valid]
set_input_delay -clock clk  -min 0  [get_ports in_valid]
set_input_delay -clock clk  -max 5.5  [get_ports in_valid2]
set_input_delay -clock clk  -min 0  [get_ports in_valid2]
set_input_delay -clock clk  -max 5.5  [get_ports {in_data[11]}]
set_input_delay -clock clk  -min 0  [get_ports {in_data[11]}]
set_input_delay -clock clk  -max 5.5  [get_ports {in_data[10]}]
set_input_delay -clock clk  -min 0  [get_ports {in_data[10]}]
set_input_delay -clock clk  -max 5.5  [get_ports {in_data[9]}]
set_input_delay -clock clk  -min 0  [get_ports {in_data[9]}]
set_input_delay -clock clk  -max 5.5  [get_ports {in_data[8]}]
set_input_delay -clock clk  -min 0  [get_ports {in_data[8]}]
set_input_delay -clock clk  -max 5.5  [get_ports {in_data[7]}]
set_input_delay -clock clk  -min 0  [get_ports {in_data[7]}]
set_input_delay -clock clk  -max 5.5  [get_ports {in_data[6]}]
set_input_delay -clock clk  -min 0  [get_ports {in_data[6]}]
set_input_delay -clock clk  -max 5.5  [get_ports {in_data[5]}]
set_input_delay -clock clk  -min 0  [get_ports {in_data[5]}]
set_input_delay -clock clk  -max 5.5  [get_ports {in_data[4]}]
set_input_delay -clock clk  -min 0  [get_ports {in_data[4]}]
set_input_delay -clock clk  -max 5.5  [get_ports {in_data[3]}]
set_input_delay -clock clk  -min 0  [get_ports {in_data[3]}]
set_input_delay -clock clk  -max 5.5  [get_ports {in_data[2]}]
set_input_delay -clock clk  -min 0  [get_ports {in_data[2]}]
set_input_delay -clock clk  -max 5.5  [get_ports {in_data[1]}]
set_input_delay -clock clk  -min 0  [get_ports {in_data[1]}]
set_input_delay -clock clk  -max 5.5  [get_ports {in_data[0]}]
set_input_delay -clock clk  -min 0  [get_ports {in_data[0]}]
set_output_delay -clock clk  -max 5.5  [get_ports out_valid]
set_output_delay -clock clk  -min 0  [get_ports out_valid]
set_output_delay -clock clk  -max 5.5  [get_ports out_sad]
set_output_delay -clock clk  -min 0  [get_ports out_sad]
set_input_transition -max 0.5  [get_ports clk]
set_input_transition -min 0.5  [get_ports clk]
set_input_transition -max 0.5  [get_ports rst_n]
set_input_transition -min 0.5  [get_ports rst_n]
set_input_transition -max 0.5  [get_ports in_valid]
set_input_transition -min 0.5  [get_ports in_valid]
set_input_transition -max 0.5  [get_ports in_valid2]
set_input_transition -min 0.5  [get_ports in_valid2]
set_input_transition -max 0.5  [get_ports {in_data[11]}]
set_input_transition -min 0.5  [get_ports {in_data[11]}]
set_input_transition -max 0.5  [get_ports {in_data[10]}]
set_input_transition -min 0.5  [get_ports {in_data[10]}]
set_input_transition -max 0.5  [get_ports {in_data[9]}]
set_input_transition -min 0.5  [get_ports {in_data[9]}]
set_input_transition -max 0.5  [get_ports {in_data[8]}]
set_input_transition -min 0.5  [get_ports {in_data[8]}]
set_input_transition -max 0.5  [get_ports {in_data[7]}]
set_input_transition -min 0.5  [get_ports {in_data[7]}]
set_input_transition -max 0.5  [get_ports {in_data[6]}]
set_input_transition -min 0.5  [get_ports {in_data[6]}]
set_input_transition -max 0.5  [get_ports {in_data[5]}]
set_input_transition -min 0.5  [get_ports {in_data[5]}]
set_input_transition -max 0.5  [get_ports {in_data[4]}]
set_input_transition -min 0.5  [get_ports {in_data[4]}]
set_input_transition -max 0.5  [get_ports {in_data[3]}]
set_input_transition -min 0.5  [get_ports {in_data[3]}]
set_input_transition -max 0.5  [get_ports {in_data[2]}]
set_input_transition -min 0.5  [get_ports {in_data[2]}]
set_input_transition -max 0.5  [get_ports {in_data[1]}]
set_input_transition -min 0.5  [get_ports {in_data[1]}]
set_input_transition -max 0.5  [get_ports {in_data[0]}]
set_input_transition -min 0.5  [get_ports {in_data[0]}]
