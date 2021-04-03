`timescale 1ns / 10ps

module mips32_test1;

reg clk1, clk2;
initial begin
    clk1 = 0;
    clk2 = 0;
    forever begin
        #5 clk1 = 1; #5 clk1 = 0;
        #5 clk2 = 1; #5 clk2 = 0;
    end
end

MIPS32 mips(.clk1(clk1), .clk2(clk2));

integer k, fd;
initial begin
    for (k = 0; k < 31; k = k + 1) mips.Reg[k] = k;

    mips.Mem[0] = 32'h2801000a; // ADDI R1, R0, 10
    mips.Mem[1] = 32'h28020014; // ADDI R2, R0, 20
    mips.Mem[2] = 32'h28030019; // ADDI R3, R0, 25
    mips.Mem[4] = 32'h0ce77800; // OR   R7, R7, R7 -- dummy
    mips.Mem[3] = 32'h0ce77800; // OR   R7, R7, R7 -- dummy
    mips.Mem[5] = 32'h00222000; // ADD  R4, R1, R2
    mips.Mem[6] = 32'h0ce77800; // OR   R7, R7, R7 -- dummy
    mips.Mem[7] = 32'h00832800; // ADD  R5, R4, R3
    mips.Mem[8] = 32'hfc000000; // HTL

    mips.HALTED = 0;
    mips.PC = 0;
    mips.TAKEN_BRANCH = 0;

    #280
    for (k = 0; k < 6; k = k + 1)
        $display("R%1d - %2d", k, mips.Reg[k]);

    fd = $fopen("tb_mips32_test1.log", "w");
    if (mips.Reg[5] == 55) begin
        $fdisplay(fd, "%m Test: SUCCESS, at %0d ns", $time);
    end
    else begin
        $fdisplay(fd, "%m Test: FAIL, at %0d ns", $time);
    end
    $fclose(fd);
end
/*
Simulation output:
R0 -  0
R1 - 10
R2 - 20
R3 - 25
R4 - 30
R5 - 55
*/
initial begin
    $dumpfile("mips32_test1.vcd");
    $dumpvars(0, mips32_test1);
    // #300 $finish;
end
endmodule
