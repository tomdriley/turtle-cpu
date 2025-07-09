`ifndef PROGRAM_COUNTER_PKG_SV
`define PROGRAM_COUNTER_PKG_SV

// program_counter_pkg.sv
// author: Tom Riley
// date: 2025-07-05

package program_counter_pkg;
    typedef enum logic [2:0] {
        COND_ZERO   = 3'b000,
        COND_NOT_ZERO = 3'b001,
        COND_POSITIVE = 3'b010,
        COND_NEGATIVE = 3'b011,
        COND_CARRY_SET = 3'b100,
        COND_CARRY_CLEARED = 3'b101,
        COND_OVERFLOW_SET = 3'b110,
        COND_OVERFLOW_CLEARED = 3'b111
    } branch_condition_e;
endpackage

`endif // PROGRAM_COUNTER_PKG_SV
