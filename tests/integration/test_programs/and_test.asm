; AND register instruction test
; Expected result: ACC = 4 (0b0110 & 0b0101 = 0b0100)
start:
    SET 6    ; 0b0110
    PUT R0
    SET 5    ; 0b0101
    AND R0
    HALT
