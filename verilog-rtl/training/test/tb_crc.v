`timescale 1ns / 1ps

module tb_crc();

localparam integer CYCLE = 2;

reg clk;
reg rst_n;
reg en;
reg[31:0] din;
wire[9:0] dout;
integer d;
initial begin
    clk = 0;
    rst_n = 0;
    #(3 * CYCLE) rst_n = 1;
end

initial begin
    en = 0;
    d = 0;
    wait(rst_n == 1);
    repeat(100) begin
        d = d + 1;
        #CYCLE din = d;
        en = 1;
    end
    en = 0;
end
always #(CYCLE/2) clk = ~clk;

crc u_crc(
    .clk(clk),
    .rst_n(rst_n),
    .en(en),
    .din(din),
    .dout(dout)
    );
endmodule
