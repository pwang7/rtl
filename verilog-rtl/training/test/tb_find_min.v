`timescale 1ns / 1ps

module tb_find_min();

reg[31:0] din0;
reg[31:0] din1;
reg[31:0] din2;
reg[31:0] din3;
wire[1:0] min_idx;

initial begin
    din0 = 9;
    din1 = 5;
    din2 = 2;
    din3 = 7;
end

find_min u_find_min(
    .din0(din0),
    .din1(din1),
    .din2(din2),
    .din3(din0),
    .min_idx(min_idx)
    );
endmodule
