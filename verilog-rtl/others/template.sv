`default_nettype none

// Setup Slack = Tcycle + Tclk2 - Tsu - (Tclk1 + Tco + Tdata)
// Hold Slack = Tcycle + Tclk1 + Tco + Tdata - (Tcycle + Tclk2 + Th)

// 组合逻辑：多路器、加法器、缓冲器、逻辑开关、总线、逻辑运算电路
// 时序逻辑：计数器、同步有限状态机、运算控制器、总线分配器

// FDCE/FDPE: sync-en, async-rst/set
// FDRE/FDSE: sync-en, sync-rst/set


// set_param general.maxThreads 16
// set_property IOB TRUE [get_ports eth_mdio]

/*
reg clk = 0;
always @(clk) begin #50 clk = ~clk; end
always @(clk) begin #50; clk = ~clk; end
always @(clk) begin clk = #50 ~clk; end
always begin #50 clk = ~clk; end

always @(clk) begin #50 clk <= ~clk; end
always @(clk) begin #50; clk <= ~clk; end
always @(clk) begin clk <= #50 ~clk; end

initial begin clk <= 0; forever clk = #50 ~clk; end
initial begin clk <= 0; forever #50 clk = ~clk; end
initial begin clk <= 0; forever clk <= #50 ~clk; end
initial begin clk <= 0; forever #50 clk <= ~clk; end
*/

/*
D Flip-Flop
D	Q
0	0
1	1

T Flip-Flop
T	Q
0	Q
1	Q'

J-K Flip-Flop
J	K	Q
0	0	Q
0	1	0
1	0	1
1	1	Q'

S-R Flip-Flop
S	R	Q
0	0	Q
0	1	0
1	0	1
1	1	?
*/

/*
1)时序电路建模时，用非阻塞赋值。
2)锁存器电路建模时，用非阻塞赋值。
3)用 always 块建立组合逻辑模型时，用阻塞赋值。
4)在同一个 always 块中建立时序和组合逻辑电路时，用非阻塞赋值。
5)在同一个 always 块中不要既用非阻塞赋值又用阻塞赋值。
6)不要在一个以上的 always 块中为同一个变量赋值。
7)用$strobe 系统任务来显示用非阻塞赋值的变量值。
8)在赋值时不要使用 #0 延迟。
*/

/*
assert ($isunknown(sel)) else $error("sel=X");

program automatic test;
    class Bad;
        rand bit [7:0] a, b;
        constraint ab { a < b; b < a ;} // this constraint cannot be solved
    endclass
    initial begin
        Bad b = new;
        assert(b.randomize()) else $fatal; // checking if randomize fails
    end
endprogram
*/
module counter_binary(
    input wire clk,
    input wire reset,
    input wire counter_binary_en,
    output reg [31:0] counter_binary,
    output reg counter_binary_match
    );
parameter MATCH_PATTERN = 32;
always @(posedge clk)
    if(reset) begin
        counter_binary<= 'b0;
        counter_binary_match <= 1'b0;
    end
    else begin
        counter_binary<= counter_binary_en? counter_binary + 1'b1: counter_binary;
        counter_binary_match <= counter_binary == MATCH_PATTERN;
    end

// fork-join example
initial begin
    fork
        my_task1();
        my_task1();
    join
end

event DONE;
task my_task1();
    @(DONE);
    $display("event received");
endtask

task my_task2();
    ->DONE;
    $display("event sent");
endtask

endmodule

module template;
reg clk, rst_n;
reg [7:0] cnt, cnt0, cnt1, out1;
reg X, Y, Z;

// 结构法：后一级计数器的加1条件依赖前一级计数器的结束条件
// 变量法：变量X用组合逻辑
// 计数器：数什么，数多少
// 加1条件不足时，添加flag_add信号，flag_add变1条件变0条件 
wire add_cnt, end_cnt;
always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cnt <= '0;
    end
    else if (add_cnt) begin
        if (end_cnt)
            cnt <= '0;
        else
            cnt <= cnt + 1'b1;
    end
end
assign add_cnt = Z;
assign end_cnt = add_cnt && cnt == X - 1;

reg en, flag_add;
always @ (posedge clk or negedge rst_n) begin
    if (!rst_n)
        flag_add <= 0;
    else if (en)
        flag_add <= 1;
    else if (end_cnt)
        flag_add <= 0;
end

// Structural counter
wire add_cnt0, end_cnt0;
always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cnt0 <= 0;
    end
    else if (add_cnt0) begin
        if (end_cnt0)
            cnt0 <= 0;
        else
            cnt0 <= cnt0 + 1'b1;
    end
end
assign add_cnt0 = flag_add;
assign end_cnt0 = add_cnt0 && cnt0 == X - 1;

wire add_cnt1, end_cnt1;
always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cnt1 <= 0;
    end
    else if (add_cnt1) begin
        if (end_cnt1)
            cnt1 <= 0;
        else
            cnt1 <= cnt1 + 1'b1;
    end
end
assign add_cnt1 = end_cnt0;
assign end_cnt1 = add_cnt1 && cnt1 == Y - 1;

/*
// 嵌套循环给矩阵求和
reg [(X * Y * Z -1):0] array;
always @ (posedge clk or negedge rst_n) begin
    if (!rst_n)
        flag_add <= 0;
    else if (add_cnt0)
        sum <= sum + array[(cnt1*X*Z + cnt0*Z + Z - 1)-:Z]
end

// 冒泡排序
reg [width-1:0] vec [0:length-1];
always @ (*) begin
    X = length - 1 - cnt1;
    Y = length - 1;
end
always @ (posedge clk or negedge rst_n) begin
    if (!rst_n)
        vec <= 0;
    else if (add_cnt0 && vec[cnt0] < vec[cnt0 + 1]) begin
        vec[cnt0] <= vec[cnt0 + 1];
        vec[cnt0 + 1] <= vec[cnt0];
    end
end

// C代码转Verilog，分别看每个变量在每个周期的最终结果
// C是串行执行关注过程，Verilog只关心每个周期的变量的结果
*/

/*
// moore_regular_template.v
module moore_regular_template#(
    parameter param1: <value>,
            param2 : <value>
)(
    input wire clk, reset,
    input wire [<size>] input1, input2, ...,
    output reg [<size>] output1, output2
    );
localparam [<size_state>] // for 4 states : size_state = 1:0
            s0 = 0,s1 = 1,s2 = 2,... ;
reg[<size_state>] state_reg, state_next; 

// state register : state_reg
// This process contains sequential part and all the D-FF are
// included in this process. Hence, only 'clk' and 'reset' are
// required for this process.
always @(posedge clk, posedge reset) begin
    if (reset) begin
        state_reg <= s1;
    end
    else begin
        state_reg <= state_next;
    end
end

// next state logic : state_next
// This is combinational of the sequential design,
// which contains the logic for next-state
// include all signals and input in sensitive-list except state_next
always @(input1, input2, state_reg) begin
    state_next = state_reg; // default state_next
    case (state_reg)
        s0 : begin
            if (<condition>) begin // if (input1 = 2'b01) then
                state_next = s1;
            end
            else if (<condition>) begin // add all the required condition
                state_next = ...;
            end
            else begin // remain in current state
                state_next = s0;
            end
        end
        s1 : begin
            if (<condition>) begin // if (input1 = 2'b10) then
                state_next = s2;
            end
            else if (<condition>) begin // add all the required condition
                state_next = ...;
            end
            else begin// remain in current state
                state_next = s1;
            end
        end
        s2 : begin
            ...
        end
    endcase
end
// combination output logic
// This part contains the output of the design
// no if-else statement is used in this part
// include all signals and input in sensitive-list except state_next
always @(input1, input2, ..., state_reg) begin
    // default outputs
    output1 = <value>;output2 = <value>;
    ...
    case (state_reg)
        s0 : begin
            output1 = <value>;
            output2 = <value>;
            ...
        end
        s1 : begin
            output1 = <value>;
            output2 = <value>;
            ...
        end
        s2 : begin...end
    endcase
end

// optional D-FF to remove glitches
always @(posedge clk, posedge reset) begin
    if (reset) begin
        new_output1 <= ... ;
        new_output2 <= ... ;
    end
    else begin
        new_output1 <= output1;
        new_output2 <= output2;
    end
end
endmodule

// mealy_regular_template.v
module mealy_regular_template #(
    parameter param1 = <value>,
                param2 = <value>
)(
    input wire clk, reset,
    input wire [<size>] input1, input2, ...,
    output reg [<size>] output1, output2
    );
localparam [<size_state>] // for 4 states : size_state = 1:0
            s0 = 0,s1 = 1,s2 = 2,... ;
reg[<size_state>] state_reg, state_next;

// state register : state_reg
// This `always block' contains sequential part and all the D-FF are
// included in this process. Hence, only 'clk' and 'reset' are
// required for this process.
always(posedge clk, posedge reset) begin
    if (reset) begin
        state_reg <= s1;
    end
    else begin
        state_reg <= state_next;
    end
end

// next state logic and outputs
// This is combinational part of the sequential design,
// which contains the logic for next-state and outputs
// include all signals and input in sensitive-list except state_next
always @(input1, input2, ..., state_reg) begin
    state_next = state_reg; // default state_next
    // default outputs
    output1 = <value>;
    output2 = <value>;
    ...
    case (state_reg)
        s0 : begin
            if (<condition>) begin // if (input1 == 2'b01) then
                output1 = <value>;
                output2 = <value>;
                ...
                state_next = s1;
            end
            else if <condition> begin // add all the required condition
                output1 = <value>;
                output2 = <value>;
                ...
                state_next = ...;
            end
            else begin // remain in current state
                output1 = <value>;
                output2 = <value>;
                ...
                state_next = s0;
            end
        end
        s1 : begin
            ...
        end
    endcase
end

// optional D-FF to remove glitches
always(posedge clk, posedge reset) begin
    if (reset) begin
        new_output1 <= ... ;
        new_output2 <= ... ;
    else begin
        new_output1 <= output1;
        new_output2 <= output2;
    end
end
endmodule
*/

// State machine

enum data_type { IDLE, S1, S2 } state_c, state_n;

always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state_c <= IDLE;
    end
    else begin
        state_c <= state_n;
    end
end

wire idle2s1_start, s12s2_start, s22idl_start;
always @ (*) begin
    (* full_case = 1, parallel_case = 1 *)
    case(state_c)
        IDLE: begin
            if (idle2s1_start) begin
                state_n = S1;
            end
            else begin
                state_n = state_c;
            end
        end
        S1: begin
            if (s12s2_start) begin
                state_n = S2;
            end
            else begin
                state_n = state_c;
            end
        end
        S2: begin
            if (s22idl_start) begin
                state_n = IDLE;
            end
            else begin
                state_n = state_c;
            end
        end
        default: begin
            state_n = IDLE;
        end
    endcase
end

assign idle2s1_start = state_c == IDLE && X;
assign s12s2_start   = state_c == S1   && Y;
assign s22idl_start  = state_c == S2   && Z;

// state_str is an ASCII representation of state_c
reg [1:11*8] state_str; // current state shown as ASCII
always @(*) begin
    state_str = "";
    case (state_c)
        IDLE: state_str = "STATE_IDLE";
        S1: state_str = "STATE_S1";
        S2: state_str = "STATE_S2";
        default: state_str = "-";
    endcase
end

always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out1 <= 1'b0;
    end
    else if (state_n == S1) begin
        out1 <= 1'b1;
    end
    else begin
        out1 <= 1'b0;
    end
end

endmodule


// Test bench

module gen_clk_rst (
    output reg clk,
    output reg rst_n
    );

    localparam PERIOD = 1;
    localparam RST_CYCLE = 2;
    initial begin
        clk=0;
        rst_n = 0;
        repeat (RST_CYCLE) @(negedge clk);
        rst_n = 1;
    end

	always #(PERIOD * 0.5)  clk = ~clk;

    // always @(clk) #10 clk = ~clk;
    // always @(clk) #10 clk <= ~clk;
    // always @(clk) clk <= #10 ~clk;
endmodule

module tb0();
    wire clk, rst_n;
    gen_clk_rst u_gen_clk_rst(.clk(clk), .rst_n(rst_n));

    initial begin
        wait (rst_n == 1);
        @(negedge clk);
    end
endmodule

module tb1;
    parameter CYCLE = 4;
    parameter RST_TIME = 3;

    reg clk, rst_n;
    initial begin
        clk = 0;
        forever #(CYCLE/2) clk = ~clk;
    end

    initial begin
        rst_n = 1;
        #2;
        rst_n = 0;
        #(CYCLE*RST_TIME)
        rst_n = 1;
    end

    initial begin
        $dumpfile("wave.vcd");        // generate vcd file
        $dumpvars;
    end

    reg din;
    initial begin
        #1;
        din = 0;
        #(10*CYCLE);
        din = 1;
    end

    // FIFO
    // 是否要报文为单位？
    // 是否有优先级？
    // 是否要收到整个报文才开始？

    initial $monitor($time, "output q=%d", q);

    // '1 is a special literal syntax for a number with all bits set to 1.
    // '0, 'x, and 'z are also valid.
endmodule

module tb2;
    reg clk;
    reg value;

    initial begin
        clk = 0;  // clock generation
        forever #10 clk = ~clk;
    end

    initial begin
        @(posedge clk);
        while(value == 0) @(posedge clk);
        repeat(100) @(posedge clk);

        $stop;
        $finish;
    end
endmodule

// CRC generation:
// https://www.easics.com/crctool/

/*
// XDC

// Constrain ordering
## Timing Assertions Section
# Primary clocks
# Virtual clocks
# Generated clocks
# Clock Groups
# Input and output delay constraints

## Timing Exceptions Section
# False Paths
# Max Delay / Min Delay
# Multicycle Paths
# Case Analysis
# Disable Timing

## Physical Constraints Section


// Constrain for registers sync-ing async signal
set_property ASYNC_REG TRUE [get_cells [list sync0_reg sync1_reg]]

// Async clocks
set_clock_groups -name sys_ss_async –asynchronous \
    -group [get_clocks -include_generated_clocks sysclk] \
    -group [get_clocks -include_generated_clocks ssclkin]

// Overlapped but exclusive clocks
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

// Multiple phys_opt_design
synth_design
opt_design
place_design
phys_opt_design -directive AggressiveExplore
phys_opt_design -directive AggressiveFanoutOpt
phys_opt_design -force_replication_on_nets $highfanout_nets
phys_opt_design -retime
route_design
phys_opt_design

// Post place optimiztion
synth_design
opt_design
place_design
phys_opt_design
route_design
for {set i 0} {$i<=3} {incr i} {
    place_design -post_place_opt
    route_design
    report_timing_summary -file $i.rpt
    write_checkpoint -force post_place_opted.dcp
}

// Timing report
report_timing_summary -file $i.rpt # report_timing、report_clocks 、check_timing 
report_timing
get_timing_paths

// Checkpoint
open_checkpoint
write_checkpoint
read_checkpoint

// Incremental design flow
read_checkpoint -incremental

// Async FIFO constrains
set_max_delay-from [get_cells ……/rd_pntr_gc_reg[*]] -to [get_cells ……/Q_reg_reg[*]] \
    -datapath_only [get_property PERIOD $rd_clock]
set_max_delay[get_property PERIOD $rd_clock]-from [get_cells ……/wr_pntr_gc_reg[*]] -to [get_cells ……/Q_reg_reg[*]] \
    -datapath_only [get_property PERIOD $wr_clock]
*/


/*
硬件仿真加速器emulation
CLK pin -> D
Input Port -> D
CLK pin -> Output Port
Input Port -> Output Port
*/

/*
// Design Net Port Pin Clock Reference Cell
// TCL
sizeof_collection [all_clocks]
get_ports CLK
get_ports SPI
get_ports *
get_ports C*

get_cells U3|*|*3

get_nets INV*|*
llength [get_object_name [get_nets *]] // TCL internal
sizeof_collection [get_nets *] // Sysnops

get_pins *Z|Q*

// Cell属性
get_attribute [get_cell -h U3] ref_name
get_attribute [get_cell -h U2/A] owner_net

// Port属性
get_attribute [get_ports A] direction
get_attribute [get_ports OUT[1]] direction

// Net属性
get_attribute [get_nets INVO] full_name
get_object_name [get_nets INVO]

// -f 可以过滤属性
get_ports * -f "direction==in"
get_pins * -f "direction==out"
get_cell * -f "ref_name==INV"

// -of 得到指定object相连接的object
get_nets -of [get_port A]
get_net -of [get_pin U2/A]
get_pin -of [get_net INV1]
get_pins -of [get_cell U4]

*/

/*
// 综合阶段，不综合时钟网络
create_clock -name sysclk -period 10 [get_ports CLK];
set_dont_touch_network [get_clocks CLK]
set_input_delay -max 4 -clock CLK [get_ports A]
set_output_delay -max 4 -clock CLK [get_ports B]
-max 建立时间
-min 保持时间

// 系统同步
Period=5ns
// 器件延迟
Tcko-MAX=2ns
Tcko-MIN=1ns
// 线路延迟
T_trace(min)=0.3ns
T_trace(max)=0.4ns

create_clock -name sysclk -period 10 [get_ports CLK];
set_input_delay -clock sysclk -max 2.4 [get_ports DIN];
set_input_delay -clock sysclk -min 1.3 [get_ports DIN];


// 源同步SDR

//
Period=5ns
// 器件延迟，通过查手册得知
Tcko-MAX=3ns
Tcko-MIN=2ns

create_clock -name sysclk -period 5 [get_ports CLK];
set_input_delay -clock sysclk -max 3 [get_ports DIN];
set_input_delay -clock sysclk -min 2 [get_ports DIN];
# set_input_delay -max Tcko-MAX, -min Tcko-MIN

// 示波器测量
Period=5ns
DV_before=2ns
DV_after=2ns

create_clock -name sysclk -period 5 [get_ports CLK];
set_input_delay -clock sysclk -max 3 [get_ports DIN];
set_input_delay -clock sysclk -min 2 [get_ports DIN];
# set_input_delay -max (Period - DV_before), -min DV_after

// DDR源同步中心同步
// 示波器测量
上升沿DV_before=0.4ns
上升沿DV_after=0.6ns
下降沿DV_before=0.7ns
下降沿DV_after=0.2ns

set period 10.0;
create_clock -period $period -name clk [get_ports src_sync_ddr_clk];
//上升沿
set_input_delay -clock clk -max [expr $period/2 - 0.7] [get_ports src_sync_ddr_din[*]];
set_input_delay -clock clk -min 0.6 [get_ports src_sync_ddr_din[*]];
# set_input_delay -max [Period/2 - 下降沿DV_before], -min 上升沿DV_after
//下降沿
set_input_delay -clock clk -max [expr $period/2 - 0.4] [get_ports src_sync_ddr_din[*]] -clock_fall -add_delay;
set_input_delay -clock clk -min 0.2 [get_ports src_sync_ddr_din[*]] -clock_fall -add_delay;
# set_input_delay -max [Period/2 - 上升沿DV_before], -min 下降沿DV_after

// DDR源同步边沿对齐
上升沿skew_brefore=0.6ns
上升沿skew_after=0.4ns
下降沿skew_before=0.3ns
下降沿skew_after=0.7ns

create_clock -name clk -period 10 [get_ports src_sync_ddr_clk];
set_input_delay -clock clk -max 0.4 [get_ports src_sync_ddr_clk[*]];
set_input_delay -clock clk -min -0.6 [get_ports src_sync_ddr_clk[*]];
set_input_delay -clock clk -max 0.7 [get_ports src_sync_ddr_clk[*]] -clock_fall -add_delay;
set_input_delay -clock clk -min -0.3 [get_ports src_sync_ddr_clk[*]] -clock_fall -add_delay;

// 有数据无时钟，设置虚拟时钟
create_clock -name clk_100 -period 10 [get_ports i_clk_100MHz];
create_clock -name clk_50_virtual -period 20;
set_input_delay -max 5.2 -min 2.0 -clock clk_50_virtual [get_ports i_data_50];

*/
