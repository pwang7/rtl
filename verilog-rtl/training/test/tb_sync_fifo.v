`timescale 1ns / 1ps

module tb_sync_fifo();

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

wire full, empty;
reg wr_en, rd_en;

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

assign add_cnt = !full;
assign end_cnt = add_cnt && cnt == MAX_CNT - 1;

reg [DATA_WIDTH-1:0] data_in;
wire [DATA_WIDTH-1:0] data_out;
/*
always @ (posedge clk or negedge rst_n) begin
    if (rst_n == 1'b0) begin
        wr_en <= 0;
        data_in <= {DATA_WIDTH{1'bX}};
    end
    else if (!full) begin
            wr_en <= 1;
            data_in <= cnt;
        end
        else
            wr_en <= 0;
end

always @ (posedge clk or negedge rst_n) begin
    if (rst_n == 1'b0)
        rd_en <= 0;
    else if (!empty)
            rd_en <= 1;
        else
            rd_en <= 0;
end
*/
always @ (posedge clk or negedge rst_n) begin
    if (rst_n == 1'b0) begin
        wr_en <= 0;
        rd_en <= 0;
        data_in <= {DATA_WIDTH{1'bX}};
    end
    else begin
        if (add_cnt && cnt < MAX_CNT/2) begin
            wr_en <= 1;
            rd_en <= 0;
            data_in <= cnt;
        end
        else if (add_cnt && cnt >= MAX_CNT/2) begin
            wr_en <= 0;
            rd_en <= 1;
            data_in <= {DATA_WIDTH{1'bX}};
        end
    end
end

sync_fifo #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) u_sync_fifo (
    .clk(clk),
    .rst_n(rst_n),
    .wr_en(wr_en),
    .rd_en(rd_en),
    .data_in(data_in),
    .data_out(data_out),
    .full(full),
    .empty(empty)
    );

endmodule
