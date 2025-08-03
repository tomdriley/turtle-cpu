; Branch if Zero instruction test (taken)
; Expected result: ACC = 0 (SET 1 should be skipped)
start:
    SET 1
    SUBI 1   ; ACC = 0, sets zero flag
    BZ end
    SET 1
end:
    HALT
