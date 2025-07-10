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

    // Parameters
    localparam int CLK_PERIOD_NS = 100; // 10 MHz clock for faster simulation

    // Signals
    logic reset_btn;
    logic manual_clk_sw;
    logic pulse_clk_btn;

    // Instantiate the turtle CPU top module
    turtle_cpu_top #(
        .CLK_PERIOD_NS(CLK_PERIOD_NS)
    ) uut (
        .reset_btn(reset_btn),
        .manual_clk_sw(manual_clk_sw),
        .pulse_clk_btn(pulse_clk_btn)
    );

    // Task to apply reset
    task automatic apply_reset(
        input int reset_duration_ns,
        input string test_name
    );
        $display("Applying reset: %s", test_name);
        reset_btn = 1'b1;
        #reset_duration_ns;
        reset_btn = 1'b0;
        $display("Reset released");
    endtask

    // Task to manually pulse the clock
    task automatic manual_clock_pulse(
        input int num_pulses,
        input string test_name
    );
        manual_clk_sw = 1'b1; // Switch to manual clock mode
        #100ns;
        $display("Manual clock test: %s (%0d pulses)", test_name, num_pulses);
        
        for (int i = 0; i < num_pulses; i++) begin
            pulse_clk_btn = 1'b1;
            #50ns;
            pulse_clk_btn = 1'b0;
            #50ns;
            $display("  Manual pulse %0d completed", i+1);
        end
        
        manual_clk_sw = 1'b0; // Switch back to automatic clock
        #100ns;
    endtask

    // Task to run for a specific duration
    task automatic run_for_duration(
        input int duration_us,
        input string test_name
    );
        $display("Running test: %s for %0d us", test_name, duration_us);
        #(duration_us * 1000); // Convert to ns
        $display("Test completed: %s", test_name);
    endtask

    // Test sequence
    initial begin
        $display("Starting Turtle CPU Top-level testbench...");
        
        // Initialize signals
        reset_btn = 1'b0;
        manual_clk_sw = 1'b0;
        pulse_clk_btn = 1'b0;
        
        // Wait for initial settling
        #100ns;

        // Test 1: Basic reset functionality
        apply_reset(500, "Basic_Reset_Test");
        run_for_duration(10, "Run_After_Reset");

        // Test 2: Multiple reset pulses
        apply_reset(200, "Short_Reset_1");
        run_for_duration(5, "Run_After_Short_Reset");
        apply_reset(200, "Short_Reset_2");
        run_for_duration(5, "Run_After_Short_Reset_2");

        // Test 3: Long reset test
        apply_reset(1000, "Long_Reset_Test");
        run_for_duration(20, "Run_After_Long_Reset");

        // Test 4: Manual clock operation
        apply_reset(500, "Reset_Before_Manual_Clock");
        manual_clock_pulse(10, "Manual_Clock_Test_10_Pulses");
        
        // Test 5: Switch between manual and automatic clock
        $display("Testing clock mode switching...");
        manual_clk_sw = 1'b1;
        #1000ns;
        manual_clock_pulse(5, "Manual_Mode_5_Pulses");
        manual_clk_sw = 1'b0;
        #2000ns;
        manual_clk_sw = 1'b1;
        manual_clock_pulse(3, "Manual_Mode_3_Pulses");
        manual_clk_sw = 1'b0;
        #1000ns;

        // Test 6: Reset during operation
        $display("Testing reset during operation...");
        run_for_duration(10, "Normal_Operation");
        apply_reset(300, "Reset_During_Operation");
        run_for_duration(10, "Resume_After_Reset");

        // Test 7: Rapid reset pulses
        $display("Testing rapid reset pulses...");
        for (int i = 0; i < 5; i++) begin
            apply_reset(100, $sformatf("Rapid_Reset_%0d", i));
            run_for_duration(2, $sformatf("Brief_Run_%0d", i));
        end

        // Test 8: Long running test to observe CPU behavior
        $display("Long running test to observe CPU behavior...");
        apply_reset(500, "Final_Reset");
        run_for_duration(100, "Long_Running_Test");

        // Test 9: Manual clock with reset
        $display("Testing manual clock with reset...");
        manual_clk_sw = 1'b1;
        apply_reset(500, "Reset_In_Manual_Mode");
        manual_clock_pulse(15, "Manual_Clock_After_Reset");
        manual_clk_sw = 1'b0;

        // Test 10: Boundary conditions
        $display("Testing boundary conditions...");
        
        // Very short pulses
        reset_btn = 1'b1;
        #10ns;
        reset_btn = 1'b0;
        #100ns;
        
        pulse_clk_btn = 1'b1;
        #10ns;
        pulse_clk_btn = 1'b0;
        #100ns;

        // Test 11: Final long test
        $display("Final comprehensive test...");
        apply_reset(500, "Final_Comprehensive_Reset");
        run_for_duration(200, "Final_Comprehensive_Run");

        $display("Turtle CPU Top-level testbench completed successfully!");
        $finish;
    end

    // Monitor important signals (if accessible)
    initial begin
        $display("Monitor started...");
        
        // Monitor clock and reset
        forever begin
            @(posedge uut.clk);
            // Add monitoring statements here if needed
            // $display("Clock edge at time %0t", $time);
        end
    end

    // Timeout watchdog
    initial begin
        #10ms; // 10 millisecond timeout
        $display("ERROR: Testbench timeout reached!");
        $finish;
    end

endmodule

`endif // TURTLE_CPU_TOP_TB
