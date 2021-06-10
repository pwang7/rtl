`timescale 1ns / 1ps

module width_change_8to12 #(
    parameter AWIDTH = 8,
    parameter BWIDTH = 12,
    parameter BUF_WIDTH = 24
)(
    input clk, // system clock 50Mhz on board
    input rst_n,// system rst, low active
    input a_vld,// inputa_vld
    input [AWIDTH-1:0] a,
    output reg b_vld,
    output reg [BWIDTH-1:0] b
    );
localparam CNT_WIDTH = $clog2(BUF_WIDTH + 1);

reg [(BUF_WIDTH - 1):0] buffer;
reg [CNT_WIDTH-1:0] cnt, pos_r;
wire add_cnt, end_cnt;

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

assign add_cnt = a_vld;
assign end_cnt = add_cnt && cnt == BUF_WIDTH / AWIDTH - 1;

wire [CNT_WIDTH-1:0] cur_pos;
assign cur_pos = BUF_WIDTH - 1 - cnt * AWIDTH;

always @ (posedge clk or negedge rst_n) begin
    if (rst_n == 1'b0) begin
        buffer <= {BUF_WIDTH{1'b0}};
        b_vld <= 0;
        pos_r <= BUF_WIDTH - 1;
    end
    else if (add_cnt) begin
        buffer[cur_pos-:AWIDTH] <= a;

        if (pos_r - cur_pos >= BWIDTH) begin
            b_vld <= 1;
            b <= buffer[pos_r-:BWIDTH];
            if (pos_r == BWIDTH - 1)
                pos_r <= BUF_WIDTH -1;
            else
                pos_r <= pos_r - BWIDTH;
        end
        else
            b_vld <= 0;
    end
end
endmodule
