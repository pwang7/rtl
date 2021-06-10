`timescale 1ns / 1ps

module Serial2Pal(
    input Clk,
    input din,
    input ena,
    output reg [3:0] dout = 4'b0000
    );

always @ (posedge Clk)
    if(ena)
        dout <= {dout[2:0],din};
    else
        dout <= dout;
endmodule