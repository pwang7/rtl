`timescale 1ns / 1ps

module Comparator(
    input wire [7:0] a, // 比较数
    input wire [7:0] b, // 比较数
    output reg result, // 比较结果
    output reg equal // 比较结果
    );

// 行为描述
always @(a or b) begin
    if(a > b)
        {equal,result} <= 2'b01; // a 比 b 大
    else begin
        if(a < b)
            {equal,result} <= 2'b00; // a 比 b 小
        else
            {equal,result} <= 2'b10; // 相等
    end
end

// 数据流描述
// assign equal = (a == b) ? 1 : 0;
// assign result = (a > b) ? 1 : 0;
endmodule
