`timescale 1ns / 1ps

module bcd_counter(
    input clk,
    input reset,   // Synchronous active-high reset
    output [3:1] ena,
    output [15:0] q);

reg [3:0] cnt0, cnt1, cnt2, cnt3;
assign q = {cnt3, cnt2, cnt1, cnt0};

wire add_cnt0, end_cnt0, add_cnt1, end_cnt1, add_cnt2, end_cnt2, add_cnt3, end_cnt3;
assign ena = {add_cnt3, add_cnt2, add_cnt1};

always @ (posedge clk) begin
    if (reset) begin
        cnt0 <= 0;
    end
    else if (add_cnt0) begin
        if (end_cnt0)
            cnt0 <= 0;
        else
            cnt0 <= cnt0 + 1'b1;
    end
end
assign add_cnt0 = 1;
assign end_cnt0 = add_cnt0 && cnt0 == 10 - 1;

always @ (posedge clk) begin
    if (reset) begin
        cnt1 <= 0;
    end
    else if (add_cnt1) begin
        if (end_cnt1)
            cnt1 <= 0;
        else
            cnt1 <= cnt1 + 1'b1;
    end
end
assign add_cnt1 = end_cnt0;
assign end_cnt1 = add_cnt1 && cnt1 == 10 - 1;

always @ (posedge clk) begin
    if (reset) begin
        cnt2 <= 0;
    end
    else if (add_cnt2) begin
        if (end_cnt2)
            cnt2 <= 0;
        else
            cnt2 <= cnt2 + 1'b1;
    end
end
assign add_cnt2 = end_cnt1;
assign end_cnt2 = add_cnt2 && cnt2 == 10 - 1;

always @ (posedge clk) begin
    if (reset) begin
        cnt3 <= 0;
    end
    else if (add_cnt3) begin
        if (end_cnt3)
            cnt3 <= 0;
        else
            cnt3 <= cnt3 + 1'b1;
    end
end
assign add_cnt3 = end_cnt2;
assign end_cnt3 = add_cnt3 && cnt3 == 10 - 1;

endmodule
