`timescale 1ns / 1ps

module tb_sp_ram();

localparam DATA_WIDTH = 8;
localparam ADDR_WIDTH = 5;
localparam MAX_CNT = (2**ADDR_WIDTH) * 2;
localparam CNT_WIDTH = $clog2(MAX_CNT + 1);

reg clk;
reg rst_n;

wire[ADDR_WIDTH-1:0] addr;
wire[DATA_WIDTH-1:0] din;
wire[DATA_WIDTH-1:0] dout;
reg en;
wire wen;

initial begin
    clk = 0;
    rst_n = 0;
    en = 0;
    #50
    rst_n = 1;
    #50
    en = 1;
end

always #1 clk = ~clk;

sp_ram #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) u_sp_ram(
    .clk(clk),
    .wen(wen),
    .en(en),
    .addr(addr),
    .din(din),
    .q(dout)
    );

reg[CNT_WIDTH:0] cnt;
always @ (posedge clk or negedge rst_n) begin
    if (rst_n==1'b0) begin
        cnt <= 0;
    end
    else if (add_cnt) begin
        if (end_cnt)
            cnt <= 0;
        else
            cnt <= cnt + 1'b1;
    end
end

assign add_cnt = en;
assign end_cnt = add_cnt && cnt == MAX_CNT - 1;

assign wen = (add_cnt && cnt < MAX_CNT/2) ? 1 : 0;
assign addr = cnt;
assign din = cnt;

endmodule
