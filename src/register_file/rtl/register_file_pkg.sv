`ifndef REGISTER_FILE_PKG_SV
`define REGISTER_FILE_PKG_SV

// register_file_pkg.sv
// author: Tom Riley
// date: 2025-07-03

// Register encoding package
package register_file_pkg;
    typedef enum logic [3:0] {
        REG_R0     = 4'b0000,
        REG_R1     = 4'b0001,
        REG_R2     = 4'b0010,
        REG_R3     = 4'b0011,
        REG_R4     = 4'b0100,
        REG_R5     = 4'b0101,
        REG_R6     = 4'b0110,
        REG_R7     = 4'b0111,
        REG_ACC    = 4'b1000,
        REG_DBAR   = 4'b1001,
        REG_DOFF   = 4'b1010,
        REG_IBAR   = 4'b1101,
        REG_IOFF   = 4'b1110,
        REG_STATUS = 4'b1111
    } reg_addr_e;

    typedef enum int {
        ZERO_FLAG     = 0,
        NEGATIVE_FLAG = 1,
        CARRY_FLAG    = 2,
        OVERFLOW_FLAG = 3
    } status_flag_e;
endpackage

`endif // REGISTER_FILE_PKG_SV
