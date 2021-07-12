`timescale 1ns / 1ps

module Shift_Register(
    input Clk,
    input [7:0] din,
    output reg [7:0] dout
    );

always@(posedge Clk)
    dout <= (din << 1);
    // dout <= {din[7:1], 1'b0};

endmodule