`ifndef DECODER_SV
`define DECODER_SV

// decoder.sv
// author: Tom Riley
// date: 2025-07-08

/* verilator lint_off IMPORTSTAR */
import alu_pkg::*;
import program_counter_pkg::*;
import decoder_pkg::*;
/* verilator lint_on IMPORTSTAR */

module decoder#(
    parameter int INST_W = 16,
    parameter int DATA_W = 8,
    parameter int I_ADDR_W = 12,
    parameter int REG_ADDR_WIDTH = 4
) (
    // Inputs
    input wire [INST_W-1:0] instruction,
    // Data/address outputs
    output logic [I_ADDR_W-1:0] address_immediate,
    output logic [DATA_W-1:0] acc_immediate,
    output logic [DATA_W-1:0] alu_operand_b_immediate,
    // Outputs to register file
    output wire acc_write_enable,
    output wire write_put_acc,
    output wire read_get_acc,
    output wire [REG_ADDR_WIDTH-1:0] reg_addr,
    output wire read_data_output_enable,
    output wire status_write_enable,
    // Outputs to data memory
    output wire data_memory_write_enable,
    output wire data_memory_output_enable,
    // Outputs to program counter
    output wire jump_branch_select,
    output wire immediate_address_select,
    output wire unconditional_branch,
    output wire branch_condition_e branch_condition,
    output wire pc_relative,
    // Outputs to ALU
    output wire alu_output_enable,
    output alu_func_e alu_function
);
    logic branch_instruction;
    opcode_e op;
    reg_mem_func_e reg_mem_func;
    logic [3:0] function_bits;
    logic [DATA_W-1:0] data_immediate;
    logic acc_immediate_output_enable;
    logic operand_b_immediate_output_enable;

    // Instruction field extraction
    assign branch_instruction = instruction[BRANCH_INSTRUCTION_OFFSET];
    assign branch_condition = branch_condition_e'(instruction[BRANCH_CONDITION_MSB:BRANCH_CONDITION_LSB]);
    assign op = opcode_e'(instruction[OP_MSB:OP_LSB]);
    assign function_bits = instruction[FUNCTION_MSB:FUNCTION_LSB];
    assign alu_function = alu_func_e'(function_bits);
    assign reg_mem_func = reg_mem_func_e'(function_bits);
    assign address_immediate = instruction[ADDRESS_IMMEDIATE_MSB:ADDRESS_IMMEDIATE_LSB];
    assign data_immediate = instruction[DATA_IMMEDIATE_MSB:DATA_IMMEDIATE_LSB];
    assign reg_addr = instruction[REG_ADDR_MSB:REG_ADDR_LSB];

    // PC-relative control: All branches and JMPI are relative, JMPR is relative, JMP is absolute
    assign pc_relative = branch_instruction || (op == OPCODE_JUMP_IMM) || 
                         (op == OPCODE_JUMP_REG && function_bits[0] == 1'b0); // JMPR=0, JMP=1

    // Opcode decoding logic
    assign acc_immediate_output_enable = (op == OPCODE_REG_MEMORY && reg_mem_func == SET);
    assign operand_b_immediate_output_enable = (op == OPCODE_ARITH_LOGIC_IMM);
    assign acc_write_enable = (
        op == OPCODE_ARITH_LOGIC 
        || op == OPCODE_ARITH_LOGIC_IMM 
        || (
            op == OPCODE_REG_MEMORY 
            && (
                reg_mem_func == SET
                || reg_mem_func == GET
                || reg_mem_func == LOAD
            )
        )
    );
    assign write_put_acc = (op == OPCODE_REG_MEMORY && reg_mem_func == PUT);
    assign read_get_acc = (op == OPCODE_REG_MEMORY && reg_mem_func == GET);
    assign read_data_output_enable = (op == OPCODE_ARITH_LOGIC || branch_instruction);
    assign status_write_enable = (op == OPCODE_ARITH_LOGIC || op == OPCODE_ARITH_LOGIC_IMM);
    assign data_memory_write_enable = (op == OPCODE_REG_MEMORY && reg_mem_func == STORE);
    assign data_memory_output_enable = (op == OPCODE_REG_MEMORY && reg_mem_func == LOAD);
    assign jump_branch_select = (branch_instruction || op == OPCODE_JUMP_REG || op == OPCODE_JUMP_IMM);
    assign immediate_address_select = (branch_instruction || op == OPCODE_JUMP_IMM);
    assign unconditional_branch = (op == OPCODE_JUMP_IMM);
    assign alu_output_enable = (op == OPCODE_ARITH_LOGIC || op == OPCODE_ARITH_LOGIC_IMM);

    // Assign outputs for immediate values
    // These are tristate outputs, so they will be driven only when the corresponding output enable
    assign acc_immediate = acc_immediate_output_enable ? data_immediate : 'z;
    assign alu_operand_b_immediate = operand_b_immediate_output_enable ? data_immediate : 'z;

endmodule: decoder

`endif // DECODER_SV
