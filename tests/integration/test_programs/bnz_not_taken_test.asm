; Branch if Not Zero instruction test (not taken)
; Expected result: ACC = 1 (SET 1 should execute)
start:
    SET 0
    BNZ end
    SET 1
end:
    HALT
