`timescale 1ns / 1ps

module tb_async_fifo();

localparam DATA_WIDTH = 8;
localparam ADDR_WIDTH = 5;
localparam MAX_CNT = (2**ADDR_WIDTH);
localparam RST_TIME = 2;
localparam RCYCLE = 6;
localparam WCYCLE = 8;

reg rclk;
reg rden;
reg rst_n;
reg wclk;
reg [DATA_WIDTH-1:0] wdata;
reg wren;

wire [DATA_WIDTH-1:0] rdata;
wire rempty;
wire wfull;

initial begin
    rst_n = 0;
    rclk = 0;
    wclk = 0;
    #RST_TIME rst_n = 1;
end

initial begin
    rclk = 1'b0;
    wclk = 1'b0;
end
always #(RCYCLE/2) rclk = ~rclk;
always #(WCYCLE/2) wclk = ~wclk;

initial begin
    wren = 0;
    rden = 0;
    wdata = 0;
    #RST_TIME;
    repeat (MAX_CNT) begin
        wren = 1;
        rden = 0;
        wdata = wdata + 1;
        #WCYCLE;
    end
    repeat (MAX_CNT) begin
        wren <= 0;
        rden = 1;
        #RCYCLE;
    end

    repeat (MAX_CNT/2) begin
        wren = 1;
        rden = 0;
        wdata = wdata + 1;
        #WCYCLE;
    end
    repeat (MAX_CNT/2) begin
        wren <= 0;
        rden = 1;
        #RCYCLE;
    end
end

async_fifo  #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) u_async_fifo (
    .rd_clk(rclk),
    .rd_rst_n(rst_n),
    .rd_data(rdata),
    .empty(rempty),
    .rd_en(rden),
    .wr_clk(wclk),
    .wr_rst_n(rst_n),
    .wr_data(wdata),
    .full(wfull),
    .wr_en(wren)
    );

// async_fifo  #(
//     .DATA_WIDTH(DATA_WIDTH),
//     .ADDR_WIDTH(ADDR_WIDTH)
// ) u_async_fifo (
//     .rclk(rclk),
//     .rdata(rdata),
//     .rempty(rempty),
//     .rden(rden),
//     .rst_n(rst_n),
//     .wclk(wclk),
//     .wdata(wdata),
//     .wfull(wfull),
//     .wren(wren)
//     );

endmodule
