`ifndef UART_CONTROLLER_SV
`define UART_CONTROLLER_SV

// uart_controller.sv
// author: Tom Riley
// date: 2026-01-07

// This module implements a simple UART transmitter and receiver.
module uart_controller #(
    parameter int CLOCK_FREQ = 100_000_000,
    // Architecture parameters
    parameter int DATA_W = 8,
    parameter int D_ADDR_W = 12,
    // UART parameters
    parameter int BAUD_RATE = 9600,
    // Minimum number of idle (mark=1) bit-times to insert between frames.
    // This is in units of baud bit periods (not oversample ticks).
    parameter int MINIMUM_IDLE_BITS = 1,
    parameter bit PARITY_EN = 0,
    parameter bit PARITY_EVEN = 1,
    parameter int OVERSAMPLE_RATE = 16,
    parameter int START_SAMPLES = OVERSAMPLE_RATE / 4,
    parameter int DATA_SAMPLES = 3,
    localparam int FRAME_W = 1 + DATA_W + (PARITY_EN ? 1 : 0) + 1,  // Start + Data + Parity + Stop
    localparam int FRAME_CNT_W = $clog2(FRAME_W),
    localparam int BAUD_CNT_W = $clog2(OVERSAMPLE_RATE),
    // Calculate baud clocks by oversample clock first, then multiplying
    // to ensure integer math works out. This will round down, but the error
    // should be negligible.
    localparam int OVERSAMPLE_CLOCKS = CLOCK_FREQ / (BAUD_RATE * OVERSAMPLE_RATE),
    localparam int BAUD_CLOCKS = OVERSAMPLE_CLOCKS * OVERSAMPLE_RATE,
    localparam int OVERSAMPLE_CNT_W = $clog2(OVERSAMPLE_CLOCKS)
) (
    input logic clk,
    input logic reset_n,
    // UART interface
    output logic RsTx,
    input logic RsRx,
    // Memory interface
    input logic [D_ADDR_W-1:0] data_addr,
    input logic write_enable,
    input logic [DATA_W-1:0] write_data,
    output logic [DATA_W-1:0] read_data,
    output logic int_mem_select
);

  // Tie off outputs for now
  assign read_data = '0;
  assign int_mem_select = 1'b1;  // Always select internal memory

  // ------------------------------------------------------------------------
  // Baud rate generator
  // ------------------------------------------------------------------------

  logic [BAUD_CNT_W-1:0] baud_cnt, next_baud_cnt;
  logic [OVERSAMPLE_CNT_W-1:0] oversample_cnt, next_oversample_cnt;
  logic baud_tick, next_baud_tick;
  logic oversample_tick, next_oversample_tick;

  assign next_oversample_tick = (oversample_cnt == OVERSAMPLE_CLOCKS - 1);
  assign next_baud_tick = next_oversample_tick && (baud_cnt == OVERSAMPLE_RATE - 1);
  assign next_baud_cnt = next_oversample_tick ? (next_baud_tick ? '0 : (baud_cnt + 1)) : baud_cnt;
  assign next_oversample_cnt = next_oversample_tick ? '0 : (oversample_cnt + 1);

  always_ff @(posedge clk) begin
    if (!reset_n) begin
      baud_cnt <= '0;
      oversample_cnt <= '0;
      baud_tick <= 1'b0;
      oversample_tick <= 1'b0;
    end else begin
      baud_cnt <= next_baud_cnt;
      oversample_cnt <= next_oversample_cnt;
      baud_tick <= next_baud_tick;
      oversample_tick <= next_oversample_tick;
    end
  end

  // ------------------------------------------------------------------------
  // UART Transmitter
  // ------------------------------------------------------------------------

  localparam int MESSAGE_LENGTH = 15;
  localparam int FIRST_CHAR_INDEX = MESSAGE_LENGTH - 1;

  logic [8*MESSAGE_LENGTH-1:0] message = {"Hello, World!", 8'h0D, 8'h0A};  // "Hello, World!\r\n"
  logic [7:0] current_char;
  logic [$clog2(MESSAGE_LENGTH)-1:0] char_index;
  logic char_sent;

  assign current_char = message[8*char_index+:8];

  always_ff @(posedge clk) begin
    if (!reset_n) begin
      char_index <= FIRST_CHAR_INDEX;
    end else if (char_sent) begin
      if (char_index == 0) begin
        char_index <= FIRST_CHAR_INDEX;
      end else begin
        char_index <= char_index - 1;
      end
    end
  end

  uart_transmitter #(
      .DATA_W(DATA_W),
      .MINIMUM_IDLE_CNT(MINIMUM_IDLE_BITS),
      .BAUD_RATE(BAUD_RATE),
      .PARITY_EN(PARITY_EN),
      .PARITY_EVEN(PARITY_EVEN)
  ) uart_transmitter_inst (
      .clk(clk),
      .reset_n(reset_n),
      .baud_tick(baud_tick),
      .data_in(current_char),
      .in_valid(1'b1),  // Always valid
      .in_ready(char_sent),
      .RsTx(RsTx)
  );

endmodule : uart_controller

`endif  // UART_CONTROLLER_SV
