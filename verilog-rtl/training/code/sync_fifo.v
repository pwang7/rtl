`timescale 1ns / 1ps

module sync_fifo #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 5
)(
    input clk,
    input rst_n,

    input wr_en,
    input rd_en,
    input [DATA_WIDTH-1:0] data_in,
    output [DATA_WIDTH-1:0] data_out,
    output full,
    output empty
    );

localparam DEPTH = 2**ADDR_WIDTH;

reg [DATA_WIDTH-1:0] ram [0:DEPTH-1];
reg [ADDR_WIDTH:0] wr_addr;
reg [ADDR_WIDTH:0] rd_addr;

// Why does not ram[rd_addr] work?
assign data_out = ram[rd_addr[ADDR_WIDTH-1:0]];
assign empty = (wr_addr == rd_addr);
assign full = (wr_addr[ADDR_WIDTH] ^ rd_addr[ADDR_WIDTH]) &&
              (wr_addr[ADDR_WIDTH-1:0] == rd_addr[ADDR_WIDTH-1:0]);

always @ (posedge clk or negedge rst_n)
    if (!rst_n) begin
        wr_addr <= 'b0;
        rd_addr <= 'b0;
        for (integer idx = 0; idx < DEPTH; idx = idx + 1)
            ram[idx] <= 'b0;
    end
    else begin
        if (wr_en && !full) begin
            ram[wr_addr] <= data_in;
            wr_addr <= wr_addr + 1'b1;
        end
        else if (rd_en && !empty) begin
            rd_addr <= rd_addr + 1'b1;
        end
    end

endmodule


module sync_fifo2 #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 5
)(
    input clk,
    input rst_n,

    input wr_en,
    input rd_en,
    input [DATA_WIDTH-1:0] data_in,
    output [DATA_WIDTH-1:0] data_out,
    output full,
    output empty
    // output reg empty,
    // output reg full
    );

localparam DEPTH = 2**ADDR_WIDTH;

reg [DATA_WIDTH-1:0] ram [0:DEPTH-1];
reg [ADDR_WIDTH-1:0] wr_addr;
reg [ADDR_WIDTH-1:0] rd_addr;
reg [ADDR_WIDTH:0] count;

always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        wr_addr <= 0;
        rd_addr <= 0;
        count <= 0;
    end
    else if (wr_en && !rd_en) begin
        if (!full) begin
            count <= count + 1;
            ram[wr_addr] <= data_in;
            wr_addr <= wr_addr + 1;
        end
    end
    else if (!wr_en && rd_en) begin
        if (!empty) begin
            count <= count - 1;
            rd_addr <= rd_addr + 1;
        end
    end
    else if (wr_en && rd_en) begin
            ram[wr_addr] <= data_in;
            wr_addr <= wr_addr + 1;
            rd_addr <= rd_addr + 1;
    end
end

assign data_out = ram[rd_addr];

assign empty = (count == 0);
assign full = (count == DEPTH);
// always @ (*) begin
//     if (count == 0)
//         empty = 1;
//     else
//         empty = 0;     
//     if (count == MAX_CNT)
//         full = 1;
//     else
//         full = 0;
// end

endmodule
