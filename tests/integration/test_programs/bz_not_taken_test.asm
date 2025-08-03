; Branch if Zero instruction test (not taken)
; Expected result: ACC = 0 (SET 0 should execute)
start:
    SET 1
    NOP      ; ADDI 0 - sets flags based on ACC=1 (zero flag clear)
    BZ end
    SET 0
end:
    HALT
