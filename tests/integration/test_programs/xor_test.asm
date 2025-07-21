; XOR register instruction test
; Expected result: ACC = 5 (0b0110 ^ 0b0011 = 0b0101)
start:
    SET 6    ; 0b0110
    PUT R0
    SET 3    ; 0b0011
    XOR R0
    HALT
