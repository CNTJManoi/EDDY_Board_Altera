project_open Eddy_c -revision Eddy_c
create_timing_netlist -model slow
read_sdc
update_timing_netlist
report_timing -to_clock [get_clocks {inst4|altpll_component|auto_generated|pll1|clk[0]}] \
    -setup -npaths 10 -detail full_path -stdout
project_close
