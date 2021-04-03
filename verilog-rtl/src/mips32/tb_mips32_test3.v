`timescale 1ns / 10ps

module mips32_test3;

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

    mips.Mem[0] = 32'h280a00c8; // ADDI R10, R0, 200
    mips.Mem[1] = 32'h28020001; // ADDI R2, R0, 1
    mips.Mem[2] = 32'h0e94a000; // OR   R20, R20, R20  -- dummy
    mips.Mem[3] = 32'h21430000; // LW   R3, 0(R10)
    mips.Mem[4] = 32'h0e94a000; // OR   R20, R20, R20  -- dummy
    mips.Mem[5] = 32'h14431000; // Loop: MUL R2, R2, R3
    mips.Mem[6] = 32'h2c630001; // SUBI  R3, R3, 1
    mips.Mem[7] = 32'h0e94a000; // OR    R20, R20, R20 -- dummy
    mips.Mem[8] = 32'h3460fffc; // BNEQZ R3, Loop
    mips.Mem[9] = 32'h2542fffe; // SW    R2, -2(R10)
    mips.Mem[10] = 32'hfc000000; // HTL

    mips.Mem[200] = 7; // Find factorial of 7
    mips.PC = 0;
    mips.HALTED = 0;
    mips.TAKEN_BRANCH = 0;

    #2000 $display("Mem[200]=%2d, Mem[198]=%6d",
                   mips.Mem[200], mips.Mem[198]);

    fd = $fopen("tb_mips32_test3.log", "w");
    if (mips.Mem[198] == 5040) begin
        $fdisplay(fd, "%m Test: SUCCESS, at %0d ns", $time);
    end
    else begin
        $fdisplay(fd, "%m Test: FAIL, at %0d ns", $time);
    end
    $fclose(fd);
end
/*
Simulation output:
R2:    2
R2:    1
R2:    7
R2:   42
R2:  210
R2:  840
R2: 2520
R2: 5040
R2: 5040
Mem[200] = 7, Mem[198] = 5040
*/
initial begin
    $dumpfile("mips32_test3.vcd");
    $dumpvars(0, mips32_test3);
    $monitor("R2: %4d", mips.Reg[2]);
    #3000 $finish;
end

endmodule
