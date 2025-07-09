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
    input logic [D_ADDR_W-1:0] data_addr,
    input logic [DATA_W-1:0] write_data,
    input logic write_enable,
    input logic output_enable,
    output logic [DATA_W-1:0] read_data
);
    logic [DATA_W-1:0] mem [D_MEMORY_DEPTH-1:0];

    // Read operation
    always_comb begin
        if (output_enable && !write_enable) begin
            read_data = mem[data_addr];
        end
        else begin
            read_data = 'z; // High impedance when not reading
        end
    end

    // Write operation
    always_latch begin
        if (write_enable) begin
            mem[data_addr] = write_data;
        end
    end
endmodule: data_memory

`endif // DATA_MEMORY_SV
