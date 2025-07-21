; XORI (XOR immediate) instruction test
; Expected result: ACC = 5 (0b0110 ^ 0b0011 = 0b0101)
start:
    SET 6    ; 0b0110
    XORI 3   ; 0b0011
    HALT
