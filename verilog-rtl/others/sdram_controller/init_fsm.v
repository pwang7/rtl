`include "../rtl/head.v"

//上电模块
module init_fsm(
       clk          ,//输入时钟 100MHz
       soft_rst_n   ,//软复位
       init_en      ,//上电使能
       init_done    ,//完成上电
       init_bus     //命令和地址总线
);

input init_en               ;
input clk                   ;
input soft_rst_n            ;
                            
output reg init_done        ;
output  [19:0] init_bus     ;

reg [12:0] sdr_a            ;
reg [1 :0] sdr_ba           ;
reg [3 :0] sdr_cmd          ;
reg        sdr_cke          ;

assign init_bus = {sdr_cmd,sdr_a,sdr_ba,sdr_cke};//组装总线

reg [15:0] cnt              ;
reg [2 :0] state            ;

//一次只变化一个bit
parameter  IDLE = 3'b000    ;//0
parameter  s0   = 3'b001    ;//1
parameter  s1   = 3'b011    ;//3
parameter  s2   = 3'b010    ;//2
parameter  s3   = 3'b110    ;//6
parameter  s4   = 3'b111    ;//7
parameter  s5   = 3'b101    ;//5


/*
上电过程：
           100us                                         TRP周期                  TRFC周期
电压稳定点 ------> CKE置高电平、NOP命令 ---> 所有Bank预充电--------> 所有Bank预充电-----------> 所有Bank预充电

 TRFC周期              TMRD周期
----------->寄存器配置---------->完成上电初始化操作
 */
always @(posedge clk)begin
if(!soft_rst_n)begin//同步复位
   sdr_a     <= 13'd0   ;
   sdr_ba    <= 2'b00   ;
   sdr_cmd   <= `INH    ;
   sdr_cke   <= 1'b0    ;
   cnt       <= 16'd0   ;
   init_done <= 1'b0    ;//有刷新操作时为0
   state     <= IDLE    ;
end
else 
    case(state)
        IDLE:  if(!init_en)
                 state     <= IDLE;
               else begin //如果使能了刷新模块             
                 init_done <= 1'b0;
                 state     <= s0  ;
               end
               
        s0  :  if(cnt < `T100us -1)begin//间隔100us
                 state <= s0      ;
                 cnt   <= cnt + 1 ;    
               end
               else begin
                 state   <= s1    ;
                 cnt     <= 16'd0 ;
                 sdr_cke <= 1'b1  ;//CKE置高电平
                 sdr_cmd <= `NOP  ;
               end
               
        s1  :  begin
               sdr_cmd   <= `PRE  ;//对所以Bank预充电
               sdr_a[10] <=  1    ;
               state     <=  s2   ;
               end
               
        s2  :  if(cnt < `tRP-1)begin//间隔TRP个周期
                 state  <= s2     ;
                 cnt    <= cnt + 1;
                 sdr_cmd<= `NOP   ;
               end
               else begin
                 state  <= s3     ;
                 cnt    <= 16'd0  ;
                 sdr_cmd<= `REF   ;//刷新命令 
               end
               
        s3  : if(cnt < `tRFC-1)begin//间隔TRFC个周期
                 state  <= s3     ;
                 cnt    <= cnt + 1;
                 sdr_cmd<= `NOP   ;
              end              
              else begin
                 state  <= s4     ;
                 cnt    <= 16'd0  ;
                 sdr_cmd<= `REF   ;//刷新命令
              end
              
        s4  :if(cnt < `tRFC-1)begin//间隔TRFC个周期
                 state  <= s4     ;
                 cnt    <= cnt + 1;
                 sdr_cmd<= `NOP    ;
                 end    
             else begin
                 state  <= s5     ;
                 cnt    <= 16'd0  ;
                 sdr_cmd<= `LMR   ;//寄存器配置命令
                 sdr_a  <= `OP    ;//13根地址线上装载具体配置的参数 突发长度、顺序突发的设置     
             end
        
        s5  :if(cnt < `tMRD -1)begin//间隔tMRD个周期
                 state  <= s5     ;
                 cnt    <= cnt + 1;
                 sdr_cmd<= `NOP   ;
             end
             else begin
                 state     <= IDLE   ;
                 cnt       <= 16'd0  ;
                 init_done <= 1'b1   ;//完成刷新动作
             end
        default:
                state   <= IDLE ;
endcase

end


endmodule