`timescale 1ns / 1ps

module tp_ram #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 5
)(
    input clkwr,
    input clkrd,

    input wren,
    input [ADDR_WIDTH-1:0] addrwr,
    input [DATA_WIDTH-1:0] din,

    input rden,
    input [ADDR_WIDTH-1:0] addrrd,
    output [DATA_WIDTH-1:0] dout
    );

reg [DATA_WIDTH-1:0] ram [0:(2**ADDR_WIDTH)-1];
reg [DATA_WIDTH-1:0] q;

always @ (posedge clkwr) begin
    if (wren)
        ram[addrwr] <= din;
end

always @ (posedge clkrd) begin
    if (rden)
        q <= ram[addrrd];
    else
        q <= {DATA_WIDTH{1'bX}};
end

reg conflict;
always @ (posedge clkrd) begin
    // Should synchronize `wren` w.r.t. `clkrd`?
    if (wren && rden && addrwr == addrrd)
        conflict <= 1;
    else
        conflict <= 0;
end

assign dout = conflict ? din : q;

endmodule
