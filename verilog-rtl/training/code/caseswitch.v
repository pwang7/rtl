`timescale 1ns / 1ps

module caseswitch(
    input clk,
    input rst_n,

    input [3:0] data,

    output reg[2:0] add
    );

always @ (posedge clk or negedge rst_n) begin
    if (!rst_n)
        add <= 3'd0;
    else
        case(data)
            0,1,2,3: add <= 1;
            4,5,6,7: add <= 2;
            8,9,10,11: add <= 3;
            12,13,14,15: add <= 4;
            default: ;
        endcase
end
endmodule
