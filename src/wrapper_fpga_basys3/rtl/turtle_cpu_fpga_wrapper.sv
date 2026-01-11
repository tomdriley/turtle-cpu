`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 01/03/2026 02:06:27 PM
// Design Name:
// Module Name: turtle_cpu_fpga_wrapper
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


module turtle_cpu_fpga_wrapper #(
    // Architecture parameters
    parameter int DATA_W = 8,
    parameter int D_ADDR_W = 12,
    parameter int INST_W = 16,
    parameter int I_ADDR_W = 12,
    parameter int NUM_GPR = 8,
    // Other parameters
    parameter int REG_ADDR_WIDTH = 4,
    parameter int I_MEMORY_DEPTH = 1 << I_ADDR_W,
    parameter int D_MEMORY_DEPTH = 1 << D_ADDR_W,
    localparam int BYTE_SIZE = 8
) (
    input logic clk_in,
    input logic [15:0] sw,
    output logic [15:0] led,
    output logic [6:0] seg,
    output logic [3:0] an,
    output logic RsTx,
    input logic RsRx
);

  logic clk;
  logic reset_n;

  logic [D_ADDR_W-1:0] data_addr;
  logic write_enable;
  logic [DATA_W-1:0] write_data;
  logic [DATA_W-1:0] read_data;
  logic int_mem_select;

  logic debug_enable;
  logic [3:0] reg_debug_addr;
  logic [DATA_W-1:0] reg_debug_rdata;
  logic [D_ADDR_W-1:0] dmem_debug_addr;
  logic [DATA_W-1:0] dmem_debug_rdata;
  logic [I_ADDR_W-1:0] imem_debug_addr;
  logic [INST_W-1:0] imem_debug_rdata;

  logic [I_ADDR_W-1:0] pc;

  clk_rst_pll_sync clk_rst_pll_sync_inst (.*);

  io_controller io_controller_inst (.*);

  turtle_cpu_subsystem turtle_cpu_subsystem_inst (.*);

endmodule
