`ifndef PROGRAM_COUNTER_TB
`define PROGRAM_COUNTER_TB

// program_counter_tb.sv
// author: Tom Riley
// date: 2025-07-10

/* verilator lint_off IMPORTSTAR */
import program_counter_pkg::*;
import register_file_pkg::*;
/* verilator lint_on IMPORTSTAR */

// Testbench for the program_counter module
module program_counter_tb;
    initial begin
        $dumpfile("waves.vcd");
        $dumpvars(0, program_counter_tb);
    end

    // Parameters
    localparam I_ADDR_W = 12;
    localparam DATA_W = 8;

    // Signals
    logic clk;
    logic rst_n;
    logic [I_ADDR_W-1:0] imar;
    logic [I_ADDR_W-1:0] address_immediate;
    logic jump_branch_select;
    logic immediate_select;
    logic unconditional_branch;
    logic [DATA_W-1:0] status_register;
    logic [2:0] branch_condition;
    wire [I_ADDR_W-1:0] pc;

    // Instantiate the program counter
    program_counter #(
        .I_ADDR_W(I_ADDR_W),
        .DATA_W(DATA_W)
    ) uut (
        .clk(clk),
        .rst_n(rst_n),
        .imar(imar),
        .address_immediate(address_immediate),
        .jump_branch_select(jump_branch_select),
        .immediate_select(immediate_select),
        .unconditional_branch(unconditional_branch),
        .status_register(status_register),
        .branch_condition(branch_condition),
        .pc(pc)
    );

    // Clock generation
    always #5ns clk = ~clk;

    // Task to setup status register with specific flags
    task automatic setup_status_flags(
        input logic zero,
        input logic negative,
        input logic carry,
        input logic overflow
    );
        status_register = '0;
        status_register[ZERO_FLAG] = zero;
        status_register[NEGATIVE_FLAG] = negative;
        status_register[CARRY_FLAG] = carry;
        status_register[OVERFLOW_FLAG] = overflow;
    endtask

    // Task to test normal PC increment
    task automatic test_pc_increment(
        input string test_name
    );
        jump_branch_select = 1'b0;
        immediate_select = 1'b0;
        unconditional_branch = 1'b0;
        @(posedge clk);
        @(negedge clk);
        $display("Test: %s | PC=%03h", test_name, pc);
    endtask

    // Task to test unconditional branch
    task automatic test_unconditional_branch(
        input [I_ADDR_W-1:0] target_addr,
        input logic use_immediate,
        input string test_name
    );
        if (use_immediate) begin
            address_immediate = target_addr;
            immediate_select = 1'b1;
        end else begin
            imar = target_addr;
            immediate_select = 1'b0;
        end
        jump_branch_select = 1'b1;
        unconditional_branch = 1'b1;
        @(posedge clk);
        @(negedge clk);
        $display("Test: %s | Target=%03h PC=%03h", test_name, target_addr, pc);
        jump_branch_select = 1'b0;
        unconditional_branch = 1'b0;
    endtask

    // Task to test conditional branch
    task automatic test_conditional_branch(
        input [I_ADDR_W-1:0] target_addr,
        input logic use_immediate,
        input branch_condition_e condition,
        input logic zero_flag,
        input logic negative_flag,
        input logic carry_flag,
        input logic overflow_flag,
        input string test_name
    );
        setup_status_flags(zero_flag, negative_flag, carry_flag, overflow_flag);
        if (use_immediate) begin
            address_immediate = target_addr;
            immediate_select = 1'b1;
        end else begin
            imar = target_addr;
            immediate_select = 1'b0;
        end
        jump_branch_select = 1'b1;
        unconditional_branch = 1'b0;
        branch_condition = condition;
        @(posedge clk);
        @(negedge clk);
        $display("Test: %s | Condition=%s Target=%03h PC=%03h", 
                test_name, condition.name(), target_addr, pc);
        jump_branch_select = 1'b0;
    endtask

    // Test sequence
    initial begin
        $display("Starting Program Counter testbench...");
        
        // Initialize signals
        clk = 1'b0;
        rst_n = 1'b0;
        imar = '0;
        address_immediate = '0;
        jump_branch_select = 1'b0;
        immediate_select = 1'b0;
        unconditional_branch = 1'b0;
        status_register = '0;
        branch_condition = COND_ZERO;
        
        // Apply reset
        #20ns;
        rst_n = 1'b1;
        #10ns;
        
        $display("PC after reset: %03h", pc);

        // Test normal PC increment
        for (int i = 0; i < 10; i++) begin
            test_pc_increment($sformatf("PC_Increment_%0d", i));
        end

        // Test unconditional branch with immediate address
        test_unconditional_branch(12'h100, 1'b1, "Unconditional_Branch_Immediate");
        
        // Test unconditional branch with register address
        test_unconditional_branch(12'h200, 1'b0, "Unconditional_Branch_Register");
        
        // Test conditional branches - Zero flag conditions
        test_conditional_branch(12'h300, 1'b1, COND_ZERO, 1'b1, 1'b0, 1'b0, 1'b0, "Conditional_Zero_True");
        test_conditional_branch(12'h400, 1'b1, COND_ZERO, 1'b0, 1'b0, 1'b0, 1'b0, "Conditional_Zero_False");
        
        test_conditional_branch(12'h500, 1'b1, COND_NOT_ZERO, 1'b0, 1'b0, 1'b0, 1'b0, "Conditional_NotZero_True");
        test_conditional_branch(12'h600, 1'b1, COND_NOT_ZERO, 1'b1, 1'b0, 1'b0, 1'b0, "Conditional_NotZero_False");
        
        // Test conditional branches - Sign flag conditions
        test_conditional_branch(12'h700, 1'b1, COND_POSITIVE, 1'b0, 1'b0, 1'b0, 1'b0, "Conditional_Positive_True");
        test_conditional_branch(12'h800, 1'b1, COND_POSITIVE, 1'b0, 1'b1, 1'b0, 1'b0, "Conditional_Positive_False");
        
        test_conditional_branch(12'h900, 1'b1, COND_NEGATIVE, 1'b0, 1'b1, 1'b0, 1'b0, "Conditional_Negative_True");
        test_conditional_branch(12'hA00, 1'b1, COND_NEGATIVE, 1'b0, 1'b0, 1'b0, 1'b0, "Conditional_Negative_False");
        
        // Test conditional branches - Carry flag conditions
        test_conditional_branch(12'hB00, 1'b1, COND_CARRY_SET, 1'b0, 1'b0, 1'b1, 1'b0, "Conditional_Carry_Set_True");
        test_conditional_branch(12'hC00, 1'b1, COND_CARRY_SET, 1'b0, 1'b0, 1'b0, 1'b0, "Conditional_Carry_Set_False");
        
        test_conditional_branch(12'hD00, 1'b1, COND_CARRY_CLEARED, 1'b0, 1'b0, 1'b0, 1'b0, "Conditional_Carry_Cleared_True");
        test_conditional_branch(12'hE00, 1'b1, COND_CARRY_CLEARED, 1'b0, 1'b0, 1'b1, 1'b0, "Conditional_Carry_Cleared_False");
        
        // Test conditional branches - Overflow flag conditions
        test_conditional_branch(12'hF00, 1'b1, COND_OVERFLOW_SET, 1'b0, 1'b0, 1'b0, 1'b1, "Conditional_Overflow_Set_True");
        test_conditional_branch(12'h010, 1'b1, COND_OVERFLOW_SET, 1'b0, 1'b0, 1'b0, 1'b0, "Conditional_Overflow_Set_False");
        
        test_conditional_branch(12'h020, 1'b1, COND_OVERFLOW_CLEARED, 1'b0, 1'b0, 1'b0, 1'b0, "Conditional_Overflow_Cleared_True");
        test_conditional_branch(12'h030, 1'b1, COND_OVERFLOW_CLEARED, 1'b0, 1'b0, 1'b0, 1'b1, "Conditional_Overflow_Cleared_False");

        // Test reset functionality
        $display("Testing reset functionality...");
        rst_n = 1'b0;
        @(posedge clk);
        @(negedge clk);
        $display("PC after reset: %03h", pc);
        rst_n = 1'b1;
        @(posedge clk);
        @(negedge clk);

        // Test PC wraparound
        $display("Testing PC wraparound...");
        test_unconditional_branch(12'hFFF, 1'b1, "Jump_to_Max_Address");
        test_pc_increment("PC_Increment_from_Max");

        // Test multiple consecutive branches
        $display("Testing consecutive branches...");
        test_unconditional_branch(12'h123, 1'b1, "Branch_1");
        test_unconditional_branch(12'h456, 1'b1, "Branch_2");
        test_unconditional_branch(12'h789, 1'b1, "Branch_3");

        $display("Program Counter testbench completed successfully!");
        $finish;
    end

endmodule

`endif // PROGRAM_COUNTER_TB
