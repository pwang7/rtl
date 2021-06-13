module tb_ripple_carry_adder;

reg [31:0] input1,input2, expected;
wire [31:0] actual;
integer seed;

ripple_carry_adder dut(input1, input2, actual);

initial begin
    $dumpportsall;
    $dumpfile("wave.vcd");        // generate vcd file
    $dumpvars;
end

initial begin
    seed = 0;
    repeat(10) begin
        input1 = $random(seed);
        input2 = $random(seed);
        expected = input1 + input2;
        #1;
        if (actual != expected) $display("ERROR: %0d+%0d was %0d expected %0d",
            input1, input2, actual, expected);
        #9;
    end
    $finish(2);
end

endmodule
