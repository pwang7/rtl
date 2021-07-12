`timescale 1ns / 1ps

module Pal2Serial( // 四位并串转换程序：PiSo_Shift = 4
    input Clk,
    input Load, // 输入数据加载信号
    input [3:0] din, // 4 位并行输入数据
    output dout // 1 位串行输出数据
    );

reg [3:0] databuff = 4'b0000; // 中间缓冲通道

always @(posedge Clk)
    if (Load) 
        databuff <= din;
    else
        databuff <= databuff << 1;

assign dout = databuff[3];

endmodule