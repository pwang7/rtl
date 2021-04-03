# To run this Tcl proc
#source project_run.tcl
#set WorkDir {G:/Vivado/wavegen}
#set PrjName wavegen_prj
#set Part xc7k325tffg900-2
#pm_full_design_flow $WorkDir $PrjName $Part

# Required source file directories:
# src sim xdc ip

proc pm_full_design_flow {WorkDir PrjName Part} {
    set WorkDir [file normalize $WorkDir]

    cd $WorkDir

    create_project –name $PrjName –dir $WorkDir/$PrjName -part $Part -force
    puts "Create project successfully!"

    # Add RTL source files
    add_files -fileset sources_1 ./src -quiet
    update_compile_order -fileset sources_1
    puts "RTL design source files added successfully!"

    # Add testbench source files
    add_files -fileset sim_1 ./sim -quite
    update_compile_order -fileset sim_1
    puts "Simulation source files added successfully!"

    # Add constraints files
    add_files -fileset constrs_1 ./xdc -quiet
    puts "constraint files added successfully!"

    # Add existing IPs
    add_files [glob -nocomplain ./ip/*/*.xci] -quiet
    update_compile_order -fileset sources_1
    puts "IPs added successfully!"

    # Launch Synthesis
    launch_runs synth_1
    wait_on_run synth_1
    puts "Synthesis Done!"

    # Check timing results of Synthesis
    open_run synth_1
    set NegSlackPath [get_cells -slack_lesser_than 0 -quiet]
    if {[llength $NegSlackPath] > 0} {
        puts "Timing Violations after Synthesis!"
        start_gui
        return 1
    } else {
        puts "Timing is closure after Synthesis!"
    }

    # Set bit file properties
    set_property BITSTREAM.CONFIG.CONFIGRATE 66 [current_design]
    set_property CONFIG_VOLTAGE 1.8 [current_design]
    set_property CFGBVS GND [current_design]
    puts "Bit file properties set successfully!"

    # Set configuration memory properties
    set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design] # SPI位宽
    set_property config_mode SPIx4 [current_design]
    puts "configuration memory properties set successfully!"

    # Launch Implementation
    set_property strategy Performance_Explore [get_runs impl_1]
    launch_runs impl_1
    wait_on_run impl_1
    puts "Implementation Done!"

    # Check timing results of Implementation
    open_run impl_1
    set NegSlackPath [get_cells -slack_lesser_than 0 -quiet]
    if {[llength $NegSlackPath] > 0} {
        puts "Timing Violations after Implementation!"
        start_gui
        return 1
    } else {
        puts "Timing is closure after Implementation!"
    }

    # Generate bit file
    launch_runs impl_1 -to_step write_bitstream
    wait_on_run impl_1
    puts "Bit file generated successfully!"

    # Generate MCS file
    set BitDir [get_property DIRECTORY [get_runs impl_1]]
    set bitfile [glob -nocomplain $BitDir/*.bit]
    write_cfgmem -force -format MCS -interface SPIx4 -loadbit "up 0x0 $bitfile" $BitDir/$PrjName
    puts "MCS file generated successfully! File name: $PrjName.mcs"
}
