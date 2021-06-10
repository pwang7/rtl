`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/11/2021 09:20:44 PM
// Design Name: 
// Module Name: tb_gray_code
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


module tb_gray_code();

localparam WIDTH = 5;
reg [WIDTH-1:0] bin_in, gray_in;
wire [WIDTH-1:0] bin_out, gray_out;

initial begin
    bin_in = 7;
    gray_in = 4;
end

bin_to_gray #(.WIDTH(WIDTH)) u_bin_to_gray(
    .bin_in(bin_in),
    .gray_out(gray_out)
    );

gray_to_bin #(.WIDTH(WIDTH)) u_gray_to_bin(
    .gray_in(gray_in),
    .bin_out(bin_out)
    );
endmodule
