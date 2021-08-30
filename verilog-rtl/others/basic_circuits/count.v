`timescale 1ns / 1ps

module count(
    input Clk,
    input Up, // 可增可减（可逆）计数器
    output reg [7:0] Cout = 8'b0000_0000 // 8 位计数器
    );

always @(posedge Clk)
    if (Up)
        Cout <= Cout + 1'b1;
    else
        Cout <= Cout - 1'b1;
endmodule
