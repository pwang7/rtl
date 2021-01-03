`timescale 1ns / 1ps

module non_block #(
    parameter WIDTH = 64
)(
    input       clk,
    input       rst_n,
    input  [WIDTH-1:0] a,
    output [WIDTH-1:0] b,
    output [WIDTH-1:0] c
    );
reg [WIDTH-1:0] b,c;

always@(posedge clk) begin
    if (!rst_n) begin
        b <= 'b1;
	c <= 'b1;
    end
    else begin
        b <= a;
        c <= b;
    end
end
endmodule


module tb_non_block;

    localparam WIDTH = 4;

    // Inputs
    `include "clk_rst_gen.vh"
    //reg clk;
    reg [WIDTH-1:0] a;

    // Outputs
    wire [WIDTH-1:0] b;
    wire [WIDTH-1:0] c;

    // Instantiate the Unit Under Test (UUT)
    non_block #(.WIDTH(WIDTH)) uut (
        .clk(clk), 
	.rst_n(rst_n),
        .a(a), 
        .b(b), 
        .c(c)
    );

    initial begin
        clk = 0;
        forever #50 clk = ~clk;
    end

    initial begin
        a = 'b1;
	wait(rst_n == 'b1);
       	@(posedge clk) a <= 'h3;
        $display("____________________________");
	repeat (3) @(negedge clk);
        @(posedge clk) a = 'h7;
        $display("____________________________");
	repeat (3) @(negedge clk);
        @(posedge clk) a <= 'h5;
        $display("____________________________");
	repeat (3) @(negedge clk);
        @(posedge clk) a = 'h2;
        $display("____________________________");
	repeat (3) @(negedge clk);
        @(posedge clk) a <= 'h4;
        $display("____________________________");
        //$stop;
    end

endmodule
