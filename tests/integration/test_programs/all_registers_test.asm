; Test all general purpose registers
; Expected result: R0=1, R1=2, R2=3, R3=4, R4=5, R5=6, R6=7, R7=8
start:
    SET 1
    PUT R0
    SET 2
    PUT R1
    SET 3
    PUT R2
    SET 4
    PUT R3
    SET 5
    PUT R4
    SET 6
    PUT R5
    SET 7
    PUT R6
    SET 8
    PUT R7
    HALT
