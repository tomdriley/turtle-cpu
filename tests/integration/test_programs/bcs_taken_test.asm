; Branch if Carry Set instruction test (taken)
; Expected result: ACC = 5 (0xFF + 6 = 0x105, carry set, SET 0 skipped)
start:
    SET 255   ; 0xFF
    ADDI 6
    BCS end
    SET 0
end:
    HALT
