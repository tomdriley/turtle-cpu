; Basic LOAD instruction test
; Expected result: ACC = 1 (loaded from memory)
start:
    SET 1
    STORE
    SET 0
    LOAD
    HALT
