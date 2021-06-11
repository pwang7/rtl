# MIPS32 assembly code with if condition

ADDI  R1, R0, 2
ADDI  R2, R0, 4
ADDI  R3, R0, 1
ADD   R4, R1, R2    # 6
MUL   R5, R1, R2    # 8
SLT   R6, R4, R5    # true
OR    R20, R20, R20 # dummy
BEQZ  R6, Cond1     # jump
OR    R20, R20, R20 # dummy
BNEQZ R6, Cond2
OR    R20, R20, R20 # dummy
Cond2: ADD R3, R4, R0
Cond1: ADD R3, R5, R0
HLT
