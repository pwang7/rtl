`timescale 1ns / 1ps

module tb_rr_sched();
reg clk;
reg rst_n;
reg q0_rdy;
reg q1_rdy;
reg q2_rdy;
wire [2:0] sel;

initial begin
    clk = 0;
    rst_n = 0;
    q0_rdy = 0;
    q1_rdy = 0;
    q2_rdy = 0;
    #5
    rst_n = 1;
    #20
    q0_rdy = 1;
    q1_rdy = 1;
    q2_rdy = 1;
    #100
    q0_rdy = 1;
    q1_rdy = 1;
    q2_rdy = 0;
    #100
    q0_rdy = 1;
    q1_rdy = 0;
    q2_rdy = 0;
    #100
    q0_rdy = 0;
    q1_rdy = 0;
    q2_rdy = 0;
end

always #10 clk = ~clk;

rr_sched u_rr_sched(
    .clk(clk),
    .rst_n(rst_n),
    .q0_rdy(q0_rdy),
    .q1_rdy(q1_rdy),
    .q2_rdy(q2_rdy),
    .sel(sel)
    );
endmodule
