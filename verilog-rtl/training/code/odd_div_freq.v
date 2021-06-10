`timescale 1ns / 1ps

module odd_div_freq(
    input clk,
    input rst_n,

    output oclk
    );

parameter DIV = 3;
localparam CNT_WIDTH = $clog2(DIV + 1);

reg [CNT_WIDTH-1:0] cnt;
reg clk_tmp;
wire add_cnt, end_cnt;

always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
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
assign end_cnt = add_cnt && cnt == DIV - 1;

wire clk_inv = ~clk;

always @ (*) begin
    if (add_cnt && cnt <= (DIV / 2 + 1) - 1)
        clk_tmp = clk;
    else
        clk_tmp = 0;
end

reg clk_inv_tmp;
always @ (*) begin
    if (add_cnt && cnt > (DIV / 2) - 1)
        clk_inv_tmp = 0;
    else
        clk_inv_tmp = clk_inv;
end

assign oclk = clk_inv_tmp | clk_tmp;

endmodule
