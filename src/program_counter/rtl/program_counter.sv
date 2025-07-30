`ifndef PROGRAM_COUNTER_SV
`define PROGRAM_COUNTER_SV

// program_counter.sv
// author: Tom Riley
// date: 2025-07-05

/* verilator lint_off IMPORTSTAR */
import register_file_pkg::*;
import program_counter_pkg::*;
import decoder_pkg::*;
/* verilator lint_on IMPORTSTAR */

module program_counter #(
    parameter int I_ADDR_W = 12,
    parameter int INST_W_BYTES = 2,
    parameter int DATA_W = 8
) (
    input logic clk,
    input logic rst_n,
    input logic [I_ADDR_W-1:0] imar, // Instruction Memory Address Register
    input logic [I_ADDR_W-1:0] address_immediate, // Immediate address for branch instructions
    input logic jump_branch_select, // Enable signal for jump/branch instructions
    input logic immediate_select, // Select immediate address for branch
    input logic unconditional_branch, // Flag for unconditional branches
    input logic [DATA_W-1:0] status_register, // Status register containing flags
    input branch_condition_e branch_condition, // Branch condition to evaluate
    input logic pc_relative, // Flag for PC-relative addressing
    output logic [I_ADDR_W-1:0] pc // Program Counter output
);
    logic [I_ADDR_W-1:0] next_pc; // Next program counter value
    logic [I_ADDR_W-1:0] branch_addr; // Address to branch to if condition is met
    logic [I_ADDR_W-1:0] target_offset; // Target address or offset
    logic branch_taken; // Flag indicating if a branch is taken
    logic [DATA_W-1:4] status_register_unused; // Unused bits in status register

    // Select the target offset/address (immediate or register)
    assign target_offset = (immediate_select) ? address_immediate : imar;
    
    // Calculate final branch address: PC-relative adds offset to PC, absolute uses target directly
    assign branch_addr = pc_relative ? (pc + target_offset) : target_offset;
    
    assign next_pc = branch_taken ? branch_addr : (pc + INST_W_BYTES[I_ADDR_W-1:0]); // Increment PC by instruction width if not branching
    assign status_register_unused = status_register[DATA_W-1:4]; // Unused bits in status register
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc <= '0; // Reset program counter to zero
        end else begin
            pc <= next_pc; // Update program counter to next value
        end
    end

    always_comb begin
        if (jump_branch_select && !unconditional_branch) begin
            unique case (branch_condition)
                COND_ZERO: branch_taken = status_register[ZERO_FLAG];
                COND_NOT_ZERO: branch_taken = !status_register[ZERO_FLAG];
                COND_NEGATIVE: branch_taken = status_register[NEGATIVE_FLAG];
                COND_POSITIVE: branch_taken = !status_register[NEGATIVE_FLAG];
                COND_CARRY_SET: branch_taken = status_register[CARRY_FLAG];
                COND_CARRY_CLEARED: branch_taken = !status_register[CARRY_FLAG];
                COND_OVERFLOW_SET: branch_taken = status_register[OVERFLOW_FLAG];
                COND_OVERFLOW_CLEARED: branch_taken = !status_register[OVERFLOW_FLAG];
            endcase
        end else begin
            branch_taken = jump_branch_select;
        end
    end

endmodule: program_counter

`endif // PROGRAM_COUNTER_SV
