; Jump immediate instruction test
; Expected result: ACC = 0 (SET 1 should be skipped)
start:
    SET 0
    JMPI end
    SET 1
end:
    HALT
