`timescale 1ns / 1ps

module tb_serial_fsm();

localparam CYCLE = 2;
localparam RST_CYCLE = 2;

reg clk, reset, in;
reg [7:0] data;
wire [7:0] byte, byte2;
wire done, done2;
reg [3:0] idx;

always #(CYCLE/2) clk = ~clk;

initial begin
    clk = 1;
    reset = 1;
    in = 1;
    data = 8'hA5;
    repeat (RST_CYCLE) @(negedge clk);
    reset = 0;
    @(negedge clk) in = 0;
    idx = 0;
    repeat (8) begin
        @(negedge clk);
        idx = idx + 1;
        in = data[8 - idx];
    end
    @(negedge clk) in = 1;
    repeat (10) @(negedge clk);
    $stop;
end

serial_fsm uut(
    .clk(clk),
    .in(in),
    .reset(reset),    // Synchronous reset
    .out_byte(byte),
    .done(done)
    );

serial_fsm2 uut2(
    .clk(clk),
    .in(in),
    .reset(reset),    // Synchronous reset
    .out_byte(byte2),
    .done(done2)
    );
endmodule
