`include "../rtl/head.v"

//刷新计数器模块
module ref_timer(
        clk        ,//时钟线 100Mhz
        rt_en      ,//使能刷新
        rt_flag    ,//计数器满标志
        soft_rst_n //软复位
);

input  clk         ;
input  soft_rst_n  ;
input  rt_en       ;
                   
output reg rt_flag ;

reg [9:0] cnt      ;

always@(posedge clk)begin
  if (!soft_rst_n)begin//同步复位
      cnt     <= 10'd0        ;
      rt_flag <= 1'b0         ; 
  end
  else if(rt_en)
            if(cnt >=700)begin// 最长在64ms/8192=7.813us=7813ns周期内进行一次刷新
              cnt    <= 10'd0   ;
              rt_flag<= 1'b1    ;
          end
            else begin
                cnt    <= cnt + 1  ;//100MHz 计数一次10ns
                rt_flag<= 1'b0     ;
            end
  else 
       cnt       <= 10'd0       ;
       rt_flag   <= 1'b0        ;
     
 end
 

endmodule