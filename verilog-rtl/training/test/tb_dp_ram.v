`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/07/2021 11:50:41 PM
// Design Name: 
// Module Name: tb_dp_ram
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb_dp_ram();

localparam DATA_WIDTH = 8;
localparam ADDR_WIDTH = 5;
localparam MAX_CNT = (2**ADDR_WIDTH) * 2;
localparam CNT_WIDTH = $clog2(MAX_CNT + 1);

reg clk;
reg rst_n;

initial begin
    clk = 0;
    rst_n = 0;
    #50
    rst_n = 1;
end

always #1 clk = ~clk;

reg[CNT_WIDTH:0] cnt;
always @ (posedge clk or negedge rst_n) begin
    if (rst_n == 1'b0) begin
        cnt <= 0;
    end
    else if (add_cnt) begin
        if (end_cnt)
            cnt <= 0;
        else
            cnt <= cnt + 1'b1;
    end
end

assign add_cnt = 1;
assign end_cnt = add_cnt && cnt == MAX_CNT - 1;

reg flag;
always @ (posedge clk or negedge rst_n) begin
    if (rst_n == 1'b0)
        flag <= 1;
    else if (end_cnt)
        flag <= ~flag;
end

wire rden = (add_cnt && cnt >= MAX_CNT/2) ? 1 : 0;
wire wren = (add_cnt && cnt < MAX_CNT/2) ? 1 : 0;
wire [ADDR_WIDTH-1:0] addr_wr = (add_cnt && cnt < MAX_CNT/2) ? cnt : 0;
wire [ADDR_WIDTH-1:0] addr_rd = (add_cnt && cnt >= MAX_CNT/2) ? cnt - MAX_CNT/2 : 0;
wire [DATA_WIDTH-1:0] din = (add_cnt && cnt < MAX_CNT/2) ? cnt : 0;
wire [DATA_WIDTH-1:0] dout;
// reg [DATA_WIDTH-1:0] dout;

// reg rden;
// reg wren;
// reg [ADDR_WIDTH-1:0] addr_wr;
// reg [ADDR_WIDTH-1:0] addr_rd;
// reg [DATA_WIDTH-1:0] din;
// wire [DATA_WIDTH-1:0] dout;

// always @ (posedge clk or negedge rst_n) begin
//     if (rst_n == 1'b0) begin
//         rden <= 0;
//         wren <= 0;
//         addr_wr <= 0;
//         addr_rd <= 0;
//         din <= 0;
//     end
//     else begin
//         wren <= (add_cnt && cnt < MAX_CNT/2) ? 1 : 0;
//         addr_wr <= (add_cnt && cnt < MAX_CNT/2) ? cnt : 0;
//         din <= (add_cnt && cnt < MAX_CNT/2) ? cnt : 0;

//         rden <= (add_cnt && cnt >= MAX_CNT/2) ? 1 : 0;
//         addr_rd <= (add_cnt && cnt >= MAX_CNT/2) ? cnt - MAX_CNT/2 : 0;
//     end
// end

// wire rden_a = rden;
// wire wren_a = 0;
// wire [ADDR_WIDTH-1:0] address_a = addr_rd;
// wire [DATA_WIDTH-1:0] data_a = 0;
// wire [DATA_WIDTH-1:0] ram_rd_data_a;
// assign dout = ram_rd_data_a;

// wire rden_b = 0;
// wire wren_b = wren;
// wire [ADDR_WIDTH-1:0] address_b = addr_wr;
// wire [DATA_WIDTH-1:0] data_b = din;
// wire [DATA_WIDTH-1:0] ram_rd_data_b = 0;


wire rden_a = flag ? rden : 0;
wire wren_a = flag ? 0 : wren;
wire [ADDR_WIDTH-1:0] address_a = flag ? addr_rd : addr_wr;
wire [DATA_WIDTH-1:0] data_a = flag ? 0 : din;
wire [DATA_WIDTH-1:0] ram_rd_data_a;

wire rden_b = flag ? 0 : rden;
wire wren_b = flag ? wren : 0;
wire [ADDR_WIDTH-1:0] address_b = flag ? addr_wr : addr_rd;
wire [DATA_WIDTH-1:0] data_b = flag ? din : 0;
wire [DATA_WIDTH-1:0] ram_rd_data_b;

assign dout = flag ? ram_rd_data_a : ram_rd_data_b;
// always @ (posedge clk or negedge rst_n) begin
//     if (rst_n == 1'b0)
//         dout <= 0;
//     else if (flag)
//         dout <= ram_rd_data_a;
//     else
//         dout <= ram_rd_data_b;
// end

dp_ram #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) u_dp_ram (
    .addr_a(address_a),
    .addr_b(address_b),
    .clk_a(clk),
    .clk_b(clk),
    .din_a(data_a),
    .din_b(data_b),
    .rden_a(rden_a),
    .rden_b(rden_b),
    .wren_a(wren_a),
    .wren_b(wren_b),
    .dout_a(ram_rd_data_a),
    .dout_b(ram_rd_data_b)
    );

endmodule
