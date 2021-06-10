`timescale 1ns / 1ps

module clock_time_counter(
    input clk,
    input reset,
    input ena,
    output pm,
    output [7:0] hh,
    output [7:0] mm,
    output [7:0] ss); 

    reg [3:0] cnt0, cnt1, cnt2, cnt3, cnt4, cnt5;
    assign hh = (cnt5 == 0 && cnt4 == 0) ? {4'd1, 4'd2} : {cnt5, cnt4};
    // assign hh = {cnt5, cnt4};
    assign mm = {cnt3, cnt2};
    assign ss = {cnt1, cnt0};
    reg pm_r;
    assign pm = pm_r;
    
    wire add_cnt0, end_cnt0, add_cnt1, end_cnt1, add_cnt2, end_cnt2, add_cnt3, end_cnt3, add_cnt4, end_cnt4, add_cnt5, end_cnt5;

    wire [3:0] X;
    assign X = (cnt5 == 0) ? 10 : 2;
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
    assign add_cnt0 = ena;
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
    assign end_cnt1 = add_cnt1 && cnt1 == 6 - 1;

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
    assign end_cnt3 = add_cnt3 && cnt3 == 6 - 1;

    always @ (posedge clk) begin
        if (reset) begin
            cnt4 <= 0;
        end
        else if (add_cnt4) begin
            if (end_cnt4)
                cnt4 <= 0;
            else
                cnt4 <= cnt4 + 1'b1;
        end
    end
    assign add_cnt4 = end_cnt3;
    assign end_cnt4 = add_cnt4 && cnt4 == X - 1;

    always @ (posedge clk) begin
        if (reset) begin
            cnt5 <= 0;
        end
        else if (add_cnt5) begin
            if (end_cnt5)
                cnt5 <= 0;
            else
                cnt5 <= cnt5 + 1'b1;
        end
    end
    assign add_cnt5 = end_cnt4;
    assign end_cnt5 = add_cnt5 && cnt5 == 2 - 1;

    always @ (posedge clk) begin
        if (reset)
            pm_r <= 0;
        else if (end_cnt5)
            pm_r <= ~pm_r;
    end
endmodule
