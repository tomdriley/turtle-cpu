`ifndef TURTLE_CPU_TOP
`define TURTLE_CPU_TOP

// turtle_cpu_top.sv
// author: Tom Riley
// date: 2025-07-01

// This module is the top-level module for the Turtle CPU.
module turtle_cpu_top#(
    parameter int CLK_PERIOD_NS = 1000,
    parameter int DATA_WIDTH = 8
) (
    input logic reset_btn,
    input logic manual_clk_sw,
    input logic pulse_clk_btn
);
    logic [DATA_WIDTH-1:0] acc_bus = '0;
    logic [DATA_WIDTH-1:0] op_b_bus = '0;
    logic [2:0] alu_func = '0;
    /* verilator lint_off UNUSEDSIGNAL */
    wire clk;
    wire reset_n;
    wire [DATA_WIDTH-1:0] acc_next_bus;
    wire signed_overflow;
    wire carry_flag;
    /* verilator lint_on UNUSEDSIGNAL */
    
    // Module instantiations
    clk_rst_gen #(
        .CLK_PERIOD_NS(CLK_PERIOD_NS)
    ) clk_rst_gen_inst (
        .reset_btn(reset_btn),
        .manual_clk_sw(manual_clk_sw),
        .pulse_clk_btn(pulse_clk_btn),
        .clk(clk),
        .reset_n(reset_n)
    );

    alu #(
        .DATA_WIDTH(DATA_WIDTH)
    ) alu_inst (
        .op_a(acc_bus),
        .op_b(op_b_bus),
        .func(alu_func),
        .out(acc_next_bus),
        .signed_overflow(signed_overflow),
        .carry_flag(carry_flag)
    );

endmodule: turtle_cpu_top

`endif // TURTLE_CPU_TOP

