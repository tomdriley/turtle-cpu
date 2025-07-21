; Branch if Carry Set instruction test (not taken)
; Expected result: ACC = 0 (0xFE + 1 = 0xFF, no carry, SET 0 executes)
start:
    SET 254   ; 0xFE
    ADDI 1
    BCS end
    SET 0
end:
    HALT
