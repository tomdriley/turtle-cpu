; Branch if Positive instruction test (taken)
; Expected result: ACC = 1 (SET 0 should be skipped)
start:
    SET 1
    ADDI 0   ; NOP - sets flags based on ACC=1 (positive)
    BP end
    SET 0
end:
    HALT
