; Branch if Not Zero instruction test (taken)
; Expected result: ACC = 1 (SET 0 should be skipped)
start:
    SET 1
    BNZ end
    SET 0
end:
    HALT
