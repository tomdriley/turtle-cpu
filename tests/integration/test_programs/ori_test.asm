; ORI (OR immediate) instruction test
; Expected result: ACC = 6 (0b0010 | 0b0100 = 0b0110)
start:
    SET 2    ; 0b0010
    ORI 4    ; 0b0100
    HALT
