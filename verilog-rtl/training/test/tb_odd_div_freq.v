`timescale 1ns / 1ps

module tb_odd_div_freq();

reg clk, rst_n;
wire oclk;

initial begin
    clk = 0;
    rst_n = 0;
    #5
    rst_n = 1;
end

always #1 clk = ~clk;

odd_div_freq # (
    .DIV(3)
) u_odd_div_freq(
    .clk(clk),
    .rst_n(rst_n),
    .oclk(oclk)
    );
endmodule
