`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/07/2021 12:01:52 AM
// Design Name: 
// Module Name: tb_key_debounce
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


module tb_key_debounce();
reg clk;
reg rst_n;
reg key_n;
wire deb_key_n;
initial begin
    clk = 0;
    rst_n = 0;
    #100
    rst_n = 1;
    key_n = 1;
    #200
    #200
    key_n = 0;
    #50_000_000
    key_n = 1;
    #200
    key_n = 1;
    #200
    key_n = 0;
    #200
    key_n = 1;
    #200
    key_n = 0;
    #200
    key_n = 1;
end

always #10 clk = ~clk;

key_debounce u_key_debounce(
    .clk(clk),
    .rst_n(rst_n),
    .key_n(key_n),
    .deb_key_n(deb_key_n)
    );
endmodule
