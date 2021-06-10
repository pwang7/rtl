`timescale 1ns / 1ps

module tb_width_change_8to12();

localparam AWIDTH = 8,
           BWIDTH = 12;

reg clk;
reg rst_n;
reg a_vld;
reg[AWIDTH-1:0] a;
wire [BWIDTH-1:0] b;
wire b_vld;

initial begin
    clk = 0;
    rst_n = 0;
    a = 8'b0;
    a_vld= 0;
    #50
    rst_n = 1;
    #28
    a_vld = 1;
    a = 8'h55;
    #20
    a_vld = 0;
    #20
    a_vld = 1;
    a = 8'haa;
    #20
    a = 8'hbb;
    #20
    a = 8'hcc;
    #20
    a = 8'hdd;
    #20
    a = 8'hee;
    #20
    a_vld= 0;
    #60
    a_vld = 1;
    a = 8'hff;
    #20
    a_vld= 0;
end

always #10 clk = ~clk;

width_change_8to12 #(
    .AWIDTH(AWIDTH),
    .BWIDTH(BWIDTH)
) u_width_change_8to12 (
    .clk(clk),
    .rst_n(rst_n),
    .a_vld(a_vld),
    .a(a),
    .b_vld(b_vld),
    .b(b)
    );

endmodule
