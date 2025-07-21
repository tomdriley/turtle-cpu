; Branch if Negative instruction test (taken)
; Expected result: ACC = -1 (SET 0 should be skipped)
start:
    SET -1
    BN end
    SET 0
end:
    HALT
