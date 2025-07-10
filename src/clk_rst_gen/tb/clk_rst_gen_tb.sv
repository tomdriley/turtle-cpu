`ifndef CLK_RST_GEN_TB
`define CLK_RST_GEN_TB

// clk_rst_gen_tb.sv
// author: Tom Riley
// date: 2025-04-30

// This is a testbench for the clk_rst_gen module.
module clk_rst_gen_tb;
    initial begin
        $dumpfile("waves.vcd");
        $dumpvars(0, clk_rst_gen_tb);
    end

    // Parameters
    parameter int CLK_PERIOD_NS = 100; // Faster clock for simulation

    // Inputs
    logic reset_btn;
    logic manual_clk_sw;
    logic pulse_clk_btn;

    // Outputs
    /* verilator lint_off UNUSEDSIGNAL */
    logic clk;
    logic reset_n;
    /* verilator lint_on UNUSEDSIGNAL */

    // Instantiate the Unit Under Test (UUT)
    clk_rst_gen #(
        .CLK_PERIOD_NS(CLK_PERIOD_NS)
    ) uut (
        .reset_btn(reset_btn),
        .manual_clk_sw(manual_clk_sw),
        .pulse_clk_btn(pulse_clk_btn),
        .clk(clk),
        .reset_n(reset_n)
    );

    // Test sequence
    initial begin
        $display("Starting clk_rst_gen testbench...");
        
        // Test reset functionality
        $display("Testing reset functionality...");
        reset_btn = 1; // Apply reset
        manual_clk_sw = 0;
        pulse_clk_btn = 0;
        #100ns;
        if (reset_n !== 0) $error("Reset should be asserted (reset_n = 0)");
        
        reset_btn = 0; // Release reset
        #100ns;
        if (reset_n !== 1) $error("Reset should be deasserted (reset_n = 1)");
        
        // Test automatic clock mode
        $display("Testing automatic clock mode...");
        manual_clk_sw = 0;
        #5000ns; // Wait for a few clock cycles
        
        // Test manual clock mode
        $display("Testing manual clock mode...");
        manual_clk_sw = 1;
        pulse_clk_btn = 0;
        #100ns;
        if (clk !== 0) $error("Clock should be 0 when pulse_clk_btn is 0");
        
        pulse_clk_btn = 1;
        #100ns;
        if (clk !== 1) $error("Clock should be 1 when pulse_clk_btn is 1");
        
        pulse_clk_btn = 0;
        #100ns;
        if (clk !== 0) $error("Clock should be 0 when pulse_clk_btn is 0");
        
        $display("clk_rst_gen testbench completed successfully!");
        $finish; // End simulation
    end

endmodule: clk_rst_gen_tb

`endif // CLK_RST_GEN_TB

