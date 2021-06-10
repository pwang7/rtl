`include "../rtl/head.v"

//写数据状态机
module wr_fsm(
          clk        ,//100MHz的时钟信号
          soft_rst_n ,//软复位
          wr_en      ,//写使能
          wr_done    ,//写操作完成信号
          row        ,//行地址
          col        ,//列地址
          ba         ,//Bank地址
          wdata      ,//外部输入的写数据 16bit位宽
          wr_bus     ,//写的地址和命令总线
          dq_out     ,//两个时钟装配后数据输出(32bit位宽) 准备发往SDR 
          out_en      //三态门开关，如果使能的话，把dq_out数据发往SDR_dq上面。写入SDR
);

input clk            ;
input soft_rst_n     ;
input wr_en          ;
input [12:0] row     ;//13bit位宽
input [9:0] col      ;//10bit位宽
input [1:0] ba       ;//Bank地址总线
input [31:0] wdata   ;//Avalon上面过来的写数据(31bit)

output reg wr_done   ; 
output [19:0] wr_bus ;
output reg [15:0] dq_out;
output reg out_en    ;

reg [2:0] cnt        ;
reg [1:0] state      ;

reg [3:0] wr_cmd     ;
reg [12:0] wr_a      ;
reg [1:0] wr_ba      ;
reg wr_cke           ;

parameter s0 = 2'b00;
parameter s1 = 2'b01;
parameter s2 = 2'b11;
parameter s3 = 2'b10;

assign wr_bus = {wr_cmd,wr_a,wr_ba,wr_cke};//组装写数据模块的命令和地址总线

always@(posedge clk) begin
if(!soft_rst_n)begin//同步复位
  wr_done <=  1'b0  ;
  wr_cmd  <=  `NOP  ;
  wr_a    <=  13'b0 ;
  wr_ba   <=  2'b0  ; 
  wr_cke  <=  1'b1  ;
  dq_out  <=  1'b0  ;
  out_en  <=  1'b0  ;
  cnt     <=  3'd0  ;
  state   <=  s0    ;
end
else 
   case(state)
    s0: if(!wr_en)
            state     <= s0            ;
         else begin                     //如果写使能打开
            wr_cmd    <= `ACT          ;//发送激活命令
            wr_a      <= row           ;//发送行地址 
            wr_ba     <= ba            ;//发送Bank地址
            wr_done   <= 0             ;
            state     <= s1            ;
         end
        
    s1: if(cnt < `tRCD - 1)begin        //经过TRCD周期  
            cnt       <= cnt + 1       ;
            wr_cmd    <= `NOP          ;
            state     <= s1            ;
         end
         else begin
            wr_cmd    <= `WR           ;//发送写命令
            wr_a[9:0] <= col           ;//发送列地址
            wr_a[10]  <= 1             ;//自动管理purchage 
            cnt       <= 3'd0          ;
            out_en    <= 1             ;//打开写入SDR的三态门开关
            dq_out    <= wdata[15:0]   ;//装配低16bit数据    
            state     <= s2            ;
         end
         
    s2: begin
            wr_cmd    <= `NOP          ;
            out_en    <= 1             ;//打开写入SDR的三态门开关
            dq_out    <= wdata[31:16]  ;//装配高16bit数据
            state     <= s3            ;
         end
    s3:begin
            wr_done   <= 1'b1          ;
            out_en    <= 1'b0          ;
            state     <= s0            ;
        end
            
    endcase

end


endmodule