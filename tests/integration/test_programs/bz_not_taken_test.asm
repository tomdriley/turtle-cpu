; Branch if Zero instruction test (not taken)
; Expected result: ACC = 0 (SET 0 should execute)
start:
    SET 1
    BZ end
    SET 0
end:
    HALT
