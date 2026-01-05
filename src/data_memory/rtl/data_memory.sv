`ifndef DATA_MEMORY_SV
`define DATA_MEMORY_SV

// data_memory.sv
// author: Tom Riley
// date: 2025-07-03

module data_memory #(
    parameter int D_ADDR_W = 12,
    parameter int DATA_W = 8,
    parameter int D_MEMORY_DEPTH = 1 << D_ADDR_W
) (
    input logic clk,
    input logic [D_ADDR_W-1:0] data_addr,
    input logic [DATA_W-1:0] write_data,
    input logic write_enable,
    output logic [DATA_W-1:0] read_data,

    // Debug memory connections (for simulation/probing)
    input logic debug_enable,
    input logic [D_ADDR_W-1:0] debug_addr,
    output logic [DATA_W-1:0] debug_rdata
    );

    logic [DATA_W-1:0] mem [D_MEMORY_DEPTH-1:0]; // Distributed RAM
    logic [D_ADDR_W-1:0] effective_addr;

    assign effective_addr = debug_enable ? debug_addr : data_addr;
    assign debug_rdata = mem[effective_addr];

    // Always drive the read value; the top-level decides when to consume it.
    assign read_data = mem[effective_addr];

    // Write operation
    always_ff @(posedge clk) begin
        if (write_enable && !debug_enable) begin
            mem[data_addr] <= write_data;
        end
    end

endmodule: data_memory

`endif // DATA_MEMORY_SV
