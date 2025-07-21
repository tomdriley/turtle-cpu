; Basic STORE instruction test
; Expected result: Memory[0x000] = 1
start:
    SET 1
    STORE
    HALT
