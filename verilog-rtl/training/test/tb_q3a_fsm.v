`timescale 1ns / 1ps

module tb_q3a_fsm();

localparam CYCLE = 2;

reg clk, reset, s, w;
wire z, z2;

always #(CYCLE/2) clk = ~clk;

initial begin
    clk = 1;
    reset = 1;
    s = 0;
    w = 0;
    repeat (2) @(negedge clk);
    reset = 0;
    @(negedge clk);
    s = 0;
    @(negedge clk);
    s = 1;

    w = 0;
    @(negedge clk);
    w = 1;
    @(negedge clk);
    w = 0;

    @(negedge clk);
    w = 1;
    @(negedge clk);
    w = 1;
    @(negedge clk);
    w = 0;

    @(negedge clk);
    w = 0;
    @(negedge clk);
    w = 0;
    @(negedge clk);
    w = 0;

    @(negedge clk);
    w = 1;
    @(negedge clk);
    w = 1;
    @(negedge clk);
    w = 1;

    @(negedge clk);
    w = 0;
    @(negedge clk);
    w = 1;
    @(negedge clk);
    w = 1;

    @(negedge clk);
    w = 0;
    @(negedge clk);
    w = 0;
    @(negedge clk);
    w = 1;

    @(negedge clk);
    w = 1;
    @(negedge clk);
    w = 0;
    @(negedge clk);
    w = 1;
end

q3a_fsm u_q3a_fsm(
    .clk(clk),
    .reset(reset),   // Synchronous reset
    .s(s),
    .w(w),
    .z(z)
);

q3a_fsm2 u_q3a_fsm2(
    .clk(clk),
    .reset(reset),   // Synchronous reset
    .s(s),
    .w(w),
    .z(z2)
);
endmodule
