`include "../rtl/head.v"

//读状态机
module rd_fsm(
            clk         , //100MHz的时钟线
            capture_clk , //捕获时钟 理论上是180度相位
            soft_rst_n  , //软复位
            rd_en       , //读数据使能
            rd_done     , //完成读出数据操作标志
            row         , //行地址
            col         , //列地址
            ba          , //Bank地址
            rdata       , //读出的数据
            rd_bus      , //读数据模块的总线
            sdr_dq        //从SDR输出的数据
);

input  clk, capture_clk, soft_rst_n ;
input  rd_en                        ;
output reg rd_done                  ;
input  [12:0] row                   ;
input  [9:0]  col                   ;
input  [1:0]  ba                    ;
output wire [31:0] rdata             ;
output [19:0] rd_bus                ;
input  [15:0] sdr_dq                ;

reg    [15:0] dq_cap                ;
reg    [15:0] dq_syn                ;
reg    load_l                       ;
reg    load_h                       ;
reg    [12:0] rd_a                  ;
reg    [1:0]  rd_ba                 ;
reg    [3:0]  rd_cmd                ;
reg    rd_cke                       ;
reg    [5:0]  cnt                   ;
reg    [2:0]  state                 ;

localparam reg[2:0] s0 = 3'b000;
localparam reg[2:0] s1 = 3'b001;
localparam reg[2:0] s2 = 3'b011;
localparam reg[2:0] s3 = 3'b111;
localparam reg[2:0] s4 = 3'b110;

/*================================================*/


assign rd_bus = {rd_cmd, rd_a, rd_ba, rd_cke}; //组装总线

always @ (posedge clk)
begin
    if (!soft_rst_n)//同步复位
        begin
            rd_done <= 0    ;//管理输出端口
            rd_cmd  <= `NOP ;
            rd_a    <= 0    ;
            rd_ba   <= 0    ;
            rd_cke  <= 1    ;
            load_l  <= 0    ;
            load_h  <= 0    ;
            cnt     <= 0    ;
            state   <= s0   ;
        end
    else
        case (state)
            s0: if (!rd_en)
                    state  <= s0   ;
                 else begin //读数据模块打开
                    rd_cmd <= `ACT ; //发送激活命令给SDR
                    rd_a   <= row  ; //发送行地址给SDR
                    rd_ba  <= ba   ; //发送Bank地址给给SDR
                    rd_done<= 0    ;
                    state  <= s1   ;
                 end
            s1: if (cnt < `tRCD - 1) //经过TRCD的周期
                    begin
                        rd_cmd <= `NOP    ;
                        cnt    <= cnt + 1 ;
                        state  <= s1      ;
                    end
                  else begin
                        rd_cmd     <= `RD   ; //发送读数据命令
                        cnt        <= 0     ;
                        rd_ba      <= ba    ; //发送Bank地址
                        rd_a[9:0]  <= col   ; //发送列地址
                        rd_a[10]   <= 1     ; //自动管理purchage
                        state      <= s2    ;
                   end
           s2: if (cnt < `CL + `SL - 1) //经过CL(列选通潜伏期)+SL个周期后
                    begin
                        rd_cmd     <= `NOP    ;
                        cnt        <= cnt + 1 ;
                        state      <= s2      ;
                    end
                  else begin
                        load_l     <= 1       ; //装配低16bit数据
                        cnt        <= 0       ;
                        state      <= s3      ;
                  end
            s3: begin
                        load_l     <= 0       ;
                        load_h     <= 1       ;//装配高16bit数据
                        state      <= s4      ;
                 end
            s4: begin
                        rd_done    <= 1       ; //发出完成读出数据的反馈信号
                        load_h     <= 0       ;
                        state      <= s0      ;
                 end
            default: state <= s0;
        endcase
end

//sdr_dq是来自SDR_CLK时钟域，需要先用capture_clk捕获，理论上SDR_CLK和capture_clk都是180度相位
//此时的sdr_dq数据与capture_clk是中心对齐
always @ (posedge capture_clk)
    begin: CAP_REG
        dq_cap <= sdr_dq;
    end
//此时的dq_cap数据与CLK是中心对齐
always @ (posedge clk)
    begin: SYN_REG
        dq_syn <= dq_cap;
    end

reg [15:0] rdata_lr;
reg [15:0] rdata_hr;
always @ (posedge clk)
    begin:FIT
        if (!soft_rst_n)begin
            rdata_lr <= 16'b0             ;
            rdata_hr <= 16'b0             ;
            end
        else if (load_l) //如果需要装配低16bit数据时候
            rdata_lr <= dq_syn            ;
        else if (load_h) //如果需要装配高16bit数据的时候
            rdata_hr <= dq_syn            ;
    end

assign rdata   = {rdata_hr, rdata_lr}; //rdata再给Avalon总线上的local_rdata，输出到总线上
endmodule
