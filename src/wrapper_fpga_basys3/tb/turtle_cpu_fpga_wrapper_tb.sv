`ifndef TURTLE_CPU_FPGA_WRAPPER_TB_SV
`define TURTLE_CPU_FPGA_WRAPPER_TB_SV

`timescale 1ns / 1ps

module turtle_cpu_fpga_wrapper_tb;

    logic clk_in;
    logic [15:0] sw;
    logic [15:0] led;
    logic [6:0] seg;
    logic [3:0] an;

    // Instantiate the DUT
    turtle_cpu_fpga_wrapper uut (.*);

    // Clock generation
    initial begin
        clk_in = 0;
        forever #5 clk_in = ~clk_in; // 100MHz clock
    end

    task wait_cycles(input int num_cycles);
        repeat (num_cycles) @(posedge clk_in);
    endtask

    task wait_for_reset_release();
        @(posedge uut.reset_n);
    endtask

    // Test sequences
    initial begin
        // Initialize inputs
        sw = 16'h0000;

        wait_for_reset_release();
        
        // Seven segment refresh is about 200_000 cycles = 2ms at 100MHz per digit
        // It will be a bit more than that because of the internal clock running at 16ns period
        // So wait wait about 10ms to be safe
        wait_cycles(1_000_000); // 10ms

        $finish;
    end
endmodule: turtle_cpu_fpga_wrapper_tb

`endif // TURTLE_CPU_FPGA_WRAPPER_TB_SV
