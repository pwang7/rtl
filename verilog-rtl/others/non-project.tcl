cd {~/vivado_projects}

# Define the output directory
set OutputDir ./wavegen_output
file mkdir $OutputDir

# Set basic infomation
set top wave_gen
set part xc7k70tfbg676-1

# Read IP files into memory
read_ip [glob -nocomplain ./ip/*.xcix]
# Synthesis IP if needed
#synth_ip
#generate_target

# Read design files into memory
read_verilog [glob -nocomplain ./src/*.v*]
#read_vhdl
#read_edif
# For verilog include files
set_property FILE_TYPE "Verilog Header" [get_files clogb2.vh]
set_property FILE_TYPE "Verilog Header" [get_files include.v]
set_property IS_GLOBAL_INCLUDE true [get_files include.v]
puts "Design files load successfully"

# Read desing constraint files into memory
read_xdc [glob -nocomplain ./xdc/*.xdc]
puts "Design constrains load successfully"

# Synthesis
synth_desing -part $part -top $top -flatten_hierarchy rebuilt
write_checkpoint -force $OutputDir/${top}_synth.dcp
report_timing_summary -file $OutputDir/post_synth_timing_summary.rpt
report_utilization -file $OutputDir/post_synth_util.rpt

# -no_lc
# Check `using O5 and O6` in utilization report, if >15% of LUT use both O5 and O6,
# then turning off LUT combining with -no_lc, to avoid congestion

# -shreg_min_size NUM
# 该选项设定只有当移位寄存器的长度>NUM时，srl_style才起作用
# (* srl_style = "reg_srl_reg" *) reg[15:0] shift_reg; // Shift Register with srl_style
# srl_style: srl_reg/reg_srl/reg_srl_reg/register/srl

# 综合属性
# (* ram_style = "block" *) reg[15:0] ram;
# (* rom_style = "distributed" *) reg[15:0] rom;
# (* use_dsp48 = "yes/no" *) 可以把多位加减法、累加等也用dsp48来实现，减少逻辑资源消耗
# (* black_box = "yes/no"*) module some_mod();
# (* keep = “true/false” *) wire sig1; // 防止变量被综合优化掉
# (* dout_touch = "true/false" *) wire sig1; // 防止综合、布局布线来优化掉变量
# (* fsm_encoding = "one_hot/sequential/johnson/gray/auto" *) reg[7:0] fsm_state;

# -directive Explore/Default/RuntimeOptimized/Quick
# Explore - high effort
# Default - medium effort
# RuntimeOptimized - low effort
# Quick - quick effort

# 5 strategy groups: Performance/Area/Power/Flow/Congestion


# 只运行实现，需要先读入网表和约束
# Step 1: read in top-level EDIF netlist from Synthesis tool
#read_edif c:/top.edif
#read_edif c:/core1.edif
#read_edif c:/core2.edif
# Step 2: specify target device and merge the netlists into a big one
#link_design -part xc7z020clg400-2 -top top
# Step 3: read XDC constraints to specify timing requirements
#read_xdc c:/top_timing.xdc
#read_xdc c:/top_physical.xdc

# Logic optimization
opt_design -directive Explore
# opt_design -directive ExploreArea # ExploreArea is opt_design only
report_utilization -file $OutputDir/post_opt_util.rpt
report_timing_summary -file $OutputDir/post_opt_timing_summary.rpt
write_checkpoint -force $OutputDir/${top}_opt.dcp

# Place
# For place_design, -directive and other options are exclusive
place_design -directive Explore
write_checkpoint -force $OutputDir/${top}_placed.dcp
report_timing_summary -file $OutputDir/post_place_timing_summary.rpt
report utilization -file $OutputDir/post_place_util.rpt

if {[get_property SLACK [get_timing_paths -max_paths 1 -nworst 1 -setup]] < 0} {
    puts "Found setup timing violations => running physical optimization"
    phys_opt_design
}

# phys_opt_design options:
# -fanout: 高扇出优化
# -placement: 布局优化
# -rewiring: 组合逻辑优化
# -critical cells: 复制关键路径上的模块
# -DSP register: 把寄存器放入或移出DSP48
# -BRAM register: 把寄存器放入或移出BRAM
# -shift register: 移位寄存器用SRL或不用
# -critical pin: 交换LUT的管脚
# -very high fanout: 高扇出的驱动复制
# -BRAM enable: BRAM使能针对功耗优化
# -force net replication: 复制net不管时序余量
# -register retiming: 改变触发器位置来改进组合逻辑延迟
# -hold-fix: 插入数据路径延迟来满足保持时间

# Route
route_design -directive Explore
write_checkpoint -force $OutputDir/${top}_routed.dcp
report_route_status -file $OutputDir/post_route_status.rpt
report_timing_summary -file $OutputDir/post_route_timing_summary.rpt
report utilization -file $OutputDir/post_route_util.rpt
report_drc -file $OutputDir/post_route_drc.rpt

# Post place optimization, to improve placement for worst case timing paths
#place_design -post_place_opt
#phys_opt_design
#route_design

#route_design -delay/-auto_delay -nets $myCritialNets # route for given nets or pin
#route_design -preserve -directive RuntimeOptimized # keep route of previous cmd, and route for others
#route_design -unroute # delete current routes

# 对时序最有帮助的三条命令
#place_design -post_place_opt
#phys_opt_design
#route_design -delay -nets $myCritialNets

# 增量实现
#link_design -part xc7z020clg400-2 -top $revised_top
#opt_design
#read_checkpoint -incremental $reference.dcp
#place_design
# #phys_opt_design # if run in original reference design
#route_design
#report_incremental_reuse -file $OutputDir/routed_reuse.rpt
#report_timing -label_reused # R/NR/PNR/N 复用/没复用/布局复用布线没复用/新的对象
#report_timing_summary -label_reused -max_paths 10 -file $OutputDir/routed_timing_summary.rpt

# BitGen
write_bitstream -force $OutputDir/${top}.bit

# 对增量implement很大的影响：
# RAM大小增加
# 内部总线宽度增加
# 无符号数改为有符号数
# 时序约束改变
# 逻辑层次改变
# 寄存器在组合逻辑中位置改变(register re-timing)

# 增量模式下，如果RTL代码改动要重新综合，如果只是网表改动无须重新综合
# 只有place_design和route_design才有增量模式
# 增量模式下-directive不能用
# 增量模式和参考模式的strategy不能变

# 解决IP被锁定或IP芯片不符问题
# 在内存中单独创建IP工程
create_project -in memory
set_property part <part> [current_project]
read_ip <xci file>
set_property is_locked false [get_files <xci file>] # 解除锁定
generate_target synthesis [get_files <xci file>]
#generate_target all [get_files <xci file>] #指定all也可以
synth_design -top <top name> -part <part>