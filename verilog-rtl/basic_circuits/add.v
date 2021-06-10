`timescale 1ns / 1ps

module Half_Adder(
    input wire a, // 加数
    input wire b, // 加数
    output reg sum, // 和
    output reg cout // 进位输出
    );
// 行为描述
always @(a or b) begin
    sum  = a ^ b; // 实践证明，这里 <= 和 = 的结果都一样；都是纯粹的组合逻辑；
    cout = a & b;
end

// 数据流描述
// assign sum  = a ^ b;
// assign cout = a & b;

// 门级描述
// and(cout,a,b);
// xor(sum,a,b);
endmodule

module Full_Adder(
    input wire a, // 加数
    input wire b, // 加数
    input wire cin,// 进位输入
    output reg sum, // 和
    output reg cout // 进位输出
    );

// 行为描述
always @(a or b or cin) begin
    {cout,sum} <= a + b + cin;
end

// 行为描述
//    always @(a or b or cin) begin
//        sum  = a ^ b ^ cin; // 实践证明，这里 <= 和 = 的结果都一样；都是纯粹的组合逻辑；
//        cout = a & b | b & cin | a & cin;
//    end

// 数据流描述
// assign {cout, sum} = a + b + cin;
endmodule