`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 01/03/2026 04:29:23 PM
// Design Name:
// Module Name: clk_rst_gen
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


module clk_rst_pll_sync (
    input  clk_in,
    output clk,
    output reset_n
);

  // 1) Synchronize PLL lock
  logic pll_locked;
  logic [1:0] lock_sync;
  always @(posedge clk or negedge pll_locked) begin
    if (!pll_locked) lock_sync <= 2'b00;
    else lock_sync <= {lock_sync[0], 1'b1};
  end

  // 2) Delay counter
  localparam int DELAY_CYCLES = 100;
  localparam int CNT_W = $clog2(DELAY_CYCLES);
  logic [CNT_W-1:0] cnt;
  logic ready;

  always @(posedge clk) begin
    if (!lock_sync[1]) begin
      cnt   <= 0;
      ready <= 1'b0;
    end else if (!ready) begin
      if (cnt == DELAY_CYCLES - 1) ready <= 1'b1;
      else cnt <= cnt + 1'b1;
    end
  end

  assign reset_n = lock_sync[1] & ready;

  clk_wiz_0 instance_name (
      // Clock out ports
      .clk_out1(clk),         // output clk_out1
      // Status and control signals
      .reset   (0),           // input reset
      .locked  (pll_locked),  // output locked
      // Clock in ports
      .clk_in1 (clk_in)       // input clk_in1
  );

endmodule
