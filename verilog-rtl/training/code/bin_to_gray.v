`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/06/2021 11:25:37 PM
// Design Name: 
// Module Name: bin_to_gray
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


module bin_to_gray(
    bin_in,
    gray_out
    );

parameter WIDTH = 4;
input[WIDTH-1:0] bin_in;
output wire [WIDTH-1:0] gray_out;

assign gray_out = (bin_in >> 1) ^ bin_in;
// gray_out[0] = (bin_in[1]) ^ bin_in[0];
// gray_out[1] = (bin_in[2]) ^ bin_in[1];
// gray_out[2] = (bin_in[3]) ^ bin_in[2];
// gray_out[3] = (bin_in[3]) ^ 0 ;

endmodule
