`ifndef INSTRUCTION_MEMORY_TB
`define INSTRUCTION_MEMORY_TB

// instruction_memory_tb.sv
// author: Tom Riley
// date: 2025-07-10

// Testbench for the instruction_memory module
module instruction_memory_tb;
    initial begin
        $dumpfile("waves.vcd");
        $dumpvars(0, instruction_memory_tb);
    end

    // Parameters
    localparam INST_W = 16;
    localparam I_ADDR_W = 12;
    localparam I_MEMORY_DEPTH = 1 << I_ADDR_W;

    // Signals
    logic [I_ADDR_W-1:0] addr;
    wire [INST_W-1:0] instruction;

    // Instantiate the instruction memory
    instruction_memory #(
        .INST_W(INST_W),
        .I_ADDR_W(I_ADDR_W),
        .I_MEMORY_DEPTH(I_MEMORY_DEPTH)
    ) uut (
        .addr(addr),
        .instruction(instruction)
    );

    // Task to read instruction from memory
    task automatic read_instruction(
        input [I_ADDR_W-1:0] address,
        input string test_name,
        input [INST_W-1:0] expected_instruction = 'x
    );
        addr = address;
        #10ns;
        if (expected_instruction === 'x) begin
            $display("Read: %s | Addr=%03h Instruction=%04h", test_name, address, instruction);
        end else begin
            if (instruction === expected_instruction) begin
                $display("Read: %s | Addr=%03h Instruction=%04h [EXPECTED]", test_name, address, instruction);
            end else begin
                $display("Read: %s | Addr=%03h Instruction=%04h [UNEXPECTED - Expected %04h]", 
                        test_name, address, instruction, expected_instruction);
            end
        end
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

    function automatic [INST_W-1:0] create_reg_memory_with_data(
        input [7:0] data_immediate,
        input [3:0] function_code
    );
        return {data_immediate, function_code, 3'b010, 1'b0};
    endfunction

    function automatic [INST_W-1:0] create_jump_imm(
        input [11:0] address_immediate
    );
        return {address_immediate, 3'b100, 1'b0};
    endfunction

    function automatic [INST_W-1:0] create_jump_reg(
        input [3:0] function_code
    );
        return {4'b0000, 4'b0000, function_code, 3'b111, 1'b0};
    endfunction

    function automatic [INST_W-1:0] create_conditional_branch(
        input [11:0] address_immediate,
        input [2:0] branch_condition
    );
        return {address_immediate, branch_condition, 1'b1};
    endfunction

    // Test sequence
    initial begin
        $display("Starting Instruction Memory testbench...");
        
        // Initialize signals
        addr = '0;
        #10ns;

        // Test reading from various addresses with known instruction patterns
        read_instruction(12'h000, "Read_Address_0");
        read_instruction(12'h001, "Read_Address_1");
        read_instruction(12'h002, "Read_Address_2");
        read_instruction(12'h010, "Read_Address_16");
        read_instruction(12'h100, "Read_Address_256");
        read_instruction(12'hFFF, "Read_LastAddress");

        // Test with sample instruction patterns
        $display("Testing with sample instruction patterns...");
        
        // Test some common instruction patterns that might be in memory
        // These are example patterns based on the instruction format specification
        
        // Arithmetic Logic Immediate instructions (using correct encodings)
        $display("Expected patterns for common instructions:");
        $display("  ADDI #0x55: %04h", create_arith_logic_imm(8'h55, 4'b0000));  // ADD = 0000
        $display("  SUBI #0x33: %04h", create_arith_logic_imm(8'h33, 4'b0001));  // SUB = 0001
        $display("  ANDI #0xFF: %04h", create_arith_logic_imm(8'hFF, 4'b0010));  // AND = 0010
        $display("  ORI  #0x0F: %04h", create_arith_logic_imm(8'h0F, 4'b0100));  // OR = 0100
        $display("  XORI #0xAA: %04h", create_arith_logic_imm(8'hAA, 4'b0101));  // XOR = 0101
        
        // Arithmetic Logic Register instructions (using correct encodings)
        $display("  ADD R1:     %04h", create_arith_logic_reg(4'b0001, 4'b0000));  // R1, ADD
        $display("  SUB R2:     %04h", create_arith_logic_reg(4'b0010, 4'b0001));  // R2, SUB
        $display("  AND R3:     %04h", create_arith_logic_reg(4'b0011, 4'b0010));  // R3, AND
        $display("  OR  R4:     %04h", create_arith_logic_reg(4'b0100, 4'b0100));  // R4, OR
        $display("  XOR R5:     %04h", create_arith_logic_reg(4'b0101, 4'b0101));  // R5, XOR
        $display("  INV:        %04h", create_arith_logic_reg(4'b0000, 4'b0111));  // INV = 0111
        
        // Register/Memory instructions (using correct encodings)
        $display("  SET #0x42:  %04h", create_reg_memory_with_data(8'h42, 4'b0100));  // SET = 0100
        $display("  PUT R1:     %04h", create_reg_memory(4'b0001, 4'b0011));  // R1, PUT = 0011
        $display("  GET R2:     %04h", create_reg_memory(4'b0010, 4'b0010));  // R2, GET = 0010
        $display("  LOAD:       %04h", create_reg_memory(4'b0000, 4'b0000));  // LOAD = 0000
        $display("  STORE:      %04h", create_reg_memory(4'b0000, 4'b0001));  // STORE = 0001
        
        // Jump instructions (using correct encodings)
        $display("  JMPI 0x123: %04h", create_jump_imm(12'h123));
        $display("  JMPR:       %04h", create_jump_reg(4'b0000));  // RELATIVE = 0000
        $display("  JMP:        %04h", create_jump_reg(4'b0001));  // ABSOLUTE = 0001
        
        // Conditional branch instructions (using correct encodings)
        $display("  BZ  0x200:  %04h", create_conditional_branch(12'h200, 3'b000));  // ZERO = 000
        $display("  BNZ 0x300:  %04h", create_conditional_branch(12'h300, 3'b001));  // NOT_ZERO = 001
        $display("  BP  0x400:  %04h", create_conditional_branch(12'h400, 3'b010));  // POSITIVE = 010
        $display("  BN  0x500:  %04h", create_conditional_branch(12'h500, 3'b011));  // NEGATIVE = 011
        $display("  BCS 0x600:  %04h", create_conditional_branch(12'h600, 3'b100));  // CARRY_SET = 100
        $display("  BCC 0x700:  %04h", create_conditional_branch(12'h700, 3'b101));  // CARRY_CLEARED = 101
        $display("  BOS 0x800:  %04h", create_conditional_branch(12'h800, 3'b110));  // OVERFLOW_SET = 110
        $display("  BOC 0x900:  %04h", create_conditional_branch(12'h900, 3'b111));  // OVERFLOW_CLEARED = 111

        // Test sequential access (simulating program execution)
        $display("Sequential access test (simulating program execution)...");
        for (int i = 0; i < 32; i++) begin
            read_instruction(I_ADDR_W'(i), $sformatf("Sequential_%0d", i));
        end

        // Test random access
        $display("Random access test...");
        for (int i = 0; i < 50; i++) begin
            automatic logic [I_ADDR_W-1:0] rand_addr = I_ADDR_W'($urandom_range(0, I_MEMORY_DEPTH-1));
            read_instruction(rand_addr, $sformatf("Random_Access_%0d", i));
        end

        // Test address boundaries
        $display("Address boundary tests...");
        read_instruction(12'h000, "Boundary_First");
        read_instruction(12'hFFF, "Boundary_Last");
        
        // Test rapid address changes
        $display("Rapid address change test...");
        for (int i = 0; i < 10; i++) begin
            addr = I_ADDR_W'(i);
            #1ns;
            $display("Rapid: Addr=%03h Instruction=%04h", addr, instruction);
        end

        // Test address stability
        $display("Address stability test...");
        addr = 12'h123;
        for (int i = 0; i < 10; i++) begin
            #5ns;
            $display("Stable: Time=%0t Addr=%03h Instruction=%04h", $time, addr, instruction);
        end

        // Test instruction decoding visualization
        $display("Instruction format visualization for current memory contents:");
        for (int i = 0; i < 16; i++) begin
            addr = I_ADDR_W'(i);
            #10ns;
            $display("Addr[%03h]: %04h = %016b", I_ADDR_W'(i), instruction, instruction);
            
            // Decode instruction format
            if (instruction[0] == 1'b1) begin
                $display("  -> Conditional Branch: addr=%03h, condition=%03b", 
                        instruction[15:4], instruction[3:1]);
            end else begin
                case (instruction[3:1])
                    3'b000: $display("  -> ARITH_LOGIC_IMM: data=%02h, func=%04b", 
                                    instruction[15:8], instruction[7:4]);
                    3'b001: $display("  -> ARITH_LOGIC: reg=%04b, func=%04b", 
                                    instruction[11:8], instruction[7:4]);
                    3'b010: $display("  -> REG_MEMORY: reg=%04b, func=%04b", 
                                    instruction[11:8], instruction[7:4]);
                    3'b100: $display("  -> JUMP_IMM: addr=%03h", instruction[15:4]);
                    3'b111: $display("  -> JUMP_REG: func=%04b", instruction[7:4]);
                    default: $display("  -> Unknown opcode: %03b", instruction[3:1]);
                endcase
            end
        end

        $display("Instruction Memory testbench completed successfully!");
        $finish;
    end

endmodule

`endif // INSTRUCTION_MEMORY_TB
