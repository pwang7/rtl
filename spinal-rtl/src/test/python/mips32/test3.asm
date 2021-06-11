# MIPS32 assembly code with loop

ADDI R10, R0, 200
ADDI R2, R0, 1
OR   R20, R20, R20  # dummy
LW   R3, 0(R10)
OR   R20, R20, R20  # dummy
Loop: MUL R2, R2, R3
SUBI  R3, R3, 1
OR    R20, R20, R20 # dummy
BNEQZ R3, Loop
SW    R2, -2(R10)
HLT
