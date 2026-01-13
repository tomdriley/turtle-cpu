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
    localparam int BAUD_CNT_W = $clog2(OVERSAMPLE_RATE),
    // Calculate baud clocks by oversample clock first, then multiplying
    // to ensure integer math works out. This will round down, but the error
    // should be negligible.
    localparam int OVERSAMPLE_CLOCKS = CLOCK_FREQ / (BAUD_RATE * OVERSAMPLE_RATE),
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
  // UART Rx/Tx loopback with FIFOs
  // ------------------------------------------------------------------------

  // Receiver signals
  logic [DATA_W-1:0] rx_data;
  logic rx_valid;

  // RX FIFO
  logic rx_fifo_full, rx_fifo_empty;
  logic [DATA_W-1:0] rx_fifo_rdata;
  logic rx_fifo_read;
  logic rx_fifo_write;

  // TX FIFO
  logic tx_fifo_full, tx_fifo_empty;
  logic [DATA_W-1:0] tx_fifo_rdata;
  logic tx_fifo_write;
  logic tx_fifo_read;

  // Loopback policy: whenever RX FIFO has data and TX FIFO has space, move one byte
  assign tx_fifo_write = !rx_fifo_empty && !tx_fifo_full;
  assign rx_fifo_read  = tx_fifo_write;

  // RX FIFO write when UART delivers a byte
  assign rx_fifo_write = rx_valid && !rx_fifo_full;

  fifo_sync #(
      .DATA_W (DATA_W),
      .ENTRIES(16)
  ) rx_fifo_inst (
      .clk(clk),
      .reset_n(reset_n),
      .write_en(rx_fifo_write),
      .write_data(rx_data),
      .full(rx_fifo_full),
      .read_en(rx_fifo_read),
      .read_data(rx_fifo_rdata),
      .empty(rx_fifo_empty),
      .status_count(),
      .status_overflow(),
      .status_underflow()
  );

  fifo_sync #(
      .DATA_W (DATA_W),
      .ENTRIES(16)
  ) tx_fifo_inst (
      .clk(clk),
      .reset_n(reset_n),
      .write_en(tx_fifo_write),
      .write_data(rx_fifo_rdata),
      .full(tx_fifo_full),
      .read_en(tx_fifo_read & !tx_fifo_empty),
      .read_data(tx_fifo_rdata),
      .empty(tx_fifo_empty),
      .status_count(),
      .status_overflow(),
      .status_underflow()
  );

  uart_receiver #(
      .DATA_W(DATA_W),
      .PARITY_EN(PARITY_EN),
      .PARITY_EVEN(PARITY_EVEN),
      .OSR(OVERSAMPLE_RATE)
  ) uart_receiver_inst (
      .clk(clk),
      .reset_n(reset_n),
      .oversample_tick(oversample_tick),
      .RsRx(RsRx),
      .data_out(rx_data),
      .data_valid(rx_valid)
  );

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
      .data_in(tx_fifo_rdata),
      .in_valid(~tx_fifo_empty),
      .in_ready(tx_fifo_read),
      .RsTx(RsTx)
  );

endmodule : uart_controller

`endif  // UART_CONTROLLER_SV
