`ifndef UART_TRANSMITTER_SV
`define UART_TRANSMITTER_SV

// uart_transmitter.sv
// author: Tom Riley
// date: 2026-01-08

// This module implements a simple UART transmitter.
module uart_transmitter #(
    parameter int DATA_W = 8,
    // UART parameters
    parameter int BAUD_RATE = 9600,
    // Minimum number of idle (mark=1) bit-times to insert between frames.
    // This is in units of baud bit periods (not oversample ticks).
    parameter int MINIMUM_IDLE_CNT = 1,
    parameter bit PARITY_EN = 0,
    parameter bit PARITY_EVEN = 1,
    localparam int FRAME_W = DATA_W,
    localparam int FRAME_CNT_W = $clog2(FRAME_W),
    localparam int MIN_IDLE_CNT_W = (MINIMUM_IDLE_CNT > 0) ? $clog2(MINIMUM_IDLE_CNT + 1) : 1
) (
    input logic clk,
    input logic reset_n,
    input logic baud_tick,
    input logic [DATA_W-1:0] data_in,
    input logic in_valid,
    output logic in_ready,
    output logic RsTx
);

  typedef enum logic [2:0] {
    IDLE_PRE_HANDSHAKE,
    IDLE_POST_HANDSHAKE,
    START,
    DATA,
    PARITY,
    STOP,
    MIN_IDLE
  } tx_state_e;

  tx_state_e tx_state, next_tx_state;
  logic [FRAME_CNT_W-1:0] tx_frame_cnt, next_tx_frame_cnt;
  logic [MIN_IDLE_CNT_W-1:0] tx_min_idle_cnt, next_tx_min_idle_cnt;
  logic [DATA_W-1:0] tx_data, next_tx_data;
  logic parity_bit;

  always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      tx_state <= IDLE_PRE_HANDSHAKE;
      tx_frame_cnt <= '0;
      tx_min_idle_cnt <= '0;
      tx_data <= '0;
    end else begin
      tx_state <= next_tx_state;
      tx_frame_cnt <= next_tx_frame_cnt;
      tx_min_idle_cnt <= next_tx_min_idle_cnt;
      tx_data <= next_tx_data;
    end
  end

  localparam tx_state_e POST_DATA_STATE = PARITY_EN ? PARITY : STOP;
  localparam tx_state_e POST_STOP_STATE = (MINIMUM_IDLE_CNT > 0) ? MIN_IDLE : IDLE_PRE_HANDSHAKE;

  always_comb begin
    unique case (tx_state)
      IDLE_PRE_HANDSHAKE: begin
        next_tx_state = (!in_valid)
          ? IDLE_PRE_HANDSHAKE
          : (baud_tick ? START : IDLE_POST_HANDSHAKE);
      end
      IDLE_POST_HANDSHAKE: begin
        next_tx_state = baud_tick ? START : IDLE_POST_HANDSHAKE;
      end
      START: begin
        next_tx_state = baud_tick ? DATA : START;
      end
      DATA: begin
        next_tx_state = baud_tick ? ((tx_frame_cnt == FRAME_W - 1) ? POST_DATA_STATE : DATA) : DATA;
      end
      PARITY: begin
        next_tx_state = baud_tick ? STOP : PARITY;
      end
      STOP: begin
        next_tx_state = baud_tick ? POST_STOP_STATE : STOP;
      end
      MIN_IDLE: begin
        next_tx_state = (baud_tick && (tx_min_idle_cnt == (MINIMUM_IDLE_CNT - 1)))
          ? IDLE_PRE_HANDSHAKE
          : MIN_IDLE;
      end
    endcase
  end

  always_comb begin
    case (tx_state)
      START: begin
        RsTx = 1'b0;
      end
      DATA: begin
        RsTx = tx_data[0];
      end
      PARITY: begin
        RsTx = parity_bit;
      end
      default: begin
        RsTx = 1'b1;
      end
    endcase
  end

  always_comb begin
    case (tx_state)
      IDLE_PRE_HANDSHAKE: begin
        in_ready = 1'b1;
      end
      default: begin
        in_ready = 1'b0;
      end
    endcase
  end

  always_comb begin
    case (tx_state)
      IDLE_PRE_HANDSHAKE: begin
        next_tx_data = in_valid ? data_in : tx_data;
      end
      DATA: begin
        next_tx_data = baud_tick ? {1'b1, tx_data[DATA_W-1:1]} : tx_data;
      end
      default: begin
        next_tx_data = tx_data;
      end
    endcase
  end

  always_comb begin
    case (tx_state)
      START: begin
        next_tx_frame_cnt = '0;
      end
      DATA: begin
        next_tx_frame_cnt = baud_tick ? tx_frame_cnt + 1 : tx_frame_cnt;
      end
      default: begin
        next_tx_frame_cnt = tx_frame_cnt;
      end
    endcase
  end

  always_comb begin
    case (tx_state)
      MIN_IDLE: begin
        next_tx_min_idle_cnt = baud_tick ? (tx_min_idle_cnt + 1) : tx_min_idle_cnt;
      end
      default: begin
        next_tx_min_idle_cnt = tx_min_idle_cnt;
      end
    endcase
  end

endmodule : uart_transmitter

`endif  // UART_TRANSMITTER_SV
