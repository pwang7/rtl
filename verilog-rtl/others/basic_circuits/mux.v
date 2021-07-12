`timescale 1ns / 1ps

module Multiplexer2(
    input wire a, // 输入数据信号
    input wire b, // 输入数据信号
    input wire sel, // 输入控制信号
    output result // 输出数据信号_已选择
    );

    assign result = sel ? a : b;
endmodule

module Multiplexer4(
    input wire a, // 输入数据信号
    input wire b, // 输入数据信号
    input wire c, // 输入数据信号
    input wire d, // 输入数据信号
    input wire [1:0] sel, // 输入控制信号
    output reg result // 输出数据信号_已选择
    );

always @(sel, a, b, c, d)
    case (sel)
        2'b00: result <= a;
        2'b01: result <= b;
        2'b10: result <= c;
        2'b11: result <= d;
    endcase
endmodule