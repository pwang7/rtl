`timescale 1ns / 1ps

module tb_clock_time_counter();

localparam CYCLE = 2;

reg clk, reset, ena;
wire pm;
wire [7:0] hh, mm, ss;

always #(CYCLE/2) clk = ~clk;

initial begin
    clk = 0;
    reset = 1;
    ena = 1;
    #(2 * CYCLE) reset = 0;
end

clock_time_counter uut(
    .clk(clk),
    .reset(reset),
    .ena(ena),
    .pm(pm),
    .hh(hh),
    .mm(mm),
    .ss(ss)
    ); 
endmodule
