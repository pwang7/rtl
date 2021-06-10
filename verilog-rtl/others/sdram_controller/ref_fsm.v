`include "../rtl/head.v"

//刷新模块
module ref_fsm(
      ref_done    ,//完成刷新操作
      ref_en      ,//使能刷新
      clk         ,//输入100MHz时钟
      ref_bus     ,//刷新模块的bus
      soft_rst_n  ,//软复位
);

input ref_en         ;
input clk            ;
input soft_rst_n     ;
output reg ref_done  ;
output [19:0] ref_bus;

reg [12:0] ref_a     ;
reg [1 :0] ref_ba    ;
reg [3 :0] ref_cmd   ;
reg        ref_cke   ;

assign ref_bus = {ref_cmd,ref_a,ref_ba,ref_cke};//组装刷新的命令和地址总线

reg [14:0] cnt   ;
reg [1 :0] state ;

parameter s0 = 2'b00;
parameter s1 = 2'b01;
parameter s2 = 2'b11;


/*
刷新过程(固定时钟周期内进行一次刷新，保证电容电量得到及时补偿)：
           TRP周期          TRFC周期                  
预充电命令 -------->刷新命令 ---------> 刷新操作完成

 */
always @(posedge clk)begin
if(!soft_rst_n)begin//同步复位
  //管理输出端口
  ref_done <= 1'b0 ;
  ref_ba   <= 2'd0 ;
  ref_a    <= 13'd0;
  ref_cmd  <= `NOP ;
  ref_cke  <= 1'b1 ;
  cnt      <= 15'd0;
  state    <= s0   ;
end
else 
  case(state)
    s0: if(!ref_en)begin//如果刷新使能开关没有打开
          state        <= s0          ;
          ref_done     <= 0           ;
        end
        else begin//如果刷新使能开关已经打开
          state     <= s1           ;
          ref_cmd   <= `PRE         ;//预充电命令
          ref_a[10] <= 1            ;//所有Bank
          ref_done  <= 0            ;
        end
        
    s1: if(cnt < `tRP-1)begin//经过TRP周期
          cnt         <= cnt + 1   ;
          ref_cmd     <= `NOP      ; 
          state       <= s1        ;
        end
        else begin
          cnt         <= 15'd0     ;
          ref_cmd     <= `REF      ;//发送刷新命令
          state       <= s2        ;          
        end        
    
    s2: if(cnt < `tRFC-1)begin//经过TRFC周期
           cnt         <= cnt + 1  ;
           ref_cmd  <= `NOP     ;    
           state    <= s2       ;           
        end
        else begin 
           cnt <= 15'd0         ;
           ref_done <= 1'b1     ;//完成刷新工作
           state    <= s0       ;
        end    
    default:
          state       <= s0       ;
  endcase
 

 
end

endmodule