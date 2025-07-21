; STORE and LOAD with different addresses test
; Expected result: ACC = 10 (0x0A loaded from address 1)
start:
    SET 1
    PUT DOFF    ; Addr <= 0x001
    SET 10      ; 0x0A
    STORE       ; Store 0x0A @ Addr 0x001
    SET 0
    PUT DOFF    ; Addr <= 0x000
    STORE       ; Store 0x00 @ Addr 0x000
    SET 1
    PUT DOFF    ; Addr <= 0x001
    LOAD        ; Load from Addr 0x001
    HALT
