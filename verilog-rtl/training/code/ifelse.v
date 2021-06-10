`timescale 1ns / 1ps

module ifelse(
    input clk,
    input rst_n,

    input [3:0] data,

    output reg[2:0] add
    );

always @ (posedge clk or negedge rst_n) begin
    if (!rst_n)
        add <= 3'd0;
    else
        if (data < 4)
            add <= 1;
        else if (data < 8)
            add <= 2;
        else if (data < 12)
            add <= 3;
        else
            add <=4;
end
endmodule
