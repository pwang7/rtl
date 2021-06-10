`timescale 1ns / 1ps

module rule_110 #(
    parameter LEN = 512
)(
    input clk,
    input load,
    input [LEN-1:0] data,
    output reg [LEN-1:0] q ); 

    reg [LEN-1:0] q_n, q_v, q_r;
    reg left, center, right;
    always @ (*) begin
        for (integer idx = 0; idx < LEN; idx = idx + 1) begin
            right = (idx > 0) ? q[idx - 1] : 0;
            left = (idx < LEN - 1) ? q[idx + 1] : 0;
            center = q[idx];
            // (q[i] ^ q[i - 1] )|| (!q[i+1] & q[i-1]); 
            q_n[idx] = (right ^ center) | (~left & right);
        end
    end
    always @ (posedge clk) begin
        if (load) begin
            q <= data;
            q_v <= data;
        end
        else begin
            // q <= q_n;
            q <= ({q[LEN-2:0], 1'b0} ^ q) | ( ~{1'b0, q[LEN-1:1]} & {q[LEN-2:0], 1'b0});
            q_r <= q_v;
            q_v <= ({q_v[LEN-2:0], 1'b0} ^ q_v) | ( ~{1'b0, q_v[LEN-1:1]} & {q_v[LEN-2:0], 1'b0});
        end
    end
endmodule
