// http://hdl.huangzzk.info/

`timescale 1ns / 10ps

module wrong_fsm(clk, rst, q);
input clk, rst;
output reg [3:0] q;
reg [1:0] state;
always @(posedge clk)
    if (rst) state <= 'd0;
    else
        case(state)
            0: begin
                state <= 1;
                q <= 1;
            end
            1: begin
                state <= 2;
                q <= 9;
            end
            2: begin
                state <= 3;
                q <= 3;
            end
            3: begin
                state <= 0;
                q <= 5;
            end
        endcase
endmodule

module correct_fsm(clk, rst, q);
input clk, rst;
output reg [3:0] q;
reg [1:0] state, ns;

//! fsm_extract
always @(posedge clk)
    if (rst) state <= 'd0;
    else state <= ns;

always @(*)
    case(state)
        0: ns = 1;
        1: ns = 2;
        2: ns = 3;
        3: ns = 0;
    endcase

always @(*)
    case(state)
        0: q = 1;
        1: q = 9;
        2: q = 3;
        3: q = 5;
    endcase
endmodule

module tb_fsm;
reg clk;
reg rst;

localparam PERIOD = 10;
localparam RST_CYCLE = 2;

initial begin
    clk=0;
    rst = 1;
    repeat (RST_CYCLE) @(negedge clk);
    rst = 0;
    #100 $finish;
end

always #(PERIOD * 0.5)  clk = ~clk;

wire [3:0] wrong_q, correct_q;

wrong_fsm wf(.clk(clk), .rst(rst), .q(wrong_q));

correct_fsm cf(.clk(clk), .rst(rst), .q(correct_q));


initial begin            
    $dumpfile("wave.vcd");        // generate vcd file
    $dumpvars;
end

endmodule