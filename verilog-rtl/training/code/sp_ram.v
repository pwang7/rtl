`timescale 1ns / 1ps

module sp_ram #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 5
)(
    input clk,
    input wen, //ram读写使能
    input en, //ram总使能
    input[ADDR_WIDTH-1:0] addr,
    input[DATA_WIDTH-1:0] din,
    output reg[DATA_WIDTH-1:0] q
    );

reg[DATA_WIDTH-1:0] ram [0:(2**ADDR_WIDTH)-1];

always @ (posedge clk) begin
    if (en && !wen)
        q <= ram[addr];
    else
        q <= {DATA_WIDTH{1'bZ}};
end

always @ (posedge clk) begin
    if (en && wen)
        ram[addr] <= din;
end

endmodule
