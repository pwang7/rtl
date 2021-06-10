`timescale 1ns / 1ps

module edge_test(
    input clk,
    input rst_n,

    input a,
    
    output y1,
    output y2,
    output y3
    );
reg a_r ;

always @ (posedge clk or negedge rst_n) begin
    if (rst_n == 1'b0)
        a_r <= 1'b0 ;
    else
        a_r <= a;
end

assign y1 = a & ~a_r;
assign y2 = ~a & a_r;
assign y3 = a ^ a_r;

endmodule
