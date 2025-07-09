`ifndef ALU_PKG_SV
`define ALU_PKG_SV

// alu_pkg.sv
// author: Tom Riley
// date: 2025-07-05

package alu_pkg;
    // ALU function enumeration
    typedef enum logic [2:0] {
        ADD        = 3'b000,
        SUB        = 3'b001,
        AND        = 3'b010,
        OR         = 3'b100,
        XOR        = 3'b101,
        INV        = 3'b111
    } alu_func_e;
endpackage: alu_pkg

`endif // ALU_PKG_SV
