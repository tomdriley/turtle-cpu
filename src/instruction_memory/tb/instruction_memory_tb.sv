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
        .INIT_FILE("count_255.mem"),
        .I_MEMORY_DEPTH(I_MEMORY_DEPTH)
    ) uut (
        .addr(addr),
        .instruction(instruction)
    );

    initial begin: main_test
        $monitor("addr=%4d, instruction=0x%4h (0b%16b)", addr, instruction, instruction);
        $display("Wrote count 1 to 255 to memory");

        for(bit[I_ADDR_W-1:0] i = 0; i < 256; i += 2) begin: addr_loop
            bit [7:0] actual_top, expected_top, actual_bottom, expected_bottom;
            addr = i;
            #1;
            expected_top = i[7:0]+2;
            expected_bottom = i[7:0]+1;
            actual_top = instruction[15:8];
            actual_bottom = instruction[7:0];
            assert(actual_top == expected_top) else $error("Top: 0x%2h doesn't match 0x%2h", actual_top, expected_top);
            assert(actual_bottom == expected_bottom) else $error("Bottom: 0x%2h doesn't match 0x%2h", actual_bottom, expected_bottom);
            #100;
        end

        $finish;
    end

endmodule

`endif // INSTRUCTION_MEMORY_TB
