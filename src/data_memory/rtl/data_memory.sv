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
    output tri   [DATA_W-1:0] read_data
);
    logic [DATA_W-1:0] mem [D_MEMORY_DEPTH-1:0];
    logic [DATA_W-1:0] read_data_val;
    logic read_data_en;

    assign read_data_en = output_enable && !write_enable;

    // Read datapath (value is always computed; tri-state driver controls visibility on bus)
    always_comb begin
        read_data_val = mem[data_addr];
    end

    tristate_driver #(.DATA_W(DATA_W)) read_data_driver (
        .en(read_data_en),
        .d(read_data_val),
        .bus(read_data)
    );

    // Write operation
    always_latch begin
        if (write_enable) begin
            mem[data_addr] = write_data;
        end
    end
endmodule: data_memory

`endif // DATA_MEMORY_SV
