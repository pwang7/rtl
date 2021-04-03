# To run this Tcl script
#source non-project_run.tcl

cd {G:\Vivado\nonprj}
# Set basic infomation
set top wave_gen
set part xc7k325tffg900-2

# Read IPs into memory
create_project -in memory
set_property PART $part [current_project]
set IpFiles [glob -nocomplain ./ip/*/*.xci]
foreach ipxci $IpFiles {
    read_ip $ipxci
    set_property is_locked false [get_files $ipxci]
    generate_target all [get_files $ipxci]
    puts "IP $ipxci Synthesis Done!"
}

# Read design files into memory
read_verilog [glob -nocomplain ./src/*.v*] -quiet
set_property FILE_TYPE "Verilog Header" [get_files clogb2.vh]
puts "Design files read successfully!"

# Read constraint files into memory
read_xdc [glob -nocomplain ./xdc/*.xdc] -quiet
puts "Constraint files read successfully!"

# Synthesis
synth_design -part $part -top $top
write_checkpoint -force ${top}_synth.dcp

# Opt
opt_design -directive Explore
write_checkpoint -force ${top}_opt.dcp

# Place
place_design -directive Explore
write_checkpoint -force ${top}_placed.dcp
report_utilization -file ${top}_placed_utilization.rpt
report_timing_summary -file ${top}_placed_timing.rpt

# Route
route_design -directive Explore
write_checkpoint -force ${top}_routed.dcp
report_timing_summary -file ${top}_routed_timing.rpt

# BitGen
write_bitstream -force ${top}.bit

start_gui
#stop_gui