`include "../rtl/head.v"

module m_fms(
        local_wdata       ,//1、Avalon总线 写数据 32bit
        local_rdata       ,//2、Avalon总线 读数据 32bit
        local_write       ,//3、Avalon总线 写命令
        local_addr        ,//4、Avalon总线 读写地址
        local_read        ,//5、Avalon总线 读命令
        local_ready       ,//6、Avalon总线 local_ready为1表示当前无读写操作，为0表示当前正在进行读写操作
        local_rddatavalid ,//7、Avalon总线 需要的数据刚刚读出
        
        init_done         ,//完成上电操作
        ref_done          ,//完成刷新操作
        wr_done           ,//完成写数据操作
        rd_done           ,//完成读数据操作
        row               ,//输出行地址
        col               ,//输出列地址
        ba                ,//输出Bank地址线
        wdata             ,//把Avalon总线上的写数据发送到写模块
        rdata             ,//从DDR读出的数据读出到Avalon总线上
        clk               ,//100Mhz时钟
        soft_rst_n        ,//软复位
        init_en           ,//使能上电模块
        ref_en            ,//使能刷新模块
        rt_en             ,//使能刷新计算器
        wr_en             ,//写数据使能
        rd_en             ,//读数据使能
        rt_flag           ,//计算器计满的标志 固定周期进行刷新操作
        smux               //多路选择器开关
);

input      [31:0]  local_wdata         ;
output reg [31:0]  local_rdata         ;
input      [24:0]  local_addr          ;
input              local_write         ;
input              local_read          ;
output reg         local_ready         ;
output reg         local_rddatavalid   ;
input      [31:0]  rdata               ;

input init_done        ;
input ref_done         ;
input wr_done          ;
input rd_done          ;

input clk              ;
input soft_rst_n       ;
input rt_flag          ;

output reg [12:0] row         ;
output reg [9:0]  col         ;
output reg [1:0]  ba          ;
output reg [31:0] wdata       ;                       
output reg        init_en     ;
output reg        ref_en      ;
output reg        rt_en       ;
output reg        wr_en       ;
output reg        rd_en       ;
output reg [1:0] smux         ;

reg [3:0]  state       ; 
  
parameter s0 = 4'b0000  ;
parameter s1 = 4'b0001  ;
parameter s2 = 4'b0011  ;
parameter s3 = 4'b0010  ;
parameter s4 = 4'b0110  ;
parameter s5 = 4'b0111  ;
parameter s6 = 4'b1111  ;

always @(posedge clk)begin 
 if(!soft_rst_n)begin//同步复位           
     ref_en            <= 1'b0      ;//管理输出端口
     rt_en             <= 1'b0      ;
     init_en           <= 1'b0      ;
     wr_en             <= 1'b0      ;
     rd_en             <= 1'b0      ;
     wdata             <= 32'd0     ;
     row               <= 13'd0     ;
     col               <= 10'd0     ;
     ba                <= 2'd0      ;
     smux              <= `MUX_INIT ;
     state             <= s0        ;
     local_ready       <= 1'b0      ;
     local_rddatavalid <= 1'b0      ;
     local_rdata       <= 0         ;
 end
 else  
    case(state)
        s0: begin
             state         <= s1       ;
             init_en       <= 1        ;//执行上电操作
             end

        s1:if(!init_done)begin
               init_en     <= 1'b0     ;
               state       <= s1       ;
           end
            else begin//完成上电后
               rt_en       <= 1        ;//打开刷新计算器模块的使能
               smux        <= `MUX_REF ;//多路选择器选择刷新的bus
               local_ready <= 1        ;
               state       <= s2       ;
            end
        
        s2: begin
               ref_en      <=   1'b1  ;//打开刷新模块的使能
               state       <=   s3    ;
             end
             
        s3:if(!ref_done)begin
               ref_en      <= 1'b0    ;
               state       <= s3      ;
            end
            else begin//完成刷新操作后
               state       <= s4      ;
            end
                   
              
        s4: if(!rt_flag)begin//如果在刷新计数周期的空闲时间里，可以执行读写操作
                if(local_write)
                     begin//如果Avalon总线上的写命令有打开 执行写操作
                           state       <= s5                ;
                           wr_en       <= 1'b1              ;//打开写使能模块
                           row         <= local_addr[22:10] ;//发送给写模块的行地址
                           col         <= local_addr[9:0]   ;//发送给写模块的列地址
                           ba          <= local_addr[24:23] ;//发送给写模块的Bank地址
                           local_ready <= 0                 ;//向外部发出此时SDR控制器忙的信息
                           wdata       <= local_wdata       ;//Avalon总线上的写数据发送给写模块，再由写模块发送给SDR
                           smux        <= `MUX_WR           ;//多路选择器选择写数据模块的bus
                       end 
                   else if(local_read)//如果Avalon总线上的读命令有打开 执行读操作
                       begin
                           state       <= s6                ;
                           smux        <= `MUX_RD              ;//多路选择器选择读数据模块的bus
                           rd_en       <= 1'b1              ;//打开读使能模块
                           row         <= local_addr[22:10] ;
                           col         <= local_addr[9:0]   ;
                           ba          <= local_addr[24:23] ;
                           local_ready <= 0                 ;
                           local_rddatavalid <= 0           ;
                       end
                   else begin//既没有写数据请求，也没有读数据请求
                           state       <= s4                ;
                   end
            end     
            else begin//到了该刷新的时间，应该执行刷新操作
                   ref_en      <= 1'b1              ;//打开刷新模块使能开关
                   state       <= s3                ;
            end
             
        
        s5:if(!wr_done)begin
                  wr_en        <= 1'b0              ;
                  state        <= s5                ;
             end
             else begin//如果已经完成写数据操作
                  smux         <= `MUX_REF          ;//多路选择器重新回到刷新的bus
                  local_ready  <= 1'b1              ;//标志已经完成写操作
                  state        <= s4                ;
             end
        s6:if(!rd_done)begin
                  rd_en <= 0;
                  state <= s6;
            end
            else begin//完成数据的读出
                  rd_en <= 0;
                  state       <= s4          ;
                  smux        <= `MUX_REF    ;
                  local_ready <= 1'b1        ;
                  local_rddatavalid <= 1'b1  ;
                  local_rdata <= rdata       ;
        end
        default:
                  state <= s0;
    endcase
end

endmodule