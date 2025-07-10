`ifndef DECODER_TB
`define DECODER_TB

// decoder_tb.sv
// author: Tom Riley
// date: 2025-07-10

/* verilator lint_off IMPORTSTAR */
import decoder_pkg::*;
import alu_pkg::*;
import register_file_pkg::*;
import program_counter_pkg::*;
/* verilator lint_on IMPORTSTAR */

// Testbench for the decoder module
module decoder_tb;
    initial begin
        $dumpfile("waves.vcd");
        $dumpvars(0, decoder_tb);
    end

    // Parameters
    localparam INST_W = 16;
    localparam I_ADDR_W = 12;
    localparam DATA_W = 8;

    // Signals
    logic [INST_W-1:0] instruction;
    wire [I_ADDR_W-1:0] address_immediate;
    wire [DATA_W-1:0] acc_immediate;
    wire [DATA_W-1:0] alu_operand_b_immediate;
    wire acc_write_enable;
    wire write_put_acc;
    wire read_get_acc;
    wire [3:0] reg_addr;
    wire read_data_output_enable;
    wire status_write_enable;
    wire data_memory_write_enable;
    wire data_memory_output_enable;
    wire jump_branch_select;
    wire immediate_address_select;
    wire unconditional_branch;
    wire [2:0] branch_condition;
    wire alu_output_enable;
    wire [2:0] alu_function;

    // Instantiate the decoder
    decoder #(
        .INST_W(INST_W),
        .I_ADDR_W(I_ADDR_W),
        .DATA_W(DATA_W)
    ) uut (
        .instruction(instruction),
        .address_immediate(address_immediate),
        .acc_immediate(acc_immediate),
        .alu_operand_b_immediate(alu_operand_b_immediate),
        .acc_write_enable(acc_write_enable),
        .write_put_acc(write_put_acc),
        .read_get_acc(read_get_acc),
        .reg_addr(reg_addr),
        .read_data_output_enable(read_data_output_enable),
        .status_write_enable(status_write_enable),
        .data_memory_write_enable(data_memory_write_enable),
        .data_memory_output_enable(data_memory_output_enable),
        .jump_branch_select(jump_branch_select),
        .immediate_address_select(immediate_address_select),
        .unconditional_branch(unconditional_branch),
        .branch_condition(branch_condition),
        .alu_output_enable(alu_output_enable),
        .alu_function(alu_function)
    );

    // Task to test instruction decoding
    task automatic test_instruction(
        input [INST_W-1:0] instr,
        input string test_name,
        input string expected_description = ""
    );
        instruction = instr;
        #10ns;
        $display("Test: %s", test_name);
        if (expected_description != "") begin
            $display("  Expected: %s", expected_description);
        end
        $display("  Instruction: %04h (%016b)", instr, instr);
        $display("  Address Immediate: %03h", address_immediate);
        $display("  ACC Immediate: %02h", acc_immediate);
        $display("  ALU B Immediate: %02h", alu_operand_b_immediate);
        $display("  Control Signals:");
        $display("    acc_write_enable: %b", acc_write_enable);
        $display("    write_put_acc: %b", write_put_acc);
        $display("    read_get_acc: %b", read_get_acc);
        $display("    reg_addr: %h", reg_addr);
        $display("    read_data_output_enable: %b", read_data_output_enable);
        $display("    status_write_enable: %b", status_write_enable);
        $display("    data_memory_write_enable: %b", data_memory_write_enable);
        $display("    data_memory_output_enable: %b", data_memory_output_enable);
        $display("    jump_branch_select: %b", jump_branch_select);
        $display("    immediate_address_select: %b", immediate_address_select);
        $display("    unconditional_branch: %b", unconditional_branch);
        $display("    branch_condition: %03b", branch_condition);
        $display("    alu_output_enable: %b", alu_output_enable);
        $display("    alu_function: %03b", alu_function);
        $display("");
    endtask

    // Function to create instruction based on format
    function automatic [INST_W-1:0] create_arith_logic_imm(
        input [7:0] data_immediate,
        input [3:0] function_code
    );
        return {data_immediate, function_code, 3'b000, 1'b0};
    endfunction

    function automatic [INST_W-1:0] create_arith_logic_reg(
        input [3:0] register,
        input [3:0] function_code
    );
        return {4'b0000, register, function_code, 3'b001, 1'b0};
    endfunction

    function automatic [INST_W-1:0] create_reg_memory(
        input [3:0] register,
        input [3:0] function_code
    );
        return {4'b0000, register, function_code, 3'b010, 1'b0};
    endfunction

    function automatic [INST_W-1:0] create_reg_memory_imm(
        input [7:0] data_immediate,
        input [3:0] function_code
    );
        return {data_immediate, function_code, 3'b010, 1'b0};
    endfunction

    function automatic [INST_W-1:0] create_jump_imm(
        input [11:0] addr_imm
    );
        return {addr_imm, 3'b100, 1'b0};
    endfunction

    function automatic [INST_W-1:0] create_jump_reg(
        input [3:0] function_code
    );
        return {4'b0000, 4'b0000, function_code, 3'b111, 1'b0};
    endfunction

    function automatic [INST_W-1:0] create_conditional_branch(
        input [11:0] addr_imm,
        input [2:0] branch_cond
    );
        return {addr_imm, branch_cond, 1'b1};
    endfunction

    // Test sequence
    initial begin
        $display("Starting Decoder testbench...");
        
        // Initialize
        instruction = '0;
        #10ns;

        // Test Arithmetic/Logic Immediate instructions (OPCODE 000)
        test_instruction(create_arith_logic_imm(8'h55, 4'b0000), "ADDI_#55", "ADDI #0x55");
        test_instruction(create_arith_logic_imm(8'h33, 4'b0001), "SUBI_#33", "SUBI #0x33");
        test_instruction(create_arith_logic_imm(8'hFF, 4'b0010), "ANDI_#FF", "ANDI #0xFF");
        test_instruction(create_arith_logic_imm(8'h0F, 4'b0100), "ORI_#0F", "ORI #0x0F");
        test_instruction(create_arith_logic_imm(8'hAA, 4'b0101), "XORI_#AA", "XORI #0xAA");

        // Test Arithmetic/Logic Register instructions (OPCODE 001)
        test_instruction(create_arith_logic_reg(4'b0001, 4'b0000), "ADD_R1", "ADD R1");
        test_instruction(create_arith_logic_reg(4'b0010, 4'b0001), "SUB_R2", "SUB R2");
        test_instruction(create_arith_logic_reg(4'b0011, 4'b0010), "AND_R3", "AND R3");
        test_instruction(create_arith_logic_reg(4'b0100, 4'b0100), "OR_R4", "OR R4");
        test_instruction(create_arith_logic_reg(4'b0101, 4'b0101), "XOR_R5", "XOR R5");
        test_instruction(create_arith_logic_reg(4'b0000, 4'b0111), "INV", "INV (no register needed)");

        // Test Register/Memory instructions (OPCODE 010)
        test_instruction(create_reg_memory_imm(8'h42, 4'b0100), "SET_#42", "SET #0x42");
        test_instruction(create_reg_memory(4'b0001, 4'b0011), "PUT_R1", "PUT R1");
        test_instruction(create_reg_memory(4'b0010, 4'b0010), "GET_R2", "GET R2");
        test_instruction(create_reg_memory(4'b0000, 4'b0000), "LOAD", "LOAD");
        test_instruction(create_reg_memory(4'b0000, 4'b0001), "STORE", "STORE");

        // Test different register addresses
        test_instruction(create_reg_memory(4'b0000, 4'b0010), "GET_R0", "GET R0");
        test_instruction(create_reg_memory(4'b0001, 4'b0010), "GET_R1", "GET R1");
        test_instruction(create_reg_memory(4'b1000, 4'b0010), "GET_ACC", "GET ACC");
        test_instruction(create_reg_memory(4'b1001, 4'b0010), "GET_DBAR", "GET DBAR");
        test_instruction(create_reg_memory(4'b1010, 4'b0010), "GET_DOFF", "GET DOFF");
        test_instruction(create_reg_memory(4'b1101, 4'b0010), "GET_IBAR", "GET IBAR");
        test_instruction(create_reg_memory(4'b1110, 4'b0010), "GET_IOFF", "GET IOFF");
        test_instruction(create_reg_memory(4'b1111, 4'b0010), "GET_STATUS", "GET STATUS");

        // Test Jump Immediate instructions (OPCODE 100)
        test_instruction(create_jump_imm(12'h123), "JMPI_123", "JMPI 0x123");
        test_instruction(create_jump_imm(12'h456), "JMPI_456", "JMPI 0x456");
        test_instruction(create_jump_imm(12'hFFF), "JMPI_FFF", "JMPI 0xFFF");

        // Test Jump Register instructions (OPCODE 111)
        test_instruction(create_jump_reg(4'b0000), "JMPR", "JMPR (relative)");
        test_instruction(create_jump_reg(4'b0001), "JMP", "JMP (absolute)");

        // Test Conditional Branch instructions (bit 0 = 1)
        test_instruction(create_conditional_branch(12'h200, 3'b000), "BZ_200", "BZ 0x200");
        test_instruction(create_conditional_branch(12'h300, 3'b001), "BNZ_300", "BNZ 0x300");
        test_instruction(create_conditional_branch(12'h400, 3'b010), "BP_400", "BP 0x400");
        test_instruction(create_conditional_branch(12'h500, 3'b011), "BN_500", "BN 0x500");
        test_instruction(create_conditional_branch(12'h600, 3'b100), "BCS_600", "BCS 0x600");
        test_instruction(create_conditional_branch(12'h700, 3'b101), "BCC_700", "BCC 0x700");
        test_instruction(create_conditional_branch(12'h800, 3'b110), "BOS_800", "BOS 0x800");
        test_instruction(create_conditional_branch(12'h900, 3'b111), "BOC_900", "BOC 0x900");

        // Test comprehensive instruction set
        $display("Comprehensive instruction set test...");
        
        // Test all arithmetic operations with different registers
        for (int reg_idx = 0; reg_idx < 8; reg_idx++) begin
            test_instruction(create_arith_logic_reg(4'(reg_idx), 4'b0000), 
                           $sformatf("ADD_R%0d", reg_idx), $sformatf("ADD R%0d", reg_idx));
        end
        
        // Test all PUT/GET operations with different registers
        for (int reg_idx = 0; reg_idx < 16; reg_idx++) begin
            test_instruction(create_reg_memory(4'(reg_idx), 4'b0011), 
                           $sformatf("PUT_REG_%0d", reg_idx), $sformatf("PUT REG[%0d]", reg_idx));
            test_instruction(create_reg_memory(4'(reg_idx), 4'b0010), 
                           $sformatf("GET_REG_%0d", reg_idx), $sformatf("GET REG[%0d]", reg_idx));
        end
        
        // Test SET with different immediate values
        test_instruction(create_reg_memory_imm(8'h00, 4'b0100), "SET_#00", "SET #0x00");
        test_instruction(create_reg_memory_imm(8'h80, 4'b0100), "SET_#80", "SET #0x80");
        test_instruction(create_reg_memory_imm(8'hFF, 4'b0100), "SET_#FF", "SET #0xFF");
        
        // Test all branch conditions with different addresses
        for (int cond = 0; cond < 8; cond++) begin
            test_instruction(create_conditional_branch(12'(12'h100 + cond*16), 3'(cond)), 
                           $sformatf("BRANCH_COND_%0d", cond), 
                           $sformatf("Branch condition %0d to 0x%03h", cond, 12'(12'h100 + cond*16)));
        end

        // Test edge cases
        test_instruction(16'h0000, "ALL_ZEROS");
        test_instruction(16'hFFFF, "ALL_ONES");
        test_instruction(16'hAAAA, "PATTERN_A");
        test_instruction(16'h5555, "PATTERN_5");

        // Test invalid opcodes (should still decode gracefully)
        test_instruction(16'b011_000_00000000, "INVALID_OPCODE_011");
        test_instruction(16'b101_000_00000000, "INVALID_OPCODE_101");
        test_instruction(16'b110_000_00000000, "INVALID_OPCODE_110");

        // Random instruction test
        $display("Random instruction decode test...");
        for (int i = 0; i < 20; i++) begin
            automatic logic [INST_W-1:0] rand_instr = INST_W'($urandom());
            test_instruction(rand_instr, $sformatf("Random_%0d", i));
        end

        $display("Decoder testbench completed successfully!");
        $finish;
    end

endmodule

`endif // DECODER_TB
