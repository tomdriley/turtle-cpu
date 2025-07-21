; Branch if Zero instruction test (taken)
; Expected result: ACC = 0 (SET 1 should be skipped)
start:
    SET 0
    BZ end
    SET 1
end:
    HALT
