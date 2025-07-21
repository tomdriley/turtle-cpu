; Branch if Carry Clear instruction test (not taken)
; Expected result: ACC = 0 (0xFF + 6 = 0x105, carry set, SET 0 executes)
start:
    SET 255   ; 0xFF
    ADDI 6
    BCC end
    SET 0
end:
    HALT
