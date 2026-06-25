project_open Eddy_c -revision Eddy_c
create_timing_netlist -model slow
read_sdc
update_timing_netlist
report_timing -to_clock [get_clocks ADC0_DCO] -hold -npaths 5 \
    -detail full_path -stdout
project_close
