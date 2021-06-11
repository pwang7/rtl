# MIPS32 assembly code bubble sort

ADDI   R3, R0, 100   # begin idx
ADDI   R4, R0, 102   # min idx
ADDI   R5, R0, 109   # max idx, total 10

Begin: ADDI  R1, R3, 0     # pos one
ADDI   R2, R3, 1     # pos two

Comp: LW    R11, 0(R1)
LW    R12, 0(R2)
OR    R20, R20, R20 # dummy
SLT   R13, R11, R12
OR    R20, R20, R20 # dummy
BNEQZ R13, Inc
OR    R20, R20, R20 # dummy
SW    R11, 0(R2)       # swap
SW    R12, 0(R1)

Inc:  SLT   R22, R2, R5
OR    R20, R20, R20 # dummy
BEQZ  R22, Cond     # finish condition check
OR    R20, R20, R20 # dummy
ADDI  R1, R1, 1
ADDI  R2, R2, 1
BEQZ  R0, Comp      # next
OR    R20, R20, R20 # dummy

Cond: SLT  R21, R4, R5
OR    R20, R20, R20 # dummy
BEQZ  R21, Done
OR    R20, R20, R20 # dummy
SUBI  R5, R5, 1
BEQZ  R0, Begin     # rewind
OR    R20, R20, R20 # dummy

Done: HLT
