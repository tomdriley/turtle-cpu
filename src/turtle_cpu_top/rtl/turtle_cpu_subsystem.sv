`ifndef TURTLE_CPU_SUBSYSTEM_SV
`define TURTLE_CPU_SUBSYSTEM_SV

module turtle_cpu_subsystem#(
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
    input logic clk,
    input logic reset_n,

    // Register and Memory debug memory connections (for simulation/probing)
    input logic debug_enable,
    input logic [3:0] reg_debug_addr,
    output logic [DATA_W-1:0] reg_debug_rdata,
    input logic [D_ADDR_W-1:0] dmem_debug_addr,
    output logic [DATA_W-1:0] dmem_debug_rdata,
    input logic [I_ADDR_W-1:0] imem_debug_addr,
    output logic [INST_W-1:0] imem_debug_rdata
);

    logic [I_ADDR_W-1:0] instruction_addr;
    logic [INST_W-1:0] instruction;

    logic [D_ADDR_W-1:0] data_addr;
    logic [DATA_W-1:0] write_data;
    logic data_memory_write_enable;
    logic [DATA_W-1:0] read_data;

    (* keep_hierarchy = "yes" *)
    instruction_memory #(
        .I_ADDR_W(I_ADDR_W),
        .INST_W(INST_W),
        .I_MEMORY_DEPTH(I_MEMORY_DEPTH)
    ) instruction_memory_inst (
        .addr(instruction_addr),
        .instruction(instruction),
        .debug_enable(debug_enable),
        .debug_addr(imem_debug_addr),
        .debug_rdata(imem_debug_rdata)
    );

    (* keep_hierarchy = "yes" *)
    data_memory #(
        .D_ADDR_W(D_ADDR_W),
        .DATA_W(DATA_W),
        .D_MEMORY_DEPTH(D_MEMORY_DEPTH)
    ) data_memory_inst (
        .clk(clk),
        .data_addr(data_addr),
        .write_data(write_data),
        .write_enable(data_memory_write_enable),
        .read_data(read_data),
        .debug_enable(debug_enable),
        .debug_addr(dmem_debug_addr),
        .debug_rdata(dmem_debug_rdata)
    );

    (* keep_hierarchy = "yes" *)
    turtle_cpu_core #(
        .DATA_W(DATA_W),
        .D_ADDR_W(D_ADDR_W),
        .INST_W(INST_W),
        .I_ADDR_W(I_ADDR_W),
        .NUM_GPR(NUM_GPR),
        .REG_ADDR_WIDTH(REG_ADDR_WIDTH)
    ) turtle_cpu_core_inst (
        .clk(clk),
        .reset_n(reset_n),
        .instruction_addr(instruction_addr),
        .instruction(instruction),
        .data_addr(data_addr),
        .write_data(write_data),
        .data_memory_write_enable(data_memory_write_enable),
        .read_data(read_data),
        .debug_enable(debug_enable),
        .reg_debug_addr(reg_debug_addr),
        .reg_debug_rdata(reg_debug_rdata)
    );

endmodule : turtle_cpu_subsystem


`endif // TURTLE_CPU_SUBSYSTEM_SV
