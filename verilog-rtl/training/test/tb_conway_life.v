`timescale 1ns / 1ps

module tb_conway_life();

localparam CYCLE = 2;
localparam ROWS = 4;
localparam COLS = 4;

reg clk, load;
reg [(ROWS * COLS - 1):0] data;
wire [(ROWS * COLS - 1):0] q;

always #(CYCLE/2) clk = ~clk;

initial begin
    clk = 0;
    load = 0;
    data = 256'h7;
    #(2 * CYCLE) load = 1;
    #(CYCLE) load = 0;
end

conway_life #(
    .ROWS(ROWS),
    .COLS(COLS)
) uut(
    .clk(clk),
    .load(load),
    .data(data),
    .q(q)
    );
endmodule
