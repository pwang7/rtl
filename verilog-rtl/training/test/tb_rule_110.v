`timescale 1ns / 1ps

module tb_rule_110();

localparam CYCLE = 2;
localparam LEN = 5;
reg clk, load;
reg [LEN-1:0] data;
wire [LEN-1:0] q;

always #(CYCLE/2) clk = ~clk;

initial begin
    clk = 0;
    load = 0;
    data = 512'h1;
    #(2 * CYCLE) load = 1;
    #(CYCLE) load = 0;
end

rule_110 #(.LEN(LEN)) uut(
    .clk(clk),
    .load(load),
    .data(data),
    .q(q)
    ); 

endmodule
