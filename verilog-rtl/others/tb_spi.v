`timescale  1ns/1ps

`define sin_data_file "./sin_12bit.txt"

module tb_spi;

reg clk;
reg rst_n;
reg start;
reg [2:0] channel;

wire SCLK;
wire DIN;
wire CS_N;
reg DOUT;

wire done;
wire [11:0] data;

reg [11:0] memory [4095:0];
reg [11:0] address;

SPI SPI_inst(
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .channel(channel),

    .SCLK(SCLK),
    .DIN(DIN),
    .DOUT(DOUT),

    .done(done),
    .data(data)
);

initial clk = 'b1;
always #10 clk = ~clk;

initial $readmemh(`sin_data_file, memory);

integer i;

initial begin
    rst_n = 'b0;
    channel = 'd0;
    start = 'b0;
    DOUT = 'b0;
    address = 0;
    #100;
    rst_n = 'b1;
    #100;
    channel = 'd3;
    for (i = 0; i < 3; i = i + 1) begin
        for (address = 0; address < 4095; address = address + 1) begin
            start = 'b1;
            #20;
            start = 'b0;
            gene_DOUT(memory[address]);
            @(posedge done);
            #200;
        end
    end
    #20000;
    $stop;
end

task gene_DOUT;
    input [15:0] vdata;
    reg [4:0] cnt;
    begin
        cnt = 0;
        wait(!CS_N);
        while (cnt < 16) begin
            @(posedge SCLK) DOUT = vdata[15 - cnt];
            cnt = cnt + 'b1;
        end
    end
endtask

endmodule