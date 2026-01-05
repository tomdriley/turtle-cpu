`ifndef TURTLE_CPU_CORE_SV
`define TURTLE_CPU_CORE_SV

// turtle_cpu_core.sv
// author: Tom Riley
// date: 2026-01-03

// This module is the core of the Turtle CPU.
module turtle_cpu_core#(
    // Architecture parameters
    parameter int DATA_W = 8,
    parameter int D_ADDR_W = 12,
    parameter int INST_W = 16,
    parameter int I_ADDR_W = 12,
    parameter int NUM_GPR = 8,
    // Other parameters
    parameter int REG_ADDR_WIDTH = 4,
    localparam int BYTE_SIZE = 8,
    localparam int INST_W_BYTES = (INST_W + BYTE_SIZE - 1) / BYTE_SIZE // Calculate number of bytes needed for instruction
) (
    input logic clk,
    input logic reset_n,

    // Instruction Memory interface
    output logic [I_ADDR_W-1:0] instruction_addr,
    input logic [INST_W-1:0] instruction,

    // Data Memory interface
    output logic [D_ADDR_W-1:0] data_addr,
    output logic [DATA_W-1:0] write_data,
    output logic data_memory_write_enable,
    input logic [DATA_W-1:0] read_data,

    // Register File debug memory connections (for simulation/probing)
    input logic debug_enable,
    input logic [3:0] reg_debug_addr,
    output logic [DATA_W-1:0] reg_debug_rdata
);

    /* verilator lint_off IMPORTSTAR */
    import program_counter_pkg::*;
    import alu_pkg::*;
    import decoder_pkg::*;
    import register_file_pkg::*;
    /* verilator lint_on IMPORTSTAR */

    // FPGA-friendly shared-bus modeling:
    // Instead of internal tri-states, expose each candidate source on its own wire
    // and mux the bus explicitly.
    logic [DATA_W-1:0] register_data_bus;
    logic [DATA_W-1:0] acc_in_bus;

    // Register File to Program Counter connections
    wire [I_ADDR_W-1:0] imar; // Instruction Memory Address Register

    // Decoder to Program Counter connections
    wire [I_ADDR_W-1:0] address_immediate; // Immediate address for
    wire jump_branch_select; // Enable signal for jump/branch instructions
    wire immediate_select; // Select immediate address for branch
    wire unconditional_branch; // Flag for unconditional branches
    wire pc_relative; // Flag for PC-relative addressing
    branch_condition_e branch_condition; // Branch condition to evaluate

    // Program Counter to Instruction Memory connections
    wire [I_ADDR_W-1:0] pc; // Program Counter

    // Decoder to Register File connections
    wire acc_write_enable; // Enable signal for writing to accumulator
    wire write_put_acc; // Control signal that ACC should be written from immediate (put)
    wire read_get_acc; // Control signal that ACC should be written from register (get)
    wire [REG_ADDR_WIDTH-1:0] reg_addr; // Register address for read
    wire read_data_output_enable; // Enable signal for output from register file to bus
    wire status_write_enable; // Enable signal for writing to status register from ALU

    // Data-memory read select (core-internal; no longer needs to be exported)
    wire data_memory_output_enable;

    // Decoder immediate sources (formerly tri-stated onto buses)
    wire [DATA_W-1:0] decoder_acc_immediate;
    wire decoder_acc_immediate_output_enable;
    wire [DATA_W-1:0] decoder_alu_operand_b_immediate;
    wire decoder_alu_operand_b_immediate_output_enable;

    // Decoder to ALU connections
    wire alu_output_enable; // Enable signal for ALU output
    alu_func_e alu_function; // ALU function to perform

    // Register File to Data Memory connections
    wire [D_ADDR_W-1:0] dmar; // Data Memory Address Register

    // Register File to Data Memory / ALU shared connections
    wire [DATA_W-1:0] acc_out; // Output from accumulator

    // Register file read data (separate wire, muxed into register_data_bus)
    wire [DATA_W-1:0] regfile_read_data;

    // ALU result (separate wire, muxed into acc_in_bus)
    wire [DATA_W-1:0] alu_result;

    // ALU to Register File connections
    wire zero_flag; // Zero flag output from ALU
    wire positive_flag; // Positive flag output from ALU
    wire carry_flag; // Carry flag output from ALU
    wire overflow_flag; // Overflow flag output from ALU

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
        .pc_relative(pc_relative),
        .pc(pc),
        .debug_enable(debug_enable)
    );

    decoder #(
        .INST_W(INST_W),
        .DATA_W(DATA_W),
        .I_ADDR_W(I_ADDR_W),
        .REG_ADDR_WIDTH(REG_ADDR_WIDTH)
    ) decoder_inst (
        .instruction(instruction),
        .address_immediate(address_immediate),
        .acc_immediate(decoder_acc_immediate),
        .acc_immediate_output_enable(decoder_acc_immediate_output_enable),
        .alu_operand_b_immediate(decoder_alu_operand_b_immediate),
        .alu_operand_b_immediate_output_enable(decoder_alu_operand_b_immediate_output_enable),
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
        .alu_function(alu_function),
        .pc_relative(pc_relative)
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
        .read_data(regfile_read_data),
        .status_write_enable(status_write_enable),
        .zero_flag(zero_flag),
        .positive_flag(positive_flag),
        .carry_flag(carry_flag),
        .overflow_flag(overflow_flag),
        .dmar(dmar),
        .imar(imar),
        .debug_enable(debug_enable),
        .debug_addr(reg_debug_addr),
        .debug_rdata(reg_debug_rdata)
    );

    alu #(
        .DATA_W(DATA_W)
    ) alu_inst (
        .operand_a(acc_out),
        .operand_b(register_data_bus),
        .alu_func(alu_function),
        .alu_result(alu_result),
        .zero_flag(zero_flag),
        .positive_flag(positive_flag),
        .carry_flag(carry_flag),
        .signed_overflow(overflow_flag)
    );

    // Mux the register_data_bus sources (regfile vs immediate operand-B)
    always_comb begin
        unique case (1'b1)
            decoder_alu_operand_b_immediate_output_enable: register_data_bus = decoder_alu_operand_b_immediate;
            read_data_output_enable: register_data_bus = regfile_read_data;
            default: register_data_bus = '0;
        endcase
    end

    // Mux the accumulator input bus sources (immediate vs memory vs ALU)
    logic mem_read_en;
    assign mem_read_en = data_memory_output_enable && !data_memory_write_enable;

    always_comb begin
        unique case (1'b1)
            decoder_acc_immediate_output_enable: acc_in_bus = decoder_acc_immediate;
            mem_read_en: acc_in_bus = read_data;
            alu_output_enable: acc_in_bus = alu_result;
            default: acc_in_bus = '0;
        endcase
    end

`ifndef SYNTHESIS
    // Catch accidental multi-enables that would have been bus contention in TTL.
    always_comb begin
        assert ($onehot0({decoder_alu_operand_b_immediate_output_enable, read_data_output_enable}))
            else $error("register_data_bus contention: multiple sources enabled");
        assert ($onehot0({decoder_acc_immediate_output_enable, mem_read_en, alu_output_enable}))
            else $error("acc_in_bus contention: multiple sources enabled");
    end
`endif

    // Instruction Memory interface connections
    assign instruction_addr = pc;

    // Data Memory interface connections
    assign data_addr = dmar;
    assign write_data = acc_out;


endmodule: turtle_cpu_core

`endif // TURTLE_CPU_CORE_SV
