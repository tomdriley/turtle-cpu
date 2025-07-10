`ifndef REGISTER_FILE_TB
`define REGISTER_FILE_TB

// register_file_tb.sv
// author: Tom Riley
// date: 2025-07-10

/* verilator lint_off IMPORTSTAR */
import register_file_pkg::*;
/* verilator lint_on IMPORTSTAR */

// Testbench for the register_file module
module register_file_tb;
    initial begin
        $dumpfile("waves.vcd");
        $dumpvars(0, register_file_tb);
    end

    // Parameters
    localparam DATA_W = 8;
    localparam D_ADDR_W = 12;
    localparam I_ADDR_W = 12;
    localparam NUM_GPR = 8;
    localparam REG_ADDR_WIDTH = 4;

    // Signals
    logic clk;
    logic reset_n;
    wire [DATA_W-1:0] acc_out;
    logic [DATA_W-1:0] acc_in;
    logic acc_write_enable;
    logic read_get_to_acc;
    logic write_put_acc;
    logic [REG_ADDR_WIDTH-1:0] reg_addr;
    logic read_data_output_enable;
    wire [DATA_W-1:0] read_data;
    logic status_write_enable;
    logic zero_flag;
    logic negative_flag;
    logic carry_flag;
    logic overflow_flag;
    wire [D_ADDR_W-1:0] dmar;
    wire [I_ADDR_W-1:0] imar;

    // Instantiate the register file
    register_file #(
        .DATA_W(DATA_W),
        .D_ADDR_WIDTH(D_ADDR_W),
        .I_ADDR_WIDTH(I_ADDR_W),
        .NUM_GPR(NUM_GPR),
        .REG_ADDR_WIDTH(REG_ADDR_WIDTH)
    ) uut (
        .clk(clk),
        .reset_n(reset_n),
        .acc_out(acc_out),
        .acc_in(acc_in),
        .acc_write_enable(acc_write_enable),
        .read_get_to_acc(read_get_to_acc),
        .write_put_acc(write_put_acc),
        .reg_addr(reg_addr),
        .read_data_output_enable(read_data_output_enable),
        .read_data(read_data),
        .status_write_enable(status_write_enable),
        .zero_flag(zero_flag),
        .negative_flag(negative_flag),
        .carry_flag(carry_flag),
        .overflow_flag(overflow_flag),
        .dmar(dmar),
        .imar(imar)
    );

    // Clock generation
    always #5ns clk = ~clk;

    // Task to write to accumulator
    task automatic write_accumulator(
        input [DATA_W-1:0] data,
        input string test_name
    );
        acc_in = data;
        acc_write_enable = 1'b1;
        @(posedge clk);
        @(negedge clk);
        acc_write_enable = 1'b0;
        $display("Write ACC: %s | Data=%02h ACC_OUT=%02h", test_name, data, acc_out);
    endtask

    // Task to write to status register
    task automatic write_status_register(
        input logic zero,
        input logic negative,
        input logic carry,
        input logic overflow,
        input string test_name
    );
        zero_flag = zero;
        negative_flag = negative;
        carry_flag = carry;
        overflow_flag = overflow;
        status_write_enable = 1'b1;
        @(posedge clk);
        @(negedge clk);
        status_write_enable = 1'b0;
        $display("Write Status: %s | Z=%b N=%b C=%b O=%b", test_name, zero, negative, carry, overflow);
    endtask

    // Task to PUT (write from accumulator to register)
    task automatic put_register(
        input [REG_ADDR_WIDTH-1:0] addr,
        input string test_name
    );
        reg_addr = addr;
        write_put_acc = 1'b1;
        @(posedge clk);
        @(negedge clk);
        write_put_acc = 1'b0;
        $display("PUT: %s | Addr=%h ACC=%02h", test_name, addr, acc_out);
    endtask

    // Task to GET (read from register to accumulator)
    task automatic get_register(
        input [REG_ADDR_WIDTH-1:0] addr,
        input string test_name
    );
        reg_addr = addr;
        read_get_to_acc = 1'b1;
        @(posedge clk);
        @(negedge clk);
        read_get_to_acc = 1'b0;
        $display("GET: %s | Addr=%h ACC=%02h", test_name, addr, acc_out);
    endtask

    // Task to read register data with output enable
    task automatic read_register_data(
        input [REG_ADDR_WIDTH-1:0] addr,
        input logic enable,
        input string test_name
    );
        reg_addr = addr;
        read_data_output_enable = enable;
        #10ns;
        if (enable) begin
            $display("Read: %s | Addr=%h Data=%02h", test_name, addr, read_data);
        end else begin
            $display("Read: %s | Addr=%h Data=Hi-Z (enable=%b)", test_name, addr, enable);
        end
        read_data_output_enable = 1'b0;
    endtask

    // Test sequence
    initial begin
        $display("Starting Register File testbench...");
        
        // Initialize signals
        clk = 1'b0;
        reset_n = 1'b0;
        acc_in = '0;
        acc_write_enable = 1'b0;
        read_get_to_acc = 1'b0;
        write_put_acc = 1'b0;
        reg_addr = '0;
        read_data_output_enable = 1'b0;
        status_write_enable = 1'b0;
        zero_flag = 1'b0;
        negative_flag = 1'b0;
        carry_flag = 1'b0;
        overflow_flag = 1'b0;
        
        // Apply reset
        #20ns;
        reset_n = 1'b1;
        #10ns;
        
        $display("Initial state after reset:");
        $display("  ACC_OUT: %02h", acc_out);
        $display("  DMAR: %03h", dmar);
        $display("  IMAR: %03h", imar);

        // Test accumulator write/read
        write_accumulator(8'hAA, "ACC_Write_Test");
        write_accumulator(8'h55, "ACC_Write_Test2");
        
        // Test status register write
        write_status_register(1'b1, 1'b0, 1'b1, 1'b0, "Status_Test1");
        write_status_register(1'b0, 1'b1, 1'b0, 1'b1, "Status_Test2");

        // Test PUT operations (write from ACC to registers)
        write_accumulator(8'h11, "Setup_for_PUT");
        put_register(REG_R0, "PUT_R0");
        
        write_accumulator(8'h22, "Setup_for_PUT");
        put_register(REG_R1, "PUT_R1");
        
        write_accumulator(8'h33, "Setup_for_PUT");
        put_register(REG_R2, "PUT_R2");
        
        write_accumulator(8'h44, "Setup_for_PUT");
        put_register(REG_DBAR, "PUT_DBAR");
        
        write_accumulator(8'h55, "Setup_for_PUT");
        put_register(REG_DOFF, "PUT_DOFF");
        
        write_accumulator(8'h66, "Setup_for_PUT");
        put_register(REG_IBAR, "PUT_IBAR");
        
        write_accumulator(8'h77, "Setup_for_PUT");
        put_register(REG_IOFF, "PUT_IOFF");

        // Test GET operations (read from registers to ACC)
        get_register(REG_R0, "GET_R0");
        get_register(REG_R1, "GET_R1");
        get_register(REG_R2, "GET_R2");
        get_register(REG_DBAR, "GET_DBAR");
        get_register(REG_DOFF, "GET_DOFF");
        get_register(REG_IBAR, "GET_IBAR");
        get_register(REG_IOFF, "GET_IOFF");
        
        // Test reading status register
        get_register(REG_STATUS, "GET_STATUS");

        // Test reading accumulator register
        get_register(REG_ACC, "GET_ACC");

        // Test read data output with tristate control
        read_register_data(REG_R0, 1'b1, "Read_R0_Enabled");
        read_register_data(REG_R1, 1'b1, "Read_R1_Enabled");
        read_register_data(REG_R0, 1'b0, "Read_R0_Disabled");

        // Test all general purpose registers
        $display("Testing all general purpose registers...");
        for (int i = 0; i < NUM_GPR; i++) begin
            write_accumulator(DATA_W'(8'h80 + i), $sformatf("Setup_GPR_%0d", i));
            put_register(REG_ADDR_WIDTH'(i), $sformatf("PUT_GPR_%0d", i));
            get_register(REG_ADDR_WIDTH'(i), $sformatf("GET_GPR_%0d", i));
            read_register_data(REG_ADDR_WIDTH'(i), 1'b1, $sformatf("Read_GPR_%0d", i));
        end

        // Test DMAR and IMAR address formation
        $display("Testing address register formation...");
        write_accumulator(8'h12, "DBAR_Setup");
        put_register(REG_DBAR, "PUT_DBAR_12");
        write_accumulator(8'h34, "DOFF_Setup");
        put_register(REG_DOFF, "PUT_DOFF_34");
        #10ns;
        $display("DMAR formed: %03h (expected: 1234)", dmar);
        
        write_accumulator(8'h56, "IBAR_Setup");
        put_register(REG_IBAR, "PUT_IBAR_56");
        write_accumulator(8'h78, "IOFF_Setup");
        put_register(REG_IOFF, "PUT_IOFF_78");
        #10ns;
        $display("IMAR formed: %03h (expected: 5678)", imar);

        // Test reset functionality
        $display("Testing reset functionality...");
        reset_n = 1'b0;
        @(posedge clk);
        @(negedge clk);
        reset_n = 1'b1;
        @(posedge clk);
        @(negedge clk);
        $display("After reset - ACC_OUT: %02h DMAR: %03h IMAR: %03h", acc_out, dmar, imar);

        // Test edge cases
        $display("Testing edge cases...");
        
        // Test writing to invalid register addresses
        write_accumulator(8'hFF, "Invalid_Reg_Setup");
        put_register(4'hC, "PUT_Invalid_Reg_C");
        get_register(4'hC, "GET_Invalid_Reg_C");
        
        // Test simultaneous operations (should not happen in real design)
        write_accumulator(8'h99, "Simultaneous_Test_Setup");
        acc_write_enable = 1'b1;
        read_get_to_acc = 1'b1;
        reg_addr = REG_R0;
        @(posedge clk);
        @(negedge clk);
        acc_write_enable = 1'b0;
        read_get_to_acc = 1'b0;
        $display("Simultaneous operations test - ACC_OUT: %02h", acc_out);

        $display("Register File testbench completed successfully!");
        $finish;
    end

endmodule

`endif // REGISTER_FILE_TB
