`ifndef TURTLE_CPU_TOP_TB
`define TURTLE_CPU_TOP_TB

// turtle_cpu_top_tb.sv
// author: Tom Riley
// date: 2025-07-10

// Testbench for the turtle_cpu_top module
module turtle_cpu_top_tb;
    initial begin
        $dumpfile("waves.vcd");
        $dumpvars(0, turtle_cpu_top_tb);
    end

    // Signals
    logic reset_btn;
    logic manual_clk_sw;
    logic pulse_clk_btn;

    int cycle_count = 0;

    // Instantiate the turtle CPU top module
    turtle_cpu_top uut (
        .reset_btn(reset_btn),
        .manual_clk_sw(manual_clk_sw),
        .pulse_clk_btn(pulse_clk_btn)
    );

    function automatic string dir_of(input string path);
        int i;
        for (i = path.len() - 1; i >= 0; i--) begin
            if (path[i] == "/") begin
                if (i == 0) return "/";
                return path.substr(0, i - 1);
            end
        end
        return ".";
    endfunction

    // Test sequence
    initial begin
        string tb_dir = dir_of(`__FILE__);
        string turtle_cpu_top_dir = {tb_dir, "/.."};

        // Defaults use absolute paths so xsim can find the files regardless of run directory.
        string initial_instruction_memory_file = {turtle_cpu_top_dir, "/initial_instruction_memory.txt"};
        string final_data_memory_file = {turtle_cpu_top_dir, "/final_data_memory.txt"};
        string final_register_file = {turtle_cpu_top_dir, "/final_register_file.txt"};

        reset_btn = 1;
        manual_clk_sw = 0;
        pulse_clk_btn = 0;

        #2us;

        reset_btn = 0;

        if (!$value$plusargs("initial_instruction_memory_file=%s", initial_instruction_memory_file)) begin
            $display("No initial instruction memory file provided, using default.");
        end
        $display("Loading initial instruction memory from %s", initial_instruction_memory_file);
        $readmemb(initial_instruction_memory_file, uut.turtle_cpu_subsystem_inst.instruction_memory_inst.mem);

        #20ms;

        $display("Turtle CPU Top-level testbench completed successfully!");

        if (!$value$plusargs("final_data_memory_file=%s", final_data_memory_file)) begin
            $display("No final data memory file provided, using default.");
        end
        $display("Saving final data memory to %s", final_data_memory_file);
        $writememb(final_data_memory_file, uut.turtle_cpu_subsystem_inst.data_memory_inst.mem);
        
        if (!$value$plusargs("final_register_file=%s", final_register_file)) begin
            $display("No final register file provided, using default.");
        end
        $display("Saving final register file to %s", final_register_file);
        $writememb(final_register_file, uut.turtle_cpu_subsystem_inst.turtle_cpu_core_inst.register_file_inst.mem);

        $finish;
    end

    always @(edge uut.reset_n) begin
        if (uut.reset_n) begin
            $display("Reset deasserted!");
        end
        else begin
            $display("Reset asserted!");
        end
    end

    always @(posedge uut.clk or edge uut.reset_n) begin
        if (uut.reset_n) begin
            // First, let's add detailed decoder signal monitoring
            $display("cycle=%4d pc=%4d, instruction=0x%4h", cycle_count, uut.turtle_cpu_subsystem_inst.turtle_cpu_core_inst.pc, uut.turtle_cpu_subsystem_inst.turtle_cpu_core_inst.instruction);
            $display("  DECODER_SIGNALS: branch_inst=%b, jump_branch_sel=%b, uncond_branch=%b, op=%s", 
                uut.turtle_cpu_subsystem_inst.turtle_cpu_core_inst.decoder_inst.branch_instruction,
                uut.turtle_cpu_subsystem_inst.turtle_cpu_core_inst.jump_branch_select,
                uut.turtle_cpu_subsystem_inst.turtle_cpu_core_inst.unconditional_branch,
                uut.turtle_cpu_subsystem_inst.turtle_cpu_core_inst.decoder_inst.op.name()
            );
            
            // Show the actual instruction classification
            if (uut.turtle_cpu_subsystem_inst.turtle_cpu_core_inst.decoder_inst.branch_instruction) begin
                $display("  BRANCH_INSTRUCTION: cond=%s, addr_imm=0x%03h", 
                    uut.turtle_cpu_subsystem_inst.turtle_cpu_core_inst.branch_condition.name(), uut.turtle_cpu_subsystem_inst.turtle_cpu_core_inst.address_immediate);
            end else begin
                string op_name;
                string func_name;

                op_name = uut.turtle_cpu_subsystem_inst.turtle_cpu_core_inst.decoder_inst.op.name();
                if (uut.turtle_cpu_subsystem_inst.turtle_cpu_core_inst.decoder_inst.op == OPCODE_REG_MEMORY) begin
                    func_name = uut.turtle_cpu_subsystem_inst.turtle_cpu_core_inst.decoder_inst.reg_mem_func.name();
                end else if (uut.turtle_cpu_subsystem_inst.turtle_cpu_core_inst.decoder_inst.alu_output_enable === 1'b1) begin
                    func_name = uut.turtle_cpu_subsystem_inst.turtle_cpu_core_inst.decoder_inst.alu_function.name();
                end else begin
                    func_name = "N/A";
                end

                $display("  NON_BRANCH: op=%s, func=%s", op_name, func_name);
            end
            
            $display("  STATE: acc=0x%02h, gpr=%p", uut.turtle_cpu_subsystem_inst.turtle_cpu_core_inst.acc_out, uut.turtle_cpu_subsystem_inst.turtle_cpu_core_inst.register_file_inst.gpr);
            
            // Monitor ALU flags and status register updates
            if (uut.turtle_cpu_subsystem_inst.turtle_cpu_core_inst.decoder_inst.status_write_enable) begin
                $display("  STATUS_UPDATE: alu_zero=%b, alu_positive=%b, alu_carry=%b, alu_overflow=%b, status_we=%b",
                    uut.turtle_cpu_subsystem_inst.turtle_cpu_core_inst.alu_inst.zero_flag,
                    uut.turtle_cpu_subsystem_inst.turtle_cpu_core_inst.alu_inst.positive_flag,
                    uut.turtle_cpu_subsystem_inst.turtle_cpu_core_inst.alu_inst.carry_flag,
                    uut.turtle_cpu_subsystem_inst.turtle_cpu_core_inst.alu_inst.signed_overflow,
                    uut.turtle_cpu_subsystem_inst.turtle_cpu_core_inst.decoder_inst.status_write_enable
                );
                $display("  STATUS_DETAIL: old_status=0x%02h, new_status=0x%02h, reg_data_bus=0x%02h",
                    uut.turtle_cpu_subsystem_inst.turtle_cpu_core_inst.register_file_inst.mem[15], // Previous STATUS value
                    {4'b0, uut.turtle_cpu_subsystem_inst.turtle_cpu_core_inst.alu_inst.signed_overflow, uut.turtle_cpu_subsystem_inst.turtle_cpu_core_inst.alu_inst.carry_flag, uut.turtle_cpu_subsystem_inst.turtle_cpu_core_inst.alu_inst.positive_flag, uut.turtle_cpu_subsystem_inst.turtle_cpu_core_inst.alu_inst.zero_flag},
                    uut.turtle_cpu_subsystem_inst.turtle_cpu_core_inst.register_data_bus
                );
            end
            
            // Enhanced monitoring for branch instructions - use the correct branch detection
            if (uut.turtle_cpu_subsystem_inst.turtle_cpu_core_inst.decoder_inst.branch_instruction) begin
                $display("  BRANCH_DEBUG: cond=%s, status=0x%02h, addr_imm=0x%03h, pc_rel=%b",
                    uut.turtle_cpu_subsystem_inst.turtle_cpu_core_inst.branch_condition.name(),
                    uut.turtle_cpu_subsystem_inst.turtle_cpu_core_inst.register_data_bus,
                    uut.turtle_cpu_subsystem_inst.turtle_cpu_core_inst.address_immediate,
                    uut.turtle_cpu_subsystem_inst.turtle_cpu_core_inst.pc_relative
                );
                $display("  BRANCH_CALC: target_offset=0x%03h, branch_addr=0x%03h, branch_taken=%b",
                    uut.turtle_cpu_subsystem_inst.turtle_cpu_core_inst.program_counter_inst.target_offset,
                    uut.turtle_cpu_subsystem_inst.turtle_cpu_core_inst.program_counter_inst.branch_addr,
                    uut.turtle_cpu_subsystem_inst.turtle_cpu_core_inst.program_counter_inst.branch_taken
                );
                $display("  PC_LOGIC: next_pc=0x%03h, current_pc=0x%03h",
                    uut.turtle_cpu_subsystem_inst.turtle_cpu_core_inst.program_counter_inst.next_pc,
                    uut.turtle_cpu_subsystem_inst.turtle_cpu_core_inst.pc
                );
                
                // Detailed branch condition evaluation
                $display("  BRANCH_EVAL: zero_flag=%b, pos_flag=%b, carry_flag=%b, overflow_flag=%b",
                    uut.turtle_cpu_subsystem_inst.turtle_cpu_core_inst.register_data_bus[0], // ZERO_FLAG 
                    uut.turtle_cpu_subsystem_inst.turtle_cpu_core_inst.register_data_bus[1], // POSITIVE_FLAG
                    uut.turtle_cpu_subsystem_inst.turtle_cpu_core_inst.register_data_bus[2], // CARRY_FLAG
                    uut.turtle_cpu_subsystem_inst.turtle_cpu_core_inst.register_data_bus[3]  // SIGNED_OVERFLOW_FLAG
                );
                
                // Show how branch condition is being evaluated
                case (uut.turtle_cpu_subsystem_inst.turtle_cpu_core_inst.branch_condition)
                    COND_ZERO: $display("  BZ_EVAL: zero_flag=%b, should_branch=%b", 
                        uut.turtle_cpu_subsystem_inst.turtle_cpu_core_inst.register_data_bus[0], uut.turtle_cpu_subsystem_inst.turtle_cpu_core_inst.register_data_bus[0] == 1'b1);
                    COND_NOT_ZERO: $display("  BNZ_EVAL: zero_flag=%b, should_branch=%b", 
                        uut.turtle_cpu_subsystem_inst.turtle_cpu_core_inst.register_data_bus[0], uut.turtle_cpu_subsystem_inst.turtle_cpu_core_inst.register_data_bus[0] == 1'b0);
                    COND_POSITIVE: $display("  BP_EVAL: pos_flag=%b, should_branch=%b", 
                        uut.turtle_cpu_subsystem_inst.turtle_cpu_core_inst.register_data_bus[1], uut.turtle_cpu_subsystem_inst.turtle_cpu_core_inst.register_data_bus[1] == 1'b1);
                    COND_NEGATIVE: $display("  BN_EVAL: pos_flag=%b, should_branch=%b", 
                        uut.turtle_cpu_subsystem_inst.turtle_cpu_core_inst.register_data_bus[1], uut.turtle_cpu_subsystem_inst.turtle_cpu_core_inst.register_data_bus[1] == 1'b0);
                    COND_CARRY_SET: $display("  BCS_EVAL: carry_flag=%b, should_branch=%b", 
                        uut.turtle_cpu_subsystem_inst.turtle_cpu_core_inst.register_data_bus[2], uut.turtle_cpu_subsystem_inst.turtle_cpu_core_inst.register_data_bus[2] == 1'b1);
                    COND_CARRY_CLEARED: $display("  BCC_EVAL: carry_flag=%b, should_branch=%b", 
                        uut.turtle_cpu_subsystem_inst.turtle_cpu_core_inst.register_data_bus[2], uut.turtle_cpu_subsystem_inst.turtle_cpu_core_inst.register_data_bus[2] == 1'b0);
                    default: $display("  UNKNOWN_BRANCH_CONDITION: %s", uut.turtle_cpu_subsystem_inst.turtle_cpu_core_inst.branch_condition.name());
                endcase
            end
            
            cycle_count <= cycle_count + 1;
        end
    end

endmodule

`endif // TURTLE_CPU_TOP_TB
