# DCP includes netlist (EDIF), constraints (XDC), physical data (XDEF)
# DCP generated at synth, opt, place, route
# Add or Create Design Source <- DCP
# Add Existing IP <- XCI

set OutputDir [get_property DIRECTORY [current_project]]
set ProjName [get_property NAME [current_project]]

# 查看IP的约束与工程的约束的编译顺序
report_compile_order -constraints

# 打开IP名为char_fifo的例子工程
open_example_project [get_ips char_fifo]

# 查看IP的属性，诸如IP版本是否被锁定、IP的综合方式OOC或Global
report_ip_status -name char_fifo
report_property [get_ips char_fifo]

# Get a list of IPs in the current design
get_ips
# Generate target data for the specified source
generate_target
# Reset target data for the specified source
reset_target
# Upgrade a configurable IP to a later version
upgrade_ip

report_property [current_project ]
set_property TARGET_LANGUAGE VHDL [current_project]

# XSIM编译好的针对第三方仿真工具的库
<Vivado_Install_Dir>/data/xsim/xsim.ini

# 仿真
set MYVARS [get_objects VARNAME_???_*]
log_wave $MYVARS
resart
run 10us
# Open new wave window
add_wave $MYWARS
close_sim -force

# 静态仿真
# Flow->Open Static Simulation...

# 为第三方仿真工具编译库
set target_dir {E:\Xilinx\Xlib}
set sim_exec_path {E:\modeltech64_10.2\win64}
compile_simlib -directory $target_dir -family all -language all -library all \
    -simulator modelsim -simulator_exec_path $sim_exec_path # -32bit

# Multiple runs
# Flow->Create Runs...
open_run impl_2
current_run [get_runs synth_1]
current_design # run result is call design
delete_run synth_2

# -to_step opt_design/power_opt_design/place_design/"power_opt_design (post_place)"/phys_opt_design/route_design/write_bitstream
launch_runs impl_1 -to_step place_design
launch_runs impl_1 -next_step

# 增量实现
set_property INCREMENTAL_CHECKPOINT reference.dcp [get_runs impl_2]
get_property INCREMENTAL_CHECKPOINT [current_run]
reset_property # 取消增量实现

# 查看特定对象是否重用
set myReusedObj [get_cells -hier -filter "IS_REUSED == TRUE"]
set myReusedObj [get_nets -hier -filter "IS_REUSED == TRUE"]
set myReusedObj [get_pins -hier -filter "IS_REUSED == TRUE"]
report_property [lindex $myReusedObj 0]

# Place Design / Pre-Placement Incremental Reuse Report
# Place Design / Incremental Reuse Report
# Route Design / Incremental Reuse Report

# 常用快捷键
C-Q 打开关闭Flow Navigator
C-E 打开选中对象的属性窗口
F4 打开选中对象的网表视图
F6 打开选中对象的层次视图
F7 打开选中对象的RTL代码
F11 运行综合
F12: Unselect all

# Tcl与Vivado交互
get_selected_objects
select_objects # 然后F4
unselect_objects

launch_runs synth_1
launch_runs impl_1
launch_runs impl_1 -to_step write_bitstream

# 创建工程
create_project waveprj G:/Vivado/wavegen/waveprj \
    -part xc7k325tffg900-2
create_project –name waveprj –dir G:/Vivado/wavegen/waveprj \
    -part xc7z020clg400-2
set_property target_language Verilog [current_project]
set_property source_mgmt_mode DisplayOnly [current_project]
# source_mgmt_mode:
# All: Automatic Update and Compile Order
# DisplayOnly: Automatic Update, Manual Compile Order
# None: No Update, Manual Compile Order

# 添加源文件、仿真文件、约束文件、IP文件
# import_files会拷贝文件
# Add design source files
add_files -fileset sources_1 ./src
update_compile_order -fileset sources_1
# Add simulation source files
add_files -fileset sim_1 ./sim
update_compile_order -fileset sim_1
# Add constraints files
add_files -fileset constrs_1 ./xdc
# Add existing IPs
add_files [glob ./ip/*/*.xci]
update_compile_order -fileset sources_1

# 综合设置
# Set the value of FLATTEN_HIERARCHY
set_property STEPS.SYNTH_DESIGN.ARGS.FLATTEN_HIERARCHY rebuilt \
    [get_runs synth_1]
# Set the module as OOC
create_fileset -blockset -define_from dac_spi dac_spi
# Create new synthesis run
create_run synth_2 -flow {Vivado Synthesis 2014} \
    -strategy {Vivado Synthesis Defaults}

# 运行综合
launch_runs synth_1
wait_on_run synth_1
# Check synthesis result
open_run synth_1
get_timing_paths -slack_lesser_than 0 -quiet

# 综合后要设置BitStream文件属性
set_property BITSTREAM.CONFIG.CONFIGRATE 66 [get_designs synth_2]
set_property CONFIG_VOLTAGE 1.8 [get_designs synth_2]
set_property CFGBVS GND [get_designs synth_2]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [get_designs synth_2] # SPI位宽
set_property config_mode SPIx4 [current_design]

# 运行实现
# Select the desired strategy
set_property strategy Performance_Explore [get_runs impl_1]
# Enable or Disable intermediate flow
set_property STEPS.PHYS_OPT_DESIGN.IS_ENABLED true [get_runs impl_4]
set_property STEPS.OPT_DESIGN.ARGS.DIRECTIVE AddRemap \
    [get_runs impl_4]
launch_runs impl_1
wait_on_run impl_1

# 生成BitStream
launch_runs impl_1 -to_step write_bitstream
wait_on_run impl_1
set_property STEPS.WRITE_BITSTREAM.ARGS.BIN_FILE true \
    [get_runs impl_1]
launch_runs impl_1 -to_step write_bitstream
wait_on_run impl_1
# 生成Memory Config文件
write_cfgmem -force -format MCS -interface SPIx4 -loadbit \
    "up 0x0 G:/Vivado/wavegen/waveprj/waveprj.runs/impl_2/wave_gen.bit" \
    G:/Vivado/wavegen/waveprj/waveprj.runs/impl_2/wave_gen_impl_2

# 查看分析报告前要打开Design
get_runs
open_run impl_1
report_timing




# 将所有输出端口的寄存器放到IBO内
set_property IOB true [all_fanout -flat -endpoints_only -only_cells [all_inputs]]
set_property IOB true [all_inputs]
# 将所有输入端口的寄存器放到IBO内
set_property IOB true [all_fanin -flat -startpoints_only -only_cells [all_outputs]]
set_property IOB true [all_outputs]