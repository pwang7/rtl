`timescale 1ns / 1ps

module Serial2Serial(
    input Clk,
    input din,
    output dout
    );

reg [3:0] databuff = {4{1'b0}};// 表示 4 bits 缓冲通道

always @(posedge Clk)
    databuff  <= {databuff[2:0], din};

assign dout = databuff[3];
endmodule