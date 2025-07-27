`ifndef TURTLE_CPU_TOP
`define TURTLE_CPU_TOP

// turtle_cpu_top.sv
// author: Tom Riley
// date: 2025-07-01

/* verilator lint_off IMPORTSTAR */
import program_counter_pkg::*;
import alu_pkg::*;
import decoder_pkg::*;
import program_counter_pkg::*;
import register_file_pkg::*;
/* verilator lint_on IMPORTSTAR */

// This module is the top-level module for the Turtle CPU.
module turtle_cpu_top#(
    parameter int CLK_PERIOD_NS = 1000,
    // Architecture parameters
    parameter int DATA_W = 8,
    parameter int D_ADDR_W = 12,
    parameter int INST_W = 16,
    parameter int I_ADDR_W = 12,
    parameter int NUM_GPR = 8,
    // Other parameters
    parameter int REG_ADDR_WIDTH = 4,
    parameter int I_MEMORY_DEPTH = 1 << I_ADDR_W,
    parameter int D_MEMORY_DEPTH = 1 << D_ADDR_W,
    localparam int BYTE_SIZE = 8,
    localparam int INST_W_BYTES = (INST_W + BYTE_SIZE - 1) / BYTE_SIZE // Calculate number of bytes needed for instruction
) (
    input logic reset_btn,
    input logic manual_clk_sw,
    input logic pulse_clk_btn
);
    wire clk;
    wire reset_n;

    // Shared Bus connections
    wire [DATA_W-1:0] register_data_bus; // Data bus for register file
    wire [DATA_W-1:0] acc_in_bus; // Input bus for accumulator

    // Register File to Program Counter connections
    wire [I_ADDR_W-1:0] imar; // Instruction Memory Address Register

    // Decoder to Program Counter connections
    wire [I_ADDR_W-1:0] address_immediate; // Immediate address for
    wire jump_branch_select; // Enable signal for jump/branch instructions
    wire immediate_select; // Select immediate address for branch
    wire unconditional_branch; // Flag for unconditional branches
    branch_condition_e branch_condition; // Branch condition to evaluate

    // Program Counter to Instruction Memory connections
    wire [I_ADDR_W-1:0] pc; // Program Counter

    // Instruction Memory to Decoder connections
    wire [INST_W-1:0] instruction; // Instruction fetched from memory

    // Decoder to Register File connections
    wire acc_write_enable; // Enable signal for writing to accumulator
    wire write_put_acc; // Control signal that ACC should be written from immediate (put)
    wire read_get_acc; // Control signal that ACC should be written from register (get)
    wire [REG_ADDR_WIDTH-1:0] reg_addr; // Register address for read
    wire read_data_output_enable; // Enable signal for output from register file to bus
    wire status_write_enable; // Enable signal for writing to status register from ALU

    // Decoder to Data Memory connections
    wire data_memory_write_enable; // Enable signal for writing to data memory
    wire data_memory_output_enable; // Enable signal for reading from data memory

    // Decoder to ALU connections
    wire alu_output_enable; // Enable signal for ALU output
    alu_func_e alu_function; // ALU function to perform

    // Register File to Data Memory connections
    wire [D_ADDR_W-1:0] dmar; // Data Memory Address Register

    // Register File to Data Memory / ALU shared connections
    wire [DATA_W-1:0] acc_out; // Output from accumulator

    // ALU to Register File connections
    wire zero_flag; // Zero flag output from ALU
    wire positive_flag; // Positive flag output from ALU
    wire carry_flag; // Carry flag output from ALU
    wire overflow_flag; // Overflow flag output from ALU

    clk_rst_gen #(
        .CLK_PERIOD_NS(CLK_PERIOD_NS)
    ) clk_rst_gen_inst (
        .reset_btn(reset_btn),
        .manual_clk_sw(manual_clk_sw),
        .pulse_clk_btn(pulse_clk_btn),
        .clk(clk),
        .reset_n(reset_n)
    );

    program_counter #(
        .I_ADDR_W(I_ADDR_W),
        .INST_W_BYTES(INST_W_BYTES),
        .DATA_W(DATA_W)
    ) program_counter_inst (
        .clk(clk),
        .rst_n(reset_n),
        .imar(imar),
        .address_immediate(address_immediate),
        .jump_branch_select(jump_branch_select),
        .immediate_select(immediate_select),
        .unconditional_branch(unconditional_branch),
        .status_register(register_data_bus),
        .branch_condition(branch_condition),
        .pc(pc)
    );
        
    instruction_memory #(
        .I_ADDR_W(I_ADDR_W),
        .INST_W(INST_W),
        .I_MEMORY_DEPTH(I_MEMORY_DEPTH)
    ) instruction_memory_inst (
        .addr(pc),
        .instruction(instruction)
    );

    decoder #(
        .INST_W(INST_W),
        .DATA_W(DATA_W),
        .I_ADDR_W(I_ADDR_W),
        .REG_ADDR_WIDTH(REG_ADDR_WIDTH)
    ) decoder_inst (
        .instruction(instruction),
        .address_immediate(address_immediate),
        .acc_immediate(acc_in_bus),
        .alu_operand_b_immediate(register_data_bus),
        .acc_write_enable(acc_write_enable),
        .write_put_acc(write_put_acc),
        .read_get_acc(read_get_acc),
        .reg_addr(reg_addr),
        .read_data_output_enable(read_data_output_enable),
        .status_write_enable(status_write_enable),
        .data_memory_write_enable(data_memory_write_enable),
        .data_memory_output_enable(data_memory_output_enable),
        .jump_branch_select(jump_branch_select),
        .immediate_address_select(immediate_select),
        .unconditional_branch(unconditional_branch),
        .branch_condition(branch_condition),
        .alu_output_enable(alu_output_enable),
        .alu_function(alu_function)
    );

    register_file #(
        .DATA_W(DATA_W),
        .I_ADDR_WIDTH(I_ADDR_W),
        .D_ADDR_WIDTH(I_ADDR_W),
        .NUM_GPR(NUM_GPR),
        .REG_ADDR_WIDTH(REG_ADDR_WIDTH)
    ) register_file_inst (
        .clk(clk),
        .reset_n(reset_n),
        .acc_out(acc_out),
        .acc_in(acc_in_bus),
        .acc_write_enable(acc_write_enable),
        .read_get_to_acc(read_get_acc),
        .write_put_acc(write_put_acc),
        .reg_addr(reg_addr),
        .read_data_output_enable(read_data_output_enable),
        .read_data(register_data_bus),
        .status_write_enable(status_write_enable),
        .zero_flag(zero_flag),
        .positive_flag(positive_flag),
        .carry_flag(carry_flag),
        .overflow_flag(overflow_flag),
        .dmar(dmar),
        .imar(imar)
    );

    data_memory #(
        .D_ADDR_W(D_ADDR_W),
        .DATA_W(DATA_W),
        .D_MEMORY_DEPTH(D_MEMORY_DEPTH)
    ) data_memory_inst (
        .data_addr(dmar),
        .write_data(acc_out),
        .write_enable(data_memory_write_enable),
        .output_enable(data_memory_output_enable),
        .read_data(acc_in_bus)
    );

    alu #(
        .DATA_W(DATA_W)
    ) alu_inst (
        .operand_a(acc_out),
        .operand_b(register_data_bus),
        .alu_func(alu_function),
        .output_enable(alu_output_enable),
        .alu_result(acc_in_bus),
        .zero_flag(zero_flag),
        .positive_flag(positive_flag),
        .carry_flag(carry_flag),
        .signed_overflow(overflow_flag)
    );

endmodule: turtle_cpu_top

`endif // TURTLE_CPU_TOP

