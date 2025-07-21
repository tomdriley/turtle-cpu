; SUB register instruction test
; Expected result: ACC = 2 (5 - 3)
start:
    SET 3
    PUT R0
    SET 5
    SUB R0
    HALT
