`ifndef SEVEN_SEGMENT_DRIVER_TB_SV
`define SEVEN_SEGMENT_DRIVER_TB_SV

`timescale 1ns / 1ps

module seven_segment_driver_tb;

    logic       clk;
    logic       reset_n;
    logic [3:0] dig[3:0];
    logic [6:0] seg;
    logic [3:0] an;

    seven_segment_driver#(
        .TICK_CYCLES  (1000) // Faster tick for simulation
    ) uut (
        .clk       (clk),
        .reset_n   (reset_n),
        .dig       (dig),
        .seg       (seg),
        .an        (an)
    );

    // Drive clock and reset
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz clock
    end

    initial begin
        // Initialize inputs
        reset_n = 0;
        dig[0] = 4'h1;
        dig[1] = 4'h2;
        dig[2] = 4'h3;
        dig[3] = 4'h4;

        // Release reset after some time
        #20;
        reset_n = 1;

        // Run simulation for long enough to see multiple digit cycles
        #20000;

        // Finish simulation
        $finish;
    end

endmodule: seven_segment_driver_tb

`endif // SEVEN_SEGMENT_DRIVER_TB_SV
