`ifndef INSTRUCTION_MEMORY_SV
`define INSTRUCTION_MEMORY_SV

// instruction_memory.sv
// author: Tom Riley
// date: 2025-07-03

module instruction_memory #(
    parameter int I_ADDR_W = 12,
    parameter int INST_W = 16,
    parameter int I_MEMORY_DEPTH = 1 << I_ADDR_W,
    parameter string INIT_FILE = "initial_instruction_memory.mem",
    localparam int BYTE_SIZE = 8,
    localparam int INST_W_BYTES = (INST_W + BYTE_SIZE - 1) / BYTE_SIZE // Calculate number of bytes needed for instruction
) (
    input logic [I_ADDR_W-1:0] addr,
    output logic [INST_W-1:0] instruction,

    // Debug memory connections (for simulation/probing)
    input logic debug_enable,
    input logic [I_ADDR_W-1:0] debug_addr,
    output logic [INST_W-1:0] debug_rdata
    );

    logic [BYTE_SIZE-1:0] mem [I_MEMORY_DEPTH-1:0]; // ROM array
    logic [I_ADDR_W-1:0] effective_addr;

    assign effective_addr = debug_enable ? debug_addr : addr;
    assign debug_rdata = instruction;

    initial begin
        $readmemb(INIT_FILE, mem);
    end

    // Instruction output logic
    always_comb begin
        // Little endian instruction fetch
        for (int i = 0; i < INST_W_BYTES; i++) begin
            instruction[i*BYTE_SIZE +: BYTE_SIZE] = mem[effective_addr + i[I_ADDR_W-1:0]];
        end
    end

endmodule: instruction_memory

`endif // INSTRUCTION_MEMORY_SV
