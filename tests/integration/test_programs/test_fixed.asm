; Test case for fixed mem-compare
start:
    SET 50      ; Set accumulator to 50
    PUT DOFF    ; Set data memory offset to 50 
    SET 200     ; Set accumulator to 200
    STORE       ; Store 200 at address 50
    SET 50      ; Reset accumulator to 50
    PUT DOFF    ; Set data memory offset to 50
    LOAD        ; Load from address 50 (should be 200)
    HALT        ; Stop execution
