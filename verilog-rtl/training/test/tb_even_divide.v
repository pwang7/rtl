`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/07/2021 01:06:34 AM
// Design Name: 
// Module Name: tb_even_divide
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb_even_divide();
reg clk;
reg rst_n;
wire out_clk;
initial begin
    clk= 1'b0;
    rst_n = 1'b0;
    #200
    rst_n = 1'b1;
end

always #10 clk = ~clk;
even_divide u_even_divide(
    .clk(clk),
    .rst_n(rst_n),
    .out_clk(out_clk)
    );

endmodule
