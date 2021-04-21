# 综合之后着重分析的是逻辑级数、资源利用率和控制集。
# 在综合之后需要分析逻辑级数、资源利用率、时钟拓扑结构、时钟资源利用率和控制集，
# 此外，还要分析BRAM/URAM/DSP的使用是不是最优的（例如，是否使用输出寄存器或者级联寄存器等），这些要素都会影响设计时序。
# 分析的过程是先运行report_qor_assessment，再从中发现Status为REVIEW的条目，接着用相应的命令进一步分析。
#
# 综合要查看的报告
report_high_fanout_nets
report_design_analysis -logic_level_distribution # 逻辑级数分布
report_utilization # LUT：FF数量最好是1:1
report_methodology # RTL DRC
report_drc # DRC
report_clock_utilization [-clock_roots_only] # Clock roots分配
report_cdc
report_synchronizer_mtbf # 7z020不支持

# 自动流水线属性
# autopipeline_module
# autopipeline_group
# autopipeline_include
# autopipeline_limit

# RAM属性
# RAM_DECOMP
# CASCADE_HEIGHT

# 文件编译顺序
report_compile_order
reorder_files # 工程模式下

# 平时的工程中的时序约束：
# 首先是虚拟时钟，这个约束在平时的工程中基本不会用到，像需要设置虚拟时钟的场景，我们也都是通过设计来保证时序收敛，设置虚拟时钟的意义不大。
# 第二就是output delay，在FPGA的最后一级寄存器到输出的路径上，往往都使用了IOB，也就是IO block，因此最后一级寄存器的位置是固定的，从buffer到pad的走线延时是确定的。在这种情况下，是否满足时序要求完全取决于设计，做约束只是验证一下看看时序是否收敛。所以也基本不做。但是input delay是需要的，因为这是上一级器件输出的时序关系。
# 第三个就是多周期路径，我们讲了那么多多周期路径的应用场景，但实际我们是根据Timing report来进行约束的，即便那几种场景都存在，但如果Timing report中没有提示任何的时序 warning，我们往往也不会去添加约束。
# 第四个就是在设置了多周期后，如果还是提示Intra-Clocks Paths的setup time不过，那就要看下程序，是否写的不规范。

# 时序报告Data Path Delay由两部分构成：
# 逻辑延迟（对应图中的logic）：
# 对于7系列FPGA，如果逻辑延迟超过了25%，那么说明时序违例的主要原因是逻辑级数太高了；对于UltraScale系列FPGA，这个指标则为50%。
# 和线延迟（对应图中的route）：
# 对于7系列FPGA，如果线延迟超过了75%，那么说明时序违例的主要原因是线延迟太高了；对于UltraScale系列FPGA，这个指标则为50%。

# 逻辑延迟经验：
# 对于Logic Levels，通常认为1个LUT+1根net的延迟为0.5ns，据此来评估逻辑级数是否过高。例如如果时钟为100MHz，那么逻辑级数在10/0.5=20左右是可以接受的。
# 时钟路径经验：
# 对于Clock Path Skew，如果该值超过了0.5ns，就要关注；
# 对于Clock Uncertainty，如果该时钟是由MMCM或PLL生成，且Discrete Jitter超过了50ps，就要回到Clocking Wizard界面尝试修改参数改善Discrete Jitter。


# STC 经验值：WNS>300ps

# report_design_analysis有三种工作模式：时序分析、复杂度分析和拥塞分析：
report_design_analysis -logic_level_distribution -name logic_level
report_design_analysis -logic_level_distribution -logic_level_dist_paths 100 -name logic_level
# 第一行为逻辑级数，第二行对应数字wei相应的时序路径的个数。选中这个数字，点击鼠标右键，可生成相应的时序报告。
report_design_analysis -complexity -name comp
# 在这个报告中，有三个参数需要格外关注，分别是Rent、Average Fanout和Total Instances。
# 其中Rent指数反映了模块的互连度，该指数越高，互连越重。较重的互连意味着设计会消耗大量的全局布线资源，从而导致布线拥塞。
# Rent值超过0.65或者Average Fanout大于4同时Total Instances 15K时要引起足够关注，很可能会造成布线拥塞。
report_design_analysis -congestion -name cong
# 分析设计的拥塞程度

# 时序约束创建步骤
reset_timing
# 识别时钟源
report_clock_networks
check_timing -override_default no_clock
# 检查时钟约束
report_clocks
check_timing -override_default no_clock
check_timing -override_default unconstrained_internal_endpoints
report_methodology -checks [get_methodology_checks {TIMING-* XDCC-*}]
# 识别端口的时钟
report_timing -from [get_ports PORT_NAME] 
report_timing_summary -report_unconstrained
# 检查IO约束
report_timing -from [all_inputs ] -delay_type min_max 
report_timing -from [all_outputs ] -delay_type min_max 
# 识别跨时钟域
report_clock_interaction
check_timing -override_defaults multiple_clock
report_cdc
# 如果CDC总线使用格雷编码（例如，FIFO）或者如果需要限制1个或多个信号上的2个异步时钟之间的时延，
# 则必须使用set_max_delay约束及-datapath_only选项来忽略这些路径上的时钟偏差和抖动，并覆盖时延要求的默认路径要求
#
# 检查欠缺的时序约束
check_timing -name chk_rpt 
#
# 检查XDC约束之间的覆盖
report_methodology -checks [get_methodology_checks {XDCC-*}]

report_clock_networks / check_timing
report_clocks
report_clock_interaction

# 加紧时序约束
# set_clock_uncertainty是收紧时序约束的安全做法，而不是改变时钟
set_clock_uncertainty -setup 0.3 [get_clocks CLK] # before synthesis
set_clock_uncertainty -setup 0 [get_clocks CLK] # after phys_opt_design or after route

# 时钟相关约束
set_input_jitter
set_system_jitter # 不常用
set_clock_latency
set_external_delay

# 时序约束
create_clock # 差分时钟只约束P端口，不约束N端口
set_input_delay / set_output_delay
set_max_delay / set_min_delay

# Source clock path delay
# Data path delay
# Destination clock path delay

# 建立时间约束不满足，数据延迟太大
# 保持时间约束不满足，时钟延迟太大

# 时钟约束的检查
# Check if there are endpoints that are missing a constraint
check_timing
check_timing –override_defaults no_clock
# Determine the source of missing clocks
check_timing
report_clock_networks
# Validate clock characteristics
report_clocks
report_property [get_clocks wbClk]


# 生成时钟
create_clock -name clkin -period 10 [get_ports clkin]
# Option 1: master clock source is the primary clock source point
create_generated_clock -name clkdiv2 -source [get_ports clkin] -divide_by 2 \
    [get_pins REGA/Q]
# Option 2: master clock source is the REGA clock pin
create_generated_clock -name clkdiv2 -source [get_pins REGA/C] -divide_by 2 \
    [get_pins REGA/Q]
# waveform specified with -edges instead of -divide_by
create_generated_clock -name clkdiv2 -source [get_pins REGA/C] \
    -edges {1 3 5} [get_pins REGA/Q]

# 异步时钟
set_clock_groups –name async_clk0_clk1 –asynchronous \
    –group [get_clocks –include_generated_clocks clk0] \
    –group [get_clocks –include_generated_clocks clk1]
set_clock_groups –name exclusive_clk0_clk1 –physically_exclusive \
    –group clk0 –group clk1

# 输入延迟：对于输入管脚，首先判断捕获时钟是主时钟还是衍生时钟，如果是主时钟，直接用set_input_delay即可，如果是衍生时钟，要先创建虚拟时钟，然后再设置delay。
# 输出延迟：对于输出管脚，判断有没有输出随路时钟，若有，则直接使用set_output_delay，若没有，则需要创建虚拟时钟。

# 输入延迟
create_clock -name sysclk -period 10 [get_ports CLKIN];
set Tco_max 2.4
set TD_max 3.0
set Tco_min 0.9
set TD_min 0.4
set_input_delay -clock sysclk -max [expr {$Tco_max+$TD_max}] [get_ports DIN];
set_input_delay -clock sysclk -min [expr {$Tco_min+$TD_min}] [get_ports DIN];
# DDR输入延迟
set period 10.0;
create_clock -period $period -name clk [get_ports src_sync_ddr_clk];
# 上升沿
set_input_delay -clock clk -max [expr $period/2 - 0.7] [get_ports src_sync_ddr_din[*]];
set_input_delay -clock clk -min 0.6 [get_ports src_sync_ddr_din[*]];
# set_input_delay -max [Period/2 - 下降沿DV_before], -min 上升沿DV_after
# 下降沿
set_input_delay -clock clk -max [expr $period/2 - 0.4] [get_ports src_sync_ddr_din[*]] -clock_fall -add_delay;
set_input_delay -clock clk -min 0.2 [get_ports src_sync_ddr_din[*]] -clock_fall -add_delay;
# set_input_delay -max [Period/2 - 上升沿DV_before], -min 下降沿DV_after

# 输出延迟
create_clock –name sysclk –period 10 [get_ports clkin]
set_output_delay –clock sysclk –max 2 [get_ports dout]
set_output_delay –clock sysclk –min -1 [get_ports dout]
# DDR输出延迟
# 上升沿
set_output_delay –min -1 –clock Clk [get_ports Data_Out]
set_output_delay –max 3 –clock Clk [get_ports Data_Out]
# 下降沿
set_output_delay –min -1 –clock Clk [get_ports Data_Out]\
    -clock_fall –add_delay
set_output_delay –max 3 –clock Clk [get_ports Data_Out]\
    -clock_fall –add_delay

# 输入端口到输入端口的组合逻辑延迟
set_max_delay 15 –from [get_ports din] –to [get_ports dout]

# 虚拟时钟
create_clock -name virtclk -period 10
set_clock_latency -source 1 [get_clocks virtclk] # 虚拟时钟的延迟
set_input_jitter virtclk 0.05 # 虚拟时钟抖动
set_clock_uncertainty


# 用户来指定这类衍生时钟的名字，其余频率等都由 Vivado 自动推导
create_generated_clock -name my_clk_name [get_pins mmcm0/CLKOUT] \
    -source [get_pins mmcm0/CLKIN] \
    -master_clock main_clk

# 用户自定义的衍生时钟
create_generated_clock -name clk2 [get_pins REGA/Q] \
    -source [get_ports CKP1] -divide_by 1 \
    -invert

# 所有衍生钟自动跟其主时钟一组，从而与其它组的时钟之间为异步关系
set_clock_groups -name sys_ss_async –asynchronous \
    -group [get_clocks -include_generated_clocks sysclk] \
    -group [get_clocks -include_generated_clocks ssclkin]

# 同一端口创建多个时钟，-add
# set_clock_groups -async/–physically_exclusive/-logically_exclusive
create_generated_clock -name clk125_bufgctrl \
    -divide_by 1 [get_pins bufgctrl_i/O] \
    -source [get_ports bufgctrl_i/I0]
create_generated_clock -name clk250_bufgctrl \
    -divide_by 1 [get_pins bufgctrl_i/O] \
    -source [get_ports bufgctrl_i/I1] \
    -add -master_clock clk250
set_clock_groups –physically_exclusive \
    –group clk125_bufgctrl \
    –group clk250_bufgctrl

# 虚拟时钟
create_clock -period 20 -name clk_50_virtual

# 异步FIFO读写地址之间CDC约束
set_max_delay-from [get_cells ……/rd_pntr_gc_reg[*]] -to [get_cells ……/Q_reg_reg[*]] \
    -datapath_only [get_property PERIOD $rd_clock]
set_max_delay[get_property PERIOD $rd_clock]-from [get_cells ……/wr_pntr_gc_reg[*]] -to [get_cells ……/Q_reg_reg[*]] \
    -datapath_only[get_property PERIOD $wr_clock]


# 多周期路径
# 单时钟域多周期路径/同步时钟的跨时钟域
# set_multicycle_path语句中数字的含义：
# 对于-setup：表示该多周期路径所需要的时钟周期个数；
# 对于-hold：表示相对于缺省捕获沿（图中的Defaulthold）,实际捕获沿（图中的Newhold）应回调的时钟周期个数
# 参考时钟周期的选取：
# -end表示参考时钟为捕获端（收端）所用时钟，对于-setup缺省为-end
# -start表示参考时钟为发送端（发端）所用时钟，对于-hold缺省为-start

set_multicycle_path -from [get_clocks clk1] -to [get_clocks clk2] -setup -end 2
set_multicycle_path -from [get_clocks clk1] -to [get_clocks clk2] -hold -start 1

# 同频不同相/正偏移的时序约束，仅约束建立时间，无须约束保持时间
set mylowpin_start [get_pins i_mycdc_low2f/q_reg/C]
set mylowpin_end [get_pins i_mycdc_low2f/q_reg/D]
set_multicycle_path -from $mylowpin_start -to $mylowpin_end -setup -end 2

# 同频不同相/负偏移的时序约束，无须约束

# 多周期路径，选快时钟为参考时钟，当发端和收端时钟一样可以省略-start/-end

# 慢时钟->快时钟，接收时钟频率是发送时钟频率的整数倍，同相位
set mylowpin_start [get_pins i_mycdc_low2f/q_reg/C]
set mylowpin_end [get_pins i_mycdc_low2f/q_reg/D]
set_multicycle_path -from $mylowpin_start -to $mylowpin_end -setup -end 2
set_multicycle_path -from $mylowpin_start -to $mylowpin_end -hold -end 1

# 慢时钟->快时钟，接收时钟频率是发送时钟频率的整数倍，不同相位
set mylowpin_start [get_pins i_mycdc_low2f/q_reg/C]
set mylowpin_end [get_pins i_mycdc_low2f/q_reg/D]
set_multicycle_path -from $mylowpin_start -to $mylowpin_end -setup -end 3
set_multicycle_path -from $mylowpin_start -to $mylowpin_end -hold -end 1

# 快时钟->慢时钟，发送时钟频率是接收时钟频率的整数倍，同相位
set mylowpin_start [get_pins i_mycdc_low2f/q_reg/C]
set mylowpin_end [get_pins i_mycdc_low2f/q_reg/D]
set_multicycle_path -from $mylowpin_start -to $mylowpin_end -setup -start 2
set_multicycle_path -from $mylowpin_start -to $mylowpin_end -hold -start 1

# 快时钟->慢时钟，发送时钟频率是接收时钟频率的整数倍，不同相位/正偏移
set mylowpin_start [get_pins i_mycdc_low2f/q_reg/C]
set mylowpin_end [get_pins i_mycdc_low2f/q_reg/D]
set_multicycle_path -from $mylowpin_start -to $mylowpin_end -setup -start 3
set_multicycle_path -from $mylowpin_start -to $mylowpin_end -hold -start 1

# 多周期路径总结如下
# 单时钟域
set_multicycle_path -from [get_pins PIN_NAME] -to [get_pins PIN_NAME] N -setup
set_multicycle_path -from [get_pins PIN_NAME] -to [get_pins PIN_NAME] N-1 -hold
# 慢时钟到快时钟
set_multicycle_path -from [get_clocks clk1] -to [get_clocks clk2] N -setup
set_multicycle_path -from [get_clocks clk1] -to [get_clocks clk2] N-1 -hold -end
# 快时钟到慢时钟
set_multicycle_path -from [get_clocks clk1] -to [get_clocks clk2] N -setup -start
set_multicycle_path -from [get_clocks clk1] -to [get_clocks clk2] N-1 -hold



# 在XDC中设置ASYNC_REG属性
set_property ASYNC_REG TRUE [get_cells sync_rega]
set_property ASYNC_REG TRUE [get_cells sync_regb]


# 伪路径一般用于：
# - 跨时钟域
# - 一上电就被写入数据的寄存器
# - 异步复位或测试逻辑
# - 异步双端口RAM
# 异步复位同步释放的路径设为伪路径，CDC路径不要设为伪路径而用set_clock_groups
set_false_path -to [get_pins -hier -filter {NAME =~ */rst_ref_sync*/PRE}]



# Tcl UG835

# 过滤出所有有问题的约束
write_xdc -constraints invalid ~/bad_constraints.xdc

# 帮助
help get_cells -args/-syntax

# 常用Tcl命令选项
get_cells/get_nets/get_pins -hier/-filter/-of/-regexp/-nocase
get_ports/get_clocks -filter/-of/-regexp/-nocase

get_selected_objects # 使用示例：set MYCELL [get_cells [get_selected_objects]]

# 常用报告：timing/utilization/power
report_timing_summary
report_timing -slack_lesser_than
report_utilization -hier -cells [get_cells usbEngine0/u1]
report_clock_utilization
report_high_fanout_nets -timing -min_fanout 500 -load_types -max_nets 100
report_control_sets -verbose -sort_by {clk set}
report_cdc
report_drc
report_power_opt
report_ip_status
report_route_status
report_design_analysis
report_compile_order -constraints
report_clock_networks
report_clock_interaction
report_datasheet
report_power
report_property [current_project]
report_methodology # DRC

# 查看锁存器
all_latches

# 常用报告命令
# Various reports generated by Vivado GUI
–Report timing summary:report_timing_summary
–Report clock interaction:report_clock_interaction
–Report utilization:report_utilization
–Report Power:report_power
# Other useful reports generated by Vivado TCL
–Report clocks:report_clocks
–Report clock utilization:report_clock_utilization
–Report timing for custormerized path:report_timing
–Report high fanout nets:report_high_fanout_nets
–Report control sets:report_control_sets
–Report IP status:report_ip_status
–Report power optimizations:report_power_opt
–Report design analysis:report_design_analysis
–Report cross domain clocks:report_cdc

# Tcl store
xilinx::designutils::check_cdc_paths
