`timescale 1ns / 1ps

module find_min(
    input [31:0] din0,
    input [31:0] din1,
    input [31:0] din2,
    input [31:0] din3,
    output reg[1:0] min_idx
    );
reg[31:0] din [0:3];

always @ (*) begin
    din[0] = din0;
    din[1] = din1;
    din[2] = din2;
    din[3] = din3;
    min_idx = 0;
    if (din1 < din[min_idx])
        min_idx = 1;
    if (din2 < din[min_idx])
        min_idx = 2;
    if (din3 < din[min_idx])
        min_idx = 3;
end

endmodule
