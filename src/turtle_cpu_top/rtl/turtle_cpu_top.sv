`ifndef TURTLE_CPU_TOP
`define TURTLE_CPU_TOP

// turtle_cpu_top.sv
// author: Tom Riley
// date: 2025-07-01

/* verilator lint_off IMPORTSTAR */
import program_counter_pkg::*;
import alu_pkg::*;
import decoder_pkg::*;
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
    parameter int D_MEMORY_DEPTH = 1 << D_ADDR_W
) (
    input logic reset_btn,
    input logic manual_clk_sw,
    input logic pulse_clk_btn
);
    wire clk;
    wire reset_n;

    clk_rst_gen #(
        .CLK_PERIOD_NS(CLK_PERIOD_NS)
    ) clk_rst_gen_inst (
        .reset_btn(reset_btn),
        .manual_clk_sw(manual_clk_sw),
        .pulse_clk_btn(pulse_clk_btn),
        .clk(clk),
        .reset_n(reset_n)
    );

    turtle_cpu_subsystem #(
        .DATA_W(DATA_W),
        .D_ADDR_W(D_ADDR_W),
        .INST_W(INST_W),
        .I_ADDR_W(I_ADDR_W),
        .NUM_GPR(NUM_GPR),
        .REG_ADDR_WIDTH(REG_ADDR_WIDTH),
        .I_MEMORY_DEPTH(I_MEMORY_DEPTH),
        .D_MEMORY_DEPTH(D_MEMORY_DEPTH)
    ) turtle_cpu_subsystem_inst (
        .clk(clk),
        .reset_n(reset_n),
        // Debug connections tied off for top-level
        .debug_enable(1'b0),
        .reg_debug_addr(4'b0),
        .dmem_debug_addr({D_ADDR_W{1'b0}}),
        .imem_debug_addr({I_ADDR_W{1'b0}}),
        /* verilator lint_off PINCONNECTEMPTY */
        .reg_debug_rdata(),
        .dmem_debug_rdata(),
        .imem_debug_rdata()
        /* verilator lint_on PINCONNECTEMPTY */
    );

endmodule: turtle_cpu_top

`endif // TURTLE_CPU_TOP

