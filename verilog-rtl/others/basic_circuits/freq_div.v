`timescale 1ns / 1ps

module Two_Div(
    input clk_in,
    input rst_n,
    output reg clk_out
    );

always @(posedge clk_in) begin
    if (!rst_n)
        clk_out <= 0;
    else
        clk_out <= ~clk_out;
end
endmodule

module Two_Exp_Div(
    input clk_in,
    input rst_n,
    output reg clk_out1,clk_out2,clk_out3,clk_out4
    );
 
    reg [3:0] counter ;
 
/*---------------------计数模块----------------------*/
always @(posedge clk_in or negedge rst_n)
    if (!rst_n)
        counter <= 0;
    else begin
        if (counter == 4'b1111)
            counter <= 4'b0000;
        else
            counter <= counter + 1'b1;
    end
 
/*---------------------产生分频----------------------*/
always @(posedge clk_in or negedge rst_n)
    if (!rst_n) begin
        clk_out1 <= 0;
        clk_out2 <= 0;
        clk_out3 <= 0;
        clk_out4 <= 0;
    end
    else begin
        clk_out1 <= counter[0];    // 2分频
        clk_out2 <= counter[1];    // 4分频
        clk_out3 <= counter[2];    // 8分频
        clk_out4 <= counter[3];    // 16分频
    end
endmodule

module Even_Div(
    input      clk_in,
    input      rst_n,
    output reg clk_out
    );

reg [2:0] cnt; // log2(6) = 2.5850 <= 3;这里，6也可以换成 10、12、14 ...

always @(posedge clk_in or negedge rst_n) begin
    if (!rst_n)
        cnt <= 0;
    else begin
        if (cnt == 5) // 6 bits 计数器: 0 - 5;实现置零;
            cnt <= 0;
        else
            cnt <= cnt + 1'b1;
    end
end

always @(posedge clk_in, negedge rst_n) begin
    if (!rst_n)
        clk_out <= 0;
    else begin
        if (cnt <= 2) // 3 bits 计数器: 0 - 2;实现翻转;
            clk_out <= 1;
        else
            clk_out <= 0;
    end
end
endmodule

module Odd_Div(
    input  clk_in,
    input  rst_n,
    output clk_out
    );

parameter N = 3;

reg clk_n;
reg clk_p;
reg [3:0] cnt_p;
reg [3:0] cnt_n;

always @(posedge clk_in or negedge rst_n) begin
    if (!rst_n) begin
        clk_p <= 1'b0;
        cnt_p <= 4'b0;
    end
    else begin
        if (cnt_p == N-1) begin
            clk_p <= ~clk_p;
            cnt_p <= 4'b0;
        end
        else if (cnt_p == (N-1)/2) begin
            clk_p <= ~clk_p;
            cnt_p <= cnt_p + 1;
        end
        else begin
            cnt_p <= cnt_p + 1;
            clk_p <= clk_p;
        end
    end
end

always @(negedge clk_in or negedge rst_n) begin
    if (!rst_n) begin
        clk_n <= 1'b0;
        cnt_n <= 4'b0;
    end
    else begin
        if (cnt_n == N-1) begin
            clk_n <= ~clk_n;
            cnt_n <= 4'b0;
        end
        else if (cnt_n == (N-1)/2) begin
            clk_n <= ~clk_n;
            cnt_n <= cnt_n + 1;
        end
        else begin
            cnt_n <= cnt_n + 1;
            clk_n <= clk_n;
        end
    end
end

assign clk_out = clk_n | clk_p;
endmodule

// 3分频的规律（毕竟是最常考的），占空比1/3的是求或操作，占空比为2/3的是求与操作
module Three_Div(
    input  clk_in,
    input  rst_n,
    output clk_out
    );

reg [1:0] cnt_p; // log2(3) = 1.5850 <= 2

always @(posedge clk_in or negedge rst_n) begin
    if (!rst_n)
        cnt_p <= 0;
    else begin
        if (cnt_p == 2)
            cnt_p <= 0;
        else
            cnt_p <= cnt_p + 1'b1;
    end
end

reg [1:0] cnt_n; // log2(3) = 1.5850 <= 2

always @(negedge clk_in or negedge rst_n) begin // negedge clk
    if (!rst_n)
        cnt_n <= 0;
    else begin
        if (cnt_n == 2)
            cnt_n <= 0;
        else
            cnt_n <= cnt_n + 1'b1;
    end
end

reg clk_out_p; // 上升沿时钟输出寄存器

always @(posedge clk_in or negedge rst_n) begin
    if (!rst_n)
        clk_out_p <= 0;
    else begin
        if (cnt_p <= 1)
            clk_out_p <= 1;
        else
            clk_out_p <= 0;
    end
end

reg clk_out_n; // 下降沿时钟输出寄存器

always @(negedge clk_in or negedge rst_n) begin
    if (!rst_n)
        clk_out_n <= 0;
    else begin
        if (cnt_n <= 1)
            clk_out_n <= 1;
        else
            clk_out_n <= 0;
    end
end

assign clk_out = clk_out_n & clk_out_p;
endmodule
