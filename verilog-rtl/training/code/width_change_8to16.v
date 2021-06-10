`timescale 1ns / 1ps

module width_change_8to16 #(
    parameter AWIDTH = 8,
    parameter BWIDTH = 16
)(
    input clk,
    input rst_n,
    input a_vld,
    input [AWIDTH-1:0] a,
    output reg b_vld,
    output reg [BWIDTH-1:0] b
    );

localparam CNT_MAX = BWIDTH / AWIDTH;
localparam CNT_WIDTH = $clog2(CNT_MAX + 1);

reg [CNT_WIDTH-1:0] cnt;
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
assign end_cnt = add_cnt && cnt == CNT_MAX - 1;

always @ (posedge clk or negedge rst_n) begin
    if (rst_n == 1'b0) begin
        b <= 0;
        b_vld <= 0;
    end
    else if (add_cnt) begin
        b[(BWIDTH - 1 - cnt * AWIDTH)-:AWIDTH] <= a;
        if (end_cnt)
            b_vld <= 1;
        else
            b_vld <= 0;
    end
end

endmodule
