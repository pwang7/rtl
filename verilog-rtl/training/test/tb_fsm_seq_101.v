`timescale 1ns / 1ps

module gen_clk_rst (
    output reg clk,
    output reg rst_n
    );

    localparam PERIOD = 1;
    localparam RST_CYCLE = 2;

	always #(PERIOD * 0.5) clk = ~clk;
    initial begin
        clk = 0;
        rst_n = 0;
        repeat (RST_CYCLE) @(negedge clk);
        rst_n = 1;
    end
endmodule

module tb_fsm_seq_101();
wire clk, rst_n;
gen_clk_rst u_gen_clk_rst(.clk(clk), .rst_n(rst_n));

reg x;
wire z1, z2, z3;
initial begin
    x = 0;
    wait(rst_n == 1);
    @(negedge clk) x = 1;
    @(negedge clk) x = 0;
    @(negedge clk) x = 1;
    @(negedge clk) x = 0;
    @(negedge clk) x = 1;
    @(negedge clk) x = 1;
    @(negedge clk) $stop;
end


answer_01xz uut1(
	.clk(clk),
	.aresetn(rst_n),
	.x(x),
	.z(z1)
);
fsm_seq_101_mealy uut2(
	.clk(clk),
	.aresetn(rst_n),
	.x(x),
	.z(z2)
);
fsm_seq_101_moore uut3(
	.clk(clk),
	.aresetn(rst_n),
	.x(x),
	.z(z3)
);

endmodule
