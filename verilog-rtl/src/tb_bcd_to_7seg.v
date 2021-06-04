`timescale 1ns/100ps

module testbench;
reg clk;
reg reset;
reg [31:0] ii;
reg [31:0] error_count;
reg [3:0] bcd;
wire [6:0] seven_seg_display; 
parameter TP = 1;
parameter CLK_HALF_PERIOD = 5;
 
// assign clk = #CLK_HALF_PERIOD ~clk;  // Create a clock with a period of ten ns
initial begin
    clk = 0;
    #5;
    forever clk = #( CLK_HALF_PERIOD )  ~clk;
end

initial begin
    $dumpfile("wave.vcd");
    $dumpvars;
    // clk  = #CLK_HALF_PERIOD ~clk;
    $display("%0t, Reseting system", $time);
    error_count = 0;
    bcd  = 4'h0;
    reset = #TP 1'b1;
    repeat (30) @ (posedge clk);
    reset  = #TP 1'b0;
    repeat (30) @ (posedge clk);
    $display("%0t, Begin BCD test", $time); // This displays a message

    for (ii = 0; ii < 10; ii = ii + 1) begin
        repeat (1) @ (posedge clk);
        bcd  = ii[3:0];
        repeat (1) @ (posedge clk);
        if (seven_seg_display !== seven_seg_prediction(bcd)) begin
            $display(
                "%0t, ERROR: For BCD %d, module output 0b%07b does not match prediction logic value of 0b%07b.",
                $time, bcd, seven_seg_display, seven_seg_prediction(bcd)
            );
            error_count = error_count + 1;
        end
    end
    $display("%0t, Test Complete with %d errors", $time, error_count);
    $display("%0t, Test %s", $time, ~|error_count ? "pass." : "fail.");
    $finish; // This causes the simulation to end.
end

parameter SEG_A = 7'b0000001;
parameter SEG_B = 7'b0000010;
parameter SEG_C = 7'b0000100;
parameter SEG_D = 7'b0001000;
parameter SEG_E = 7'b0010000;
parameter SEG_F = 7'b0100000;
parameter SEG_G = 7'b1000000;

function [6:0] seven_seg_prediction;
    input [3:0] bcd_in;

    // +--- A ---+
    // |         |
    // F         B
    // |         |
    // +--- G ---+
    // |         |
    // E         C
    // |         |
    // +--- D ---+

    begin
        case (bcd_in)
            4'h0: seven_seg_prediction = SEG_A | SEG_B | SEG_C | SEG_D | SEG_E | SEG_F;
            4'h1: seven_seg_prediction = SEG_B | SEG_C;
            4'h2: seven_seg_prediction = SEG_A | SEG_B | SEG_G | SEG_E | SEG_D;
            4'h3: seven_seg_prediction = SEG_A | SEG_B | SEG_G | SEG_C | SEG_D;
            4'h4: seven_seg_prediction = SEG_F | SEG_G | SEG_B | SEG_C;
            4'h5: seven_seg_prediction = SEG_A | SEG_F | SEG_G | SEG_C | SEG_D;
            4'h6: seven_seg_prediction = SEG_A | SEG_F | SEG_G | SEG_E | SEG_C | SEG_D;
            4'h7: seven_seg_prediction = SEG_A | SEG_B | SEG_C;
            4'h8: seven_seg_prediction = SEG_A | SEG_B | SEG_C | SEG_D | SEG_E | SEG_F | SEG_G;
            4'h9: seven_seg_prediction = SEG_A | SEG_F | SEG_G | SEG_B | SEG_C;
            default: seven_seg_prediction = 7'h0;
        endcase
    end
endfunction

bcd_to_7seg u0_bcd_to_7seg (
    .clk               (clk),
    .reset             (reset),
    .bcd               (bcd),
    .seven_seg_display (seven_seg_display)
);


endmodule
