`timescale 1ns / 1ps

module Clock_Switch_No_Glitch(
    input clk0,
    input clk1,
    input rst_n,
    input select,
    output clk_out
    );

wire clk0_neg = ~clk0;
wire clk1_neg = ~clk1;

reg clk0_ff0, clk0_ff1;
reg clk1_ff0, clk1_ff1;

always @(posedge clk0 or negedge rst_n) begin
    if (!rst_n)
        clk0_ff0 <= 0;
    else
        clk0_ff0 <= select & ~clk1_ff1;
end

always @(posedge clk0_neg or negedge rst_n) begin
    if (!rst_n)
        clk0_ff1 <= 0;
    else
        clk0_ff1 <= clk0_ff0;
end

always @(posedge clk1 or negedge rst_n) begin
    if (!rst_n)
        clk1_ff0 <= 0;
    else
        clk1_ff0 <= ~select & ~clk0_ff1;
end

always @(posedge clk1_neg or negedge rst_n) begin
    if (!rst_n)
        clk1_ff1 <= 0;
    else
        clk1_ff1 <= clk1_ff0;
end

assign clk_out = clk0_ff1 | clk1_ff1;

endmodule
