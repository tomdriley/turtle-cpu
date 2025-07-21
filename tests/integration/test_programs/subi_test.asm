; SUBI (subtract immediate) instruction test
; Expected result: ACC = 3 (5 - 2)
start:
    SET 5
    SUBI 2
    HALT
