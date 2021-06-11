ADDI R1, R0, 120
OR   R3, R3, R3  # dummy
LW   R2, 0(R1)
OR   R3, R3, R3  # dummy
ADDI R2, R2, 45
OR   R3, R3, R3  # dummy
SW   R2, 1(R1)
HLT
