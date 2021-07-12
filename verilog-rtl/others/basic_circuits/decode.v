`timescale 1ns / 1ps

module Decoders(
    input wire [2:0] b, // 输入信号_未译码
    output reg [7:0] d // 输出信号_已译码
    );

    always @ ( b ) begin
        case ( b )
            3'b000 : d <= 8'b0000_0001;
            3'b001 : d <= 8'b0000_0010;
            3'b010 : d <= 8'b0000_0100;
            3'b100 : d <= 8'b0001_0000;
            3'b101 : d <= 8'b0010_0000;
            3'b110 : d <= 8'b0100_0000;
            3'b111 : d <= 8'b1000_0000;
            default: d <= 8'b0000_0000;
        endcase
    end
endmodule