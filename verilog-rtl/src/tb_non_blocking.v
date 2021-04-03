`timescale 1ns / 1ps

module non_block #(
    parameter WIDTH = 64
)(
    input       clk,
    input       rst_n,
    input [WIDTH-1:0] a,
    output reg [WIDTH-1:0] b,
    output reg [WIDTH-1:0] c
    );

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

    reg [63:0] u64 = 'b1;

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

initial begin            
    $dumpfile("wave.vcd");        // generate vcd file
    $dumpvars;
end

endmodule

module tb_delta_delay;
reg clk1;
reg clk2;
// reg clk3;
reg data;
reg d_in, d_out;
reg d_delta1, d_delta2;
reg reset;

initial begin
    reset = 1;
    data= 0;
    #15;
    reset = 0;
    #15;
    @(posedge clk1);
    data = 1;
    @(posedge clk1);
    data = 0;
    #50;
    $finish(2);
end
    
initial begin
    clk1 = 0;
    forever #5 clk1 = ~clk1;
end

always @(*) begin
    clk2 <= clk1;
    // clk3 <= clk2;
end

// always @(*) begin
//     d_delta1 <= d_in;
//     d_delta2 <= d_delta1;
// end

always @(posedge clk1)
    if(reset) d_in <= 1'b0;
    else d_in <= data;
    
always @(posedge clk2)
    if(reset) d_out <= 1'b0;
    else d_out <= d_in;

endmodule
