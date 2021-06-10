`timescale 1ns / 1ps

module tb_width_change_8to16();

localparam AWIDTH = 8,
           BWIDTH = 16;

reg clk;
reg rst_n;
reg a_vld;
reg [AWIDTH-1:0] a;
wire [BWIDTH-1:0] b;
wire b_vld;

initial begin
    clk = 0;
    rst_n = 0;
    a = 0;
    a_vld = 0;
    #50
    rst_n = 1;
    #30
    a_vld = 1;
    a = 8'h00;
    #20
    a = 8'h11;
    #20
    #20
    a_vld = 0;
    #20
    a_vld = 1;
    a = 8'h22;
    #20
    a = 8'h33;
    #20
    a = 8'h44;
    #20
    a = 8'h55;
    #20
    a = 8'h66;
    #20
    a = 8'h77;
    #20
    a = 8'h88;
    #20
    a = 8'h99;
    #20
    a = 8'haa;
    #20
    a = 8'hbb;
    #20
    a = 8'hcc;
    #20
    a_vld = 0;
end

always #10 clk = ~clk;

width_change_8to16 #(
    .AWIDTH(AWIDTH),
    .BWIDTH(BWIDTH)
) u_width_change_8to16(
    .clk(clk),
    .rst_n(rst_n),
    .a_vld(a_vld),
    .a(a),
    .b_vld(b_vld),
    .b(b)
    );

endmodule
