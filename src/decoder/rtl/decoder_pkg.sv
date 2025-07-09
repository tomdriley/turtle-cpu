`ifndef DECODER_PKG_SV
`define DECODER_PKG_SV

// decoder_pkg.sv
// author: Tom Riley
// date: 2025-07-09

package decoder_pkg;
    localparam int BRANCH_INSTRUCTION_OFFSET = 0;
    localparam int BRANCH_CONDITION_LSB = 1;
    localparam int BRANCH_CONDITION_MSB = 3;
    localparam int OP_LSB = 1;
    localparam int OP_MSB = 3;
    localparam int ALU_FUNC_LSB = 4;
    localparam int ALU_FUNC_MSB = 7;
    localparam int REG_MEM_FUNC_LSB = 4;
    localparam int REG_MEM_FUNC_MSB = 7;
    localparam int ADDRESS_IMMEDIATE_LSB = 4;
    localparam int ADDRESS_IMMEDIATE_MSB = 15;
    localparam int DATA_IMMEDIATE_LSB = 8;
    localparam int DATA_IMMEDIATE_MSB = 15;
    localparam int REG_ADDR_LSB = 8;
    localparam int REG_ADDR_MSB = 11;

    typedef enum logic [2:0] {
        OPCODE_ARITH_LOGIC_IMM = 3'b000,
        OPCODE_ARITH_LOGIC = 3'b001,
        OPCODE_REG_MEMORY = 3'b010,
        OPCODE_JUMP_IMM = 3'b100,
        OPCODE_JUMP_REG = 3'b111
    } opcode_e;

    typedef enum logic [3:0] {
        LOAD = 4'b0000,
        STORE = 4'b0001,
        GET = 4'b0010,
        PUT = 4'b0011,
        SET = 4'b0100
    } reg_mem_func_e;
endpackage

`endif // DECODER_PKG_SV
