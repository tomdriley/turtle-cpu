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


module io_controller #(
    // Architecture parameters
    parameter int DATA_W = 8,
    parameter int D_ADDR_W = 12,
    parameter int INST_W = 16,
    parameter int I_ADDR_W = 12,
    // Other parameters
    parameter int I_MEMORY_DEPTH = 1 << I_ADDR_W,
    parameter int D_MEMORY_DEPTH = 1 << D_ADDR_W,
    localparam int BYTE_SIZE = 8
) (
    input clk,
    input reset_n,
    // FPGA I/O
    input [15:0] sw,
    output [15:0] led,
    output [6:0] seg,
    output [3:0] an,
    output RsTx,
    input RsRx,
    // Memory interface
    input logic [D_ADDR_W-1:0] data_addr,
    input logic write_enable,
    input logic [DATA_W-1:0] write_data,
    output logic [DATA_W-1:0] read_data,
    output logic int_mem_select,
    // Debug connections
    output logic debug_enable,
    output logic [3:0] reg_debug_addr,
    input logic [DATA_W-1:0] reg_debug_rdata,
    output logic [D_ADDR_W-1:0] dmem_debug_addr,
    input logic [DATA_W-1:0] dmem_debug_rdata,
    output logic [I_ADDR_W-1:0] imem_debug_addr,
    input logic [INST_W-1:0] imem_debug_rdata,
    input logic [I_ADDR_W-1:0] pc
);

  // ------------------------------------------------------------------------
  // Local signals
  // ------------------------------------------------------------------------
  logic [3:0] dig[4];  // 4 hex digits to display
  logic [15:0] data_out;

  logic [11:0] addr, addr_sync1, addr_sync2;
  logic [1:0] mem_sel;

  logic debug_enable_in, debug_enable_sync1, debug_enable_sync2;

  // ------------------------------------------------------------------------
  // Switch/LED passthrough + raw switch decoding
  // ------------------------------------------------------------------------
  assign led[15:1]             = sw[15:1];
  assign led[0] = RsTx;
  assign addr            = sw[11:0];
  assign mem_sel         = sw[14:13];
  assign debug_enable_in = sw[15];

  // ------------------------------------------------------------------------
  // CDC / input synchronization (switches -> clk domain)
  // ------------------------------------------------------------------------
  // Synchronize address selection to clk domain
  always_ff @(posedge clk) begin
    if (!reset_n) begin
      addr_sync1 <= 12'b0;
      addr_sync2 <= 12'b0;
    end else begin
      addr_sync1 <= addr;
      addr_sync2 <= addr_sync1;
    end
  end

  // Synchronize debug enable to clk domain
  always_ff @(posedge clk) begin
    if (!reset_n) begin
      debug_enable_sync1 <= 1'b0;
      debug_enable_sync2 <= 1'b0;
    end else begin
      debug_enable_sync1 <= debug_enable_in;
      debug_enable_sync2 <= debug_enable_sync1;
    end
  end
  assign debug_enable = debug_enable_sync2;

  // ------------------------------------------------------------------------
  // Debug address outputs (derived from synchronized address)
  // ------------------------------------------------------------------------
  assign dmem_debug_addr = addr_sync2[D_ADDR_W-1:0];
  assign imem_debug_addr = addr_sync2[I_ADDR_W-1:0];
  assign reg_debug_addr = addr_sync2[3:0];

  // ------------------------------------------------------------------------
  // Display data selection
  //   - debug_enable=1: show selected debug source
  //   - debug_enable=0: show PC
  // ------------------------------------------------------------------------
  // mem_sel encoding:
  //   2'b10: Instruction Memory
  //   2'b11: Data Memory
  //   2'b0x: Register File
  always_comb begin
    if (debug_enable) begin
      unique case (mem_sel)
        2'b10:   data_out = imem_debug_rdata;
        2'b11:   data_out = {8'b0, dmem_debug_rdata};
        default: data_out = {8'b0, reg_debug_rdata};
      endcase
    end else begin
      data_out = {4'b0, pc};
    end
  end

  // ------------------------------------------------------------------------
  // Convert data_out into 4 nibbles for 7-seg driver
  // ------------------------------------------------------------------------
  for (genvar i = 0; i < 4; i++) begin : gen_assign_dig
    assign dig[i] = data_out[i*4+:4];
  end

  // ------------------------------------------------------------------------
  // Outputs / submodules
  // ------------------------------------------------------------------------
  seven_segment_driver seven_segment_driver_inst (.*);
  uart_controller uart_controller_inst (.*);
endmodule
