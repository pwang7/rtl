`timescale 1ns / 1ps

module async_fifo #(
    parameter ADDR_WIDTH       = 4            ,
    parameter DATA_WIDTH       = 16           ,
    parameter ALMOST_FULL_GAP  = 3            ,
    parameter ALMOST_EMPTY_GAP = 3            ,
    parameter FIFO_DEEP        = 2**ADDR_WIDTH
)(
    input wr_clk                   ,
    input wr_rst_n                 ,
    input wr_en                    ,
    input [DATA_WIDTH-1:0] wr_data ,
    output almost_full             ,
    output full                    ,

    input rd_clk                   ,
    input rd_rst_n                 ,
    input rd_en                    ,
    output almost_empty            ,
    output empty                   ,
    output [DATA_WIDTH-1:0] rd_data
);

// wire [ADDR_WIDTH-1:0] waddr;
// wire [ADDR_WIDTH-1:0] raddr;
reg [DATA_WIDTH-1:0] ram [0:FIFO_DEEP-1];

reg [ADDR_WIDTH:0] wr_addr; // Write address with MSB as overflow indicator
reg [ADDR_WIDTH:0] rd_addr; // Read address with MSB as overflow indicator
wire [ADDR_WIDTH:0] wr_gap; // Gap between write and read addresses
wire [ADDR_WIDTH:0] rd_gap; // Gap between read and write addresses
wire [ADDR_WIDTH:0] wr_addr_gray;
wire [ADDR_WIDTH:0] rd_addr_gray;
reg [ADDR_WIDTH:0] wr_addr_gray_tmp;
reg [ADDR_WIDTH:0] rd_addr_gray_tmp;
reg [ADDR_WIDTH:0] wr_addr_gray_sync;
reg [ADDR_WIDTH:0] rd_addr_gray_sync;
wire [ADDR_WIDTH:0] wr_addr_gray2bin;
wire [ADDR_WIDTH:0] rd_addr_gray2bin;

// Write control

integer idx;
always @ (posedge wr_clk or negedge wr_rst_n) begin
    if (!wr_rst_n) begin
        wr_addr <= {(ADDR_WIDTH + 1){1'b0}};
        for (idx = 0; idx < FIFO_DEEP; idx = idx + 1)
            ram[idx] <= 0;
    end
    else if (wr_en && !full) begin
        ram[wr_addr] <= wr_data;
        wr_addr <= wr_addr + 1;
    end
end

// Write address to Gray code
assign wr_addr_gray = wr_addr ^ (wr_addr >> 1);
// always @ (*) begin
//     wr_addr_gray = wr_addr ^ (wr_addr >> 1);
// end

// Sync read address Gray code w.r.t. write clock
always @ (posedge wr_clk or negedge wr_rst_n) begin
    if (!wr_rst_n) begin
        rd_addr_gray_tmp <= {(ADDR_WIDTH + 1){1'b0}};
        rd_addr_gray_sync <= {(ADDR_WIDTH + 1){1'b0}};
    end
    else begin
        rd_addr_gray_tmp <= rd_addr_gray;
        rd_addr_gray_sync <= rd_addr_gray_tmp;
    end
end

// Convert sync-ed read address Gray code to binary
genvar i;
generate
    assign rd_addr_gray2bin[ADDR_WIDTH - 1] = rd_addr_gray_sync[ADDR_WIDTH - 1];
    for (i = ADDR_WIDTH - 2; i >= 0; i = i - 1) begin
        assign rd_addr_gray2bin[i] = rd_addr_gray2bin[i + 1] ^ rd_addr_gray_sync[i];
    end
endgenerate
// always @ (*) begin: RD_ADDR_GRAY_2_BIN
//     integer idx;
//     rd_addr_gray2bin[ADDR_WIDTH - 1] = rd_addr_gray_sync[ADDR_WIDTH - 1];
//     for (idx = ADDR_WIDTH - 2; idx >= 0; idx = idx - 1) begin
//         rd_addr_gray2bin[idx] = rd_addr_gray2bin[idx + 1] ^ rd_addr_gray_sync[idx];
//     end
// end

assign wr_gap = wr_addr[ADDR_WIDTH] ^ rd_addr_gray2bin[ADDR_WIDTH] ?
                rd_addr_gray2bin[ADDR_WIDTH-1:0] - wr_addr[ADDR_WIDTH-1:0] :
                FIFO_DEEP - (wr_addr - rd_addr_gray2bin);

assign almost_full = wr_gap < ALMOST_FULL_GAP;
assign full = wr_gap == 0;

// always @ (*) begin
//     if (wr_addr[ADDR_WIDTH] ^ rd_addr_gray2bin[ADDR_WIDTH])
//         wr_gap = rd_addr_gray2bin[ADDR_WIDTH-1:0] - wr_addr[ADDR_WIDTH-1:0];
//     else
//         wr_gap = FIFO_DEEP - (wr_addr - rd_addr_gray2bin);
// end

// always @ (*) begin
//     if (wr_gap < ALMOST_FULL_GAP)
//         almost_full = 1;
//     else
//         almost_full = 0;
// end

// always @ (*) begin
//     full = wr_gap == 0;
// end

// Read

// FWFT read mode, first word fall through
assign rd_data = ram[rd_addr];

always @ (posedge rd_clk or negedge rd_rst_n) begin
    if (!rd_rst_n) begin
        rd_addr <= {(ADDR_WIDTH + 1){1'b0}};
    end
    else if (rd_en && !empty)
        rd_addr <= rd_addr + 1;
end

// Read address to Gray code
assign rd_addr_gray = rd_addr ^ (rd_addr >> 1);
// always @ (*) begin
//     rd_addr_gray = rd_addr ^ (rd_addr >> 1);
// end

// Sync write address Gray code w.r.t. read clock
always @ (posedge rd_clk or negedge rd_rst_n) begin
    if (!rd_rst_n) begin
        wr_addr_gray_tmp <= {(ADDR_WIDTH + 1){1'b0}};
        wr_addr_gray_sync <= {(ADDR_WIDTH + 1){1'b0}};
    end
    else begin
        wr_addr_gray_tmp <= wr_addr_gray;
        wr_addr_gray_sync <= wr_addr_gray_tmp;
    end
end

// Convert sync-ed write address Gray code to binary
genvar j;
generate
    assign wr_addr_gray2bin[ADDR_WIDTH - 1] = wr_addr_gray_sync[ADDR_WIDTH - 1];
    for (j = ADDR_WIDTH - 2; j >= 0; j = j - 1) begin
        assign wr_addr_gray2bin[j] = wr_addr_gray2bin[j + 1] ^ wr_addr_gray_sync[j];
    end
endgenerate
// always @ (*) begin: WR_ADDR_GRAY_2_BIN
//     integer idx;
//     wr_addr_gray2bin[ADDR_WIDTH - 1] = wr_addr_gray_sync[ADDR_WIDTH - 1];
//     for (idx = ADDR_WIDTH - 2; idx >= 0; idx = idx - 1) begin
//         wr_addr_gray2bin[idx] = wr_addr_gray2bin[idx + 1] ^ wr_addr_gray_sync[idx];
//     end
// end

assign rd_gap = wr_addr_gray2bin - rd_addr_gray;
assign almost_empty = rd_gap < ALMOST_EMPTY_GAP;
assign empty = rd_gap == 0;

// always @ (*) begin
//     rd_gap = wr_addr_gray2bin - rd_addr_gray;
// end

// always @ (*) begin
//     if (rd_gap < ALMOST_EMPTY_GAP)
//         almost_empty = 1;
//     else
//         almost_empty = 0;
// end

// always @ (*) begin
//     empty = rd_gap == 0;
// end

endmodule

// module async_fifo #(
//     parameter DATA_WIDTH = 8,
//     parameter ADDR_WIDTH = 5
// )(
//     input [DATA_WIDTH-1:0] wdata,
//     input rst_n,
//     input wren, wclk, //写请求信号，写时钟
//     input rden, rclk, //读请求信号，读时钟
//     output [DATA_WIDTH-1:0] rdata,
//     output wfull,
//     output rempty
//     );

// localparam CAPACITY = 2**ADDR_WIDTH;

// reg [DATA_WIDTH-1:0] ram [0:(2**ADDR_WIDTH)-1];
// reg [ADDR_WIDTH-1:0] waddr, raddr;
// reg [ADDR_WIDTH-1:0] waddr_r, raddr_w;
// reg wren_r, rden_w;
// reg addr_round;
// wire wempty, rfull;

// always @ (posedge wclk or negedge rst_n) begin
//     if (!rst_n) begin
//         waddr <= 0;
//         addr_round <= 0;
//     end
//     else if (wren && !rden_w && !wfull) begin
//         ram[waddr] <= wdata;
//         waddr <= waddr + 1;
//         if (waddr == CAPACITY - 1) begin
//             addr_round <= 1;
//         end
//     end
//     else if (!wren && rden_w && !rempty) begin
//     end
//     else if (wren && rden_w) begin
//         waddr <= waddr + 1;
//         if (waddr == CAPACITY - 1) begin
//             addr_round <= 1;
//         end
//     end
// end

// always @ (posedge wclk or negedge rst_n) begin
//     if (!rst_n) begin
//         rden_w <= 0;
//         raddr_w <= 0;
//     end
//     else begin
//         rden_w <= rden;
//         raddr_w <= raddr;
//     end
// end

// assign wfull = addr_round && (waddr == raddr_w);
// assign wempty = !addr_round && (waddr == raddr_w);


// always @ (posedge rclk or negedge rst_n) begin
//     if (!rst_n) begin
//         raddr <= 0;
//     end
//     else if (rden && !wren_r && !rempty) begin
//         raddr <= raddr + 1;
//         if (raddr == CAPACITY - 1) begin
//             addr_round <= 0;
//         end
//     end
//     else if (!rden && wren_r && !rfull) begin
//     end
//     else if (rden && wren_r) begin
//         raddr <= raddr + 1;
//         if (raddr == CAPACITY - 1) begin
//             addr_round <= 0;
//         end
//     end
// end

// always @ (posedge rclk or negedge rst_n) begin
//     if (!rst_n) begin
//         wren_r <= 0;
//         waddr_r <= 0;
//     end
//     else begin
//         wren_r <= wren;
//         waddr_r <= waddr;
//     end
// end

// assign rdata = ram[raddr];
// assign rfull = addr_round && (raddr == waddr_r);
// assign rempty = !addr_round && (raddr == waddr_r);

// endmodule
