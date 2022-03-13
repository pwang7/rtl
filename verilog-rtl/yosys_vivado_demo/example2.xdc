create_clock -period 25.000 -name clk -waveform {0.000 12.500} [get_ports clk]

set_property -dict {IOSTANDARD LVCMOS33 PACKAGE_PIN N11} [get_ports clk]
set_property -dict {IOSTANDARD LVCMOS33 PACKAGE_PIN D1} [get_ports led]

set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]

