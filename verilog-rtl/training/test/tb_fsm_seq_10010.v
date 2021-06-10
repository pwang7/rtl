`timescale 1ns / 1ps

module tb_fsm_seq_10010();
    reg clk;
    reg rst_n;
    reg [23:0] data;
    wire z1, z2, x;

    assign x = data[23];

    always #10 clk = ~clk;

    always @(posedge clk)
        data = {data[22:0],data[23]};
        
    initial begin
        clk = 0;
        rst_n = 1;
        #2 rst_n = 0;
        #30 rst_n = 1;
        data = 'b1100_1001_0000_1001_0010;
        #1000 $stop;
    end

    fsm_seq_10010_mealy dut(
        .clk(clk),
        .rst_n(rst_n),
        .x(x),
        .z(z1)
        );

    fsm_seq_10010_moore uut(
        .clk(clk),
        .rst_n(rst_n),
        .x(x),
        .z(z2)
        );
endmodule
