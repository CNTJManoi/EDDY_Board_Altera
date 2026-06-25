# Primary oscillator and PLL-derived clocks.
create_clock -name CLK16 -period 62.500 [get_ports {16MHz}]
derive_pll_clocks

# STM32 SPI: the fitted C8 device does not close 54 MHz MISO timing.
# 27 MHz (108 MHz / 4) is the supported production setting.
create_clock -name SCK -period 37.037 [get_ports PA5]
set_output_delay -clock SCK -max 0.0 [get_ports PB4]
set_output_delay -clock SCK -min 0.0 [get_ports PB4]

# STM32 SPI4 is transparently routed to one of four write-only LTC2640 DACs.
# SPI4 runs at 108 MHz / 4 = 27 MHz. Limit each combinational FPGA leg to
# 8 ns, leaving margin against the LTC2640 4 ns data setup/hold requirements.
create_clock -name SPI4_SCK -period 37.037 [get_ports PE2]
set_max_delay 8.000 -from [get_ports PE2] -to [get_ports DAC_CLK]
set_max_delay 8.000 -from [get_ports PE6] -to [get_ports DAC_DATA]
set_max_delay 8.000 -from [get_ports PE4] -to [get_ports {DAC_CS[*]}]
# The channel GPIO is programmed well before PE4 falls. Its decode only has to
# settle before the transaction, not within one SPI half-cycle.
set_max_delay 12.000 -from [get_ports {PD[4] PD[5]}] -to [get_ports {DAC_CS[*]}]

# AD9649 source-synchronous CMOS interfaces. DATA is captured on the rising DCO
# edge specified by the converter, then transferred through a falling-edge
# holding register before the M9K write edge.
create_clock -name ADC0_DCO -period 15.625 [get_ports C0DCO]
create_clock -name ADC1_DCO -period 15.625 [get_ports C1DCO]
create_clock -name ADC2_DCO -period 15.625 [get_ports C2DCO]
create_clock -name ADC3_DCO -period 15.625 [get_ports C3DCO]

set_input_delay -clock ADC0_DCO -max  0.500 [get_ports {C0D[*]}]
set_input_delay -clock ADC0_DCO -min -0.500 [get_ports {C0D[*]}]
set_input_delay -clock ADC1_DCO -max  0.500 [get_ports {C1D[*]}]
set_input_delay -clock ADC1_DCO -min -0.500 [get_ports {C1D[*]}]
set_input_delay -clock ADC2_DCO -max  0.500 [get_ports {C2D[*]}]
set_input_delay -clock ADC2_DCO -min -0.500 [get_ports {C2D[*]}]
set_input_delay -clock ADC3_DCO -max  0.500 [get_ports {C3D[*]}]
set_input_delay -clock ADC3_DCO -min -0.500 [get_ports {C3D[*]}]

# PCB net DC- connects FPGA pin R22/DAC_CLKN to the AD9744 CLK+ pin. CMODE is
# grounded, so this is the only active clock input; DAC_CLKP is tri-stated.
# DD is registered on rising clk64 and CLK+ is inverted clk64, providing one
# half-cycle for the AD9744 2.0 ns setup and 1.5 ns hold requirements.
create_generated_clock -name DAC_CAPTURE \
    -source [get_pins {inst4|altpll_component|auto_generated|pll1|clk[0]}] \
    -invert [get_ports DAC_CLKN]
set_output_delay -clock DAC_CAPTURE -max  2.000 [get_ports {DD[*]}]
set_output_delay -clock DAC_CAPTURE -min -1.500 [get_ports {DD[*]}]

# SPI, the four returned ADC clocks, and the PLL domain are asynchronous at
# the FPGA boundary. Crossings use stable-word protocols or synchronizers.
set_clock_groups -asynchronous \
    -group [get_clocks SCK] \
    -group [get_clocks SPI4_SCK] \
    -group [get_clocks {CLK16 DAC_CAPTURE inst4|altpll_component|auto_generated|pll1|clk[0]}] \
    -group [get_clocks ADC0_DCO] \
    -group [get_clocks ADC1_DCO] \
    -group [get_clocks ADC2_DCO] \
    -group [get_clocks ADC3_DCO]

derive_clock_uncertainty
