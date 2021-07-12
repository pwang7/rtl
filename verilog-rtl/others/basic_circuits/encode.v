`timescale 1ns / 1ps

module Encoders(
    input wire [7:0] d, // 输入信号_未编码
    output reg [2:0] b  // 输出信号_已编码
    );  

    always @ ( d ) begin 
        case ( d )
            8'b0000_0001 : b <= 3'b000;
            8'b0000_0010 : b <= 3'b001;
            8'b0000_0100 : b <= 3'b010;
            8'b0000_1000 : b <= 3'b011;
            8'b0001_0000 : b <= 3'b100;
            8'b0010_0000 : b <= 3'b101;
            8'b0100_0000 : b <= 3'b110;
            8'b1000_0000 : b <= 3'b111; 
            default      : b <= 3'b000;
        endcase 
    end
endmodule

module Priority_Encoders(
    input wire [7:0] d, // 输入信号_未编码
    output reg [2:0] b  // 输出信号_已编码
    );  

    always @ ( d ) begin
        casez ( d )
            8'b0000_0001 : b <= 3'b000;
            8'b0000_001? : b <= 3'b001;
            8'b0000_01?? : b <= 3'b010;
            8'b0000_1??? : b <= 3'b011;
            8'b0001_???? : b <= 3'b100;
            8'b001?_???? : b <= 3'b101;
            8'b01??_???? : b <= 3'b110;
            8'b1???_???? : b <= 3'b111; 
            default      : b <= 3'bxxx;
        endcase 
    end
endmodule