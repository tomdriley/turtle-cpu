`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/03/2026 04:29:23 PM
// Design Name: 
// Module Name: io_controller
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module io_controller#(
    // Architecture parameters
    parameter int DATA_W = 8,
    parameter int D_ADDR_W = 12,
    parameter int INST_W = 16,
    parameter int I_ADDR_W = 12,
    // Other parameters
    parameter int I_MEMORY_DEPTH = 1 << I_ADDR_W,
    parameter int D_MEMORY_DEPTH = 1 << D_ADDR_W,
    localparam int BYTE_SIZE = 8
)(
    input clk,
    input reset_n,
    input [15:0] sw,
    output [15:0] led,
    output [6:0] seg,
    output [3:0] an,
    // Debug connections
    output logic debug_enable,
    output logic [3:0] reg_debug_addr,
    input logic [DATA_W-1:0] reg_debug_rdata,
    output logic [D_ADDR_W-1:0] dmem_debug_addr,
    input logic [DATA_W-1:0] dmem_debug_rdata,
    output logic [I_ADDR_W-1:0] imem_debug_addr,
    input logic [INST_W-1:0] imem_debug_rdata
);
    
    logic [3:0] dig[3:0]; // 4 hex digits to display

    // Map switches to LEDs directly
    assign led = sw;

    // Lower 12 bits select an address to view (for data or instruction memory)
    logic [11:0] addr, addr_sync1, addr_sync2;

    assign addr = sw[11:0];

    // Synchronize address to clk domain
    always_ff @(posedge clk) begin
        if (!reset_n) begin
            addr_sync1 <= 12'b0;
            addr_sync2 <= 12'b0;
        end else begin
            addr_sync1 <= addr;
            addr_sync2 <= addr_sync1;
        end
    end

    assign dmem_debug_addr = addr_sync2[D_ADDR_W-1:0];
    assign imem_debug_addr = addr_sync2[I_ADDR_W-1:0];
    assign reg_debug_addr = addr_sync2[3:0];

    // 2 bits select which memory to view
    // 10: Instruction Memory
    // 11: Data Memory
    // 0x: Register Memory
    logic [1:0] mem_sel;
    assign mem_sel = sw[14:13];
    logic [15:0] data_out;
    always_comb begin
        unique case (mem_sel)
            2'b10: data_out = {4'b0, imem_debug_rdata}; // Instruction Memory
            2'b11: data_out = {4'b0, dmem_debug_rdata}; // Data Memory
            default: data_out = {4'b0, reg_debug_rdata}; // Register Memory
        endcase
    end
    // Convert data_out to hex for 7-seg display
    for (genvar i = 0; i < 4; i++) begin
        assign dig[i] = data_out[i*4 +: 4];
    end

    // Enable debug when switch 15 is high
    logic debug_enable_in, debug_enable_sync1, debug_enable_sync2;

    assign debug_enable_in = sw[15];
    assign debug_enable = debug_enable_sync2;

    // Synchronize debug_enable to clk domain
    always_ff @(posedge clk) begin
        if (!reset_n) begin
            debug_enable_sync1 <= 1'b0;
            debug_enable_sync2 <= 1'b0;
        end else begin
            debug_enable_sync1 <= debug_enable_in;
            debug_enable_sync2 <= debug_enable_sync1;
        end
    end
    
    seven_segment_driver seven_segment_driver_inst(.*);
endmodule
