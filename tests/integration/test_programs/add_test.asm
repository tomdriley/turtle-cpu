; ADD register instruction test
; Expected result: ACC = 3 (1 + 2)
start:
    SET 1
    PUT R0
    SET 2
    ADD R0
    HALT
