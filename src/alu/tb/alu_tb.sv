`ifndef ALU_TB
`define ALU_TB

// alu_tb.sv
// author: Tom Riley
// date: 2025-07-10

// Testbench for the ALU module
module alu_tb;
    /* verilator lint_off IMPORTSTAR */
    import alu_pkg::*;
    /* verilator lint_on IMPORTSTAR */
    initial begin
        $dumpfile("waves.vcd");
        $dumpvars(0, alu_tb);
    end

    // Parameters
    localparam DATA_W = 8;

    // Signals
    logic [DATA_W-1:0] operand_a;
    logic [DATA_W-1:0] operand_b;
    alu_func_e alu_func;
    logic output_enable;
    wire [DATA_W-1:0] alu_result;
    wire zero_flag;
    wire positive_flag;
    wire carry_flag;
    wire signed_overflow;

    // Instantiate the ALU
    alu #(
        .DATA_W(DATA_W)
    ) uut (
        .operand_a(operand_a),
        .operand_b(operand_b),
        .alu_func(alu_func),
        .output_enable(output_enable),
        .alu_result(alu_result),
        .zero_flag(zero_flag),
        .positive_flag(positive_flag),
        .carry_flag(carry_flag),
        .signed_overflow(signed_overflow)
    );

    // Task to test a specific ALU operation
    task automatic test_alu_operation(
        input [DATA_W-1:0] op_a,
        input [DATA_W-1:0] op_b,
        input alu_func_e func,
        input logic enable,
        input string test_name
    );
        operand_a = op_a;
        operand_b = op_b;
        alu_func = func;
        output_enable = enable;
        #10ns;
        
        $display("Test: %s | A=%02h B=%02h Func=%s En=%b | Result=%02h Z=%b P=%b C=%b O=%b",
                test_name, op_a, op_b, func.name(), enable, 
                alu_result, zero_flag, positive_flag, carry_flag, signed_overflow);
    endtask

    // Test sequence
    initial begin
        $display("Starting ALU testbench...");
        
        // Test all ALU functions with various operands
        test_alu_operation(8'h10, 8'h20, ADD, 1'b1, "ADD_Basic");
        test_alu_operation(8'hFF, 8'h01, ADD, 1'b1, "ADD_Overflow");
        test_alu_operation(8'h00, 8'h00, ADD, 1'b1, "ADD_Zero");
        test_alu_operation(8'h7F, 8'h01, ADD, 1'b1, "ADD_SignedOverflow");
        
        test_alu_operation(8'h30, 8'h10, SUB, 1'b1, "SUB_Basic");
        test_alu_operation(8'h10, 8'h30, SUB, 1'b1, "SUB_Negative");
        test_alu_operation(8'h00, 8'h01, SUB, 1'b1, "SUB_Underflow");
        test_alu_operation(8'h80, 8'h01, SUB, 1'b1, "SUB_SignedOverflow");
        
        test_alu_operation(8'hAA, 8'h55, AND, 1'b1, "AND_Basic");
        test_alu_operation(8'hFF, 8'hFF, AND, 1'b1, "AND_AllOnes");
        test_alu_operation(8'hFF, 8'h00, AND, 1'b1, "AND_Zero");
        
        test_alu_operation(8'hAA, 8'h55, OR, 1'b1, "OR_Basic");
        test_alu_operation(8'h00, 8'h00, OR, 1'b1, "OR_Zero");
        test_alu_operation(8'hF0, 8'h0F, OR, 1'b1, "OR_AllOnes");
        
        test_alu_operation(8'hAA, 8'h55, XOR, 1'b1, "XOR_Basic");
        test_alu_operation(8'hFF, 8'hFF, XOR, 1'b1, "XOR_Same");
        test_alu_operation(8'hF0, 8'h0F, XOR, 1'b1, "XOR_Complement");
        
        test_alu_operation(8'hAA, 8'h00, INV, 1'b1, "INV_Basic");
        test_alu_operation(8'hFF, 8'h00, INV, 1'b1, "INV_AllOnes");
        test_alu_operation(8'h00, 8'h00, INV, 1'b1, "INV_Zero");
        
        // Test tri-state behavior
        test_alu_operation(8'h55, 8'h55, ADD, 1'b0, "Tristate_Disabled");
        test_alu_operation(8'h55, 8'h55, ADD, 1'b1, "Tristate_Enabled");
        
        // Random test cases
        $display("Running random test cases...");
        for (int i = 0; i < 100; i++) begin
            automatic logic [DATA_W-1:0] rand_a = DATA_W'($urandom_range(0, 2**DATA_W - 1));
            automatic logic [DATA_W-1:0] rand_b = DATA_W'($urandom_range(0, 2**DATA_W - 1));
            automatic alu_func_e valid_funcs[6] = '{ADD, SUB, AND, OR, XOR, INV};
            /* verilator lint_off UNUSEDSIGNAL */
            automatic int func_idx = $urandom_range(0, 5);
            /* verilator lint_on UNUSEDSIGNAL */
            automatic alu_func_e rand_func = valid_funcs[func_idx];
            test_alu_operation(rand_a, rand_b, rand_func, 1'b1, $sformatf("Random_%0d", i));
        end

        $display("ALU testbench completed successfully!");
        $finish;
    end

endmodule

`endif // ALU_TB
