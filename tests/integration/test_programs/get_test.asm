; GET instruction test  
; Expected result: ACC = 1 (retrieved from R0)
start:
    SET 1
    PUT R0
    SET 0
    GET R0
    HALT
