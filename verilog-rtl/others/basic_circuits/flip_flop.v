`timescale 1ns / 1ps

module D_FF(
    input  Clk,
    input  D,
    output reg Q
    );

always @(posedge Clk) begin
    Q <= D;
end
endmodule

module Latch(
    input din,
    input en,
    output reg dout
    );

always @(din or en)
    if(en) 
        dout <= din;
endmodule

module JK_FF(
    input wire Clk,
    input wire J,
    input wire K,
    output reg Q
    );

// 公式
always @(posedge Clk) begin
    Q <= (J & (~Q)) | ((~K) & Q);
end

// 查找表
//    always @(posedge Clk)
//        case({J, K})
//           2'b00: Q <= Q;
//           2'b01: Q <= 0;
//           2'b10: Q <= 1;
//           2'b11: Q <= ~Q;
//       endcase
endmodule

module T_FF(
    input wire Clk,
    input wire T,
    output reg Q
    );

// 公式
always @(posedge Clk) begin
    Q <= (T & (~Q)) | ((~T) & Q);
end
    
// 查找表
//  always @(posedge Clk)
//      if(t)
//          Q <= ~Q;
//      else
//          Q <=  Q;
endmodule