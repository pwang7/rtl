`timescale 1ns / 1ps

module Tri_State(
    input din,
    input en,
    output reg dout
    );

always @(din or en)
    if (en)
        dout <= din;
    else
        dout <= 1'bz;

// 数据流描述
// assign dout = en ? din : 1'bz;
endmodule