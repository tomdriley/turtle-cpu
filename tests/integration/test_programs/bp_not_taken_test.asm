; Branch if Positive instruction test (not taken)
; Expected result: ACC = 1 (SET 1 should execute)
start:
    SET -1
    BP end
    SET 1
end:
    HALT
