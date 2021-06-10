`timescale 1ns / 1ps

module dp_ram #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 5
)(
    input clk_a,
    input clk_b,

    input wren_a,
    input rden_a,
    input [ADDR_WIDTH-1:0] addr_a,
    input [DATA_WIDTH-1:0] din_a,

    input wren_b,
    input rden_b,
    input [ADDR_WIDTH-1:0] addr_b,
    input [DATA_WIDTH-1:0] din_b,

    output [DATA_WIDTH-1:0] dout_a,
    output [DATA_WIDTH-1:0] dout_b
    );

reg [DATA_WIDTH-1:0] ram [0:(2**ADDR_WIDTH)-1];
reg [DATA_WIDTH-1:0] q_a, q_b;

always @ (posedge clk_a) begin
    if (wren_a)
        ram[addr_a] <= din_a;
end

always @ (posedge clk_a) begin
    if (rden_a)
        q_a <= ram[addr_a];
    else
        q_a <= {DATA_WIDTH{1'bX}};
end

always @ (posedge clk_b) begin
    if (wren_b)
        ram[addr_b] <= din_b;
end

always @ (posedge clk_b) begin
    if (rden_b)
        q_b <= ram[addr_b];
    else
        q_b <= {DATA_WIDTH{1'bX}};
end

reg conflict_wr_a_rd_b;
always @ (posedge clk_b) begin
    // Should synchronize `wren_a` w.r.t. `clk_b`?
    if (wren_a && rden_b && addr_a == addr_b)
        conflict_wr_a_rd_b <= 1;
    else
        conflict_wr_a_rd_b <= 0;
end

assign dout_b = conflict_wr_a_rd_b ? din_a : q_b;

reg conflict_rd_a_wr_b;
always @ (posedge clk_a) begin
    // Should synchronize `wren_b` w.r.t. `clk_a`?
    if (rden_a && wren_b && addr_a == addr_b)
        conflict_rd_a_wr_b <= 1;
    else
        conflict_rd_a_wr_b <= 0;
end

assign dout_a = conflict_rd_a_wr_b ? din_b : q_a;

endmodule
