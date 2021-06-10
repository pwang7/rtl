`timescale 1ns / 1ps

module even_divide(
    input clk,
    input rst_n,

    output out_clk
    );
parameter DIVISION = 2;
parameter WIDTH = $clog2(DIVISION/2 + 1);

reg[WIDTH-1:0] cnt;
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

assign add_cnt = 1;
assign end_cnt = add_cnt && cnt == DIVISION - 1;

assign out_clk = (add_cnt && cnt < DIVISION/2)? 1 : 0;

endmodule
