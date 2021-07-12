`timescale 1ns / 1ps

module Parity_Check(
    input wire [7:0] a, // 输入数据
    output odd, // 奇数位
    output even // 偶数位
    );

assign odd = a[0] ^ a[1] ^ a[2] ^ a[3] ^ a[4] ^ a[5] ^ a[6] ^ a[7];
// assign odd = ^ a;
assign even = ~odd;
endmodule