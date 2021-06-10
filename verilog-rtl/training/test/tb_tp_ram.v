`timescale 1ns / 1ps

module tb_tp_ram();

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

reg ram_wr_en;
reg [ADDR_WIDTH-1:0] ram_waddr;
reg [DATA_WIDTH-1:0] ram_wr_data;

reg ram_rd_en;
reg [ADDR_WIDTH-1:0] ram_raddr;
wire [DATA_WIDTH-1:0] ram_rd_data;

always @ (posedge clk or negedge rst_n) begin
    if (rst_n == 1'b0) begin
        ram_wr_en <= 0;
        ram_waddr <= 0;
        ram_wr_data <= 0;
    end
    else begin
        ram_wr_en <= (add_cnt && cnt < MAX_CNT/2) ? 1 : 0;
        ram_waddr <= (add_cnt && cnt < MAX_CNT/2) ? cnt : 0;
        ram_wr_data <= (add_cnt && cnt < MAX_CNT/2) ? cnt : 0;

        ram_rd_en <= (add_cnt && cnt >= MAX_CNT/2) ? 1 : 0;
        ram_raddr <= (add_cnt && cnt >= MAX_CNT/2) ? cnt - MAX_CNT/2 : 0;
    end
end

tp_ram #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) u_tp_ram (
    .addrwr(ram_waddr),
    .addrrd(ram_raddr),
    .clkwr(clk),
    .clkrd(clk),
    .din(ram_wr_data),
    .rden(ram_rd_en),
    .wren(ram_wr_en),
    .dout(ram_rd_data)
    );

endmodule
