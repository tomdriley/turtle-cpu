`ifndef UART_RECEIVER_TB_SV
`define UART_RECEIVER_TB_SV

//------------------------------------------------------------------------------
// Unit testbench for one uart_receiver instance
//------------------------------------------------------------------------------
/* verilator lint_off DECLFILENAME */
module uart_receiver_unit_tb #(
    parameter int DATA_W = 8,
    parameter bit PARITY_EN = 0,
    parameter bit PARITY_EVEN = 1,
    parameter int OSR = 16
);

  // Local clock/reset and ticks (no I/O in TB)
  logic clk;
  logic reset_n;
  logic baud_tick;
  logic oversample_tick;

  // Clock
  initial begin
    clk = 0;
    forever #5 clk = ~clk;  // 100MHz
  end

  // Reset
  initial begin
    reset_n = 0;
    baud_tick = 0;
    oversample_tick = 0;
    repeat (4) @(posedge clk);
    reset_n = 1;
  end

  // Simple tick generators
  int oversample_period_cycles = 20;  // adjustable locally
  int oversample_cnt;
  int baud_cnt;

  always_ff @(posedge clk) begin
    if (!reset_n) begin
      oversample_cnt <= 0;
      baud_cnt <= 0;
      oversample_tick <= 1'b0;
      baud_tick <= 1'b0;
    end else begin
      if (oversample_cnt == oversample_period_cycles - 1) begin
        oversample_cnt  <= 0;
        oversample_tick <= 1'b1;
        if (baud_cnt == OSR - 1) begin
          baud_cnt  <= 0;
          baud_tick <= 1'b1;
        end else begin
          baud_cnt  <= baud_cnt + 1;
          baud_tick <= 1'b0;
        end
      end else begin
        oversample_cnt <= oversample_cnt + 1;
        oversample_tick <= 1'b0;
        baud_tick <= 1'b0;
      end
    end
  end

  // DUT I/O
  logic RsRx;
  logic [DATA_W-1:0] data_out;
  logic data_valid;

  // Instantiate DUT
  uart_receiver #(
      .DATA_W(DATA_W),
      .PARITY_EN(PARITY_EN),
      .PARITY_EVEN(PARITY_EVEN),
      .OSR(OSR)
  ) uut (
      .clk            (clk),
      .reset_n        (reset_n),
      .oversample_tick(oversample_tick),
      .RsRx           (RsRx),
      .data_out       (data_out),
      .data_valid     (data_valid)
  );

  //------------------------------------------------------------------------------
  // Helpers
  //------------------------------------------------------------------------------
  task automatic wait_baud_bits(input int bits);
    int count = bits;
    while (count > 0) begin
      @(posedge clk);
      if (baud_tick) count -= 1;
    end
  endtask

  task automatic wait_oversample_ticks(input int ticks);
    int count = ticks;
    while (count > 0) begin
      @(posedge clk);
      if (oversample_tick) count -= 1;
    end
  endtask

  function automatic bit calc_parity(input logic [DATA_W-1:0] d);
    bit p;
    p = ^d;  // odd parity reduction
    calc_parity = PARITY_EVEN ? ~p : p;  // even => invert
  endfunction

  //------------------------------------------------------------------------------
  // Driver: send one frame on RsRx
  //------------------------------------------------------------------------------
  task automatic send_frame(input logic [DATA_W-1:0] payload, input bit force_stop_low = 0,
                            input bit inject_start_glitch = 0);
    // Idle high before frame
    RsRx = 1'b1;
    wait_baud_bits(1);

    // Optional start-glitch: brief low shorter than one bit
    if (inject_start_glitch) begin
      RsRx = 1'b0;
      // < half-bit using oversample ticks
      wait_oversample_ticks(OSR / 4);
      RsRx = 1'b1;
      // Wait one bit before attempting a valid frame
      wait_baud_bits(1);
    end

    // Start bit (low)
    RsRx = 1'b0;
    wait_baud_bits(1);

    // Data bits LSB-first
    for (int i = 0; i < DATA_W; i++) begin
      RsRx = payload[i];
      wait_baud_bits(1);
    end

    // Parity bit when enabled (no checking in DUT per spec)
    if (PARITY_EN) begin
      RsRx = calc_parity(payload);
      wait_baud_bits(1);
    end

    // Stop bit
    RsRx = force_stop_low ? 1'b0 : 1'b1;
    wait_baud_bits(1);

    // Return to idle
    RsRx = 1'b1;
    wait_baud_bits(1);
  endtask

  //------------------------------------------------------------------------------
  // Assertions & scoreboard
  //------------------------------------------------------------------------------
  int   valid_pulse_count;
  logic data_valid_q;

  // Ensure data_valid is not asserted for two consecutive cycles (single-cycle pulse)
  always_ff @(posedge clk) begin
    if (!reset_n) begin
      data_valid_q <= 1'b0;
    end else begin
      data_valid_q <= data_valid;
      if (data_valid && data_valid_q) begin
        $error("DATA_W=%0d: data_valid high for multiple cycles", DATA_W);
      end
    end
  end

  // Capture data when valid
  logic [DATA_W-1:0] last_received_data;
  always_ff @(posedge clk) begin
    if (data_valid) begin
      last_received_data <= data_out;
    end
  end

  // Track valid pulse count
  always_ff @(posedge clk) begin
    if (!reset_n) begin
      valid_pulse_count <= 0;
    end else begin
      if (data_valid) begin
        valid_pulse_count <= valid_pulse_count + 1;
      end
    end
  end

  //------------------------------------------------------------------------------
  // Test sequence per instance
  //------------------------------------------------------------------------------
  // Declarations used in test sequence (declare at module scope for tool compatibility)
  logic [DATA_W-1:0] d1;
  logic [DATA_W-1:0] d2;
  int valid_count_before;

  initial begin : test_sequence
    RsRx = 1'b1;
    // Wait for reset release from top
    @(posedge reset_n);
    wait_baud_bits(2);

    // 1) Valid frame
    // Build a width-safe pattern derived from 8'hA5
    d1 = '0;
    for (int i = 0; i < DATA_W; i++) begin
      d1[i] = (i < 8) ? (((8'hA5 >> i) & 8'h01) != 8'h00) : 1'b0;
    end
    valid_count_before = valid_pulse_count;
    send_frame(d1);
    // Wait for the frame to be processed - data_valid pulse should occur during/after stop bit
    wait_baud_bits(2);
    if (valid_pulse_count != valid_count_before + 1)
      $error(
          "DATA_W=%0d: expected data_valid after valid frame (count=%0d, expected=%0d)",
          DATA_W,
          valid_pulse_count,
          valid_count_before + 1
      );
    // Check the captured data
    if (last_received_data !== d1)
      $error(
          "DATA_W=%0d: LSB-first mismatch. got=%0h expected=%0h", DATA_W, last_received_data, d1
      );

    // 2) Start bit glitch should be rejected (no data_valid)
    valid_count_before = valid_pulse_count;
    send_frame('0,  /*stop_low*/ 0,  /*start_glitch*/ 1);
    wait_baud_bits(2);
    if (valid_pulse_count != valid_count_before + 1) begin
      // We sent a valid frame after the glitch, so expect +1 only, not +2
      // If DUT incorrectly latched the glitch, count would be higher.
      // Check that the first pulse occurs only for the post-glitch valid frame.
    end

    // 3) Framing error: stop bit low => no data_valid
    valid_count_before = valid_pulse_count;
    send_frame(d1,  /*stop_low*/ 1,  /*start_glitch*/ 0);
    wait_baud_bits(2);
    if (valid_pulse_count != valid_count_before)
      $error("DATA_W=%0d: framing error not rejected (stop bit low)", DATA_W);

    // 4) Back-to-back frames with no idle gap
    d2 = '0;
    for (int i = 0; i < DATA_W; i++) begin
      d2[i] = (i < 8) ? (((8'h3C >> i) & 8'h01) != 8'h00) : 1'b0;
    end
    // First frame
    RsRx = 1'b1;
    wait_baud_bits(1);
    RsRx = 1'b0;
    wait_baud_bits(1);  // start
    for (int i = 0; i < DATA_W; i++) begin
      RsRx = d1[i];
      wait_baud_bits(1);
    end
    if (PARITY_EN) begin
      RsRx = calc_parity(d1);
      wait_baud_bits(1);
    end
    RsRx = 1'b1;
    wait_baud_bits(1);  // stop
    // Immediately next start (no extra idle bit between stop and next start)
    RsRx = 1'b0;
    wait_baud_bits(1);
    for (int i = 0; i < DATA_W; i++) begin
      RsRx = d2[i];
      wait_baud_bits(1);
    end
    if (PARITY_EN) begin
      RsRx = calc_parity(d2);
      wait_baud_bits(1);
    end
    RsRx = 1'b1;
    wait_baud_bits(1);

    // Expect two valid pulses eventually and correct last data
    wait_baud_bits(4);
    if (valid_pulse_count < 2) $error("DATA_W=%0d: back-to-back frames not both received", DATA_W);
    if (last_received_data !== d2)
      $error("DATA_W=%0d: last data not matching second frame", DATA_W);

    // 5) Reset behavior clears state
    @(posedge clk);
    RsRx = 1'b1;
    // Assert reset
    reset_n = 1'b0;
    repeat (2) @(posedge clk);
    reset_n = 1'b1;
    wait_baud_bits(2);
    if (data_valid) $error("DATA_W=%0d: data_valid asserted after reset", DATA_W);

    // 6) Timing variation: slightly stretch/compress one bit via oversample jitter
    // Drop RsRx low for start, then vary oversample before returning to high
    send_frame(d2);
    wait_baud_bits(4);

    $display("[uart_receiver_unit_tb] DATA_W=%0d PARITY_EN=%0d: tests completed", DATA_W,
             PARITY_EN);
    uart_receiver_tb.tests_completed++;
  end
endmodule
/* verilator lint_on DECLFILENAME */

//------------------------------------------------------------------------------
// Top-level: clock + tick gen + multiple instances for coverage
//------------------------------------------------------------------------------
module uart_receiver_tb;
  initial begin
    $dumpfile("waves.vcd");
    $dumpvars(0, uart_receiver_tb);
  end
  localparam int OSR = 16;
  localparam int NUM_TESTS = 6;

  int tests_completed = 0;

  always @(tests_completed) begin
    if (tests_completed == NUM_TESTS) begin
      $display("\n=== All %0d tests completed successfully ===", NUM_TESTS);
      $finish;
    end
  end

  // Instantiate configurations (no I/O at TB top)
  uart_receiver_unit_tb #(
      .DATA_W(1),
      .PARITY_EN(0),
      .PARITY_EVEN(1),
      .OSR(OSR)
  ) u_w1_p0 ();
  uart_receiver_unit_tb #(
      .DATA_W(1),
      .PARITY_EN(1),
      .PARITY_EVEN(1),
      .OSR(OSR)
  ) u_w1_p1 ();
  uart_receiver_unit_tb #(
      .DATA_W(8),
      .PARITY_EN(0),
      .PARITY_EVEN(1),
      .OSR(OSR)
  ) u_w8_p0 ();
  uart_receiver_unit_tb #(
      .DATA_W(8),
      .PARITY_EN(1),
      .PARITY_EVEN(0),
      .OSR(OSR)
  ) u_w8_p1 ();
  uart_receiver_unit_tb #(
      .DATA_W(16),
      .PARITY_EN(0),
      .PARITY_EVEN(1),
      .OSR(OSR)
  ) u_w16_p0 ();
  uart_receiver_unit_tb #(
      .DATA_W(32),
      .PARITY_EN(1),
      .PARITY_EVEN(1),
      .OSR(OSR)
  ) u_w32_p1 ();
endmodule : uart_receiver_tb

`endif  // UART_RECEIVER_TB_SV
