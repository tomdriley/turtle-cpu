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

    // Test sequence
    initial begin
        string initial_instruction_memory_file = "initial_instruction_memory.txt";
        string final_data_memory_file = "final_data_memory.txt";
        string final_register_file = "final_register_file.txt";

        reset_btn = 1;
        manual_clk_sw = 0;
        pulse_clk_btn = 0;

        #2us;

        reset_btn = 0;

        if (!$value$plusargs("initial_instruction_memory_file=%s", initial_instruction_memory_file)) begin
            $display("No initial instruction memory file provided, using default.");
        end
        $display("Loading initial instruction memory from %s", initial_instruction_memory_file);
        $readmemb(initial_instruction_memory_file, uut.instruction_memory_inst.mem);

        #20ms;

        $display("Turtle CPU Top-level testbench completed successfully!");

        if (!$value$plusargs("final_data_memory_file=%s", final_data_memory_file)) begin
            $display("No final data memory file provided, using default.");
        end
        $display("Saving final data memory to %s", final_data_memory_file);
        $writememb(final_data_memory_file, uut.data_memory_inst.mem);
        
        if (!$value$plusargs("final_register_file=%s", final_register_file)) begin
            $display("No final register file provided, using default.");
        end
        $display("Saving final register file to %s", final_register_file);
        $writememb(final_register_file, uut.register_file_inst.mem);

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
            $display(
                "cycle=%4d pc=%4d, instruction=0x%4h, op=%25s, func=%10s, acc=0x%2h, gpr=%p",
                cycle_count,
                uut.pc,
                uut.instruction,
                uut.jump_branch_select && !uut.unconditional_branch ? "BRANCH" : uut.decoder_inst.op.name,
                uut.jump_branch_select && !uut.unconditional_branch ? uut.branch_condition.name : uut.decoder_inst.op == OPCODE_REG_MEMORY ? uut.decoder_inst.reg_mem_func.name : uut.decoder_inst.alu_output_enable ? uut.decoder_inst.alu_function.name : "N/A",
                uut.acc_out,
                uut.register_file_inst.gpr
            );
            cycle_count <= cycle_count + 1;
        end
    end

endmodule

`endif // TURTLE_CPU_TOP_TB
