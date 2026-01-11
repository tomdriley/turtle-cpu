`ifndef FIFO_SYNC_SV
`define FIFO_SYNC_SV

// fifo_sync.sv
// author: Tom Riley
// date: 2026-01-10

// This module implements a synchronous FIFO.
module fifo_sync #(
    parameter  int DATA_W  = 8,
    parameter  int ENTRIES = 12,
    localparam int DEPTH   = ENTRIES + 1,
    localparam int CNT_W   = $clog2(DEPTH)
) (
    input  logic              clk,
    input  logic              reset_n,
    input  logic              write_en,
    input  logic [DATA_W-1:0] write_data,
    output logic              full,
    input  logic              read_en,
    output logic [DATA_W-1:0] read_data,
    output logic              empty,
    output logic [   CNT_W:0] status_count,
    output logic              status_overflow,
    output logic              status_underflow
);

  logic write_transfer = write_en && !full;
  logic read_transfer = read_en && !empty;

  logic [ENTRIES:0][DATA_W-1:0] mem;

  logic [CNT_W-1:0] read_ptr;
  logic [CNT_W-1:0] write_ptr;

  assign empty = (read_ptr == write_ptr);
  assign full  = ((write_ptr == ENTRIES) && (read_ptr == 0)) || ((write_ptr + 1) == read_ptr);

  always @(posedge clk) begin
    if (!reset_n) begin
      status_count <= '0;
    end else begin
      if (write_transfer && !read_transfer) begin
        status_count <= status_count + 1;
      end else if (!write_transfer && read_transfer) begin
        status_count <= status_count - 1;
      end else begin
        status_count <= status_count;
      end
    end
  end

  always @(posedge clk) begin
    if (!reset_n) begin
      write_ptr <= '0;
    end else begin
      if (write_transfer && (write_ptr == ENTRIES)) begin
        write_ptr <= '0;
      end else if (write_transfer) begin
        write_ptr <= write_ptr + 1;
      end else begin
        write_ptr <= write_ptr;
      end
    end
  end

  always @(posedge clk) begin
    if (!reset_n) begin
      read_ptr <= '0;
    end else begin
      if (read_transfer && (read_ptr == ENTRIES)) begin
        read_ptr <= '0;
      end else if (read_transfer) begin
        read_ptr <= read_ptr + 1;
      end else begin
        read_ptr <= read_ptr;
      end
    end
  end

  assign read_data = mem[read_ptr];

  always @(posedge clk) begin
    if (!reset_n) begin
      mem <= '0;  // Reset to known state
    end else if (write_transfer) begin
      mem[write_ptr] <= write_data;
    end
  end

  always @(posedge clk) begin
    if (!reset_n) begin
      status_overflow  <= 0;
      status_underflow <= 0;
    end else begin
      status_overflow  <= status_overflow || (write_en && full);
      status_underflow <= status_underflow || (read_en && empty);
    end
  end

`ifdef FORMAL
  // Formal verification properties

  reg f_past_valid;
  initial f_past_valid = 1'b0;
  always @(posedge clk) begin
    f_past_valid <= 1'b1;
  end

  // Do not depend on a particular reset sequence in formal.
  // Instead, constrain the initial internal state to a legal (reset-like) state.
  // Minimal initial constraints: allow any consistent occupancy and flags.
  // This avoids over-constraining to all-zeros while still providing
  // a valid base for k-induction.
  always_comb begin
    if ($initstate) begin
      assume (status_count <= ENTRIES);
      // Constrain pointers to valid ring range to avoid inconsistent basecases
      assume (read_ptr  <= ENTRIES);
      assume (write_ptr <= ENTRIES);
      assume (full == (status_count == ENTRIES));
      assume (empty == (status_count == 0));
      assume (status_count == ((write_ptr >= read_ptr)
          ? (write_ptr - read_ptr)
          : (DEPTH + write_ptr - read_ptr)));
      assume (status_overflow == 1'b0);
      assume (status_underflow == 1'b0);
    end
  end

  // Reset properties for synchronous reset.
  // In SVA sampling, flop outputs update after the clock edge, so check the
  // reset effect one cycle after reset was asserted.
  always @(posedge clk) begin
    if (f_past_valid && $past(!reset_n)) begin
      reset_status_count : assert (status_count == '0);
      reset_full : assert (!full);
      reset_empty : assert (empty);
      reset_status_overflow : assert (!status_overflow);
      reset_status_underflow : assert (!status_underflow);
    end
  end

  // Full and empty flags consistency
  always @(posedge clk) begin
    if (reset_n && f_past_valid && $past(reset_n)) begin
      full_consistency : assert (full == (status_count == ENTRIES));
      empty_consistency : assert (empty == (status_count == 0));
    end
  end

  // Occupancy invariants: status_count matches pointer distance and stays within bounds.
  always @(posedge clk) begin
    if (reset_n && f_past_valid && $past(reset_n)) begin
      // Runtime pointer range safety
      ptr_range : assert ((write_ptr <= ENTRIES) && (read_ptr <= ENTRIES));
      count_bound : assert (status_count <= ENTRIES);
      ptr_distance_consistency :
      assert (status_count == ((write_ptr >= read_ptr)
          ? (write_ptr - read_ptr)
          : (DEPTH + write_ptr - read_ptr)));
    end
  end


  // Overflow and underflow conditions
  always @(posedge clk) begin
    if (f_past_valid && reset_n && $past(reset_n)) begin
      if ($past(write_en) && $past(full)) begin
        overflow_condition : assert (status_overflow);
      end

      if ($past(read_en) && $past(empty)) begin
        underflow_condition : assert (status_underflow);
      end
    end
  end

  // Count update logic
  always @(posedge clk) begin
    if (f_past_valid && reset_n && $past(reset_n)) begin
      if ($past(write_transfer) && !$past(read_transfer)) begin
        status_count_increment : assert (status_count == $past(status_count) + 1);
      end else if (!$past(write_transfer) && $past(read_transfer)) begin
        status_count_decrement : assert (status_count == $past(status_count) - 1);
      end else begin
        status_count_no_change : assert (status_count == $past(status_count));
      end
    end
  end

  // Count should always change by at most 1
  always @(posedge clk) begin
    if (f_past_valid && reset_n && $past(reset_n)) begin
      // maximum_count_change :
      // assert ((status_count <= $past(
      //     status_count
      // ) + 1) && (status_count >= $past(
      //     status_count
      // ) - 1));
      maximum_count_change :
      assert ((status_count == $past(
          status_count
      )) || (($past(
          status_count
      ) <= ENTRIES) && (status_count == ($past(
          status_count
      ) + 1))) || (($past(
          status_count
      ) > 0) && (status_count == ($past(
          status_count
      ) - 1))));
    end
  end

  // Empty fifo data integrity
  // If fifo is empty, and a write occurs, followed by a read, the data read should match the data written.
  logic [DATA_W-1:0] f_expected_data;
  logic              f_expected_valid;

  initial f_expected_data = '0;
  initial f_expected_valid = 1'b0;

  always @(posedge clk) begin
    if (!reset_n) begin
      f_expected_valid <= 1'b0;
    end else begin
      // When exactly one item is in the FIFO (coming from empty), remember it.
      if (empty && (status_count == 0) && write_transfer && !read_transfer) begin
        f_expected_data  <= write_data;
        f_expected_valid <= 1'b1;
      end else if ((status_count != 1) || (write_transfer && !read_transfer && !empty)) begin
        // If we leave the single-item state or enqueue another item, expectation no longer applies.
        f_expected_valid <= 1'b0;
      end

      // Once a successful read of that single item occurs, drop the expectation.
      if (read_transfer) begin
        f_expected_valid <= 1'b0;
      end
    end
  end

  always @(posedge clk) begin
    if (f_past_valid && reset_n && $past(reset_n)) begin
      if (f_expected_valid) begin
        empty_expected_mem_image : assert (mem[read_ptr] == f_expected_data);
      end

      if ($past(f_expected_valid)) begin
        // Invariant: expectation corresponds to a single stored item in the prior cycle.
        empty_expectation_singleton : assert ($past(status_count) == 1);
      end

      // When we actually performed the read in the prior cycle, the data must match.
      if ($past(f_expected_valid && read_transfer)) begin
        empty_data_integrity : assert ($past(read_data) == $past(f_expected_data));
      end
    end
  end

  // Cover properties
  // Cover that fifo becomes full
  always @(posedge clk) begin
    if (f_past_valid) begin
      cover_full : cover (full);
    end
  end
  // Cover that fifo becomes empty
  always @(posedge clk) begin
    if (f_past_valid) begin
      cover_empty : cover (empty);
    end
  end

`endif  // FORMAL

endmodule : fifo_sync

`endif  // FIFO_SYNC_SV
