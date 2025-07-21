; Branch if Carry Clear instruction test (taken)
; Expected result: ACC = 255 (0xFE + 1 = 0xFF, no carry, SET 0 skipped)
start:
    SET 254   ; 0xFE
    ADDI 1
    BCC end
    SET 0
end:
    HALT
