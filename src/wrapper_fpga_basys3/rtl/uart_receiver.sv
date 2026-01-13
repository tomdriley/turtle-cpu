`ifndef UART_RECEIVER_SV
`define UART_RECEIVER_SV

// uart_receiver.sv
// author Tom Riley
// date: 2026-01-11

// This module implemnets a simple UART receiver
module uart_receiver #(
    parameter int DATA_W = 8,
    // UART parameters
    parameter bit PARITY_EN = 0,
    parameter bit PARITY_EVEN = 1,
    parameter int OSR = 16,
    localparam int FRAME_W = DATA_W,
    localparam int FRAME_CNT_W = (DATA_W > 1) ? $clog2(FRAME_W) : 1
) (
    input logic clk,
    input logic reset_n,
    input logic oversample_tick,
    input logic RsRx,
    output logic [DATA_W-1:0] data_out,
    output logic data_valid
);

  typedef enum logic [2:0] {
    IDLE,
    START,
    POST_START,
    DATA,
    PARITY,
    STOP
  } rx_state_e;

  localparam rx_state_e POST_DATA_STATE = PARITY_EN ? PARITY : STOP;
  localparam int SAMPLE_CNT_W = $clog2(OSR);

  rx_state_e rx_state, next_rx_state;
  logic [SAMPLE_CNT_W-1:0] sample_cnt, next_sample_cnt;
  logic [FRAME_CNT_W-1:0] frame_cnt, next_frame_cnt;
  logic [DATA_W-1:0] data_reg, next_data_reg;
  logic next_data_valid;
  logic parity_bit, next_parity_bit;

  always_ff @(posedge clk) begin
    if (!reset_n) begin
      rx_state <= IDLE;
    end else begin
      rx_state <= next_rx_state;
    end
  end

  always_ff @(posedge clk) begin
    if (!reset_n) begin
      sample_cnt <= 0;
    end else begin
      sample_cnt <= next_sample_cnt;
    end
  end

  always_ff @(posedge clk) begin
    if (!reset_n) begin
      frame_cnt <= 0;
    end else begin
      frame_cnt <= next_frame_cnt;
    end
  end

  always_ff @(posedge clk) begin
    if (!reset_n) begin
      data_reg <= 0;
    end else begin
      data_reg <= next_data_reg;
    end
  end

  always_ff @(posedge clk) begin
    if (!reset_n) begin
      parity_bit <= 0;
    end else begin
      parity_bit <= next_parity_bit;
    end
  end

  always_ff @(posedge clk) begin
    if (!reset_n) begin
      data_valid <= 0;
    end else begin
      data_valid <= next_data_valid;
    end
  end

  always_comb begin
    next_rx_state = rx_state;
    unique case (rx_state)
      IDLE: begin
        if (oversample_tick && !RsRx) next_rx_state = START;
      end
      START: begin
        if (oversample_tick && (sample_cnt == SAMPLE_CNT_W'((OSR / 2) - 1))) begin
          next_rx_state = RsRx ? IDLE : POST_START;
        end
      end
      POST_START: begin
        // Immediate transition to reset sample_cnt and start data bit sampling
        next_rx_state = DATA;
      end
      DATA: begin
        if (oversample_tick && (sample_cnt == SAMPLE_CNT_W'(OSR - 1))) begin
          next_rx_state = (frame_cnt == FRAME_CNT_W'(DATA_W - 1)) ? POST_DATA_STATE : DATA;
        end
      end
      PARITY: begin
        if (oversample_tick && (sample_cnt == SAMPLE_CNT_W'(OSR - 1))) begin
          next_rx_state = STOP;
        end
      end
      STOP: begin
        if (oversample_tick && (sample_cnt == SAMPLE_CNT_W'(OSR - 1))) begin
          next_rx_state = IDLE;
        end
      end
      default: next_rx_state = IDLE;
    endcase
  end

  always_comb begin
    next_sample_cnt = sample_cnt;
    unique case (rx_state)
      START, DATA, PARITY, STOP: begin
        if (oversample_tick) begin
          next_sample_cnt = (sample_cnt == SAMPLE_CNT_W'(OSR - 1)) ? '0 : sample_cnt + 1;
        end
      end
      default: next_sample_cnt = 0;
    endcase
  end

  always_comb begin
    next_frame_cnt = frame_cnt;
    unique case (rx_state)
      IDLE, START, POST_START: begin
        next_frame_cnt = 0;
      end
      DATA: begin
        if (oversample_tick && (sample_cnt == SAMPLE_CNT_W'(OSR - 1))) begin
          next_frame_cnt = frame_cnt + 1;
        end
      end
      default: next_frame_cnt = frame_cnt;
    endcase
  end

  generate
    if (DATA_W == 1) begin : gen_data_shift_1
      always_comb begin
        next_data_reg = data_reg;
        if (rx_state == DATA && oversample_tick && (sample_cnt == SAMPLE_CNT_W'(OSR / 2))) begin
          next_data_reg = RsRx;
        end
      end
    end else begin : gen_data_shift
      always_comb begin
        next_data_reg = data_reg;
        if (rx_state == DATA && oversample_tick && (sample_cnt == SAMPLE_CNT_W'(OSR / 2))) begin
          next_data_reg = {RsRx, data_reg[DATA_W-1:1]};  // LSB first
        end
      end
    end
  endgenerate

  always_comb begin
    next_parity_bit = parity_bit;
    if (rx_state == PARITY && oversample_tick && (sample_cnt == SAMPLE_CNT_W'(OSR / 2))) begin
      next_parity_bit = RsRx;
    end else if (rx_state == IDLE) begin
      next_parity_bit = 0;
    end
  end

  assign data_out = data_reg;
  wire parity_ok = PARITY_EN ? (parity_bit == (PARITY_EVEN ? ~^data_reg : ^data_reg)) : 1'b1;

  // Gate data_valid with parity if enabled
  always_comb begin
    next_data_valid = 0;
    if (rx_state == STOP && oversample_tick && (sample_cnt == SAMPLE_CNT_W'(OSR - 1)) && RsRx && parity_ok) begin
      next_data_valid = 1;
    end
  end

endmodule : uart_receiver

`endif  // UART_RECEIVER_SV
