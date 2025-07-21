; INV (invert/NOT) instruction test
; Expected result: ACC = 240 (0b11110000)
start:
    SET 15   ; 0b00001111
    INV
    HALT
